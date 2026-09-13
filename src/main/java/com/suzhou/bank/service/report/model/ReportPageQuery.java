package com.suzhou.bank.service.report.model;

import lombok.Data;

/**
 * 报告列表检索条件（模板化报告列表页）
 *
 * <p>约定：所有文本字段按「包含」匹配（LIKE %值%）；{@code status} 精确匹配；
 * 时间字段为闭区间日期（{@code yyyy-MM-dd}，含当天 00:00:00 ~ 23:59:59）。
 * 全部条件为空时等价于「查全部」。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
public class ReportPageQuery {

    /** 页码，从 1 开始 */
    private int page = 1;

    /** 每页条数 */
    private int size = 10;

    /** 日检流水号（模糊） */
    private String checkTaskNo;

    /** 客户编号（模糊） */
    private String customerId;

    /** 客户名称（模糊） */
    private String customerName;

    /** 报告编号（模糊） */
    private String reportNo;

    /** 报告标题（模糊） */
    private String reportTitle;

    /** 报告状态（精确）：111 / 000 / 888 / 999 */
    private String status;

    /** 用户账号（模糊） */
    private String userNo;

    /** 创建时间范围起（yyyy-MM-dd，含当天） */
    private String createdBegin;

    /** 创建时间范围止（yyyy-MM-dd，含当天） */
    private String createdEnd;

    /** 生成（更新）时间范围起（yyyy-MM-dd，含当天） */
    private String updatedBegin;

    /** 生成（更新）时间范围止（yyyy-MM-dd，含当天） */
    private String updatedEnd;
}
