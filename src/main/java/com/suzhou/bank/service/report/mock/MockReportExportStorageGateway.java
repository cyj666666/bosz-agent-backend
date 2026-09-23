package com.suzhou.bank.service.report.mock;

import com.suzhou.bank.service.report.gateway.ReportExportStorageGateway;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 「导出文件落对象存储」的 <b>MOCK 实现（外网专用）</b>
 *
 * <p>行内的**内容平台**（类 S3 对象存储）外网没有 ⇒ 外网只把"本应存上去的文件"打进日志，
 * 便于在外网就把对象键、文件名、大小这些装配清楚。</p>
 *
 * <p>⛔ <b>行内不要这个类</b>：行内应存在
 * {@code com.suzhou.bank.service.report.gateway.ContentPlatformExportStorage}。
 * 本类与 {@code MockAfterLoanRiskApplyGateway}、{@code ReportShareUrlMockService} 同在
 * {@code service/report/mock/} 包下，往行内同步时**整个包跳过**。</p>
 *
 * <p>⚠️ <b>刻意返回 {@code stored=false}</b>：外网跑出来的导出结果里，那次上传**并没有真的发生**。
 * 返回 true 会让人以为"文件已经在内容平台上了"，排查时得出错误结论。</p>
 *
 * @author 曹陆宇
 * @since 1.4.0
 */
@Slf4j
@Service
public class MockReportExportStorageGateway implements ReportExportStorageGateway {

    private static final String MOCK_TIP = "外网无内容平台（对象存储）对接，导出文件未上传（MOCK）";

    @Override
    public StoreResult store(ExportFile file) {
        if (file == null) {
            return StoreResult.notStored(MOCK_TIP);
        }
        log.warn("【外网 MOCK】导出文件未上传：fileName={} size={}B objectKey={} reportNo={} 操作人={} 说明={}",
                file.getFileName(),
                file.getContent() == null ? 0 : file.getContent().length,
                file.suggestObjectKey(),
                file.getReportNo(),
                file.getOperatorNo(),
                MOCK_TIP);
        return StoreResult.notStored(MOCK_TIP);
    }
}
