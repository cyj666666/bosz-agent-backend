package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.springframework.format.annotation.DateTimeFormat;

/**
 * @Description: 知识库关联参数集版本记录表
 * @Author: jeecg-boot
 * @Date: 2026-03-04
 * @Version: V1.0
 */
@Data
@TableName("knowledge_relate_input_param_version")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "knowledge_relate_input_param_version对象", description = "知识库关联参数集版本记录表")
public class KnowledgeRelateInputParamVersionEntity {

    /**
     * 主键ID
     */
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键ID")
    private java.lang.String id;
    /**
     * 知识库ID
     */
    @Schema(description = "知识库ID")
    private java.lang.String knowledgeId;
    /**
     * 版本号
     */
    @Schema(description = "版本号")
    private java.lang.String versionNo;
    /**
     * 参数集
     */
    @Schema(description = "参数集")
    private java.lang.String inputParam;
    /**
     * 参数集名称
     */
    @Schema(description = "参数集名称")
    private java.lang.String inputParamName;
    /**
     * 创建时间
     */
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "创建时间")
    private java.util.Date inputTime;
    /**
     * 更新时间
     */
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "更新时间")
    private java.util.Date updateTime;
}
