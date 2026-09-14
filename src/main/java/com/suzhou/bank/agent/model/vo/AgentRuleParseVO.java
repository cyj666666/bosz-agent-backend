package com.suzhou.bank.agent.model.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

@Data
@Tag(name = "AgentRuleParseVO返回对象", description = "规则解析返回对象")
public class AgentRuleParseVO {

    @Schema(description = "解析逻辑表达式")
    private String parsedExpression;

    @Schema(description = "大模型提示词Key")
    private String promptKey;


    @Schema(description = "大模型提示词Key")
    private String parseCode;
}