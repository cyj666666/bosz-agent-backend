package com.suzhou.bank.service.report.ai;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.suzhou.bank.entity.report.AppReportAiRisk;
import com.suzhou.bank.entity.report.AppReportCatalog;
import com.suzhou.bank.entity.report.AppReportContentInstance;
import com.suzhou.bank.mapper.report.AppReportAiRiskMapper;
import com.suzhou.bank.mapper.report.AppReportCatalogMapper;
import com.suzhou.bank.mapper.report.AppReportContentInstanceMapper;
import com.suzhou.bank.service.report.config.ReportAiAnalysisProperties;
import com.suzhou.bank.service.report.model.ReportConstants;
import com.suzhou.bank.service.report.spi.ReportAnalysisDataSource;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 全文分析素材组装器
 *
 * <p>把「报告正文摘取 + 外部数据」拼成一段给大模型看的纯文本素材。正文摘取口径：</p>
 * <ul>
 *   <li>{@code analysisType=ANALYSIS}（分析类正文）—— <b>全量纳入</b>，是素材主体；</li>
 *   <li>{@code fillType=TITLE} —— 作为章节标题纳入，给模型上下文；</li>
 *   <li>{@code analysisType=RULE} —— <b>纳入「待处理」与「已采纳」的要点</b>，只排除人工判定为
 *       {@code INVALID}（无效）的。<br>
 *       ⚠️ 2026-09-13 由「仅已采纳」放开为「待处理 + 已采纳」：全文分析要校验
 *       <b>报告是否已回答了风险要点</b>，核对对象必须是完整清单，只给已采纳的就漏掉了待处理项。</li>
 *   <li>{@code fillType=TABLE} —— 表格块纳入（HTML 表格会被转成「单元格 + 制表符」的文本）；</li>
 *   <li>{@code fillType=SOURCE_LINK} —— 排除（块本身只是外链按钮，没有分析价值）。</li>
 * </ul>
 * <p>排序按目录树的真实层级（父级 sortNo 链 + 本级 sortNo），报告级内容块排在最前，
 * 让模型读到的顺序与人工阅读顺序一致。正文之后另附【风险要点清单】小节，
 * 给模型一份显式的核对对象。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AnalysisMaterialBuilder {

    private final AppReportContentInstanceMapper instanceMapper;
    private final AppReportCatalogMapper catalogMapper;
    private final AppReportAiRiskMapper riskMapper;
    private final ReportAiAnalysisProperties properties;

    /** 外部数据域（预留扩展点）：容器里没有实现时 provider 返回空列表，不影响主流程 */
    private final ObjectProvider<ReportAnalysisDataSource> dataSources;

    /**
     * 组装素材
     *
     * @param reportNo     报告编号
     * @param checkTaskNo  日检流水号
     * @param customerId   客户编号
     * @param customerName 客户名称
     * @param reportTitle  报告标题
     * @return 纯文本素材（已按上限截断）
     */
    public String build(String reportNo, String checkTaskNo, String customerId,
                       String customerName, String reportTitle) {
        StringBuilder sb = new StringBuilder(8192);

        sb.append("【报告基本信息】\n");
        sb.append("客户名称：").append(nvl(customerName)).append('\n');
        sb.append("客户编号：").append(nvl(customerId)).append('\n');
        sb.append("报告标题：").append(nvl(reportTitle)).append('\n');
        sb.append("日检流水号：").append(nvl(checkTaskNo)).append('\n');
        sb.append("报告编号：").append(nvl(reportNo)).append('\n');

        appendReportBody(sb, reportNo);
        appendExternalData(sb, reportNo, customerId, customerName);

        String material = sb.toString();
        int limit = properties.getMaxMaterialChars();
        if (limit > 0 && material.length() > limit) {
            material = material.substring(0, limit) + "\n\n（素材过长，已按 " + limit + " 字符截断）";
        }
        return material;
    }

    /**
     * 素材里**不纳入**的内容块（按模板 {@code agentCode} 判定）。
     *
     * <p>用户口径（2026-09-19）：全文分析**不参考这两块** ——</p>
     * <ul>
     *   <li>{@code dxjclsqk} 「单项检查任务落实情况」</li>
     *   <li>{@code tddkjcqk} 「特定贷款的检查情况」</li>
     * </ul>
     * <p>两块讲的都是**非日常检查**（单项检查 / 特定检查贷款），与「日常贷后检查结论」不是一回事，
     * 纳入素材只会让模型把别的检查口径当成日常检查的结论（{@code tddkjcqk} 历史上还出现过
     * 把提示词原文写进正文的事故）。</p>
     * <p>按 {@code agentCode} 判定：blockName 会随文案调整，agentCode 与模板/规则配置同源、稳定。</p>
     */
    private static final Set<String> EXCLUDED_AGENT_CODES =
            new HashSet<>(Arrays.asList("dxjclsqk", "tddkjcqk"));

    /** 报告正文摘取：按目录树顺序输出 */
    private void appendReportBody(StringBuilder sb, String reportNo) {
        List<AppReportContentInstance> instances = new ArrayList<>();
        for (AppReportContentInstance ins : instanceMapper.selectList(
                Wrappers.<AppReportContentInstance>lambdaQuery()
                        .eq(AppReportContentInstance::getReportNo, reportNo))) {
            // 排除「单项检查 / 特定贷款检查」两块（见 EXCLUDED_AGENT_CODES）；
            // 这里先过滤再分组 ⇒ 某目录下块被全部排除时，目录标题也不会单独留下
            if (ins.getAgentCode() != null && EXCLUDED_AGENT_CODES.contains(ins.getAgentCode())) {
                continue;
            }
            instances.add(ins);
        }

        if (instances.isEmpty()) {
            sb.append("\n【报告正文摘取】\n（该报告暂无内容实例）\n");
            return;
        }

        // 已采纳的风险要点集合：只有命中这里的 RULE 块才纳入
        List<AppReportAiRisk> risks = riskMapper.selectList(
                Wrappers.<AppReportAiRisk>lambdaQuery()
                        .eq(AppReportAiRisk::getReportNo, reportNo));
        Map<String, String> riskStatusOfBlock = new HashMap<>();
        for (AppReportAiRisk risk : risks) {
            riskStatusOfBlock.put(risk.getBlockCode(), risk.getStatus());
        }

        // 目录顺序
        List<AppReportCatalog> catalogs = catalogMapper.selectList(null);
        Map<String, AppReportCatalog> catalogByCode = new HashMap<>();
        for (AppReportCatalog c : catalogs) {
            catalogByCode.put(c.getCatalogCode(), c);
        }
        Map<String, List<AppReportContentInstance>> blocksByCatalog = new LinkedHashMap<>();
        List<AppReportContentInstance> reportLevel = new ArrayList<>();
        for (AppReportContentInstance ins : instances) {
            if (!StringUtils.hasText(ins.getCatalogCode())) {
                reportLevel.add(ins);
            } else {
                blocksByCatalog.computeIfAbsent(ins.getCatalogCode(), k -> new ArrayList<>()).add(ins);
            }
        }
        List<String> orderedCodes = new ArrayList<>(blocksByCatalog.keySet());
        Map<String, String> orderKeyCache = new HashMap<>();
        orderedCodes.sort(Comparator.comparing(code -> catalogOrderKey(code, catalogByCode, orderKeyCache)));

        sb.append("\n【报告正文摘取】\n");

        // 风险要点清单：正文里逐块输出之外，末尾再给一份显式清单，
        // 供模型按条核对「报告是否已回答」（提示词要求它只列缺项，没有清单就无从判断）
        List<String> riskChecklist = new ArrayList<>();

        List<AppReportContentInstance> head = new ArrayList<>(reportLevel);
        head.sort(Comparator.comparing(AppReportContentInstance::getSortNo,
                Comparator.nullsLast(Comparator.naturalOrder())));
        for (AppReportContentInstance ins : head) {
            appendBlock(sb, ins, riskStatusOfBlock, "报告头", riskChecklist);
        }

        for (String catalogCode : orderedCodes) {
            AppReportCatalog catalog = catalogByCode.get(catalogCode);
            String catalogName = catalog == null || !StringUtils.hasText(catalog.getCatalogName())
                    ? catalogCode : catalog.getCatalogName();
            sb.append("\n== ").append(catalogName).append(" ==\n");
            List<AppReportContentInstance> blocks = blocksByCatalog.get(catalogCode);
            blocks.sort(Comparator.comparing(AppReportContentInstance::getSortNo,
                    Comparator.nullsLast(Comparator.naturalOrder())));
            for (AppReportContentInstance ins : blocks) {
                appendBlock(sb, ins, riskStatusOfBlock, catalogName, riskChecklist);
            }
        }

        appendRiskChecklist(sb, riskChecklist);
    }

    /**
     * 风险要点清单小结
     * <p>提示词要求模型核对「报告是否回答了风险要点」，因此末尾给一份按顺序编号的清单，
     * 让它有明确的核对对象；清单为空时不输出该节。</p>
     */
    private void appendRiskChecklist(StringBuilder sb, List<String> riskChecklist) {
        if (riskChecklist.isEmpty()) {
            return;
        }
        sb.append("\n【风险要点清单】\n");
        sb.append("（以下为本次需要核对其是否已被报告回答的风险要点，共 ")
                .append(riskChecklist.size()).append(" 条）\n");
        for (int i = 0; i < riskChecklist.size(); i++) {
            sb.append(i + 1).append(". ").append(riskChecklist.get(i)).append('\n');
        }
    }

    /** 单个内容块的摘取规则 */
    private void appendBlock(StringBuilder sb, AppReportContentInstance ins,
                            Map<String, String> riskStatusOfBlock, String catalogName,
                            List<String> riskChecklist) {
        String fillType = ins.getFillType();
        String analysisType = ins.getAnalysisType();
        String content = ins.getContent();
        if (!StringUtils.hasText(content)) {
            return;
        }
        // 外链按钮：无分析价值，排除
        if (ReportConstants.FILL_SOURCE_LINK.equals(fillType)) {
            return;
        }
        String riskStatus = null;
        // 风险要点：**待处理 + 已采纳都纳入**（要校验"报告是否已回答风险要点"），
        // 只排除人工判定为无效的；同时收集进末尾的核对清单。
        if (ReportConstants.ANALYSIS_RULE.equals(analysisType)) {
            riskStatus = riskStatusOfBlock.get(ins.getBlockCode());
            if (ReportConstants.RISK_INVALID.equals(riskStatus)) {
                return;
            }
        }
        String text = htmlToText(content);
        if (!StringUtils.hasText(text)) {
            return;
        }
        if (ReportConstants.FILL_TITLE.equals(fillType)) {
            sb.append(text).append('\n');
            return;
        }
        String name = StringUtils.hasText(ins.getBlockName()) ? ins.getBlockName() : ins.getBlockCode();
        if (ReportConstants.ANALYSIS_RULE.equals(analysisType)) {
            riskChecklist.add(name + "（" + catalogName + "）");
        }
        String tag = ReportConstants.ANALYSIS_RULE.equals(analysisType) ? riskTag(riskStatus)
                : (ReportConstants.FILL_TABLE.equals(fillType) ? "表格" : "分析内容");
        sb.append("- [").append(tag).append("] ").append(name).append("：\n")
                .append(indent(text)).append('\n');
    }

    /** 风险要点的状态标注：让模型知道这条是"已采纳"还是"待处理" */
    private static String riskTag(String status) {
        if (ReportConstants.RISK_ADOPTED.equals(status)) {
            return "风险要点（已采纳）";
        }
        return "风险要点（待处理）";
    }

    /** 外部数据：由各 {@link ReportAnalysisDataSource} 实现提供，无实现时整节省略 */
    private void appendExternalData(StringBuilder sb, String reportNo,
                                   String customerId, String customerName) {
        List<ReportAnalysisDataSource> sources = new ArrayList<>();
        dataSources.forEach(sources::add);
        if (sources.isEmpty()) {
            return;
        }
        StringBuilder section = new StringBuilder();
        for (ReportAnalysisDataSource source : sources) {
            String text;
            try {
                text = source.load(reportNo, customerId, customerName);
            } catch (Exception e) {
                // 单个数据域取数失败不影响整篇分析
                log.warn("全文分析外部数据域取数失败：code={} reportNo={} customerId={} 原因={}",
                        source.code(), reportNo, customerId, e.getMessage());
                continue;
            }
            if (!StringUtils.hasText(text)) {
                continue;
            }
            section.append("\n-- ").append(source.label()).append(" --\n")
                    .append(indent(text)).append('\n');
        }
        if (section.length() > 0) {
            sb.append("\n【外部数据】\n").append(section);
        }
    }

    /** 目录排序键：父级链 + 本级 sortNo（零填充，保证字典序等于数值序） */
    private String catalogOrderKey(String catalogCode, Map<String, AppReportCatalog> byCode,
                                  Map<String, String> cache) {
        String cached = cache.get(catalogCode);
        if (cached != null) {
            return cached;
        }
        AppReportCatalog catalog = byCode.get(catalogCode);
        if (catalog == null) {
            return "9999/" + catalogCode;
        }
        int sortNo = catalog.getSortNo() == null ? 9999 : catalog.getSortNo();
        String self = String.format("%04d", sortNo);
        String key = StringUtils.hasText(catalog.getParentCode())
                ? catalogOrderKey(catalog.getParentCode(), byCode, cache) + "/" + self
                : self;
        cache.put(catalogCode, key);
        return key;
    }

    /** 轻量 HTML → 文本：保留段落换行、表格单元格用制表符分隔，便于大模型理解 */
    static String htmlToText(String html) {
        String text = html
                .replaceAll("(?i)<\\s*br\\s*/?>", "\n")
                .replaceAll("(?i)</\\s*(p|div|li|tr|h[1-6]|table)\\s*>", "\n")
                .replaceAll("(?i)</\\s*(td|th)\\s*>", "\t")
                .replaceAll("(?i)<\\s*li\\s*>", "・")
                .replaceAll("<[^>]*>", "")
                .replace("&nbsp;", " ")
                .replace("&lt;", "<")
                .replace("&gt;", ">")
                .replace("&quot;", "\"")
                .replace("&#39;", "'")
                .replace("&amp;", "&");
        // 去空行、去行首尾空白、合并多余空行
        StringBuilder out = new StringBuilder(text.length());
        boolean lastBlank = false;
        for (String line : text.split("\n")) {
            String trimmed = line.replaceAll("[ \t]+$", "").replaceAll("^[ \t]+", "");
            if (trimmed.isEmpty()) {
                if (!lastBlank && out.length() > 0) {
                    out.append('\n');
                }
                lastBlank = true;
                continue;
            }
            out.append(trimmed).append('\n');
            lastBlank = false;
        }
        return out.toString().trim();
    }

    private static String indent(String text) {
        return "    " + text.replace("\n", "\n    ");
    }

    private static String nvl(String value) {
        return StringUtils.hasText(value) ? value : "-";
    }
}
