package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("rule_condition")
public class RuleCondition {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long ruleId;
    private String indicatorKey;
    private String operator;
    private String threshold;
    private Integer logicOrder;
    private String logicConnector;
}