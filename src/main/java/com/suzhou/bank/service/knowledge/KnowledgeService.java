package com.suzhou.bank.service.knowledge;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.*;
import java.util.List;

public interface KnowledgeService {
    // 场景管理
    Page<RuleScenario> pageScenario(int page, int size);
    List<RuleScenario> listAllScenarios();
    void saveScenario(RuleScenario scenario);
    void deleteScenario(Long id);

    // 规则管理
    Page<KnowledgeRule> pageRule(int page, int size, String keyword);
    KnowledgeRule getRule(Long id);
    void saveRule(KnowledgeRule rule);
    void updateRule(KnowledgeRule rule);
    void deleteRule(Long id);

    // 规则条件
    List<RuleCondition> listConditions(Long ruleId);
    void saveConditions(Long ruleId, List<RuleCondition> conditions);

    // 规则标签
    List<RuleTag> listTags(Long ruleId);
    void saveTags(Long ruleId, List<RuleTag> tags);

    // 按标签匹配规则（给 Know-Kit 用）
    List<KnowledgeRule> matchRules(List<String> scenarioTags);
}
