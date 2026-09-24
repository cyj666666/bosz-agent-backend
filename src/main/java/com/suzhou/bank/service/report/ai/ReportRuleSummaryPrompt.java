package com.suzhou.bank.service.report.ai;

/**
 * 风险要点总结提示词的<b>兜底</b>常量
 *
 * <p>提示词首选来源是表 {@code app_report_prompt}（promptCode = {@code RULE_SUMMARY}），
 * 由 {@link ReportPromptService} 读取；表里没有或读不到时才回落到本类
 * —— 与 {@link ReportAiAnalysisPrompt} / {@link ReportWarningAdvicePrompt} 完全同构。</p>
 *
 * <p>系统提示词正文放在 {@code resources/report-prompt/RULE_SUMMARY.system.txt}，
 * 改完请同步更新 {@code sql/报告详情表设计/报告提示词表_新增_风险要点总结.sql}。</p>
 *
 * <p>⚠️ <b>本提示词与代码里的解析契约强耦合</b>：正文里的 {@code #PICK#} 行、{@code #TAIL#} 分隔行
 * 分别对应 {@code AgentReportContentProvider} 的 {@code PICK_MARK} / {@code TAIL_MARK}，
 * 「最多 5 条」对应 {@code MAX_RISK_ITEMS}。改这三处中任何一个，另一处必须同步改，
 * 否则后端解析不到标记会走兜底逻辑（取模板顺序前 N 条），行为与预期不符。
 * 也因为这种强耦合，该条提示词在「通用提示词管理」页面<b>不展示、不可编辑</b>
 * （{@code app_report_prompt.sceneType = 'SYSTEM'}）。</p>
 *
 * @author 曹陆宇
 * @since 1.0.0
 */
public final class ReportRuleSummaryPrompt {

    private static final String SYSTEM_FILE = "RULE_SUMMARY.system.txt";

    private ReportRuleSummaryPrompt() {
    }

    /** 系统提示词兜底文本（表里没配时使用） */
    public static String systemPrompt() {
        return PromptResources.load(SYSTEM_FILE);
    }

    /**
     * 用户提示词模板兜底文本
     *
     * <p>本场景的「用户消息」就是组装好的素材原文（没有额外包装文案），
     * 所以模板只有 {@code {material}} 一个占位符 —— {@link ReportPromptService#renderUserPrompt}
     * 会把它整段替换成素材。</p>
     */
    public static String userPromptTemplate() {
        return "{material}";
    }
}
