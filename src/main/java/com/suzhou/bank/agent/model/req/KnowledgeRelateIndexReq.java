package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

import javax.validation.constraints.NotBlank;

@Data
@Tag(name = "KnowledgeRelateIndexReq", description = "知识库关联指标请求")
public class KnowledgeRelateIndexReq extends PageBaseParam {

    @NotBlank
    @Schema(description = "知识库ID")
    private String knowledgeId;

    @Schema(description = "指标编号")
    private String indexNo;

    @Schema(description = "指标名称")
    private String indexName;

    @Schema(description = "指标类型")
    private String indexType;

    @Schema(description = "是否溯源 Y：是，N：否")
    private String traceStatus;

    @Schema(description = "是否溯源卡片 Y：是，N：否")
    private String traceCardStatus;
}
