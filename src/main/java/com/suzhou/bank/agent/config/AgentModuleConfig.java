package com.suzhou.bank.agent.config;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * agent 模块装配入口
 *
 * <p><b>为什么要有这个类</b>：agent 模块要求与宿主解耦，因此不能去改主类上的
 * {@code @MapperScan("com.suzhou.bank.mapper")}。这里用独立的 {@code @MapperScan}
 * 覆盖 agent 自己的 Mapper 包，实现"零侵入宿主启动类"。</p>
 *
 * <p><b>扫描范围为什么是 {mapper} 包而不是整个 agent 包</b>（2026-09-14 冒烟后修正）：
 * 原实现写的是 {@code basePackages = "com.suzhou.bank.agent"} 加
 * {@code annotationClass = Mapper.class}，即"扫整个 agent 包、但只认带 {@code @Mapper} 的接口"。
 * 这个约定要求<b>每个 Mapper 都必须手写 {@code @Mapper} 注解</b>，
 * 而源工程 amar-agent-server 的 Mapper <b>是不写该注解的</b>——
 * 于是每次批量移植 Mapper，都会静默漏掉一批（实测 39 个 Mapper 中只有 15 个带注解），
 * 症状是启动期报 {@code NoSuchBeanDefinitionException: ...Mapper}，
 * 且一次只暴露一个，需反复重启才能排完。</p>
 *
 * <p>现在改为<b>把边界写在包名上</b>：{@code com.suzhou.bank.agent.mapper} 是专属的 Mapper 包，
 * 包内不会出现 Service 接口（已核对：包内 39 个接口全部 {@code extends BaseMapper}），
 * 所以按包扫描既准确又不需要注解约束。原有的 {@code @Mapper} 注解<b>予以保留</b>——
 * 它是显式的自解释标记，与包名约束形成双保险。</p>
 *
 * <p><b>为什么还要指定 {@code nameGenerator}</b>：MyBatis 默认用「类名首字母小写」当 Bean 名，
 * 该名字在容器内必须全局唯一。agent 与宿主各自有 Mapper 包，实测有 1 个同名
 * （{@code LargeModelConfigMapper}），不加前缀就会抛
 * {@code ConflictingBeanDefinitionException}。详见 {@link AgentMapperBeanNameGenerator}。</p>
 */
@Configuration
@EnableConfigurationProperties(AgentProperties.class)
@MapperScan(basePackages = "com.suzhou.bank.agent.mapper",
        nameGenerator = AgentMapperBeanNameGenerator.class)
public class AgentModuleConfig {
}
