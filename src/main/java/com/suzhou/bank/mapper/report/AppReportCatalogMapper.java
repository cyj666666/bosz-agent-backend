package com.suzhou.bank.mapper.report;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.report.AppReportCatalog;
import org.apache.ibatis.annotations.Mapper;

/**
 * 报告目录配置表 Mapper（app_report_catalog，模板层）
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Mapper
public interface AppReportCatalogMapper extends BaseMapper<AppReportCatalog> {
}
