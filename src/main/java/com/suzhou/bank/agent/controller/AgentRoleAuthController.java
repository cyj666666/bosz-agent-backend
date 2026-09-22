package com.suzhou.bank.agent.controller;

import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.mapper.AgentRoleMapper;
import com.suzhou.bank.agent.model.req.RoleAuthSaveReq;
import com.suzhou.bank.agent.service.ISysRoleIndexService;
import com.suzhou.bank.agent.service.ISysRoleKnowledgeOutputService;
import com.suzhou.bank.agent.service.ISysRoleKnowledgeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.Collections;
import java.util.List;

/**
 * 角色「数据授权」配置 —— 指标 / 知识 / 知识输出 三套
 *
 * <p><b>为什么需要这个 Controller（2026-09-22）</b>：三套授权的 Service
 * （{@code saveRoleIndex} / {@code saveRoleKnowledge} / {@code saveRoleKnowledgeOutput}）
 * 在 agent 模块内<b>从未被任何 Controller 调用过</b>——即"过滤在生效、但没人能配"。
 * 实测：{@code sys_role_index} 0 行 ⇒ 非全通角色（如 khjl）进指标配置**指标树全空**。
 * 本 Controller 就是补上缺失的配置入口。</p>
 *
 * <p><b>⚠️ 权限归属：admin-only</b>。它在 {@code config/AuthInterceptor} 里与
 * {@code /api/user/**}、{@code /api/role/**} 同列，只有「菜单全通角色」能调。
 * <b>刻意不纳入</b>「能看菜单就能操作」那条统一规则 —— 它管的是"谁能看什么"，
 * 若能分配给普通角色就等于**提权**（自己给自己授权）。</p>
 *
 * <p><b>⚠️ 落库延迟</b>：{@code saveRoleIndex} / {@code saveRoleKnowledge} 带 {@code @Async}，
 * 接口返回时可能尚未提交；前端保存后需延迟或重查再校验
 * （{@code saveRoleKnowledgeOutput} 是同步的）。</p>
 *
 * @author 曹陆宇
 * @since 1.0.0
 */
@Slf4j
@Tag(name = "角色数据授权")
@RestController
@RequestMapping("/api/agent/roleAuth")
@RequiredArgsConstructor
public class AgentRoleAuthController {

    private final ISysRoleIndexService sysRoleIndexService;
    private final ISysRoleKnowledgeService sysRoleKnowledgeService;
    private final ISysRoleKnowledgeOutputService sysRoleKnowledgeOutputService;
    private final AgentRoleMapper agentRoleMapper;

    @Operation(summary = "角色数据授权-角色列表", description = "列出全部角色（含 menu_permissions），供配置页选择角色")
    @GetMapping("/roles")
    public AgentResult<?> roles() {
        return AgentResult.OK(agentRoleMapper.selectAllRoles());
    }

    @Operation(summary = "角色数据授权-查询指标授权",
            description = "返回该角色在 sys_role_index 已授权的 indexId 列表（前端回传作 lastPermissionIds）")
    @GetMapping("/index/{roleId}")
    public AgentResult<?> indexAuth(@PathVariable String roleId) {
        return AgentResult.OK(nullToEmpty(
                sysRoleIndexService.getIndexIdListByRoleId(Collections.singletonList(roleId))));
    }

    @Operation(summary = "角色数据授权-保存指标授权",
            description = "差分保存 sys_role_index（新增=permission-last，删除=last-permission）；Service 为 @Async，落库略有延迟")
    @PostMapping("/index")
    public AgentResult<?> saveIndex(@RequestBody @Valid RoleAuthSaveReq req) {
        sysRoleIndexService.saveRoleIndex(req.getRoleId(),
                join(req.getPermissionIds()), join(req.getLastPermissionIds()));
        return AgentResult.OK("保存成功");
    }

    @Operation(summary = "角色数据授权-查询知识授权",
            description = "返回该角色在 sys_role_knowledge 已授权的 knowledgeId（知识分组）列表")
    @GetMapping("/knowledge/{roleId}")
    public AgentResult<?> knowledgeAuth(@PathVariable String roleId) {
        return AgentResult.OK(nullToEmpty(
                sysRoleKnowledgeService.getKnowledgeIdListByRoleId(Collections.singletonList(roleId))));
    }

    @Operation(summary = "角色数据授权-保存知识授权",
            description = "差分保存 sys_role_knowledge；Service 为 @Async，落库略有延迟")
    @PostMapping("/knowledge")
    public AgentResult<?> saveKnowledge(@RequestBody @Valid RoleAuthSaveReq req) {
        sysRoleKnowledgeService.saveRoleKnowledge(req.getRoleId(),
                join(req.getPermissionIds()), join(req.getLastPermissionIds()));
        return AgentResult.OK("保存成功");
    }

    @Operation(summary = "角色数据授权-查询知识输出授权",
            description = "按「角色 + 知识分组」返回已授权的输出要求 id 列表")
    @GetMapping("/knowledgeOutput/{roleId}")
    public AgentResult<?> knowledgeOutputAuth(@PathVariable String roleId,
                                              @RequestParam String groupId) {
        return AgentResult.OK(nullToEmpty(
                sysRoleKnowledgeOutputService.getKnowledgeIdListByRoleIdAndGroup(roleId, groupId)));
    }

    @Operation(summary = "角色数据授权-保存知识输出授权",
            description = "整体覆盖「角色 + 知识分组」下的输出要求授权（同步落库）")
    @PostMapping("/knowledgeOutput")
    public AgentResult<?> saveKnowledgeOutput(@RequestBody @Valid RoleAuthSaveReq req) {
        if (StringUtils.isBlank(req.getGroupId())) {
            return AgentResult.error("groupId 不能为空");
        }
        sysRoleKnowledgeOutputService.saveRoleKnowledgeOutput(req.getRoleId(),
                req.getGroupId(), join(req.getPermissionIds()));
        return AgentResult.OK("保存成功");
    }

    /** null → 空列表：前端直接当数组用，省掉 null 判断（空列表 = 该角色无授权） */
    private static List<String> nullToEmpty(List<String> list) {
        return list == null ? Collections.<String>emptyList() : list;
    }

    /**
     * List → 逗号分隔串（Service 的 {@code ParamUtil.getDiff} 是逗号分隔语义）。
     * <p>{@code null} 原样返回 ⇒ 落到 {@code getDiff} 的 {@code isEmpty(diff)} 分支 ⇒ <b>本侧不参与差分</b>
     * （前端没传"变更前列表"时不会误删）。</p>
     */
    private static String join(List<String> list) {
        return list == null ? null : String.join(",", list);
    }
}
