package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 规则标签表（rule_tag）
 * <p>规则的分类标签，按 tagType（场景/行业/产品）和 tagValue 存储。
 * 支持 Know-Kit 按标签匹配适用的风险规则。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@TableName("rule_tag")
public class RuleTag {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long ruleId;
    private String tagType;
    private String tagValue;
}