package com.suzhou.bank.service.report.mock;

import com.suzhou.bank.service.report.gateway.AfterLoanRiskApplyGateway;
import com.suzhou.bank.service.report.gateway.RiskApplyPushCommand;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 「预警信号推送信贷」的 <b>MOCK 实现（外网专用）</b>
 *
 * <p>🔴 <b>外网没有信贷（CRCS）依赖包</b> —— 真正的推送能力是行内独有的
 * （{@code CrcsAfterLoanAiService#newRiskApplyN}）。本类只把"本应发出去的报文"
 * 完整打进日志，便于在外网就把**报文组装逻辑**验证清楚（等级映射、字段来源对不对）。</p>
 *
 * <p>⛔ <b>行内不要这个类</b>：行内应存在
 * {@code com.suzhou.bank.service.report.gateway.CrcsAfterLoanRiskApplyGateway}。
 * 本类与 {@code ReportShareUrlMockService} 同在 {@code service/report/mock/} 包下，
 * 往行内同步时**整个包跳过**（见 {@code doc/往行内同步_清单_v1.md}）。</p>
 *
 * <p>⚠️ <b>刻意返回 {@code pushed=false}</b>，而不是假装成功：
 * 外网跑出来的"已采纳"里，那一次推送**并没有真的发生**。如果这里返回 true，
 * 以后排查"信贷侧到底收没收到"时会得出错误结论。</p>
 *
 * @author 曹陆宇
 * @since 1.4.0
 */
@Slf4j
@Service
public class MockAfterLoanRiskApplyGateway implements AfterLoanRiskApplyGateway {

    private static final String MOCK_TIP = "外网无信贷（CRCS）对接，预警信号未真实推送（MOCK）";

    @Override
    public PushResult pushWarningSignal(RiskApplyPushCommand command) {
        if (command == null) {
            return PushResult.notPushed(MOCK_TIP);
        }
        int count = command.getSignals() == null ? 0 : command.getSignals().size();
        log.warn("【外网 MOCK】预警信号推送被跳过：reportNo={} serialNo(checkTaskNo)={} workid={} 操作人={} 信号条数={} 说明={}",
                command.getReportNo(), command.getCheckTaskNo(), command.getWorkid(),
                command.getOperatorNo(), count, MOCK_TIP);

        // 把"本该发出去的报文"逐条打出来 —— 这是外网唯一能用来核对映射对不对的手段
        if (command.getSignals() != null) {
            for (RiskApplyPushCommand.Signal signal : command.getSignals()) {
                log.warn("【外网 MOCK】  ├─ triggerMode={} warningLevel={} riskMessage={} signInvestigation={}",
                        signal.getTriggerMode(), signal.getWarningLevel(),
                        signal.getRiskMessage(), signal.getSignInvestigation());
            }
        }
        return PushResult.notPushed(MOCK_TIP);
    }
}
