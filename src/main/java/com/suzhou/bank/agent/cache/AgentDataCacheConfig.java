package com.suzhou.bank.agent.cache;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * agent 模块缓存装配
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.cache.DataCacheConfig}。</p>
 *
 * <p><b>配置键变更说明</b>：源工程用 {@code cache.memory.*}，
 * 本模块收敛到 {@code agent.cache.memory.*} 命名空间，与宿主配置彻底分开。
 * 三个参数均有默认值，不配置也能正常启动；
 * 若从源工程迁移配置，需同步改写键名前缀。</p>
 */
@Configuration
public class AgentDataCacheConfig {

    /** 内存缓存初始化大小，默认 500 */
    @Value("${agent.cache.memory.initial-capacity:500}")
    private int initialCapacity;

    /** 内存缓存最大条数，默认 1000 */
    @Value("${agent.cache.memory.max-size:1000}")
    private int maxSize;

    /** 内存缓存超时时间（秒），默认 600 */
    @Value("${agent.cache.memory.expire-time:600}")
    private int expireTime;

    @Bean
    public MemoryCache memoryCache() {
        return new MemoryCache(initialCapacity, maxSize, expireTime);
    }

    @Bean
    public DoubleCache doubleCache() {
        return new DoubleCache(memoryCache());
    }
}
