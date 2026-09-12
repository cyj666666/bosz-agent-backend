package com.suzhou.bank.mapper.report;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.report.AppReportAiAnalysis;
import org.apache.ibatis.annotations.Mapper;

/**
 * 报告 AI 全文分析表 Mapper（app_report_ai_analysis）
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Mapper
public interface AppReportAiAnalysisMapper extends BaseMapper<AppReportAiAnalysis> {
}
