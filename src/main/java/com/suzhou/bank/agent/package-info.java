/**
 * agent 模块 —— 自包含的智能体配置域
 *
 * <h3>模块边界（重要）</h3>
 * <ul>
 *   <li><b>不依赖</b> {@code com.suzhou.bank.service} / {@code com.suzhou.bank.entity} /
 *       {@code com.suzhou.bank.mapper} 等宿主业务包；</li>
 *   <li><b>自带</b>统一返回体 {@link com.suzhou.bank.agent.common.AgentResult}，
 *       不改动宿主的 {@code com.suzhou.bank.common.Result}；</li>
 *   <li><b>自带</b>Mapper 扫描（见 {@link com.suzhou.bank.agent.config.AgentModuleConfig}），
 *       不改动主类的 {@code @MapperScan}；</li>
 *   <li>接口路径统一挂 {@code /api/agent/**}，复用宿主既有的 {@code AuthInterceptor} 鉴权，
 *       无需新增拦截器。</li>
 * </ul>
 *
 * <h3>搬迁/合并</h3>
 * 整个 {@code com.suzhou.bank.agent} 包可整体复制到目标工程，只需保证：
 * <ol>
 *   <li>目标工程有 Spring Boot + MyBatis-Plus + Lombok；</li>
 *   <li>Spring 能扫到本包（若目标工程的主类不在 {@code com.suzhou.bank} 下，
 *       需在启动类加 {@code scanBasePackages}）；</li>
 *   <li>数据库已建好 agent 相关表（见 {@code src/main/resources/sql/agent/}）。</li>
 * </ol>
 *
 * <p>来源：安硕 amar-agent-server 的「指标配置 / 知识配置管理 / 智策引擎」三个模块，
 * 详见 {@code src/main/resources/prompts/检查项解析_提示词设计_v1.md} 与迁移清单。</p>
 */
package com.suzhou.bank.agent;
