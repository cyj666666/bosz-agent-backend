package com.suzhou.bank;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.suzhou.bank.mapper")
public class SuzhouBankApplication {
    public static void main(String[] args) {
        SpringApplication.run(SuzhouBankApplication.class, args);
    }
}
