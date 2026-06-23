package com.suzhou.bank.config;

/**
 * 授权辅助工具。
 * 当前为占位实现——接入 Spring Security / JWT 后替换为真实用户上下文。
 * TODO: 集成认证框架后，从 SecurityContextHolder 获取当前用户信息。
 */
public final class AuthHelper {

    private AuthHelper() {}

    /**
     * 校验当前用户是否有权访问指定客户数据。
     * 当前占位实现不做拦截；接入认证后按机构/角色过滤。
     */
    public static void verifyCustomerAccess(Long customerId) {
        // TODO: 从 SecurityContext 获取当前用户，校验 customerId 归属
    }

    /**
     * 获取当前登录用户的机构ID。
     * @return null 表示未认证（接入认证框架后需抛异常）
     */
    public static Long getCurrentBranchId() {
        // TODO: 从 SecurityContext 获取当前用户所属机构
        return null;
    }

    /**
     * 获取当前登录用户的角色。
     */
    public static String getCurrentRole() {
        // TODO: 从 SecurityContext 获取当前用户角色
        return null;
    }

    /**
     * 判断当前用户是否为管理员角色。
     */
    public static boolean isAdmin() {
        return "ADMIN".equalsIgnoreCase(getCurrentRole());
    }

    /**
     * 校验当前用户为管理员，否则拒绝操作。
     * TODO: 接入认证后抛出 AccessDeniedException
     */
    public static void verifyAdmin() {
        // TODO: if (!isAdmin()) throw new AccessDeniedException("需要管理员权限");
    }
}
