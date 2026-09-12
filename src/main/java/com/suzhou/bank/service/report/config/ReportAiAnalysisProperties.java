package com.suzhou.bank.service.report.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * AI 全文分析配置（report.ai-analysis.*）
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
@Component
@ConfigurationProperties(prefix = "report.ai-analysis")
public class ReportAiAnalysisProperties {

    /** 使用哪个大模型配置（对应 large_model_config.lm_code） */
    private String lmCode = "default";

    /** 调用大模型的超时（毫秒） */
    private int timeoutMillis = 300000;

    /** 素材文本上限（字符），超出则截断并在末尾标注，防止撑爆上下文 */
    private int maxMaterialChars = 60000;

    /** 独立线程池：核心线程数（全文分析是长耗时 IO，串行少量即可） */
    private int poolSize = 2;

    /** 独立线程池：最大线程数 */
    private int maxPoolSize = 4;

    /** 独立线程池：队列容量 */
    private int queueCapacity = 50;
}
