package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;

import lombok.Data;


@Data
public class IndexMoveReq {

    @Schema(description = "分组ID")
    private String groupId;

    @Schema(description = "选则的指标编号")
    private String selectParamNo;
}
