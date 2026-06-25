package com.suzhou.bank.service.knowledge;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.*;
import java.util.List;
import java.util.Map;

/**
 * 知识库服务接口
 * <p>管理风险判定规则体系，包括场景定义、规则的CRUD、
 * 规则条件和标签的管理，以及按标签匹配规则供 Know-Kit 使用。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
public interface KnowledgeService {

    // ==================== 场景管理 ====================

    /**
     * 场景分页查询
     */
    Page<RuleScenario> pageScenario(int page, int size);

    /**
     * 查询全部场景（供下拉选择等使用）
     */
    List<RuleScenario> listAllScenarios();

    /**
     * 新增场景定义
     */
    void saveScenario(RuleScenario scenario);

    /**
     * 更新场景定义
     */
    void updateScenario(RuleScenario scenario);

    /**
     * 删除场景定义
     */
    void deleteScenario(Long id);

    // ==================== 规则管理 ====================

    /**
     * 规则分页查询
     *
     * @param keyword 模糊搜索关键词（规则名称或编码），可选
     */
    Page<KnowledgeRule> pageRule(int page, int size, String keyword);

    /**
     * 根据ID查询规则
     */
    KnowledgeRule getRule(Long id);

    /**
     * 新增规则
     */
    void saveRule(KnowledgeRule rule);

    /**
     * 更新规则
     */
    void updateRule(KnowledgeRule rule);

    /**
     * 删除规则（级联删除关联的条件和标签）
     */
    void deleteRule(Long id);

    // ==================== 规则条件 ====================

    /**
     * 查询规则的条件列表
     *
     * @return 条件列表（按逻辑顺序排列）
     */
    List<RuleCondition> listConditions(Long ruleId);

    /**
     * 保存规则条件（先删后插，批量替换）
     */
    void saveConditions(Long ruleId, List<RuleCondition> conditions);

    // ==================== 规则标签 ====================

    /**
     * 查询规则的标签列表
     */
    List<RuleTag> listTags(Long ruleId);

    /**
     * 保存规则标签（先删后插，批量替换）
     */
    void saveTags(Long ruleId, List<RuleTag> tags);

    // ==================== 标签去重值 ====================

    /**
     * 获取各类型标签的去重值（供报告生成页下拉选择行业/产品/风险类型）
     *
     * @return 按 tagType 分组的去重标签值，key = 标签类型, value = 去重后的标签值列表
     */
    Map<String, List<String>> distinctTagValues();

    // ==================== 规则匹配 ====================

    /**
     * 按场景标签匹配规则（供 Know-Kit 分析时调用）
     * <p>通过 rule_tag 表关联查询，返回所有标签匹配且启用的规则。</p>
     *
     * @param scenarioTags 场景标签值列表
     * @return 匹配到的规则列表
     */
    List<KnowledgeRule> matchRules(List<String> scenarioTags);
}
