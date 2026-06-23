package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("indicator_data")
public class IndicatorData {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long customerId;
    private String indicatorKey;
    private String indicatorName;
    private String currentValue;
    private String previousValue;
    private String changeDesc;
    private String dataUnit;
    private String domain;
    private String period;
    private Integer sortOrder;
    private java.util.Date createdAt;
}