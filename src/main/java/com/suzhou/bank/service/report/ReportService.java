package com.suzhou.bank.service.report;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.service.report.model.ReportDetailVO;
import com.suzhou.bank.service.report.model.ReportGenerateResult;
import com.suzhou.bank.service.report.model.ReportRiskEditLogVO;
import com.suzhou.bank.service.report.model.ReportVersionVO;

import java.util.List;

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
     * 查询某日检流水号（checkTaskNo）下的版本列表（供版本下拉框）
     * <p>包含：进行中（000，即"新报告生成中"）与已完成（888 且已赋予版本号）的版本；
     * 按 id 倒序（最新插入的在前，故进行中的新版本排最前），返回每个版本的
     * reportNo / version / status / updatedAt。</p>
     *
     * @param checkTaskNo 日检流水号
     * @return 版本列表（空流水号返回空列表）
     */
    List<ReportVersionVO> versions(String checkTaskNo);

    /**
     * 查询某日检流水号（checkTaskNo）下最新版本的报告详情
     * <p>等价于「取该流水号下最新版本 reportNo → 查详情」，供列表进入详情页时一步到位。</p>
     *
     * @param checkTaskNo 日检流水号
     * @return 最新版本报告详情
     */
    ReportDetailVO latest(String checkTaskNo);

    /**
     * 更新报告：在指定日检流水号下新建一份报告（新版本）
     * <p>复制该流水号下最新已完成版本的字段，自动生成随机报告编号，版本号自增 1，
     * 状态置为 000-进行中，并异步触发报告生成（完成后置 888）。</p>
     * <p>若该流水号下已有进行中的报告，直接拒绝（避免重复生成）。</p>
     *
     * @param checkTaskNo 日检流水号
     * @return 新建的进行中版本（reportNo / version / status）
     */
    ReportVersionVO renew(String checkTaskNo);

    /**
     * 更新 AI 风险处置状态（采纳 / 无效 / 待处理）
     * <p>行身份为 (reportNo, blockCode)——一条 analysisType=RULE 的内容块 ↔ 一条风险。
     * 只更新 {@code app_report_ai_risk.status}；正文与 riskDesc 均不变
     * （"无效"表示该风险不参与报告，前端渲染时整块隐藏）。</p>
     *
     * @param reportNo  报告编号
     * @param blockCode 内容块编号
     * @param status    ADOPTED-已采纳 / INVALID-已无效 / PENDING-待处理（其它值按 PENDING 处理）
     */
    void updateRiskStatus(String reportNo, String blockCode, String status);

    /**
     * 修改规则类正文内容（同事务同步风险列表文案）
     * <p>更新 {@code app_report_content_instance.content}，并同步
     * {@code app_report_ai_risk.riskDesc}（两者为同一份文案，必须同步，
     * 否则列表文案与正文不一致、且前端正文定位会失配），
     * 同时把该风险状态置为 ADOPTED-已采纳。</p>
     * <p>本方法声明事务：正文与列表副本必须同时成功或同时失败。</p>
     *
     * @param reportNo     报告编号
     * @param blockCode    内容块编号
     * @param content      新的正文内容（HTML 片段，不允许为空）
     * @param operatorNo   操作人账号（写入修改记录）
     * @param operatorName 操作人姓名（写入修改记录；为空时回落账号）
     */
    void updateBlockContent(String reportNo, String blockCode, String content,
                            String operatorNo, String operatorName);

    /**
     * 查询某风险要点的修改记录（归档维度：同日检流水号 + 同风险要点）
     * <p>按修改时间<b>倒序</b>返回（最新在上），前端按 1、2、3… 编号展示为
     * 「N、{修改人} {修改时间} 修改为：{修改后文案}」。</p>
     * <p>归档维度为 checkTaskNo + blockCode（而非 reportNo），故同一日检流水号下
     * 各版本的修改历史会累计展示，跨版本可追溯。</p>
     *
     * @param checkTaskNo 日检流水号
     * @param blockCode   风险要点编号（= 内容块编号）
     * @return 修改记录列表（无记录返回空列表）
     */
    List<ReportRiskEditLogVO> editHistory(String checkTaskNo, String blockCode);

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
