package com.suzhou.bank.report.model;

/**
 * 报告模板枚举常量
 * <p>与字典解耦的字符串枚举，值即数据库实际存储值。
 * 后续扩展填充类型/空数据策略只需在此追加常量，不影响既有数据。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
public final class ReportConstants {

    private ReportConstants() {
    }

    /** 填充类型：标题（text=标题文案） */
    public static final String FILL_TITLE = "TITLE";

    /** 填充类型：文本（analysisType/agentCode 仅本类型有值） */
    public static final String FILL_TEXT = "TEXT";

    /** 填充类型：表格（content 为表格成品片段） */
    public static final String FILL_TABLE = "TABLE";

    /**
     * 填充类型：溯源链接
     * <p>本身就是一个内容块，其实例 content 存外部跳转链接，前端渲染为按钮/链接，
     * 点击新开浏览器标签页。与块间锚点跳转（jumpAnchorCode）无关。</p>
     */
    public static final String FILL_SOURCE_LINK = "SOURCE_LINK";

    /** 分析文本类型：经验规则类（内容体即 AI 风险明细，支持前端编辑） */
    public static final String ANALYSIS_RULE = "RULE";

    /** 分析文本类型：文本分析类 */
    public static final String ANALYSIS_TEXT = "ANALYSIS";

    /** 标题级别：报告主标题（承载报告头，如公司名称） */
    public static final int TITLE_LEVEL_REPORT = 1;

    /** 标题级别：章节标题 */
    public static final int TITLE_LEVEL_CHAPTER = 2;

    /** 标题级别：小节标题 */
    public static final int TITLE_LEVEL_SECTION = 3;

    /** 空数据策略：整块隐藏 */
    public static final String EMPTY_HIDE = "HIDE";

    /** 空数据策略：显示"暂无数据"占位 */
    public static final String EMPTY_PLACEHOLDER = "PLACEHOLDER";

    /** 风险处置状态：待处理 */
    public static final String RISK_PENDING = "PENDING";

    /** 风险处置状态：已采纳 */
    public static final String RISK_ADOPTED = "ADOPTED";

    /** 风险处置状态：已无效 */
    public static final String RISK_INVALID = "INVALID";

    /** 报告状态：111-待开始（报告记录的初始状态，由上游预生成） */
    public static final String REPORT_STATUS_WAITING = "111";

    /** 报告状态：000-进行中（定时任务取到待开始记录后置入，加工期间保持） */
    public static final String REPORT_STATUS_RUNNING = "000";

    /** 报告状态：888-已完成（加工正常结束） */
    public static final String REPORT_STATUS_DONE = "888";

    /** 报告状态：999-失败（加工过程抛异常） */
    public static final String REPORT_STATUS_FAILED = "999";

    /** 是否可用：可用 */
    public static final int ENABLED = 1;
}
