package com.suzhou.bank.agent.model.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;


import lombok.Data;

import java.util.List;

@Data
@Tag(name="知识库黑盒参数配置对象", description = "知识库黑盒参数配置")
public class KnowledgeBlackConfigSaveVO {

    @Schema(description = "主键ID")
    private List<KnowledgeBlackParamsConfigVO> blackParamsConfigVOList;

    @Schema(description = "黑盒模型编码")
    private String blackModelCode;

    @Schema(description = "黑盒输出要求")
    private String blackContentDesc;

    @Schema(description = "关联知识库知识库ID")
    private String relateKnowledgeId;
}
