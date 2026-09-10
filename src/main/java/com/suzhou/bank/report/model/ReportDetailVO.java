package com.suzhou.bank.report.model;

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

    private String reportDate;

    private String reportStatus;

    private Date generateTime;

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
