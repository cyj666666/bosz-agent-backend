package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 风险判定规则表（knowledge_rule）
 * <p>知识库核心表，存储风险判定规则。
 * description 字段使用自然语言描述，供 Know-Kit 大模型理解；
 * 结构化条件通过 rule_condition 表关联存储。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@TableName("knowledge_rule")
public class KnowledgeRule {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String ruleCode;
    private String ruleName;
    private String ruleType;
    private String description;
    private Integer enabled;
    private java.util.Date createdAt;
    private java.util.Date updatedAt;
}