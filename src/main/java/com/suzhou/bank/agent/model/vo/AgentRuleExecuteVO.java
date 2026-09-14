package com.suzhou.bank.agent.model.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

import java.util.List;

@Data
@Tag(name = "AgentRuleExecuteVO返回对象", description = "规则模拟执行返回对象")
public class AgentRuleExecuteVO {

    @Schema(description = "计算结果状态")
    private Object resultStatus;

    @Schema(description = "匹配指标列表")
    private List<AgentRuleMetricVO> matchedMetrics;

    @Schema(description = "事实分析表达式")
    private String factExpression;
}
