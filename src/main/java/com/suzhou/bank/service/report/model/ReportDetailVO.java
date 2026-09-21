package com.suzhou.bank.service.report.model;

import lombok.Data;

import java.util.Date;
import java.util.List;

/**
 * 报告详情（三栏式渲染数据源）
 * <p>左栏取 catalogs，中栏取 headBlocks + catalogs[].blocks，右栏取 risks。
 * 数据全部来自实例层一次查询，空数据策略随块返回由前端决定隐藏或占位。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
public class ReportDetailVO {

    private String reportNo;

    private String customerId;

    private String customerName;

    private String reportTitle;

    /**
     * 用户编号（用户账号，上游预生成报告时写入 report.user_no）
     * <p>🔴 2026-09-21 口径：链接溯源换一次性链接时，{@code userId} 取<b>本字段</b>
     * （= 报告发起人），<b>不是</b>当前登录态账号。</p>
     */
    private String userNo;

    /** 日检流水号（同一流水号下多个版本） */
    private String checkTaskNo;

    /** 报告版本号（1/2/3…，"V"前缀由前端拼接） */
    private Integer version;

    /** 报告状态：111-待开始 000-进行中 888-已完成（唯一终态）999-失败（预留状态，正常链路不再产生） */
    private String status;

    /**
     * 失败原因 / 软备注：部分内容块生成失败或模板/落库级错误的汇总，无失败时为空
     * <p><b>注意 status 仍为 888</b>：本工程对齐行内口径，<b>888 是唯一终态</b>，
     * 单个内容块失败不中断整份报告，原因汇总到这里由前端在详情页顶部显示提示条
     * （Vue3 详情页读 {@code detail.failReason} 渲染 {@code .report-fail-note}）。</p>
     */
    private String failReason;

    /** 更新时间（生成完成/失败时刷新，即报告"生成时间"） */
    private Date updatedAt;

    /** 报告级内容块（catalogCode 为空，如报告头大标题），渲染在正文最上方 */
    private List<ReportBlockVO> headBlocks;

    /** 目录树（含各目录下的内容块） */
    private List<ReportCatalogNode> catalogs;

    /** AI 风险识别列表 */
    private List<ReportRiskItem> risks;

    /** 风险统计：待处理 */
    private int riskPending;

    /** 风险统计：已采纳 */
    private int riskAdopted;

    /** 风险统计：已无效 */
    private int riskInvalid;
}
