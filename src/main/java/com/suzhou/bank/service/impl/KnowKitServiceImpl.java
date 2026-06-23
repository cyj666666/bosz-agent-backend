package com.suzhou.bank.service.impl;

import com.alibaba.fastjson2.JSON;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.mapper.*;
import com.suzhou.bank.service.knowkit.KnowKitService;
import com.suzhou.bank.service.knowledge.KnowledgeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * Know-Kit 智能体适配服务实现（Mock 版）
 * <p>当前为模拟实现，生成逼真的分析结果用于流程联调。
 * 后续对接真实 Know-Kit API 时，仅需替换 mockResponse 方法。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class KnowKitServiceImpl implements KnowKitService {

    private final KnowKitTaskMapper taskMapper;
    private final IndicatorDataMapper indicatorMapper;
    private final TextDataMapper textMapper;
    private final KnowledgeService knowledgeService;

    /** 提交分析任务给 Know-Kit */
    @Override
    public KnowKitTask submitAnalysis(Long customerId, List<String> scenarioTags) {
        log.info("KnowKit分析开始, customerId={}, scenarioTags={}", customerId, scenarioTags);

        List<IndicatorData> indicators = indicatorMapper.selectList(
                new LambdaQueryWrapper<IndicatorData>().eq(IndicatorData::getCustomerId, customerId));
        List<TextData> texts = textMapper.selectList(
                new LambdaQueryWrapper<TextData>().eq(TextData::getCustomerId, customerId));
        List<KnowledgeRule> rules = knowledgeService.matchRules(scenarioTags);

        log.info("KnowKit数据组装完毕, customerId={}, indicatorCount={}, textCount={}, ruleCount={}",
                customerId, indicators.size(), texts.size(), rules.size());

        // 组装请求 JSON
        Map<String, Object> req = new LinkedHashMap<>();
        req.put("customerId", customerId);
        req.put("scenarioTags", scenarioTags);
        req.put("data", new HashMap<String, Object>() {{
            put("indicators", indicators);
            put("texts", texts);
        }});
        req.put("rules", rules);

        // 生成 Mock 分析结果
        Map<String, Object> mockResponse = buildMockResponse(customerId, indicators, rules, scenarioTags);

        KnowKitTask task = new KnowKitTask();
        task.setCustomerId(customerId);
        task.setScenarioTags(JSON.toJSONString(scenarioTags));
        task.setRequestJson(JSON.toJSONString(req));
        task.setStatus("SUCCESS");
        task.setResponseJson(JSON.toJSONString(mockResponse));
        task.setCreatedAt(new Date());
        task.setCompletedAt(new Date());
        taskMapper.insert(task);

        log.info("KnowKit任务已创建(Mock), taskId={}, customerId={}, riskLevel={}",
                task.getId(), customerId, mockResponse.get("overallRiskLevel"));
        return task;
    }

    /** 查询任务结果 */
    @Override
    public KnowKitTask getTaskResult(Long id) {
        return taskMapper.selectById(id);
    }

    /** 重试失败任务 */
    @Override
    public KnowKitTask retryTask(Long id) {
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

    /**
     * 生成 Mock 分析结果
     * <p>模拟 Know-Kit 大模型分析输出，后续替换为真实 API 调用。</p>
     */
    private Map<String, Object> buildMockResponse(Long customerId,
            List<IndicatorData> indicators, List<KnowledgeRule> rules, List<String> tags) {

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("taskId", "KK-" + customerId + "-" + System.currentTimeMillis());
        resp.put("overallRiskLevel", "橙色预警");
        resp.put("riskScore", 68);

        // 综合评估
        resp.put("summary", "经综合分析，该企业当前经营状况存在以下需关注的风险点："
                + "营收同比增长放缓，存货周转天数延长，应收账款账龄出现恶化趋势。"
                + "资产负债率较上期上升8个百分点，短期偿债能力承压。"
                + "此外，实际控制人涉及民间借贷纠纷，存在代偿风险。"
                + "综合评定风险等级为橙色预警，建议加强贷后监控力度，增加现场检查频次。");

        // 关键发现
        List<Map<String, String>> findings = new ArrayList<>();
        findings.add(mapOf("dimension", "财务分析", "severity", "红",
                "finding", "营收同比下降43.5%，营业成本下降幅度小于营收降幅，毛利率由18%降至11%"));
        findings.add(mapOf("dimension", "偿债能力", "severity", "红",
                "finding", "资产负债率由65%升至75%，短期借款增加2100万，对外担保触发代偿150万"));
        findings.add(mapOf("dimension", "经营环境", "severity", "橙",
                "finding", "核心客户A公司停止合作（原占营收32%），财务总监离职空窗4个月"));
        findings.add(mapOf("dimension", "用信变化", "severity", "橙",
                "finding", "他行抽贷800万，抵押物新增二顺位抵押，资金归集率持续不达标"));
        findings.add(mapOf("dimension", "司法信息", "severity", "黄",
                "finding", "实控人涉民间借贷纠纷被强制执行45万，VOCs排放超标罚款25万"));
        findings.add(mapOf("dimension", "税务状况", "severity", "黄",
                "finding", "纳税评级由B级下调至M级，实缴增值税同比-38%，收入确认方向出现反转"));
        resp.put("findings", findings);

        // 建议措施
        List<String> recommendations = new ArrayList<>();
        recommendations.add("建议将本笔贷后频率由季度调整为月度，增加现场回访频次");
        recommendations.add("要求企业提供近6个月银行流水原件，核实经营性现金流的真实性");
        recommendations.add("跟踪财务总监到岗进度，评估管理层稳定性对经营的影响");
        recommendations.add("关注核心客户流失后的新客户开拓进展及订单恢复情况");
        recommendations.add("密切监控抵押物状态及对外担保履约进展");
        resp.put("recommendations", recommendations);

        // 规则匹配信息
        resp.put("matchedRuleCount", rules.size());
        resp.put("indicatorCount", indicators.size());
        resp.put("analyzedAt", new Date().toString());

        return resp;
    }

    private Map<String, String> mapOf(String k1, String v1, String k2, String v2,
            String k3, String v3) {
        Map<String, String> m = new LinkedHashMap<>();
        m.put(k1, v1);
        m.put(k2, v2);
        m.put(k3, v3);
        return m;
    }
}
