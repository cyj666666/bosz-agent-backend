package com.suzhou.bank.service.report.spi;

import com.suzhou.bank.entity.report.AppReportContentBlock;
import lombok.Data;

/**
 * 内容加工上下文
 * <p>生成器向 {@link ReportContentProvider} 索要内容时提供的上下文信息，
 * 承载"给谁、哪一块、属于哪个目录"，便于加工方（前置数据加工/智能体调用）定位数据。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
public class ReportGenerateContext {

    private String reportNo;

    private String customerId;

    private String customerName;

    /** 内容块所属目录名称（报告级内容块为 NULL） */
    private String catalogName;

    /** 待加工的内容块（模板定义） */
    private AppReportContentBlock block;
}
