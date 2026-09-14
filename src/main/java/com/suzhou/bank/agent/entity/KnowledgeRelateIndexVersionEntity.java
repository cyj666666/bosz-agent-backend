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
 * @Description: 知识库关联指标版本记录表
 * @Author: jeecg-boot
 * @Date: 2026-03-04
 * @Version: V1.0
 */
@Data
@TableName("knowledge_relate_index_version")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "knowledge_relate_index_version对象", description = "知识库关联指标版本记录表")
public class KnowledgeRelateIndexVersionEntity {

    /**
     * 主键ID
     */
    @TableId(type = IdType.AUTO)
    @Schema(description = "主键ID")
    private java.lang.Integer id;
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
     * 指标编号
     */
    @Schema(description = "指标编号")
    private java.lang.String indexNo;
    /**
     * 父级指标编号
     */
    @Schema(description = "父级指标编号")
    private java.lang.String parentIndexNo;
    /**
     * 指标名称
     */
    @Schema(description = "指标名称")
    private java.lang.String indexName;
    /**
     * 指标类型
     */
    @Schema(description = "指标类型")
    private java.lang.String indexType;
    /**
     * 关联接口服务ID
     */
    @Schema(description = "关联接口服务ID")
    private java.lang.String supplierId;
    /**
     * 关联接口编号
     */
    @Schema(description = "关联接口编号")
    private java.lang.String intfNo;
    /**
     * 添加类型 add-新增，bland-知识库绑定
     */
    @Schema(description = "添加类型 add-新增，bland-知识库绑定")
    private java.lang.String addType;
    /**
     * 是否溯源 Y：是，N：否
     */
    @Schema(description = "是否溯源 Y：是，N：否")
    private java.lang.String traceStatus;
    /**
     * 是否溯源卡片 Y：是，N：否
     */
    @Schema(description = "是否溯源卡片 Y：是，N：否")
    private java.lang.String traceCardStatus;
    /**
     * 溯源配置
     */
    @Schema(description = "溯源配置")
    private java.lang.Object traceConfig;
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
