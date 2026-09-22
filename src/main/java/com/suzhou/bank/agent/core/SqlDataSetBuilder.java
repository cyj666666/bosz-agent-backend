package com.suzhou.bank.agent.core;

import cn.hutool.core.collection.CollectionUtil;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.serializer.SerializerFeature;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.suzhou.bank.agent.db.AgentDataSourceProvider;
import com.suzhou.bank.agent.db.DynamicDataSourceModel;
import com.suzhou.bank.agent.dict.AgentDictCache;
import com.suzhou.bank.agent.dict.DictModel;
import com.suzhou.bank.agent.enums.DriverTypeEnum;
import com.suzhou.bank.agent.util.AgentParamNames;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

import static com.suzhou.bank.agent.db.DynamicDBUtil.getNamedParameterJdbcTemplate;
import static com.suzhou.bank.agent.db.DynamicDBUtil.queryForListCompat;

/**
 * SQL 类型指标的取数实现（本模块最核心的取数路径）
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.agent.core.SqlDataSetBuilder}。</p>
 *
 * <p><b>取数流程</b>：</p>
 * <ol>
 *   <li>解析 {@code script} 得到 {@link SqlScript}（数据源 + SQL + 参数定义）；</li>
 *   <li>按 {@code SqlLimitType} 字典限制结果集条数（默认 100），
 *       达梦/Oracle 用 {@code rownum}，其余用 {@code limit}；</li>
 *   <li>处理细类参数（{@code relateIndexSet}）：从 {@code extensions} 中按
 *       {@code sourceField} 路径取值填充；</li>
 *   <li>处理黑盒参数（{@code blackParams}）：key 形如 {@code xxx--paramName}，
 *       在目标参数为空时兜底填充；</li>
 *   <li>处理 {@code paramData} 的关联指标与默认值，把缺失的 {@code :name} 直接替换为默认值；</li>
 *   <li>用命名参数模板执行查询，返回 {@code List<Map>}。</li>
 * </ol>
 *
 * <p><b>与源实现的差异（均为改造点，非行为变更）</b>：</p>
 * <ul>
 *   <li>{@code CommonAPI} → {@link AgentDataSourceProvider}（去掉 JeecgBoot 依赖）；</li>
 *   <li>{@code SysDictCache} → {@link AgentDictCache}；</li>
 *   <li>{@code @AllArgsConstructor}+{@code @Autowired} 字段并存（既走构造注入又走字段注入）
 *       简化为纯字段注入，效果等价、避免误读。</li>
 * </ul>
 *
 * <p><b>注意（保留源行为）</b>：取数异常时返回 {@code null} 而不是抛异常，
 * 由上层（指标查询）决定如何降级。这是源实现的设计，
 * 意味着"取不到数"和"SQL 报错"在上层无法区分，排查时需看日志。</p>
 */
@Slf4j
@Component(value = "Sql")
public class SqlDataSetBuilder implements DataSetBuilder {

    /** 未配置 SqlLimitType 字典时的默认结果集上限 */
    private static final int DEFAULT_LIMIT = 100;

    /**
     * 严格取数标记键（2026-09-16 新增）
     *
     * <p>调用方把它放进请求参数（值 {@code true}），取数时就**禁止**用
     * {@code paramData[].defaultValue}（即配置里预置的"样例值"）兜底。</p>
     *
     * <p><b>为什么需要</b>：默认值兜底原本是**无条件**的 —— 参数一缺，就把"样例值"
     * （如 {@code '苏州XX精密机械制造有限公司'}、{@code '科大讯飞股份有限公司'}）直接替换进 SQL 去跑，
     * <b>不报错、也不留痕</b>。结果就是"真实业务执行"时参数没传全，却拿样例数据算出了
     * 一个看起来正常的结论 —— 比报错危险得多。</p>
     *
     * <p>所以：<b>配置态预览</b>（指标预览、知识库详情页测试集）保持宽松、继续享受兜底；
     * <b>真实业务执行</b>（{@code /get/rule} 那条链路：规则判定 + 智策引擎补充分析）带上本标记，
     * 参数缺失时宁可这次取不到数（返回 {@code null}，由上层按"未取到值"如实反映），
     * 也绝不用样例值顶包。</p>
     *
     * <p>注意：本键随请求参数一路传到取数线程，是刻意为之 —— 取数跑在独立的
     * {@code fetch-data-fetcher-*} 线程池里，ThreadLocal 传不过去。</p>
     */
    public static final String STRICT_FETCH_KEY = "__strictFetch";

    /**
     * 「参数缺失时，允许用配置里的样例值兜底」标记（2026-09-19 加入，<b>默认安全</b>口径）。
     *
     * <p>⛔ <b>它不表示"这个入口就用样例值"</b> —— 命名刻意写全，避免被误读。
     * 语义只有一句：</p>
     *
     * <pre>
     * 调用方传了值      → 永远用传入的值（任何入口、任何标记都一样）
     * 调用方没传这个值  → 带本标记 ⇒ 用 defaultValue 样例值兜底（留 WARN 日志）
     *                     不带本标记 ⇒ 跳过本次取数（不用样例值顶包）
     * </pre>
     *
     * <p>🔴 <b>为什么要把默认反过来</b>：{@link #STRICT_FETCH_KEY} 是<b>白名单式</b>的 ——
     * 谁记得打标记谁才安全，<b>漏打就静默吃样例值</b>。方向是反的：新增一条链路、
     * 或改漏一个入口，默认就是"宽松"，事故静默发生（2026-09-17 与 09-19 各踩过一次）。
     * 现在翻转为 <b>fail-closed</b>：默认一律严格，只有<b>配置页预览 / 试跑</b>
     * （本来就允许不填参数、拿样例值看效果）才显式带上本标记。</p>
     *
     * <p>判断统一走 {@link #isStrictExecution(Map)}，别各处自己写表达式 ——
     * 口径一旦分裂就会出现"取数层严格、短路层不严格"这种自相矛盾。</p>
     */
    public static final String ALLOW_SAMPLE_FALLBACK_KEY = "__allowSampleFallback";

    /**
     * 本次取数是否属于「真实业务执行」（= 参数缺失时<b>不允许</b>用样例值兜底）。
     *
     * <p>口径：显式声明严格 ⇒ 严格；否则<b>只有</b>显式声明允许兜底才放行，其余默认严格。</p>
     *
     * <p>⚠️ 配置里的 {@code defaultValue} 是**真实样例值**
     * （{@code 'RPT-202603-001'} / {@code '苏州XX精密机械制造有限公司'} / {@code '泰州公司'}），
     * 一旦被当成真实数据参与取数，会产出"看起来完全正常、实则张冠李戴"的结论。</p>
     *
     * <p>✅ 反过来也要说清：<b>传入的参数永远优先</b> —— 真实的 {@code reportNo} 传进来，
     * 就绝不会被 {@code defaultValue} 顶掉（2026-09-19 实测：V2 传入新编号、
     * 配置默认值是旧编号，146 条取数 127 条为空 ⇒ 用的就是传入值）。</p>
     */
    public static boolean isStrictExecution(Map<String, ?> parameters) {
        if (parameters == null) {
            return true;
        }
        if (Boolean.TRUE.equals(parameters.get(STRICT_FETCH_KEY))) {
            return true;
        }
        return !Boolean.TRUE.equals(parameters.get(ALLOW_SAMPLE_FALLBACK_KEY));
    }

    @Autowired
    private AgentDataSourceProvider agentDataSourceProvider;

    @Autowired
    private AgentDictCache agentDictCache;

    @Override
    public String type() {
        return "Sql";
    }

    @Override
    public String label() {
        return "SQL";
    }

    @Override
    public List<?> build(String paramNo, String script, Map<String, Object> parameters, String relateIndexSet) {
        try {
            SqlScript sqlScript = JSON.parseObject(script, SqlScript.class);
            String scriptSql = sqlScript.getSql();
            if (StringUtils.isEmpty(sqlScript.getDataSource()) || StringUtils.isEmpty(scriptSql)) {
                return null;
            }
            String dataSourceId = sqlScript.getDataSource();
            DynamicDataSourceModel dataSourceModel = agentDataSourceProvider.getDynamicDbSourceById(dataSourceId);
            if (Objects.isNull(dataSourceModel)) {
                log.error("数据源信息不存在,dataSourceId:{}", dataSourceId);
                return null;
            }

            // sql查询结果限制条数处理
            int limit = DEFAULT_LIMIT;
            String dbType = dataSourceModel.getDbType();
            try {
                List<DictModel> list = agentDictCache.get("SqlLimitType");
                if (CollectionUtil.isNotEmpty(list)) {
                    limit = Integer.parseInt(list.get(0).getValue());
                }
            } catch (Exception e) {
                log.error("获取数据库限制条数异常！");
            }

            boolean driverFlag = DriverTypeEnum.DM.dbType.equals(dbType) || DriverTypeEnum.ORACLE.dbType.equals(dbType);
            if (driverFlag) {
                scriptSql = String.format("select * from (%s) where rownum <= %s", scriptSql, limit);
            } else {
                scriptSql = String.format("select * from (%s) rs limit %s", scriptSql, limit);
            }

            // 细类参数解析
            if (StringUtils.isNotEmpty(relateIndexSet)) {
                JSONArray jsonArray = JSON.parseArray(relateIndexSet);
                if (null != jsonArray && !jsonArray.isEmpty()) {
                    List<JSONObject> collect = jsonArray.stream()
                            .map(json -> (JSONObject) json)
                            .filter(json -> paramNo.equals(json.getString("paramNo")))
                            .collect(Collectors.toList());
                    if (CollectionUtils.isNotEmpty(collect)) {
                        List<JSONObject> paramsList = collect.get(0).getJSONArray("params").stream()
                                .map(json -> (JSONObject) json)
                                .filter(json -> "1".equals(json.getString("sourceFlag")))
                                .collect(Collectors.toList());
                        if (CollectionUtils.isNotEmpty(paramsList)) {
                            paramsList.forEach(params -> {
                                String pField = params.getString("field");
                                String pSourceField = params.getString("sourceField");
                                if (StringUtils.isNotEmpty(pSourceField)) {
                                    String[] split = pSourceField.split("-");
                                    Object extensions = parameters.get("extensions");
                                    try {
                                        if (Objects.isNull(extensions)) {
                                            String extensionsStr = String.valueOf(parameters.get("extensions_str"));
                                            if (StringUtils.isNotBlank(extensionsStr)) {
                                                extensions = JSON.parseObject(extensionsStr);
                                            }
                                        }
                                    } catch (Exception e) {
                                        log.error("extensions_str取值异常！");
                                    }
                                    if (Objects.nonNull(extensions)) {
                                        JSONObject jsonObject = (JSONObject) extensions;
                                        int index = split.length == 3 ? 2 : (split.length == 2 ? 1 : -1);
                                        if (index != -1 && jsonObject.containsKey(split[index])) {
                                            parameters.put(pField, jsonObject.get(split[index]));
                                        }
                                        if (split.length > 3) {
                                            int ind = pSourceField.indexOf("-", split[0].length() + 1);
                                            String substring = pSourceField.substring(ind + 1);
                                            if (jsonObject.containsKey(substring)) {
                                                parameters.put(pField, jsonObject.get(substring));
                                            }
                                        }
                                    }
                                }
                            });
                        }
                    }
                }
            }

            // 黑盒配置取值
            Object blackParams = parameters.get("blackParams");
            if (Objects.nonNull(blackParams)) {
                @SuppressWarnings("unchecked")
                Map<String, Object> blackParamsMap = (Map<String, Object>) blackParams;
                blackParamsMap.forEach((k, v) -> {
                    String[] split = k.split("--");
                    if (split.length > 1) {
                        String key = split[1];
                        Object object = parameters.get(key);
                        if (Objects.isNull(object) || StringUtils.isEmpty(String.valueOf(object))) {
                            parameters.put(key, v);
                        }
                    }
                });
            }

            // 入参名归一（兼容旧写法）—— 取数层的**最后兜底**。
            // 配置里的参数名已统一成驼峰（reportNo / entName / guarantorName），
            // 而调用方可能仍传 reportno / guarantorname 等历史写法；Java 侧 Map.get 大小写敏感，
            // 写法对不上就取不到值。这里就地补上规范名键（双写，原键保留），调用方无需改动。
            AgentParamNames.normalizeInPlace(parameters);

            // 关联参数和默认值处理
            // 🔴 默认安全（fail-closed）：没显式声明"预览"就一律严格，绝不吃配置里的样例值。
            boolean strictFetch = isStrictExecution(parameters);
            if (!sqlScript.getParamData().isEmpty()) {
                for (Object obj : sqlScript.getParamData()) {
                    JSONObject object = (JSONObject) obj;
                    JSONObject relateIndex = object.getJSONObject("relateIndex");
                    String name = object.getString("name");
                    Object defaultValue = object.get("defaultValue");
                    // 别名感知取值：规范名取不到时按等同别名的任意写法再取一次
                    Object nameValue = AgentParamNames.get(parameters, name);
                    if (Objects.nonNull(nameValue) && !parameters.containsKey(name)) {
                        // 别名命中的值回填到规范名键，供后面的 NamedParameterJdbcTemplate 绑定 :name
                        parameters.put(name, nameValue);
                    }
                    if (Objects.nonNull(relateIndex)) {
                        String no = relateIndex.getString("no");
                        if (parameters.containsKey(no) && Objects.isNull(nameValue)) {
                            parameters.put(name, parameters.get(no));
                        }
                    }
                    if (Objects.isNull(nameValue) || String.valueOf(nameValue).equals("\"\"")
                            || String.valueOf(nameValue).equals("''") || StringUtils.isEmpty(String.valueOf(nameValue))) {
                        // 严格模式（真实业务执行）：宁可不取数，也绝不用配置里预置的样例值顶包。
                        // 返回 null 后由上层按"未取到值"如实反映（missingValueCount / executeFailed），
                        // 而不是拿样例数据算出一个看起来正常的结论。
                        if (strictFetch) {
                            log.warn("【严格取数】指标[{}] 参数[{}] 调用方未传值 —— 跳过本次取数（不执行 SQL），"
                                    + "不会用配置里预置的样例值顶包。若这次确实是配置页预览/试跑，"
                                    + "请让入口带上 {} =true。", paramNo, name, ALLOW_SAMPLE_FALLBACK_KEY);
                            return null;
                        }
                        if (Objects.nonNull(defaultValue) && !StringUtils.isEmpty(String.valueOf(defaultValue))) {
                            scriptSql = scriptSql.replaceAll(":" + name, String.valueOf(defaultValue));
                            // 非严格模式（配置页预览 / 试跑）允许用配置预置样例值兜底，但必须**留痕**：
                            // 2026-09-17 实测过一次难查的 bug —— 智策页面的"补充分析"漏传 guarantorName，
                            // 取数层静默用样例值 '泰州公司' 顶包，导致规则判定与文案描述取到两条不同记录、
                            // 写出自相矛盾的结论，而日志里只有 SQL 结果、看不出"这是样例值"。
                            // 有了这条 WARN，再遇到"结果里冒出配置样例值"，一眼就能定位是哪条链路漏传了入参。
                            log.warn("【样例值兜底】指标[{}] 参数[{}] 未取到值，已用配置预置样例值[{}]替换占位符（非严格模式）。"
                                    + "若本次属于真实业务执行，说明调用方漏传了该参数。", paramNo, name, defaultValue);
                        }
                    }
                }
            }

            // 执行sql查询
            // 🔴 2026-09-23（行内专用加固）：原先直接用 jdbcTemplate.queryForList(...)，
            //    Spring 会对 numeric/decimal 列调用 rs.getBigDecimal()；行内 GaussDB(M 模式)
            //    驱动在这些列上会带上**千分位** ⇒ 抛「不良的类型值 bigdecimal」，
            //    再被下面的 catch 吞掉、返回 null ⇒ 指标静默"取不到值"、报告成片无数据。
            //    改用 queryForListCompat：numeric/decimal 走 getString + 剥千分位，
            //    其余列行为完全不变。详见 DynamicDBUtil#queryForListCompat 的类注释。
            NamedParameterJdbcTemplate jdbcTemplate = getNamedParameterJdbcTemplate(dataSourceModel.getCode());
            return queryForListCompat(jdbcTemplate, scriptSql, parameters);
        } catch (Exception e) {
            log.error("数据源查询数据异常，异常原因{}", ExceptionUtils.getStackTrace(e));
            return null;
        }
    }

    @Override
    public List<?> formatData(List<?> data) {
        List<JSONObject> list = new ArrayList<>(data.size());
        data.forEach(obj -> {
            JSONObject newJson = new JSONObject(true);
            JSONObject json = JSON.parseObject(JSON.toJSONString(obj, SerializerFeature.WriteMapNullValue));
            newJson.putAll(json);
            list.add(newJson);
        });
        return list;
    }
}
