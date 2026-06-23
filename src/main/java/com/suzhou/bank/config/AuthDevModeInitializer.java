package com.suzhou.bank.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import javax.annotation.PostConstruct;

/**
 * 启动时根据配置激活 AuthHelper 开发模式。
 * 上线时删除 application.yml 中的 app.auth.dev-mode 配置即可。
 */
@Component
public class AuthDevModeInitializer {

    @Value("${app.auth.dev-mode:false}")
    private boolean devMode;

    @PostConstruct
    public void init() {
        AuthHelper.setDevMode(devMode);
    }
}
