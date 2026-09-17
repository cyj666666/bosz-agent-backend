package com.suzhou.bank.service.report.model;

import lombok.Data;

/**
 * AI 风险列表项（渲染用）
 * <p>对应右侧「AI 风险识别列表」一行，数据源为 app_report_ai_risk。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
public class ReportRiskItem {

    private String blockCode;

    /** 智能体编码（与正文内容实例的关联键） */
    private String agentCode;

    private String ruleName;

    /** 风险描述（对应章节正文的同一份文案）= 智策引擎的「补充分析」文案 */
    private String riskDesc;

    /**
     * 智策引擎的「校验结果」JSON（仅经验规则类风险有值）
     *
     * <p>与 {@link #riskDesc} 是同一次规则调用的两个产物，同行关联：
     * {@code result} / {@code factExpression} / {@code metrics}（本次校验用到的指标清单）/
     * {@code missingValueCount}·{@code totalMetricCount} / {@code guarantorName}。
     * 担保人口径轮循多个担保人时为 JSON 数组。</p>
     *
     * <p>⚠️ 只读留痕：正文侧编辑正文会同步 {@code riskDesc}，但不会动本字段。</p>
     */
    private String checkResult;

    /** 处置状态：PENDING/ADOPTED/INVALID */
    private String status;

    /** 点击本行跳转到的正文锚点（单向） */
    private String jumpAnchorCode;

    private Integer sortNo;

    /** 所属目录编号（自内容实例带出，供列表展示"对应章节"） */
    private String catalogCode;

    /**
     * 该风险要点在当前日检流水号下的修改记录条数（跨版本累计）。
     * <p>供前端决定是否显示「修改记录(N)」按钮，避免每行单独发一次查询请求。</p>
     */
    private Integer editCount;
}
