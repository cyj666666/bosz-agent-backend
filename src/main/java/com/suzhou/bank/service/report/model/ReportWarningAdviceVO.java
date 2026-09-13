package com.suzhou.bank.service.report.model;

import lombok.Data;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * 报告预警建议（详情页「预警建议」页签数据源）
 *
 * <p>把「批次 + 明细」合成一个对象返回，前端一次请求即可渲染：</p>
 * <ul>
 *   <li>批次级：{@link #status}（RUNNING/DONE/FAILED）、{@link #coreTip} 核心提示、
 *       模型信息、失败原因、触发人与时间；</li>
 *   <li>明细级：{@link #advices} 逐条预警信号（含各自处理状态，供逐条采纳/不采纳）；</li>
 *   <li>统计：{@link #redCount}/{@link #orangeCount}/{@link #yellowCount} —— 由明细按等级
 *       <b>现算</b>，不在表里存，避免与实际明细不一致。</li>
 * </ul>
 *
 * <p>无批次记录时返回 {@code null}（前端展示"尚未生成"空态）。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
public class ReportWarningAdviceVO {

    /** 批次ID */
    private Long id;

    /** 报告编号 */
    private String reportNo;

    /** 日检流水号 */
    private String checkTaskNo;

    /** 基于哪一次全文分析生成 */
    private Long analysisId;

    /** RUNNING / DONE / FAILED */
    private String status;

    /** 核心提示（模型总结，1~3 句话概括最需关注的风险） */
    private String coreTip;

    /** 所用提示词编码 */
    private String promptCode;

    /** 实际调用的模型名 */
    private String modelName;

    /** 触发人姓名（取不到回落账号） */
    private String operatorName;

    private String operatorNo;

    /** 大模型调用耗时（毫秒） */
    private Long costMillis;

    /** 失败原因（status=FAILED 时有值） */
    private String failReason;

    /** 生成完成时间 */
    private Date generateTime;

    /** 创建（触发）时间 */
    private Date inputtime;

    /** 逐条预警信号（按 seqNo 升序） */
    private List<ReportWarningAdviceItem> advices = new ArrayList<>();

    /** 红色预警条数（现算） */
    private int redCount;

    /** 橙色预警条数（现算） */
    private int orangeCount;

    /** 黄色预警条数（现算） */
    private int yellowCount;
}
