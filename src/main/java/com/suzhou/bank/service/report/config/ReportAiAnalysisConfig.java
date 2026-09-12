package com.suzhou.bank.service.report.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.ThreadPoolExecutor;

/**
 * AI 全文分析的独立线程池
 *
 * <p>全文分析是「调大模型」这种长耗时 IO（分钟级），必须与报告生成、Web 请求线程隔离，
 * 因此单独建一个池：核心 2 / 最大 4 / 队列 50，满了由调用线程兜底执行（CallerRuns），
 * 避免直接丢弃任务导致状态永远停在 RUNNING。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Configuration
public class ReportAiAnalysisConfig {

    @Bean("reportAiAnalysisExecutor")
    public ThreadPoolTaskExecutor reportAiAnalysisExecutor(ReportAiAnalysisProperties properties) {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(properties.getPoolSize());
        executor.setMaxPoolSize(properties.getMaxPoolSize());
        executor.setQueueCapacity(properties.getQueueCapacity());
        executor.setKeepAliveSeconds(120);
        executor.setThreadNamePrefix("report-ai-analysis-");
        // 队列满时由提交线程执行，宁可让本次请求慢一点也不丢任务
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        // 关闭时等待正在跑的分析收尾，避免状态卡在 RUNNING
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(60);
        executor.initialize();
        return executor;
    }
}
