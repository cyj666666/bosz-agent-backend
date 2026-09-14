package com.suzhou.bank.agent.model.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;


import lombok.Data;

@Data
@Tag(name="知识库黑盒参数配置对象", description = "知识库黑盒参数配置")
public class KnowledgeBlackParamsConfigVO {

    @Schema(description = "主键ID")
    private Integer id;

    @Schema(description = "关联知识库知识库ID")
    private String relateKnowledgeId;

    @Schema(description = "参数NO")
    private String paramNo;

    @Schema(description = "参数编码")
    private String paramCode;

    @Schema(description = "参数类型")
    private String paramType;

    @Schema(description = "参数名称")
    private String paramName;

    @Schema(description = "关联数据字典ID")
    private String relateDictId;

    @Schema(description = "关联数据字典值")
    private String relateDictValue;

    @Schema(description = "关联细类参数")
    private String relateSourceParam;

    @Schema(description = "前端展示参数名称")
    private String showName;

    @Schema(description = "参数说明")
    private String paramDesc;

    @Schema(description = "黑盒输出要求")
    private String blackContentDesc;

    @Schema(description = "参数值")
    private String paramValue;

    @Schema(description = "参数状态 N无效 Y有效")
    private String paramStatus;

    @Schema(description = "排序")
    private String sortNo;

    @Schema(description = "登记日期")
    private String inputTime;

    @Schema(description = "更新日期")
    private String updateTime;
}
