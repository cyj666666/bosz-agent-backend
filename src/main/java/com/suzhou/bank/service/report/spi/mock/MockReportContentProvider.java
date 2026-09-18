package com.suzhou.bank.service.report.spi.mock;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import com.suzhou.bank.entity.report.AppReportContentBlock;
import com.suzhou.bank.service.report.model.ReportConstants;
import com.suzhou.bank.service.report.spi.ContentPayload;
import com.suzhou.bank.service.report.spi.ReportContentProvider;
import com.suzhou.bank.service.report.spi.ReportGenerateContext;
import com.suzhou.bank.service.report.spi.RuleHit;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import org.springframework.util.StringUtils;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 报告内容提供者 · 模拟实现（演示 / 联调走通用）
 *
 * <p><b>2026-09-18 重构：由「按 blockCode 查 JSON」改为「按块类型造内容」。</b>
 * 原实现读 {@code classpath:report-demo/demo-content.json}，里面的 key 是**旧模板**的 blockCode
 * （{@code BLK_SUM_02} 这种），与重建后的模板（{@code V2_BLK_SUMMARY_A01}）编码体系完全不同 ——
 * 实测 82 个 JSON 块与 182 个模板块**交集为 0**，切回 mock 会得到一份几乎全空的报告。</p>
 *
 * <p>现在按 {@code analysisType} / {@code fillType} 生成内容，<b>与 blockCode 彻底解耦</b>：
 * 模板再怎么改版，模拟报告都是完整的。内容一律带 {@link #TAG} 标识，避免与真实分析结果混淆
 * （要去掉改这一个常量即可）。</p>
 *
 * <p>JSON 仍保留为**可选覆盖**：按当前 blockCode 往 JSON 里加条目即可覆盖该块
 * （便于对个别块定制假文案）。默认一条都命中不了，全部走"按类型造内容"。</p>
 *
 * <p><b>报告头 3 块</b>（{@code catalogCode} 为空）特殊处理：主标题=客户名、副标题=固定文案、说明=空（HIDE）。</p>
 * <p><b>延后块</b>（{@code RULE_SUMMARY} / {@code RULE_ENTRY#}）在阶段 1 不会进本方法
 * （生成器直接跳过），总结块由 {@link #provideRuleSummary} 单独产出。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "report.mock-content.enabled", havingValue = "true", matchIfMissing = true)
public class MockReportContentProvider implements ReportContentProvider {

    /** 可选覆盖资源（不再用于批量造内容，仅作"个别块定制"入口） */
    private static final String RESOURCE_PATH = "report-demo/demo-content.json";

    /** 客户名称占位符（JSON 覆盖里可用） */
    private static final String CUSTOMER_NAME_TOKEN = "${customerName}";

    /** 模拟内容统一标识 —— ⛔ 去掉它之前先想清楚：报告里将无法一眼区分真假 */
    private static final String TAG = "【模拟数据】";

    /** 报告头块名关键词（报告头是 catalogCode 为空的那 3 个块） */
    private static final String HEAD_MAIN_TITLE = "主标题";
    private static final String HEAD_SUB_TITLE = "副标题";
    private static final String HEAD_SUB_TITLE_TEXT = "日常贷后检查报告";

    /** 未命中判定：RULE 块在真实链路里只对"命中"的规则出内容，模拟态统一给"命中" */
    private static final String CHECK_RESULT_HIT = "命中";

    /** 风险要点最多列几条（与真实链路 {@code AgentReportContentProvider#MAX_RISK_ITEMS} 一致） */
    private static final int MAX_RISK_ITEMS = 5;

    private static final String TABLE_HEADER =
            "| 序号 | 项目 | 数值 | 单位 | 备注 |\n"
                    + "| --- | --- | --- | --- | --- |\n";

    /** blockCode → 内容成品（懒加载后只读；仅作可选覆盖） */
    private volatile Map<String, String> contentMap;

    @Override
    public ContentPayload provide(ReportGenerateContext context) {
        if (context == null || context.getBlock() == null) {
            return null;
        }
        AppReportContentBlock block = context.getBlock();
        String blockName = StringUtils.hasText(block.getBlockName())
                ? block.getBlockName() : block.getBlockCode();
        String customerName = StringUtils.hasText(context.getCustomerName())
                ? context.getCustomerName() : "某某公司";

        // ① 报告头（catalogCode 空）—— 与模板编码无关，固定内容
        if (!StringUtils.hasText(block.getCatalogCode())) {
            if (blockName.contains(HEAD_MAIN_TITLE)) {
                return new ContentPayload(customerName);
            }
            if (blockName.contains(HEAD_SUB_TITLE)) {
                return new ContentPayload(HEAD_SUB_TITLE_TEXT);
            }
            // 报告说明块 → 空，配合模板 emptyStrategy=HIDE 不渲染（与真实链路同口径）
            return null;
        }

        // ② 可选覆盖：JSON 里配了当前 blockCode 就用它
        String override = lookupOverride(block.getBlockCode(), customerName);
        if (override != null) {
            return new ContentPayload(override, checkResultOf(block));
        }

        // ③ 按类型造内容（与 blockCode 解耦）
        String content = buildByType(block, blockName, customerName, context.getCatalogName());
        if (!StringUtils.hasText(content)) {
            return null;
        }
        return new ContentPayload(content, checkResultOf(block));
    }

    /**
     * 风险要点总结（阶段 2 回调）
     *
     * <p>素材是**本报告已生成的全部 RULE 块**，模拟态不再调大模型，直接把命中的规则按章节罗列出来 ——
     * 这样条目块（复用 RULE 内容）与本文案口径一致，也不会因为一次模型调用把 mock 变成"半真半假"。</p>
     */
    @Override
    public ContentPayload provideRuleSummary(ReportGenerateContext context, List<RuleHit> ruleHits) {
        if (ruleHits == null || ruleHits.isEmpty()) {
            return null;
        }
        StringBuilder sb = new StringBuilder(256);
        sb.append("<p>").append(TAG).append("本次报告共命中 ").append(ruleHits.size())
                .append(" 条经验规则，按章节归纳如下：</p>\n<ol>\n");
        for (RuleHit hit : ruleHits) {
            sb.append("  <li>");
            if (StringUtils.hasText(hit.getCatalogName())) {
                sb.append("<strong>").append(esc(hit.getCatalogName())).append("</strong>：");
            }
            sb.append(esc(hit.getBlockName())).append("</li>\n");
        }
        sb.append("</ol>");
        return new ContentPayload(sb.toString());
    }

    /**
     * 模拟态的风险要点总结（2026-09-18 新增）
     *
     * <p>与真实链路**同契约**：同时给出总结 + 「只保留哪几条」。真实链路是模型挑
     * 「最严重的 N 条」；模拟态没有判断力，固定取**模板顺序前 {@value #MAX_RISK_ITEMS} 条**，
     * 这样切 mock 也能看到"风险要点只列 5 条"的版面，不至于又变回罗列全部。</p>
     */
    @Override
    public RuleSummaryResult summarizeRuleRisks(ReportGenerateContext context, List<RuleHit> ruleHits) {
        if (ruleHits == null || ruleHits.isEmpty()) {
            return null;
        }
        List<String> keep = new ArrayList<String>();
        List<RuleHit> picked = new ArrayList<RuleHit>();
        for (RuleHit hit : ruleHits) {
            if (keep.size() >= MAX_RISK_ITEMS) {
                break;
            }
            keep.add(hit.getBlockCode());
            picked.add(hit);
        }
        return new RuleSummaryResult(provideRuleSummary(context, picked), keep);
    }

    /* ==================== 内容生成 ==================== */

    /**
     * 按 {@code analysisType} / {@code fillType} 造内容
     *
     * <p>返回空串表示"无内容"（该块按 emptyStrategy 占位或隐藏）。</p>
     */
    private String buildByType(AppReportContentBlock block, String blockName,
                               String customerName, String catalogName) {
        String analysisType = block.getAnalysisType();
        String fillType = block.getFillType();
        String where = StringUtils.hasText(catalogName) ? catalogName : "本报告";

        // 经验规则（智策引擎）：模拟"命中"
        if (ReportConstants.ANALYSIS_RULE.equalsIgnoreCase(analysisType)) {
            return "<p>" + TAG + "经校验，" + esc(customerName) + "在「" + esc(where) + "」命中规则："
                    + "<strong>" + esc(blockName) + "</strong>。</p>\n"
                    + "<p>处置建议：核实相关情况，必要时补充说明材料并跟踪后续变化。</p>";
        }
        // 表格溯源：给一张结构完整的假表格（前端"点开弹窗"能看到东西）
        if (ReportConstants.ANALYSIS_TRACE_TABLE.equalsIgnoreCase(analysisType)) {
            return mockTable();
        }
        // 链接溯源：链接开头来自信贷配置表，模拟态同样留空（配合 HIDE 不渲染）
        if (ReportConstants.ANALYSIS_TRACE_LINK.equalsIgnoreCase(analysisType)) {
            return null;
        }
        // 外部灌入
        if (ReportConstants.ANALYSIS_EXTERNAL.equalsIgnoreCase(analysisType)) {
            return "<p>" + TAG + esc(blockName) + "：该块内容由外部接口灌入，模拟态给出占位文案。</p>";
        }

        // 其余（ANALYSIS / 无 analysisType）按 fillType 分流
        if (ReportConstants.FILL_TITLE.equalsIgnoreCase(fillType)) {
            return esc(blockName);
        }
        if (ReportConstants.FILL_TABLE.equalsIgnoreCase(fillType)) {
            return mockTable();
        }
        if (ReportConstants.FILL_SOURCE_LINK.equalsIgnoreCase(fillType)) {
            return null;
        }
        return "<p>" + TAG + "针对" + esc(customerName) + "的「" + esc(blockName) + "」："
                + "整体情况与上次检查相比无重大异常，相关数据已核实，建议持续关注指标变化。</p>";
    }

    /** 一张 3 行的模拟表格（md 文本，与真实链路 TRACE_TABLE 的输出形态一致） */
    private String mockTable() {
        return TABLE_HEADER
                + "| 1 | 示例项一 | 1,000.00 | 万元 | " + TAG + " |\n"
                + "| 2 | 示例项二 | 2,000.00 | 万元 | " + TAG + " |\n"
                + "| 3 | 示例项三 | 3,000.00 | 万元 | " + TAG + " |\n";
    }

    /** RULE 块给「命中」结论；其余返回 null（风险行只对 RULE 块建） */
    private static String checkResultOf(AppReportContentBlock block) {
        return ReportConstants.ANALYSIS_RULE.equalsIgnoreCase(block.getAnalysisType())
                ? CHECK_RESULT_HIT : null;
    }

    /* ==================== JSON 可选覆盖 ==================== */

    private String lookupOverride(String blockCode, String customerName) {
        if (!StringUtils.hasText(blockCode)) {
            return null;
        }
        ensureLoaded();
        String content = contentMap.get(blockCode);
        if (!StringUtils.hasText(content)) {
            return null;
        }
        log.info("【报告内容加工】模拟内容命中 JSON 覆盖 blockCode={}", blockCode);
        return content.replace(CUSTOMER_NAME_TOKEN, customerName);
    }

    /** 首次调用时加载可选覆盖内容，失败则忽略（不影响生成流程） */
    private void ensureLoaded() {
        if (contentMap != null) {
            return;
        }
        synchronized (this) {
            if (contentMap != null) {
                return;
            }
            Map<String, String> contents = new HashMap<>();
            try (InputStream in = new ClassPathResource(RESOURCE_PATH).getInputStream()) {
                JSONObject root = JSON.parseObject(StreamUtils.copyToString(in, StandardCharsets.UTF_8));
                JSONObject contentNode = root.getJSONObject("content");
                if (contentNode != null) {
                    contentNode.forEach((k, v) -> contents.put(k, v == null ? null : String.valueOf(v)));
                }
                log.info("已加载模拟内容覆盖资源（可选）：{} 条；命中不了即走「按块类型造内容」", contents.size());
            } catch (Exception e) {
                log.warn("模拟内容覆盖资源不可用（{}），全部按块类型造内容：{}", RESOURCE_PATH, e.getMessage());
            }
            contentMap = contents;
        }
    }

    /** 轻量 HTML 转义（内容里有用户/模板来的文本） */
    private static String esc(String s) {
        if (s == null) {
            return "";
        }
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }
}
