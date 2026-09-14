package com.suzhou.bank.agent.model.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;


import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="KnowledgeInfoVO对象", description = "应用空间关联知识库信息表")
public class KnowledgeInfoVO {

    @Schema(description = "一级知识库字典码值")
    private String labelDictCode1;

    @Schema(description = "二级知识库字典码值")
    private String labelDictCode2;

    @Schema(description = "三级知识库字典码值")
    private String labelDictCode3;

    @Schema(description = "四级知识库字典码值")
    private String labelDictCode4;

    @Schema(description = "一级知识库码值")
    private String labelCodeLevel1;

    @Schema(description = "二级知识库码值")
    private String labelCodeLevel2;

    @Schema(description = "三级知识库码值")
    private String labelCodeLevel3;

    @Schema(description = "四级知识库码值")
    private String labelCodeLevel4;

    @Schema(description = "一级知识库名")
    private String labelNameLevel1;

    @Schema(description = "二级知识库名")
    private String labelNameLevel2;

    @Schema(description = "三级知识库名")
    private String labelNameLevel3;

    @Schema(description = "四级知识库名")
    private String labelNameLevel4;
}
