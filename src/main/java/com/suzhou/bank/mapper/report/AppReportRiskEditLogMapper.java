package com.suzhou.bank.mapper.report;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.report.AppReportRiskEditLog;
import org.apache.ibatis.annotations.Mapper;

/**
 * 风险要点修改记录表 Mapper（app_report_risk_edit_log，归档表）
 *
 * @author cyj666666
 * @since 1.2.0
 */
@Mapper
public interface AppReportRiskEditLogMapper extends BaseMapper<AppReportRiskEditLog> {
}
