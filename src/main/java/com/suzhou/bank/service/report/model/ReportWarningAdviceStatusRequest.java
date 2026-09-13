package com.suzhou.bank.service.report.model;

import lombok.Data;

/**
 * 预警建议处理状态更新请求
 *
 * <p>行身份为预警建议明细的 {@code id}（一条预警信号一行）。该操作只改处理状态与处理人，
 * 预警信号内容本身不变。</p>
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
}
