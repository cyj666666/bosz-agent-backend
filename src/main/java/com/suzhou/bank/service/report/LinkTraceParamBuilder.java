package com.suzhou.bank.service.report;

import com.suzhou.bank.mapper.LinkTraceQueryMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 链接溯源 pageParams 装配器（🔴 2026-09-21 曹哥口径 = 方案 B）
 *
 * <p>报告「链接溯源」块被点击时，后端按 `shareCode` **实时**从业务表取数、拼出信贷侧需要的
 * `pageParams`（形如 `serialNo=xxx&customerId=xxx`），再交给信贷侧链接服务调信贷
 * `getPageShareUrlN` 换**一次性**链接。**全程不落库** —— 链接有时效，绝不能前置加工。</p>
 *
 * <p>取值来源：`report`（customer_id / customer_name / check_task_no）、
 * `app_credit_report_info` / `app_guarantor_credit_info`（征信报告记录号）、
 * `xd_corp_check_info`（批复相关信息）。逐条口径见《链接溯源相关.xlsx》。</p>
 *
 * <p>🔴 `1050`（征信）在**三个位置复用**（借款人 / 企业担保人 / 个人担保人），**shareCode 相同**，
 * 只能靠块的 `agentParams` 主体令牌区分 ⇒ 见 {@link #buildCreditReport}。</p>
 *
 * <p>🔴 本文件在行内 / 外网 **同包同路径、逐字同源**（2026-09-21 链接溯源行内外同步）。修改时请两边一起改。</p>
 *
 * <p><b>行内外分工</b>：本类只做**参数实时装配**（不依赖 SSF，行内外完全共享）；
 * 「拿装配好的 pageParams 去换链接」那一步由信贷链接服务承担 —— 行内为 `CreditShareUrlService`
 * （依赖 SSF `AuthApi`），**外网未接入 SSF、没有该服务**，故本类的外网副本暂无调用方。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LinkTraceParamBuilder {

    // ---------------- shareCode（信贷侧登记，见《链接溯源相关.xlsx》） ----------------
    /** 批复链接（电子批复） */
    public static final String SC_APPROVE_INFO = "1010";
    /** 打卡 */
    public static final String SC_DAILY_CHECK = "1020";
    /** 批复落实 */
    public static final String SC_PUBLIC_CONDITION = "1030";
    /** 财务分析表 */
    public static final String SC_ENT_FINA = "1040";
    /** 征信（借款人 / 企业担保人 / 个人担保人 —— 三处复用） */
    public static final String SC_CREDIT_REPORT = "1050";
    /** 资金用途及回流异常排查台账 */
    public static final String SC_TROUBLE_MORTGAGE = "1060";
    /** 预警台账 */
    public static final String SC_ALERT_LEDGER = "1080";
    /** 地方征信 */
    public static final String SC_NATIONAL_DEVELOPMENT = "1090";
    /** 对公日常贷后检查 */
    public static final String SC_DAILY_PUBLIC_CHECK = "1120";
    /** 资金用途及回流异常延期整改台账 */
    public static final String SC_TROUBLE_RECTIFY = "1130";
    /** 预警信号台账 */
    public static final String SC_ALERT_SIGN_LEDGER = "1150";

    // ---------------- 主体令牌（块 agentParams 里的元令牌，与知识库块同风格） ----------------
    private static final String TOKEN_SUBJECT_TYPE = "subjectType";
    private static final String TOKEN_GUARANTOR_TYPE = "guarantorType";
    /** `subjectType` 取值（用户口径：中文，见 2026-09-21） */
    private static final String SUBJECT_BORROWER = "借款人";
    private static final String SUBJECT_GUARANTOR = "担保人";
    /** `guarantorType` 取值 */
    private static final String GUARANTOR_NATURAL = "自然人";

    // ---------------- 固定值 ----------------
    private static final String FIXED_APPLY_TYPE = "AFPublicDailyCheckApply";
    private static final String FIXED_CUSTOMER_TYPE = "01";
    private static final String FIXED_MENU_TYPE = "1";
    private static final String FIXED_FILE_TYPE = "2";
    private static final String FIXED_FALSE = "false";

    private final LinkTraceQueryMapper queryMapper;

    /**
     * 装配 pageParams（实时）。
     *
     * @param shareCode     块的 `agentCode`（信贷登记的分享编码，如 `1010`）
     * @param reportNo      报告编号（取 report 表的客户/流水号）
     * @param blockCode     块编号（用于读主体令牌，仅 1050 需要）
     * @param guarantorName 当前担保人名（可选；多个担保人时定位具体人）
     * @return 形如 `serialNo=xxx&customerId=xxx` 的 pageParams 串
     * @throws RuntimeException 未知 shareCode / 关键取值缺失
     */
    public String build(String shareCode, String reportNo, String blockCode, String guarantorName) {
        String sc = shareCode == null ? "" : shareCode.trim();
        if (!StringUtils.hasText(reportNo)) {
            throw new RuntimeException("reportNo 不能为空");
        }
        Map<String, Object> base = queryMapper.selectReportBase(reportNo);
        if (base == null || base.isEmpty()) {
            throw new RuntimeException("未找到报告记录: " + reportNo);
        }
        String customerId = str(base, "customer_id");
        String customerName = str(base, "customer_name");
        String checkTaskNo = str(base, "check_task_no");

        switch (sc) {
            case SC_APPROVE_INFO:
                return buildApproveInfo(reportNo, customerId);
            case SC_DAILY_CHECK:
                return buildDailyCheck(checkTaskNo, customerId, customerName, null);
            case SC_PUBLIC_CONDITION:
                return buildDailyCheck(checkTaskNo, customerId, customerName, FIXED_FALSE);
            case SC_ENT_FINA:
                return join(kv("menuType", FIXED_MENU_TYPE),
                        kv("customerIds", customerId), kv("customerNames", customerName));
            case SC_CREDIT_REPORT:
                return buildCreditReport(reportNo, blockCode, guarantorName, customerId);
            case SC_TROUBLE_MORTGAGE:
            case SC_ALERT_LEDGER:
            case SC_TROUBLE_RECTIFY:
            case SC_ALERT_SIGN_LEDGER:
                return join(kv("customerId", customerId));
            case SC_NATIONAL_DEVELOPMENT:
                return join(kv("customerType", FIXED_CUSTOMER_TYPE), kv("customerId", customerId));
            case SC_DAILY_PUBLIC_CHECK:
                return join(kv("customerId", customerId), kv("applyType", FIXED_APPLY_TYPE));
            default:
                throw new RuntimeException("未知的 shareCode（信贷分享编码）: " + sc);
        }
    }

    /** 1010 批复链接（电子批复）—— 取对公检查主表的相关流水号 */
    private String buildApproveInfo(String reportNo, String customerId) {
        Map<String, Object> row = queryMapper.selectCorpCheckInfo(reportNo);
        return join(
                kv("serialNo", str(row, "bapserialno")),
                kv("customerId", customerId),
                kv("applySerialNo", str(row, "baserialno")),
                kv("approveSerialNo", str(row, "bapserialno")),
                kv("electroApproveSerialNo", str(row, "electroapproveserialno")),
                kv("approveApplyType", str(row, "approveapplytype")));
    }

    /** 1020 打卡 / 1030 批复落实 —— 以日检流水号为主体 */
    private String buildDailyCheck(String checkTaskNo, String customerId, String customerName,
                                   String modifyPermission) {
        List<String> parts = new ArrayList<>();
        parts.add(kv("serialNo", checkTaskNo));
        parts.add(kv("customerId", customerId));
        parts.add(kv("customerName", customerName));
        parts.add(kv("isOnlyRead", FIXED_FALSE));
        if (modifyPermission != null) {
            parts.add(kv("modifyPermission", modifyPermission));
        }
        return join(parts);
    }

    /**
     * 1050 征信 —— 按主体令牌分三支（借款人 / 企业担保人 / 个人担保人）。
     *
     * <p>块 `agentParams` 存主体令牌，如 `subjectType=担保人,guarantorType=自然人`；
     * 未配令牌时**默认借款人**（六章那块就是这个语义）。</p>
     */
    private String buildCreditReport(String reportNo, String blockCode, String guarantorName,
                                     String customerId) {
        Map<String, String> tokens = parseTokens(queryMapper.selectBlockAgentParams(blockCode));
        String subjectType = tokens.getOrDefault(TOKEN_SUBJECT_TYPE, SUBJECT_BORROWER);
        String guarantorType = tokens.get(TOKEN_GUARANTOR_TYPE);

        String creditRecordNo;
        if (SUBJECT_BORROWER.equals(subjectType)) {
            creditRecordNo = queryMapper.selectCreditReportNo(reportNo, SUBJECT_BORROWER);
        } else if (GUARANTOR_NATURAL.equals(guarantorType)) {
            // 个人担保人 → app_guarantor_credit_info
            creditRecordNo = StringUtils.hasText(guarantorName)
                    ? queryMapper.selectGuarantorCreditReportNoByName(reportNo, guarantorName)
                    : queryMapper.selectGuarantorCreditReportNo(reportNo);
        } else {
            // 企业担保人（或未标 guarantorType 的担保人）→ app_credit_report_info
            creditRecordNo = StringUtils.hasText(guarantorName)
                    ? queryMapper.selectCreditReportNoByName(reportNo, subjectType, guarantorName)
                    : queryMapper.selectCreditReportNo(reportNo, subjectType);
        }

        if (!StringUtils.hasText(creditRecordNo)) {
            throw new RuntimeException("未取到征信报告记录号（subjectType=" + subjectType
                    + (StringUtils.hasText(guarantorName) ? ", guarantorName=" + guarantorName : "")
                    + ", reportNo=" + reportNo + "）");
        }
        log.info("【链接溯源·1050征信】reportNo={} blockCode={} subjectType={} guarantorName={} creditRecordNo={}",
                reportNo, blockCode, subjectType, guarantorName, creditRecordNo);
        return join(kv("creditRecordNo", creditRecordNo),
                kv("fileType", FIXED_FILE_TYPE),
                kv("customerId", customerId));
    }

    // ==================== 工具 ====================

    /** 解析块的元令牌串（`k1=v1,k2=v2`） */
    private static Map<String, String> parseTokens(String agentParams) {
        Map<String, String> m = new HashMap<>(4);
        if (!StringUtils.hasText(agentParams)) {
            return m;
        }
        for (String seg : agentParams.split(",")) {
            int i = seg.indexOf('=');
            if (i > 0) {
                m.put(seg.substring(0, i).trim(), seg.substring(i + 1).trim());
            }
        }
        return m;
    }

    /** 单个 `key=value`；值为空则返回 null（由 {@link #join} 丢弃，避免给信贷传空参） */
    private static String kv(String key, String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        String v;
        try {
            v = URLEncoder.encode(value, "UTF-8");
        } catch (Exception e) {
            v = value;
        }
        return key + "=" + v;
    }

    /** 拼接非空片段为 `a=1&b=2` */
    private static String join(String... parts) {
        List<String> list = new ArrayList<>(parts.length);
        for (String p : parts) {
            if (StringUtils.hasText(p)) {
                list.add(p);
            }
        }
        return join(list);
    }

    private static String join(List<String> parts) {
        return String.join("&", parts);
    }

    /** 从 MyBatis 返回的 Map 里按列名取值（**大小写不敏感**：不同驱动返回的列名大小写不一致） */
    private static String str(Map<String, Object> row, String col) {
        if (row == null || row.isEmpty()) {
            return null;
        }
        Object v = row.get(col);
        if (v == null) {
            for (Map.Entry<String, Object> e : row.entrySet()) {
                if (e.getKey() != null && e.getKey().equalsIgnoreCase(col)) {
                    v = e.getValue();
                    break;
                }
            }
        }
        return v == null ? null : String.valueOf(v);
    }
}
