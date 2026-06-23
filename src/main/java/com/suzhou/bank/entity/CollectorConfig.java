package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

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