package com.suzhou.bank.service.report.model;

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

    /** 空数据策略：整块隐藏（非默认，需显式配置） */
    public static final String EMPTY_HIDE = "HIDE";

    /** 空数据策略：显示"暂无数据"占位（默认策略） */
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

    /** AI全文分析状态：进行中（同一 reportNo 同时只允许一条该状态） */
    public static final String ANALYSIS_STATUS_RUNNING = "RUNNING";

    /** AI全文分析状态：已完成 */
    public static final String ANALYSIS_STATUS_DONE = "DONE";

    /** AI全文分析状态：失败（预警建议批次复用同一套状态） */
    public static final String ANALYSIS_STATUS_FAILED = "FAILED";

    /**
     * 预警建议批次状态：排队中 —— 仅「一键串行」时使用
     * <p>链式触发会预插一条 PENDING 批次，等全文分析结束再由续接器翻成 RUNNING。
     * 这样做有两个作用：① 前端立刻能看到"整条链在跑"，不用等全文分析完成才知道；
     * ② 它是「这次全文分析是链式触发还是单独触发」的判据 —— 单独触发不会预插批次，
     * 因此不会误启预警建议。</p>
     */
    public static final String ANALYSIS_STATUS_PENDING = "PENDING";

    // ==================== 提示词编码（app_report_prompt.promptCode） ====================

    /** 提示词：AI 全文分析 */
    public static final String PROMPT_AI_FULL_ANALYSIS = "AI_FULL_ANALYSIS";

    /** 提示词：AI 预警建议 */
    public static final String PROMPT_WARNING_ADVICE = "WARNING_ADVICE";

    // ==================== 预警建议等级（app_report_warning_advice.warningLevel） ====================

    /** 建议预警等级：红色预警 */
    public static final String WARNING_LEVEL_RED = "RED";

    /** 建议预警等级：橙色预警 */
    public static final String WARNING_LEVEL_ORANGE = "ORANGE";

    /** 建议预警等级：黄色预警 */
    public static final String WARNING_LEVEL_YELLOW = "YELLOW";
}
