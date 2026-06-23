package com.suzhou.bank.config;

import lombok.extern.slf4j.Slf4j;

/**
 * 授权辅助工具 — 默认 fail-close，确保不遗漏接入真实认证。
 * 开发阶段在 application.yml 设置 app.auth.dev-mode: true 激活宽松模式。
 * 上线前删除 dev-mode 配置，确保所有校验生效。
 */
@Slf4j
public final class AuthHelper {

    /**
     * 开发模式：true 时校验仅打印警告不抛异常。
     * 上线前务必关闭。由 AuthDevModeInitializer 根据配置注入。
     */
    static volatile boolean devMode = false;

    private AuthHelper() {}

    /**
     * 校验当前用户是否有权访问指定客户数据。
     * @throws IllegalStateException 未接入认证且非开发模式
     */
    public static void verifyCustomerAccess(Long customerId) {
        if (devMode) {
            log.warn("[AUTH-DEV] verifyCustomerAccess({}) — 开发模式放行，上线前请接入认证", customerId);
            return;
        }
        throw new IllegalStateException(
            "认证未接入：verifyCustomerAccess 尚未实现。开发阶段请设置 app.auth.dev-mode=true");
    }

    /**
     * 校验当前用户为管理员角色。
     * @throws IllegalStateException 未接入认证且非开发模式
     */
    public static void verifyAdmin() {
        if (devMode) {
            log.warn("[AUTH-DEV] verifyAdmin() — 开发模式放行，上线前请接入认证");
            return;
        }
        throw new IllegalStateException(
            "认证未接入：verifyAdmin 尚未实现。开发阶段请设置 app.auth.dev-mode=true");
    }

    /* ---- 上下文获取方法（接入认证后实现） ---- */

    public static Long getCurrentBranchId() {
        return null; // TODO: 从 SecurityContext 获取
    }

    public static String getCurrentRole() {
        return null; // TODO: 从 SecurityContext 获取
    }

    public static boolean isAdmin() {
        return "ADMIN".equalsIgnoreCase(getCurrentRole());
    }

    /**
     * 由 AuthDevModeInitializer 调用，不要在业务代码中调用。
     */
    static void setDevMode(boolean enabled) {
        devMode = enabled;
        if (enabled) {
            log.warn("========================================");
            log.warn("⚠  AUTH DEV MODE ACTIVE — 所有授权校验已放行");
            log.warn("========================================");
        }
    }
}
