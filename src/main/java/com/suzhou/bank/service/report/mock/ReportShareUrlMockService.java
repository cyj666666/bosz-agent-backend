package com.suzhou.bank.service.report.mock;

import com.suzhou.bank.service.report.LinkTraceParamBuilder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.net.URLEncoder;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 链接溯源「换一次性链接」的 <b>MOCK 实现（外网专用）</b>
 *
 * <p>🔴🔴 <b>背景与边界</b>：真正的换链接走信贷 SSF（`AuthApi.getPageShareUrlN`），
 * 那是**行内**才有的能力（`CreditShareUrlService`）；**外网没有 SSF**，
 * 因此外网的 `POST /api/report/share-url` 原本只会 404 ⇒ 前端点「🔗 溯源」只能看到失败 toast，**没法联调**。</p>
 *
 * <p><b>本 MOCK 做的事（不是硬编码假数据）</b>：</p>
 * <ol>
 *   <li>{@code pageParams} 走**真实的** {@link LinkTraceParamBuilder}（11 个 shareCode 策略，**真查库**）
 *       ⇒ 参数装配逻辑与行内完全一致，能在外网就验证对不对；</li>
 *   <li>返回一个指向本工程 mock 页（{@code /api/report/share-url/mock-page}）的链接，
 *       点击后新窗口会打开「模拟信贷页面」，把收到的 `shareCode` / `userId` / `reportNo` /
 *       `blockCode` / `guarantorName` / **装配好的 pageParams（已解码）** 全部回显出来，
 *       便于肉眼确认参数是否装配正确。</li>
 * </ol>
 *
 * <p>⛔ <b>行内不要这个类</b>：行内已有同路径的**真实**接口（`ReportController#shareUrl` +
 * `CreditShareUrlService`）。往行内同步时**跳过**本包（见 `doc/往行内同步_清单_v1.md`）。
 * 开关：`credit.share.mock-enabled`（默认 `false` ⇒ 接口返回明确错误而不是 404）。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ReportShareUrlMockService {

    /** 模拟信贷页面的路径（本工程内，仅外网自测用） */
    public static final String MOCK_PAGE_PATH = "/api/report/share-url/mock-page";

    private final LinkTraceParamBuilder paramBuilder;

    /**
     * 装配 pageParams（真实）并拼出「模拟信贷页面」的链接。
     *
     * @param serverBase         本服务的基址（如 `http://localhost:8080`，由调用方按请求推导）
     * @param userId             报告发起人账号（`report.user_no`）
     * @param shareCode          信贷分享编码（块的 `agentCode`）
     * @param reportNo           报告编号
     * @param blockCode          内容块编号（`1050` 征信靠它读主体令牌）
     * @param guarantorName      当前担保人名（可选）
     * @param pageParamsOverride 手工覆盖的 pageParams（可选；传了就不装配）
     * @return { url: 可直接打开的模拟链接, relativeUrl: 相对路径 }
     */
    public Map<String, String> getPageShareUrl(String serverBase, String userId, String shareCode,
                                               String reportNo, String blockCode, String guarantorName,
                                               String pageParamsOverride) {
        String pageParams = StringUtils.hasText(pageParamsOverride)
                ? pageParamsOverride.trim()
                : paramBuilder.build(shareCode, reportNo, blockCode, guarantorName);

        String relative = MOCK_PAGE_PATH + "?" + query(
                "shareCode", shareCode,
                "userId", userId,
                "reportNo", reportNo,
                "blockCode", blockCode,
                "guarantorName", guarantorName,
                "pageParams", pageParams);
        String url = StringUtils.hasText(serverBase) ? serverBase + relative : relative;

        log.info("【链接溯源·MOCK】shareCode={} userId={} reportNo={} blockCode={} guarantorName={} pageParams={}",
                shareCode, userId, reportNo, blockCode, guarantorName, pageParams);

        // 与行内保持一致的 `{url, relativeUrl}` 结构；额外给个 mock 标记，便于前端/联调一眼区分
        Map<String, String> out = new LinkedHashMap<>(3);
        out.put("url", url);
        out.put("relativeUrl", relative);
        out.put("mock", "true");
        return out;
    }

    /**
     * 模拟信贷页面的 HTML：把收到的参数全部回显（链接有效性、一次性语义都用文字说明）。
     *
     * @param q 已解析的查询参数（未传的键可能为 null）
     */
    public String mockPageHtml(Map<String, String> q) {
        StringBuilder rows = new StringBuilder();
        appendRow(rows, "分享编码 shareCode（来自块 agentCode）", q.get("shareCode"));
        appendRow(rows, "用户账号 userId（report.user_no）", q.get("userId"));
        appendRow(rows, "报告编号 reportNo", q.get("reportNo"));
        appendRow(rows, "内容块编号 blockCode", q.get("blockCode"));
        appendRow(rows, "担保人名 guarantorName（多担保人时）", q.get("guarantorName"));
        appendRow(rows, "装配出的 pageParams（原样回显）", q.get("pageParams"));
        appendRow(rows, "解码后的 pageParams（逐项）", decodeHint(q.get("pageParams")));

        return "<!DOCTYPE html><html lang=\"zh-CN\"><head><meta charset=\"UTF-8\">"
                + "<title>模拟信贷页面（外网 MOCK）</title>"
                + "<style>body{margin:0;padding:32px;font-family:-apple-system,'Microsoft YaHei',sans-serif;"
                + "background:#f5f7fb;color:#1f2937}"
                + ".card{max-width:860px;margin:0 auto;background:#fff;border:1px solid #e5e7eb;"
                + "border-radius:14px;padding:26px 30px;box-shadow:0 6px 24px rgba(15,23,42,.06)}"
                + "h2{margin:0 0 6px;font-size:20px;color:#124a91}"
                + ".tip{margin:0 0 20px;padding:10px 14px;border-radius:10px;font-size:13px;line-height:1.7;"
                + "background:#fff7ed;border:1px solid rgba(217,119,6,.32);color:#9a5b08}"
                + "table{width:100%;border-collapse:collapse;font-size:14px}"
                + "th,td{padding:10px 12px;border-bottom:1px solid #eef2f7;text-align:left;vertical-align:top}"
                + "th{width:300px;color:#475569;font-weight:600;background:#fafbfd}"
                + "code{background:#f1f5f9;padding:2px 6px;border-radius:6px;font-size:13px;"
                + "word-break:break-all;display:inline-block;max-width:100%}"
                + "</style></head><body><div class=\"card\">"
                + "<h2>模拟信贷页面 · 外网 MOCK</h2>"
                + "<p class=\"tip\">这一页是<b>外网自测用的模拟页</b>，不是真的信贷系统。它只做一件事："
                + "把「报告侧点链接溯源后送过来的参数」原样回显。<br>"
                + "真实链路 = 后端调信贷 <code>getPageShareUrlN</code> 换一次性链接（仅行内具备 SSF 能力）→ "
                + "信贷页面按 <code>pageParams</code> 定位到对应业务页；"
                + "链接<b>仅限使用一次、默认 1h 超时</b>。</p>"
                + "<table><tbody>" + rows + "</tbody></table>"
                + "</div></body></html>";
    }

    private static void appendRow(StringBuilder sb, String label, String value) {
        sb.append("<tr><th>").append(escape(label)).append("</th><td>")
                .append(StringUtils.hasText(value) ? "<code>" + escape(value) + "</code>" : "<span style=\"color:#94a3b8\">（未传）</span>")
                .append("</td></tr>");
    }

    /** 把 `a=1&b=2` 拆成多行 `a = 1`，便于核对 */
    private static String decodeHint(String pageParams) {
        if (!StringUtils.hasText(pageParams)) {
            return null;
        }
        StringBuilder sb = new StringBuilder();
        for (String seg : pageParams.split("&")) {
            if (seg.isEmpty()) {
                continue;
            }
            if (sb.length() > 0) {
                sb.append("<br>");
            }
            sb.append(escape(seg));
        }
        return sb.toString();
    }

    private static String escape(String s) {
        if (s == null) {
            return "";
        }
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    /** 拼 `k=v&k=v`（跳过空值，值做 URL 编码） */
    private static String query(String... kv) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i + 1 < kv.length; i += 2) {
            String k = kv[i];
            String v = kv[i + 1];
            if (!StringUtils.hasText(v)) {
                continue;
            }
            if (sb.length() > 0) {
                sb.append('&');
            }
            sb.append(k).append('=').append(encode(v));
        }
        return sb.toString();
    }

    private static String encode(String v) {
        try {
            return URLEncoder.encode(v, "UTF-8");
        } catch (Exception e) {
            return v;
        }
    }
}
