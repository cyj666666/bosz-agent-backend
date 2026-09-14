package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
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
 * @Description: 知识库同步任务记录表
 * @Author: jeecg-boot
 * @Date: 2026-03-04
 * @Version: V1.0
 */
@Data
@TableName("knowledge_sync_task")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "knowledge_sync_task对象", description = "知识库同步任务记录表")
public class KnowledgeSyncTaskEntity {

    /**
     * 主键id
     */
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键id")
    private java.lang.String id;
    /**
     * 同步类型：knowledge-知识库同步, index-指标同步, apiSource-API数据源同步, dataSource-SQL数据源, largeModelSource-大模型同步
     */
    @Schema(description = "同步类型：knowledge-知识库同步, index-指标同步, apiSource-API数据源同步, dataSource-SQL数据源, largeModelSource-大模型")
    private java.lang.String syncType;
    /**
     * 同步状态：new-新建任务；processing-同步中；success-同步成功；failed-同步失败；
     */
    @Schema(description = "同步状态：new-新建任务；processing-同步中；success-同步成功；failed-同步失败；")
    private java.lang.String syncStatus;
    /**
     * 同步用户ID
     */
    @Schema(description = "同步用户ID")
    private java.lang.String userId;
    /**
     * 同步用户名称
     */
    @Schema(description = "同步用户名称")
    private java.lang.String userName;
    /**
     * 创建时间
     */
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "创建时间")
    private java.lang.String inputTime;
    /**
     * 完成时间
     */
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "完成时间")
    private java.lang.String finishTime;
    /**
     * 耗时（毫秒）
     */
    @Schema(description = "耗时（毫秒）")
    private java.lang.Integer costTime;

    @TableField(exist = false)
    private String costTimeDesc;
}
