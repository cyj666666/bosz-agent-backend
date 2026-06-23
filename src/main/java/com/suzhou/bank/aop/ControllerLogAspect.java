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

@Slf4j
@Aspect
@Component
public class ControllerLogAspect {

    @Pointcut("execution(* com.suzhou.bank.controller..*(..))")
    public void controllerPointcut() {}

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
