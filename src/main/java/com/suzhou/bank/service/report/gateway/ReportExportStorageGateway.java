package com.suzhou.bank.service.report.gateway;

import lombok.Getter;

/**
 * 「导出文件落对象存储」网关 —— 2026-09-23 客户追加需求（行内内容平台）
 *
 * <p><b>需求</b>：报告导出的 Word 文件，在**行内**除给用户下载外，还要同步到行内的
 * **内容平台**（类 S3 的对象存储）。外网没有这个平台 ⇒ 只需一个留痕的 MOCK。</p>
 *
 * <p>🔴🔴 <b>与 {@link AfterLoanRiskApplyGateway} 完全同一套接缝思路</b>：</p>
 * <table border="1">
 *   <tr><th>环境</th><th>实现</th></tr>
 *   <tr><td>外网（本工程）</td>
 *       <td>{@code service/report/mock/MockReportExportStorageGateway}（只打日志，⛔ 不同步行内）</td></tr>
 *   <tr><td>行内</td>
 *       <td>{@code service/report/gateway/ContentPlatformExportStorage}（行内专有件，⛔ 不被覆盖）
 *           —— <b>当前是留给行内开发的空实现</b>，见该类 TODO</td></tr>
 * </table>
 * <p>业务层（{@code ReportWordExportService}）只依赖本接口 ⇒ 这份调用代码两版逐字相同，
 * 往行内同步时不冲突。</p>
 *
 * <p><b>调用语义（照抄 {@link AfterLoanRiskApplyGateway} 的三条，别改）</b>：</p>
 * <ol>
 *   <li><b>best-effort，绝不影响下载</b>：上传失败不该让用户拿不到文件 ——
 *       文件已经生成好了，"存不进去"是我方运维问题，不是用户的问题；</li>
 *   <li><b>必须留痕、不许静默</b>：实现里失败要打 ERROR，返回值里带原因
 *       （本工程历史教训：取数异常被吞 ⇒ 与"查到 0 行"完全同形）；</li>
 *   <li><b>幂等由对象键保证</b>：{@link ExportFile#suggestObjectKey()} 给出的键含
 *       报告编号 + 导出的时间戳，同一次导出不会互相覆盖；重试则由平台侧按键覆盖。</li>
 * </ol>
 *
 * @author 曹陆宇
 * @since 1.4.0
 */
public interface ReportExportStorageGateway {

    /**
     * 存一份导出文件
     *
     * @param file 待存文件（非空；{@code content} 非空）
     * @return 存储结果（**不抛异常** —— 实现内部必须自行兜住所有异常）
     */
    StoreResult store(ExportFile file);

    /** 待存的对象 */
    @Getter
    class ExportFile {

        /** 建议文件名（不含路径），如 {@code 苏州XX公司-日常贷后检查报告-20260923.docx} */
        private final String fileName;

        /** 文件内容（docx 字节） */
        private final byte[] content;

        /** 报告编号（可作对象键前缀，便于按报告检索） */
        private final String reportNo;

        /** 日检流水号（可空） */
        private final String checkTaskNo;

        /** 客户名称（可空，便于人工在平台上认文件） */
        private final String customerName;

        /** 操作人账号（谁点的导出） */
        private final String operatorNo;

        /** 内容类型（固定为 docx 的 MIME） */
        private final String contentType;

        public ExportFile(String fileName, byte[] content, String reportNo, String checkTaskNo,
                          String customerName, String operatorNo, String contentType) {
            this.fileName = fileName;
            this.content = content;
            this.reportNo = reportNo;
            this.checkTaskNo = checkTaskNo;
            this.customerName = customerName;
            this.operatorNo = operatorNo;
            this.contentType = contentType;
        }

        /**
         * 建议对象键：{@code report/{reportNo}/{时间戳}-{文件名}}
         *
         * <p>行内实现可直接用它，也可按内容平台的目录规范自行改写 —— 它只是"给个不会互相覆盖的默认键"。
         * ⚠️ 文件名里可能含中文，**不要**在这里做 URL 编码（那是调用平台 SDK 时的事）。</p>
         */
        public String suggestObjectKey() {
            String prefix = (reportNo == null || reportNo.isEmpty()) ? "unknown" : reportNo;
            return "report/" + prefix + "/" + System.currentTimeMillis() + "-" + fileName;
        }
    }

    /** 存储结果 */
    @Getter
    class StoreResult {

        /** true = 已真实写入对象存储；false = 未存（环境不支持 MOCK / 或失败） */
        private final boolean stored;

        /** 结果说明（写日志用；成功时带对象键，失败时带原因） */
        private final String message;

        /** 对象键（成功时非空；行内实现按平台返回的 key / url 填） */
        private final String objectKey;

        private StoreResult(boolean stored, String message, String objectKey) {
            this.stored = stored;
            this.message = message;
            this.objectKey = objectKey;
        }

        public static StoreResult stored(String objectKey) {
            return new StoreResult(true, "已写入对象存储", objectKey);
        }

        public static StoreResult notStored(String message) {
            return new StoreResult(false, message, null);
        }
    }
}
