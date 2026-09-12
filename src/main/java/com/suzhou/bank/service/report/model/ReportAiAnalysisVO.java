package com.suzhou.bank.service.report.model;

import lombok.Data;

import java.util.Date;

/**
 * 报告 AI 全文分析结果项（详情页「AI分析全文」面板数据源）
 *
 * <p>挂在报告编号上、保留多次：列表按 id 倒序（最新在上），前端取首条作为「当前展示的分析」。
 * {@link #status} 三态：</p>
 * <ul>
 *   <li>{@code RUNNING} 进行中 —— 前端展示「分析进行中」提示，用户可关闭（后台继续跑），
 *       再次进入凭状态判断；</li>
 *   <li>{@code DONE} 已完成 —— 渲染 {@link #analysisContent}；</li>
 *   <li>{@code FAILED} 失败 —— 展示 {@link #failReason}。</li>
 * </ul>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
public class ReportAiAnalysisVO {

    private Long id;

    /** 报告编号 */
    private String reportNo;

    /** 日检流水号 */
    private String checkTaskNo;

    /** RUNNING / DONE / FAILED */
    private String status;

    /** 分析正文（成品 HTML 片段，前端直接渲染） */
    private String analysisContent;

    /** 综合结论摘要 */
    private String summary;

    /** 大模型给出的总体风险等级 */
    private String riskLevel;

    /** 实际调用的模型名 */
    private String modelName;

    /** 触发人姓名（取不到回落账号） */
    private String operatorName;

    private String operatorNo;

    /** 大模型调用耗时（毫秒） */
    private Long costMillis;

    /** 失败原因（status=FAILED 时有值） */
    private String failReason;

    /** 分析完成时间 */
    private Date generateTime;

    /** 创建（触发）时间 */
    private Date inputtime;
}
