package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 报告 AI 全文分析表（app_report_ai_analysis）
 * <p>右侧「AI分析全文」面板的数据源。<b>挂在报告编号 reportNo 上、保留多次</b>：
 * 同一版报告可以反复分析，前端按 id 倒序取最新一次。</p>
 * <p>生成方式：前端手动触发 → 独立线程池异步执行 → 前端按 status 轮询。
 * 同一 reportNo 同时只允许一条 {@code RUNNING}（服务层校验，未加 DB 唯一约束）。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
@TableName("app_report_ai_analysis")
public class AppReportAiAnalysis {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 报告编号（归档维度，同一报告可保留多次分析记录） */
    @TableField("reportNo")
    private String reportNo;

    /** 日检流水号（冗余，便于按流水号追溯） */
    @TableField("checkTaskNo")
    private String checkTaskNo;

    @TableField("customerId")
    private String customerId;

    @TableField("customerName")
    private String customerName;

    /** 分析状态：RUNNING-进行中 / DONE-已完成 / FAILED-失败 */
    @TableField("status")
    private String status;

    /** 分析正文（成品 HTML 片段，前端直接渲染） */
    @TableField("analysisContent")
    private String analysisContent;

    /** 综合结论摘要 */
    @TableField("summary")
    private String summary;

    /** 大模型给出的总体风险等级 */
    @TableField("riskLevel")
    private String riskLevel;

    /** 所用大模型配置编码（large_model_config.lm_code） */
    @TableField("lmCode")
    private String lmCode;

    /** 实际调用的模型名 */
    @TableField("modelName")
    private String modelName;

    /** 送进大模型的素材快照（正文摘取 + 外部数据，便于追溯与复算） */
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

    /** 分析完成时间 */
    @TableField("generateTime")
    private Date generateTime;

    @TableField("inputtime")
    private Date inputtime;
}
