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

    /**
     * 以下三个字段是**本工程新增的可观测性**（2026-09-16），源工程没有。
     *
     * <p>背景：企业名只是一个普通入参，后端**不校验企业是否存在**；企业名不存在时
     * 指标取数为空，表达式会拿空值/默认值去算，仍然得出一个"命中/未命中"的结论，
     * 甚至照常触发 AI 分析 —— 从界面上完全看不出"这次校验的数据是空的"。
     * 把"有没有取到值""表达式有没有算成"显式返回，前端才能如实提示。
     */
    @Schema(description = "表达式是否执行失败。失败时 resultStatus 为 null，**不能当作\"未命中\"**")
    private Boolean executeFailed;

    @Schema(description = "未取到值的指标数量（按企业名查不到数据时会出现）")
    private Integer missingValueCount;

    @Schema(description = "本次校验涉及的指标总数")
    private Integer totalMetricCount;
}
