package com.suzhou.bank.service.report.export;

import com.suzhou.bank.service.report.ReportService;
import com.suzhou.bank.service.report.gateway.ReportExportStorageGateway;
import com.suzhou.bank.service.report.model.ReportBlockVO;
import com.suzhou.bank.service.report.model.ReportCatalogNode;
import com.suzhou.bank.service.report.model.ReportConstants;
import com.suzhou.bank.service.report.model.ReportDetailVO;
import com.suzhou.bank.service.report.model.ReportRiskItem;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.apache.poi.xwpf.usermodel.XWPFRun;
import org.apache.poi.xwpf.usermodel.XWPFTable;
import org.apache.poi.xwpf.usermodel.XWPFTableRow;
import org.apache.poi.xwpf.usermodel.XWPFTableCell;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTP;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTSimpleField;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import java.io.ByteArrayOutputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 报告 Word 导出（真 .docx，POI/XWPF 生成）—— 2026-09-23 测试反馈 #8
 *
 * <p><b>为什么改成后端生成</b>：原实现是前端拼一段 HTML 塞进
 * {@code Blob('application/msword')} 的伪 doc —— 能打开，但**目录与多级标题层级**保不住
 * （那是浏览器导出 doc 的固有限制），而客户明确要求"目录正常、各个层级标题正常"。</p>
 *
 * <p><b>本实现的口径（对齐客户 7 条细则）</b>：</p>
 * <ol>
 *   <li>浏览器自动触发下载 —— 由接口 {@code Content-Disposition: attachment} 实现；</li>
 *   <li>文件名 {@code {公司名称}-日常贷后检查报告-yyyyMMdd.docx}（见 {@link #buildFileName}）；</li>
 *   <li>所见即所得：只导出**当前版本实际有内容的章节**（标题 + 正文 + 数据表格），结构取自
 *       {@link ReportService#detail(String)} 的目录树，与页面同源；</li>
 *   <li>已采纳段落保留修改后内容 —— 正文内容读的就是实例表（人工改过就是改后的，天然满足）；</li>
 *   <li>已标记无效的段落不出现 —— {@code analysisType=RULE} 且对应风险 {@code status=INVALID} 的块整块跳过；</li>
 *   <li>不含导航栏 / 工具栏 / 侧边面板 / 操作按钮 / 溯源链接 —— 只写正文；{@code fillType=SOURCE_LINK}
 *       的块（"溯源链接"按钮）直接跳过；表格溯源入口本就是前端交互，md 表格里没有按钮；</li>
 *   <li>普通 Word 样式：一级/二级/三级目录用 Word 内置 {@code Heading1/2/3} 样式
 *       + 文档开头插**真 TOC 域**（域指令见 {@link #writeTocField}），
 *       在 Word 里更新域即得带页码的目录。</li>
 * </ol>
 *
 * <p>🔴 <b>两件必须知道的事</b>：</p>
 * <ul>
 *   <li><b>扩展名是 {@code .docx} 不是 {@code .doc}</b>：POI 产出的是 OOXML（doсx）格式，
 *       若把文件名写成 {@code .doc}，Word 会提示"文件格式与扩展名不符"。客户需求里写的是
 *       {@code .doc}，实际按 {@code .docx} 给（内容仍是 Word 可正常打开的兼容文档）。</li>
 *   <li><b>TOC 是"域"</b>：Word 打开时目录处会显示提示文字（本实现在域内放了占位说明），
 *       按 {@code Ctrl+A → F9}（或右键→更新域）即生成带页码的完整目录 —— 这是 Word 域机制
 *       的固有行为，不是导出出错。</li>
 * </ul>
 *
 * <p>⚠️ <b>不引第三方 markdown 库</b>：本工程构建走离线（{@code mvn -o}），新增依赖拉不到包；
 * 且正文的 markdown 形态是**受控的**（由 {@code TraceTableBuilder} / 提示词产出：
 * 段落、表格、少量列表与加粗），故用 {@link #writeMarkdown} 做轻量解析即可。</p>
 *
 * @author 曹陆宇
 * @since 1.4.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ReportWordExportService {

    private final ReportService reportService;

    /**
     * 导出文件落对象存储（行内 = 内容平台；外网 = MOCK）
     *
     * <p>🔴 这是另一个"两版实现不同"的接缝，与
     * {@link com.suzhou.bank.service.report.gateway.AfterLoanRiskApplyGateway} 同一套路子：
     * 本类只认接口，两版代码逐字相同。**best-effort** —— 存不上去不影响用户下载。</p>
     */
    private final ReportExportStorageGateway exportStorageGateway;

    /** 导出结果（字节 + 建议文件名，控制器据此设 header） */
    public static class ExportResult {

        private final byte[] bytes;
        private final String fileName;

        public ExportResult(byte[] bytes, String fileName) {
            this.bytes = bytes;
            this.fileName = fileName;
        }

        public byte[] getBytes() {
            return bytes;
        }

        public String getFileName() {
            return fileName;
        }
    }

    /**
     * 生成 .docx
     *
     * @param reportNo 报告编号
     * @return 字节 + 建议文件名
     * @throws IllegalStateException 报告不存在 / 生成失败（由控制器转成 4xx/5xx）
     */
    public ExportResult export(String reportNo, String operatorNo) {
        if (!StringUtils.hasText(reportNo)) {
            throw new IllegalStateException("缺少报告编号（reportNo），无法导出");
        }
        ReportDetailVO detail;
        try {
            detail = reportService.detail(reportNo);
        } catch (RuntimeException e) {
            // detail() 在报告不存在时会抛业务异常 —— 统一换成导出侧的可读文案
            throw new IllegalStateException("读取报告详情失败：" + e.getMessage(), e);
        }
        if (detail == null) {
            throw new IllegalStateException("报告不存在或尚未生成完成：" + reportNo);
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        // try-with-resources：XWPFDocument 关闭时会把内容写进 out
        try (XWPFDocument doc = new XWPFDocument()) {
            writeTitle(doc, detail);
            writeTocField(doc);
            writeBody(doc, detail);
            doc.write(out);
        } catch (Exception e) {
            log.error("导出 Word 失败：reportNo={} 原因={}", reportNo, e.getMessage(), e);
            throw new IllegalStateException("导出 Word 失败：" + e.getMessage(), e);
        }

        byte[] bytes = out.toByteArray();
        String fileName = buildFileName(detail);
        // 落对象存储（行内 = 内容平台）——best-effort，失败只告警，⛔ 不影响用户下载
        storeToObjectStorage(fileName, bytes, detail, operatorNo);
        return new ExportResult(bytes, fileName);
    }

    /**
     * 把导出文件同步到对象存储（行内 = 内容平台）
     *
     * <p>🔴 <b>为什么放在"生成之后、返回之前"且整体 try-catch</b>：</p>
     * <ul>
     *   <li>文件已经生成好了 —— 上传是我方的额外动作，**不能因为平台抖动让用户下载失败**；</li>
     *   <li>但也不能静默：失败要打 ERROR 并带上 reportNo/文件名，便于事后补传。</li>
     * </ul>
     *
     * <p>⚠️ 目前是**同步**调用：若行内内容平台上传耗时明显（大文件/慢链路），
     * 建议把本方法体改成 {@code @Async} 或投递到线程池 —— 那时记得同时把
     * "上传失败" 的可见性补上（例如落一张待补传表），否则就退化成静默失效了。</p>
     */
    private void storeToObjectStorage(String fileName, byte[] bytes, ReportDetailVO detail, String operatorNo) {
        try {
            ReportExportStorageGateway.ExportFile file = new ReportExportStorageGateway.ExportFile(
                    fileName, bytes, detail.getReportNo(), detail.getCheckTaskNo(),
                    detail.getCustomerName(), operatorNo,
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document");
            ReportExportStorageGateway.StoreResult result = exportStorageGateway.store(file);
            if (result != null && result.isStored()) {
                log.info("导出文件已同步到对象存储：reportNo={} fileName={} objectKey={}",
                        detail.getReportNo(), fileName, result.getObjectKey());
            } else {
                // 外网 MOCK、或行内上传失败 —— 必须留下可见痕迹
                log.warn("导出文件未同步到对象存储：reportNo={} fileName={} size={}B 说明={}",
                        detail.getReportNo(), fileName, bytes.length,
                        result == null ? "网关返回 null" : result.getMessage());
            }
        } catch (Exception e) {
            log.error("导出文件同步对象存储异常（已忽略，用户下载不受影响）：reportNo={} fileName={} 原因={}",
                    detail.getReportNo(), fileName, e.getMessage(), e);
        }
    }

    /**
     * 文件名：{@code {公司名称}-日常贷后检查报告-yyyyMMdd.docx}
     *
     * <p>用**导出当天**的日期（客户给的是「yyyyMMdd」未指明基准；取下载日最符合
     * "这是今天导出的那份报告"的直觉）。公司名称里的文件名非法字符（{@code \ / : * ? " < > |}）
     * 一律替换成下划线 —— 否则浏览器会丢掉整个文件名、或截断。</p>
     */
    public String buildFileName(ReportDetailVO detail) {
        String company = detail == null ? null : detail.getCustomerName();
        if (!StringUtils.hasText(company)) {
            company = "报告";
        }
        String safe = company.replaceAll("[\\\\/:*?\"<>|\\s]+", "_");
        String date = new SimpleDateFormat("yyyyMMdd").format(new Date());
        return safe + "-日常贷后检查报告-" + date + ".docx";
    }

    /* ==================== 文档骨架 ==================== */

    /** 报告头：大标题（报告标题）+ 客户名称一行 */
    private void writeTitle(XWPFDocument doc, ReportDetailVO detail) {
        String title = StringUtils.hasText(detail.getReportTitle())
                ? detail.getReportTitle() : "日常贷后检查报告";
        XWPFParagraph p = doc.createParagraph();
        p.setStyle("Title");
        XWPFRun r = p.createRun();
        r.setText(title);
        r.setBold(true);
        r.setFontSize(22);

        if (StringUtils.hasText(detail.getCustomerName())) {
            XWPFParagraph sub = doc.createParagraph();
            XWPFRun sr = sub.createRun();
            sr.setText("客户名称：" + detail.getCustomerName());
            sr.setFontSize(11);
        }
    }

    /**
     * 插入真 TOC 域
     *
     * <p>域指令 = {@code TOC} + 开关：取标题级别 1~3、条目带超链接、隐藏制表位页码、改用大纲级别。
     * 域里放了一句占位说明，用户在 Word 里更新域后会被真实目录替换。</p>
     *
     * <p>⚠️ 本注释刻意<b>不写那两个反斜杠开关</b>：Java 源码里 {@code 反斜杠+u} 会被当作 Unicode 转义
     * 预处理（**注释里也生效**）⇒ 写成 {@code 反斜杠u} 直接编译报「非法的 Unicode 转义」。
     * 真正的域指令在下面的字符串常量里（那里用的是双反斜杠转义，安全）。</p>
     */
    private void writeTocField(XWPFDocument doc) {
        XWPFParagraph p = doc.createParagraph();
        CTP ctp = p.getCTP();
        CTSimpleField field = ctp.addNewFldSimple();
        field.setInstr("TOC \\o \"1-3\" \\h \\z \\u");
        XWPFRun hint = p.createRun();
        hint.setText("（目录：在 Word 中按 Ctrl+A 后 F9、或右键「更新域」即可生成带页码的目录）");
        hint.setFontSize(9);
        hint.setItalic(true);
    }

    /** 正文：按目录树顺序（一级→其下块→二级→…）写；同时保证"当前可见章节"才出现 */
    private void writeBody(XWPFDocument doc, ReportDetailVO detail) {
        // 无效风险的块编号集合：这些块整块不导出（客户细则 5）
        Map<String, ReportRiskItem> riskByBlock = indexRisks(detail.getRisks());

        // 报告级内容块（catalogCode 为空，如报告头大标题）——正文最上方
        if (!CollectionUtils.isEmpty(detail.getHeadBlocks())) {
            for (ReportBlockVO block : detail.getHeadBlocks()) {
                writeBlock(doc, block, riskByBlock, 1);
            }
        }

        if (CollectionUtils.isEmpty(detail.getCatalogs())) {
            return;
        }
        for (ReportCatalogNode node : detail.getCatalogs()) {
            writeCatalog(doc, node, riskByBlock);
        }
    }

    /** 递归写目录节点：标题（HeadingN）+ 本节点内容块 + 子节点 */
    private void writeCatalog(XWPFDocument doc, ReportCatalogNode node, Map<String, ReportRiskItem> riskByBlock) {
        if (node == null) {
            return;
        }
        int level = node.getCatalogLevel() == null ? 1 : node.getCatalogLevel();
        // Word 内置标题样式只有 1~9；目录最深三级，直接映射
        int headingLevel = Math.max(1, Math.min(9, level));
        if (StringUtils.hasText(node.getCatalogName())) {
            XWPFParagraph h = doc.createParagraph();
            // ① 套 Word 内置标题样式 —— TOC 域就是靠它抓目录项的（必做）
            h.setStyle("Heading" + headingLevel);
            XWPFRun hr = h.createRun();
            hr.setText(node.getCatalogName());
            // ② 再叠一层直接格式做兜底：万一某台机器的 Word 模板里没有内置 Heading 样式
            //    （样式缺失时 setStyle 静默不生效），层级也还能从字号/加粗上分出来。
            hr.setBold(true);
            hr.setFontSize(headingFontSize(headingLevel));
        }
        if (!CollectionUtils.isEmpty(node.getBlocks())) {
            for (ReportBlockVO block : node.getBlocks()) {
                writeBlock(doc, block, riskByBlock, headingLevel);
            }
        }
        if (!CollectionUtils.isEmpty(node.getChildren())) {
            for (ReportCatalogNode child : node.getChildren()) {
                writeCatalog(doc, child, riskByBlock);
            }
        }
    }

    /**
     * 写一个内容块
     *
     * <p>跳过规则（按客户细则 5 / 6）：</p>
     * <ul>
     *   <li>{@code fillType=SOURCE_LINK} —— 那是"溯源链接"按钮，属交互元素，不导出；</li>
     *   <li>{@code emptyStrategy=HIDE} 且内容为空 —— 页面上本来就看不见，导出也不该出现；</li>
     *   <li>{@code analysisType=RULE} 且对应风险 {@code status=INVALID} —— 已标记无效的段落不导出。</li>
     * </ul>
     */
    private void writeBlock(XWPFDocument doc, ReportBlockVO block, Map<String, ReportRiskItem> riskByBlock,
                            int catalogLevel) {
        if (block == null) {
            return;
        }
        if (ReportConstants.FILL_SOURCE_LINK.equalsIgnoreCase(block.getFillType())) {
            return;
        }
        ReportRiskItem risk = riskByBlock.get(block.getBlockCode());
        if (risk != null && ReportConstants.RISK_INVALID.equalsIgnoreCase(risk.getStatus())) {
            return;
        }
        String content = block.getContent();
        boolean blank = !StringUtils.hasText(content);
        if (blank && ReportConstants.EMPTY_HIDE.equalsIgnoreCase(block.getEmptyStrategy())) {
            return;
        }
        if (blank) {
            // PLACEHOLDER：页面上显示"暂无数据"占位，导出保留同一口径
            XWPFParagraph p = doc.createParagraph();
            XWPFRun r = p.createRun();
            r.setText("暂无数据");
            r.setItalic(true);
            return;
        }
        writeMarkdown(doc, content, null);
    }

    /* ==================== 轻量 markdown → docx ==================== */

    /**
     * 把一段 markdown 写进文档
     *
     * <p>支持（够用即可，不做完整 md 解析）：表格（{@code |a|b|} + {@code |---|} 分隔行）、
     * 有序/无序列表、行内加粗 {@code **x**}、普通段落、以及 {@code #} 标题**降级为加粗段落**
     * （正文标题由结构渲染、不由模型写 —— 若内容里真出现 {@code #}，不并入目录层级，避免打乱目录）。</p>
     *
     * @param styleOverride 段落样式覆盖（当前调用方传 null，保留给将来"表格单元格内嵌文本"用）
     */
    private void writeMarkdown(XWPFDocument doc, String md, String styleOverride) {
        String[] lines = md.replace("\r\n", "\n").replace("\r", "\n").split("\n", -1);
        int i = 0;
        while (i < lines.length) {
            String line = lines[i];
            String trimmed = line.trim();

            // 空行：分段
            if (trimmed.isEmpty()) {
                i++;
                continue;
            }
            // 代码围栏：整段按等宽文本输出（内容里偶有 JSON 片段）
            if (trimmed.startsWith("```")) {
                i++;
                while (i < lines.length && !lines[i].trim().startsWith("```")) {
                    XWPFParagraph p = doc.createParagraph();
                    XWPFRun r = p.createRun();
                    r.setFontFamily("Consolas");
                    r.setFontSize(9);
                    r.setText(lines[i]);
                    i++;
                }
                i++; // 跳过收尾的 ```
                continue;
            }
            // 表格：本行是 |...| 且下一行是分隔行 |---|---|
            if (isTableRow(trimmed) && i + 1 < lines.length && isTableSeparator(lines[i + 1].trim())) {
                int end = i + 2;
                while (end < lines.length && isTableRow(lines[end].trim())) {
                    end++;
                }
                writeTable(doc, lines, i, end);
                i = end;
                continue;
            }
            // 标题：降级为加粗段落（见方法注释）
            int hashes = countHeadingHashes(trimmed);
            if (hashes > 0) {
                XWPFParagraph p = doc.createParagraph();
                if (styleOverride != null) {
                    p.setStyle(styleOverride);
                }
                XWPFRun r = p.createRun();
                r.setBold(true);
                writeInline(r, trimmed.substring(Math.min(trimmed.length(), hashes)).trim());
                i++;
                continue;
            }
            // 列表
            if (isBullet(trimmed)) {
                XWPFParagraph p = doc.createParagraph();
                p.setIndentationLeft(360);
                XWPFRun r = p.createRun();
                r.setText("· ");
                writeInline(r, stripBullet(trimmed));
                i++;
                continue;
            }
            // 普通段落（连续非空行合并成一段，避免每行一个段落）
            StringBuilder sb = new StringBuilder();
            int j = i;
            while (j < lines.length) {
                String t = lines[j].trim();
                if (t.isEmpty() || t.startsWith("```") || isTableRow(t) || countHeadingHashes(t) > 0) {
                    break;
                }
                if (isBullet(t)) {
                    break;
                }
                if (sb.length() > 0) {
                    sb.append(' ');
                }
                sb.append(t);
                j++;
            }
            if (sb.length() == 0) {
                i++;
                continue;
            }
            XWPFParagraph p = doc.createParagraph();
            if (styleOverride != null) {
                p.setStyle(styleOverride);
            }
            XWPFRun r = p.createRun();
            writeInline(r, sb.toString());
            i = j;
        }
    }

    /** md 表格 → XWPFTable（第一行表头加粗，列数按分隔行确定） */
    private void writeTable(XWPFDocument doc, String[] lines, int start, int end) {
        List<String> rows = new ArrayList<>();
        for (int k = start; k < end; k++) {
            String t = lines[k].trim();
            if (isTableSeparator(t)) {
                continue;
            }
            rows.add(t);
        }
        if (rows.isEmpty()) {
            return;
        }
        int cols = splitRow(rows.get(0)).size();
        if (cols == 0) {
            return;
        }
        XWPFTable table = doc.createTable(rows.size(), cols);
        table.setWidth("100%");
        for (int r = 0; r < rows.size(); r++) {
            List<String> cells = splitRow(rows.get(r));
            XWPFTableRow row = table.getRow(r);
            for (int c = 0; c < cols; c++) {
                XWPFTableCell cell = row.getCell(c);
                if (cell == null) {
                    continue;
                }
                // 清掉 POI 预置的空段落，改成我们自己的
                cell.removeParagraph(0);
                XWPFParagraph p = cell.addParagraph();
                XWPFRun run = p.createRun();
                run.setFontSize(9);
                run.setBold(r == 0);
                writeInline(run, c < cells.size() ? cells.get(c) : "");
            }
        }
        // 表格后空一行，避免与下一段贴在一起
        doc.createParagraph();
    }

    /** 行内标记：只处理 `**加粗**`（其余标记原样保留，避免误删内容） */
    private void writeInline(XWPFRun target, String text) {
        if (!StringUtils.hasText(text)) {
            return;
        }
        String[] parts = text.split("\\*\\*");
        for (int i = 0; i < parts.length; i++) {
            if (parts[i].isEmpty()) {
                continue;
            }
            if (i == 0) {
                target.setText(parts[i]);
            } else {
                XWPFRun r = target.getParagraph().createRun();
                r.setBold(i % 2 == 1);
                r.setFontSize(target.getFontSize() > 0 ? target.getFontSize() : 10);
                r.setText(parts[i]);
            }
        }
    }

    /* ==================== 小工具（纯静态） ==================== */

    /** 标题字号兜底：一级 16pt / 二级 14pt / 三级 12pt（再深按 12pt 处理） */
    private static int headingFontSize(int level) {
        if (level <= 1) {
            return 16;
        }
        if (level == 2) {
            return 14;
        }
        return 12;
    }

    private static Map<String, ReportRiskItem> indexRisks(List<ReportRiskItem> risks) {
        Map<String, ReportRiskItem> map = new HashMap<>();
        if (risks != null) {
            for (ReportRiskItem item : risks) {
                if (item != null && StringUtils.hasText(item.getBlockCode())) {
                    map.put(item.getBlockCode(), item);
                }
            }
        }
        return map;
    }

    private static boolean isTableRow(String trimmed) {
        return trimmed.startsWith("|") && trimmed.length() > 1;
    }

    /** 分隔行：| --- | :---: | 等（只含 | - : 空格） */
    private static boolean isTableSeparator(String trimmed) {
        if (!isTableRow(trimmed)) {
            return false;
        }
        for (char c : trimmed.toCharArray()) {
            if (c != '|' && c != '-' && c != ':' && c != ' ') {
                return false;
            }
        }
        return trimmed.indexOf('-') >= 0;
    }

    /** 拆一行表格为单元格（去掉首尾竖线，保留内容原样） */
    private static List<String> splitRow(String trimmed) {
        List<String> cells = new ArrayList<>();
        String body = trimmed;
        if (body.startsWith("|")) {
            body = body.substring(1);
        }
        if (body.endsWith("|")) {
            body = body.substring(0, body.length() - 1);
        }
        for (String cell : body.split("\\|", -1)) {
            cells.add(cell.trim());
        }
        return cells;
    }

    private static int countHeadingHashes(String trimmed) {
        int n = 0;
        while (n < trimmed.length() && trimmed.charAt(n) == '#') {
            n++;
        }
        if (n >= 1 && n <= 6 && n < trimmed.length() && trimmed.charAt(n) == ' ') {
            return n;
        }
        return 0;
    }

    private static boolean isBullet(String trimmed) {
        return trimmed.startsWith("- ") || trimmed.startsWith("* ") || trimmed.startsWith("+ ");
    }

    private static String stripBullet(String trimmed) {
        return trimmed.substring(2).trim();
    }
}
