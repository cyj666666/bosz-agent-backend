package com.suzhou.bank.agent.model.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;


import lombok.Data;

@Data
@Tag(name="index_base_group对象", description = "指标分组表")
public class IndexBaseGroupVO {

    @Schema(description = "指标分组Id")
    private String groupId;

    @Schema(description = "指标分组名称")
    private String groupName;

    @Schema(description = "父指标分组Id")
    private String parentGroupId;

    @Schema(description = "父指标分组名称")
    private String parentGroupName;

    @Schema(description = "排序")
    private String sortNo;

    @Schema(description = "指标分组状态 0无效 1有效")
    private String groupStatus;

    @Schema(description = "指标分组编码")
    private String groupValue;
}
