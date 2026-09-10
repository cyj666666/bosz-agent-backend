package com.suzhou.bank.report.model;

import lombok.Data;

/**
 * AI 风险列表项（渲染用）
 * <p>对应右侧「AI 风险识别列表」一行，数据源为 app_report_ai_risk。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
public class ReportRiskItem {

    private String blockCode;

    /** 智能体编码（与正文内容实例的关联键） */
    private String agentCode;

    private String ruleName;

    /** 风险描述（对应章节正文的同一份文案） */
    private String riskDesc;

    /** 处置状态：PENDING/ADOPTED/INVALID */
    private String status;

    /** 点击本行跳转到的正文锚点（单向） */
    private String jumpAnchorCode;

    private Integer sortNo;

    /** 所属目录编号（自内容实例带出，供列表展示"对应章节"） */
    private String catalogCode;
}
