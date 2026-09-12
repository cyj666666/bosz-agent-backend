package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 风险要点修改记录表（app_report_risk_edit_log，归档表）
 *
 * <p><b>归档维度 = checkTaskNo（日检流水号）+ blockCode（风险要点 = 内容块编号）。</b>
 * 同一日检流水号下各版本共用同一套 blockCode（blockCode 来自模板），
 * 因此按此维度归档可跨版本追溯；若按 reportNo 归档，报告换版本后历史就断了。</p>
 *
 * <p>写入时机：{@code ReportServiceImpl.updateBlockContent} 中，
 * 与内容实例 content 的更新<b>同事务</b>插入一条；仅当内容确实发生变化时写入，
 * 且只记录人工修改（不含 AI 生成原文）。</p>
 *
 * @author cyj666666
 * @since 1.2.0
 */
@Data
@TableName("app_report_risk_edit_log")
public class AppReportRiskEditLog {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 日检流水号（归档维度①） */
    @TableField("checkTaskNo")
    private String checkTaskNo;

    /** 风险要点编号（= 内容块编号，归档维度②） */
    @TableField("blockCode")
    private String blockCode;

    /** 产生本次修改的报告编号 */
    @TableField("reportNo")
    private String reportNo;

    /** 风险要点名称（冗余，便于单独展示） */
    @TableField("blockName")
    private String blockName;

    /** 所属目录编号（冗余） */
    @TableField("catalogCode")
    private String catalogCode;

    @TableField("customerId")
    private String customerId;

    @TableField("customerName")
    private String customerName;

    /** 修改前文案（审计对比用） */
    @TableField("contentBefore")
    private String contentBefore;

    /** 修改后文案（列表展示用） */
    @TableField("contentAfter")
    private String contentAfter;

    /** 修改人账号 */
    @TableField("operatorNo")
    private String operatorNo;

    /** 修改人姓名（取 sys_user.real_name，取不到回落账号） */
    @TableField("operatorName")
    private String operatorName;

    /** 修改时间 */
    @TableField("inputtime")
    private Date inputtime;
}
