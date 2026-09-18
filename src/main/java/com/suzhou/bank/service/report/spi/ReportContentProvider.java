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

    /**
     * 「风险要点」一次产出：<b>总结文案</b> + <b>只保留哪几条要点</b>（2026-09-18 新增）
     *
     * <p><b>为什么需要它</b>：用户口径是「风险要点不必如实罗列全部命中，挑最严重的 5 条即可」。
     * 而"哪几条最重要"只有**模型**能判断 ⇒ 让它在出总结的同时把选中的规则名一并吐出来，
     * 生成器据此**只回填这几条条目块**，其余留空（模板 {@code emptyStrategy=HIDE} → 整块不渲染）。</p>
     *
     * <p><b>与 {@link #provideRuleSummary} 的关系</b>：本方法返回 {@code null} 时，
     * 生成器回落到 {@link #provideRuleSummary}（只出总结、**不筛选**，等于旧行为）。
     * 老的实现只实现 {@code provideRuleSummary} 也能照旧跑。</p>
     *
     * @param context  加工上下文（block 即总结块）
     * @param ruleHits 本报告已生成内容、且内容非空的全部 RULE 块（按模板顺序）
     * @return 总结 + 保留清单；不支持时返回 {@code null}
     */
    default RuleSummaryResult summarizeRuleRisks(ReportGenerateContext context, List<RuleHit> ruleHits) {
        return null;
    }

    /**
     * 风险要点总结的产物
     *
     * @author cyj666666
     * @since 1.4.0
     */
    class RuleSummaryResult {

        /** 开头总结（落到 {@code RULE_SUMMARY} 块；可为 null 表示无内容） */
        private final ContentPayload summary;

        /**
         * 要点条目**只保留**这些 RULE 块（元素 = {@link RuleHit#getBlockCode()}）
         *
         * <p>{@code null} 或空集合 = <b>不筛选</b>，全部条目照旧回填。</p>
         */
        private final List<String> keepRuleBlockCodes;

        /**
         * 结尾结论（落到 {@code RULE_SUMMARY_TAIL} 块；2026-09-18 新增）
         *
         * <p>用户口径：风险要点是「<b>总述 → 4~5 条要点 → 收尾结论</b>」三段式。
         * 三段由**同一次**大模型调用产出，本字段拿的是最后那段收尾
         * （"综上，上述几项风险分别指向……"）。为 {@code null} 时该块按 emptyStrategy 隐藏。</p>
         */
        private final ContentPayload tail;

        public RuleSummaryResult(ContentPayload summary, List<String> keepRuleBlockCodes) {
            this(summary, keepRuleBlockCodes, null);
        }

        public RuleSummaryResult(ContentPayload summary, List<String> keepRuleBlockCodes,
                                 ContentPayload tail) {
            this.summary = summary;
            this.keepRuleBlockCodes = keepRuleBlockCodes;
            this.tail = tail;
        }

        public ContentPayload getSummary() {
            return summary;
        }

        public List<String> getKeepRuleBlockCodes() {
            return keepRuleBlockCodes;
        }

        public ContentPayload getTail() {
            return tail;
        }
    }
}
