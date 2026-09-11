package com.suzhou.bank.service.report.model;

import lombok.Data;

/**
 * 报告内容块（渲染用）
 * <p>由内容实例 + 模板的 emptyStrategy 合成；结构性字段取自实例（模板快照），
 * emptyStrategy 取自模板（属于渲染策略，不随报告实例固化）。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
public class ReportBlockVO {

    private String blockCode;

    /** 所属目录编号（报告级内容块为 NULL） */
    private String catalogCode;

    /** 填充类型：TITLE/TEXT/TABLE/SOURCE_LINK */
    private String fillType;

    /** 分析文本类型：RULE/ANALYSIS */
    private String analysisType;

    private String agentCode;

    /** 内容块名称（analysisType=RULE 时即规则名称） */
    private String blockName;

    private Integer titleLevel;

    private Integer sortNo;

    /** 空数据策略：HIDE-整块隐藏 PLACEHOLDER-显示占位 */
    private String emptyStrategy;

    /** 本块锚点编码（作为其它块跳转的目标标识） */
    private String anchorCode;

    /** 块间跳转目标锚点（单向）：前端点击本块后滚动定位到该锚点对应的块；无跳转则为 NULL */
    private String jumpAnchorCode;

    /** 内容成品；为空时前端按 emptyStrategy 渲染。SOURCE_LINK 类此处为外部跳转链接 */
    private String content;

    /** 内容是否为空 */
    private Boolean empty;
}
