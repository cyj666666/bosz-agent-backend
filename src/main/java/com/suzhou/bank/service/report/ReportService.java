package com.suzhou.bank.service.report;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.Report;

public interface ReportService {
    /** 基于 Know-Kit 结果生成报告 */
    Report generate(Long customerId, Long knowKitTaskId);

    /** 查询报告 */
    Report getById(Long id);

    /** 报告列表 */
    Page<Report> page(int page, int size, Long customerId);

    /** 获取报告 HTML */
    String getReportHtml(Long id);

    /** 删除报告 */
    void delete(Long id);
}
