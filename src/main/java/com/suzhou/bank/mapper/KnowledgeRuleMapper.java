package com.suzhou.bank.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.KnowledgeRule;
import org.apache.ibatis.annotations.Mapper;

/**
 * 风险判定规则表 Mapper
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Mapper
public interface KnowledgeRuleMapper extends BaseMapper<KnowledgeRule> {
}
