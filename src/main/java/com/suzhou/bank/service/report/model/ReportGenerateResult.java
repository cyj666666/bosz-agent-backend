package com.suzhou.bank.service.report.model;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

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

    /** 客户编号（report.customer_id 为字符串类型） */
    private String customerId;

    private String customerName;

    private String reportTitle;

    /** 报告状态：111-待开始 000-进行中 888-已完成 999-失败 */
    private String reportStatus;

    /**
     * 本次生成赋予的版本号（置 888 时写入；失败/未完成时为 null）
     * <p>版本号 = 该日检流水号下已有记录的最大版本号 + 1（首份为 V1）。
     * 只有 888 且 version 非空的记录才会被 {@code versions()} / {@code latest()} 认作有效版本。</p>
     */
    private Integer version;

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

    /**
     * 块级失败清单（每项形如「[blockCode/块名] 原因」）
     * <p>分块隔离的产物：单块加工异常不中断整份报告，原因逐条收在这里，
     * 由 {@code buildBlockFailureNote} 汇总成 {@code fail_reason} 软备注（报告仍置 888）。
     * 为 null/空表示全部块成功。</p>
     */
    private List<String> blockFailures = new ArrayList<>();
}
