package com.suzhou.bank.service.data.collector;

import com.suzhou.bank.entity.CollectorConfig;

/**
 * 数据采集器接口（策略模式）
 * <p>定义"从哪拿数据"的抽象，不同数据源类型（HTTP API、SFTP、数据库等）
 * 实现此接口，由采集器配置表驱动运行时选择。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
public interface DataCollector {

    /**
     * 获取采集器类型标识
     *
     * @return 类型字符串（如 HTTP_API、SFTP_FILE，与 collector_config.collector_type 对应）
     */
    String getType();

    /**
     * 执行数据采集
     *
     * @param config 采集器配置（含连接信息、凭证等）
     * @return 原始数据字符串（JSON/文本等）
     */
    String collect(CollectorConfig config);

    /**
     * 校验采集器配置是否合法
     *
     * @param configJson 配置JSON字符串
     * @return true 表示配置格式正确
     */
    boolean validateConfig(String configJson);
}
