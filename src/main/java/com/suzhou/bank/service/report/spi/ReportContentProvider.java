package com.suzhou.bank.service.report.spi;

import java.util.List;

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

    /**
     * 生成「风险要点总结」（模板里 agentCode={@code RULE_SUMMARY} 的那个块）
     *
     * <p><b>为什么单独一个方法</b>：这个块的素材不是它自己的配置，而是「本报告**已生成的全部
     * RULE 块内容**」，而且它在模板里排在所有 RULE 块**之前**，一阶段按顺序加工时素材还不存在 ——
     * 所以由生成器在两阶段里的**阶段 2** 收齐后再回调本方法。</p>
     *
     * <p>默认实现返回 {@code null}（不支持总结的实现不用改）：此时该块内容为空，
     * 按模板的 emptyStrategy 渲染占位或隐藏。</p>
     *
     * @param context    加工上下文（block 即那个总结块，可读它的 agentCode/blockName 等模板信息）
     * @param ruleHits   本报告已生成内容、且内容非空的全部 RULE 块（按模板顺序）
     * @return 总结文案；不支持或无素材时返回 null
     */
    default ContentPayload provideRuleSummary(ReportGenerateContext context, List<RuleHit> ruleHits) {
        return null;
    }
}
