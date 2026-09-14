package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import com.suzhou.bank.agent.model.common.PageBaseParam;


@EqualsAndHashCode(callSuper = true)
@Data
@Tag(name = "分组下知识库prompt配置预览请求", description = "KnowledgeBasePromptViewReq")
public class KnowledgeBlackParamsConfigReq extends PageBaseParam {

    @Schema(description = "主键ID")
    private Integer id;

    @Schema(description = "关联知识库ID")
    private String relateKnowledgeId;

}
