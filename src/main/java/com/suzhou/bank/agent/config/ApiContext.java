package com.suzhou.bank.agent.config;

import com.alibaba.fastjson.JSON;
import com.suzhou.bank.agent.mapper.AgentRoleMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * agent 模块的当前调用者上下文
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.config.ApiContext}。</p>
 *
 * <p><b>与原实现的关键差异——取值来源换成了宿主的既有约定，而不是依赖框架：</b></p>
 * <p>原实现通过 JeecgBoot 的 {@code LoginUserHolder} 从它自己的 JWT 解析当前用户。
 * agent 模块不引入 JeecgBoot，改为读取宿主 {@code AuthInterceptor} 在鉴权时
 * 写入 request 的三个属性：{@code userId} / {@code username} / {@code roles}。</p>
 *
 * <p>这样做的好处是<b>零编译期耦合</b>——本类不认识宿主的任何一个类，
 * 只依赖 Spring 的 {@code RequestContextHolder} 与 Servlet 规范里的 request attribute 名。
 * 搬迁到别的工程时，只要那边同样把这两个属性写进 request，本类即可照常工作。</p>
 *
 * <p><b>注意</b>：{@code @Async} 线程、定时任务等非 HTTP 线程里取不到 request，
 * 此时返回的是"空上下文"（userId/userName 为空字符串）而不是抛异常——
 * 这与原实现的容错取向一致（原实现在取不到时也会 new 一个空模型）。</p>
 */
@Slf4j
public class ApiContext {

    /** 宿主 AuthInterceptor 写入的用户主键属性名 */
    private static final String ATTR_USER_ID = "userId";

    /** 宿主 AuthInterceptor 写入的用户名属性名 */
    private static final String ATTR_USERNAME = "username";

    /** 宿主 AuthInterceptor 写入的角色列表属性名 */
    private static final String ATTR_ROLES = "roles";

    private static final ThreadLocal<ApiContextModel> THREAD_LOCAL = new ThreadLocal<>();

    /**
     * 缓存对应的 request 引用
     *
     * <p><b>为什么需要它</b>：Tomcat 复用工作线程，同一线程会依次服务不同用户的请求。
     * 源实现只按"ThreadLocal 为空"判断是否解析，在宿主环境下会出现
     * <b>把上一个请求的用户信息串给下一个请求</b>（跨用户数据泄漏）——
     * 因为源工程每个请求都由 {@code ApiAccessAuthCheckFilter} 先 {@code setApiContextModel} 覆盖，
     * 而宿主没有这个过滤器，只剩本类的懒加载，一旦线程复用就命中脏值。</p>
     *
     * <p>这里额外记录 request 引用，请求不同（或被清理过）就重新解析，从根上消除串号。</p>
     */
    private static final ThreadLocal<HttpServletRequest> THREAD_REQUEST = new ThreadLocal<>();

    public static void setApiContextModel(ApiContextModel apiContextModel) {
        THREAD_LOCAL.set(apiContextModel);
        THREAD_REQUEST.set(currentRequest());
    }

    public static void removeApiContextModel() {
        THREAD_LOCAL.remove();
        THREAD_REQUEST.remove();
    }

    public static ApiContextModel getOriginalApiContextModel() {
        return THREAD_LOCAL.get();
    }

    /**
     * 取当前调用者上下文。
     *
     * <p>优先取本线程显式设置过的模型（{@link #setApiContextModel}），
     * 否则从当前请求中解析；两者都没有时返回一个空模型，<b>不返回 null</b>——
     * 原实现同样保证非 null，平移过来的业务代码直接 {@code .getUserName()} 不会 NPE。</p>
     */
    public static ApiContextModel getApiContextModel() {
        HttpServletRequest current = currentRequest();
        ApiContextModel model = THREAD_LOCAL.get();
        // 请求不同即重新解析：兼顾"同一请求内不重复查库"与"不同请求绝不串号"
        if (model == null || THREAD_REQUEST.get() != current) {
            model = resolveFromRequest(current);
            THREAD_LOCAL.set(model);
            THREAD_REQUEST.set(current);
        }
        return model;
    }

    private static HttpServletRequest currentRequest() {
        try {
            RequestAttributes attrs = RequestContextHolder.getRequestAttributes();
            if (attrs instanceof ServletRequestAttributes) {
                return ((ServletRequestAttributes) attrs).getRequest();
            }
        } catch (Exception e) {
            log.warn("agent 模块获取当前请求失败", e);
        }
        return null;
    }

    private static ApiContextModel resolveFromRequest(HttpServletRequest request) {
        ApiContextModel.ApiContextModelBuilder builder = ApiContextModel.builder();
        if (request == null) {
            return emptyModel(builder);
        }
        try {
            String userId = stringAttr(request, ATTR_USER_ID);
            builder.userId(userId)
                    .userName(stringAttr(request, ATTR_USERNAME))
                    .realName(stringAttr(request, ATTR_USERNAME));

            Object roles = request.getAttribute(ATTR_ROLES);
            if (roles instanceof List) {
                @SuppressWarnings("unchecked")
                List<String> roleCodeList = (List<String>) roles;
                builder.roleCode(roleCodeList);
            } else {
                builder.roleCode(Collections.<String>emptyList());
            }

            // 角色主键（sys_role.id）：宿主 JWT 里没有，按 userId 查 sys_user_role 得到。
            // sys_role_index.role_id 的口径是主键，因此这一步是「角色→指标」授权查询的前提。
            List<String> roleIds = resolveRoleIds(userId);
            builder.roleIdList(roleIds);
            // role 字段是源工程遗留契约：内容是角色主键列表的 JSON 数组字符串
            // （源实现 IndexConfigServiceImpl#getIndexIdListByRoleId 用 JSON.parseArray(role, String.class) 消费）。
            // 早期实现误塞了 roleCode（如 "admin"），与 sys_role_index.role_id 的口径不符，
            // 且会让 fastjson 抛 "field null expect '[', but error ... column 2admin"（冒烟实测 500，已修正）。
            builder.role(roleIds.isEmpty() ? "" : JSON.toJSONString(roleIds));
        } catch (Exception e) {
            log.warn("agent 模块解析当前调用者上下文失败，将使用空上下文", e);
            return emptyModel(builder);
        }
        return builder.build();
    }

    private static ApiContextModel emptyModel(ApiContextModel.ApiContextModelBuilder builder) {
        return builder.userId("").userName("").realName("")
                .roleCode(Collections.<String>emptyList())
                .roleIdList(Collections.<String>emptyList())
                .role("")
                .build();
    }

    /**
     * 按用户主键查角色主键列表
     *
     * <p>查不到或查库失败都返回空列表而<b>不抛异常</b>：本方法服务于"权限过滤"，
     * 权限过滤的技术性失败不应让整个接口 500（该放行还是该拦断由调用方按业务语义决定）。</p>
     */
    private static List<String> resolveRoleIds(String userId) {
        if (userId == null || userId.trim().isEmpty()) {
            return Collections.emptyList();
        }
        try {
            Long uid = Long.valueOf(userId.trim());
            AgentRoleMapper mapper = AgentSpringContext.getBean(AgentRoleMapper.class);
            List<Long> roleIds = mapper.selectRoleIdsByUserId(uid);
            if (roleIds == null || roleIds.isEmpty()) {
                return Collections.emptyList();
            }
            return roleIds.stream().map(String::valueOf).collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("agent 模块按 userId 解析角色主键失败，userId={}", userId, e);
            return Collections.emptyList();
        }
    }

    private static String stringAttr(HttpServletRequest request, String name) {
        Object v = request.getAttribute(name);
        return v == null ? "" : String.valueOf(v);
    }
}
