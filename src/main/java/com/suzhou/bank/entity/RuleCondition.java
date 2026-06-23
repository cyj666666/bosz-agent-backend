package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 规则条件表（rule_condition）
 * <p>存储风险规则的结构化判断条件，如"资产负债率 > 70%"。
 * 按 logicOrder 排列，通过 logicConnector（AND/OR）组合为完整判定逻辑。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
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