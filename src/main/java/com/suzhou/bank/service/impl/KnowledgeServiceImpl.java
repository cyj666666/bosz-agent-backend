package com.suzhou.bank.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.mapper.*;
import com.suzhou.bank.service.knowledge.KnowledgeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 知识库服务实现
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class KnowledgeServiceImpl implements KnowledgeService {
    private final RuleScenarioMapper sm;
    private final KnowledgeRuleMapper rm;
    private final RuleConditionMapper cm;
    private final RuleTagMapper tm;

    @Override
    public Page<RuleScenario> pageScenario(int page, int size) {
        return sm.selectPage(new Page<>(page, size),
            new LambdaQueryWrapper<RuleScenario>().orderByDesc(RuleScenario::getCreatedAt));
    }

    @Override public List<RuleScenario> listAllScenarios() { return sm.selectList(null); }

    @Override
    public void saveScenario(RuleScenario s) {
        sm.insert(s);
        log.info("场景已新增, id={}, code={}, name={}", s.getId(), s.getScenarioCode(), s.getScenarioName());
    }

    @Override
    public void deleteScenario(Long id) {
        sm.deleteById(id);
        log.info("场景已删除, id={}", id);
    }

    @Override
    public Page<KnowledgeRule> pageRule(int page, int size, String kw) {
        LambdaQueryWrapper<KnowledgeRule> w = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(kw)) {
            w.and(x -> x.like(KnowledgeRule::getRuleName, kw).or().like(KnowledgeRule::getRuleCode, kw));
        }
        w.orderByDesc(KnowledgeRule::getCreatedAt);
        return rm.selectPage(new Page<>(page, size), w);
    }

    @Override public KnowledgeRule getRule(Long id) { return rm.selectById(id); }

    @Override
    @Transactional
    public void saveRule(KnowledgeRule r) {
        rm.insert(r);
        log.info("规则已新增, id={}, code={}, name={}, type={}", r.getId(), r.getRuleCode(), r.getRuleName(), r.getRuleType());
    }

    @Override
    public void updateRule(KnowledgeRule r) {
        rm.updateById(r);
        log.info("规则已更新, id={}, code={}, name={}", r.getId(), r.getRuleCode(), r.getRuleName());
    }

    @Override
    @Transactional
    public void deleteRule(Long id) {
        log.info("删除规则及关联条件+标签, ruleId={}", id);
        cm.delete(new LambdaQueryWrapper<RuleCondition>().eq(RuleCondition::getRuleId, id));
        tm.delete(new LambdaQueryWrapper<RuleTag>().eq(RuleTag::getRuleId, id));
        rm.deleteById(id);
    }

    @Override
    public List<RuleCondition> listConditions(Long ruleId) {
        return cm.selectList(new LambdaQueryWrapper<RuleCondition>()
            .eq(RuleCondition::getRuleId, ruleId).orderByAsc(RuleCondition::getLogicOrder));
    }

    @Override
    @Transactional
    public void saveConditions(Long ruleId, List<RuleCondition> conds) {
        cm.delete(new LambdaQueryWrapper<RuleCondition>().eq(RuleCondition::getRuleId, ruleId));
        conds.forEach(c -> { c.setRuleId(ruleId); cm.insert(c); });
        log.info("规则条件已更新, ruleId={}, conditionCount={}", ruleId, conds.size());
    }

    @Override
    public List<RuleTag> listTags(Long ruleId) {
        return tm.selectList(new LambdaQueryWrapper<RuleTag>().eq(RuleTag::getRuleId, ruleId));
    }

    @Override
    @Transactional
    public void saveTags(Long ruleId, List<RuleTag> tags) {
        tm.delete(new LambdaQueryWrapper<RuleTag>().eq(RuleTag::getRuleId, ruleId));
        tags.forEach(t -> { t.setRuleId(ruleId); tm.insert(t); });
        log.info("规则标签已更新, ruleId={}, tagCount={}", ruleId, tags.size());
    }

    @Override
    public List<KnowledgeRule> matchRules(List<String> tags) {
        if (tags == null || tags.isEmpty()) return Collections.emptyList();
        List<RuleTag> matched = tm.selectList(
            new LambdaQueryWrapper<RuleTag>().in(RuleTag::getTagValue, tags));
        List<Long> ids = matched.stream().map(RuleTag::getRuleId).distinct().collect(Collectors.toList());
        if (ids.isEmpty()) return Collections.emptyList();
        List<KnowledgeRule> result = rm.selectBatchIds(ids).stream()
            .filter(r -> r.getEnabled() == 1).collect(Collectors.toList());
        log.info("规则匹配完成, inputTags={}, matchedRules={}", tags.size(), result.size());
        return result;
    }
}
