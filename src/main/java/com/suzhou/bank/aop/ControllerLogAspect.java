package com.suzhou.bank.aop;

import com.alibaba.fastjson2.JSON;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;

/**
 * Controller 请求日志切面
 * <p>拦截所有 Controller 方法调用，记录请求方法、URL、参数、
 * 执行耗时和结果状态，用于日常运维和问题排查。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Aspect
@Component
public class ControllerLogAspect {

    /**
     * 切点：匹配 controller 包下所有 public 方法
     */
    @Pointcut("execution(* com.suzhou.bank.controller..*(..))")
    public void controllerPointcut() {}

    /**
     * 环绕通知：记录入参 → 执行方法 → 记录耗时和结果
     */
    @Around("controllerPointcut()")
    public Object around(ProceedingJoinPoint joinPoint) throws Throwable {
        ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        String httpMethod = "UNKNOWN";
        String uri = "UNKNOWN";
        if (attrs != null) {
            HttpServletRequest req = attrs.getRequest();
            httpMethod = req.getMethod();
            uri = req.getRequestURI();
        }

        String className = joinPoint.getSignature().getDeclaringTypeName();
        String methodName = joinPoint.getSignature().getName();
        Object[] args = joinPoint.getArgs();

        // 入参日志（截断过长参数）
        String params = args != null && args.length > 0 ? JSON.toJSONString(args) : "";
        if (params.length() > 500) {
            params = params.substring(0, 500) + "...(truncated)";
        }

        log.info("[{}] {} {}.{} | params={}", httpMethod, uri, className, methodName, params);

        long start = System.currentTimeMillis();
        try {
            Object result = joinPoint.proceed();
            long elapsed = System.currentTimeMillis() - start;
            log.info("[{}] {} {}.{} | elapsed={}ms | SUCCESS", httpMethod, uri, className, methodName, elapsed);
            return result;
        } catch (Throwable e) {
            long elapsed = System.currentTimeMillis() - start;
            log.error("[{}] {} {}.{} | elapsed={}ms | FAILED | error={}", httpMethod, uri, className, methodName, elapsed, e.getMessage());
            throw e;
        }
    }
}
