package com.suzhou.bank.service.report.ai;

import com.suzhou.bank.entity.report.AppReportAiAnalysis;
import com.suzhou.bank.mapper.report.AppReportAiAnalysisMapper;
import com.suzhou.bank.service.report.model.ReportConstants;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * 预警建议素材组装器
 *
 * <p>在 {@link AnalysisMaterialBuilder} 产出的报告素材（正文摘取 + 风险要点清单 + 外部数据）
 * 之后，追加一节【AI 全文分析结论】—— 提示词要求「结合签署意见与 AI 全文分析结论」来做定级，
 * 所以必须把该报告已有的一次成功分析结果一并喂进去。</p>
 *
 * <p>签署意见不单独取数：行内数据来源是模块明细表，本工程暂无实体；若前置加工已把签署意见
 * 写进报告正文块，则第 1 步的报告素材里天然就带了（见 2026-09-13 的口径）。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class WarningAdviceMaterialBuilder {

    private final AnalysisMaterialBuilder materialBuilder;
    private final AppReportAiAnalysisMapper analysisMapper;

    /**
     * 组装预警建议素材
     *
     * @param analysisId 指定基于哪次全文分析；为空时取该报告最新一次成功的分析
     */
    public String build(String reportNo, String checkTaskNo, String customerId,
                        String customerName, String reportTitle, Long analysisId) {
        StringBuilder sb = new StringBuilder(8192);
        sb.append(materialBuilder.build(reportNo, checkTaskNo, customerId, customerName, reportTitle));
        appendAnalysisConclusion(sb, reportNo, analysisId);
        return sb.toString();
    }

    /** 追加全文分析结论；没有可用分析时整节省略（不编造、不阻断） */
    private void appendAnalysisConclusion(StringBuilder sb, String reportNo, Long analysisId) {
        AppReportAiAnalysis analysis = analysisId == null
                ? latestDoneAnalysis(reportNo) : analysisMapper.selectById(analysisId);
        if (analysis == null || !StringUtils.hasText(analysis.getAnalysisContent())) {
            log.info("预警建议素材：未找到可用的全文分析结论，本节跳过（reportNo={}）", reportNo);
            return;
        }
        String text = AnalysisMaterialBuilder.htmlToText(analysis.getAnalysisContent());
        if (!StringUtils.hasText(text)) {
            return;
        }
        sb.append("\n【AI 全文分析结论】\n");
        sb.append("（来源：报告 ").append(reportNo)
                .append(" 的全文分析，生成时间 ").append(analysis.getGenerateTime()).append("）\n");
        sb.append("    ").append(text.replace("\n", "\n    ")).append('\n');
    }

    /** 该报告最新一次成功的全文分析 */
    private AppReportAiAnalysis latestDoneAnalysis(String reportNo) {
        return analysisMapper.selectOne(
                com.baomidou.mybatisplus.core.toolkit.Wrappers.<AppReportAiAnalysis>lambdaQuery()
                        .eq(AppReportAiAnalysis::getReportNo, reportNo)
                        .eq(AppReportAiAnalysis::getStatus, ReportConstants.ANALYSIS_STATUS_DONE)
                        .orderByDesc(AppReportAiAnalysis::getId)
                        .last("LIMIT 1"));
    }
}
