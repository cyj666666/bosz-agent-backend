package com.suzhou.bank.service.report.ai;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.entity.report.AppReportAiAnalysis;
import com.suzhou.bank.mapper.ReportMapper;
import com.suzhou.bank.mapper.report.AppReportAiAnalysisMapper;
import com.suzhou.bank.service.report.ReportGenerateException;
import com.suzhou.bank.service.report.model.ReportConstants;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.Date;

/**
 * AI 全文分析的后台执行体
 *
 * <p>由独立线程池调用，串起「组装素材 → 拼提示词 → 调大模型 → 落库」。
 * 落在单独 Bean 而非 ReportServiceImpl 内部方法，是为了避免自调用绕过代理、
 * 也让这个长耗时流程与报告生成逻辑解耦。</p>
 *
 * <p><b>不抛异常</b>：全过程 try-catch(Throwable)，失败一律把记录置为 {@code FAILED}
 * 并把原因写进 {@code fail_reason}（超 1000 字符截断）—— 与报告生成的口径一致，
 * 否则线程池里的异常会导致状态永远停在 RUNNING。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ReportAiAnalysisTask {

    private static final int FAIL_REASON_MAX = 1000;
    private static final int SUMMARY_MAX = 500;

    private final AppReportAiAnalysisMapper analysisMapper;
    private final ReportMapper reportMapper;
    private final AnalysisMaterialBuilder materialBuilder;
    private final ReportPromptService promptService;
    private final LargeModelGatewayClient gatewayClient;
    /** 结束事件发布器：交给 ReportAiChainListener 续接预警建议（仅链式触发时才有效果） */
    private final ApplicationEventPublisher eventPublisher;

    /**
     * 执行一次全文分析
     *
     * @param analysisId app_report_ai_analysis.id
     */
    public void run(Long analysisId) {
        AppReportAiAnalysis record = analysisMapper.selectById(analysisId);
        if (record == null) {
            log.warn("全文分析任务跳过：记录不存在 id={}", analysisId);
            return;
        }
        long start = System.currentTimeMillis();
        log.info("全文分析开始：id={} reportNo={}", analysisId, record.getReportNo());
        try {
            Report report = reportMapper.selectOne(
                    Wrappers.<Report>lambdaQuery()
                            .eq(Report::getReportNo, record.getReportNo())
                            .last("LIMIT 1"));

            String material = materialBuilder.build(
                    record.getReportNo(),
                    record.getCheckTaskNo(),
                    record.getCustomerId(),
                    record.getCustomerName(),
                    report == null ? null : report.getReportTitle());

            // 提示词优先取表 app_report_prompt（改完立即生效），没有则回落到代码兜底
            ReportPromptService.ResolvedPrompt prompt =
                    promptService.resolve(ReportConstants.PROMPT_AI_FULL_ANALYSIS);
            if (!StringUtils.hasText(prompt.getSystemPrompt())) {
                throw new ReportGenerateException("全文分析提示词为空：请检查 app_report_prompt 的 "
                        + ReportConstants.PROMPT_AI_FULL_ANALYSIS + " 配置");
            }
            String systemPrompt = prompt.getSystemPrompt();
            String userPrompt = promptService.renderUserPrompt(prompt, material);
            LargeModelGatewayClient.LlmResult result = gatewayClient.chat(systemPrompt, userPrompt);

            AppReportAiAnalysis update = new AppReportAiAnalysis();
            update.setId(analysisId);
            update.setStatus(ReportConstants.ANALYSIS_STATUS_DONE);
            update.setAnalysisContent(result.getContent());
            update.setSummary(extractSummary(result.getContent()));
            update.setModelName(result.getModelName());
            update.setLmCode(result.getLmCode());
            update.setCostMillis(result.getCostMillis());
            update.setSourceSnapshot(material);
            update.setPromptSnapshot("[system]\n" + systemPrompt + "\n\n[user]\n" + userPrompt);
            update.setFailReason(null);
            update.setGenerateTime(new Date());
            analysisMapper.updateById(update);

            log.info("全文分析完成：id={} reportNo={} 总耗时={}ms 正文长度={}",
                    analysisId, record.getReportNo(), System.currentTimeMillis() - start,
                    result.getContent().length());
            publishCompleted(record.getReportNo(), analysisId, true);
        } catch (Throwable e) {
            String reason = truncate(e.getMessage() == null ? e.toString() : e.getMessage(), FAIL_REASON_MAX);
            log.error("全文分析失败：id={} reportNo={} 原因={}", analysisId, record.getReportNo(), reason, e);
            try {
                AppReportAiAnalysis update = new AppReportAiAnalysis();
                update.setId(analysisId);
                update.setStatus(ReportConstants.ANALYSIS_STATUS_FAILED);
                update.setFailReason(reason);
                update.setGenerateTime(new Date());
                analysisMapper.updateById(update);
            } catch (Throwable inner) {
                log.error("全文分析失败状态回写也失败了：id={}", analysisId, inner);
            }
            // 失败同样续接：预警建议对全文分析是软依赖，不能被一起拖死
            publishCompleted(record.getReportNo(), analysisId, false);
        }
    }

    /** 发布结束事件（失败不影响全文分析已落库的最终状态） */
    private void publishCompleted(String reportNo, Long analysisId, boolean success) {
        try {
            eventPublisher.publishEvent(new ReportAiAnalysisCompletedEvent(reportNo, analysisId, success));
        } catch (Throwable e) {
            log.error("发布全文分析结束事件失败：reportNo={} analysisId={}", reportNo, analysisId, e);
        }
    }

    /**
     * 从分析正文里抽一段摘要（用于列表展示）
     * <p>取首个非空段落，去标签、截断；抽不到就返回 null，不做兜底编造。</p>
     */
    private String extractSummary(String html) {
        if (!StringUtils.hasText(html)) {
            return null;
        }
        String text = AnalysisMaterialBuilder.htmlToText(html);
        if (!StringUtils.hasText(text)) {
            return null;
        }
        for (String line : text.split("\n")) {
            String trimmed = line.trim();
            if (trimmed.length() >= 15) {
                return truncate(trimmed, SUMMARY_MAX);
            }
        }
        return truncate(text.trim(), SUMMARY_MAX);
    }

    private static String truncate(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() <= max ? value : value.substring(0, max);
    }
}
