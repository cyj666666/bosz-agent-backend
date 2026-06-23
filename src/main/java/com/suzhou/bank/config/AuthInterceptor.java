package com.suzhou.bank.config;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.List;

/**
 * 登录认证拦截器
 * <p>校验请求头中的 Authorization Bearer Token。
 * 系统管理相关路径（/api/user/**, /api/role/**）需要管理员角色。
 * 放行白名单由 WebMvcConfig 配置。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Component
@RequiredArgsConstructor
public class AuthInterceptor implements HandlerInterceptor {

    private final JwtUtil jwtUtil;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) throws Exception {
        // OPTIONS 预检请求直接放行
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            sendError(response, 401, "未登录或 Token 已过期");
            return false;
        }

        String token = authHeader.substring(7);
        if (!jwtUtil.validateToken(token)) {
            sendError(response, 401, "Token 无效或已过期");
            return false;
        }

        // 将用户信息存入 request attribute，供后续使用
        request.setAttribute("userId", jwtUtil.getUserId(token));
        request.setAttribute("username", jwtUtil.getUsername(token));

        // 系统管理接口需要管理员角色（修改自己密码的接口除外）
        String path = request.getRequestURI();
        if (!path.endsWith("/change-password")
                && (path.startsWith("/api/user") || path.startsWith("/api/role"))) {
            List<String> roles = jwtUtil.getRoles(token);
            if (roles == null || !roles.contains("admin")) {
                sendError(response, 403, "无权限，仅系统管理员可操作");
                return false;
            }
        }

        return true;
    }

    private void sendError(HttpServletResponse response, int status, String message) throws Exception {
        response.setContentType("application/json;charset=UTF-8");
        response.setStatus(status);
        response.getWriter().write("{\"code\":" + status + ",\"message\":\"" + message + "\"}");
    }
}