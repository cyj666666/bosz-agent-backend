package com.suzhou.bank.service.report.spi;

import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 内容加工产物
 * <p>由 {@link ReportContentProvider} 返回，对应一个内容块的成品内容。
 * 加工方只需关心"内容体"，其余结构性信息（含块间跳转锚点）由生成器按模板补齐。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
@NoArgsConstructor
public class ContentPayload {

    /**
     * 内容成品：标题文案 / 分析文本（RULE 类即风险文案）/ 表格片段 /
     * 溯源内容块的外部跳转链接（溯源块本身就是一个内容块，content 存链接，
     * 前端渲染为按钮或链接，点击新开浏览器标签页）
     */
    private String content;

    /**
     * 校验结论（<b>仅 {@code analysisType=RULE} 的智策引擎类内容块填充</b>，其余为 null）
     *
     * <p>取值只有 {@code 命中} / {@code 未命中}—— 就是"这条经验规则判定结果如何"。
     * 生成器把它落到 {@code app_report_ai_risk.check_result}，与补充分析文案
     * （{@code risk_desc}）同行关联。</p>
     *
     * <p>⚠️ 未命中（以及表达式执行失败的「校验失败」）时内容为空，<b>不会生成 AI 风险行</b>，
     * 所以真正落到风险表里的值恒为 {@code 命中}。</p>
     *
     * <p>⛔ 校验溯源明细（事实表达式 / 涉及指标 / 命中值）<b>不在这里</b>：
     * 溯源是单独的内容块设计（{@code fillType=SOURCE_LINK}），与风险表职责不同。</p>
     */
    private String checkResult;

    public ContentPayload(String content) {
        this.content = content;
    }

    public ContentPayload(String content, String checkResult) {
        this.content = content;
        this.checkResult = checkResult;
    }
}
