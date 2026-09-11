package com.suzhou.bank.service.report.spi;

import lombok.AllArgsConstructor;
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
@AllArgsConstructor
public class ContentPayload {

    /**
     * 内容成品：标题文案 / 分析文本（RULE 类即风险文案）/ 表格片段 /
     * 溯源内容块的外部跳转链接（溯源块本身就是一个内容块，content 存链接，
     * 前端渲染为按钮或链接，点击新开浏览器标签页）
     */
    private String content;
}
