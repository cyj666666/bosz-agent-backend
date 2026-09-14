package com.suzhou.bank.agent.cache;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.parser.Feature;
import org.apache.commons.lang3.StringUtils;

/**
 * 双层缓存（当前为纯内存实现）
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.cache.DoubleCache}。</p>
 *
 * <p><b>为什么叫 Double</b>：源设计意图是「本地内存 + 分布式(Redis)」两级，
 * 但分布式那一级在源工程里始终未启用。本模块保持类名与调用方式不变
 * （业务代码按 {@code DoubleCache} 注入），实现退化为单层内存，
 * 行为与源工程实际运行时一致。</p>
 */
public class DoubleCache implements Cache {

    /**
     * 内存缓存
     */
    private final MemoryCache memoryCache;

    public DoubleCache(MemoryCache memoryCache) {
        this.memoryCache = memoryCache;
    }

    @Override
    public String getValue(String key) {
        return memoryCache.getValue(key);
    }

    @Override
    public <T> T getValue(String key, Class<T> clazz) {
        String value = getValue(key);
        if (StringUtils.isBlank(value)) {
            return null;
        }
        return JSON.parseObject(value, clazz, Feature.OrderedField);
    }

    @Override
    public void set(String key, Object value) {
        String cacheValue;
        if (value instanceof String) {
            cacheValue = (String) value;
        } else {
            cacheValue = JSON.toJSONString(value);
        }
        this.memoryCache.set(key, cacheValue);
    }

    @Override
    public void set(String key, Object value, int expireTime) {
        String cacheValue;
        if (value instanceof String) {
            cacheValue = (String) value;
        } else {
            cacheValue = JSON.toJSONString(value);
        }
        this.memoryCache.set(key, cacheValue, expireTime);
    }

    @Override
    public void remove(String key) {
        this.memoryCache.remove(key);
    }
}
