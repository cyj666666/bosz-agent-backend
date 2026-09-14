package com.suzhou.bank.agent.config;

import com.suzhou.bank.agent.common.AgentBizException;
import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.stereotype.Component;

/**
 * agent 模块的 Spring 上下文持有者
 *
 * <p><b>为什么需要它</b>：动态取数引擎（{@code DynamicDBUtil}、{@code DataSourceCachePool}）
 * 是按「静态方法」设计的（源工程如此，被业务代码广泛静态调用），
 * 但它们内部又需要拿到 Spring 容器里的 Bean，只能通过静态上下文桥接。</p>
 *
 * <p>替代源工程的 {@code org.jeecg.common.util.SpringContextUtils}，
 * 使 agent 模块不依赖 JeecgBoot。</p>
 *
 * <p><b>取不到 Bean 时直接抛异常而不是返回 null</b>：
 * 配置缺失属于装配期错误，静默返回 null 会让问题推迟到运行期、且表现为"数据源为空"这种误导性的症状。</p>
 */
@Component
public class AgentSpringContext implements ApplicationContextAware {

    private static ApplicationContext applicationContext;

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        AgentSpringContext.applicationContext = applicationContext;
    }

    public static ApplicationContext getApplicationContext() {
        return applicationContext;
    }

    /**
     * 按类型取 Bean，取不到即抛异常。
     */
    /**
     * 按「Bean 名称 + 类型」取 Bean（兼容源工程 {@code SpringContextUtils.getBean(name, clazz)} 的用法）
     *
     * <p>典型场景：数据源取数按 {@code scriptType}（即 {@code @Component("Sql")} 这类 Bean 名）
     * 动态选择 {@code DataSetBuilder} 实现。</p>
     */
    public static <T> T getBean(String name, Class<T> clazz) {
        if (applicationContext == null) {
            throw new AgentBizException("agent 模块 Spring 上下文尚未初始化，无法获取 Bean：" + name);
        }
        try {
            return applicationContext.getBean(name, clazz);
        } catch (BeansException e) {
            throw new AgentBizException("agent 模块未找到名为 " + name + " 的 Bean（类型 " + clazz.getName() + "）", e);
        }
    }
    public static <T> T getBean(Class<T> clazz) {
        if (applicationContext == null) {
            throw new AgentBizException("agent 模块 Spring 上下文尚未初始化，无法获取 Bean：" + clazz.getName());
        }
        try {
            return applicationContext.getBean(clazz);
        } catch (BeansException e) {
            throw new AgentBizException("agent 模块未找到所需 Bean：" + clazz.getName()
                    + "，请检查对应实现类是否已被 Spring 扫描到", e);
        }
    }
}
