package com.suzhou.bank.agent.db;

import com.alibaba.druid.pool.DruidDataSource;
import com.suzhou.bank.agent.config.AgentSpringContext;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 动态数据源连接池缓存（进程内，不支持分布式）
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.common.util.dynamic.db.DataSourceCachePool}。</p>
 *
 * <p><b>两处与原实现的差异（均为修正，不改变对外行为）</b>：</p>
 * <ol>
 *   <li>容器由 {@code HashMap} 改为 {@code ConcurrentHashMap}。原实现是静态共享缓存，
 *       但用非线程安全的 {@code HashMap}；指标取数是并发路径（多个规则/多个用户同时取值），
 *       在 JDK8 的 HashMap 上并发扩容可能造成链表成环、CPU 打满。此处直接修正。</li>
 *   <li>依赖来源由 JeecgBoot 的 {@code CommonAPI} 改为 agent 自有的
 *       {@link AgentDataSourceProvider}，去掉对 JeecgBoot 的依赖。</li>
 * </ol>
 */
public class DataSourceCachePool {

    /** 数据源连接池缓存【本地 class 缓存 - 不支持分布式】 */
    private static final Map<String, DruidDataSource> DB_SOURCES = new ConcurrentHashMap<>();

    /**
     * 按 dbKey 取数据源配置（每次都回源查库，由上层 {@link DynamicDBUtil} 负责缓存连接池本身）
     */
    public static DynamicDataSourceModel getCacheDynamicDataSourceModel(String dbKey) {
        AgentDataSourceProvider provider = AgentSpringContext.getBean(AgentDataSourceProvider.class);
        return provider.getDynamicDbSourceByCode(dbKey);
    }

    public static DruidDataSource getCacheBasicDataSource(String dbKey) {
        return DB_SOURCES.get(dbKey);
    }

    public static void putCacheBasicDataSource(String dbKey, DruidDataSource db) {
        DB_SOURCES.put(dbKey, db);
    }

    /**
     * 清空数据源缓存（腾退时关闭所有连接池）
     */
    public static void cleanAllCache() {
        for (Map.Entry<String, DruidDataSource> entry : DB_SOURCES.entrySet()) {
            DruidDataSource druidDataSource = entry.getValue();
            if (druidDataSource != null && druidDataSource.isEnable()) {
                druidDataSource.close();
            }
        }
        DB_SOURCES.clear();
    }

    public static void removeCache(String dbKey) {
        DruidDataSource druidDataSource = DB_SOURCES.get(dbKey);
        if (druidDataSource != null && druidDataSource.isEnable()) {
            druidDataSource.close();
        }
        DB_SOURCES.remove(dbKey);
    }
}
