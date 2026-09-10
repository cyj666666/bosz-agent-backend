package com.suzhou.bank.mapper.report;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.report.AppReportInfo;
import org.apache.ibatis.annotations.Mapper;

/**
 * 贷后报告主表 Mapper（app_report_info）
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Mapper
public interface AppReportInfoMapper extends BaseMapper<AppReportInfo> {
}
