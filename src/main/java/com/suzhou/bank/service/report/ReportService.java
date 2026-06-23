package com.suzhou.bank.service.report;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.Report;

/**
 * 报告服务接口
 * <p>基于 Know-Kit 分析结果和原始指标数据生成 H5 交互式贷后管理报告。
 * 报告生成时拍摄数据快照，保证历史报告内容不可变。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
public interface ReportService {

    /**
     * 基于 Know-Kit 分析结果生成报告
     * <p>报告包含客户基础信息、指标数据快照和 H5 HTML 内容。</p>
     *
     * @param customerId    客户ID
     * @param knowKitTaskId Know-Kit 分析任务ID
     * @return 生成的报告记录
     */
    Report generate(Long customerId, Long knowKitTaskId);

    /**
     * 根据ID查询报告
     */
    Report getById(Long id);

    /**
     * 报告列表分页查询
     *
     * @param customerId 按客户ID筛选，可选
     */
    Page<Report> page(int page, int size, Long customerId);

    /**
     * 获取报告的 H5 HTML 内容
     *
     * @return 报告 HTML 字符串
     */
    String getReportHtml(Long id);

    /**
     * 删除报告
     */
    void delete(Long id);
}
