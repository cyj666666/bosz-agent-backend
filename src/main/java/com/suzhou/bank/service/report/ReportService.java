package com.suzhou.bank.service.report;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.service.report.model.ReportDetailVO;
import com.suzhou.bank.service.report.model.ReportGenerateResult;

/**
 * 报告服务（模板驱动的报告实例生成）
 * <p>本服务只负责"模板表 + 实例表"的逻辑，不负责报告记录的发起：
 * {@code report} 表的记录由上游预先生成（初始状态 111-待开始），
 * 定时任务轮询到 111 后调用本服务完成加工。</p>
 * <p><b>状态流转</b>：000-进行中 → 888-已完成 / 999-失败。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
public interface ReportService {

    /**
     * 生成报告实例（含状态流转，定时任务直接调用本方法）
     * <p>流程：校验报告记录与状态 → 置 000 进行中 → 加工（{@link #process(String)}）
     * → 置 888 已完成；加工抛异常时置 999 失败并向上抛出。</p>
     * <p>本方法不声明事务；互斥由上游统一加分布式锁保证。</p>
     *
     * @param reportNo 报告编号（对应 report.report_no）
     * @return 生成结果（各项统计）
     */
    ReportGenerateResult generate(String reportNo);

    /**
     * 纯加工：按模板生成内容实例与 AI 风险明细（自行管理状态时调用）
     * <p>以模板表为唯一驱动：读模板目录与内容块 → 逐块落实例（结构性字段快照、位置锚点）
     * → analysisType=RULE 的内容块一对一生成风险明细。</p>
     * <p>不声明事务、不做重跑清理：报告编号每次唯一，重复加工由实例表唯一键拦截。</p>
     * <p>不抛异常：失败时记录日志并返回 success=false + failReason。</p>
     *
     * @param reportNo 报告编号
     * @return 加工结果
     */
    ReportGenerateResult process(String reportNo);

    /**
     * 读取报告详情（三栏式渲染数据源）
     * <p>返回报告头内容块、目录树（含内容块与空数据策略）、AI 风险列表与风险统计。</p>
     *
     * @param reportNo 报告编号
     * @return 报告详情
     */
    ReportDetailVO detail(String reportNo);

    /**
     * 报告记录分页查询（报告列表页用）
     * <p>直接查 report，供列表页展示并跳转到详情。</p>
     *
     * @param page       页码
     * @param size       每页条数
     * @param customerId 按客户编号筛选，可选
     * @return 报告记录分页数据
     */
    Page<Report> page(int page, int size, String customerId);
}
