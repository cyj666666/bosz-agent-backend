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

    /** 日检流水号（同一流水号下多个版本） */
    private String checkTaskNo;

    /** 报告版本号（如 V1/V2/V3） */
    private String version;

    /** 报告状态：111-待开始 000-进行中 888-已完成 999-失败 */
    private String status;

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
