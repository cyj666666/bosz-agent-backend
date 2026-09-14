package com.suzhou.bank.agent.db;

import com.alibaba.druid.pool.DruidDataSource;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.config.AgentSpringContext;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.sql.SQLException;

/**
 * 动态数据源取数工具（agent 模块「指标取数」的执行引擎）
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.common.util.dynamic.db.DynamicDBUtil}。</p>
 *
 * <p><b>这个类为什么必须存在</b>：指标配置里「SQL 数据源」类型的指标，
 * 其值来自行内各个外部业务库（MySQL / Oracle / PostgreSQL / 达梦 / Hive / openGauss）。
 * 本类按 {@code sys_data_source} 的配置动态创建 Druid 连接池并缓存，
 * 是指标「能取到数」的前提。它不是"多数据源框架"，而是"外部取数引擎"，
 * 与宿主主库（GaussDB）的 DataSource 完全无关，不共用连接池。</p>
 *
 * <p><b>与源实现的差异</b>：仅把 {@code JeecgBootException} 换成
 * {@link AgentBizException}、{@code DataSourceProperties} 换成
 * {@link DynamicDataSourceProperties}（配置前缀 {@code agent.dynamic.datasource}），
 * 其余连接池参数与容错策略完全保留（含 TCP 连接/读取超时与失败快速中断设置，
 * 避免外部库不可达时线程被长时间挂住）。</p>
 */
@Slf4j
@Component
public class DynamicDBUtil {

    private static volatile DynamicDataSourceProperties dataSourceProperties;

    private static DynamicDataSourceProperties getDataSourceProperties() {
        if (dataSourceProperties == null) {
            synchronized (DynamicDBUtil.class) {
                if (dataSourceProperties == null) {
                    dataSourceProperties = AgentSpringContext.getBean(DynamicDataSourceProperties.class);
                }
            }
        }
        return dataSourceProperties;
    }

    private static DruidDataSource getJdbcDataSource(final DynamicDataSourceModel dbSource) {
        String dbDriver = dbSource.getDbDriver();
        if (StringUtils.isEmpty(dbDriver)) {
            log.warn("数据库驱动为空，无法创建数据源");
            return null;
        }
        return createRDBMSDataSource(dbSource);
    }

    private static DruidDataSource createRDBMSDataSource(DynamicDataSourceModel dbSource) {
        DruidDataSource dataSource = new DruidDataSource();
        applyDataSourceProperties(dataSource, dbSource);
        return dataSource;
    }

    private static void applyDataSourceProperties(DruidDataSource dataSource, DynamicDataSourceModel dbSource) {
        // 设置基本连接信息
        dataSource.setDriverClassName(dbSource.getDbDriver());
        dataSource.setUrl(dbSource.getDbUrl());
        dataSource.setUsername(dbSource.getDbUsername());
        dataSource.setPassword(dbSource.getDbPassword());

        DynamicDataSourceProperties properties = getDataSourceProperties();
        if (properties != null && properties.getDruid() != null) {
            DynamicDataSourceProperties.BasicDataSourceConfig druidConfig = properties.getDruid();
            dataSource.setInitialSize(getIntValue(druidConfig.getInitialSize(), 5));
            dataSource.setMinIdle(getIntValue(druidConfig.getMinIdle(), 10));
            dataSource.setMaxActive(getIntValue(druidConfig.getMaxActive(), 50));
            dataSource.setMaxWait(getIntValue(druidConfig.getMaxWait(), 10000));
            dataSource.setTimeBetweenEvictionRunsMillis(getIntValue(druidConfig.getTimeBetweenEvictionRunsMillis(), 60000));
            dataSource.setMinEvictableIdleTimeMillis(getIntValue(druidConfig.getMinEvictableIdleTimeMillis(), 300000));

            // 根据数据库类型设置默认验证查询
            String defaultValidationQuery = getValidationQueryByDbType(dbSource.getDbType());
            dataSource.setValidationQuery(StringUtils.defaultIfEmpty(druidConfig.getValidationQuery(), defaultValidationQuery));

            dataSource.setTestWhileIdle(druidConfig.isTestWhileIdle());
            dataSource.setTestOnBorrow(druidConfig.isTestOnBorrow());
            dataSource.setTestOnReturn(druidConfig.isTestOnReturn());
            // JDBC驱动连接超时，避免TCP connect阻塞过久（默认60s+）
            dataSource.setConnectTimeout(getIntValue(druidConfig.getConnectTimeout(), 5000));
            dataSource.setSocketTimeout(getIntValue(druidConfig.getSocketTimeout(), 15000));
            // 获取连接失败后不再无限重试：默认true，重试耗尽即标记数据源不可用
            dataSource.setBreakAfterAcquireFailure(true);
            dataSource.setConnectionErrorRetryAttempts(getIntValue(druidConfig.getConnectionErrorRetryAttempts(), 1));
            dataSource.setTimeBetweenConnectErrorMillis(getIntValue(druidConfig.getTimeBetweenConnectErrorMillis(), 5000));
        } else {
            setDefaultDataSourceProperties(dataSource, dbSource.getDbType());
        }
    }

    /**
     * 根据数据库类型获取验证查询语句
     */
    private static String getValidationQueryByDbType(String dbType) {
        if (StringUtils.isEmpty(dbType)) {
            return "SELECT 1";
        }
        switch (dbType.toLowerCase()) {
            case "mysql":
            case "dm":
            case "postgresql":
            case "opengauss":
                return "SELECT 1";
            case "oracle":
                return "SELECT 1 FROM DUAL";
            default:
                return "SELECT 1";
        }
    }

    private static int getIntValue(String value, int defaultValue) {
        // 未配置（null / 空串 / 字面量 "null"）属于预期情况，直接用默认值、不打告警。
        // 源实现每次建连接池都会为「配置里本来就没写的项」刷 WARN（如
        // timeBetweenEvictionRunsMillis / minEvictableIdleTimeMillis），属于无意义噪音，本工程收敛掉。
        // 真正值得告警的是「配了但格式不对」，那种情况仍在下面打 WARN。
        if (StringUtils.isBlank(value) || "null".equalsIgnoreCase(value.trim())) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            log.warn("配置值 '{}' 无法转换为整数，使用默认值: {}", value, defaultValue);
            return defaultValue;
        }
    }

    private static void setDefaultDataSourceProperties(DruidDataSource dataSource, String dbType) {
        dataSource.setInitialSize(5);
        dataSource.setMinIdle(10);
        dataSource.setMaxActive(50);
        dataSource.setMaxWait(10000);
        dataSource.setTimeBetweenEvictionRunsMillis(60000);
        dataSource.setMinEvictableIdleTimeMillis(300000);

        // 根据数据库类型设置验证查询
        String validationQuery = getValidationQueryByDbType(dbType);
        dataSource.setValidationQuery(validationQuery);

        dataSource.setTestWhileIdle(true);
        dataSource.setTestOnBorrow(true);
        dataSource.setTestOnReturn(false);
        // JDBC驱动连接超时，避免TCP connect阻塞过久（默认60s+）
        dataSource.setConnectTimeout(5000);
        dataSource.setSocketTimeout(15000);
        // 获取连接失败后不无限重试：1次重试后标记数据源不可用
        dataSource.setBreakAfterAcquireFailure(true);
        dataSource.setConnectionErrorRetryAttempts(1);
        dataSource.setTimeBetweenConnectErrorMillis(5000);
    }

    /**
     * 通过 dbKey 获取数据源
     *
     * @param dbKey 数据源标识（即 {@code sys_data_source.code}）
     * @return DruidDataSource 数据源实例
     */
    public static DruidDataSource getDbSourceByDbKey(final String dbKey) {
        if (StringUtils.isEmpty(dbKey)) {
            throw new AgentBizException("数据源标识不能为空");
        }

        // 获取多数据源配置
        DynamicDataSourceModel dbSource = DataSourceCachePool.getCacheDynamicDataSourceModel(dbKey);
        if (dbSource == null) {
            throw new AgentBizException("未找到对应的数据源配置，dbKey：" + dbKey);
        }

        // 先判断缓存中是否存在可用的数据库连接
        DruidDataSource cacheDbSource = DataSourceCachePool.getCacheBasicDataSource(dbKey);
        if (cacheDbSource != null && !cacheDbSource.isClosed() && cacheDbSource.isEnable()) {
            log.debug("从缓存中获取DB连接，dbKey: {}", dbKey);
            return cacheDbSource;
        }
        // 缓存不可用（空/已关闭/被breakAfterAcquireFailure禁用），清理并重建
        if (cacheDbSource != null) {
            log.warn("缓存中的数据源不可用，dbKey: {}, isClosed: {}, isEnable: {}，将重新创建",
                    dbKey, cacheDbSource.isClosed(), cacheDbSource.isEnable());
            DataSourceCachePool.removeCache(dbKey);
        }

        DruidDataSource dataSource = getJdbcDataSource(dbSource);
        if (dataSource == null) {
            throw new AgentBizException("动态数据源连接失败，dbKey：" + dbKey);
        }
        DataSourceCachePool.putCacheBasicDataSource(dbKey, dataSource);
        log.debug("创建新的DB数据库连接，dbKey: {}", dbKey);
        return dataSource;
    }

    /**
     * 安全关闭数据库连接池
     */
    public static void closeDbKey(final String dbKey) {
        if (StringUtils.isEmpty(dbKey)) {
            log.warn("尝试关闭空数据源标识");
            return;
        }

        DruidDataSource dataSource = DataSourceCachePool.getCacheBasicDataSource(dbKey);
        if (dataSource == null) {
            log.debug("数据源 {} 不存在或已被关闭", dbKey);
            return;
        }

        try {
            if (!dataSource.isClosed()) {
                // 先尝试提交未提交的事务
                try (Connection connection = dataSource.getConnection()) {
                    if (!connection.getAutoCommit()) {
                        connection.commit();
                    }
                } catch (SQLException e) {
                    log.warn("提交事务时发生异常，dbKey: {}", dbKey, e);
                }

                // 关闭数据源
                dataSource.close();
                log.debug("成功关闭数据源，dbKey: {}", dbKey);
            }
        } catch (Exception e) {
            log.error("关闭数据源时发生异常，dbKey: {}", dbKey, e);
        } finally {
            // 从缓存中移除
            DataSourceCachePool.removeCache(dbKey);
        }
    }

    /**
     * 检查数据源是否可用
     */
    public static boolean isDataSourceAvailable(final String dbKey) {
        try {
            DruidDataSource dataSource = getDbSourceByDbKey(dbKey);
            return dataSource != null && !dataSource.isClosed() && dataSource.isEnable();
        } catch (Exception e) {
            log.warn("检查数据源可用性时发生异常，dbKey: {}", dbKey, e);
            return false;
        }
    }

    /**
     * 测试数据库连接
     */
    public static boolean testConnection(final String dbKey) {
        try (Connection connection = getDbSourceByDbKey(dbKey).getConnection()) {
            return connection.isValid(5); // 5秒超时
        } catch (SQLException e) {
            log.error("测试数据库连接失败，dbKey: {}", dbKey, e);
            return false;
        }
    }

    public static JdbcTemplate getJdbcTemplate(String dbKey) {
        DruidDataSource dataSource = getDbSourceByDbKey(dbKey);
        return new JdbcTemplate(dataSource);
    }

    public static NamedParameterJdbcTemplate getNamedParameterJdbcTemplate(String dbKey) {
        DruidDataSource dataSource = getDbSourceByDbKey(dbKey);
        return new NamedParameterJdbcTemplate(dataSource);
    }

    /**
     * 执行更新操作
     */
    public static int update(final String dbKey, String sql, Object... param) {
        JdbcTemplate jdbcTemplate = getJdbcTemplate(dbKey);
        if (ArrayUtils.isEmpty(param)) {
            return jdbcTemplate.update(sql);
        } else {
            return jdbcTemplate.update(sql, param);
        }
    }
}
