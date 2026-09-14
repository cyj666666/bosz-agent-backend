package com.suzhou.bank.agent.service;

import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.extension.service.IService;
import org.apache.ibatis.annotations.Param;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.entity.AgentRuleEntity;
import com.suzhou.bank.agent.entity.AgentRulePrompt;
import com.suzhou.bank.agent.model.req.AgentRuleExecuteReq;
import com.suzhou.bank.agent.model.req.AgentRuleParseReq;
import com.suzhou.bank.agent.model.req.AgentRuleSaveReq;
import com.suzhou.bank.agent.model.vo.AgentRuleExecuteVO;
import com.suzhou.bank.agent.model.vo.AgentRuleParseVO;
import com.suzhou.bank.agent.service.impl.AgentRuleServiceImpl;

import java.util.List;

public interface IAgentRuleService extends IService<AgentRuleEntity> {

    AgentRuleEntity saveRule(AgentRuleSaveReq req);

    AgentRuleParseVO parseRule(AgentRuleParseReq req);

    AgentRuleExecuteVO executeRule(AgentRuleExecuteReq req);

    ListResult<?> getEnts(JSONObject req);

    List<AgentRuleServiceImpl.TopicTreeVO> getTopicTreeList();

    AgentRuleEntity getRule(String ruleCode);

    AgentResult<?> getRuleTreeByTopic(@Param("keyname") String keyname);
}
