package com.suzhou.bank.agent.cache;

/**
 * 缓存抽象
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.cache.Cache}，原样平移。</p>
 *
 * <p>本模块只有进程内实现（{@link MemoryCache} / {@link DoubleCache}），
 * 源工程虽有 Redis 相关的注释残留，但实际未接入分布式缓存。</p>
 */
public interface Cache {

    /**
     * 根据 key 取缓存的字符串值
     */
    String getValue(String key);

    /**
     * 根据 key 取缓存并反序列化为指定类型
     */
    <T> T getValue(String key, Class<T> clazz);

    /**
     * 写入缓存并指定过期时间
     */
    void set(String key, Object value, int expireTime);

    /**
     * 写入缓存
     */
    void set(String key, Object value);

    /**
     * 删除缓存
     */
    void remove(String key);
}
