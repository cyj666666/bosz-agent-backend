package com.suzhou.bank.agent.model.common;


import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class PageBaseParam {

    @Schema(description = "页码")
    private int pageIndex = 1;

    @Schema(description = "每页大小")
    private int pageSize = 10;
}
