package com.suzhou.bank.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "know-kit")
public class KnowKitConfig {
    private String baseUrl;
    private String analyzePath;
    private int timeout;
}
