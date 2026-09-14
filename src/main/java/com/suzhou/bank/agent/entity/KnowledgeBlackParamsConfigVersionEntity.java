package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * @Description: 知识库黑盒参数配置版本记录表
 * @Author: jeecg-boot
 * @Date: 2026-03-04
 * @Version: V1.0
 */
@Data
@TableName("knowledge_black_params_config_version")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "knowledge_black_params_config_version对象", description = "知识库黑盒参数配置版本记录表")
public class KnowledgeBlackParamsConfigVersionEntity {

    /**
     * 主键ID
     */
    @TableId(type = IdType.AUTO)
    @Schema(description = "主键ID")
    private java.lang.Integer id;
    /**
     * 关联知识库ID
     */
    @Schema(description = "关联知识库ID")
    private java.lang.String relateKnowledgeId;
    /**
     * 版本号
     */
    @Schema(description = "版本号")
    private java.lang.String versionNo;
    /**
     * 关联参数ID
     */
    @Schema(description = "关联参数ID")
    private java.lang.String paramNo;
    /**
     * 参数编码
     */
    @Schema(description = "参数编码")
    private java.lang.String paramCode;
    /**
     * 参数类型
     */
    @Schema(description = "参数类型")
    private java.lang.String paramType;
    /**
     * 参数名称
     */
    @Schema(description = "参数名称")
    private java.lang.String paramName;
    /**
     * 参数说明
     */
    @Schema(description = "参数说明")
    private java.lang.String paramDesc;
    /**
     * 参数值
     */
    @Schema(description = "参数值")
    private java.lang.String paramValue;
    /**
     * 参数状态 N无效 Y有效
     */
    @Schema(description = "参数状态 N无效 Y有效")
    private java.lang.String paramStatus;
    /**
     * 关联数据字典ID
     */
    @Schema(description = "关联数据字典ID")
    private java.lang.String relateDictId;
    /**
     * 关联细类参数
     */
    @Schema(description = "关联细类参数")
    private java.lang.String relateSourceParam;
    /**
     * 关联细类参数编码
     */
    @Schema(description = "关联细类参数编码")
    private java.lang.String relateParamCode;
    /**
     * 关联细类参数名称
     */
    @Schema(description = "关联细类参数名称")
    private java.lang.String relateParamName;
    /**
     * 前端展示参数名称
     */
    @Schema(description = "前端展示参数名称")
    private java.lang.String showName;
    /**
     * 排序
     */
    @Schema(description = "排序")
    private java.lang.String sortNo;
    /**
     * 登记日期
     */
    @Schema(description = "登记日期")
    private java.lang.String inputTime;
    /**
     * 更新日期
     */
    @Schema(description = "更新日期")
    private java.lang.String updateTime;
    /**
     * 关联数据字段值
     */
    @Schema(description = "关联数据字段值")
    private java.lang.String relateDictValue;
}
