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

    /** 填充类型：文本（analysisType/agentCode 在 TEXT / TABLE 下才有值） */
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

    /**
     * 分析文本类型：<b>表格溯源</b>（2026-09-17 新增）
     *
     * <p>内容来源是**业务表**而不是知识配置：{@code agentCode} 存表英文名（{@code app_*}），
     * {@code agentParams} 存查询条件（`reportNo,entName`，可能再带 `列=值` 过滤令牌，
     * 如 {@code subjectType=借款人}）。加工时查表 → 拼 md 表格存 content；
     * <b>严格按条件查，不做担保人轮询</b>。fillType 恒 TABLE。</p>
     */
    public static final String ANALYSIS_TRACE_TABLE = "TRACE_TABLE";

    /**
     * 分析文本类型：<b>链接溯源</b>（2026-09-17 新增）
     *
     * <p>content 存"链接开头"（来自一张信贷还没给的配置表），前端拿到后调另一个接口补全 + SM4 加密后跳转。
     * 本版配置表未接入 ⇒ 内容留空 + 模板 {@code emptyStrategy=HIDE}。fillType 为 TEXT。</p>
     */
    public static final String ANALYSIS_TRACE_LINK = "TRACE_LINK";

    /**
     * 分析文本类型：<b>外部灌入</b>（2026-09-17 新增）
     *
     * <p>内容**不由本服务调 agent 产出**，后续由别的接口直接落 content
     * （如「风险归因分析」「行业宏观变化」两个编号）。block 内容为空 → 按 emptyStrategy 占位/隐藏。</p>
     */
    public static final String ANALYSIS_EXTERNAL = "EXTERNAL";

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

    /**
     * 报告状态：888-已完成 —— <b>唯一终态</b>
     * <p>对齐行内口径：报告必定达 888。模板缺失/校验不通过/单个内容块加工失败/落库失败
     * 都不再中断链路，而是空壳或跳过该块 + 原因汇总进 {@code fail_reason} 软备注。
     * 因此「报告完成但内容不全」看 {@code fail_reason}，不看 status。</p>
     */
    public static final String REPORT_STATUS_DONE = "888";

    /**
     * 报告状态：999-失败 —— <b>预留状态，正常链路不再产生</b>
     * <p>保留用于兼容升级前的历史存量记录（{@code versions()} 的 999 分支即为它们留着，
     * 否则老失败记录会从版本下拉里消失）。⛔ 新代码不要再置 999，失败一律走
     * 888 + {@code fail_reason} 软备注。</p>
     */
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

    /**
     * 提示词：风险要点总结（2026-09-24 从代码挪进表）
     *
     * <p>「一、（一）风险要点」三段式里，开篇总述 + 收尾结论由<b>一次大模型调用</b>产出。</p>
     */
    public static final String PROMPT_RULE_SUMMARY = "RULE_SUMMARY";

    /**
     * 提示词场景：系统内置（⛔ 「通用提示词管理」页面<b>不展示</b>）
     *
     * <p>标记在 {@code app_report_prompt.sceneType} 上。这类提示词与代码里的解析契约强耦合
     * （如 {@code #PICK#} / {@code #TAIL#} 分隔标记、条数上限），业务人员在页面上改动会直接把
     * 报告生成搞坏 ⇒ 只允许在库里改，不在界面上暴露。</p>
     */
    public static final String PROMPT_SCENE_SYSTEM = "SYSTEM";

    // ==================== 预警建议等级（app_report_warning_advice.warningLevel） ====================

    /** 建议预警等级：红色预警 */
    public static final String WARNING_LEVEL_RED = "RED";

    /** 建议预警等级：橙色预警 */
    public static final String WARNING_LEVEL_ORANGE = "ORANGE";

    /** 建议预警等级：黄色预警 */
    public static final String WARNING_LEVEL_YELLOW = "YELLOW";
}
