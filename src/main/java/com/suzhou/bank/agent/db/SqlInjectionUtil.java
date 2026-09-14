package com.suzhou.bank.agent.db;

import lombok.extern.slf4j.Slf4j;

import java.util.Locale;

/**
 * SQL 注入风险检测工具
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.common.util.SqlInjectionUtil}。</p>
 *
 * <p><b>与源实现的差异</b>：删除了 {@code checkDictTableSign} 方法。
 * 它是 JeecgBoot「在线表字典」功能专用的签名校验，依赖 Jeecg 私有的
 * {@code X-Access-Token} 请求头与固定的盐值，agent 模块没有也不需要该功能；
 * 宿主工程的鉴权头是 {@code Authorization}，保留该方法只会带来误导。</p>
 *
 * <p><b>行为保持不变</b>：各 {@code filterContent} / {@code checkSql} 方法
 * 在源实现里只打日志、<b>不抛异常</b>（异常抛出语句均被注释）。
 * 这里刻意保持"仅记录不阻断"，避免改变既有业务行为——
 * 若后续需要真正拦截，应作为一次独立的安全加固统一评估，
 * 而不是在迁移过程中悄悄改变语义。</p>
 */
@Slf4j
public class SqlInjectionUtil {

    private static final String XSS_STR = "exec |insert |delete |update |drop |truncate |declare |+";

    /**
     * sql注入过滤处理（仅记录日志）
     */
    public static void filterContent(String value) {
        if (value == null || "".equals(value)) {
            return;
        }
        value = value.toLowerCase();
        String[] xssArr = XSS_STR.split("\\|");
        for (String s : xssArr) {
            if (value.indexOf(s) > -1) {
                log.error("请注意，存在SQL注入关键词---> {}", s);
                log.error("请注意，值可能存在SQL注入风险!---> {}", value);
            }
        }
    }

    /**
     * sql注入过滤处理（仅记录日志）
     */
    public static void filterContent(String[] values) {
        String[] xssArr = XSS_STR.split("\\|");
        for (String value : values) {
            if (value == null || "".equals(value)) {
                continue;
            }
            value = value.toLowerCase();
            for (String s : xssArr) {
                if (value.indexOf(s) > -1) {
                    log.error("请注意，存在SQL注入关键词---> {}", s);
                    log.error("请注意，值可能存在SQL注入风险!---> {}", value);
                }
            }
        }
    }

    /**
     * @特殊方法(不通用) 仅用于字典条件SQL参数，注入过滤
     */
    @Deprecated
    public static void specialFilterContent(String value) {
        String specialXssStr = " exec | insert | select | delete | update | drop | count | chr | mid | master | truncate | char | declare |;|+|";
        String[] xssArr = specialXssStr.split("\\|");
        if (value == null || "".equals(value)) {
            return;
        }
        value = value.toLowerCase();
        for (String s : xssArr) {
            if (value.indexOf(s) > -1 || value.startsWith(s.trim())) {
                log.error("请注意，存在SQL注入关键词---> {}", s);
                log.error("请注意，值可能存在SQL注入风险!---> {}", value);
            }
        }
    }

    /**
     * @特殊方法(不通用) 仅用于Online报表SQL解析，注入过滤
     */
    @Deprecated
    public static void specialFilterContentForOnlineReport(String value) {
        String specialXssStr = " exec | insert | delete | update | drop | chr | mid | master | truncate | char | declare |";
        String[] xssArr = specialXssStr.split("\\|");
        if (value == null || "".equals(value)) {
            return;
        }
        value = value.toLowerCase();
        for (String s : xssArr) {
            if (value.indexOf(s) > -1 || value.startsWith(s.trim())) {
                log.error("请注意，存在SQL注入关键词---> {}", s);
                log.error("请注意，值可能存在SQL注入风险!---> {}", value);
            }
        }
    }

    /**
     * SQL标识符（表名、列名）白名单校验。
     * 仅允许字母、数字、下划线、点号。
     *
     * <p>同样只记录不阻断，与原实现一致。</p>
     */
    public static void validateSqlIdentifier(String identifier) {
        if (identifier == null || "".equals(identifier.trim())) {
            return;
        }
        if (!identifier.matches("^[a-zA-Z0-9_.]+$")) {
            log.error("非法的SQL标识符---> {}", identifier);
        }
    }

    public static void checkSql(String value) {
        if (value == null || "".equals(value)) {
            return;
        }
        value = value.toLowerCase(Locale.ENGLISH);
        String[] xssArr = XSS_STR.split("\\|");
        for (String s : xssArr) {
            if (value.indexOf(s) > -1) {
                log.error("请注意，存在SQL注入关键词---> {}", s);
                log.error("请注意，值可能存在SQL注入风险!---> {}", value);
            }
        }
    }
}
