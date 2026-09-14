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
 * @Description: 知识库同步任务异常记录表
 * @Author: jeecg-boot
 * @Date: 2026-03-04
 * @Version: V1.0
 */
@Data
@TableName("knowledge_sync_task_exception_record")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "knowledge_sync_task_exception_record对象", description = "知识库同步任务异常记录表")
public class KnowledgeSyncTaskExceptionRecordEntity {

    /**
     * 主键id
     */
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键id")
    private java.lang.String id;
    /**
     * 任务id
     */
    @Schema(description = "任务id")
    private java.lang.String taskId;
    /**
     * 异常阶段：init-数据查询阶段；knowledge-知识库同步阶段；knowledge_relate_index-知识库同步关联指标阶段；knowledge_black_params-知识库同步黑盒参数阶段；knowledge_input_param-知识库同步参数集阶段；knowledge_group-知识库分组同步阶段；index-指标同步阶段；index_group-指标分组同步阶段；source-数据源同步阶段；large_model_source-同步大模型阶段；
     */
    @Schema(description = "异常阶段：init-数据查询阶段；knowledge-知识库同步阶段；knowledge_relate_index-知识库同步关联指标阶段；knowledge_black_params-知识库同步黑盒参数阶段；knowledge_input_param-知识库同步参数集阶段；knowledge_group-知识库分组同步阶段；index-指标同步阶段；index_group-指标分组同步阶段；source-数据源同步阶段；large_model_source-同步大模型阶段；")
    private java.lang.String exceptionStage;
    /**
     * 创建时间
     */
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "创建时间")
    private java.util.Date inputTime;
    /**
     * 失败原因
     */
    @Schema(description = "失败原因")
    private java.lang.String failReason;
}
