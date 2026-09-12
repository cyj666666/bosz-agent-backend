package com.suzhou.bank.service.report.model;

import lombok.Data;

/**
 * AI 风险处置状态更新请求
 * <p>行身份为 (reportNo, blockCode)：一条 analysisType=RULE 的内容块 ↔ 一条风险（1:1）。
 * 该操作只改风险列表的处置状态，正文与 riskDesc 均不变。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
public class ReportRiskStatusRequest {

    /** 报告编号 */
    private String reportNo;

    /** 内容块编号（规则类内容块） */
    private String blockCode;

    /** 目标状态：ADOPTED-已采纳 INVALID-已无效 PENDING-待处理 */
    private String status;
}
