package com.suzhou.bank.mapper.report;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.report.AppReportActionLog;
import org.apache.ibatis.annotations.Mapper;

/**
 * 报告用户行为记录表 Mapper（app_report_action_log）
 *
 * <p>只用到 {@code BaseMapper} 的 insert（流水只增不改），暂无自定义方法。</p>
 *
 * @author 曹陆宇
 * @since 1.4.0
 */
@Mapper
public interface AppReportActionLogMapper extends BaseMapper<AppReportActionLog> {
}
