package com.suzhou.bank.service.report.spi;

/**
 * 报告全文分析的「外部数据域」扩展点（**预留位置，逐表实现**）
 *
 * <p>全文分析的素材 = 报告正文摘取 + 本接口提供的外部数据 + 提示词。
 * 「要查库里哪些别的表」目前尚未确定，因此把每一张（或每一组）外部表做成一个实现类，
 * 由 Spring 自动收集成 {@code List<ReportAnalysisDataSource>} 注入给素材组装器：</p>
 *
 * <p>接入方式（不用改任何既有代码）：</p>
 * <pre>
 * &#64;Component
 * public class IndicatorAnalysisDataSource implements ReportAnalysisDataSource {
 *     public String code()  { return "indicator"; }
 *     public String label() { return "关键指标数据"; }
 *     public String load(String reportNo, String customerId, String customerName) {
 *         // 查 indicator_data 等表，返回拼好的文本片段；无数据返回 null
 *     }
 * }
 * </pre>
 *
 * <p>约定：返回内容应为**纯文本或简单表格文本**，由素材组装器统一加小节标题；
 * 返回 {@code null} 或空串表示该数据域本次无数据，会被跳过（不会在素材里留空标题）。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
public interface ReportAnalysisDataSource {

    /** 数据域编码（日志与去重用，如 customer / indicator / credit / judicial） */
    String code();

    /** 数据域中文名（写入素材的小节标题，如「关键指标数据」） */
    String label();

    /**
     * 取该报告在本数据域下的素材文本
     *
     * @param reportNo     报告编号（⚠️ 2026-09-19 新增：业务表普遍按 {@code reportno} 关联，
     *                     只给 customerId 时同一客户的多份报告会互相串数据）
     * @param customerId   客户编号
     * @param customerName 客户名称（便于按名称查外部表）
     * @return 素材文本；无数据返回 null
     */
    String load(String reportNo, String customerId, String customerName);
}
