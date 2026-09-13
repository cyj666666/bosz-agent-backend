package com.suzhou.bank.service.report.ai;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 全文分析结束事件（成功、失败都发布）
 *
 * <p>用途：支撑「一键串行」—— 全文分析结束后，由 {@link ReportAiChainListener}
 * 接着启动预警建议。</p>
 *
 * <p><b>为什么用事件而不是直接调用服务层</b>：{@code ReportServiceImpl} 通过构造器注入了
 * 本包的 {@link ReportAiAnalysisTask}，若任务反过来注入服务层就会形成构造器循环依赖，
 * 而 Spring Boot 2.6+ 默认禁止循环引用（启动即失败）。发事件则天然解耦。</p>
 *
 * <p><b>失败也发事件</b>：预警建议对全文分析是软依赖（2026-09-13 口径），
 * 全文分析失败不应该把预警建议一起拖死，所以失败同样要触发下一步。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Getter
@RequiredArgsConstructor
public class ReportAiAnalysisCompletedEvent {

    /** 报告编号（链式续接的定位依据） */
    private final String reportNo;

    /** 本次全文分析记录 id（失败时也可能为空） */
    private final Long analysisId;

    /** 本次全文分析是否成功 */
    private final boolean success;
}
