package com.suzhou.bank.agent.config;

import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.common.AgentResult;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * agent 模块异常处理
 *
 * <p><b>为什么必须补这个类</b>：平移过来的业务代码里有大量
 * {@code throw new JeecgBootException("未查询到相关数据！")} 这类<b>业务异常</b>
 * （已改名 {@link AgentBizException}）。源工程能返回规范的错误报文，
 * 是因为 JeecgBoot 自带一个全局异常处理器把 {@code JeecgBootException} 转成了 {@code Result}。
 * 本次迁移没有平移那个处理器，导致这些原本"预期内的业务失败"变成了
 * 裸的 {@code HTTP 500} 错误页（冒烟测试实测：{@code /queryRelateIndexInfo} 传不存在的
 * paramNo 时返回的是 Spring 默认错误页而不是业务报文）。</p>
 *
 * <p><b>处理策略</b>：</p>
 * <ul>
 *   <li>只拦截 {@link AgentBizException}，<b>不拦截其它异常</b>——泛化的
 *       {@code @ExceptionHandler(Exception.class)} 会把宿主模块的异常也一起吞掉，
 *       属于越界且会掩盖真实缺陷。</li>
 *   <li>返回 HTTP 200 + {@code code=500} 的业务报文，与源工程（Jeecg 的
 *       {@code Result.error(msg)}）以及 agent 模块既有的失败约定保持一致。</li>
 *   <li>日志用 WARN 而不是 ERROR：这类异常通常是入参不存在等预期内的业务失败，
 *       打成 ERROR 会污染监控告警。</li>
 * </ul>
 */
@Slf4j
@RestControllerAdvice
public class AgentExceptionHandler {

    @ExceptionHandler(AgentBizException.class)
    public AgentResult<?> handleAgentBizException(AgentBizException e) {
        log.warn("agent 业务异常：{}", e.getMessage());
        return AgentResult.fail(e.getMessage());
    }
}
