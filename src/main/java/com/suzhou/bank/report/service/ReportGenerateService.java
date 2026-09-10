package com.suzhou.bank.report.service;

import com.suzhou.bank.report.model.ReportDetailVO;
import com.suzhou.bank.report.model.ReportGenerateResult;

/**
 * 模板驱动的报告实例生成服务
 * <p>本服务只负责"模板表 + 实例表"的逻辑，不负责报告记录的发起：
 * {@code app_report_info} 的记录由上游预先生成（初始状态 111-待开始），
 * 定时任务轮询到 111 后调用本服务完成加工。</p>
 * <p>与本工程既有报告逻辑（Report / ReportService）完全独立。</p>
 * <p><b>状态流转</b>：000-进行中 → 888-已完成 / 999-失败。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
public interface ReportGenerateService {

    /**
     * 生成报告实例（含状态流转，定时任务直接调用本方法）
     * <p>流程：校验报告记录与状态 → 置 000 进行中 → 加工（{@link #process(String)}）
     * → 置 888 已完成；加工抛异常时置 999 失败并向上抛出。</p>
     * <p>本方法不声明事务；互斥由上游统一加分布式锁保证。</p>
     *
     * @param reportNo 报告编号（对应 app_report_info.reportNo）
     * @return 生成结果（各项统计）
     */
    ReportGenerateResult generate(String reportNo);

    /**
     * 纯加工：按模板生成内容实例与 AI 风险明细（自行管理状态时调用）
     * <p>以模板表为唯一驱动：读模板目录与内容块 → 逐块落实例（结构性字段快照、位置锚点）
     * → analysisType=RULE 的内容块一对一生成风险明细。</p>
     * <p>不声明事务、不做重跑清理：报告编号每次唯一，重复加工由实例表唯一键拦截。</p>
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
}
