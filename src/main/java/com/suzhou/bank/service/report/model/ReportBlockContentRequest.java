package com.suzhou.bank.service.report.model;

import lombok.Data;

/**
 * 规则类正文内容修改请求
 * <p>更新一条内容块实例的 content，并同步其对应的 AI 风险 riskDesc（两份为同一份文案），
 * 同时把该风险状态置为 ADOPTED-已采纳。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
public class ReportBlockContentRequest {

    /** 报告编号 */
    private String reportNo;

    /** 内容块编号（规则类内容块） */
    private String blockCode;

    /** 新的正文内容（HTML 片段） */
    private String content;
}
