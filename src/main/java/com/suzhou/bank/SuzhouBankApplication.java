package com.suzhou.bank;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;

import java.net.InetAddress;

@SpringBootApplication
@MapperScan("com.suzhou.bank.mapper")
public class SuzhouBankApplication {
    public static void main(String[] args) {
        SpringApplication.run(SuzhouBankApplication.class, args);
    }

    @Bean
    CommandLineRunner startupInfo(Environment env) {
        return args -> {
            String port = env.getProperty("server.port", "8080");
            String contextPath = env.getProperty("server.servlet.context-path", "");
            String host = InetAddress.getLocalHost().getHostAddress();
            String activeProfile = env.getProperty("spring.profiles.active", "default");

            System.out.println("\n========================================");
            System.out.println("  贷后管理智能体 启动成功！");
            System.out.println("  Profile: " + activeProfile);
            System.out.println("  本地访问:  http://localhost:" + port + contextPath);
            System.out.println("  网络访问:  http://" + host + ":" + port + contextPath);
            System.out.println("========================================\n");
        };
    }
}
