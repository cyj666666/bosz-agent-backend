package com.suzhou.bank.service.report.gateway;

import lombok.Data;

import java.util.List;

/**
 * 预警信号推送入参（本工程内部命令对象）
 *
 * <p>它**不是**信贷侧的报文体，而是"我方要说的事"的中立描述。真正的报文组装
 * （{@code AflAddRiskApplyRequest} 之类）由各环境的 {@link AfterLoanRiskApplyGateway} 实现负责 ——
 * 外网没有信贷依赖包，自然也不该认识那些 DTO。</p>
 *
 * <p>字段来源（2026-09-23 客户给定的契约）：</p>
 * <ul>
 *   <li>{@code checkTaskNo} → 信贷侧 {@code serialNo}（业务流水号）= {@code report.check_task_no}；</li>
 *   <li>{@code workid} → 信贷侧 {@code workid}（审批任务编号）= 详情页 {@code /api/credit/resolve}
 *       返回的 params 里的 {@code workid}；</li>
 *   <li>{@code signals} → 信贷侧 {@code warningSignals} 数组。<b>当前每次只推 1 条</b>
 *       （点一条预警信号采纳就推一条，暂不支持批量），字段仍是列表形态以便将来扩展。</li>
 * </ul>
 *
 * @author 曹陆宇
 * @since 1.4.0
 */
@Data
public class RiskApplyPushCommand {

    /** 报告编号（我方追溯用，信贷报文里不一定有） */
    private String reportNo;

    /** 日检任务编号 → 信贷 {@code serialNo}（业务流水号） */
    private String checkTaskNo;

    /** 审批任务编号 → 信贷 {@code workid}（来自详情页 /api/credit/resolve 的 params） */
    private String workid;

    /** 客户编号 */
    private String customerId;

    /** 客户名称 */
    private String customerName;

    /**
     * 操作人账号（本次点"采纳"的那个人）
     *
     * <p>行内实现拿它当上游调用的 {@code userId} 传给
     * {@code crcsAfterLoanAiService.newRiskApplyN(req, userId)} —— 上游会用它记调用流水。
     * 外网 MOCK 不用它，但要照打日志（排查时能看出"是谁触发的推送"）。</p>
     */
    private String operatorNo;

    /** 本次要推送的预警信号（单条采纳 = 1 个元素） */
    private List<Signal> signals;

    /**
     * 单条预警信号
     *
     * <p>字段命名与信贷侧 {@code warningSignals} 元素一一对应，取值口径见各自注释。</p>
     */
    @Data
    public static class Signal {

        /** 信号来源固定值：3-AI预警（信贷口径：1-人工预警 / 2-系统预警 / 3-AI预警） */
        public static final String TRIGGER_MODE_AI = "3";

        /** 信号来源，本系统产生的**固定为** {@link #TRIGGER_MODE_AI} */
        private String triggerMode;

        /** 信号等级（**信贷码值**）：4-黄色预警 / 5-橙色预警 / 6-红色预警 */
        private String warningLevel;

        /** 信号内容 ← 我方 {@code app_report_warning_advice.signalDesc} */
        private String riskMessage;

        /** 预警信号排查描述 ← 我方 {@code app_report_warning_advice.riskDesc} */
        private String signInvestigation;

        /**
         * 我方预警等级 → <b>信贷侧码值</b>
         *
         * <p>🔴 两套码值**不是同一套**，必须映射（客户 2026-09-23 明确要求）：</p>
         * <pre>
         *   我方（app_report_warning_advice.warningLevel）   信贷（warningLevel）
         *   RED    红色                                      6
         *   ORANGE 橙色                                      5
         *   YELLOW 黄色                                      4
         * </pre>
         *
         * @param ourLevel 我方等级（RED / ORANGE / YELLOW，大小写不敏感、容忍首尾空白）
         * @return 信贷码值字符串；**无法识别时返回 null**（调用方据此跳过该条并告警，
         *         而不是猜一个等级发出去 —— 发错预警等级比不发更糟）
         */
        public static String toCreditWarningLevel(String ourLevel) {
            if (ourLevel == null) {
                return null;
            }
            switch (ourLevel.trim().toUpperCase()) {
                case "RED":
                    return "6";
                case "ORANGE":
                    return "5";
                case "YELLOW":
                    return "4";
                default:
                    return null;
            }
        }

        /** 按「信贷码值」口径构造一条信号（等级映射见 {@link #toCreditWarningLevel}） */
        public static Signal of(String ourLevel, String riskMessage, String signInvestigation) {
            Signal signal = new Signal();
            signal.setTriggerMode(TRIGGER_MODE_AI);
            signal.setWarningLevel(toCreditWarningLevel(ourLevel));
            signal.setRiskMessage(riskMessage);
            signal.setSignInvestigation(signInvestigation);
            return signal;
        }
    }
}
