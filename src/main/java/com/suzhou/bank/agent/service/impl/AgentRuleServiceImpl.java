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
import com.suzhou.bank.agent.util.QLExpressUtil;
import org.springframework.beans.factory.annotation.Autowired;
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
        JSONObject jo = new JSONObject();
        jo.put("session_no", UUID.randomUUID().toString());
        jo.put("agent_id", "审查规则解析智能体");
        jo.put("role_name", "客户经理");
        jo.put("version", "hatch");
        jo.put("stream", false);
        jo.put("no_interrupt", true);
        jo.put("input", req.getRuleText());
        JSONObject searchResult = agentSearchApiClient.execute(jo);
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

    @Override
    public AgentRuleExecuteVO executeRule(AgentRuleExecuteReq req) {
        String parsedExpression = req.getParsedExpression();
        if (StringUtils.isBlank(parsedExpression)) {
            throw new AgentBizException("表达式原文不能为空");
        }
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
                Object val = indexValueMap.get(paramNo);
                boolean valueIsEmpty = false;
                if (val == null) {
                    valueIsEmpty = true;
                } else if (val instanceof String) {
                    valueIsEmpty = StringUtils.isBlank((String) val);
                } else if (val instanceof JSONArray) {
                    valueIsEmpty = ((JSONArray) val).isEmpty();
                } else {
                    String strVal = String.valueOf(val);
                    valueIsEmpty = StringUtils.isBlank(strVal);
                }
                if (valueIsEmpty) {
                    indexValueMap.put(paramNo, defaultValue);
                }
                log.info("处理后指标编号为:{} " + paramNo + "=====:" + indexValueMap.get(paramNo));

            }
        }
        String factExpression = "";
        if (StringUtils.isNotBlank(req.getFactAnalysis())) {
            factExpression = QLExpressUtil.buildCalculationProcess(req.getFactAnalysis(), indexValueMap);
        }
        Object result = QLExpressUtil.execute(parsedExpression, indexValueMap);
        long end3 = System.currentTimeMillis();
        log.info("执行表达式，规则名称为:{} 计算QL表达式耗时{}", req.getName(), end3 - end1);
        AgentRuleExecuteVO vo = new AgentRuleExecuteVO();
        vo.setResultStatus(result);
        vo.setMatchedMetrics(matchedMetrics);
        vo.setFactExpression(factExpression);
        return vo;
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


    public static String cleanThinkBlock(String content) {
        if (content == null || !content.contains("</think>")) {
            return content;
        }
        int endIndex = content.indexOf("</think>") + "</think>".length();
        String afterThink = content.substring(endIndex);
        return afterThink.trim();
    }


    public List<String> emptyMetricList(String parsedExpression) {
        List<String> idList = new ArrayList<>();
        if (parsedExpression == null || parsedExpression.trim().isEmpty()) {
            return idList;
        }

        // 匹配 纯数字（指标编号）
        Pattern pattern = Pattern.compile("\\d+");
        Matcher matcher = pattern.matcher(parsedExpression);

        while (matcher.find()) {
            idList.add(matcher.group());
        }
        return idList;
    }
}