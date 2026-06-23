package com.suzhou.bank.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.CreditRecord;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用信记录表 Mapper
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Mapper
public interface CreditRecordMapper extends BaseMapper<CreditRecord> {
}
