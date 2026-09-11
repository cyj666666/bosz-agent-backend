package com.suzhou.bank.report.model;

import lombok.Data;

/**
 * 报告生成结果
 * <p>返回本次生成的报告编号与各项落库统计，便于调用方核对与排查。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
public class ReportGenerateResult {

    /** 报告编号 */
    private String reportNo;

    /** 客户编号（app_report_info.customerId 为字符串类型） */
    private String customerId;

    private String customerName;

    private String reportTitle;

    /** 报告状态：111-待开始 000-进行中 888-已完成 999-失败 */
    private String reportStatus;

    /** 模板内容块总数 */
    private int blockTotal;

    /** 生成的内容实例数 */
    private int contentTotal;

    /** 其中内容为空（未取到前置加工数据）的实例数 */
    private int contentEmpty;

    /** 其中按 emptyStrategy=HIDE 需整块隐藏的实例数 */
    private int contentHidden;

    /** 生成的 AI 风险明细数（= analysisType=RULE 的内容块数） */
    private int riskTotal;

    /** 是否成功（false 时配合 failReason 查看失败详情） */
    private boolean success;

    /** 失败原因：技术类或业务类异常详情，成功时为空 */
    private String failReason;

    /** 生成耗时（毫秒） */
    private long costMs;
}
