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
     * 校验结果（<b>仅 {@code analysisType=RULE} 的智策引擎类内容块填充</b>，其余为 null）
     *
     * <p>JSON 文本，字段口径与智策引擎「开始校验」的返回一致：</p>
     * <ul>
     *   <li>{@code result} —— 校验结论：{@code 命中} / {@code 未命中} / {@code 校验失败}
     *       （{@code 校验失败} 指规则表达式执行异常，<b>不等于未命中</b>，不能混为一谈）；</li>
     *   <li>{@code factExpression} —— 事实分析表达式；</li>
     *   <li>{@code metrics} —— 本次校验用到的指标清单（{@code indexCode / indexName / actualValue / dataUnit}）。
     *       ⚠️ 它<b>不是"命中的指标"</b>，而是"表达式引用的全部指标"，与取没取到值无关；</li>
     *   <li>{@code missingValueCount} / {@code totalMetricCount} —— 取数完整性；</li>
     *   <li>{@code guarantorName} —— 担保人口径时标明该结果属于哪个担保人（借款人口径无此键）。</li>
     * </ul>
     *
     * <p>多担保人轮循时是<b>JSON 数组</b>，每个元素是上述对象。生成器把它整串落到
     * {@code app_report_ai_risk.check_result}，与补充分析文案（{@code risk_desc}）同行关联。</p>
     *
     * <p>⚠️ 未命中（{@code result=未命中}）的规则块 content 为空，
     * <b>不会生成 AI 风险行</b>，因此落到风险表里的校验结果结论恒为「命中」。</p>
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
