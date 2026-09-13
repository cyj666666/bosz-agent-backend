package com.suzhou.bank.service.report.model;

import lombok.Data;

import java.util.Date;

/**
 * 报告预警建议明细项（详情页「预警建议」页签的表格数据源，一行 = 一条预警信号）
 *
 * <p>字段与模型输出表格的 7 列一一对应：序号 / 建议预警等级 / 预警信号描述 / 触发条件 /
 * 原文依据 / 风险点描述 / 所在章节。其中 {@link #status} 是人工处理结果，模型不产出。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
public class ReportWarningAdviceItem {

    private Long id;

    /** 所属批次 */
    private Long batchId;

    /** 序号（模型输出顺序，已按红>橙>黄排序） */
    private Integer seqNo;

    /** 建议预警等级：RED-红色 / ORANGE-橙色 / YELLOW-黄色（前端映射中文） */
    private String warningLevel;

    /** 预警信号描述 */
    private String signalDesc;

    /** 触发条件/判断依据 */
    private String triggerCondition;

    /** 原文依据（引用原文关键句） */
    private String sourceText;

    /** 风险点描述（未关联到风险点时为空） */
    private String riskDesc;

    /** 所在章节/段落 */
    private String chapter;

    /** 处理状态：PENDING-待处理 / ADOPTED-已采纳 / INVALID-无效 */
    private String status;

    /** 处理人姓名（取不到回落账号） */
    private String operatorName;

    private String operatorNo;

    /** 处理时间 */
    private Date operateTime;
}
