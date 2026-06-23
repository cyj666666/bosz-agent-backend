package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 场景定义表（rule_scenario）
 * <p>定义风险判定场景，scenarioCode 全局唯一。
 * 场景是规则标签的最高层级分类维度。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
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