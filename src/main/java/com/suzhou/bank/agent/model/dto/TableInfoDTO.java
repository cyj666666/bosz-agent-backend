package com.suzhou.bank.agent.model.dto;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

@Data
@Tag(name="TableInfoDTO对象", description="动态数据源表信息")
public class TableInfoDTO {

    @Schema(description = "表名称")
    private String tableName;

    @Schema(description = "表注释")
    private String tableComment;

}
