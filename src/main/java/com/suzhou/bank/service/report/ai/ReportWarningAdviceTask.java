package com.suzhou.bank.service.report.ai;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.entity.report.AppReportWarningAdvice;
import com.suzhou.bank.entity.report.AppReportWarningAdviceBatch;
import com.suzhou.bank.mapper.ReportMapper;
import com.suzhou.bank.mapper.report.AppReportWarningAdviceBatchMapper;
import com.suzhou.bank.mapper.report.AppReportWarningAdviceMapper;
import com.suzhou.bank.service.report.ReportGenerateException;
import com.suzhou.bank.service.report.model.ReportConstants;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.Date;
import java.util.List;

/**
 * 预警建议的后台执行体
 *
 * <p>由独立线程池调用，串起「组装素材 → 取提示词 → 调大模型 → 解析表格 → 落库」。
 * 与 {@link ReportAiAnalysisTask} 同样是<b>独立 Bean</b>，避免自调用绕过代理，也让长耗时流程解耦。</p>
 *
 * <p><b>不抛异常</b>：全过程 try-catch(Throwable)，失败把批次置为 {@code FAILED} 并写 {@code failReason}
 * （超 1000 字符截断），否则线程池里的异常会让状态永远停在 RUNNING。</p>
 *
 * <p><b>不加事务</b>（与生成流程口径一致）：先落明细、最后才把批次翻成 DONE。
 * 若明细落一半失败，批次仍是 FAILED，前端不渲染该批次的明细，残留行无害；
 * 失败时还会尽力清理本批次已落的明细，让状态保持干净。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ReportWarningAdviceTask {

    private static final int FAIL_REASON_MAX = 1000;
    private static final int SNAPSHOT_ECHO_MAX = 300;

    private final AppReportWarningAdviceBatchMapper batchMapper;
    private final AppReportWarningAdviceMapper adviceMapper;
    private final ReportMapper reportMapper;
    private final WarningAdviceMaterialBuilder materialBuilder;
    private final ReportPromptService promptService;
    private final LargeModelGatewayClient gatewayClient;

    /**
     * 执行一次预警建议生成
     *
     * @param batchId app_report_warning_advice_batch.id
     */
    public void run(Long batchId) {
        AppReportWarningAdviceBatch batch = batchMapper.selectById(batchId);
        if (batch == null) {
            log.warn("预警建议任务跳过：批次不存在 id={}", batchId);
            return;
        }
        long start = System.currentTimeMillis();
        log.info("预警建议开始：batchId={} reportNo={}", batchId, batch.getReportNo());

        String material = null;
        String promptSnapshot = null;
        try {
            Report report = reportMapper.selectOne(Wrappers.<Report>lambdaQuery()
                    .eq(Report::getReportNo, batch.getReportNo())
                    .last("LIMIT 1"));

            material = materialBuilder.build(
                    batch.getReportNo(),
                    batch.getCheckTaskNo(),
                    batch.getCustomerId(),
                    batch.getCustomerName(),
                    report == null ? null : report.getReportTitle(),
                    batch.getAnalysisId());

            ReportPromptService.ResolvedPrompt prompt =
                    promptService.resolve(ReportConstants.PROMPT_WARNING_ADVICE);
            if (!StringUtils.hasText(prompt.getSystemPrompt())) {
                throw new ReportGenerateException("预警建议提示词为空：请检查 app_report_prompt 的 "
                        + ReportConstants.PROMPT_WARNING_ADVICE + " 配置");
            }
            String userPrompt = promptService.renderUserPrompt(prompt, material);
            promptSnapshot = "[system]\n" + prompt.getSystemPrompt() + "\n\n[user]\n" + userPrompt;

            LargeModelGatewayClient.LlmResult result =
                    gatewayClient.chat(prompt.getSystemPrompt(), userPrompt);

            WarningAdviceOutputParser.ParsedOutput parsed =
                    WarningAdviceOutputParser.parse(result.getContent());
            if (parsed.getRows().isEmpty() && !parsed.isTableFound() && !mentionsNoSignal(parsed.getRaw())) {
                throw new ReportGenerateException("模型输出未包含预警信号表格，无法解析（原始输出前 "
                        + SNAPSHOT_ECHO_MAX + " 字：" + truncate(parsed.getRaw(), SNAPSHOT_ECHO_MAX) + "）");
            }

            Date now = new Date();
            for (WarningAdviceOutputParser.Row row : parsed.getRows()) {
                AppReportWarningAdvice entity = new AppReportWarningAdvice();
                entity.setBatchId(batchId);
                entity.setReportNo(batch.getReportNo());
                entity.setSeqNo(row.getSeqNo());
                entity.setWarningLevel(row.getWarningLevel());
                entity.setSignalDesc(row.getSignalDesc());
                entity.setTriggerCondition(row.getTriggerCondition());
                entity.setSourceText(row.getSourceText());
                entity.setRiskDesc(row.getRiskDesc());
                entity.setChapter(row.getChapter());
                entity.setStatus(ReportConstants.RISK_PENDING);
                adviceMapper.insert(entity);
            }

            // 明细落完才把批次翻成 DONE，避免前端读到"已完成但没有明细"的中间态
            AppReportWarningAdviceBatch update = new AppReportWarningAdviceBatch();
            update.setId(batchId);
            update.setStatus(ReportConstants.ANALYSIS_STATUS_DONE);
            update.setCoreTip(parsed.getCoreTip());
            update.setPromptCode(ReportConstants.PROMPT_WARNING_ADVICE);
            update.setModelName(result.getModelName());
            update.setLmCode(result.getLmCode());
            update.setCostMillis(result.getCostMillis());
            update.setSourceSnapshot(material);
            update.setPromptSnapshot(promptSnapshot);
            update.setFailReason(null);
            update.setGenerateTime(now);
            batchMapper.updateById(update);

            log.info("预警建议完成：batchId={} reportNo={} 条目={} 总耗时={}ms",
                    batchId, batch.getReportNo(), parsed.getRows().size(),
                    System.currentTimeMillis() - start);
        } catch (Throwable e) {
            String reason = truncate(e.getMessage() == null ? e.toString() : e.getMessage(), FAIL_REASON_MAX);
            log.error("预警建议失败：batchId={} reportNo={} 原因={}", batchId, batch.getReportNo(), reason, e);
            try {
                // 尽力清掉本批次可能已落的明细，让 FAILED 批次保持干净
                adviceMapper.delete(Wrappers.<AppReportWarningAdvice>lambdaQuery()
                        .eq(AppReportWarningAdvice::getBatchId, batchId));

                AppReportWarningAdviceBatch update = new AppReportWarningAdviceBatch();
                update.setId(batchId);
                update.setStatus(ReportConstants.ANALYSIS_STATUS_FAILED);
                update.setFailReason(reason);
                update.setSourceSnapshot(material);
                update.setPromptSnapshot(promptSnapshot);
                update.setGenerateTime(new Date());
                batchMapper.updateById(update);
            } catch (Throwable inner) {
                log.error("预警建议失败状态回写也失败了：batchId={}", batchId, inner);
            }
        }
    }

    /** 模型明确说了「未发现预警信号」时，没有表格也算正常结果 */
    private static boolean mentionsNoSignal(String text) {
        if (!StringUtils.hasText(text)) {
            return false;
        }
        return text.contains("未发现预警信号") || text.contains("无预警信号")
                || text.contains("未发现风险信号");
    }

    private static String truncate(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() <= max ? value : value.substring(0, max) + "…";
    }
}
