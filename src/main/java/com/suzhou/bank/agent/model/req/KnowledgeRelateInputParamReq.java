package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;


@Data
@Tag(name = "KnowledgeRelateInputParamReq", description = "知识库管理数据集查询请求对象")
public class KnowledgeRelateInputParamReq extends PageBaseParam {

    @Schema(description = "主键ID")
    private Integer id;

    @Schema(description = "知识库ID")
    private String knowledgeId;

    @Schema(description = "参数集名称")
    private String inputParamName;
}
