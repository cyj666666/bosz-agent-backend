package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Tag(name = "AgentRuleSaveReq请求对象", description = "规则保存请求对象")
public class AgentRuleSaveReq {

    @Schema(description = "规则ID，新增时为空")
    private Integer id;

    @Schema(description = "规则Code")
    private String ruleCode;

    @NotBlank(message = "规则名称不能为空")
    @Schema(description = "规则名称")
    private String ruleName;

    @NotBlank(message = "规则原文不能为空")
    @Schema(description = "规则原文")
    private String ruleText;

    @Schema(description = "一级主题")
    private String topic1;

    @Schema(description = "二级主题")
    private String topic2;

    @Schema(description = "解析逻辑表达式")
    private String parsedExpression;

    @Schema(description = "阈值设定")
    private String thresholdConfig;

    @Schema(description = "风险释义")
    private String riskRemark;

    @Schema(description = "处置意见")
    private String disposalAdvice;

    @Schema(description = "补充分析")
    private String additionalAnalysis;

    @Schema(description = "补充分析名称")
    private String additionalAnalysisName;

    @Schema(description = "规则状态 Y有效 N无效")
    private String ruleStatus;

    @Schema(description = "提示词key")
    private String promptKey;

    @Schema(description = "事实分析")
    private String factAnalysis;

    @Schema(description = "请求参数")
    private String requestParams;
}
