package com.suzhou.bank.service.report.ai;

import com.suzhou.bank.service.report.model.ReportConstants;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 预警建议模型输出解析器
 *
 * <p>模型按提示词要求输出 Markdown 表格（7 列）+ 总结，本类把它解析成结构化行。
 * 提示词里已约定「固定 7 列、每行以竖线开头结尾、单元格不得含换行与竖线」，
 * 但模型仍可能漂移，所以这里做了容错：</p>
 * <ul>
 *   <li>只认以 {@code |} 开头的行，跳过表头行与 {@code ---|---} 分隔行；</li>
 *   <li>列数多于 7 时，把中间多出的部分合并进「风险点描述」，最后一列仍是「所在章节」；</li>
 *   <li>列数少于 7 时，按顺序补齐、缺失列留空（不整行丢弃，保住已识别到的信息）；</li>
 *   <li>等级列兼容「红/橙/黄」与「红色预警/RED/YELLOW」等多种写法，统一成码值。</li>
 * </ul>
 *
 * <p>纯静态工具类、不依赖 Spring，便于离线单测。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
public final class WarningAdviceOutputParser {

    /** 表格固定列数 */
    private static final int COLUMN_COUNT = 7;

    /** 核心提示行：核心提示：xxx / 核心提示: xxx */
    private static final Pattern CORE_TIP_PATTERN =
            Pattern.compile("核心提示\\s*[:：]\\s*(.+)");

    private WarningAdviceOutputParser() {
    }

    /**
     * 解析模型输出
     *
     * @param modelOutput 模型返回的原始文本（Markdown）
     */
    public static ParsedOutput parse(String modelOutput) {
        ParsedOutput output = new ParsedOutput();
        output.setRaw(modelOutput);
        if (!StringUtils.hasText(modelOutput)) {
            return output;
        }
        String[] lines = modelOutput.replace("\r\n", "\n").replace('\r', '\n').split("\n");
        boolean headerSkipped = false;
        for (String rawLine : lines) {
            String line = rawLine.trim();
            if (line.isEmpty()) {
                continue;
            }
            if (line.startsWith("|")) {
                if (isSeparatorRow(line)) {
                    continue;
                }
                List<String> cells = splitCells(line);
                if (!headerSkipped && isHeaderRow(cells)) {
                    headerSkipped = true;
                    continue;
                }
                headerSkipped = true;
                Row row = toRow(cells);
                if (row != null) {
                    output.getRows().add(row);
                }
                continue;
            }
            if (output.getCoreTip() == null) {
                Matcher matcher = CORE_TIP_PATTERN.matcher(line.replace("**", ""));
                if (matcher.find()) {
                    output.setCoreTip(cleanCell(matcher.group(1)));
                }
            }
        }
        output.setTableFound(headerSkipped || !output.getRows().isEmpty());
        // 序号缺失或重复时，按解析顺序补正，保证前端"序号"列始终连续可读
        for (int i = 0; i < output.getRows().size(); i++) {
            Row row = output.getRows().get(i);
            if (row.getSeqNo() == null) {
                row.setSeqNo(i + 1);
            }
        }
        return output;
    }

    /** 分隔行：|---|:---:|---| 之类，去掉竖线、横线、冒号、空格后应为空 */
    private static boolean isSeparatorRow(String line) {
        String stripped = line.replace("|", "").replace("-", "").replace(":", "").replace(" ", "");
        return stripped.isEmpty();
    }

    /** 表头行：包含「序号」或「预警信号」等表头关键词 */
    private static boolean isHeaderRow(List<String> cells) {
        for (String cell : cells) {
            if (cell.contains("序号") || cell.contains("预警信号描述") || cell.contains("建议预警等级")) {
                return true;
            }
        }
        return false;
    }

    /** 按竖线切列，去掉首尾空单元（表格行以 | 开头结尾会产生两个空串） */
    private static List<String> splitCells(String line) {
        String body = line;
        if (body.startsWith("|")) {
            body = body.substring(1);
        }
        if (body.endsWith("|")) {
            body = body.substring(0, body.length() - 1);
        }
        List<String> cells = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        boolean escaped = false;
        for (int i = 0; i < body.length(); i++) {
            char c = body.charAt(i);
            if (escaped) {
                current.append(c);
                escaped = false;
                continue;
            }
            if (c == '\\') {
                escaped = true;
                continue;
            }
            if (c == '|') {
                cells.add(cleanCell(current.toString()));
                current.setLength(0);
                continue;
            }
            current.append(c);
        }
        cells.add(cleanCell(current.toString()));
        return cells;
    }

    /** 单元格清洗：去 ** 强调、去首尾空白 */
    private static String cleanCell(String cell) {
        if (cell == null) {
            return "";
        }
        return cell.replace("**", "").trim();
    }

    private static Row toRow(List<String> cells) {
        if (cells.isEmpty()) {
            return null;
        }
        // 全是空值得行直接丢弃（模型偶尔输出一个空行模板）
        boolean allBlank = true;
        for (String cell : cells) {
            if (StringUtils.hasText(cell)) {
                allBlank = false;
                break;
            }
        }
        if (allBlank) {
            return null;
        }

        Row row = new Row();
        if (cells.size() > COLUMN_COUNT) {
            log.warn("预警建议表格列数={} 多于约定的 {}，多出的内容并入「风险点描述」", cells.size(), COLUMN_COUNT);
        }
        row.setSeqNo(parseSeqNo(cellAt(cells, 0)));
        row.setWarningLevel(normalizeLevel(cellAt(cells, 1)));
        row.setSignalDesc(cellAt(cells, 2));
        row.setTriggerCondition(cellAt(cells, 3));
        row.setSourceText(cellAt(cells, 4));
        row.setRiskDesc(joinMiddle(cells, 5));
        row.setChapter(cellAt(cells, cells.size() - 1));
        if (!StringUtils.hasText(row.getWarningLevel())) {
            // 等级取不到就没什么意义了（前端按等级排序、统计），此行丢弃并告警
            log.warn("预警建议某行等级为空，已丢弃：{}", String.join(" / ", cells));
            return null;
        }
        return row;
    }

    private static String cellAt(List<String> cells, int index) {
        return index >= 0 && index < cells.size() ? cells.get(index) : "";
    }

    /** 第 6 列（风险点描述）：列数超过 7 时把中间多出的格子合进来 */
    private static String joinMiddle(List<String> cells, int fromIndex) {
        if (cells.size() <= COLUMN_COUNT) {
            return cellAt(cells, fromIndex);
        }
        StringBuilder sb = new StringBuilder();
        for (int i = fromIndex; i < cells.size() - 1; i++) {
            if (StringUtils.hasText(cells.get(i))) {
                if (sb.length() > 0) {
                    sb.append(' ');
                }
                sb.append(cells.get(i));
            }
        }
        return sb.toString();
    }

    private static Integer parseSeqNo(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        try {
            return Integer.valueOf(value.replaceAll("[^0-9]", ""));
        } catch (Exception e) {
            return null;
        }
    }

    /** 等级归一化：红/红色/红色预警/RED → RED；橙、黄同理 */
    private static String normalizeLevel(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        String v = value.trim().toUpperCase();
        if (v.startsWith("RED") || v.startsWith("红")) {
            return ReportConstants.WARNING_LEVEL_RED;
        }
        if (v.startsWith("ORANGE") || v.startsWith("橙")) {
            return ReportConstants.WARNING_LEVEL_ORANGE;
        }
        if (v.startsWith("YELLOW") || v.startsWith("黄")) {
            return ReportConstants.WARNING_LEVEL_YELLOW;
        }
        return null;
    }

    /** 解析结果 */
    @Data
    public static class ParsedOutput {

        /** 逐条预警信号 */
        private List<Row> rows = new ArrayList<>();

        /** 核心提示（模型总结里的最后一条；解析不到为 null） */
        private String coreTip;

        /** 模型原始输出（失败排查与快照用） */
        private String raw;

        /** 是否识别到表格（用于区分"未发现预警信号"与"格式漂移"） */
        private boolean tableFound;
    }

    /** 一条预警信号 */
    @Data
    public static class Row {
        private Integer seqNo;
        private String warningLevel;
        private String signalDesc;
        private String triggerCondition;
        private String sourceText;
        private String riskDesc;
        private String chapter;
    }
}
