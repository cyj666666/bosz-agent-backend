package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 报告预警建议明细表（app_report_warning_advice）
 *
 * <p><b>一行 = 一条预警信号</b>，是「采纳 / 不采纳」的操作对象 —— 采纳与否是一条信号一个决定，
 * 必须能单独改状态、单独记处理人与时间。</p>
 *
 * <p>等级码值：{@code RED} 红色 / {@code ORANGE} 橙色 / {@code YELLOW} 黄色（前端映射中文）。
 * 处理状态：{@code PENDING} 待处理 / {@code ADOPTED} 已采纳 / {@code INVALID} 无效
 * —— 与 AI 风险要点同一套三态口径。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
@TableName("app_report_warning_advice")
public class AppReportWarningAdvice {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 所属批次（app_report_warning_advice_batch.id） */
    @TableField("batchId")
    private Long batchId;

    /** 报告编号（冗余，便于直接按报告查询） */
    @TableField("reportNo")
    private String reportNo;

    /** 序号（模型输出顺序，已按红>橙>黄排序） */
    @TableField("seqNo")
    private Integer seqNo;

    /** 建议预警等级：RED-红色 / ORANGE-橙色 / YELLOW-黄色 */
    @TableField("warningLevel")
    private String warningLevel;

    /** 预警信号描述 */
    @TableField("signalDesc")
    private String signalDesc;

    /** 触发条件/判断依据 */
    @TableField("triggerCondition")
    private String triggerCondition;

    /** 原文依据（引用原文关键句） */
    @TableField("sourceText")
    private String sourceText;

    /** 风险点描述（未关联到风险点时为空） */
    @TableField("riskDesc")
    private String riskDesc;

    /** 所在章节/段落 */
    @TableField("chapter")
    private String chapter;

    /** 处理状态：PENDING-待处理 / ADOPTED-已采纳 / INVALID-无效 */
    @TableField("status")
    private String status;

    /** 处理人账号 */
    @TableField("operatorNo")
    private String operatorNo;

    /** 处理人姓名 */
    @TableField("operatorName")
    private String operatorName;

    /** 处理时间 */
    @TableField("operateTime")
    private Date operateTime;

    @TableField("inputtime")
    private Date inputtime;
}
