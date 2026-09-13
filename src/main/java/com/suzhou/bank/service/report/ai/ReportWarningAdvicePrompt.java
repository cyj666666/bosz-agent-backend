package com.suzhou.bank.service.report.ai;

/**
 * 预警建议提示词的<b>兜底</b>常量
 *
 * <p>提示词首选来源是表 {@code app_report_prompt}（promptCode = {@code WARNING_ADVICE}），
 * 由 {@link ReportPromptService} 读取；表里没有或读不到时才回落到本类。</p>
 *
 * <p>系统提示词的正文本放在 {@code resources/report-prompt/WARNING_ADVICE.system.txt}
 * （内嵌《预警管理办法》三级预警定级标准原文）。改完请同步更新
 * {@code sql/报告详情表设计/报告提示词表_初始化DML.sql}。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
public final class ReportWarningAdvicePrompt {

    private static final String SYSTEM_FILE = "WARNING_ADVICE.system.txt";

    private ReportWarningAdvicePrompt() {
    }

    /** 系统提示词兜底文本（表里没配时使用） */
    public static String systemPrompt() {
        return PromptResources.load(SYSTEM_FILE);
    }

    /** 用户提示词模板兜底文本，{@code {material}} 为素材占位符 */
    public static String userPromptTemplate() {
        return "# 待分析文本\n{material}";
    }

    /** 用户提示词（模板 + 素材），供不经表直接调用的场景使用 */
    public static String userPrompt(String material) {
        return userPromptTemplate().replace("{material}", material == null ? "" : material);
    }
}
