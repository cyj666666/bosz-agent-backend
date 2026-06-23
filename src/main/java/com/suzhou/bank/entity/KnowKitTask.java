package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * Know-Kit 任务记录表（know_kit_task）
 * <p>每次调用 Know-Kit 智能体进行任务分析的任务跟踪记录，
 * 独立存储请求和响应的完整 JSON，支持重试、对比和审计。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@TableName("know_kit_task")
public class KnowKitTask {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long customerId;
    private String scenarioTags;
    private String requestJson;
    private String responseJson;
    private String status;
    private String errorMsg;
    private java.util.Date createdAt;
    private java.util.Date completedAt;
}