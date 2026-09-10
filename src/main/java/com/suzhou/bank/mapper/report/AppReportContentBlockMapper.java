package com.suzhou.bank.mapper.report;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.report.AppReportContentBlock;
import org.apache.ibatis.annotations.Mapper;

/**
 * 报告正文内容块配置表 Mapper（app_report_content_block，模板层）
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Mapper
public interface AppReportContentBlockMapper extends BaseMapper<AppReportContentBlock> {
}
