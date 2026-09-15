package com.suzhou.bank.agent.model.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.io.Serializable;

/**
 * 智能体下拉项（{@code agent_config} 的轻量投影）
 *
 * <p><b>存在的理由</b>：源工程「新建/编辑知识库」的「关联 agent」下拉调
 * {@code /agent/agentConfig/list}，只用到每一项的 {@code id} 与 {@code agentName}。
 * 而 {@code agent_config} 表带有 {@code agent_prompt} / {@code agent_param_tpl} 两个 TEXT 大字段，
 * 若直接返回整表（源工程前端一次取 2000 条），单次响应会膨胀到几百 KB 且全是无用内容。
 * 故这里只投影下拉真正需要的列。</p>
 *
 * <p>字段与源工程前端读法对齐：源 {@code KnownEditModal.vue} 用
 * {@code label: item.agentName} / {@code value: item.id + ''}，
 * 即「显示名称、存 id」，故此处的 {@code id} 是<b>存库值</b>，{@code agentName} 是<b>显示值</b>。</p>
 */
@Data
public class AgentOptionVO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 主键（知识库表 {@code agentId} 存的就是它） */
    @Schema(description = "智能体主键（存库值）")
    private Long id;

    /** 智能体名称（下拉显示值） */
    @Schema(description = "智能体名称")
    private String agentName;

    /** 智能体编码（同名时用于区分） */
    @Schema(description = "智能体编码")
    private String agentCode;

    /** 智能体类型 */
    @Schema(description = "智能体类型")
    private String agentStatus;

    /** 大模型编码 */
    @Schema(description = "大模型编码")
    private String largeModelCode;
}
