package com.suzhou.bank.service.report.gateway;

import lombok.Getter;

/**
 * 「预警信号推送信贷」网关 —— 两版实现互不相同的<b>唯一接缝</b>（2026-09-23 测试反馈 #7）
 *
 * <p><b>需求</b>：行内版「预警建议采纳」时，除改我方状态外，还要把这条预警信号推给信贷
 * （行内实现 = 调 {@code crcsAfterLoanAiService.newRiskApplyN}）。</p>
 *
 * <p>🔴🔴 <b>为什么要有这层接口（而不是直接在 service 里调 crcs）</b>：</p>
 * <table border="1">
 *   <tr><th>环境</th><th>可用能力</th><th>本接口的实现</th></tr>
 *   <tr><td>外网（本工程）</td><td>**没有** crcs / SSF 任何依赖包</td>
 *       <td>{@code service/report/mock/MockAfterLoanRiskApplyGateway}（外网专用，⛔ 不同步行内）</td></tr>
 *   <tr><td>行内</td><td>{@code com.suzhou.bank.upstream.crcs.CrcsAfterLoanAiService}</td>
 *       <td>{@code service/report/gateway/CrcsAfterLoanRiskApplyGateway}（行内专有，⛔ 不反向覆盖）</td></tr>
 * </table>
 * <p>业务层（{@code ReportServiceImpl}）<b>只依赖本接口</b> ⇒ 这份调用代码两版逐字相同、
 * 不需要按环境分叉，往行内同步时也不会冲突。这与既有的
 * 「{@code ReportShareUrlMockService}（外网）/ {@code CreditShareUrlService}（行内）」是同一套路子。</p>
 *
 * <p><b>调用语义（重要）</b>：</p>
 * <ol>
 *   <li><b>best-effort，绝不回滚</b>：推送失败<b>不影响</b>「已采纳」这个事实 —— 状态已落库、
 *       用户在 UI 上已经看到采纳成功。把推送失败变成"采纳失败"会让用户重复点击。</li>
 *   <li><b>必须留痕、不许静默</b>：实现里失败要打 ERROR 日志，返回值里带上原因
 *       （本工程的历史教训：取数异常被 catch 吞掉 ⇒ 与"查到 0 行"完全同形，报告里根本看不出问题）。</li>
 *   <li><b>幂等由调用方保证</b>：只在"状态从非 ADOPTED 变成 ADOPTED"时推一次，
 *       重复点采纳不会重复推（见 {@code ReportServiceImpl#updateWarningAdviceStatus}）。</li>
 * </ol>
 *
 * @author 曹陆宇
 * @since 1.4.0
 */
public interface AfterLoanRiskApplyGateway {

    /**
     * 推送预警信号到信贷
     *
     * @param command 推送命令（非空；{@code signals} 至少 1 条）
     * @return 推送结果（**不抛异常** —— 实现内部必须自行兜住所有异常）
     */
    PushResult pushWarningSignal(RiskApplyPushCommand command);

    /**
     * 推送结果
     *
     * <p>刻意保留 {@code pushed} 与 {@code message} 而不是 `void`：调用方要能区分
     * 「真的推了」「环境不具备所以没推（外网 MOCK）」「推了但失败了」，否则又是一件"静默失效"。</p>
     */
    @Getter
    class PushResult {

        /** true = 已真实推送到信贷；false = 未推送（环境不支持 MOCK / 或推送失败） */
        private final boolean pushed;

        /** 结果说明（写日志、必要时给前端提示用；成功时为简短说明） */
        private final String message;

        private PushResult(boolean pushed, String message) {
            this.pushed = pushed;
            this.message = message;
        }

        public static PushResult pushed(String message) {
            return new PushResult(true, message);
        }

        public static PushResult notPushed(String message) {
            return new PushResult(false, message);
        }
    }
}
