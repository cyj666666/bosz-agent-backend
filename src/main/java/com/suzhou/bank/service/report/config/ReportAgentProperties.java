package com.suzhou.bank.service.report.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 报告内容块的智能体调用配置（report.agent.*）
 *
 * @author cyj666666
 * @since 1.4.0
 */
@Data
@Component
@ConfigurationProperties(prefix = "report.agent")
public class ReportAgentProperties {

    /**
     * 块级并发数：一个报告里有近百个内容块，每块一次大模型调用（单次数十秒），
     * 串行跑一份报告要几十分钟 —— 必须并发。
     *
     * <p>但也不能无上限：受大模型网关的并发能力约束。暂定 5，可按实测调整。</p>
     *
     * <p>⚠️ 该池只负责「单个内容块内的取数」，与 {@code reportGenerateExecutor}
     * （按报告维度的加工池）是两层，不能合并 —— 否则一份报告就会把生成池吃满，
     * 并发发起第二份报告时只能排队。</p>
     */
    private int blockPoolSize = 5;

    /** 块级并发池的队列容量（相对并发数放大，避免满队列触发 CallerRuns 把 Web 线程拖慢） */
    private int blockQueueCapacity = 200;
}
