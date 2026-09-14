package com.suzhou.bank.agent.model.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

@Data
@Tag(name = "AgentRuleMetricVO返回对象", description = "规则匹配指标返回对象")
public class AgentRuleMetricVO {

    @Schema(description = "指标编码")
    private String indexCode;

    @Schema(description = "指标名称")
    private String indexName;

    @Schema(description = "实际运行值")
    private String actualValue;

    @Schema(description = "数值单位")
    private String dataUnit;
}