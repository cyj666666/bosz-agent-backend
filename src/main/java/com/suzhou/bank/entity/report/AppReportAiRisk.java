package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * AI 风险实例表（app_report_ai_risk，实例层）
 * <p>右侧「AI 风险识别列表」的数据源。<b>一条 analysisType=RULE 的内容块 ↔ 一条风险</b>（1:1）：
 * 正文内容由内容实例的 content 承载，本表只承载列表展示字段与处置状态，
 * riskDesc 与内容实例 content 为同一份文案（正文侧编辑时须同事务同步本列）。</p>
 * <p>⚠️ <b>只有"命中"的规则才落到本表</b>：未命中的规则块内容为空、正文整块隐藏，
 * 也不会生成风险行。因此每一行都对应一次成功的规则校验，
 * {@code checkResult}（校验结果）与 {@code riskDesc}（补充分析）是同一次调用的两个产物。</p>
 * <p>唯一约束：(reportNo, blockCode) 行身份。同一个 agentCode 可在不同章节合法复用
 * （如征信类规则按借款人 / 担保人两种口径各出现一次），故不再对 agentCode 加唯一约束。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
@TableName("app_report_ai_risk")
public class AppReportAiRisk {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("reportNo")
    private String reportNo;

    @TableField("customerId")
    private String customerId;

    @TableField("customerName")
    private String customerName;

    /** 内容块编号（关联内容实例 blockCode） */
    @TableField("blockCode")
    private String blockCode;

    /** 智能体编码（已含经验规则编号，报告内唯一） */
    @TableField("agentCode")
    private String agentCode;

    /** 经验规则名称 */
    @TableField("ruleName")
    private String ruleName;

    /** 风险描述（列表展示文案，与内容实例 content 同一份文案） */
    @TableField("riskDesc")
    private String riskDesc;

    /**
     * 智策引擎的「校验结果」JSON（仅 {@code analysisType=RULE} 的风险行有值）
     *
     * <p>与 {@link #riskDesc}（补充分析文案）是**同一次规则调用的两个产物**，同一行关联：
     * {@code result}（命中判定）/ {@code factExpression}（事实表达式）/
     * {@code metrics}（本次校验用到的指标清单：编码、名称、命中值、单位）/
     * {@code missingValueCount}·{@code totalMetricCount}（取数完整性）/
     * {@code guarantorName}（担保人口径时的归属）。多担保人轮循时为 JSON 数组。</p>
     *
     * <p>⚠️ 只有<b>命中</b>的规则才会生成风险行，所以 {@code result} 恒为「命中」；
     * 未命中的规则在正文与风险列表里都不出现。</p>
     */
    @TableField("checkResult")
    private String checkResult;

    /** 处置状态：PENDING-待处理 ADOPTED-已采纳 INVALID-已无效 */
    @TableField("status")
    private String status;

    /** 跳转锚点（单向）：点击该风险行时跳转到的正文锚点 */
    @TableField("jumpAnchorCode")
    private String jumpAnchorCode;

    @TableField("sortNo")
    private Integer sortNo;

    @TableField("inputtime")
    private Date inputtime;
}
