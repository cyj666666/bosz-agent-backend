package com.suzhou.bank.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.CollectorConfig;
import org.apache.ibatis.annotations.Mapper;

/**
 * 采集器配置表 Mapper
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Mapper
public interface CollectorConfigMapper extends BaseMapper<CollectorConfig> {
}
