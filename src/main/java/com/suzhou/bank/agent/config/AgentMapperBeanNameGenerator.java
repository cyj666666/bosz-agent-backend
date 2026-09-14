package com.suzhou.bank.agent.config;

import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.support.BeanDefinitionRegistry;
import org.springframework.context.annotation.AnnotationBeanNameGenerator;

/**
 * agent 模块 Mapper 的 Bean 名生成器——统一加 {@code agent} 前缀
 *
 * <p><b>为什么需要它</b>：MyBatis 默认用「类名首字母小写」作为 Mapper 的 Bean 名，
 * 而这个名字在<b>整个 Spring 容器内必须唯一</b>。agent 模块与宿主各自有独立的 Mapper 包
 * （{@code com.suzhou.bank.agent.mapper} / {@code com.suzhou.bank.mapper}），
 * 两边一旦出现同名 Mapper，注册时就会抛
 * {@code ConflictingBeanDefinitionException}，且<b>一次只报一个</b>，排查成本很高。</p>
 *
 * <p>实测（2026-09-14 冒烟）：39 个 agent Mapper 与 17 个宿主 Mapper 有 <b>1 个</b>同名——
 * {@code LargeModelConfigMapper}（两边都叫这个名）。加前缀后与宿主彻底隔离，
 * 将来再出现同名 Mapper 也不会冲突。</p>
 *
 * <p><b>为什么改名是安全的</b>：agent 模块的 Mapper 全部是<b>按类型注入</b>
 * （{@code private final XxxMapper xxxMapper;}），没有任何一处按名称引用
 * （已核对：模块内 {@code @Qualifier} 只用于线程池，未用于 Mapper）。
 * 因此 Bean 名从 {@code largeModelConfigMapper} 变成
 * {@code agentLargeModelConfigMapper} 对业务代码完全透明。</p>
 */
public class AgentMapperBeanNameGenerator extends AnnotationBeanNameGenerator {

    /** Bean 名前缀，与宿主 Mapper 隔离 */
    private static final String PREFIX = "agent";

    @Override
    public String generateBeanName(BeanDefinition definition, BeanDefinitionRegistry registry) {
        return PREFIX + super.generateBeanName(definition, registry);
    }
}
