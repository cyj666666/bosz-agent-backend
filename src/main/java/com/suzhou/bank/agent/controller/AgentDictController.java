package com.suzhou.bank.agent.controller;

import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.dict.DictItemRow;
import com.suzhou.bank.agent.dict.DictRow;
import com.suzhou.bank.agent.mapper.AgentDictMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * agent 模块 — 数据字典查询接口
 *
 * <h3>为什么需要这个 Controller</h3>
 * <p>源工程前端「知识库配置管理 → 配置参数（黑盒参数）」页面有两个下拉依赖宿主通用字典能力：</p>
 * <ul>
 *   <li>{@code dictList()} → {@code GET /sys/dict/list}，取 {@code result.records} 作为「关联数据字典」下拉；</li>
 *   <li>{@code ajaxGetDictItems(code)} → {@code GET /sys/dict/getDictItems/{code}}，取 {@code result[0].fieldAttr}
 *       写入参数配置的 {@code relateDictValue}。</li>
 * </ul>
 * <p>这两个都是 <b>JeecgBoot 的 sys 模块接口</b>，不在本次 agent 模块移植范围内（宿主没有对应 Controller），
 * 但 agent 模块自己已经有 {@code sys_dict} / {@code sys_dict_item} 两张表、{@code AgentDictMapper}
 * 与 {@code AgentDictCache}。此处在<b>不引入 Jeecg 字典 Service 体系</b>的前提下，
 * 用 agent 自己的 Mapper 把这两个只读查询补出来。</p>
 *
 * <h3>路径约定</h3>
 * <p>挂到 {@code /api/agent/sys/dict} 下（与 {@code SysCategoryController} 的 {@code /api/agent/sys/category}
 * 同风格）。前端 axios baseURL 为 {@code /api}，故前端相对路径写 {@code /agent/sys/dict/...}。</p>
 *
 * <h3>与源工程的口径一致性</h3>
 * <p>{@code /list} 不过滤 {@code del_flag}、{@code /getDictItems} 只取 {@code status = 1} 的项——
 * 与源实现（{@code SysDictServiceImpl}）逐条对齐，避免下拉项与取值分支和源系统不一致。</p>
 */
@Slf4j
@RestController
@RequestMapping("/api/agent/sys/dict")
@RequiredArgsConstructor
@Tag(name = "agent-数据字典", description = "agent 模块数据字典只读查询（黑盒参数配置的下拉依赖）")
public class AgentDictController {

    private final AgentDictMapper agentDictMapper;

    /**
     * 字典主表列表
     *
     * <p>返回结构与源工程 {@code /sys/dict/list} 保持同形状：{@code data.records}。</p>
     */
    @Operation(summary = "字典列表", description = "对应源工程 /sys/dict/list，返回 data.records")
    @GetMapping("/list")
    public AgentResult<Map<String, Object>> list() {
        List<DictRow> rows = agentDictMapper.selectDictList();
        // 源前端取的是 res.result.records，这里保持同形状，前端无需为两个后端写两套解析
        Map<String, Object> data = new HashMap<>(2);
        data.put("records", rows);
        data.put("total", rows.size());
        return AgentResult.OK(data);
    }

    /**
     * 按字典编码取字典项（含 {@code fieldAttr}）
     *
     * <p>源前端取值：{@code res.result[0].fieldAttr} → 存为 {@code relateDictValue}。</p>
     */
    @Operation(summary = "字典项查询", description = "对应源工程 /sys/dict/getDictItems/{code}")
    @GetMapping("/getDictItems/{dictCode}")
    public AgentResult<List<DictItemRow>> getDictItems(@PathVariable("dictCode") String dictCode) {
        return AgentResult.OK(agentDictMapper.selectEnabledItemsByDictCode(dictCode));
    }
}
