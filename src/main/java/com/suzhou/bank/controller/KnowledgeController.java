package com.suzhou.bank.controller;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.service.knowledge.KnowledgeService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/api/knowledge")
@RequiredArgsConstructor
public class KnowledgeController {
    private final KnowledgeService service;
    @GetMapping("/scenario/page")
    public Result<Page<RuleScenario>> pageScenario(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size) { return Result.ok(service.pageScenario(page, size)); }
    @GetMapping("/scenario/all")
    public Result<List<RuleScenario>> listScenarios() { return Result.ok(service.listAllScenarios()); }
    @PostMapping("/scenario")
    public Result<Void> saveScenario(@RequestBody RuleScenario s) { service.saveScenario(s); return Result.ok(); }
    @DeleteMapping("/scenario/{id}")
    public Result<Void> deleteScenario(@PathVariable Long id) { service.deleteScenario(id); return Result.ok(); }
    @GetMapping("/rule/page")
    public Result<Page<KnowledgeRule>> pageRule(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size, @RequestParam(required = false) String keyword) { return Result.ok(service.pageRule(page, size, keyword)); }
    @GetMapping("/rule/{id}")
    public Result<KnowledgeRule> getRule(@PathVariable Long id) { return Result.ok(service.getRule(id)); }
    @PostMapping("/rule")
    public Result<Void> saveRule(@RequestBody KnowledgeRule r) { service.saveRule(r); return Result.ok(); }
    @PutMapping("/rule")
    public Result<Void> updateRule(@RequestBody KnowledgeRule r) { service.updateRule(r); return Result.ok(); }
    @DeleteMapping("/rule/{id}")
    public Result<Void> deleteRule(@PathVariable Long id) { service.deleteRule(id); return Result.ok(); }
    @GetMapping("/rule/{ruleId}/conditions")
    public Result<List<RuleCondition>> listConditions(@PathVariable Long ruleId) { return Result.ok(service.listConditions(ruleId)); }
    @PostMapping("/rule/{ruleId}/conditions")
    public Result<Void> saveConditions(@PathVariable Long ruleId, @RequestBody List<RuleCondition> conds) { service.saveConditions(ruleId, conds); return Result.ok(); }
    @GetMapping("/rule/{ruleId}/tags")
    public Result<List<RuleTag>> listTags(@PathVariable Long ruleId) { return Result.ok(service.listTags(ruleId)); }
    @PostMapping("/rule/{ruleId}/tags")
    public Result<Void> saveTags(@PathVariable Long ruleId, @RequestBody List<RuleTag> tags) { service.saveTags(ruleId, tags); return Result.ok(); }
}
