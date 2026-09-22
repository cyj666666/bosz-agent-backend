package com.suzhou.bank.agent.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * agent 模块配置（前缀 {@code agent}）
 *
 * <p><b>为什么独立一套配置</b>：agent 模块要能整体搬迁，配置项必须自成命名空间，
 * 避免与宿主既有配置键（如 {@code report.ai-analysis.*}）冲突或互相牵连。</p>
 *
 * <p>示例（application-dev.yml）：
 * <pre>
 * agent:
 *   lm-code: agent-rule-parse          # 检查项解析用的大模型，独立于报告模块
 *   rule-parse-prompt: classpath:prompts/检查项解析_提示词设计_v1.md
 *   indicator-catalog-limit: 200       # 指标清单粗筛上限，0 表示不粗筛、全量喂给模型
 * </pre>
 * </p>
 */
@Data
@ConfigurationProperties(prefix = "agent")
public class AgentProperties {

    /**
     * 检查项解析使用的大模型 lm_code（对应 {@code large_model_config.lm_code}）
     *
     * <p><b>刻意不复用</b> {@code report.ai-analysis.lm-code}：两者用途不同，
     * 共用会导致调一处影响另一处（改温度、换模型都会互相波及）。</p>
     */
    private String lmCode;

    /** 检查项解析的提示词资源路径（classpath: 或 file: 前缀） */
    private String ruleParsePrompt = "classpath:prompts/rule-parse-prompt.txt";

    /**
     * 指标清单粗筛上限
     *
     * <p>把全部指标塞进提示词会超 token 且稀释模型注意力，因此先本地按关键词粗筛出候选短名单。
     * 设为 0 表示不做粗筛、全量喂给模型（指标库规模很小时可这么用）。</p>
     *
     * <p><b>注意</b>：粗筛是"宁可多带不可漏带"，召回率是这套方案的单点风险，上线前要用真实规则集验证。</p>
     */
    private int indicatorCatalogLimit = 200;

    /** 大模型调用超时（毫秒）。检查项解析涉及长文本生成，默认 60s */
    private int timeoutMillis = 60000;

    /**
     * 是否启用「角色 → 指标」权限过滤（默认 <b>true</b>）
     *
     * <p>源工程 <code>IndexConfigServiceImpl</code> 在取指标分组树/指标列表前，
     * 会先按当前用户角色去 <code>sys_role_index</code> 查「该角色被授权的指标/分组节点」，
     * 查不到（列表为空）时<b>直接返回空结果</b>（fail-closed）。</p>
     *
     * <p>本工程启用该过滤，语义上是"用户只能看到自己角色被授权的指标"。
     * 为避免管理员被误挡，另有 {@link #indexRoleFilterBypassRoles} 做超管放行。</p>
     *
     * <p><b>⚠️ 前提</b>：过滤要真正生效，<code>sys_role_index</code> 必须有数据，
     * 且 <code>index_params</code> / <code>index_base_group</code> 必须有指标基础数据；
     * 二者缺任一个，页面都会是空的——但这是「数据没配」而非「代码坏了」。</p>
     *
     * <p>对应配置：<code>agent.index.role-filter-enabled</code></p>
     */
    private boolean indexRoleFilterEnabled = true;

}
