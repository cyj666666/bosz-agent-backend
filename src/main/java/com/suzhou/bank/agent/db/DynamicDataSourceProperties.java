package com.suzhou.bank.agent.db;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 动态数据源连接池参数（前缀 {@code agent.dynamic.datasource}）
 *
 * <p><b>为什么改前缀</b>：源工程用的是 {@code spring.datasource.dynamic}，
 * 那是 JeecgBoot + dynamic-datasource 的命名空间；宿主工程的
 * {@code spring.datasource} 已被自身 Druid 主数据源占用，
 * 沿用会让读配置的人误以为在配主库。agent 模块统一收敛到 {@code agent.*} 命名空间。</p>
 *
 * <p><b>为什么类名不叫 DataSourceProperties</b>：会与 Spring Boot 自带的
 * {@code org.springframework.boot.autoconfigure.jdbc.DataSourceProperties} 混淆，
 * 平移代码时极易 import 错，故显式改名。</p>
 *
 * <p>不配置时各字段为空，{@link DynamicDBUtil} 会使用内置默认值，功能不受影响。</p>
 */
@Data
@Component
@ConfigurationProperties(prefix = "agent.dynamic.datasource")
public class DynamicDataSourceProperties {

    private BasicDataSourceConfig druid = new BasicDataSourceConfig();

    @Data
    public static class BasicDataSourceConfig {

        @Schema(description = "初始化连接数")
        private String initialSize;

        @Schema(description = "最小空闲连接数")
        private String minIdle;

        @Schema(description = "最大活跃连接数")
        private String maxActive;

        @Schema(description = "最大等待时间")
        private String maxWait;

        @Schema(description = "连接检测间隔时间")
        private String timeBetweenEvictionRunsMillis;

        @Schema(description = "最小空闲时间")
        private String minEvictableIdleTimeMillis;

        @Schema(description = "验证查询语句")
        private String validationQuery;

        @Schema(description = "测试空闲连接是否可用")
        private boolean testWhileIdle;

        @Schema(description = "测试从连接池获取连接时是否可用")
        private boolean testOnBorrow;

        @Schema(description = "测试归还连接时是否可用")
        private boolean testOnReturn;

        @Schema(description = "开启连接泄露检测")
        private boolean removeAbandoned;

        @Schema(description = "连接泄露超时时间")
        private String removeAbandonedTimeout;

        @Schema(description = "记录泄露日志")
        private boolean logAbandoned;

        @Schema(description = "开启PSCache")
        private boolean poolPreparedStatements;

        @Schema(description = "每个连接上PSCache的大小")
        private String maxPoolPreparedStatementPerConnectionSize;

        @Schema(description = "配置监控统计拦截的filters，去掉后监控界面sql无法统计，'wall'用于防火墙(达梦库，需要要去掉wall)")
        private String filters;

        @Schema(description = "通过connectProperties属性来打开mergeSql功能；慢SQL记录")
        private String connectionProperties;

        @Schema(description = "连接错误重试次数")
        private String connectionErrorRetryAttempts;

        @Schema(description = "配置重试间隔，比如30秒 (30000毫秒)")
        private String timeBetweenConnectErrorMillis;

        @Schema(description = "是否在获取连接失败后中断")
        private boolean breakAfterAcquireFailure;

        @Schema(description = "JDBC驱动连接超时时间（毫秒），避免TCP connect阻塞过久")
        private String connectTimeout;

        @Schema(description = "JDBC驱动socket读取超时时间（毫秒）")
        private String socketTimeout;
    }
}
