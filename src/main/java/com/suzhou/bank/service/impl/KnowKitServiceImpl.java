package com.suzhou.bank.service.impl;
import com.alibaba.fastjson2.JSON;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.suzhou.bank.config.KnowKitConfig;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.mapper.*;
import com.suzhou.bank.service.knowkit.KnowKitService;
import com.suzhou.bank.service.knowledge.KnowledgeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import java.util.*;
@Slf4j @Service @RequiredArgsConstructor
public class KnowKitServiceImpl implements KnowKitService {
    private final KnowKitConfig kkConfig;
    private final KnowKitTaskMapper taskMapper;
    private final IndicatorDataMapper indicatorMapper;
    private final TextDataMapper textMapper;
    private final KnowledgeService knowledgeService;
    @Override public KnowKitTask submitAnalysis(Long customerId, List<String> scenarioTags) {
        log.info("KnowKit分析开始, customerId={}, scenarioTags={}", customerId, scenarioTags);

        List<IndicatorData> indicators = indicatorMapper.selectList(
            new LambdaQueryWrapper<IndicatorData>().eq(IndicatorData::getCustomerId, customerId));
        List<TextData> texts = textMapper.selectList(
            new LambdaQueryWrapper<TextData>().eq(TextData::getCustomerId, customerId));
        List<KnowledgeRule> rules = knowledgeService.matchRules(scenarioTags);

        log.info("KnowKit数据组装完毕, customerId={}, indicatorCount={}, textCount={}, ruleCount={}",
            customerId, indicators.size(), texts.size(), rules.size());

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("customerId", customerId);
        req.put("scenarioTags", scenarioTags);
        req.put("data", new HashMap<String, Object>() {{ put("indicators", indicators); put("texts", texts); }});
        req.put("rules", rules);

        KnowKitTask task = new KnowKitTask();
        task.setCustomerId(customerId);
        task.setScenarioTags(JSON.toJSONString(scenarioTags));
        Map<String, Object> requestMeta = new HashMap<>();
        requestMeta.put("customerId", customerId);
        requestMeta.put("scenarioTags", scenarioTags);
        task.setRequestJson(JSON.toJSONString(requestMeta));
        task.setStatus("PENDING");
        task.setResponseJson(null);
        task.setCreatedAt(new Date());
        taskMapper.insert(task);

        log.info("KnowKit任务已创建, taskId={}, customerId={}, status={}", task.getId(), customerId, task.getStatus());
        return task;
    }
    @Override public KnowKitTask getTaskResult(Long id) { return taskMapper.selectById(id); }
    @Override public KnowKitTask retryTask(Long id) {
        log.info("KnowKit任务重试, taskId={}", id);
        KnowKitTask t = taskMapper.selectById(id);
        if (t != null) {
            t.setStatus("PENDING");
            t.setErrorMsg(null);
            taskMapper.updateById(t);
            log.info("KnowKit任务已重置为PENDING, taskId={}", id);
        }
        return t;
    }
}
