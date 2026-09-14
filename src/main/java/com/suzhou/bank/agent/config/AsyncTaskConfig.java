package com.suzhou.bank.agent.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.scheduling.annotation.AsyncConfigurer;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;
import java.util.concurrent.ThreadPoolExecutor;


/** 迁移说明：本类原样平移自 amar-agent-server 的 com.amarsoft.config.AsyncTaskConfig。
 *
 * <p><b>为什么必须搬</b>：agent 模块有 5 处按名称 {@code @Qualifier} 注入线程池
 * （{@code FetchDataThreadPool} / {@code FetchTraceThreadPool} / {@code FetchGroupThreadPool} /
 * {@code SplitterThreadPool} / {@code RelateIndexThreadPool}），另有
 * {@code KnowledgeBaseConfigServiceImpl} 按类型注入一个无限定符的 {@code Executor}。
 * 宿主只声明了 {@code agentTaskExecutor} 与 {@code reportAiAnalysisExecutor}，
 * 不搬本类则启动期直接报「No qualifying bean」或「expected single matching bean」。
 *
 * <p><b>与宿主的关系</b>：{@code getAsyncExecutor()} 带 {@code @Primary}，
 * 因此按类型注入的 {@code Executor} 会命中它；按名称注入的那些互不干扰。
 * 宿主既有的两个线程池都是按 {@code @Qualifier} 名称注入，不受本类影响。
 */
@Configuration
@EnableAsync
public class AsyncTaskConfig implements AsyncConfigurer {

    @Override
    @Bean
    @Primary
    public Executor getAsyncExecutor() {
        ThreadPoolTaskExecutor threadPool;
        threadPool = new ThreadPoolTaskExecutor();
        // 设置核心线程数
        threadPool.setCorePoolSize(10);
        // 设置最大线程数
        threadPool.setMaxPoolSize(20);
        // 线程池所使用的缓冲队列
        threadPool.setQueueCapacity(100);
        // 设置线程的空闲时间60秒
        threadPool.setKeepAliveSeconds(60);
        // 等待任务在关机时完成--表明等待所有线程执行完
        threadPool.setWaitForTasksToCompleteOnShutdown(true);
        // 等待时间 （默认为0，此时立即停止），并没等待xx秒后强制停止
        threadPool.setAwaitTerminationSeconds(60);
        // 线程拒绝策略：当任务无法提交时，丢弃队列最前面的任务，然后重新提交被拒绝的任务
        threadPool.setRejectedExecutionHandler(new ThreadPoolExecutor.DiscardOldestPolicy());
        //  线程名称前缀
        threadPool.setThreadNamePrefix("agent-common-async-");
        // 初始化线程
        threadPool.initialize();
        return threadPool;
    }

    @Bean
    @Qualifier("AiSummaryThreadPool")
    public Executor poolExecutor() {
        ThreadPoolTaskExecutor threadPoolTaskExecutor = new ThreadPoolTaskExecutor();
        threadPoolTaskExecutor.setCorePoolSize(20);
        threadPoolTaskExecutor.setMaxPoolSize(25);
        threadPoolTaskExecutor.setQueueCapacity(100);
        threadPoolTaskExecutor.setThreadNamePrefix("comprehensive-ai-summary-fetcher-");
        threadPoolTaskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        threadPoolTaskExecutor.initialize();
        return threadPoolTaskExecutor;
    }

    @Bean
    @Qualifier("FetchDataThreadPool")
    public Executor agentDataExecutor() {
        ThreadPoolTaskExecutor threadPoolTaskExecutor = new ThreadPoolTaskExecutor();
        threadPoolTaskExecutor.setCorePoolSize(50);
        threadPoolTaskExecutor.setMaxPoolSize(100);
        threadPoolTaskExecutor.setQueueCapacity(10000);
        threadPoolTaskExecutor.setThreadNamePrefix("fetch-data-fetcher-");
        threadPoolTaskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        threadPoolTaskExecutor.initialize();
        return threadPoolTaskExecutor;
    }

    @Bean
    @Qualifier("FetchKnowledgeThreadPool")
    public Executor agentKnowledgeDataExecutor() {
        ThreadPoolTaskExecutor threadPoolTaskExecutor = new ThreadPoolTaskExecutor();
        threadPoolTaskExecutor.setCorePoolSize(8);
        threadPoolTaskExecutor.setMaxPoolSize(8);
        threadPoolTaskExecutor.setQueueCapacity(100);
        threadPoolTaskExecutor.setThreadNamePrefix("fetch-knowledge-fetcher-");
        threadPoolTaskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        threadPoolTaskExecutor.initialize();
        return threadPoolTaskExecutor;
    }

    @Bean
    @Qualifier("RelateKnowledgeThreadPool")
    public Executor relateKnowledgeDataExecutor() {
        ThreadPoolTaskExecutor threadPoolTaskExecutor = new ThreadPoolTaskExecutor();
        threadPoolTaskExecutor.setCorePoolSize(10);
        threadPoolTaskExecutor.setMaxPoolSize(10);
        threadPoolTaskExecutor.setQueueCapacity(100);
        threadPoolTaskExecutor.setThreadNamePrefix("relate-knowledge-fetcher-");
        threadPoolTaskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        threadPoolTaskExecutor.initialize();
        return threadPoolTaskExecutor;
    }

    @Bean
    @Qualifier("RelateIndexThreadPool")
    public Executor relateIndexDataExecutor() {
        ThreadPoolTaskExecutor threadPoolTaskExecutor = new ThreadPoolTaskExecutor();
        threadPoolTaskExecutor.setCorePoolSize(10);
        threadPoolTaskExecutor.setMaxPoolSize(10);
        threadPoolTaskExecutor.setQueueCapacity(100);
        threadPoolTaskExecutor.setThreadNamePrefix("relate-index-fetcher-");
        threadPoolTaskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        threadPoolTaskExecutor.initialize();
        return threadPoolTaskExecutor;
    }

    @Bean
    @Qualifier("FetchTraceThreadPool")
    public Executor traceDataExecutor() {
        ThreadPoolTaskExecutor threadPoolTaskExecutor = new ThreadPoolTaskExecutor();
        threadPoolTaskExecutor.setCorePoolSize(20);
        threadPoolTaskExecutor.setMaxPoolSize(50);
        threadPoolTaskExecutor.setQueueCapacity(10000);
        threadPoolTaskExecutor.setThreadNamePrefix("fetch-trace-config-fetcher-");
        threadPoolTaskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        threadPoolTaskExecutor.initialize();
        return threadPoolTaskExecutor;
    }

    @Bean
    @Qualifier("FetchGroupThreadPool")
    public Executor fetchGroupThreadPool() {
        ThreadPoolTaskExecutor threadPoolTaskExecutor = new ThreadPoolTaskExecutor();
        threadPoolTaskExecutor.setCorePoolSize(10);
        threadPoolTaskExecutor.setMaxPoolSize(10);
        threadPoolTaskExecutor.setQueueCapacity(10000);
        threadPoolTaskExecutor.setThreadNamePrefix("fetch-group-config-fetcher-");
        threadPoolTaskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        threadPoolTaskExecutor.initialize();
        return threadPoolTaskExecutor;
    }

    @Bean
    @Qualifier("SplitterThreadPool")
    public Executor splitterThreadPool() {
        ThreadPoolTaskExecutor threadPoolTaskExecutor = new ThreadPoolTaskExecutor();
        threadPoolTaskExecutor.setCorePoolSize(10);
        threadPoolTaskExecutor.setMaxPoolSize(10);
        threadPoolTaskExecutor.setQueueCapacity(10000);
        threadPoolTaskExecutor.setThreadNamePrefix("splitter-fetcher-");
        threadPoolTaskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        threadPoolTaskExecutor.initialize();
        return threadPoolTaskExecutor;
    }

    @Bean
    @Qualifier("FetchOcrThreadPool")
    public Executor fetchOcrThreadPool() {
        ThreadPoolTaskExecutor threadPoolTaskExecutor = new ThreadPoolTaskExecutor();
        threadPoolTaskExecutor.setCorePoolSize(5);
        threadPoolTaskExecutor.setMaxPoolSize(10);
        threadPoolTaskExecutor.setQueueCapacity(200);
        threadPoolTaskExecutor.setThreadNamePrefix("fetch-ocr-fetcher-");
        threadPoolTaskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        threadPoolTaskExecutor.initialize();
        return threadPoolTaskExecutor;
    }

}
