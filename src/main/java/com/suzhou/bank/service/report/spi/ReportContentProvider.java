package com.suzhou.bank.service.report.spi;

/**
 * 报告内容提供者（扩展点）
 * <p>报告生成不负责取数，只负责"按模板把加工好的内容落到实例表"。
 * 真实场景下由前置数据加工链路实现本接口：按 {@code block.agentCode} 调用智能体、
 * 或按内容块编码取已加工好的成品内容。</p>
 * <p>返回 {@code null} 或 content 为空表示该块无数据，生成器会按模板的
 * emptyStrategy（HIDE/PLACEHOLDER）交给前端渲染。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
public interface ReportContentProvider {

    /**
     * 加工单个内容块的内容
     *
     * @param context 加工上下文（客户、报告、内容块、所属目录）
     * @return 内容产物；无数据时返回 null
     */
    ContentPayload provide(ReportGenerateContext context);
}
