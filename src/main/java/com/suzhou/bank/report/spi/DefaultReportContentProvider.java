package com.suzhou.bank.report.spi;

/**
 * 默认内容提供者（占位实现）
 * <p>不做任何取数，一律返回 null：报告骨架照常生成，非标题类内容为空并按 emptyStrategy 渲染。
 * 由 {@code ReportGenerateConfig} 以 {@code @ConditionalOnMissingBean} 注册，
 * 接入真实前置加工链路时只需注册自己的 {@link ReportContentProvider} Bean，本类自动失效。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
public class DefaultReportContentProvider implements ReportContentProvider {

    @Override
    public ContentPayload provide(ReportGenerateContext context) {
        return null;
    }
}
