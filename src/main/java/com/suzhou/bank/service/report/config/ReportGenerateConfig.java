package com.suzhou.bank.service.report.config;

import com.suzhou.bank.service.report.spi.DefaultReportContentProvider;
import com.suzhou.bank.service.report.spi.ReportContentProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.ThreadPoolExecutor;

/**
 * 报告生成模块配置
 * <p>① 注册内容提供者的兜底实现：容器中不存在任何 {@link ReportContentProvider} 时生效。
 * 接入真实前置加工链路时，只需提供自己的 ReportContentProvider Bean，无需改动本类。</p>
 * <p>② 注册报告实例加工的独立线程池（见 {@link #reportGenerateExecutor}）。</p>
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

    /**
     * 报告实例加工的独立线程池
     *
     * <p><b>为什么必须有独立线程池</b>：外网工程没有行内那套「生成池轮询」
     * （行内是发起落 111，再由 {@code ReportGenerateJob} 定时捞取、CAS 认领转 000），
     * 改为<b>列表点「发起」后直接触发加工</b>。加工要逐块取数、后续还要调大模型，
     * 是分钟级的长耗时 IO，不能在 Web 请求线程里同步跑（必然 HTTP 超时），
     * 也不能与 {@code reportAiAnalysisExecutor} 共用（两者会互相把对方的线程占满）。</p>
     *
     * <p>拒绝策略用 CallerRuns：队列满时由提交线程兜底执行，宁可让本次发起请求慢一点，
     * 也不能静默丢任务导致报告永远停在 111。</p>
     *
     * @param poolSize      核心线程数（report.generate.pool-size）
     * @param maxPoolSize   最大线程数（report.generate.max-pool-size）
     * @param queueCapacity 队列容量（report.generate.queue-capacity）
     */
    @Bean("reportGenerateExecutor")
    public ThreadPoolTaskExecutor reportGenerateExecutor(
            @Value("${report.generate.pool-size:2}") int poolSize,
            @Value("${report.generate.max-pool-size:4}") int maxPoolSize,
            @Value("${report.generate.queue-capacity:50}") int queueCapacity) {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(poolSize);
        executor.setMaxPoolSize(maxPoolSize);
        executor.setQueueCapacity(queueCapacity);
        executor.setKeepAliveSeconds(120);
        executor.setThreadNamePrefix("report-generate-");
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        // 关闭时等待正在跑的生成收尾，避免状态卡在 000
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(60);
        executor.initialize();
        return executor;
    }

    /**
     * 内容块级并发池（一个报告内，多个内容块并行调智能体）
     *
     * <p><b>为什么必须与 {@code reportGenerateExecutor} 分开</b>：那个池的并发单位是「一份报告」，
     * 这份报告内有近百个内容块、每块一次大模型调用（单次数十秒）。若块级并发也用它，
     * 一份报告就会把池占满，第二份报告只能排队 —— 而且它的 CallerRuns 兜底会把
     * 提交线程（也就是发起报告的 Web 请求线程）拖住。</p>
     *
     * <p>并发数由 {@code report.agent.block-pool-size} 控制（暂定 5，受大模型网关并发能力约束）。</p>
     */
    @Bean("reportBlockExecutor")
    public ThreadPoolTaskExecutor reportBlockExecutor(ReportAgentProperties properties) {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        int size = properties.getBlockPoolSize() < 1 ? 1 : properties.getBlockPoolSize();
        executor.setCorePoolSize(size);
        executor.setMaxPoolSize(size);
        executor.setQueueCapacity(properties.getBlockQueueCapacity());
        executor.setKeepAliveSeconds(120);
        executor.setThreadNamePrefix("report-block-");
        // 队列满时由调用线程兜底执行：宁可这一块慢一点，也不能丢任务（丢了块内容就是空的）
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(120);
        executor.initialize();
        return executor;
    }
}
