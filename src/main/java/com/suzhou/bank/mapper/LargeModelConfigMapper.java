package com.suzhou.bank.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.LargeModelConfig;
import org.apache.ibatis.annotations.Mapper;

/**
 * 大模型配置表 Mapper（large_model_config）
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Mapper
public interface LargeModelConfigMapper extends BaseMapper<LargeModelConfig> {
}
