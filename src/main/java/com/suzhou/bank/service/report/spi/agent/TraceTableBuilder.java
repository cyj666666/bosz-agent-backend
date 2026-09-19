package com.suzhou.bank.service.report.spi.agent;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import javax.sql.DataSource;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

/**
 * 「表格溯源」内容加工：按表名 + 条件查业务表 → 拼成 <b>markdown 表格</b>文本。
 *
 * <p><b>为什么是 md 文本</b>：溯源块的内容最终进 {@code app_report_content_instance.content}，
 * 与正文一样都是文本；前端点「溯源」后弹大窗展示（不是直接铺在正文里），
 * 所以**列多也不怕**（弹窗可横向滚动）。</p>
 *
 * <p><b>取哪些列</b>（2026-09-19 起）：以《报告详情设计.xlsx》**Sheet4「溯源表格内容」**
 * 为唯一口径 —— 生成器 {@code _tools/gen_trace_table_fields.py} 把它导出成
 * {@code resources/report/trace-table-fields.json}（**23 张表 / 308 个字段**），
 * 本类只 SELECT 清单里的字段、表头用清单里的「取值字段名称」。</p>
 * <ul>
 *   <li>🔴 <b>白名单里的表头原样使用，不做「（」截断</b> —— 清单里的
 *       {@code 注册资本（万元）} 带单位，截成「注册资本」就丢信息了
 *       （截断逻辑只服务于老的「列注释」路径，注释里常带码值说明才需要砍）；</li>
 *   <li>表不在清单里 ⇒ 回退**全列 + 列注释**老行为，并记 WARN（说明 Excel 漏设计）；</li>
 *   <li>清单里的字段在物理表里找不到 ⇒ 跳过该列 + WARN，不让一条错配置整块失败。</li>
 * </ul>
 *
 * <p><b>全空列不渲染</b>：取完数后丢掉「所有行都为空」的列。一是溯源明细里空列没有信息量，
 * 二是同一张表可能挂在多个章节（实测 {@code app_credit_report_info} 同时用于
 * 「六、征信」（借款人）与「十二（二）担保人征信」（担保人）），字段白名单按表取并集后，
 * 换场景时会多出 1 个不适用于该场景的列 —— 靠"全空"自然过滤掉。</p>
 *
 * <p><b>条件口径</b>：
 * <ul>
 *   <li>参数名 → 物理列名映射见 {@link #PARAM_COLUMN}（{@code entName → customername}、
 *       {@code reportNo → reportno}，与指标 SQL 口径一致）；</li>
 *   <li>模板 {@code agentParams} 里的 {@code 列=值} 令牌是**额外过滤条件**（如 {@code subjectType=借款人}）；</li>
 *   <li>🔴 <b>某张表没有这个列就跳过该条件、只记日志</b>，不当成"过滤生效了"
 *       （已知：{@code app_guarantor_credit_info} 没有 {@code subjecttype} 列）；</li>
 *   <li>🔴 <b>严格按条件查，绝不做担保人轮询</b> —— 轮询只发生在知识库/智策引擎块。</li>
 * </ul></p>
 *
 * <p>表名做白名单校验（{@code ^app_[a-z0-9_]+$}）后拼进 SQL：表名来自模板配置，
 * 但不能因为"配置可信"就放弃防线。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Component
public class TraceTableBuilder {

    /** 参数名 → 物理列名（GaussDB 未加引号的标识符一律折成小写） */
    private static final Map<String, String> PARAM_COLUMN;

    static {
        Map<String, String> m = new HashMap<>();
        m.put("reportNo", "reportno");
        m.put("entName", "customername");
        m.put("guarantorName", "guarantorname");
        PARAM_COLUMN = Collections.unmodifiableMap(m);
    }

    /** 表名白名单：只允许 app_ 开头的小写字母/数字/下划线 */
    private static final Pattern TABLE_PATTERN = Pattern.compile("^app_[a-z0-9_]+$");

    /** 表格溯源字段白名单（由《报告详情设计》Sheet4 生成，改 Excel 后重跑生成器） */
    private static final String WHITELIST_RESOURCE = "report/trace-table-fields.json";

    /** 结果行数上限，防超大表把 content 撑爆 */
    private static final int MAX_ROWS = 500;

    /** 列元数据缓存（DDL 极少变；键 = 表名） */
    private final Map<String, List<ColumnMeta>> columnCache = new ConcurrentHashMap<>();

    /** 字段白名单：表名（小写）→ Sheet4 指定的字段清单 */
    private final Map<String, List<FieldMeta>> whitelist;

    private final NamedParameterJdbcTemplate jdbc;

    public TraceTableBuilder(DataSource dataSource) {
        this.jdbc = new NamedParameterJdbcTemplate(dataSource);
        this.whitelist = loadWhitelist();
    }

    /**
     * 「这份报告有没有业务数据」的探测表。
     *
     * <p>客户主体 / 担保人 / 财务指标 —— 这三个是本报告链路取数的核心基础；
     * <b>任一有数据</b>即认为这份报告编号下确实有业务数据。反过来，三张都空
     * 说明这个报告编号在业务表里根本不存在（典型场景：手工发起时填的编号刚好有数据，
     * 而「更新报告」换出的新编号没人往里落数）。</p>
     */
    private static final String[] CORE_DATA_TABLES = {
            "app_customer_info", "app_guarantor_info", "app_finance_indicator_info"};

    /**
     * 业务数据探测：该报告编号在核心业务表里是否存在数据。
     *
     * <p>用途见 {@code AgentReportContentProvider#hasBusinessData} ——
     * 用户口径（2026-09-19）：<b>业务表没有这份报告编号的数据，就不要调 agent
     * （知识库 / 智策引擎），正文展示"暂无数据"即可</b>。</p>
     *
     * <p>探测失败（表不存在 / 库异常）返回 {@code true} —— <b>宁可多调，不可误判为无数据</b>。</p>
     */
    public boolean hasBusinessData(String reportNo) {
        if (!StringUtils.hasText(reportNo)) {
            return false;
        }
        boolean probed = false;
        for (String table : CORE_DATA_TABLES) {
            try {
                Integer n = jdbc.queryForObject(
                        "SELECT count(*) FROM " + table + " WHERE reportno = :p0",
                        Collections.singletonMap("p0", reportNo), Integer.class);
                probed = true;
                if (n != null && n > 0) {
                    return true;
                }
            } catch (Throwable e) {
                log.warn("【报告内容加工】业务数据探测失败(该表跳过) table={} reportNo={} err={}",
                        table, reportNo, e.getMessage());
            }
        }
        if (!probed) {
            // 三张表一张都没探成 ⇒ 无法判断，不拦（避免因探测本身故障把整份报告打成空）
            log.warn("【报告内容加工】业务数据探测全部失败，按\"有数据\"处理 reportNo={}", reportNo);
            return true;
        }
        return false;
    }

    /**
     * 拼 md 表格。
     *
     * @param table       表英文名（模板 E 列，如 {@code app_customer_info}）
     * @param agentParams 模板 G 列归一化后的入参（如 {@code reportNo,entName} 或
     *                    {@code reportNo,entName,subjectType=借款人}）
     * @param values      参数名 → 值（由调用方从报告上下文取：reportNo / entName / guarantorName）
     * @return md 表格文本；无数据或表/列有问题时返回 {@code null}（块内容为空 → 模板 HIDE 兜底）
     */
    public String buildMd(String table, String agentParams, Map<String, String> values) {
        if (!StringUtils.hasText(table) || !TABLE_PATTERN.matcher(table).matches()) {
            log.warn("【报告内容加工】表格溯源：表名非法，跳过 table={}", table);
            return null;
        }
        List<ColumnMeta> allColumns = columns(table);
        if (allColumns.isEmpty()) {
            log.warn("【报告内容加工】表格溯源：表不存在或没有列 table={}", table);
            return null;
        }
        // 取列：Sheet4 白名单优先（表头 = 清单里的「取值字段名称」）；不在清单里则回退全列 + 列注释
        List<ColumnMeta> columns = pickColumns(table, allColumns);
        if (columns.isEmpty()) {
            log.warn("【报告内容加工】表格溯源：清单里的字段在表里一个都没匹配上，跳过 table={}", table);
            return null;
        }

        Map<String, Object> queryParams = new LinkedHashMap<>();
        List<String> where = new ArrayList<>();
        int condSeq = 0;
        for (String token : splitParams(agentParams)) {
            String column;
            String value;
            int eq = token.indexOf('=');
            if (eq > 0) {
                // `列=值` 令牌：额外过滤条件
                column = token.substring(0, eq).trim();
                value = token.substring(eq + 1).trim();
            } else {
                column = PARAM_COLUMN.get(token);
                value = values == null ? null : values.get(token);
            }
            if (!StringUtils.hasText(column)) {
                log.warn("【报告内容加工】表格溯源：未知参数名，跳过 table={} token={}", table, token);
                continue;
            }
            String actual = findColumn(allColumns, column);
            if (actual == null) {
                // 🔴 表里没这个列 → 跳过该条件（例如 app_guarantor_credit_info 没有 subjecttype），
                //    明确记日志，避免被误认为"过滤生效了"
                log.warn("【报告内容加工】表格溯源：表里没有该列，跳过此条件 table={} column={}", table, column);
                continue;
            }
            if (!StringUtils.hasText(value)) {
                log.warn("【报告内容加工】表格溯源：参数值为空，跳过此条件 table={} column={}", table, column);
                continue;
            }
            String key = "p" + (condSeq++);
            where.add(actual + " = :" + key);
            queryParams.put(key, value);
        }

        String sql = "SELECT " + joinColumnNames(columns) + " FROM " + table
                + (where.isEmpty() ? "" : " WHERE " + String.join(" AND ", where));
        List<Map<String, Object>> rows;
        try {
            // ⚠️ NamedParameterJdbcTemplate 没有 setMaxRows，要落到它底层的 JdbcTemplate 上设
            //    （本类的 template 是自己 new 的实例，不会被别处共享）
            jdbc.getJdbcTemplate().setMaxRows(MAX_ROWS);
            rows = jdbc.queryForList(sql, queryParams);
        } catch (Exception e) {
            log.error("【报告内容加工】表格溯源：查表失败 table={} sql={}", table, sql, e);
            return null;
        }
        if (rows == null || rows.isEmpty()) {
            log.info("【报告内容加工】表格溯源：无数据 table={} 条件={}", table, queryParams);
            return null;
        }
        List<ColumnMeta> visible = dropEmptyColumns(table, columns, rows);
        if (visible.isEmpty()) {
            log.info("【报告内容加工】表格溯源：所有列的值都为空，按无数据处理 table={} 条件={}",
                    table, queryParams);
            return null;
        }
        log.info("【报告内容加工】表格溯源：成功 table={} 行数={} 列数={}（取列 {} → 渲染 {}）条件={}",
                table, rows.size(), columns.size(), columns.size(), visible.size(), queryParams);
        return renderMd(visible, rows);
    }

    /* ==================== 字段白名单 ==================== */

    /**
     * 取列：Sheet4 白名单优先。
     *
     * <p>白名单里的表头（「取值字段名称」）**原样使用、不做截断**；物理列名做大小写不敏感匹配
     * （Excel 写的是 {@code customerId}，物理列是 {@code customerid}）。</p>
     */
    private List<ColumnMeta> pickColumns(String table, List<ColumnMeta> allColumns) {
        List<FieldMeta> fields = whitelist.get(table.toLowerCase(Locale.ROOT));
        if (fields == null) {
            log.warn("【报告内容加工】表格溯源：《报告详情设计》Sheet4 里没有这张表的字段清单，"
                    + "回退为「全列 + 列注释」table={}", table);
            return allColumns;
        }
        List<ColumnMeta> picked = new ArrayList<>(fields.size());
        int missing = 0;
        for (FieldMeta f : fields) {
            String actual = findColumn(allColumns, f.field);
            if (actual == null) {
                log.warn("【报告内容加工】表格溯源：清单字段在物理表里不存在，跳过 table={} field={}",
                        table, f.field);
                missing++;
                continue;
            }
            picked.add(new ColumnMeta(actual, null, f.label));
        }
        if (missing > 0) {
            log.warn("【报告内容加工】表格溯源：table={} 清单 {} 个字段，有 {} 个在物理表里找不到",
                    table, fields.size(), missing);
        }
        return picked;
    }

    /** 读取字段白名单 JSON；失败返回空表（⇒ 全部走「全列 + 列注释」老行为，不影响出报表） */
    private static Map<String, List<FieldMeta>> loadWhitelist() {
        Map<String, List<FieldMeta>> map = new HashMap<>();
        try (InputStream in = new ClassPathResource(WHITELIST_RESOURCE).getInputStream()) {
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            int n;
            while ((n = in.read(buffer)) > 0) {
                bos.write(buffer, 0, n);
            }
            String json = new String(bos.toByteArray(), StandardCharsets.UTF_8);
            JSONObject root = JSON.parseObject(json);
            JSONObject tables = root == null ? null : root.getJSONObject("tables");
            if (tables != null) {
                for (Map.Entry<String, Object> entry : tables.entrySet()) {
                    JSONObject tableNode = (JSONObject) entry.getValue();
                    List<FieldMeta> fields = new ArrayList<>();
                    JSONArray array = tableNode.getJSONArray("fields");
                    if (array != null) {
                        for (int i = 0; i < array.size(); i++) {
                            JSONObject fieldNode = array.getJSONObject(i);
                            String name = fieldNode.getString("field");
                            if (!StringUtils.hasText(name)) {
                                continue;
                            }
                            fields.add(new FieldMeta(name.trim(), fieldNode.getString("label")));
                        }
                    }
                    if (!fields.isEmpty()) {
                        map.put(entry.getKey().toLowerCase(Locale.ROOT), fields);
                    }
                }
            }
            int fieldCount = 0;
            for (List<FieldMeta> list : map.values()) {
                fieldCount += list.size();
            }
            log.info("【报告内容加工】表格溯源字段白名单已加载：{} 张表 / {} 个字段（{}）",
                    map.size(), fieldCount, WHITELIST_RESOURCE);
        } catch (Exception e) {
            log.error("【报告内容加工】表格溯源字段白名单加载失败：{} ⇒ 所有表回退为「全列 + 列注释」",
                    WHITELIST_RESOURCE, e);
        }
        return map;
    }

    /* ==================== 列元数据 ==================== */

    private static final String COLUMN_SQL =
            "SELECT a.attname AS col, d.description AS cmt"
                    + " FROM pg_catalog.pg_class c"
                    + " JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace"
                    + " JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid"
                    + " LEFT JOIN pg_catalog.pg_description d ON d.objoid = c.oid AND d.objsubid = a.attnum"
                    + " WHERE c.relname = :table AND a.attnum > 0 AND NOT a.attisdropped"
                    + " AND n.nspname = current_schema()"
                    + " ORDER BY a.attnum";

    private static final String COLUMN_SQL_NO_SCHEMA = COLUMN_SQL.replace(
            " AND n.nspname = current_schema()", "");

    /** 取列名 + 中文注释（带缓存）。先按当前 schema 找，找不到再放宽到全库（避免 search_path 差异） */
    private List<ColumnMeta> columns(String table) {
        List<ColumnMeta> cached = columnCache.get(table);
        if (cached != null) {
            return cached;
        }
        Map<String, Object> args = new HashMap<>();
        args.put("table", table);
        List<ColumnMeta> list = queryColumns(COLUMN_SQL, args);
        if (list.isEmpty()) {
            list = queryColumns(COLUMN_SQL_NO_SCHEMA, args);
        }
        columnCache.put(table, list);
        if (list.isEmpty()) {
            log.warn("【报告内容加工】表格溯源：拿不到列定义 table={}", table);
        }
        return list;
    }

    private List<ColumnMeta> queryColumns(String sql, Map<String, Object> args) {
        List<ColumnMeta> list = new ArrayList<>();
        try {
            List<Map<String, Object>> rows = jdbc.queryForList(sql, args);
            for (Map<String, Object> row : rows) {
                Object col = row.get("col");
                if (col == null) {
                    continue;
                }
                Object cmt = row.get("cmt");
                list.add(new ColumnMeta(String.valueOf(col), cmt == null ? null : String.valueOf(cmt)));
            }
        } catch (Exception e) {
            log.error("【报告内容加工】表格溯源：查列定义失败", e);
        }
        return list;
    }

    /** 在列清单里按大小写不敏感找真实列名 */
    private String findColumn(List<ColumnMeta> columns, String wanted) {
        for (ColumnMeta c : columns) {
            if (c.name.equalsIgnoreCase(wanted)) {
                return c.name;
            }
        }
        return null;
    }

    /* ==================== md 渲染 ==================== */

    /** 丢掉「所有行都为空」的列（溯源明细里空列没有信息量；也化解同表多场景的字段并集） */
    private List<ColumnMeta> dropEmptyColumns(String table, List<ColumnMeta> columns,
                                             List<Map<String, Object>> rows) {
        List<ColumnMeta> visible = new ArrayList<>(columns.size());
        List<String> dropped = new ArrayList<>();
        for (ColumnMeta c : columns) {
            boolean hasValue = false;
            for (Map<String, Object> row : rows) {
                if (StringUtils.hasText(value(row, c.name))) {
                    hasValue = true;
                    break;
                }
            }
            if (hasValue) {
                visible.add(c);
            } else {
                dropped.add(c.name);
            }
        }
        if (!dropped.isEmpty()) {
            log.info("【报告内容加工】表格溯源：table={} 全空列 {} 个未渲染 {}", table, dropped.size(), dropped);
        }
        return visible;
    }

    private String joinColumnNames(List<ColumnMeta> columns) {
        StringBuilder sb = new StringBuilder();
        for (ColumnMeta c : columns) {
            if (sb.length() > 0) {
                sb.append(", ");
            }
            sb.append(c.name);
        }
        return sb.toString();
    }

    private String renderMd(List<ColumnMeta> columns, List<Map<String, Object>> rows) {
        StringBuilder sb = new StringBuilder();
        sb.append("|");
        for (ColumnMeta c : columns) {
            sb.append(' ').append(cell(header(c))).append(" |");
        }
        sb.append('\n').append("|");
        for (int i = 0; i < columns.size(); i++) {
            sb.append(" --- |");
        }
        for (Map<String, Object> row : rows) {
            sb.append('\n').append("|");
            for (ColumnMeta c : columns) {
                sb.append(' ').append(cell(value(row, c.name))).append(" |");
            }
        }
        return sb.toString();
    }

    /**
     * 表头取值优先级：**白名单指定的表头** → 列注释（在**第一个「（」处截断**，注释里常带码值说明）
     * → 列名。
     *
     * <p>⚠️ 白名单表头**不截断**：它是人写的展示名，{@code 注册资本（万元）} 里那个括号是单位，
     * 砍掉就丢信息了。截断只服务于老的「列注释」路径。</p>
     */
    static String header(ColumnMeta column) {
        if (StringUtils.hasText(column.header)) {
            return column.header.trim();
        }
        String cmt = column.comment == null ? "" : column.comment.trim();
        if (cmt.isEmpty()) {
            return column.name;
        }
        int idx = cmt.indexOf('（');
        if (idx > 0) {
            cmt = cmt.substring(0, idx).trim();
        }
        return cmt.isEmpty() ? column.name : cmt;
    }

    /** 取值：列名大小写不敏感；null → 空串 */
    private String value(Map<String, Object> row, String column) {
        Object v = row.get(column);
        if (v == null) {
            for (Map.Entry<String, Object> e : row.entrySet()) {
                if (e.getKey() != null && e.getKey().equalsIgnoreCase(column)) {
                    v = e.getValue();
                    break;
                }
            }
        }
        return v == null ? "" : String.valueOf(v);
    }

    /** md 单元格：竖线转义、换行压平（否则一行会被拆成多行、表格直接错位） */
    private String cell(String raw) {
        String s = raw == null ? "" : raw;
        s = s.replace("\r", " ").replace("\n", " ").replace("|", "\\|").trim();
        return s;
    }

    private List<String> splitParams(String agentParams) {
        List<String> list = new ArrayList<>();
        if (StringUtils.hasText(agentParams)) {
            for (String item : agentParams.split(",")) {
                String t = item == null ? "" : item.trim();
                if (!t.isEmpty()) {
                    list.add(t);
                }
            }
        }
        return list;
    }

    /** 列元数据 */
    static class ColumnMeta {
        final String name;
        final String comment;
        /** 白名单指定的表头（**原样使用，不截断**）；为空时按 comment → name 推 */
        final String header;

        ColumnMeta(String name, String comment) {
            this(name, comment, null);
        }

        ColumnMeta(String name, String comment, String header) {
            this.name = name;
            this.comment = comment;
            this.header = header;
        }
    }

    /** 白名单里的一个字段（Excel 的「取值字段」+「取值字段名称」） */
    static class FieldMeta {
        final String field;
        final String label;

        FieldMeta(String field, String label) {
            this.field = field;
            this.label = label;
        }
    }
}
