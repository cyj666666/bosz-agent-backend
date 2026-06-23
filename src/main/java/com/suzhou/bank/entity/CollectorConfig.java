package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 采集器配置表（collector_config）
 * <p>定义"数据从哪来"，支持运行时动态配置。
 * 不同采集器类型（HTTP_API、SFTP_FILE等）通过策略模式实现。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@TableName("collector_config")
public class CollectorConfig {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String configName;
    private String collectorType;
    private String configJson;
    private String cronExpression;
    private Integer enabled;
    private java.util.Date createdAt;
    private java.util.Date updatedAt;
}