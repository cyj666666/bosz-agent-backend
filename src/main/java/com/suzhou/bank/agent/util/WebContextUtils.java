package com.suzhou.bank.agent.util;

import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;

/**
 * Web 上下文工具
 *
 * <p>替代源工程的 {@code org.jeecg.common.util.SpringContextUtils#getHttpServletRequest()}，
 * 只保留取当前请求这一项能力，不引入 JeecgBoot 的其它 Bean 查找逻辑。</p>
 *
 * <p><b>注意</b>：{@code @Async} 线程、定时任务等非 HTTP 线程里取不到请求，
 * 本方法会<b>抛异常</b>（与源实现一致，源实现同样会抛），
 * 调用方需自行 try/catch —— 源工程 {@code SysRoleIndexServiceImpl} 就是这么处理的。</p>
 */
public class WebContextUtils {

    /**
     * 取当前线程绑定的请求
     *
     * @throws IllegalStateException 当前线程不在 HTTP 请求上下文时
     */
    public static HttpServletRequest getHttpServletRequest() {
        RequestAttributes attributes = RequestContextHolder.getRequestAttributes();
        if (attributes instanceof ServletRequestAttributes) {
            return ((ServletRequestAttributes) attributes).getRequest();
        }
        throw new IllegalStateException("当前线程不在 HTTP 请求上下文中，无法获取 HttpServletRequest");
    }
}
