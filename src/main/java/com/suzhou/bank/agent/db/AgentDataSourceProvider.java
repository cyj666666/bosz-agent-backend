package com.suzhou.bank.agent.db;

/**
 * agent 模块的动态数据源元数据提供者
 *
 * <p><b>为什么抽成接口</b>：源工程里 {@code DynamicDBUtil} / {@code DataSourceCachePool}
 * 通过 JeecgBoot 的 {@code CommonAPI} 接口取数据源配置，实现类在 amar-base 模块中、
 * 与 JeecgBoot 的 Service 体系深度绑定。agent 模块要自包含，
 * 因此把「取数据源配置」这一个能力抽成独立接口，
 * 由 agent 自己的实现类直接读 {@code sys_data_source} 表，不经过 JeecgBoot。</p>
 */
public interface AgentDataSourceProvider {

    /**
     * 按数据源编码取配置
     *
     * @param code 数据源编码（{@code sys_data_source.code}）
     * @return 数据源配置，不存在返回 {@code null}
     */
    DynamicDataSourceModel getDynamicDbSourceByCode(String code);

    /**
     * 按主键取配置
     *
     * @param id 主键（{@code sys_data_source.id}）
     * @return 数据源配置，不存在返回 {@code null}
     */
    DynamicDataSourceModel getDynamicDbSourceById(String id);
}
