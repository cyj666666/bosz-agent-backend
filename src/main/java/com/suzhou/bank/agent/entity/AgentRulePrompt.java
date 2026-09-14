package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * Agent大模型提示词配置表 实体
 * 表：agent_rule_prompt
 */
@Data
@TableName("agent_rule_prompt")
public class AgentRulePrompt {

    /**
     * 提示词唯一标识key（主键，非自增）
     */
    @TableId(type = IdType.INPUT)
    private String key;

    /**
     * prompt提示词内容
     */
    private String prompt;
}
