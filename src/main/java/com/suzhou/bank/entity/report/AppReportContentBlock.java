package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 报告正文内容块配置表（app_report_content_block，模板层）
 * <p>每个目录下挂 N 个内容块，前端按 sortNo 顺序渲染。
 * 本表只描述"报告长什么样"，不承载内容；内容由报告生成时前置加工后写入内容实例表。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
@TableName("app_report_content_block")
public class AppReportContentBlock {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 内容块编号（全局唯一，同时作为内容实例的锚点编码） */
    @TableField("blockCode")
    private String blockCode;

    /** 所属目录编号；NULL 表示报告级内容块（如报告头），不进目录树 */
    @TableField("catalogCode")
    private String catalogCode;

    /** 填充类型：TITLE-标题 TEXT-文本 TABLE-表格 SOURCE_LINK-溯源链接（实例 content 存外部跳转链接） */
    @TableField("fillType")
    private String fillType;

    /** 分析文本类型：RULE-经验规则类 ANALYSIS-文本分析类（仅 fillType=TEXT 时有值） */
    @TableField("analysisType")
    private String analysisType;

    /** 智能体编码（仅 fillType=TEXT/TABLE 时有值；已含经验规则编号） */
    @TableField("agentCode")
    private String agentCode;

    /**
     * 调智能体时的入参清单（逗号分隔的**参数名**，仅 fillType=TEXT/TABLE 时有值）
     * <p>2026-09-17 新增（对齐《报告详情设计》G 列「知识库/智策引擎参数」）。
     * 取值只有三种：</p>
     * <ul>
     *   <li>{@code reportNo,entName} —— 只用借款人口径</li>
     *   <li>{@code reportNo,entName,guarantorName} —— 还要按担保人口径（多担保人时轮循）</li>
     *   <li>NULL / 空 —— 由 provider 按默认（reportNo,entName）处理</li>
     * </ul>
     * <p><b>为什么必须有这一列</b>：同一个 agentCode 会在不同章节复用（源表里
     * {@code zxcxsjmsqy}/{@code zwqkmsqy} 等在「六、征信」与「十二、担保人征信」各出现一次），
     * 前者是**借款人**口径、后者是**担保人**口径，入参不同、结果完全不同 ——
     * 只靠 agentCode 无法区分，调度侧不能去重也不能混用。</p>
     */
    @TableField("agentParams")
    private String agentParams;

    /** 内容块名称（analysisType=RULE 时即规则名称；模板层与实例层同名同值） */
    @TableField("blockName")
    private String blockName;

    /** 标题级别：1-报告主标题 2-章节标题 3-小节标题（仅 fillType=TITLE 时有值） */
    @TableField("titleLevel")
    private Integer titleLevel;

    /** 空数据策略：HIDE-整块隐藏 PLACEHOLDER-显示暂无数据占位 */
    @TableField("emptyStrategy")
    private String emptyStrategy;

    /**
     * 块间跳转目标锚点（单向）：点击本块时滚动定位到的目标块 anchorCode（=目标块 blockCode）。
     * <p>跳转关系属报告结构、在模板层配置，生成时快照到实例层；与填充类型无关，
     * 任何填充类型的块配置了本值即可点击跳转；无跳转则为 NULL。</p>
     */
    @TableField("jumpAnchorCode")
    private String jumpAnchorCode;

    /** 排序（同一目录内内容块顺序） */
    @TableField("sortNo")
    private Integer sortNo;

    /** 是否可用：1-可用 0-停用 */
    @TableField("isEnabled")
    private Integer isEnabled;

    @TableField("inputtime")
    private Date inputtime;
}
