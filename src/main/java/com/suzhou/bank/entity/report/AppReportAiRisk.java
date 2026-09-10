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
 * <p>唯一约束：(reportNo, blockCode) 行身份、(reportNo, agentCode) 报告内智能体编码唯一。</p>
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
