package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Tag(name = "AgentRuleParseReq请求对象", description = "规则解析请求对象")
public class AgentRuleParseReq {

    @NotBlank(message = "规则原文不能为空")
    @Schema(description = "规则原文")
    private String ruleText;
}
