package com.suzhou.bank.agent.entity;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;


import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * @Description: 知识库黑盒参数配置表
 * @Author: jeecg-boot
 * @Date: 2025-02-20
 * @Version: V1.0
 */
@Data
@TableName("knowledge_black_params_config")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="knowledge_black_params_config对象", description = "知识库黑盒参数配置表")
public class KnowledgeBlackParamsConfigEntity {

    /**主键ID*/
    @TableId(type = IdType.AUTO)
    @Schema(description = "主键ID")
    private Integer id;
    /**关联知识库知识库ID*/
    @Schema(description = "关联知识库知识库ID")
    private String relateKnowledgeId;
    /**参数NO*/
    @Schema(description = "参数NO")
    private String paramNo;
    /**参数编码*/
    @Schema(description = "参数编码")
    private String paramCode;
    /**参数类型*/
    @Schema(description = "参数类型")
    private String paramType;
    /**参数名称*/
    @Schema(description = "参数名称")
    private String paramName;
    /**关联数据字典ID*/
    @Schema(description = "关联数据字典ID")
    private String relateDictId;
    @Schema(description = "关联数据字典值")
    private String relateDictValue;
    /**关联细类参数*/
    @Schema(description = "关联细类参数")
    private String relateSourceParam;
    /**前端展示参数名称*/
    @Schema(description = "前端展示参数名称")
    private String showName;
    /**参数说明*/
    @Schema(description = "参数说明")
    private String paramDesc;
    /**参数值*/
    @Schema(description = "参数值")
    private String paramValue;
    /**参数状态 N无效 Y有效*/
    @Schema(description = "参数状态 N无效 Y有效")
    private String paramStatus;
    /**排序*/
    @Schema(description = "排序")
    private String sortNo;
    /**登记日期*/
    @Schema(description = "登记日期")
    private String inputTime;
    /**更新日期*/
    @Schema(description = "更新日期")
    private String updateTime;
}
