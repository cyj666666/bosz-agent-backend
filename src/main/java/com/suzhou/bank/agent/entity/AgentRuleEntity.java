package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

@Data
@TableName("agent_rule")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "AgentRuleEntity对象", description = "规则配置")
public class AgentRuleEntity {

    @TableId(type = IdType.AUTO)
    @Schema(description = "规则ID")
    private Integer id;

    @Schema(description = "规则Code")
    private String ruleCode;

    @Schema(description = "一级主题")
    private String topic1;

    @Schema(description = "二级主题")
    private String topic2;

    @Schema(description = "检查项")
    private String ruleName;

    @Schema(description = "触发条件")
    private String ruleText;

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

    @Schema(description = "解析逻辑表达式")
    private String parsedExpression;

    @Schema(description = "规则状态 Y有效 N无效")
    private String ruleStatus;

    @Schema(description = "入库时间")
    private String inputTime;

    @Schema(description = "更新时间")
    private String updateTime;

    @Schema(description = "入库人")
    private String inputUser;

    @Schema(description = "更新人")
    private String updateUser;

    @Schema(description = "提示词key")
    private String promptKey;

    @Schema(description = "输出结构")
    private String ruleStruct;

    @Schema(description = "事实分析")
    private String factAnalysis;

    @Schema(description = "规则参数")
    private String requestParams;
}
