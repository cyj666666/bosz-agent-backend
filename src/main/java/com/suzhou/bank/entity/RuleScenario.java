package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("rule_scenario")
public class RuleScenario {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String scenarioCode;
    private String scenarioName;
    private String description;
    private java.util.Date createdAt;
}