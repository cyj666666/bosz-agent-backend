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
import org.apache.poi.xwpf.usermodel.LineSpacingRule;
import org.apache.poi.xwpf.usermodel.ParagraphAlignment;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.apache.poi.xwpf.usermodel.XWPFRun;
import org.apache.poi.xwpf.usermodel.XWPFStyle;
import org.apache.poi.xwpf.usermodel.XWPFStyles;
import org.apache.poi.xwpf.usermodel.XWPFTable;
import org.apache.poi.xwpf.usermodel.XWPFTableCell;
import org.apache.poi.xwpf.usermodel.XWPFTableRow;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTDecimalNumber;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTFonts;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTPPr;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTRPr;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTStyle;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.STStyleType;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 报告 Word 导出（真 .docx，POI/XWPF 生成）—— 2026-09-23 测试反馈 #8
 *
 * <p><b>为什么后端生成</b>：原实现是前端拼 HTML 塞 {@code Blob('application/msword')} 的伪 doc，
 * 保不住目录与多级标题层级，而客户要求"目录正常、各个层级标题正常"。</p>
 *
 * <p><b>2026-09-23 第二轮修订（客户实测 4 条反馈）</b>：</p>
 * <ol>
 *   <li>🔴 <b>正文里的 {@code <p>} 字面量</b> —— 根因：内容块 {@code content} 是
 *       <b>markdown 与 HTML 两种形态混存</b>（前端就地编辑保存的是 innerHTML；
 *       前端的 {@code mdToHtml} 专门有 {@code looksLikeHtml(src) return src} 分支照顾它）。
 *       本类现按**同一套判据**（见 {@link #looksLikeHtml}）分流：HTML 先归一成 markdown
 *       （{@link #htmlToMarkdownLike}）再统一渲染 ⇒ 标签不再泄漏成文字。</li>
 *   <li><b>目录：正文顶部不放目录段落，也不插 TOC 域</b>（TOC 域打开时是空的、要按 F9，
 *       客户明确否掉）。目录交给 <b>Word 左侧「导航窗格」</b>（视图 → 导航窗格 / {@code Ctrl+F}），
 *       它的**唯一依据是标题的「大纲级别」** ⇒ 见 {@link #applyOutlineLevel}。</li>
 *   <li><b>排版规范化</b> —— 正文首行缩进 2 字符、1.5 倍行距、段后 6pt、表格字号与前后间距、
 *       中文字体显式指定（正文宋体 / 标题黑体）。</li>
 *   <li><b>溯源表格不导出</b> —— 判据是 {@code analysisType=TRACE_TABLE}（页面上它不是表格内容，
 *       而是一个"溯源入口"按钮，点开才弹窗）。
 *       ⚠️ <b>不要拿 {@code fillType=TABLE} 当判据</b> —— 那是**普通数据表格**，
 *       客户明确要求导出（2026-09-23 曾因这个误判把数据表格整类跳掉，端到端探针才抓出来）。</li>
 * </ol>
 *
 * <p><b>导出规则汇总</b>：只写正文；跳过 ① 溯源表格 ② 溯源链接块（SOURCE_LINK，交互按钮）
 * ③ 已标记 INVALID 的风险块 ④ 空内容且 {@code emptyStrategy=HIDE} 的块。</p>
 *
 * <p>🔴 <b>导航窗格无法由文档强制打开</b>（2026-09-23 查证，微软官方定论）：显示状态属
 * Word **客户端**设置、不随文档走；唯一强制手段是 VBA 宏，而收件人必须允许宏运行 ⇒ 不采用。
 * ✅ 但它是<b>"粘性"</b>的：用户按一次 {@code Ctrl+F} 后，其后打开任何文档都会自动带
 * ⇒ 以**操作说明**交付即可，文档里不塞提示文字（客户明确不要）。</p>
 * <p>🔴 <b>{@code new XWPFDocument()} 生成的包不含 {@code styles.xml}</b> ⇒ 必须先用
 * {@link #ensureStyles} 补样式表，否则 {@code setStyle("HeadingN")} 全是**悬空引用**
 * （详见 {@link #ensureStyles} 的注释）。</p>
 *
 * <p>⚠️ 扩展名是 {@code .docx}（POI 产出 OOXML）：写成 {@code .doc} 会触发 Word「格式与扩展名不符」告警。</p>
 * <p>⚠️ 不引第三方 markdown/HTML 库：本工程构建走离线（{@code mvn -o}）拉不到新包 ⇒
 * 用受控的轻量解析（内容形态是可控的：段落/表格/列表/少量行内标记）。</p>
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
     * <p>🔴 与 {@code AfterLoanRiskApplyGateway} 同一套接缝：本类只认接口、两版代码逐字相同。
     * **best-effort** —— 存不上去不影响用户下载。</p>
     */
    private final ReportExportStorageGateway exportStorageGateway;

    /* ==================== 版式参数（要调外观改这里） ==================== */

    /** 正文字体（中文用 eastAsia 显式指定，否则 Word 可能回退成别的字体） */
    private static final String FONT_BODY = "宋体";
    /** 标题字体 */
    private static final String FONT_HEADING = "黑体";
    /** 正文字号（pt）：小四 */
    private static final int SIZE_BODY = 12;
    /** 表格字号（pt） */
    private static final int SIZE_TABLE = 10;
    private static final int SIZE_H1 = 16;
    private static final int SIZE_H2 = 14;
    private static final int SIZE_H3 = 12;
    private static final int SIZE_DOC_TITLE = 20;
    /**
     * 文档大标题 —— **固定文案**
     *
     * <p>🔴 2026-09-24 客户定稿：**不再取 {@code reportInfo.reportTitle}**
     * （那个值是"对公客户日常定期检查报告"），统一写成「对公客户日常贷后检查报告」，
     * 与导出文件名的口径（{@code {公司名称}-日常贷后检查报告-yyyyMMdd.docx}）保持一致。</p>
     */
    private static final String DOC_TITLE = "对公客户日常贷后检查报告";
    /** 正文段后间距（twips，120 = 6pt） */
    private static final int SPACE_AFTER_BODY = 120;
    /** 标题段前/段后（twips） */
    private static final int SPACE_BEFORE_HEADING = 240;
    private static final int SPACE_AFTER_HEADING = 120;
    /** 首行缩进 2 字符：2 × 12pt × 20 twips/pt = 480 */
    private static final int INDENT_FIRST_LINE = 480;
    /** 行距倍数 */
    private static final double LINE_SPACING = 1.5;

    /**
     * "这段内容是不是 HTML" 的判据
     *
     * <p>🔴 与前端 {@code useReportInstance.ts#looksLikeHtml} 的**正则逐字对应**，
     * 改一处必须对看 —— 两边判据不一致会出现"页面看着对、导出却带标签"的裂缝。</p>
     */
    private static final Pattern HTML_LIKE = Pattern.compile(
            "<(p|div|ol|ul|li|table|thead|tbody|tr|td|th|h[1-6]|br|strong|em|span)\\b[^>]*>",
            Pattern.CASE_INSENSITIVE);

    /** 任意 HTML 标签 */
    private static final Pattern ANY_TAG = Pattern.compile("<[^>]+>");

    /* ==================== 导出结果 ==================== */

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

    /* ==================== 入口 ==================== */

    /**
     * 生成 .docx
     *
     * @param reportNo   报告编号
     * @param operatorNo 操作人账号（同步对象存储时记录"谁导出的"）
     */
    public ExportResult export(String reportNo, String operatorNo) {
        if (!StringUtils.hasText(reportNo)) {
            throw new IllegalStateException("缺少报告编号（reportNo），无法导出");
        }
        ReportDetailVO detail;
        try {
            detail = reportService.detail(reportNo);
        } catch (RuntimeException e) {
            throw new IllegalStateException("读取报告详情失败：" + e.getMessage(), e);
        }
        if (detail == null) {
            throw new IllegalStateException("报告不存在或尚未生成完成：" + reportNo);
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        // try-with-resources：XWPFDocument 关闭时会把内容写进 out
        try (XWPFDocument doc = new XWPFDocument()) {
            // 🔴 必须先补样式表：POI 空模板不含 styles.xml（见 ensureStyles），
            //    否则后面 setStyle("HeadingN") 全是悬空引用
            ensureStyles(doc);
            writeDocumentTitle(doc, detail);
            // 🔴 2026-09-23 第三轮：**不再写正文顶部的静态目录**（客户明确要求删）。
            //    目录改由 Word **左侧导航窗格**提供 —— 靠标题的大纲级别，见 applyOutlineLevel。
            writeBody(doc, detail);
            doc.write(out);
        } catch (Exception e) {
            log.error("导出 Word 失败：reportNo={} 原因={}", reportNo, e.getMessage(), e);
            throw new IllegalStateException("导出 Word 失败：" + e.getMessage(), e);
        }

        byte[] bytes = out.toByteArray();
        String fileName = buildFileName(detail);
        storeToObjectStorage(fileName, bytes, detail, operatorNo);
        return new ExportResult(bytes, fileName);
    }

    /**
     * 文件名：{@code {公司名称}-日常贷后检查报告-yyyyMMdd.docx}
     *
     * <p>用**导出当天**日期；公司名称里的文件名非法字符（{@code \ / : * ? " < > |} 与空白）
     * 一律替换成下划线，否则浏览器会丢文件名或截断。</p>
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

    /**
     * 报告头：**大标题**（居中加粗）+ **一行**元信息（客户名称 / 报告编号 / 日检流水号）
     *
     * <p>🔴 2026-09-24 客户定稿（原版面被评"看着相当奇怪"）：</p>
     * <ol>
     *   <li>大标题固定为「{@link #DOC_TITLE}」，不再取 {@code reportTitle}；</li>
     *   <li>元信息三项**放进同一个段落**（整段居中）—— 超过行宽时由 Word 自动折行，
     *       折行后每行仍居中（客户原话："放一行…换行居中吧，注意版面"）；</li>
     *   <li>与标题 / 正文之间留出间距，避免贴着正文。</li>
     * </ol>
     * <p>⚠️ 模板里的「报告头」三块（{@code BLK_HEAD_01/02/03}）与这里**内容重合**，
     * 已在 {@link #writeBody} 里跳过，否则首页会重复出现"客户名称 + 日常贷后检查报告"两行。</p>
     */
    private void writeDocumentTitle(XWPFDocument doc, ReportDetailVO detail) {
        XWPFParagraph p = doc.createParagraph();
        p.setAlignment(ParagraphAlignment.CENTER);
        p.setSpacingAfter(120);
        XWPFRun r = p.createRun();
        r.setText(DOC_TITLE);
        applyFont(r, FONT_HEADING, SIZE_DOC_TITLE);
        r.setBold(true);

        // 客户名称 / 报告编号 / 日检流水号 —— 三项**同一段、整段居中**（超宽自动折行且仍居中）
        StringBuilder meta = new StringBuilder();
        if (StringUtils.hasText(detail.getCustomerName())) {
            meta.append("客户名称：").append(detail.getCustomerName());
        }
        if (StringUtils.hasText(detail.getReportNo())) {
            if (meta.length() > 0) {
                meta.append("　　");
            }
            meta.append("报告编号：").append(detail.getReportNo());
        }
        if (StringUtils.hasText(detail.getCheckTaskNo())) {
            if (meta.length() > 0) {
                meta.append("　　");
            }
            meta.append("日检流水号：").append(detail.getCheckTaskNo());
        }
        if (meta.length() > 0) {
            XWPFParagraph mp = doc.createParagraph();
            mp.setAlignment(ParagraphAlignment.CENTER);
            mp.setSpacingBefore(120);
            mp.setSpacingAfter(240);
            XWPFRun mr = mp.createRun();
            mr.setText(meta.toString());
            applyFont(mr, FONT_BODY, 10);
        }
    }

    /** 正文：报告级块 → 目录树（标题 + 本节点块 + 子节点） */
    private void writeBody(XWPFDocument doc, ReportDetailVO detail) {
        Map<String, ReportRiskItem> riskByBlock = indexRisks(detail.getRisks());

        // 🔴 报告级块（catalogCode 为空）= 页面的「报告头」：报告主标题（=客户名称）/
        //    报告副标题（="日常贷后检查报告"）/ 报告说明 ⇒ 内容与 Word 文档头**完全重合**，
        //    2026-09-24 客户要求不再导出（否则首页会重复出现"客户名称 + 日常贷后检查报告"两行）。
        // ⚠️ headBlocks 里**还混着另一种**：catalogCode 有值、但目录已停用而落到这里的兜底块
        //    （见 ReportServiceImpl#detail 的注释）—— 那些是真实正文，**必须保留**，故按 catalogCode 判。
        if (!CollectionUtils.isEmpty(detail.getHeadBlocks())) {
            for (ReportBlockVO block : detail.getHeadBlocks()) {
                if (!StringUtils.hasText(block.getCatalogCode())) {
                    continue;
                }
                writeBlock(doc, block, riskByBlock);
            }
        }
        if (CollectionUtils.isEmpty(detail.getCatalogs())) {
            return;
        }
        for (ReportCatalogNode node : detail.getCatalogs()) {
            writeCatalog(doc, node, riskByBlock);
        }
    }

    /** 递归写目录节点：标题（HeadingN 样式 + 大纲级别）+ 本节点块 + 子节点 */
    private void writeCatalog(XWPFDocument doc, ReportCatalogNode node, Map<String, ReportRiskItem> riskByBlock) {
        if (node == null) {
            return;
        }
        int level = node.getCatalogLevel() == null ? 1 : node.getCatalogLevel();
        int headingLevel = Math.max(1, Math.min(9, level));
        if (StringUtils.hasText(node.getCatalogName())) {
            XWPFParagraph h = doc.createParagraph();
            // ① 套 Word 内置标题样式（负责字体/字号/加粗这些"外观"）
            h.setStyle("Heading" + headingLevel);
            // ①.5 🔴 显式写「大纲级别」—— Word **左侧导航窗格**唯一认的就是它（见 applyOutlineLevel）
            applyOutlineLevel(h, headingLevel);
            h.setSpacingBefore(SPACE_BEFORE_HEADING);
            h.setSpacingAfter(SPACE_AFTER_HEADING);
            // ② 标题文本（不再插书签 —— 静态目录已删，没人再引用它；
            //    导航窗格靠的是上一层的大纲级别，与书签无关）
            XWPFRun hr = h.createRun();
            hr.setText(node.getCatalogName());
            applyFont(hr, FONT_HEADING, headingFontSize(headingLevel));
            hr.setBold(true);
        }
        if (!CollectionUtils.isEmpty(node.getBlocks())) {
            for (ReportBlockVO block : node.getBlocks()) {
                writeBlock(doc, block, riskByBlock);
            }
        }
        if (!CollectionUtils.isEmpty(node.getChildren())) {
            for (ReportCatalogNode child : node.getChildren()) {
                writeCatalog(doc, child, riskByBlock);
            }
        }
    }

    /**
     * 补齐文档样式表：{@code Normal} + {@code Heading1~9}
     *
     * <p>🔴 <b>为什么必须自己写</b>（2026-09-23 拆包实测发现）：POI 的 {@code new XWPFDocument()}
     * 生成的是**极简 OOXML 包，不带 styles.xml**（保存时只写 {@code document.xml} + {@code settings.xml}）。
     * 于是 {@code setStyle("Heading1")} 写出去的 {@code w:pStyle w:val="Heading1"} 是
     * <b>悬空引用</b> —— 文档里压根没有这个样式定义。后果：
     * ① Word「样式」窗格 / 大纲视图里看不到标题样式；② 用户以后自己插目录域抓不到标题。</p>
     *
     * <p>外观本来就由直接格式（{@link #applyFont}）兜着，所以补样式不是"为了好看"，
     * 而是**让文档规范**：样式真的存在，Word 的样式库、大纲视图、导航窗格才都正常。</p>
     *
     * <p>🔴 顺带把 {@code outlineLvl} 也写进样式定义 —— 段落上那份见 {@link #applyOutlineLevel}，
     * 两条腿都站住（样式被替换了段落还在，段落漏了样式还在）。</p>
     *
     * <p>⚠️ best-effort：补样式失败只记 WARN，**不中断导出**（外观有直接格式兜底）。</p>
     */
    private static void ensureStyles(XWPFDocument doc) {
        try {
            XWPFStyles styles = doc.createStyles();

            // 正文默认样式（宋体小四）——让 Word 的"默认字体"与导出内容一致
            CTStyle normal = CTStyle.Factory.newInstance();
            normal.setType(STStyleType.PARAGRAPH);
            normal.setStyleId("Normal");
            normal.addNewName().setVal("Normal");
            applyStyleFont(normal.addNewRPr(), FONT_BODY, SIZE_BODY, false);
            styles.addStyle(new XWPFStyle(normal));

            for (int level = 1; level <= 9; level++) {
                CTStyle ct = CTStyle.Factory.newInstance();
                ct.setType(STStyleType.PARAGRAPH);
                ct.setStyleId("Heading" + level);
                // Word 中文版会把 name 本地化显示成"标题 N"，这里给标准英文名即可
                ct.addNewName().setVal("heading " + level);
                ct.addNewBasedOn().setVal("Normal");
                ct.addNewNext().setVal("Normal");
                // qFormat：让该样式在 Word 的"样式库"里冒头（空元素即 true）
                ct.addNewQFormat();
                // 大纲级别：导航窗格 / 目录域的依据（⚠️ 0 起算）
                ct.addNewPPr().addNewOutlineLvl().setVal(BigInteger.valueOf(level - 1));
                applyStyleFont(ct.addNewRPr(), FONT_HEADING, headingFontSize(level), true);
                styles.addStyle(new XWPFStyle(ct));
            }
        } catch (Exception e) {
            log.warn("补齐 Word 样式表失败（不影响导出，外观由直接格式兜底）：{}", e.getMessage());
        }
    }

    /** 给样式定义写字体（与 {@link #applyFont} 同一套参数，避免样式与直接格式打架） */
    private static void applyStyleFont(CTRPr rPr, String font, int size, boolean bold) {
        CTFonts fonts = rPr.addNewRFonts();
        fonts.setAscii(font);
        fonts.setHAnsi(font);
        fonts.setEastAsia(font);
        if (bold) {
            rPr.addNewB().setVal(true);
        }
        // 字号单位是"半磅"：12pt ⇒ 24
        rPr.addNewSz().setVal(BigInteger.valueOf(size * 2L));
    }

    /**
     * 给标题段落显式写「大纲级别」（{@code w:pPr/w:outlineLvl}）—— Word **左侧导航窗格**的依据
     *
     * <p>🔴 <b>为什么要单独写</b>（2026-09-23 客户第二轮反馈：要"左侧目录"）：</p>
     * <p>Word 导航窗格（视图 → 导航窗格，或 {@code Ctrl+F}）**只列出大纲级别为 1~9 的段落**
     * —— 它不认 {@code HeadingN} 这个名字，只认这个数值属性。内置标题样式通常
     * "硬编码"了大纲级别，但那**是样式模板给的**：样式一旦被替换、重命名或被 Word
     * 判为未知样式，导航窗格立刻变空（连标题外观都会一起丢）。</p>
     * <p>⇒ 直接写进**段落**是最硬的保证：文档在，层级就在，与样式是否被识别无关。</p>
     *
     * <p>⚠️ 值**从 0 起算**：1 级标题 ⇒ {@code outlineLvl=0}，2 级 ⇒ {@code 1}，最大 {@code 8}。</p>
     *
     * @param p            标题段落
     * @param headingLevel 1 起的标题层级（与本类 {@code HeadingN} 的 N 同一个值）
     */
    private static void applyOutlineLevel(XWPFParagraph p, int headingLevel) {
        CTPPr pPr = p.getCTP().getPPr();
        if (pPr == null) {
            pPr = p.getCTP().addNewPPr();
        }
        CTDecimalNumber lvl = pPr.getOutlineLvl();
        if (lvl == null) {
            lvl = pPr.addNewOutlineLvl();
        }
        lvl.setVal(BigInteger.valueOf(Math.max(0, Math.min(8, headingLevel - 1))));
    }

    /**
     * 写一个内容块
     *
     * <p>跳过规则：① 溯源表格（客户明确不要）② 溯源链接块 ③ 已标记 INVALID 的风险块
     * ④ 空内容且策略为 HIDE 的块。</p>
     */
    private void writeBlock(XWPFDocument doc, ReportBlockVO block, Map<String, ReportRiskItem> riskByBlock) {
        if (block == null) {
            return;
        }
        // ① 溯源表格：页面上是"溯源入口"按钮，不是正文表格 ⇒ 不导出
        //    🔴 判据**只看 analysisType=TRACE_TABLE**（溯源表格的 fillType 恰好也是 TABLE）。
        //    ⛔ 绝不能把 fillType=TABLE 也当判据 —— 那是**普通数据表格**：
        //    `AnalysisMaterialBuilder` 明确把 TABLE 块当正常材料纳入分析、`AgentReportContentProvider`
        //    也判它 analysable ⇒ 跳掉它等于直接违反客户"导出要含数据表格"。
        //    （2026-09-23 实锤：本轮就是这么误伤的，端到端探针跑出 TABLE_COUNT=0 才发现。）
        if (ReportConstants.ANALYSIS_TRACE_TABLE.equalsIgnoreCase(block.getAnalysisType())) {
            return;
        }
        // ② 溯源链接（SOURCE_LINK）：交互按钮
        if (ReportConstants.FILL_SOURCE_LINK.equalsIgnoreCase(block.getFillType())) {
            return;
        }
        // ③ 已标记无效的风险块：整块不出现
        ReportRiskItem risk = riskByBlock.get(block.getBlockCode());
        if (risk != null && ReportConstants.RISK_INVALID.equalsIgnoreCase(risk.getStatus())) {
            return;
        }
        String content = block.getContent();
        boolean blank = !StringUtils.hasText(content);
        // ④ 空内容 + HIDE：页面上本来就看不见
        if (blank && ReportConstants.EMPTY_HIDE.equalsIgnoreCase(block.getEmptyStrategy())) {
            return;
        }
        if (blank) {
            // PLACEHOLDER：页面显示"暂无数据"，导出保持同一口径
            XWPFParagraph p = doc.createParagraph();
            XWPFRun r = p.createRun();
            r.setText("暂无数据");
            applyFont(r, FONT_BODY, SIZE_BODY);
            r.setItalic(true);
            return;
        }
        writeRichText(doc, content);
    }

    /* ==================== 内容渲染（HTML / markdown 双形态） ==================== */

    /**
     * 渲染一段内容：**先判形态、再归一、最后统一按 markdown 写**
     *
     * <p>这条链路是修"导出里出现 {@code <p>} 字面量"的关键 —— 不能再假定内容一定是 markdown。</p>
     */
    private void writeRichText(XWPFDocument doc, String content) {
        String normalized = looksLikeHtml(content) ? htmlToMarkdownLike(content) : content;
        writeMarkdown(doc, normalized);
    }

    /** 与前端 `looksLikeHtml` 同款判据（见 {@link #HTML_LIKE}） */
    static boolean looksLikeHtml(String text) {
        return StringUtils.hasText(text) && HTML_LIKE.matcher(text).find();
    }

    /**
     * HTML 片段 → markdown-ish 纯文本
     *
     * <p>只做**受控转换**（内容形态是可控的），目标是"不留标签、结构不丢"：</p>
     * <ul>
     *   <li>{@code <p>}/{@code <div>}/{@code </...>} 等块级 → 段落分隔（双换行）</li>
     *   <li>{@code <br>} → 单换行</li>
     *   <li>{@code <strong>}/{@code <b>} → {@code **加粗**}；{@code <em>}/{@code <i>} → 去掉（不加斜体，中文斜体观感差）</li>
     *   <li>{@code <li>} → {@code - }；{@code <ul>}/{@code <ol>} → 段落分隔</li>
     *   <li>{@code <tr>}/{@code <td>}/{@code <th>} → 竖线表格（与 md 表格同构，下游同一套渲染）</li>
     *   <li>其余标签一律剥离；常见实体做还原</li>
     * </ul>
     */
    static String htmlToMarkdownLike(String html) {
        if (!StringUtils.hasText(html)) {
            return "";
        }
        String s = html;
        // 1) 换行与块级边界
        s = s.replaceAll("(?i)<br\\s*/?>", "\n");
        s = s.replaceAll("(?i)</(p|div|h[1-6]|ul|ol|table|thead|tbody)\\s*>", "\n\n");
        s = s.replaceAll("(?i)<(p|div|h[1-6]|ul|ol|table|thead|tbody)\\b[^>]*>", "");
        // 2) 行内标记
        s = s.replaceAll("(?i)</?(strong|b)\\b[^>]*>", "**");
        s = s.replaceAll("(?i)</?(em|i)\\b[^>]*>", "");
        // 3) 列表项
        s = s.replaceAll("(?i)<li\\b[^>]*>", "\n- ");
        s = s.replaceAll("(?i)</li\\s*>", "\n");
        // 4) 表格：行边界先换行，单元格之间补竖线，与 md 表格同构
        s = s.replaceAll("(?i)</?(tr)\\b[^>]*>", "\n");
        s = s.replaceAll("(?i)</(td|th)\\s*>", " | ");
        s = s.replaceAll("(?i)<(td|th)\\b[^>]*>", "| ");
        // 5) 其余标签全部剥离（含 img / a / span 等 —— 正文里不需要）
        s = ANY_TAG.matcher(s).replaceAll("");
        // 6) 实体还原
        s = s.replace("&nbsp;", " ").replace("&lt;", "<").replace("&gt;", ">")
                .replace("&quot;", "\"").replace("&#39;", "'").replace("&apos;", "'")
                .replace("&amp;", "&");
        // 7) 压掉多余空行（3 个以上换行 → 2 个）
        s = s.replaceAll("\n{3,}", "\n\n");
        return s.trim();
    }

    /**
     * 轻量 markdown → docx
     *
     * <p>支持：表格（{@code |a|b|} + {@code |---|} 分隔行）、无序/有序列表、行内 {@code **加粗**}、
     * 代码围栏、普通段落；{@code #} 标题**降级为加粗段落**（正文标题由结构渲染，不并入目录层级）。</p>
     */
    private void writeMarkdown(XWPFDocument doc, String md) {
        if (!StringUtils.hasText(md)) {
            return;
        }
        String[] lines = md.replace("\r\n", "\n").replace("\r", "\n").split("\n", -1);
        int i = 0;
        while (i < lines.length) {
            String trimmed = lines[i].trim();
            if (trimmed.isEmpty()) {
                i++;
                continue;
            }
            // 代码围栏：等宽小字输出（内容里偶有 JSON 片段）
            if (trimmed.startsWith("```")) {
                i++;
                while (i < lines.length && !lines[i].trim().startsWith("```")) {
                    XWPFParagraph p = doc.createParagraph();
                    p.setIndentationLeft(240);
                    p.setSpacingAfter(0);
                    XWPFRun r = p.createRun();
                    r.setFontFamily("Consolas");
                    r.setFontSize(9);
                    r.setText(lines[i]);
                    i++;
                }
                i++;
                continue;
            }
            // 表格：本行是 |...| 且下一行是分隔行
            if (isTableRow(trimmed) && i + 1 < lines.length && isTableSeparator(lines[i + 1].trim())) {
                int end = i + 2;
                while (end < lines.length && isTableRow(lines[end].trim())) {
                    end++;
                }
                writeTable(doc, lines, i, end);
                i = end;
                continue;
            }
            // 内容内的 # 标题：降级为加粗正文（不缩进，与正文区分）
            int hashes = countHeadingHashes(trimmed);
            if (hashes > 0) {
                XWPFParagraph p = doc.createParagraph();
                p.setSpacingBefore(120);
                p.setSpacingAfter(SPACE_AFTER_BODY);
                XWPFRun r = p.createRun();
                applyFont(r, FONT_HEADING, SIZE_BODY);
                r.setBold(true);
                writeInline(r, trimmed.substring(Math.min(trimmed.length(), hashes)).trim());
                i++;
                continue;
            }
            // 无序列表
            if (isBullet(trimmed)) {
                XWPFParagraph p = doc.createParagraph();
                p.setIndentationLeft(360);
                p.setSpacingAfter(60);
                p.setSpacingBetween(LINE_SPACING, LineSpacingRule.AUTO);
                XWPFRun r = p.createRun();
                applyFont(r, FONT_BODY, SIZE_BODY);
                r.setText("· ");
                writeInline(r, stripBullet(trimmed));
                i++;
                continue;
            }
            // 普通段落：连续非空行合并成一段（避免"每行一段"的碎排版）
            StringBuilder sb = new StringBuilder();
            int j = i;
            while (j < lines.length) {
                String t = lines[j].trim();
                if (t.isEmpty() || t.startsWith("```") || isTableRow(t) || countHeadingHashes(t) > 0
                        || isBullet(t)) {
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
            writeBodyParagraph(doc, sb.toString());
            i = j;
        }
    }

    /** 正文段落：首行缩进 2 字符 + 1.5 倍行距 + 段后 6pt（客户反馈的"格式不规范"就在这里） */
    private void writeBodyParagraph(XWPFDocument doc, String text) {
        XWPFParagraph p = doc.createParagraph();
        p.setIndentationFirstLine(INDENT_FIRST_LINE);
        p.setSpacingAfter(SPACE_AFTER_BODY);
        p.setSpacingBetween(LINE_SPACING, LineSpacingRule.AUTO);
        XWPFRun r = p.createRun();
        applyFont(r, FONT_BODY, SIZE_BODY);
        writeInline(r, text);
    }

    /** md 表格 → XWPFTable（表头加粗 + 浅灰底 + 细边框 + 表格前后留白） */
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
        try {
            table.setInsideHBorder(XWPFTable.XWPFBorderType.SINGLE, 4, 0, "BFBFBF");
            table.setInsideVBorder(XWPFTable.XWPFBorderType.SINGLE, 4, 0, "BFBFBF");
            table.setTopBorder(XWPFTable.XWPFBorderType.SINGLE, 4, 0, "BFBFBF");
            table.setBottomBorder(XWPFTable.XWPFBorderType.SINGLE, 4, 0, "BFBFBF");
            table.setLeftBorder(XWPFTable.XWPFBorderType.SINGLE, 4, 0, "BFBFBF");
            table.setRightBorder(XWPFTable.XWPFBorderType.SINGLE, 4, 0, "BFBFBF");
        } catch (Exception e) {
            // 边框只是观感，设不上不影响内容 —— 不让它把导出搞失败
            log.warn("设置表格边框失败（忽略）：{}", e.getMessage());
        }
        for (int r = 0; r < rows.size(); r++) {
            List<String> cells = splitRow(rows.get(r));
            XWPFTableRow row = table.getRow(r);
            for (int c = 0; c < cols; c++) {
                XWPFTableCell cell = row.getCell(c);
                if (cell == null) {
                    continue;
                }
                cell.removeParagraph(0);
                XWPFParagraph p = cell.addParagraph();
                p.setSpacingAfter(0);
                XWPFRun run = p.createRun();
                run.setFontSize(SIZE_TABLE);
                run.setFontFamily(FONT_BODY, XWPFRun.FontCharRange.eastAsia);
                run.setBold(r == 0);
                writeInline(run, c < cells.size() ? cells.get(c) : "");
            }
        }
        // 表格与后续正文之间的呼吸空间
        XWPFParagraph gap = doc.createParagraph();
        gap.setSpacingAfter(0);
    }

    /** 行内标记：只处理 {@code **加粗**}（其余标记原样保留，避免误删内容） */
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
                r.setFontSize(target.getFontSize() > 0 ? target.getFontSize() : SIZE_BODY);
                r.setFontFamily(FONT_BODY, XWPFRun.FontCharRange.eastAsia);
                r.setText(parts[i]);
            }
        }
    }

    /* ==================== 工具 ==================== */

    /** 中文字体必须显式设 eastAsia，否则 Word 可能回退成默认字体、观感不一致 */
    private static void applyFont(XWPFRun run, String font, int size) {
        run.setFontFamily(font, XWPFRun.FontCharRange.eastAsia);
        run.setFontFamily(font);
        run.setFontSize(size);
    }

    /** 标题字号：一级 16pt / 二级 14pt / 三级 12pt */
    private static int headingFontSize(int level) {
        if (level <= 1) {
            return SIZE_H1;
        }
        if (level == 2) {
            return SIZE_H2;
        }
        return SIZE_H3;
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

    /** 分隔行：{@code | --- | :---: |} 等（只含 | - : 空格） */
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

    /** 拆一行表格为单元格（去掉首尾竖线） */
    private static List<String> splitRow(String trimmed) {
        String body = trimmed;
        if (body.startsWith("|")) {
            body = body.substring(1);
        }
        if (body.endsWith("|")) {
            body = body.substring(0, body.length() - 1);
        }
        List<String> cells = new ArrayList<>();
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

    /**
     * 把导出文件同步到对象存储（行内 = 内容平台）
     *
     * <p>🔴 <b>best-effort</b>：文件已生成好，上传失败**不能让用户下载失败**；但也不能静默 ——
     * 失败打 ERROR 并带 reportNo/文件名，便于事后补传。</p>
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
                log.warn("导出文件未同步到对象存储：reportNo={} fileName={} size={}B 说明={}",
                        detail.getReportNo(), fileName, bytes.length,
                        result == null ? "网关返回 null" : result.getMessage());
            }
        } catch (Exception e) {
            log.error("导出文件同步对象存储异常（已忽略，用户下载不受影响）：reportNo={} fileName={} 原因={}",
                    detail.getReportNo(), fileName, e.getMessage(), e);
        }
    }
}
