package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import com.suzhou.bank.agent.model.common.PageBaseParam;


@EqualsAndHashCode(callSuper = true)
@Data
@Tag(name="IndexParamsInfoReq对象", description="参数信息更新/删除对象")
public class IndexParamsInfoReq extends PageBaseParam {

    @Schema(description = "参数流水号")
    private String paramNo;

    @Schema(description = "关联知识库编码")
    private String relateKnowledgeCode;

    @Schema(description = "关联知识库名称")
    private String relateKnowledgeName;

    @Schema(description = "关联指标编码")
    private String relateParamNo;

    @Schema(description = "参数名称")
    private String relateParamName;

}
