package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;


@Data
@Tag(name = "知识库分组请求对象", description = "KnowledgeBaseGroupReq")
public class KnowledgeBaseGroupReq extends PageBaseParam {

    @Schema(description = "知识库分组Id")
    private String groupId;

    @Schema(description = "知识库分组编码")
    private String groupValue;

    @Schema(description = "知识库分组名称")
    private String groupName;

    @Schema(description = "父知识库分组Id")
    private String parentGroupId;

    @Schema(description = "知识库分组类型")
    private String groupType;

    @Schema(description = "父知识库分组名称")
    private String parentGroupName;
}
