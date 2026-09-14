package com.suzhou.bank.agent.cache;

import com.alibaba.fastjson.JSON;
import com.google.common.cache.CacheBuilder;
import com.google.common.cache.CacheLoader;
import com.google.common.cache.LoadingCache;
import org.apache.commons.lang3.StringUtils;

import java.util.concurrent.TimeUnit;

/**
 * 基于 Guava LoadingCache 的进程内缓存
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.cache.MemoryCache}。</p>
 *
 * <p><b>注意（保留源行为）</b>：带 {@code expireTime} 的
 * {@link #set(String, Object, int)} 实际<b>不生效</b>——
 * 过期时间在构造时由 {@link AgentDataCacheConfig} 统一配置，
 * Guava 的 {@code LoadingCache} 不支持逐条设置 TTL。
 * 这是源实现的既有行为，此处未做改动（改为逐条 TTL 需要换用 Caffeine 或自行实现，
 * 属于独立优化，不在迁移范围内）。</p>
 */
public class MemoryCache implements Cache {

    private final LoadingCache<String, String> dataCache;

    private final int initialCapacity;

    private final int maxSize;

    private final int expireTime;

    public MemoryCache(int initialCapacity, int maxSize, int expireTime) {
        this.initialCapacity = initialCapacity;
        this.maxSize = maxSize;
        this.expireTime = expireTime;
        this.dataCache = CacheBuilder.newBuilder()
                .initialCapacity(this.initialCapacity)
                .maximumSize(this.maxSize)
                .expireAfterWrite(this.expireTime, TimeUnit.SECONDS)
                .build(new CacheLoader<String, String>() {
                    @Override
                    public String load(String key) {
                        return "";
                    }
                });
    }

    @Override
    public String getValue(String key) {
        try {
            return dataCache.get(key);
        } catch (Exception e) {
            return "";
        }
    }

    @Override
    public <T> T getValue(String key, Class<T> clazz) {
        String value = getValue(key);
        if (StringUtils.isBlank(value)) {
            return null;
        }
        return JSON.parseObject(value, clazz);
    }

    @Override
    public void set(String key, Object value) {
        if (value instanceof String) {
            dataCache.put(key, (String) value);
        } else {
            dataCache.put(key, JSON.toJSONString(value));
        }
    }

    @Override
    public void set(String key, Object value, int expireTime) {
        set(key, value);
    }

    @Override
    public void remove(String key) {
        dataCache.invalidate(key);
    }
}
