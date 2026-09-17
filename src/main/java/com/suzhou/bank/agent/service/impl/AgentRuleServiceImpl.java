package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.date.DateUtil;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.suzhou.bank.agent.client.AgentSearchApiClient;
import com.suzhou.bank.agent.client.HubApiClient;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.google.common.collect.Maps;
import javax.annotation.Resource;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.util.JSONTools;
import cn.hutool.crypto.digest.DigestUtil;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.entity.AgentRuleEntity;
import com.suzhou.bank.agent.entity.AgentRulePrompt;
import com.suzhou.bank.agent.entity.IndexParamsEntity;
import com.suzhou.bank.agent.mapper.AgentRuleMapper;
import com.suzhou.bank.agent.model.req.AgentRuleExecuteReq;
import com.suzhou.bank.agent.model.req.AgentRuleParseReq;
import com.suzhou.bank.agent.model.req.AgentRuleSaveReq;
import com.suzhou.bank.agent.model.vo.AgentRuleExecuteVO;
import com.suzhou.bank.agent.model.vo.AgentRuleMetricVO;
import com.suzhou.bank.agent.model.vo.AgentRuleParseVO;
import com.suzhou.bank.agent.service.IAgentRuleService;
import com.suzhou.bank.agent.service.IIndexParamsService;
import com.suzhou.bank.agent.service.IknowledgeBaseConfigService;
import com.suzhou.bank.agent.util.CallLlmUtil;
import com.suzhou.bank.agent.util.AgentParamNames;
import com.suzhou.bank.agent.util.QLExpressUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AgentRuleServiceImpl extends ServiceImpl<AgentRuleMapper, AgentRuleEntity> implements IAgentRuleService {

    @Resource
    AgentSearchApiClient agentSearchApiClient;

    @Resource
    private IknowledgeBaseConfigService knowledgeBaseConfigService;

    @Resource
    private IIndexParamsService indexParamsService;

    private static final String DEFAULT_RULE_STATUS = "Y";

    /* ---------- 检查项解析（P4：自有大模型路线）的配置与常量 ---------- */

    /**
     * 解析检查项时使用的大模型编码
     *
     * <p>默认值与 {@code executeRule} 里校验指标值时用的模型一致（源工程也把
     * {@code h20-DeepSeek-V32} 写在那个位置），保持"解析"与"执行"两阶段的模型一致。</p>
     */
    @Value("${agent.rule.parse-model-code:h20-DeepSeek-V32}")
    private String ruleParseModelCode;

    /** 提示词里最多列出的候选指标条数（超过则按相关性粗筛，避免提示词过长） */
    private static final int MAX_PROMPT_INDEX_COUNT = 500;

    /**
     * 检查项解析提示词（两个占位符：候选指标清单、检查项原文）
     *
     * <p><b>为什么要求模型输出这个特定结构</b>：{@code parseRule} 的后半段是按
     * {@code data.final_answer_test.final_answer} → {@code {最终结果, 指标确定}} 解析的，
     * 这是厂商智能体原有的输出契约。让自有大模型产出同结构，就能<b>复用原有消费逻辑、零改动</b>。</p>
     */
    private static final String RULE_PARSE_PROMPT_TEMPLATE =
            "你是银行贷后检查规则的解析助手。请把下面这段「检查项文本」拆解成一条可执行的规则表达式，"
                    + "并为表达式里用到的每个指标匹配出指标编号。\n\n"
                    + "【可用指标清单】（格式：指标名称 = 指标编号）\n%s\n\n"
                    + "【检查项文本】\n%s\n\n"
                    + "【输出要求】\n"
                    + "只输出一个 JSON 对象；不要输出任何解释文字，不要用 markdown 代码块包裹。结构必须严格为：\n"
                    + "{\n"
                    + "  \"最终结果\": \"用指标编号、数字与运算符组成的表达式字符串\",\n"
                    + "  \"指标确定\": { \"指标名称\": { \"指标编号\": \"对应编号\" } }\n"
                    + "}\n"
                    + "约束：\n"
                    + "1) 「指标确定」只包含同时出现在检查项文本与指标清单中的指标，指标名称用清单里的原名；\n"
                    + "2) 表达式里只允许出现指标编号、数字、以及 && || ! > < >= <= == != ( ) + - * / 这些符号；\n"
                    + "3) 若检查项文本提到的指标在清单中完全找不到，请把「最终结果」置为空字符串，"
                    + "并在 JSON 顶层额外给出 \"nofind_indicator\" 字段，值为找不到的指标名称（多个用逗号分隔）。";

    @Autowired
    private HubApiClient hubApiClient;

    @Autowired
    private final CallLlmUtil callLlmUtil;

    public List<TopicTreeVO> getTopicTreeList() {
        List<Map<String, String>> mapList = baseMapper.listTopicGroup();
        return mapList.stream()
                .map(map -> {
                    TopicTreeVO vo = new TopicTreeVO();
                    vo.setTopic1(map.get("topic1"));
                    String topic2Str = map.get("topic2_str");
                    List<String> topic2List = StringUtils.isNotBlank(topic2Str)
                            ? java.util.Arrays.asList(topic2Str.split(",")).stream().map(String::trim).collect(Collectors.toList())
                            : java.util.Collections.emptyList();
                    vo.setTopic2List(topic2List);
                    return vo;
                })
                .collect(Collectors.toList());
    }

    @lombok.Data
    public static class TopicTreeVO {
        private String topic1;
        private List<String> topic2List;
    }

    @Override
    public AgentRuleEntity saveRule(AgentRuleSaveReq req) {
        AgentRuleEntity entity = new AgentRuleEntity();
        BeanUtil.copyProperties(req, entity, true);
        if (StringUtils.isBlank(entity.getRuleStatus())) {
            entity.setRuleStatus(DEFAULT_RULE_STATUS);
        }
        entity.setUpdateTime(DateUtil.now());

        entity.setInputUser(ApiContext.getApiContextModel().getUserId());
        entity.setUpdateUser(ApiContext.getApiContextModel().getUserId());

        if (Objects.isNull(entity.getId())) {
            entity.setInputTime(DateUtil.now());
            save(entity);
            return entity;
        }

        AgentRuleEntity dbEntity = getById(entity.getId());
        if (Objects.isNull(dbEntity)) {
            throw new AgentBizException("规则不存在，保存失败！");
        }
        updateById(entity);
        return getById(entity.getId());
    }

    @Override
    public AgentRuleParseVO parseRule(AgentRuleParseReq req) {
        AgentRuleParseVO vo = new AgentRuleParseVO();
        // 迁移改造点（P4）：解析结果的来源改为「二选一」，详见 resolveParseResult 的说明。
        // 下面这段"消费解析结果"的逻辑保持源实现原样，两条路径产出的报文形状一致。
        JSONObject searchResult = resolveParseResult(req);
        JSONObject data = JSONTools.getJSONObject(searchResult, "data");

        if (data.containsKey("error_answer")) {
            JSONObject errorAnswer = JSONTools.getJSONObject(data, "error_answer");
            String finalAnswer = JSONTools.getString(errorAnswer, "final_answer");
            JSONObject finalAnswerJo = JSONObject.parseObject(finalAnswer);
            String nofindIndicator = JSONTools.getString(finalAnswerJo, "nofind_indicator");
            vo.setParsedExpression(nofindIndicator);
            vo.setParseCode("error");
            return vo;
        }
        JSONObject fakeAnswer = JSONTools.getJSONObject(data, "final_answer_test");
        String finalAnswer = JSONTools.getString(fakeAnswer, "final_answer");
        JSONObject finalAnswerJo = JSONObject.parseObject(finalAnswer);
        String finalResult = JSONTools.getString(finalAnswerJo, "最终结果");
        JSONObject indexJo = JSONTools.getJSONObject(finalAnswerJo, "指标确定");

        Map<String, String> indexMap = new HashMap<>();
        List<String> paramIdList = new ArrayList<>();
        if (StringUtils.isNotBlank(finalResult)) {
            if (indexJo != null && !indexJo.isEmpty()) {
                for (Map.Entry<String, Object> entry : indexJo.entrySet()) {
                    String metricName = entry.getKey();
                    Object valueObj = entry.getValue();

                    if (valueObj instanceof JSONObject) {
                        JSONObject metricObj = (JSONObject) valueObj;
                        String indexCode = metricObj.getString("指标编号");
                        indexMap.put(metricName, indexCode);
                        paramIdList.add(indexCode);
                    } else if (valueObj instanceof String) {
                        // 兼容模型输出的"扁平"形态：{"指标名称": "指标编号"}
                        // 模型偶尔不按契约包成 {"指标编号": "..."} 对象；不兼容会导致指标全部丢失、
                        // 表达式里的 {名称} 替换不掉，最终执行失败。
                        String indexCode = ((String) valueObj).trim();
                        indexMap.put(metricName, indexCode);
                        paramIdList.add(indexCode);
                    }
                }
            }
            String parsedExpression = finalResult;
            Map<String, String> indexNameMap = new HashMap<>();
            List<IndexParamsEntity> paramsList = indexParamsService.getParamsList(paramIdList);
            paramsList.forEach(e -> {
                indexNameMap.put(e.getParamNo(), e.getParamName());
            });
            for (Map.Entry<String, String> entry : indexMap.entrySet()) {
                parsedExpression = parsedExpression.replace(entry.getKey(), entry.getValue() != null ? "{" + entry.getValue() + "|" + indexNameMap.get(entry.getValue()) + "}" : "");
            }
            // ── 归一化兜底（P4 实测补充 2026-09-15）──
            // 上面这步是源工程既有逻辑：把「指标名称」替换成 {编号|名称}（源工程的厂商智能体输出名称）。
            // 本工程改用自有大模型后，提示词要求模型直接输出「指标编号」（更结构化、不易因名称歧义出错），
            // 于是上面会空转、表达式里留下裸编号。而下游（前端表达式展示、emptyMetricList 的 \d+ 提取）
            // 都按 {编号|名称} 这个约定格式解析，故这里把残留的裸编号补成统一格式。
            parsedExpression = normalizeMetricRefs(parsedExpression, indexMap, indexNameMap);
            // ── 表达式归一化（2026-09-16 新增）──
            // 表达式来自大模型输出，模型会带出各种"非标准但常见"的写法：全角标点、数学符号 ≥≤≠、
            // 大写的 AND/OR/NOT、单个等号、行尾注释…… 任何一个都会让 executeRule 时**整个表达式编译失败**
            // （QLCompileException）。在此处归一有两个好处：
            //   ① 前端展示的与后续回传执行的表达式是同一份，不会"界面看着对、执行却报错"；
            //   ② 下面的 promptKey（md5）基于归一后的表达式计算，缓存口径与实际执行一致。
            // ⚠️ 副作用：promptKey 因此变化，旧 AI 分析缓存会失效并重新生成（旧缓存本就基于脏表达式）。
            parsedExpression = QLExpressUtil.normalizeExpression(parsedExpression);
            vo.setParsedExpression(parsedExpression);
            JSONObject specialIndicatorResult = JSONTools.getJSONObject(finalAnswerJo, "special_indicator_result");
            if (specialIndicatorResult != null && specialIndicatorResult.size() > 0) {
                JSONObject newSpecialIndicator = new JSONObject();
                specialIndicatorResult.forEach((oldKey, val) -> {
                    String newKey = indexMap.getOrDefault(oldKey, oldKey);
                    newSpecialIndicator.put(newKey, val);
                });
                String promptKey = DigestUtil.md5Hex(parsedExpression + newSpecialIndicator);
                vo.setPromptKey(promptKey);
                if (newSpecialIndicator != null && !newSpecialIndicator.isEmpty()) {
                    AgentRulePrompt prompt = new AgentRulePrompt();
                    prompt.setKey(promptKey);
                    prompt.setPrompt(newSpecialIndicator.toJSONString());
                    baseMapper.replacePrompt(prompt);
                }
            }
        } else {
            vo.setParsedExpression(StringUtils.EMPTY);
        }

        return vo;
    }

    /* ==================== 检查项解析：结果来源（P4） ==================== */

    /**
     * 取得「规则解析结果」报文
     *
     * <p>源工程只有一条路径：调用厂商的「审查规则解析智能体」，且凭据与地址都硬编码在
     * {@code AgentSearchApiClient} 里（JWT 指向厂商预研账号）——
     * 这意味着<b>业务规则文本会离开行内环境</b>。</p>
     *
     * <p>本工程（P4）改为二选一：</p>
     * <ol>
     *   <li>配置了 {@code agent.agent-search.url} → 仍走厂商智能体（保留回退能力）；</li>
     *   <li><b>默认</b> → 走本工程自有大模型：用「候选指标清单 + 检查项文本」构造提示词，
     *       让模型直接产出与厂商同形状的 JSON。</li>
     * </ol>
     *
     * <p><b>为什么让自有大模型"复刻"厂商的输出格式</b>：{@link #parseRule} 的后半段
     * （表达式回填、指标编号替换、特殊指标 prompt 落库）是源工程既有逻辑，
     * 让它零改动、只替换"答案来源"，是风险最低的改法——出问题时只需比对两条路径的报文差异。</p>
     */
    private JSONObject resolveParseResult(AgentRuleParseReq req) {
        if (agentSearchApiClient.isConfigured()) {
            log.info("检查项解析：走外部智能体（agent.agent-search.url 已配置）");
            JSONObject jo = new JSONObject();
            jo.put("session_no", UUID.randomUUID().toString());
            jo.put("agent_id", "审查规则解析智能体");
            jo.put("role_name", "客户经理");
            jo.put("version", "hatch");
            jo.put("stream", false);
            jo.put("no_interrupt", true);
            jo.put("input", req.getRuleText());
            return agentSearchApiClient.execute(jo);
        }
        log.info("检查项解析：走本工程自有大模型，model={}", ruleParseModelCode);
        return parseByLargeModel(req);
    }

    /**
     * 用自有大模型解析检查项
     *
     * <p>返回报文刻意做成与厂商同形状：{@code {data: {final_answer_test: {final_answer: "<JSON串>"}}}}，
     * 使 {@link #parseRule} 的后续逻辑无需区分两条路径。</p>
     *
     * <p>调用方式对齐本类 {@code executeRule} 里已有的非流式大模型调用
     * （{@code stream=false} + {@code finishFlag=false} + {@code returnFlag=true}），
     * 返回值是 {@code JSONObject}，正文在 {@code content} 字段。</p>
     */
    private JSONObject parseByLargeModel(AgentRuleParseReq req) {
        String ruleText = req.getRuleText();
        if (StringUtils.isBlank(ruleText)) {
            throw new AgentBizException("检查项文本不能为空");
        }

        List<IndexParamsEntity> candidates = pickCandidateIndexes(ruleText);
        if (CollectionUtils.isEmpty(candidates)) {
            throw new AgentBizException("指标库为空，无法解析检查项。请先在「指标配置」里维护指标后再试。");
        }
        String indexList = candidates.stream()
                .filter(e -> StringUtils.isNotBlank(e.getParamNo()))
                .map(e -> StringUtils.defaultString(e.getParamName()) + " = " + e.getParamNo())
                .collect(Collectors.joining("\n"));

        String prompt = String.format(RULE_PARSE_PROMPT_TEMPLATE, indexList, ruleText);

        JSONObject param = new JSONObject();
        param.put("prompt", prompt);
        param.put("large_model_code", ruleParseModelCode);
        param.put("stream", false);
        HashMap<String, Object> kwargs = Maps.newHashMap();
        kwargs.put("enable_thinking", false);
        kwargs.put("thinking", false);
        param.put("chat_template_kwargs", kwargs);
        param.put("enable_thinking", false);

        // 非流式调用同样需要一个 SseEmitter 实例（CallLlmUtil 内部会 complete 它），
        // 与 executeRule 里的做法一致；超时 0 表示不设上限。
        SseEmitter emitter = new SseEmitter(0L);
        Object result = callLlmUtil.callLlm(param, emitter, false, true, false);
        String content = result instanceof JSONObject ? JSONTools.getString((JSONObject) result, "content") : null;
        if (StringUtils.isBlank(content)) {
            throw new AgentBizException("检查项解析失败：大模型未返回内容");
        }

        // 模型可能仍带上 <think> 块或 markdown 围栏，剥掉后再解析
        String json = extractJsonObject(cleanThinkBlock(content));
        JSONObject modelResult;
        try {
            modelResult = JSONObject.parseObject(json);
        } catch (Exception e) {
            log.error("检查项解析：模型输出不是合法 JSON，原文={}", content);
            throw new AgentBizException("检查项解析失败：大模型返回的内容不是合法 JSON");
        }
        if (modelResult == null) {
            throw new AgentBizException("检查项解析失败：大模型返回内容为空");
        }

        JSONObject answer = new JSONObject();
        answer.put("final_answer", modelResult.toJSONString());
        JSONObject data = new JSONObject();
        data.put("final_answer_test", answer);
        JSONObject wrapper = new JSONObject();
        wrapper.put("data", data);
        return wrapper;
    }

    /**
     * 从指标库里挑出「可能被这段检查项用到」的候选指标
     *
     * <p>条数在阈值内就全量给模型（最准）；超过阈值时按<b>指标名与检查项文本的
     * 2-gram 重合数</b>排序取前 {@link #MAX_PROMPT_INDEX_COUNT} 个。</p>
     *
     * <p>这么做的原因：提示词长度有上限，把全量指标塞进去既慢又容易被截断。
     * 若后续指标规模继续增长，建议把这段粗筛换成向量检索（指标名向量 + 检查项向量）。</p>
     */
    private List<IndexParamsEntity> pickCandidateIndexes(String ruleText) {
        List<IndexParamsEntity> all = indexParamsService.list();
        if (CollectionUtils.isEmpty(all)) {
            return Collections.emptyList();
        }
        if (all.size() <= MAX_PROMPT_INDEX_COUNT) {
            return all;
        }
        Set<String> bigrams = new HashSet<>();
        for (int i = 0; i + 1 < ruleText.length(); i++) {
            bigrams.add(ruleText.substring(i, i + 2));
        }
        return all.stream()
                .sorted(Comparator.comparingInt((IndexParamsEntity e) -> -bigramHitCount(e.getParamName(), bigrams)))
                .limit(MAX_PROMPT_INDEX_COUNT)
                .collect(Collectors.toList());
    }

    /** name 与候选文本的 2-gram 重合个数（粗相关性度量，仅用于排序） */
    private static int bigramHitCount(String name, Set<String> bigrams) {
        if (StringUtils.isBlank(name)) {
            return 0;
        }
        int hit = 0;
        for (int i = 0; i + 1 < name.length(); i++) {
            if (bigrams.contains(name.substring(i, i + 2))) {
                hit++;
            }
        }
        return hit;
    }

    /**
     * 从大模型输出里截出 JSON 对象
     *
     * <p>模型常见三种包装：裸 JSON、```json 围栏、前后夹带说明文字。
     * 这里按「先去围栏 → 取第一个 { 到最后一个 }」处理。</p>
     */
    private static String extractJsonObject(String text) {
        if (StringUtils.isBlank(text)) {
            return "";
        }
        String t = text.trim();
        if (t.startsWith("```")) {
            int firstNewline = t.indexOf('\n');
            int lastFence = t.lastIndexOf("```");
            if (firstNewline > 0 && lastFence > firstNewline) {
                t = t.substring(firstNewline + 1, lastFence).trim();
            }
        }
        int start = t.indexOf('{');
        int end = t.lastIndexOf('}');
        if (start >= 0 && end > start) {
            return t.substring(start, end + 1);
        }
        return t;
    }

    @Override
    public AgentRuleExecuteVO executeRule(AgentRuleExecuteReq req) {
        String parsedExpression = req.getParsedExpression();
        if (StringUtils.isBlank(parsedExpression)) {
            throw new AgentBizException("表达式原文不能为空");
        }
        // 入参名归一（兼容旧写法）—— 规则执行的**唯一漏斗**，在这里兜一层，
        // 任何调用方（含将来的内部调用）都不必关心上游传的是 reportno 还是 reportNo。
        AgentParamNames.normalizeInPlace(req.getRequestParams());
        List<String> paramIdList = emptyMetricList(parsedExpression);
        List<IndexParamsEntity> paramsList = indexParamsService.getParamsList(paramIdList);

        for (int i = 0; i < paramsList.size(); i++) {
            IndexParamsEntity entity = paramsList.get(i);
            log.info("第" + (i + 1) + "条数据：" + entity);
        }

        Map<String, Object> indexValueMap = knowledgeBaseConfigService.getIndexValueMap("", req.getRequestParams(), paramIdList, null);
        long end1 = System.currentTimeMillis();

        String promptKey = req.getPromptKey();
        if (StringUtils.isNotBlank(promptKey)) {
            AgentRulePrompt agentRulePrompt = baseMapper.getPromptByKey(promptKey);
            JSONObject specialIndicatorResult = JSONObject.parseObject(agentRulePrompt.getPrompt());
            SseEmitter emitter = new SseEmitter(0L);
            if (specialIndicatorResult != null && !specialIndicatorResult.isEmpty()) {
                for (String key : specialIndicatorResult.keySet()) {
                    String originText = specialIndicatorResult.getString(key);
                    if (originText == null || !originText.contains("&&$$data&&$$")) {
                        continue;
                    }

                    Object realVal = indexValueMap.get(key);
                    if (realVal == null) {
                        continue;
                    }

                    String newText = originText.replace("&&$$data&&$$", String.valueOf(realVal));
                    if (StringUtils.isBlank(newText)) {
                        continue;
                    }

                    JSONObject param = new JSONObject();
                    param.put("prompt", newText);
                    param.put("large_model_code", "h20-DeepSeek-V32");
                    param.put("stream", false);
                    HashMap<String, Object> kwargsMap = Maps.newHashMap();
                    kwargsMap.put("enable_thinking", false);
                    kwargsMap.put("thinking", false);
                    param.put("chat_template_kwargs", kwargsMap);
                    param.put("enable_thinking", false);
                    Object o = callLlmUtil.callLlm(param, emitter, false, true, false);
                    JSONObject callLlJo = (JSONObject) o;
                    String content = JSONTools.getString(callLlJo, "content");
                    if (StringUtils.isNotBlank(content)) {
                        indexValueMap.put(key, cleanThinkBlock(content));
                    }

                }
            }
            long end2 = System.currentTimeMillis();
            log.info("执行表达式，规则名称为:{} 调用大模型获取指标值耗时{}", req.getRuleCode(), end2 - end1);
        }


        Map<String, Object> rawDataSnapshot = new HashMap<>(indexValueMap);

        /*
         * 🔴 「未取到值」的指标数必须在**默认值兜底之前**统计（2026-09-16 新增）。
         *
         * 为什么重要：企业名（entName）只是一个普通入参，后端**不校验企业是否存在**。
         * 填一个不存在的企业名 → SQL 照常执行但返回 0 行 → 这些指标全部没有值。
         * 而下面的默认值兜底会把空值换成 default_value，表达式于是在这些"假数据"上算出
         * 命中/未命中，前端还会照常触发 AI 分析 —— 现象就是"随便输个 aaaaa 也能命中"。
         * 统计真实缺失数并回给前端，让这件事**可见**。
         */
        int missingValueCount = 0;
        for (IndexParamsEntity entity : paramsList) {
            if (isValueEmpty(rawDataSnapshot.get(entity.getParamNo()))) {
                missingValueCount++;
            }
        }

        List<AgentRuleMetricVO> matchedMetrics = paramsList.stream()
                .map(param -> {
                    AgentRuleMetricVO vo = new AgentRuleMetricVO();
                    vo.setIndexCode(param.getParamNo());
                    vo.setIndexName(param.getParamName());
                    vo.setActualValue(String.valueOf(rawDataSnapshot.getOrDefault(param.getParamNo(), "")));
                    log.info("指标编号为:{} " + param.getParamNo() + "=====:" + vo.getActualValue());
                    vo.setDataUnit(param.getDataUnit());
                    return vo;
                })
                .collect(java.util.stream.Collectors.toList());
        if (CollectionUtils.isNotEmpty(paramsList)) {
            for (IndexParamsEntity entity : paramsList) {
                String paramNo = entity.getParamNo();
                String defaultValue = entity.getDefaultValue();
                // 默认值为空直接跳过
                if (StringUtils.isBlank(defaultValue)) {
                    continue;
                }
                if (isValueEmpty(indexValueMap.get(paramNo))) {
                    indexValueMap.put(paramNo, defaultValue);
                }
                log.info("处理后指标编号为:{} " + paramNo + "=====:" + indexValueMap.get(paramNo));

            }
        }
        String factExpression = "";
        if (StringUtils.isNotBlank(req.getFactAnalysis())) {
            factExpression = QLExpressUtil.buildCalculationProcess(req.getFactAnalysis(), indexValueMap);
        }
        /*
         * 🔴 用严格版执行（2026-09-16 改）：`QLExpressUtil.execute` 会把任何异常吞掉并 return null，
         * 于是"表达式根本没算成"和"算出来是 false"在返回体里长得一模一样 ——
         * 前端只能显示"未命中"，把一个**执行失败**伪装成业务结论。
         *
         * 实测：企业名不存在 → 指标值全是空串 → 表达式被替换成 `(''>''-'')`（字符串做减法）
         * → QLBizException → 被吞成 null → 界面显示"未命中"。这不科学，所以显式区分。
         */
        Object result;
        boolean executeFailed = false;
        try {
            result = QLExpressUtil.executeStrict(parsedExpression, indexValueMap);
        } catch (QLExpressUtil.ExprExecuteException e) {
            executeFailed = true;
            result = null;
            // 日志带上完整上下文：规则、指标覆盖率、替换后的表达式、原始堆栈
            log.error("规则[{}]表达式执行失败（涉及指标 {} 个，其中 {} 个未取到值），转换后表达式：{}",
                    req.getRuleCode(), paramsList.size(), missingValueCount, e.getRenderedExpression(), e);
        }
        long end3 = System.currentTimeMillis();
        log.info("执行表达式，规则名称为:{} 计算QL表达式耗时{}", req.getName(), end3 - end1);
        AgentRuleExecuteVO vo = new AgentRuleExecuteVO();
        vo.setResultStatus(result);
        vo.setMatchedMetrics(matchedMetrics);
        vo.setFactExpression(factExpression);
        vo.setExecuteFailed(executeFailed);
        vo.setMissingValueCount(missingValueCount);
        vo.setTotalMetricCount(paramsList.size());
        return vo;
    }

    /**
     * 判断取数结果是否"为空"（null / 空白字符串 / 空数组）
     *
     * <p>与 `executeRule` 里默认值兜底原本用的判断完全一致，抽出来是为了**同一口径**：
     * 统计"未取到值"和"要不要用默认值顶上"必须用同一个判空规则，否则两边数字对不上。
     */
    private boolean isValueEmpty(Object val) {
        if (val == null) {
            return true;
        }
        if (val instanceof String) {
            return StringUtils.isBlank((String) val);
        }
        if (val instanceof JSONArray) {
            return ((JSONArray) val).isEmpty();
        }
        return StringUtils.isBlank(String.valueOf(val));
    }

    @Override
    public ListResult<?> getEnts(JSONObject req) {
        HubApiClient.ApiResult result = hubApiClient.callS1101("R11119", req);
        if (!result.isSuccess()) {
            return new ListResult<>(0, 0);
        }

        return new ListResult<>(result.getDatas());
    }

    @Override
    public AgentRuleEntity getRule(String ruleCode) {
        if (StringUtils.isBlank(ruleCode)) {
            return null;
        }
        LambdaQueryWrapper<AgentRuleEntity> wrapper = Wrappers.lambdaQuery(AgentRuleEntity.class)
                .eq(AgentRuleEntity::getRuleCode, ruleCode);
        return baseMapper.selectOne(wrapper);
    }

    @Override
    public AgentResult<?> getRuleTreeByTopic(String keyname) {
        LambdaQueryWrapper<AgentRuleEntity> wrapper = Wrappers.lambdaQuery(AgentRuleEntity.class)
                .eq(AgentRuleEntity::getRuleStatus, "Y")
                .orderByAsc(AgentRuleEntity::getTopic1, AgentRuleEntity::getTopic2, AgentRuleEntity::getRuleCode);

        // 模糊检索条件
        if (keyname != null && !StringUtils.isBlank(keyname)) {
            String likeVal = "%" + keyname.trim() + "%";
            wrapper.and(w -> w.like(AgentRuleEntity::getRuleCode, likeVal).or().like(AgentRuleEntity::getRuleName, likeVal));
        }

        List<AgentRuleEntity> ruleList = baseMapper.selectList(wrapper);
        // 过滤空主题脏数据
        ruleList = ruleList.stream()
                .filter(e -> e.getTopic1() != null && !StringUtils.isBlank(e.getTopic1()))
                .filter(e -> e.getTopic2() != null && !StringUtils.isBlank(e.getTopic2()))
                .collect(Collectors.toList());

        Map<String, Map<String, List<Map<String, Object>>>> tempGroup = new LinkedHashMap<>();
        for (AgentRuleEntity entity : ruleList) {
            String t1 = entity.getTopic1().trim();
            String t2 = entity.getTopic2().trim();
            String code = entity.getRuleCode().trim();
            String name = entity.getRuleName().trim();
            String ruleStructStr = entity.getRuleStruct();
            String[] split = Optional.ofNullable(ruleStructStr)
                    .filter(StringUtils::isNotBlank)
                    .map(s -> s.split(","))
                    .orElse(new String[0]);
            // 组装叶子节点
            Map<String, Object> leafItem = new LinkedHashMap<>();
            leafItem.put("ruleCode", code);
            leafItem.put("ruleName", name);
            leafItem.put("children", split);

            tempGroup.computeIfAbsent(t1, k -> new LinkedHashMap<>())
                    .computeIfAbsent(t2, k -> new ArrayList<>())
                    .add(leafItem);
        }

        // 组装树形数组
        List<Map<String, Object>> treeRoot = new ArrayList<>();
        for (Map.Entry<String, Map<String, List<Map<String, Object>>>> t1Entry : tempGroup.entrySet()) {
            Map<String, Object> level1 = new LinkedHashMap<>();
            level1.put("name", t1Entry.getKey());
            List<Map<String, Object>> level2Children = new ArrayList<>();

            for (Map.Entry<String, List<Map<String, Object>>> t2Entry : t1Entry.getValue().entrySet()) {
                Map<String, Object> level2 = new LinkedHashMap<>();
                level2.put("name", t2Entry.getKey());
                level2.put("children", t2Entry.getValue());
                level2Children.add(level2);
            }
            level1.put("children", level2Children);
            treeRoot.add(level1);
        }
        return AgentResult.OK(treeRoot);
    }


    /**
     * 把表达式里「裸露的指标编号」归一成约定的 {@code {编号|名称}} 形式。
     *
     * <h3>为什么需要</h3>
     * <p>源工程 {@link #parseRule} 的替换逻辑是「把<b>指标名称</b>换成 {@code {编号|名称}}」——
     * 因为源工程对接的厂商智能体输出的就是指标名称。本工程改用自有大模型后（P4），
     * 提示词要求模型直接输出<b>指标编号</b>（短标识符，比抄写中文名称更不易出错），
     * 于是那段替换空转，表达式里就留下裸编号。</p>
     *
     * <p>而下游全都按 {@code {编号|名称}} 解析：前端「从指标树插入」造的就是
     * {@code &&{编号|名称}}（见 {@code RuleFormModal.tsx}），后端 {@link #emptyMetricList}
     * 也用 {@code \d+} 从中提取编号。两种形态混用会让页面展示与编号提取都不一致，故统一之。</p>
     *
     * <h3>做法（按 {@code {}} 分段，不做占位符替换）</h3>
     * <p>用正则把表达式切成「{@code {...}} 片段」与「其余文本」交替，只在<b>其余文本</b>里替换编号，
     * {@code {}} 片段原样保留。这样天然避免了"把 {@code {1001|A}} 里的 1001 再套一层"的二次替换问题，
     * 也不需要引入占位符（占位符若含数字，还要担心与编号冲突）。</p>
     */
    private static String normalizeMetricRefs(String expression, Map<String, String> indexMap,
                                              Map<String, String> indexNameMap) {
        if (StringUtils.isBlank(expression) || indexMap == null || indexMap.isEmpty()) {
            return expression;
        }
        StringBuilder result = new StringBuilder();
        Matcher m = Pattern.compile("\\{[^}]*\\}").matcher(expression);
        int cursor = 0;
        while (m.find()) {
            result.append(replaceBareMetricCodes(expression.substring(cursor, m.start()), indexMap, indexNameMap));
            result.append(m.group());
            cursor = m.end();
        }
        result.append(replaceBareMetricCodes(expression.substring(cursor), indexMap, indexNameMap));
        return result.toString();
    }

    /** {@link #normalizeMetricRefs} 的子步骤：把一段无 {@code {}} 的文本里的裸编号换成 {@code {编号|名称}} */
    private static String replaceBareMetricCodes(String text, Map<String, String> indexMap,
                                                 Map<String, String> indexNameMap) {
        String out = text;
        for (Map.Entry<String, String> entry : indexMap.entrySet()) {
            String code = entry.getValue();
            if (StringUtils.isBlank(code)) {
                continue;
            }
            String name = indexNameMap.getOrDefault(code, "");
            // 用「非标识符字符」双向环视限定，避免编号被当成别的数字/标识符的一部分而误替换：
            // 例如编号 123 命中 1234、编号 12 命中阈值 120。
            // 原实现是 `out.replace(code, ...)` 无边界全局替换，会**静默改错**表达式（不报错、结果却不对）。
            out = Pattern.compile("(?<![0-9A-Za-z_])" + Pattern.quote(code) + "(?![0-9A-Za-z_])")
                    .matcher(out)
                    .replaceAll(Matcher.quoteReplacement("{" + code + "|" + name + "}"));
        }
        return out;
    }


    public static String cleanThinkBlock(String content) {
        if (content == null || !content.contains("</think>")) {
            return content;
        }
        int endIndex = content.indexOf("</think>") + "</think>".length();
        String afterThink = content.substring(endIndex);
        return afterThink.trim();
    }


    /**
     * 从表达式里提取「涉及到的指标编号」。
     *
     * <p><b>为什么优先取 {@code {编号|名称}} 里的编号</b>：表达式经 {@link #parseRule} 归一后，
     * 指标一定是 {@code {编号|名称}} 形态；而直接 {@code \d+} 全量提取会把<b>阈值与函数参数</b>
     * 也当成编号（实测 {@code ABS(9.8000)>10} 会提出 9 / 8000 / 10）。这些查库时多数会被过滤掉，
     * 但一旦某个数字恰好等于真实指标编号，就会<b>多取一次数</b>、并在"涉及指标"里多显示一条。</p>
     *
     * <p>兜底：表达式里没有任何 {@code {}} 占位符时（裸编号形态），保持原有的全量数字提取行为。</p>
     */
    public List<String> emptyMetricList(String parsedExpression) {
        List<String> idList = new ArrayList<>();
        if (parsedExpression == null || parsedExpression.trim().isEmpty()) {
            return idList;
        }

        // 1、优先：{编号|名称} 里的编号（与前端 RuleFormModal.tsx 的插入格式一致）
        Matcher placeholderMatcher = Pattern.compile("\\{(\\d+)(?:\\|[^}]*)?\\}").matcher(parsedExpression);
        while (placeholderMatcher.find()) {
            addDistinct(idList, placeholderMatcher.group(1));
        }
        if (!idList.isEmpty()) {
            return idList;
        }

        // 2、兜底：裸编号形态，按纯数字提取（保留原行为）
        Matcher matcher = Pattern.compile("\\d+").matcher(parsedExpression);
        while (matcher.find()) {
            addDistinct(idList, matcher.group());
        }
        return idList;
    }

    /** 去重添加（保持出现顺序）：同一指标只需取一次数，重复会放大 SQL 开销并干扰展示 */
    private static void addDistinct(List<String> list, String value) {
        if (!list.contains(value)) {
            list.add(value);
        }
    }
}