package com.suzhou.bank.service.report.model;

import lombok.Data;

/**
 * 发起报告入参（列表页「发起报告」弹框）
 *
 * <p>只收用户必填的 5 个业务字段 + 1 个选填的报告编号，其余由服务端补全：</p>
 * <ul>
 *   <li>{@code reportNo} —— <b>选填</b>；填了就用填的（对齐行内口径「传入则直接使用、跳过取号」），
 *       留空则由服务端生成（RPT + 时间戳 + 随机数）</li>
 *   <li>{@code version} —— 留空，等生成完成（888）时再赋予</li>
 *   <li>{@code status} —— 固定 {@code 111}（待开始），落表后立即异步触发加工</li>
 *   <li>{@code userNo} —— 取当前登录账号</li>
 *   <li>{@code createdAt} / {@code updatedAt} —— 交数据库默认值</li>
 * </ul>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
public class ReportCreateRequest {

    /** 客户编号（必填） */
    private String customerId;

    /** 客户名称（必填） */
    private String customerName;

    /**
     * 日检流水号（必填，详情页的入口键）
     * <p><b>防重复口径（对齐行内）</b>：只挡该流水号下的<b>在途</b>记录（111/000）；
     * 已完成（888）的不挡，因此可以对着同一流水号再发起，自然堆出 V1、V2…，
     * 详情页按 checkTaskNo 取版本号最大的那版。</p>
     */
    private String checkTaskNo;

    /** 报告标题（必填） */
    private String reportTitle;

    /** 报告类型（必填） */
    private String reportType;

    /**
     * 报告编号（<b>选填</b>）
     * <p>对齐行内口径：<b>填了就直接用填的值</b>（trim 后落库，跳过服务端取号）；
     * 留空才由服务端生成。前端发起弹框的「报告编号」输入框即此字段。</p>
     */
    private String reportNo;
}
