package com.suzhou.bank.agent.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.ThreadPoolExecutor;

/**
 * agent 模块专用线程池
 *
 * <p><b>为什么必须单独定义（而不是复用宿主已有的）</b>：</p>
 * <p>源工程 {@code IndexConfigServiceImpl} 里有一句 {@code @Autowired private Executor executor;}，
 * 用于异步处理「接口取数字段」（{@code handleApiIntfField}，会发起外部 HTTP 调用，耗时不可控）。
 * 源工程能跑，是因为它的容器里存在一个可用的 {@code Executor}。</p>
 *
 * <p>本工程移植后出现了两个问题：</p>
 * <ol>
 *   <li><b>会错误地注入到报告模块的线程池</b>：宿主 {@code ReportAiAnalysisConfig} 声明了
 *       {@code @Bean("reportAiAnalysisExecutor")}（core=2/max=4/queue=50）。
 *       而 Spring Boot 的 {@code TaskExecutionAutoConfiguration#applicationTaskExecutor}
 *       带 {@code @ConditionalOnMissingBean(Executor.class)}，检测到已有 Executor 就直接退让，
 *       于是容器里<b>只剩报告那一个</b> Executor —— 指标配置的异步任务会跑进报告的 AI 分析池子。</li>
 *   <li><b>违反模块解耦原则</b>：会让指标功能的表现受报告配置影响（报告 AI 分析长耗时任务占满核心线程时，
 *       指标请求会被 CallerRunsPolicy 丢回 HTTP 线程自己执行），且线程名前缀是
 *       {@code report-ai-analysis-}，排查问题时极易误导。</li>
 * </ol>
 *
 * <p>因此这里为 agent 模块声明一个独立线程池，并在注入处用 {@code @Qualifier} 显式指定。
 * 参数按"低频、短任务、可容忍排队"的场景设定。</p>
 *
 * <p><b>注意</b>：本类会让容器内出现<b>两个</b> {@code TaskExecutor} 类型的 Bean。
 * 因此 {@code @Async} 注解（不带 value 时）将无法自动选定线程池——
 * 目前全工程未开启 {@code @EnableAsync}，无影响；若将来要开，需额外声明一个名为
 * {@code taskExecutor} 的 Bean，否则 Spring 会退化为每次新建线程的 {@code SimpleAsyncTaskExecutor}。</p>
 */
@Configuration
public class AgentTaskExecutorConfig {

    @Bean("agentTaskExecutor")
    public ThreadPoolTaskExecutor agentTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(8);
        executor.setQueueCapacity(200);
        executor.setKeepAliveSeconds(120);
        executor.setThreadNamePrefix("agent-index-");
        // 队列满时由提交线程自己执行，保证任务不丢（与宿主报告模块的策略一致）
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(30);
        executor.initialize();
        return executor;
    }
}
