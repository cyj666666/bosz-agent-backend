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

    /**
     * 使用哪个大模型配置（对应 large_model_config.lm_code）
     * <p>本工程自定义该表字段语义（明文 api_key + 完整 url），因此用本工程专属编码，
     * 不与其它工程的配置行混用。需人工插入该行，见 {@code sql/大模型配置表_初始化DML.sql}。</p>
     */
    private String lmCode = "bosz-report-ai";

    /**
     * 调用大模型的超时（毫秒）
     * <p>按本工程场景定：后台非流式一次性调用，素材上限 6 万字符、输出约 1500 字，
     * 正常几十秒到两三分钟。给 10 分钟足够容错，又不至于把线程池线程长时间占住
     * （池只有 2 个核心线程）。<b>不要照抄 amar 的 1800s</b> —— 那是给流式长对话用的。</p>
     */
    private int timeoutMillis = 600000;

    /** 素材文本上限（字符），超出则截断并在末尾标注，防止撑爆上下文 */
    private int maxMaterialChars = 60000;

    /** 独立线程池：核心线程数（全文分析是长耗时 IO，串行少量即可） */
    private int poolSize = 2;

    /** 独立线程池：最大线程数 */
    private int maxPoolSize = 4;

    /** 独立线程池：队列容量 */
    private int queueCapacity = 50;
}
