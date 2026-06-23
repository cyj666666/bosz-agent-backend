package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("rule_tag")
public class RuleTag {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long ruleId;
    private String tagType;
    private String tagValue;
}