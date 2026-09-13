package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 报告预警建议批次表（app_report_warning_advice_batch）
 *
 * <p>承载「预警建议」每一次生成的<b>批次级</b>信息：状态、核心提示、模型信息、失败原因、触发人。
 * 明细在 {@link AppReportWarningAdvice}（batchId 一对多）。</p>
 *
 * <p>为什么单独一张批次表：① 模型调用失败时一条明细都没有，「失败状态 + 失败原因」无处可写；
 * ② 核心提示一次生成只有一句，并进明细表就得在 N 行里重复 N 遍。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
@TableName("app_report_warning_advice_batch")
public class AppReportWarningAdviceBatch {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 报告编号（归档维度，同一报告可保留多次） */
    @TableField("reportNo")
    private String reportNo;

    /** 日检流水号（冗余，便于按流水号追溯） */
    @TableField("checkTaskNo")
    private String checkTaskNo;

    /** 基于哪一次全文分析生成（app_report_ai_analysis.id） */
    @TableField("analysisId")
    private Long analysisId;

    @TableField("customerId")
    private String customerId;

    @TableField("customerName")
    private String customerName;

    /** 生成状态：RUNNING-进行中 / DONE-已完成 / FAILED-失败 */
    @TableField("status")
    private String status;

    /** 核心提示（模型总结，1~3 句话概括最需关注的风险） */
    @TableField("coreTip")
    private String coreTip;

    /** 所用提示词编码（app_report_prompt.promptCode） */
    @TableField("promptCode")
    private String promptCode;

    /** 所用大模型配置编码（large_model_config.lm_code） */
    @TableField("lmCode")
    private String lmCode;

    /** 实际调用的模型名 */
    @TableField("modelName")
    private String modelName;

    /** 送进大模型的素材快照（便于追溯与复算） */
    @TableField("sourceSnapshot")
    private String sourceSnapshot;

    /** 实际使用的提示词快照 */
    @TableField("promptSnapshot")
    private String promptSnapshot;

    @TableField("operatorNo")
    private String operatorNo;

    @TableField("operatorName")
    private String operatorName;

    /** 大模型调用耗时（毫秒） */
    @TableField("costMillis")
    private Long costMillis;

    /** 失败原因（超 1000 字符截断） */
    @TableField("failReason")
    private String failReason;

    /** 生成完成时间 */
    @TableField("generateTime")
    private Date generateTime;

    @TableField("inputtime")
    private Date inputtime;
}
