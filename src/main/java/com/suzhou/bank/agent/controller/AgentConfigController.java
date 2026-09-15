package com.suzhou.bank.agent.controller;

import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.mapper.AgentConfigMapper;
import com.suzhou.bank.agent.model.vo.AgentOptionVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * agent 模块 — 智能体配置查询接口
 *
 * <h3>为什么需要这个 Controller</h3>
 * <p>源工程「新建/编辑知识库」表单里的「关联 agent」是一个下拉，
 * 选项来自 {@code getAgentList()} → {@code POST /agent/agentConfig/list}
 * （源 {@code KnownEditModal.vue:195}，映射为 {@code label: agentName} / {@code value: id}）。</p>
 *
 * <p><b>关键事实（2026-09-15 连库实测更正）</b>：本库（{@code as_agent}，实测共 103 张表）
 * <b>并没有 {@code agent_config} 表</b>。{@code sql/agent/agent_gauss_ddl.sql} 里的
 * {@code CREATE TABLE agent_config} 来自源库的完整 DDL，但本工程实际只建了 39 张业务表
 * （外加报告 / 采集 / 数据接入等），该表不在其中。所以这里与 {@code AgentDictController}
 * 的情形<b>不同</b>——那两张字典表是真实存在的，而 agent_config 不是。</p>
 *
 * <p>因此本接口对「表不存在」做了<b>显式容错</b>：记 WARN 并返回空列表，不向前端抛 500。
 * 前端在选项为空时会降级为可手填（见 {@code KnowledgeEditorModal}），不阻塞填单；
 * 若后续决定建表并录入智能体，本接口无需任何改动即可直接生效。</p>
 *
 * <h3>关于 agentId 字段的现状（重要）</h3>
 * <p>需要如实说明：在源工程后端（{@code amar-agent-server}）中，
 * {@code KnowledgeBaseParamsEntity.agentId} <b>只有字段声明与读写透传，没有任何业务读取</b>
 * （全仓 {@code getAgentId()} / {@code setAgentId()} 零调用，也没有任何 QueryWrapper 以它作条件）。
 * 也就是说该字段目前是「只存不读」的归属标记。</p>
 * <p>这解释了为什么它<b>不影响主链路功能</b>，但同时也说明：
 * <b>不该因此就把它降级成"手填一串数字"</b>——它对使用者的语义是"这个知识库属于哪个智能体"，
 * 填错不会报错但会误导后人。恢复成下拉（可读的名称 → 存 id）才是与源系统一致的形态。</p>
 *
 * <h3>路径约定</h3>
 * <p>挂到 {@code /api/agent/agentConfig} 下，与源工程 {@code /agent/agentConfig/xxx} 同名，
 * 便于后续把源工程其余 {@code agentConfig/*} 接口（queryById / getRelaIndexList 等）按需补齐。
 * 前端 axios baseURL 为 {@code /api}，故前端相对路径写 {@code /agent/agentConfig/list}。</p>
 */
@Slf4j
@RestController
@RequestMapping("/api/agent/agentConfig")
@RequiredArgsConstructor
@Tag(name = "agent-智能体配置", description = "智能体配置只读查询（知识库「关联 agent」下拉依赖）")
public class AgentConfigController {

    private final AgentConfigMapper agentConfigMapper;

    /**
     * 智能体列表（下拉用）
     *
     * <p>返回结构对齐本工程其它分页接口的形状：{@code data.list} + {@code data.totalCount}，
     * 让前端用同一套解包逻辑（{@code res.list}）即可，无需为该接口特判。</p>
     *
     * <p>注意：源工程前端读的是 {@code res.result.list}，本工程统一返回体把业务数据放在
     * {@code data} 而非 {@code result}（见 {@link AgentResult} 的说明），前端已按 {@code data} 适配。</p>
     */
    @Operation(summary = "智能体列表", description = "对应源工程 /agent/agentConfig/list，供「关联 agent」下拉使用")
    @PostMapping("/list")
    public AgentResult<Map<String, Object>> list() {
        List<AgentOptionVO> rows;
        try {
            rows = agentConfigMapper.selectAgentOptions();
        } catch (Exception e) {
            // 本库当前没有 agent_config 表（见类注释的实测说明），查询必然失败。
            // 刻意不把异常抛给前端：让下拉安静地变空、由前端降级为可手填，
            // 比给用户弹一个 500 更符合"不阻塞填单"的目标。
            log.warn("智能体列表查询失败（本库可能尚未创建 agent_config 表）: {}", e.getMessage());
            rows = Collections.emptyList();
        }
        Map<String, Object> data = new HashMap<>(2);
        data.put("list", rows);
        data.put("totalCount", rows.size());
        return AgentResult.ok(data);
    }
}