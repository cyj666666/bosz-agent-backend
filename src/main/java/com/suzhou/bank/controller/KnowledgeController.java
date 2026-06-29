package com.suzhou.bank.controller;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.service.knowledge.KnowledgeService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

/**
 * 知识库管理接口
 * <p>管理风险判定规则体系，包含场景定义、规则CRUD、规则条件和标签的管理。
 * 规则按场景/行业/产品标签分类，通过标签匹配机制为 Know-Kit 提供适用的风险判定规则。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@RestController
@RequestMapping("/api/knowledge")
@RequiredArgsConstructor
public class KnowledgeController {
    private final KnowledgeService service;

    // ==================== 场景管理 ====================

    /**
     * 场景分页查询
     *
     * @param page 页码
     * @param size 每页条数
     * @return 场景分页数据
     */
    @GetMapping("/scenario/page")
    public Result<Page<RuleScenario>> pageScenario(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size) { return Result.ok(service.pageScenario(page, size)); }

    /**
     * 查询全部场景（不分页，供下拉选择等使用）
     *
     * @return 场景列表
     */
    @GetMapping("/scenario/all")
    public Result<List<RuleScenario>> listScenarios() { return Result.ok(service.listAllScenarios()); }

    /**
     * 新增场景定义
     *
     * @param s 场景信息（场景编码必须唯一）
     * @return 操作结果
     */
    @PostMapping("/scenario")
    public Result<Void> saveScenario(@RequestBody RuleScenario s) { service.saveScenario(s); return Result.ok(); }

    /**
     * 更新场景定义
     *
     * @param s 场景信息（需包含ID）
     * @return 操作结果
     */
    @PutMapping("/scenario")
    public Result<Void> updateScenario(@RequestBody RuleScenario s) { service.updateScenario(s); return Result.ok(); }

    /**
     * 删除场景定义
     *
     * @param id 场景ID
     * @return 操作结果
     */
    @DeleteMapping("/scenario/{id}")
    public Result<Void> deleteScenario(@PathVariable Long id) { service.deleteScenario(id); return Result.ok(); }

    // ==================== 标签去重值 ====================

    /**
     * 获取各类型标签的去重值（供报告生成页下拉选择行业/产品/风险类型）
     *
     * @return 按 tagType 分组的去重标签值 Map
     */
    @GetMapping("/tags/distinct-values")
    public Result<Map<String, List<String>>> distinctTagValues() { return Result.ok(service.distinctTagValues()); }

    // ==================== 规则管理 ====================

    /**
     * 规则分页查询
     *
     * @param page    页码
     * @param size    每页条数
     * @param keyword 模糊搜索关键词（规则名称或编码）
     * @return 规则分页数据
     */
    @GetMapping("/rule/page")
    public Result<Page<KnowledgeRule>> pageRule(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size, @RequestParam(required = false) String keyword, @RequestParam(required = false) String ruleType, @RequestParam(required = false) Integer enabled) { return Result.ok(service.pageRule(page, size, keyword, ruleType, enabled)); }

    /**
     * 查询规则详情
     *
     * @param id 规则ID
     * @return 规则信息
     */
    @GetMapping("/rule/{id}")
    public Result<KnowledgeRule> getRule(@PathVariable Long id) { return Result.ok(service.getRule(id)); }

    /**
     * 新增规则
     *
     * @param r 规则信息（包含编码、名称、类型、自然语言描述等）
     * @return 操作结果
     */
    @PostMapping("/rule")
    public Result<Void> saveRule(@RequestBody KnowledgeRule r) { service.saveRule(r); return Result.ok(); }

    /**
     * 更新规则
     *
     * @param r 规则信息（需包含ID）
     * @return 操作结果
     */
    @PutMapping("/rule")
    public Result<Void> updateRule(@RequestBody KnowledgeRule r) { service.updateRule(r); return Result.ok(); }

    /**
     * 删除规则（级联删除关联的条件和标签）
     *
     * @param id 规则ID
     * @return 操作结果
     */
    @DeleteMapping("/rule/{id}")
    public Result<Void> deleteRule(@PathVariable Long id) { service.deleteRule(id); return Result.ok(); }

    // ==================== 规则条件 ====================

    /**
     * 查询规则的条件列表
     *
     * @param ruleId 规则ID
     * @return 条件列表（按逻辑顺序排列）
     */
    @GetMapping("/rule/{ruleId}/conditions")
    public Result<List<RuleCondition>> listConditions(@PathVariable Long ruleId) { return Result.ok(service.listConditions(ruleId)); }

    /**
     * 保存规则条件（先删后插，批量替换）
     *
     * @param ruleId 规则ID
     * @param conds  条件列表
     * @return 操作结果
     */
    @PostMapping("/rule/{ruleId}/conditions")
    public Result<Void> saveConditions(@PathVariable Long ruleId, @RequestBody List<RuleCondition> conds) { service.saveConditions(ruleId, conds); return Result.ok(); }

    // ==================== 规则标签 ====================

    /**
     * 查询规则的标签列表
     *
     * @param ruleId 规则ID
     * @return 标签列表
     */
    @GetMapping("/rule/{ruleId}/tags")
    public Result<List<RuleTag>> listTags(@PathVariable Long ruleId) { return Result.ok(service.listTags(ruleId)); }

    /**
     * 保存规则标签（先删后插，批量替换）
     *
     * @param ruleId 规则ID
     * @param tags   标签列表
     * @return 操作结果
     */
    @PostMapping("/rule/{ruleId}/tags")
    public Result<Void> saveTags(@PathVariable Long ruleId, @RequestBody List<RuleTag> tags) { service.saveTags(ruleId, tags); return Result.ok(); }
}
