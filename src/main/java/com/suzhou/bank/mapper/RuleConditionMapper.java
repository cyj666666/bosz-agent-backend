package com.suzhou.bank.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.RuleCondition;
import org.apache.ibatis.annotations.Mapper;

/**
 * 规则条件表 Mapper
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Mapper
public interface RuleConditionMapper extends BaseMapper<RuleCondition> {
}
