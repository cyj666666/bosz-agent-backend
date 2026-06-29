package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 指标数据表（indicator_data）
 * <p>所有结构化指标的统一存储，通过 domain 字段区分数据域。
 * 是 Know-Kit 分析的核心输入和报告表格的数据来源。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
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

    /** 客户名称（非数据库字段，查询时 JOIN 填充） */
    @TableField(exist = false)
    private String companyName;
}