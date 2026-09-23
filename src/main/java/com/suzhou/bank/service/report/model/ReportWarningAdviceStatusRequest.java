package com.suzhou.bank.service.report.model;

import lombok.Data;

/**
 * 预警建议处理状态更新请求
 *
 * <p>行身份为预警建议明细的 {@code id}（一条预警信号一行）。该操作只改处理状态与处理人，
 * 预警信号内容本身不变。</p>
 *
 * <p>🆕 2026-09-23（测试反馈 #7）：新增两个**信贷跳转页专用**的入参 —— 它们来自
 * 详情页 {@code /api/credit/resolve} 解密出来的业务参数，前端「采纳」时原样回传，
 * 后端据此决定要不要把这条预警信号推给信贷。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
public class ReportWarningAdviceStatusRequest {

    /** 预警建议明细ID */
    private Long id;

    /** 目标状态：ADOPTED-已采纳 INVALID-无效 PENDING-待处理 */
    private String status;

    /**
     * 信贷入参 {@code isRiskApply}：点击预警信号采纳时是否推送预警信号给信贷
     *
     * <p>🔴 <b>不返回或返回空 ⇒ 默认 true</b>（客户 2026-09-23 定的默认值，与
     * {@code isReSubmit} 同一套口径）。只有显式的 {@code "false"/"0"/"no"/"n"} 才表示不推送。</p>
     *
     * <p>⚠️ <b>该字段只在信贷跳转场景才有值</b> —— {@code /api/credit/resolve} 服务的是
     * {@code /credit/report} 独立页；列表 → 详情那条路径不经过它，前端会**显式传 {@code "false"}**。
     * 换句话说：契约里的"缺省即 true"是**信贷页在 resolve 缺字段时补值**兑现的，
     * 不是"后端见不到这个字段就当推送"。</p>
     *
     * <p>⚠️ 类型用 {@code String} 而不是 {@code Boolean}：该值原样来自信贷 SM4 报文里的 JSON，
     * 可能是字符串 {@code "false"} 也可能是布尔 {@code false} —— 用 String 两种都能接住
     * （Jackson 会把标量强转成字符串），再按 {@code ReportServiceImpl#flagTrue} 统一判定。</p>
     */
    private String isRiskApply;

    /**
     * 信贷入参 {@code workid}（审批任务编号）
     *
     * <p>来源 = 详情页 {@code /api/credit/resolve} 返回的 params；推送时原样带给信贷。
     * 前端已做**大小写兼容**（{@code workid} / {@code workId} 都能取到）。</p>
     */
    private String workid;
}
