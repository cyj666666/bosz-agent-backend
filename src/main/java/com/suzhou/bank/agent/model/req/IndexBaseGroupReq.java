package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

@Data
@Tag(name = "index_base_group对象", description = "指标分组表")
public class IndexBaseGroupReq {

    @Schema(description = "指标分组Id")
    private String groupId;

    @Schema(description = "指标分组名称")
    private String groupName;

    @Schema(description = "指标分组编码")
    private String groupValue;

    @Schema(description = "指标名称")
    private String paramName;

    @Schema(description = "指标编号")
    private String paramId;
}
