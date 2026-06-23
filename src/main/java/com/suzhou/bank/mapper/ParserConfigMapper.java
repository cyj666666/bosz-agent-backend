package com.suzhou.bank.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.ParserConfig;
import org.apache.ibatis.annotations.Mapper;

/**
 * 解析器配置表 Mapper
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Mapper
public interface ParserConfigMapper extends BaseMapper<ParserConfig> {
}
