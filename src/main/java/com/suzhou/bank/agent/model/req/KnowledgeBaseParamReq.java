package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

@Data
@Tag(name="KnowledgeBaseParamReq对象", description="知识库参数查询对象")
public class KnowledgeBaseParamReq extends PageBaseParam {

    @Schema(description = "分组ID")
    private String groupId;

    @Schema(description = "父级分组ID")
    private String parentGroupId;

    @Schema(description = "知识库名称")
    private String paramName;

    @Schema(description = "知识库编号")
    private String paramNo;

    @Schema(description = "知识库标签")
    private String paramLabel;

    @Schema(description = "父级知识库ID")
    private String parentParamId;

    @Schema(description = "知识库状态")
    private String paramStatus;

    @Schema(description = "是否在线")
    private String online;

    @Schema(description = "角色ID")
    private String roleId;

    @Schema(description = "查询关键词")
    private String keyword;
}
