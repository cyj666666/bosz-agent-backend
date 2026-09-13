package com.suzhou.bank.service.report.ai;

import com.suzhou.bank.service.report.ReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 「一键串行」的续接器：全文分析结束后启动预警建议
 *
 * <p>监听 {@link ReportAiAnalysisCompletedEvent}，调用
 * {@link ReportService#launchChainedWarningAdvice} 把预先插好的 {@code PENDING} 批次
 * 翻成 {@code RUNNING} 并投递执行。</p>
 *
 * <p><b>只会对链式触发生效</b>：续接的依据是"该报告下存在 {@code PENDING} 批次"。
 * 单独触发全文分析（如直接调 {@code /instance/ai-analysis/generate}）不会预插批次，
 * 因此这里查不到待续批次、什么也不做。</p>
 *
 * <p>监听器默认是<b>同步</b>执行的（在全文分析线程里）—— 续接动作只有一次 DB 更新
 * 加一次线程池投递，开销极小，无需异步。异常自行吞掉并记日志，绝不能让续接失败
 * 影响全文分析已落库的最终状态。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ReportAiChainListener {

    private final ReportService reportService;

    @EventListener
    public void onAnalysisCompleted(ReportAiAnalysisCompletedEvent event) {
        log.info("全文分析结束，尝试续接预警建议：reportNo={} analysisId={} success={}",
                event.getReportNo(), event.getAnalysisId(), event.isSuccess());
        try {
            reportService.launchChainedWarningAdvice(event.getReportNo(), event.getAnalysisId());
        } catch (Throwable e) {
            log.error("链式续接预警建议失败：reportNo={} analysisId={} 原因={}",
                    event.getReportNo(), event.getAnalysisId(), e.getMessage(), e);
        }
    }
}
