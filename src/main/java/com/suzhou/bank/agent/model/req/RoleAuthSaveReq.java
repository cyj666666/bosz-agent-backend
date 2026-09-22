package com.suzhou.bank.agent.model.req;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import java.util.List;

/**
 * 角色「数据授权」保存请求 —— 指标 / 知识 / 知识输出 三套共用
 *
 * <p><b>为什么用 List 而不是逗号串</b>：前端勾选树节点后天然是数组，直接传数组避免前端自己拼串；
 * 由 Controller 统一 {@code String.join(",")} 后再交给 Service
 * （Service 内部走 {@code ParamUtil.getDiff}，是逗号分隔语义）。</p>
 *
 * <p><b>差分保存</b>：{@code permissionIds} = 保存后应授权的<b>全量</b>列表，
 * {@code lastPermissionIds} = 保存<b>前</b>的列表；Service 用两者求差得到"要新增/要删除"的行，
 * 因此前端必须把「打开页面时查到的列表」原样回传。</p>
 *
 * <p><b>2026-09-22 新增</b>：配合「系统管理 → 数据授权」菜单（admin-only），
 * 把此前<b>没有任何界面入口</b>的 {@code sys_role_index} / {@code sys_role_knowledge} /
 * {@code sys_role_knowledge_output} 三套授权显性化。</p>
 *
 * @author 曹陆宇
 * @since 1.0.0
 */
@Data
public class RoleAuthSaveReq {

    /** 角色主键（{@code sys_role.id}） */
    @NotBlank(message = "角色ID不能为空")
    private String roleId;

    /**
     * 保存后「应授权」的全量 id 列表。
     * <p>三套各自口径：指标 = {@code index_params.paramno} 或 {@code index_base_group.groupid}
     * （{@code sys_role_index.index_id} 混存两类）；知识 = 知识分组 id；
     * 知识输出 = 输出要求参数 id。</p>
     */
    private List<String> permissionIds;

    /** 保存前已授权的 id 列表（差分用；首次配置可传 {@code null} 或空） */
    private List<String> lastPermissionIds;

    /** 【仅知识输出授权使用】知识分组 id（{@code sys_role_knowledge_output.group_id}） */
    private String groupId;
}
