package com.suzhou.bank.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Know-Kit 智能体连接配置
 * <p>从 application.yml 的 {@code know-kit} 节点读取，
 * 包含第三方智能体的 API 地址和超时设置。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "know-kit")
public class KnowKitConfig {
    private String baseUrl;
    private String analyzePath;
    private int timeout;
}
