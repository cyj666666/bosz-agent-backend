package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;


@Data
@TableName("knowledge_relate_input_param")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "knowledge_relate_input_param对象", description = "知识库管理数据集")
public class KnowledgeRelateInputParamEntity {

    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键ID")
    private String id;

    @Schema(description = "知识库ID")
    private String knowledgeId;

    @Schema(description = "参数集")
    private String inputParam;

    @Schema(description = "参数集名称")
    private String inputParamName;

    @Schema(description = "创建时间")
    private String inputTime;

    @Schema(description = "更新时间")
    private String updateTime;
}
