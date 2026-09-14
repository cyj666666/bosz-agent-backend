package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;


@Data
@Tag(name = "制度文件知识库创建请求对象", description = "DocumentKnowledgeReq")
public class DocumentKnowledgeReq {

    @Schema(description = "制度文件Id")
    private String documentId;

    @Schema(description = "制度文件知识库分组编码")
    private String documentName;

    @Schema(description = "规则ID")
    private String ruleId;
}
