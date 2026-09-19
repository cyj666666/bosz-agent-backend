package com.suzhou.bank.service.report.spi.analysis;

import com.suzhou.bank.service.report.spi.ReportAnalysisDataSource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import javax.sql.DataSource;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * 全文分析外部数据域②：**授信管理要求**（表 {@code app_credit_approval_manage_req_info}，列 {@code CONDITION}）。
 *
 * <p><b>用户口径（2026-09-19，逐字对齐）</b>：
 * <b>「AI 分析全文，需要额外加两个数据分析来源，这两个数据正文未使用 …… 2. 若报告正文无批复管理要求，
 * 则使用授信管理要求（{@code app_credit_approval_manage_req_info} 的 {@code CONDITION}）
 * 作为 AI 全文分析的素材」</b>。</p>
 *
 * <p>即：正文里已经有「（二)批复后续管理要求落实情况」这块内容时**不补**（报告里有的东西不必再喂一遍，
 * 否则素材里会出现两份口径）；正文里没有（块为空 / 未取到数）才从表里把 {@code CONDITION} 捞出来补进素材。</p>
 *
 * <p><b>只进分析素材，报告正文不展示</b>。⚠️ 素材组装器（{@link com.suzhou.bank.service.report.ai.AnalysisMaterialBuilder}）
 * 由「AI 全文分析」与「预警建议」**共用** ⇒ 预警建议同样能看到本节
 * （用户 2026-09-19 裁决 **A：两边口径保持一致**，故不做用途隔离）。</p>
 *
 * <p>「正文里有没有」的判据：该报告在 {@code app_report_content_instance} 里，
 * {@code agentcode = 'pfglyqlsqk'} 或 {@code catalogcode = 'V2_CAT_04_POSTLOAN_02'}
 * 且 {@code content} 非空 ⇒ 视为已有。⚠️ 探测失败按**已有**处理（fail-closed）——
 * 宁可不补，也不要给模型两份互相矛盾的内容。</p>
 *
 * <p>🔴 {@code CONDITION} 列在库里是**大写**（建表时带引号），SQL 里必须写 {@code "CONDITION"}，
 * 否则会被折成小写而报「列不存在」。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Component
public class ApprovalRequirementAnalysisDataSource implements ReportAnalysisDataSource {

    /** 源表：信贷审批管理要求信息 */
    private static final String TABLE = "app_credit_approval_manage_req_info";

    /** 🔴 列名大写，必须带双引号 */
    private static final String SQL =
            "SELECT swqno, \"CONDITION\", checkdate"
                    + " FROM " + TABLE
                    + " WHERE reportno = :p0"
                    + " ORDER BY inputtime, id";

    /** 「正文里已经写过批复管理要求」的探测 */
    private static final String HAS_CONTENT_SQL =
            "SELECT count(*) FROM app_report_content_instance"
                    + " WHERE reportno = :p0"
                    + " AND (agentcode = 'pfglyqlsqk' OR catalogcode = 'V2_CAT_04_POSTLOAN_02')"
                    + " AND content IS NOT NULL AND btrim(content) <> ''";

    private final NamedParameterJdbcTemplate jdbc;

    public ApprovalRequirementAnalysisDataSource(DataSource dataSource) {
        this.jdbc = new NamedParameterJdbcTemplate(dataSource);
    }

    @Override
    public String code() {
        return "approvalRequirement";
    }

    /** 素材小节标题（用户口径命名） */
    @Override
    public String label() {
        return "授信管理要求";
    }

    @Override
    public String load(String reportNo, String customerId, String customerName) {
        if (!StringUtils.hasText(reportNo)) {
            return null;
        }
        if (reportAlreadyHasContent(reportNo)) {
            log.info("【全文分析·外部数据】批复管理要求：正文已有内容，不再补表数据 reportNo={}", reportNo);
            return null;
        }
        List<Map<String, Object>> rows;
        try {
            rows = jdbc.queryForList(SQL, Collections.singletonMap("p0", reportNo));
        } catch (Exception e) {
            log.warn("【全文分析·外部数据】批复管理要求取数失败 reportNo={} err={}",
                    reportNo, e.getMessage());
            return null;
        }
        if (rows == null || rows.isEmpty()) {
            return null;
        }
        StringBuilder sb = new StringBuilder();
        int seq = 0;
        for (Map<String, Object> row : rows) {
            String condition = value(row, "CONDITION");
            if (!StringUtils.hasText(condition)) {
                continue;
            }
            seq++;
            sb.append(seq).append(". ").append(condition.trim());
            StringBuilder meta = new StringBuilder();
            String swqno = value(row, "swqno");
            if (StringUtils.hasText(swqno)) {
                meta.append("申请文号：").append(swqno.trim());
            }
            String checkDate = value(row, "checkdate");
            if (StringUtils.hasText(checkDate)) {
                if (meta.length() > 0) {
                    meta.append(" / ");
                }
                meta.append("检查日期：").append(checkDate.trim());
            }
            if (meta.length() > 0) {
                sb.append("（").append(meta).append("）");
            }
            sb.append('\n');
        }
        if (sb.length() == 0) {
            log.info("【全文分析·外部数据】批复管理要求：有行但 CONDITION 全空 reportNo={}", reportNo);
            return null;
        }
        log.info("【全文分析·外部数据】批复管理要求：正文缺失，已从表补 {} 条 reportNo={}", seq, reportNo);
        return sb.toString().trim();
    }

    /**
     * 报告正文里是否已经有「批复管理要求」相关内容。
     *
     * <p>探测失败返回 {@code true}（按已有处理）—— 见类注释的 fail-closed 口径。</p>
     */
    private boolean reportAlreadyHasContent(String reportNo) {
        try {
            Integer n = jdbc.queryForObject(HAS_CONTENT_SQL,
                    Collections.singletonMap("p0", reportNo), Integer.class);
            return n != null && n > 0;
        } catch (Exception e) {
            log.warn("【全文分析·外部数据】批复管理要求正文探测失败，按\"已有内容\"处理 reportNo={} err={}",
                    reportNo, e.getMessage());
            return true;
        }
    }

    /** 取值：列名大小写不敏感，null → 空串 */
    private static String value(Map<String, Object> row, String column) {
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
}
