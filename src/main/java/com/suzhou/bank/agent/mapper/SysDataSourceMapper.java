package com.suzhou.bank.agent.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.agent.entity.SysDataSource;
import org.apache.ibatis.annotations.Mapper;

/**
 * 多数据源配置 Mapper（表 {@code sys_data_source}）
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.system.mapper.SysDataSourceMapper}，
 * 原本就是空的 BaseMapper，原样平移。</p>
 *
 * <p><b>必须带 {@code @Mapper}</b>：见 {@code AgentModuleConfig} 的扫描约定。</p>
 */
@Mapper
public interface SysDataSourceMapper extends BaseMapper<SysDataSource> {
}
