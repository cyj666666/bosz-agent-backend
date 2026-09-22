package com.suzhou.bank.config;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.suzhou.bank.entity.SysRole;
import com.suzhou.bank.mapper.SysRoleMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.Arrays;
import java.util.List;

/**
 * 登录认证拦截器
 * <p>校验请求头中的 Authorization Bearer Token。
 * 系统管理相关路径（<code>/api/user/**</code>、<code>/api/role/**</code>、
 * <code>/api/agent/roleAuth/**</code>）需要「系统管理菜单权限」。
 * 放行白名单由 WebMvcConfig 配置。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuthInterceptor implements HandlerInterceptor {

    private final JwtUtil jwtUtil;
    private final SysRoleMapper sysRoleMapper;

    /**
     * 「系统管理」下的菜单键集合 —— 系统管理接口的准入判据（2026-09-22 第二次口径调整）
     *
     * <p><b>语义</b>：能看系统管理菜单，就能用系统管理接口。判定看角色
     * {@code menu_permissions} 里有没有下面任意一个键。</p>
     *
     * <p>🔴 <b>这份清单有三处消费点，改一处必须三处一起想</b>：</p>
     * <ol>
     *   <li>本类 —— 后端接口准入（{@code /api/user}、{@code /api/role}、{@code /api/agent/roleAuth}）</li>
     *   <li>{@code src/layouts/MainLayout.vue} —— 「系统管理」下拉是否渲染</li>
     *   <li>{@code src/pages/system/RoleList.vue} —— 「菜单权限」多选框能否勾选分配</li>
     * </ol>
     *
     * <p>⚠️ {@code /role-auth}（数据授权）从"仅超管可见"改为<b>可分配的普通菜单项</b>：
     * 新口径是"能看系统管理菜单就能用"，若继续把它排除在可分配清单之外，
     * 就会出现「菜单渲染了但接口 403」或「接口能调但菜单看不到」的裂缝。</p>
     */
    private static final List<String> SYSTEM_MENU_KEYS =
            Arrays.asList("/users", "/roles", "/role-auth");

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
        // roles 一并在首次解析后放入 request：agent 模块的 ApiContext 从这里读取当前用户角色
        // （用于记录指标的创建人/更新人、按角色过滤指标树）。
        // 这是一处刻意的"接缝"：agent 模块不直接依赖本工程的 JwtUtil，
        // 只依赖 request attribute 名，双方解耦。
        List<String> roles = jwtUtil.getRoles(token);
        request.setAttribute("roles", roles);

        // 系统管理接口需要「系统管理菜单权限」（修改自己密码的接口除外）
        // 2026-09-22：/api/agent/roleAuth（角色「数据授权」：指标 / 知识 / 知识输出三套）
        //   与 /api/user、/api/role 用**同一条判定** —— 「能看系统管理菜单就能用」。
        //   早期实现把它单独排除在"可分配"之外（只能超管用），本次统一：
        //   判据见 SYSTEM_MENU_KEYS，兜底见 isSystemAdmin()。
        String path = request.getRequestURI();
        if (!path.endsWith("/change-password")
                && (path.startsWith("/api/user") || path.startsWith("/api/role")
                    || path.startsWith("/api/agent/roleAuth"))) {
            if (!isSystemAdmin(roles)) {
                sendError(response, 403, "无权限，仅系统管理员可操作");
                return false;
            }
        }

        return true;
    }

    /**
     * 系统管理接口准入判定（2026-09-22 第二次口径调整）
     *
     * <p><b>判定为「或」关系：</b></p>
     * <ol>
     *   <li>{@code sys_role.menu_permissions} 含 {@link #SYSTEM_MENU_KEYS} 中<b>任意一个键</b>
     *       —— <b>主口径</b>。语义 =「能看系统管理菜单就能用系统管理接口」，
     *       与前端菜单渲染、角色管理页的可分配清单同源。</li>
     *   <li>{@code role_code == "admin"} —— <b>兜底</b>，见下方风险说明。</li>
     * </ol>
     *
     * <p><b>🔴 为什么必须保留 admin 兜底（不能只认菜单数据）</b>：
     * 本拦截器守的 {@code /api/user}、{@code /api/role} 正是<b>系统管理自己的入口</b>。
     * 若只认菜单数据，存在两条不可逆自锁路径：</p>
     * <ol>
     *   <li>角色管理页的「菜单权限」多选框<b>可以把 admin 的
     *       {@code /users}、{@code /roles} 都取消勾选</b> —— 改完 admin 立刻失去
     *       用户管理/角色管理权限，而改回来又必须先进入角色管理页 ⇒ <b>永久锁死</b>；</li>
     *   <li>新环境/行内若只跑初始化脚本、没跑角色相关的增量 DML，
     *       而 DDL 默认值是 {@code '[]'} ⇒ 一上线即锁死。</li>
     * </ol>
     * <p>兜底与主口径是「或」关系，<b>不会削弱主口径</b>：普通角色只要
     * {@code menu_permissions} 里有 {@code /users}（或 {@code /roles}、{@code /role-auth}）
     * 就能通过。</p>
     *
     * <p><b>历史沿革</b>：本方法先后用过三种判据 ——
     * ①{@code roles.contains("admin")}（角色编码硬编码）→
     * ②{@code menu_permissions} 含裸 {@code "*"}（「菜单全通」）→
     * ③当前（含系统管理菜单键之一）。<b>第 ② 种已废弃</b>：客户最终确定的角色模型里
     * 管理员并不持有 {@code "*"}（管理员默认只看报告管理/智策引擎/系统管理），
     * 该判据会失效。<b>{@code "*"} 机制本身仍保留</b>（前端路由放行 + 菜单全渲染仍认它）。</p>
     *
     * @param roleCodes Token 里签发的角色编码列表
     * @return true = 允许访问系统管理接口
     */
    private boolean isSystemAdmin(List<String> roleCodes) {
        if (roleCodes == null || roleCodes.isEmpty()) {
            return false;
        }

        // ② 兜底：admin 角色编码（防上述两条自锁路径）
        if (roleCodes.contains("admin")) {
            return true;
        }

        // ① 主口径：查这些角色的 menu_permissions 里有没有系统管理菜单键
        try {
            List<SysRole> roles = sysRoleMapper.selectList(
                    new LambdaQueryWrapper<SysRole>().in(SysRole::getRoleCode, roleCodes));
            for (SysRole role : roles) {
                String perms = role.getMenuPermissions();
                if (perms == null) {
                    continue;
                }
                // 用「被双引号包裹的完整键」做字符串包含判定：
                //   · menu_permissions 是 JSON 数组串（如 ["/reports","/users"]）；
                //   · 带引号可避免误命中超集键（如 "/users-export" 不会被 "/users" 命中）。
                for (String key : SYSTEM_MENU_KEYS) {
                    if (perms.contains("\"" + key + "\"")) {
                        return true;
                    }
                }
            }
        } catch (Exception e) {
            // 查库异常 ⇒ fail-closed（拒绝）。注意上面的 admin 兜底已经 return，
            // 不受这里影响 —— 也就是"数据库抖动时系统管理员仍进得去，能把数据改回来"。
            log.warn("查询角色菜单权限失败，按无权限处理。roleCodes={}, err={}", roleCodes, e.getMessage());
            return false;
        }
        return false;
    }

    private void sendError(HttpServletResponse response, int status, String message) throws Exception {
        response.setContentType("application/json;charset=UTF-8");
        response.setStatus(status);
        response.getWriter().write("{\"code\":" + status + ",\"message\":\"" + message + "\"}");
    }
}