package com.suzhou.bank.agent.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import com.suzhou.bank.agent.entity.AgentRuleEntity;
import com.suzhou.bank.agent.entity.AgentRulePrompt;

import java.util.List;
import java.util.Map;

@Mapper
public interface AgentRuleMapper extends BaseMapper<AgentRuleEntity> {

    @Insert("REPLACE INTO agent_rule_prompt (`key`, prompt) VALUES(#{prompt.key}, #{prompt.prompt})")
    int replacePrompt(@Param("prompt") AgentRulePrompt prompt);

    /**
     * 根据key查询提示词
     */
    @Select("SELECT `key`, prompt FROM agent_rule_prompt WHERE `key` = #{promptKey}")
    AgentRulePrompt getPromptByKey(@Param("promptKey") String promptKey);

    /**
     * 一级主题 + 拼接二级主题
     */
    @Select("SELECT topic1, GROUP_CONCAT(DISTINCT topic2) AS topic2_str " +
            "FROM agent_rule " +
            "WHERE topic1 IS NOT NULL AND topic2 IS NOT NULL " +
            "GROUP BY topic1 " +
            "ORDER BY topic1")
    List<Map<String, String>> listTopicGroup();
}
