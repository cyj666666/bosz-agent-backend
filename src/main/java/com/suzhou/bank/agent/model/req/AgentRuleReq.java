package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

import java.util.List;

@Data
@Tag(name = "AgentRuleExecuteReq请求对象", description = "规则模拟执行请求对象")
public class AgentRuleReq {

    @Schema(description = "规则id")
    private int id;

    @Schema(description = "规则状态")
    private String ruleStatus;

    @Schema(description = "规则名称")
    private String ruleName;

    @Schema(description = "规则Code")
    private String ruleCode;

    @Schema(description = "更新时间-起始日期(仅传年月日，后台自动补00:00:00)")
    private String startTime;

    @Schema(description = "更新时间-结束日期(仅传年月日，后台自动补23:59:59)")
    private String endTime;

    private List<TopicPairDTO> topicPairList;

    private int pageIndex =1;

    private int pageSize =10;

    @Data
    public static class TopicPairDTO {
        private String topic1; //一级主题
        private String topic2; //二级主题
    }
}
