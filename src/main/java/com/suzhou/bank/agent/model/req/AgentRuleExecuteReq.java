package com.suzhou.bank.agent.model.req;

import com.alibaba.fastjson.JSONObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

@Data
@Tag(name = "AgentRuleExecuteReq请求对象", description = "规则模拟执行请求对象")
public class AgentRuleExecuteReq {

    @Schema(description = "请求参数")
    private JSONObject requestParams;

    @Schema(description = "规则Code")
    private String ruleCode;

    @Schema(description = "解析逻辑表达式")
    private String parsedExpression;

    @Schema(description = "模糊名称")
    private String name;

    @Schema(description = "规则id")
    private int id;

    @Schema(description = "规则状态")
    private String ruleStatus;

    @Schema(description = "提示词Key")
    private String promptKey;

    @Schema(description = "事实分析")
    private String factAnalysis;
}
