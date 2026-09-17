package com.suzhou.bank.agent.util;

import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 业务入参名归一（**向后兼容**）
 *
 * <p><b>为什么需要</b>：2026-09-17 的入参规范化把配置里的参数名统一成了驼峰
 * （{@code reportNo} / {@code entName} / {@code guarantorName}），而调用方（前端规则页、上游贷后报告系统）
 * 可能仍在传历史写法（{@code reportno} / {@code guarantorname} / {@code entname} 等）。
 * Java 侧取值是 {@code Map.get(name)}，<b>大小写敏感</b>，写法对不上就直接取不到值。</p>
 *
 * <p><b>做法</b>：把任意写法的键，**补上规范名键**（规范键不存在时才补，原键一律保留）。
 * 于是：</p>
 * <ul>
 *   <li>调用方<b>一行都不用改</b> —— 老写法照常命中；</li>
 *   <li>配置侧可以分批迁移、随时回滚 —— 新旧配置都能跑；</li>
 *   <li>归一动作会在日志里留痕（{@code 【入参归一】}），方便判断上游是否还在用旧写法。</li>
 * </ul>
 *
 * <p><b>为什么不用 ThreadLocal</b>：取数跑在独立的 {@code fetch-data-fetcher-*} 线程池里，
 * ThreadLocal 传不过去；而归一作用在"参数 Map"上，天然跟着参数走。</p>
 *
 * <p><b>匹配规则</b>：把键归一成「小写 + 去掉 {@code _} / {@code -} / 空格」再查别名表，
 * 因此 {@code ReportNo} / {@code REPORTNO} / {@code report_no} / {@code report-no} 全部命中。</p>
 */
@Slf4j
public final class AgentParamNames {

    /** 报告编号 */
    public static final String REPORT_NO = "reportNo";

    /** 企业名称（同时用于提示词 {{objectName}}、日志 ent_name） */
    public static final String ENT_NAME = "entName";

    /** 客户编号（2026-09-17 起不再作为 SQL 严格条件，保留常量供兼容与日志使用） */
    public static final String CUSTOMER_ID = "customerId";

    /** 担保人客户编号（同上，已不作为 SQL 条件） */
    public static final String GUARANTOR_ID = "guarantorId";

    /** 担保人名称（担保人场景的 SQL 条件） */
    public static final String GUARANTOR_NAME = "guarantorName";

    /** 归一后的键 → 规范名 */
    private static final Map<String, String> ALIAS = new HashMap<>();

    static {
        // 报告编号
        alias(REPORT_NO, "reportno", "report_no", "report-no", "reportnum", "report_num", "reportnumber", "report_number");
        // 企业名称（customername 也算：上游有时把"企业名称"这个参数叫 customerName）
        alias(ENT_NAME, "entname", "ent_name", "customername", "customer_name", "qiyemingcheng");
        // 客户编号
        alias(CUSTOMER_ID, "customerid", "customer_id", "custid", "cust_id", "kehuhao");
        // 担保人编号
        alias(GUARANTOR_ID, "guarantorid", "guarantor_id", "guarid", "guar_id");
        // 担保人名称
        alias(GUARANTOR_NAME, "guarantorname", "guarantor_name", "guarantorname", "danbaorenname");
    }

    private AgentParamNames() {
    }

    private static void alias(String canonical, String... variants) {
        ALIAS.put(norm(canonical), canonical);
        for (String v : variants) {
            ALIAS.put(norm(v), canonical);
        }
    }

    /** 归一用键：小写 + 去掉下划线/短横线/空格 */
    private static String norm(String s) {
        if (s == null) {
            return "";
        }
        StringBuilder sb = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '_' || c == '-' || c == ' ') {
                continue;
            }
            sb.append(Character.toLowerCase(c));
        }
        return sb.toString();
    }

    /**
     * 就地归一：为历史写法的键补上规范名键（**双写**，原键保留）。
     *
     * <p>只在"规范名键不存在"时补，因此不会覆盖调用方已经传对的规范值。</p>
     *
     * @param map 参数 Map（可为 null，方法内判空）
     */
    public static void normalizeInPlace(Map<String, Object> map) {
        if (map == null || map.isEmpty()) {
            return;
        }
        List<String> keys = new ArrayList<>(map.keySet());
        for (String k : keys) {
            if (k == null) {
                continue;
            }
            String canonical = ALIAS.get(norm(k));
            if (canonical == null || canonical.equals(k)) {
                continue;
            }
            if (!map.containsKey(canonical)) {
                map.put(canonical, map.get(k));
                log.info("【入参归一】{} -> {}（兼容旧写法，原键保留）", k, canonical);
            }
        }
    }

    /**
     * 别名感知取值：先按规范名取，取不到再按"等同别名的任意写法"取。
     *
     * <p>用作取数层的**最后兜底** —— 只要参数里带了企业名/报告号，不论什么写法都能命中。
     *
     * @param map       参数 Map
     * @param canonical 规范名（用本类的常量）
     * @return 取到的值；确实没有则返回 {@code null}
     */
    public static Object get(Map<String, Object> map, String canonical) {
        if (map == null || map.isEmpty()) {
            return null;
        }
        if (map.containsKey(canonical)) {
            return map.get(canonical);
        }
        for (Map.Entry<String, Object> e : map.entrySet()) {
            String k = e.getKey();
            if (k != null && canonical.equals(ALIAS.get(norm(k)))) {
                return e.getValue();
            }
        }
        return null;
    }

    /** 该键是否属于某个规范名的别名 */
    public static boolean isAliasOf(String key, String canonical) {
        return key != null && canonical != null && canonical.equals(ALIAS.get(norm(key)));
    }

    /** 是否为「值有效」（非 null、非空白、非空字符串字面量 '' 或 ""） */
    public static boolean hasValue(Object v) {
        if (v == null) {
            return false;
        }
        String s = String.valueOf(v).trim();
        return !s.isEmpty() && !"''".equals(s) && !"\"\"".equals(s);
    }
}
