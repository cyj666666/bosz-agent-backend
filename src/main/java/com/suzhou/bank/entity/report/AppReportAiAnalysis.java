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

    /**
     * 实际使用的提示词快照（= systemPrompt + userPrompt，**userPrompt 里已含送模型的素材**）
     *
     * <p>🔴 <b>2026-09-27 删除 {@code sourceSnapshot} 列</b>，原由：</p>
     * <ol>
     *   <li>它是本列的<b>子串</b> —— {@code renderUserPrompt} 三个分支都把 material 嵌进 userPrompt
     *       ⇒ 零独有信息；</li>
     *   <li>全仓无任何读取（纯写不读）；</li>
     *   <li>行内 M 模式 `TEXT` 仅 64KB，素材上限 6 万字符（中文约 18 万字节）本就存不下，
     *       留着要么报错要么白占一份存储。</li>
     * </ol>
     * <p>排查"当时 AI 看到了什么"看本列即可（素材在 {@code [user]} 段里）。</p>
     */
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
