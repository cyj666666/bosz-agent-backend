package com.suzhou.bank.report.spi;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 内容加工产物
 * <p>由 {@link ReportContentProvider} 返回，对应一个内容块的成品内容。
 * 加工方只需关心"内容体 + 可选的跳转目标"，其余结构性信息由生成器按模板补齐。</p>
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

    /**
     * 块间跳转锚点（可选，单向）
     * <p>仅用于内容块之间的点击快速定位：值是目标块的 anchorCode，不是外部跳转链接。
     * <b>与填充类型无关</b>——任何填充类型的内容块只要配置了本值即可跳转；
     * 由前置加工按需给出，生成器不做任何推断；置空表示本块不可点击跳转。
     * 目标块不反向记录来源。</p>
     * <p><b>前端行为：点击后滚动定位到目标块</b>（同一页面内定位，不新开页面）。</p>
     */
    private String jumpAnchorCode;
}
