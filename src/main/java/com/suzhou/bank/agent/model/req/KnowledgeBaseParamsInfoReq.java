package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;


@Data
@Tag(name = "参数信息更新/删除对象", description = "KnowledgeBaseParamsInfoReq")
public class KnowledgeBaseParamsInfoReq {
    private static final long serialVersionUID = 1L;

    @Schema(description = "参数流水号")
    private String paramId;
}
