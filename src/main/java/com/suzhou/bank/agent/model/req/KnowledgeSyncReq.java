package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import lombok.Data;

import java.util.List;

@Tag(name = "知识库同步请求参数")
@Data
public class KnowledgeSyncReq {

    @NotBlank
    @Schema(description = "同步类型", allowableValues = {"knowledge", "index", "apiSource", "dataSource", "largeModelSource"})
    private String syncType;

    @NotEmpty
    @Schema(description = "同步ID列表")
    private List<String> syncIdList;

}
