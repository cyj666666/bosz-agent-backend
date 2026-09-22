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
import java.util.List;

/**
 * 登录认证拦截器
 * <p>校验请求头中的 Authorization Bearer Token。
 * 系统管理相关路径（<code>/api/user/**</code>、<code>/api/role/**</code>、
 * <code>/api/agent/roleAuth/**</code>）需要「菜单全通」角色。
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

        // 系统管理接口需要「菜单全通」角色（修改自己密码的接口除外）
        // 2026-09-22：新增 /api/agent/roleAuth（角色「数据授权」配置，指标/知识/知识输出三套）。
        //   它与 /api/user、/api/role 同级 —— 决定"谁能看什么"，**刻意不纳入**
        //   「能看菜单就能操作」那条统一规则：若能分配给普通角色，等于允许自行提权。
        String path = request.getRequestURI();
        if (!path.endsWith("/change-password")
                && (path.startsWith("/api/user") || path.startsWith("/api/role")
                    || path.startsWith("/api/agent/roleAuth"))) {
            if (!isMenuAllPower(roles)) {
                sendError(response, 403, "无权限，仅系统管理员可操作");
                return false;
            }
        }

        return true;
    }

    /**
     * 「菜单全通」判定 —— 系统管理接口的准入条件（2026-09-22 口径统一）
     *
     * <p><b>判定为「或」关系：</b></p>
     * <ol>
     *   <li>{@code sys_role.menu_permissions} 含<b>裸 {@code "*"}</b> —— <b>主口径</b>。
     *       与以下三处同一个口径（改一处必须四处一起想）：
     *       <ul>
     *         <li>宿主 {@code AuthService#getUserMenuPermissions}：合并各角色 menu_permissions，
     *             含 {@code "*"} 即返回 {@code ["*"]}</li>
     *         <li>agent {@code AgentRoleMapper#countFullMenuRoles}：{@code LIKE '%"*"%'}
     *             （指标 / 知识的数据旁路判定）</li>
     *         <li>前端 {@code menus.includes('*')}：路由守卫放行 + 侧边菜单全渲染</li>
     *       </ul>
     *   </li>
     *   <li>{@code role_code == "admin"} —— <b>兜底</b>，见下方风险说明。</li>
     * </ol>
     *
     * <p><b>🔴 为什么必须保留 admin 兜底（不能只认 menu_permissions）</b>：
     * 本拦截器守的 {@code /api/user}、{@code /api/role} 正是<b>系统管理自己的入口</b>。
     * 若只认 {@code "*"}，存在两条不可逆自锁路径：</p>
     * <ol>
     *   <li>角色管理页的「菜单权限」多选框<b>可以把 admin 的 {@code ["*"]} 改成具体清单</b>
     *       —— 改完 admin 立刻失去用户管理/角色管理权限，而改回来又必须先进入角色管理页
     *       ⇒ <b>永久锁死</b>；</li>
     *   <li>{@code sql/agent/agent_模块菜单授权_as_agent.sql} 给 admin 存的就是
     *       <b>具体清单</b>（不含 {@code "*"}），且 DDL 默认值是 {@code '[]'}
     *       ⇒ 新环境/行内若只跑初始化脚本、没跑
     *       {@code 20260922_增量_角色菜单全通口径统一.sql}，一上线即锁死。</li>
     * </ol>
     * <p>兜底与主口径是「或」关系，<b>不会削弱主口径</b>：普通角色只要 {@code menu_permissions}
     * 里有 {@code "*"} 就能通过（这正是本次修复要达成的效果）。</p>
     *
     * @param roleCodes Token 里签发的角色编码列表
     * @return true = 允许访问系统管理接口
     */
    private boolean isMenuAllPower(List<String> roleCodes) {
        if (roleCodes == null || roleCodes.isEmpty()) {
            return false;
        }

        // ② 兜底：admin 角色编码（防上述两条自锁路径）
        if (roleCodes.contains("admin")) {
            return true;
        }

        // ① 主口径：查这些角色的 menu_permissions 里有没有裸 "*"
        try {
            List<SysRole> roles = sysRoleMapper.selectList(
                    new LambdaQueryWrapper<SysRole>().in(SysRole::getRoleCode, roleCodes));
            for (SysRole role : roles) {
                String perms = role.getMenuPermissions();
                // 用「被双引号包裹的裸星号」做字符串包含判定：
                //   · 与 agent 侧 countFullMenuRoles 的 LIKE '%"*"%' 同口径；
                //   · 不会误命中 "/agent/*" 这类前缀通配（那种是 "/*"，不是 "*"）。
                if (perms != null && perms.contains("\"*\"")) {
                    return true;
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