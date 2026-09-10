package com.suzhou.bank.report.config;

import com.suzhou.bank.report.spi.DefaultReportContentProvider;
import com.suzhou.bank.report.spi.ReportContentProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * 报告生成模块配置
 * <p>注册内容提供者的兜底实现：容器中不存在任何 {@link ReportContentProvider} 时生效。
 * 接入真实前置加工链路时，只需提供自己的 ReportContentProvider Bean，无需改动本类。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Configuration
public class ReportGenerateConfig {

    @Bean
    @ConditionalOnMissingBean(ReportContentProvider.class)
    public ReportContentProvider defaultReportContentProvider() {
        return new DefaultReportContentProvider();
    }
}
