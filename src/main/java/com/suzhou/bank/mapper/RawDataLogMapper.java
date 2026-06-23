package com.suzhou.bank.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.RawDataLog;
import org.apache.ibatis.annotations.Mapper;

/**
 * 原始数据日志表 Mapper
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Mapper
public interface RawDataLogMapper extends BaseMapper<RawDataLog> {
}
