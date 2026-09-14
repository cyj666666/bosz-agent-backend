package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.alibaba.fastjson.JSONObject;


import lombok.Data;

import javax.validation.constraints.NotNull;

@Data
@Tag(name = "KnowledgePreviewReq", description = "知识库预览请求")
public class KnowledgePreviewReq {

    @NotNull
    @Schema(description = "知识库编码")
    private String knowledgeCode;

    @NotNull
    @Schema(description = "大模型编码")
    private String largeModelCode;

    @Schema(description = "是否流式输出")
    private boolean stream = false;

    @Schema(description = "请求参数")
    private JSONObject params;
}
