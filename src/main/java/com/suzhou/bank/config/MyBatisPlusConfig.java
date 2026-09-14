package com.suzhou.bank.config;

import com.baomidou.mybatisplus.annotation.DbType;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * MyBatis-Plus 配置
 * <p>注册分页插件。数据库类型为 openGauss（PostgreSQL 兼容）。</p>
 *
 * <p><b>修正说明（2026-09-14）</b>：此处原为 {@code DbType.MYSQL}，但本工程的数据源实际是
 * {@code jdbc:opengauss://...}（见 application-*.yml 的 spring.datasource.url）。
 * MySQL 方言生成的分页语句形如 {@code LIMIT ?,?}，
 * 而 PostgreSQL 系（含 openGauss/GaussDB）只接受 {@code LIMIT ? OFFSET ?}，
 * 一旦走到分页查询就会在运行期报语法错误。改为 POSTGRE_SQL 方言。</p>
 *
 * <p>触发原因是 agent 模块（指标配置）大量使用 MyBatis-Plus 的 {@code page()} 分页，
 * 属必须修正项；宿主原有的报告模块未走 MP 分页，故此前未暴露。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Configuration
public class MyBatisPlusConfig {
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.POSTGRE_SQL));
        return interceptor;
    }
}
