package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.SysRoleKnowledgeOutputEntity;

import java.util.List;

/**
 * @Description: 角色知识库输出要求权限表
 * @Author: jeecg-boot
 * @Date:   2026-01-04
 * @Version: V1.0
 */
public interface ISysRoleKnowledgeOutputService extends IService<SysRoleKnowledgeOutputEntity> {

    void saveRoleKnowledgeOutput(String roleId, String groupId, String paramIds);

    boolean checkKnowledgeOutputAuth(List<String> roleIdList, String paramId);

    /**
     * 按「角色 + 知识分组」查已授权的输出要求 id 列表
     *
     * <p>供「角色数据授权」配置页回显，并作为差分保存时的 lastPermissionIds 来源。
     * （{@code saveRoleKnowledgeOutput} 是"整体覆盖"语义，与另两套的差分会话不同。）</p>
     *
     * @param roleId  角色主键（sys_role.id）
     * @param groupId 知识分组 id
     * @return 已授权的输出要求 id 列表；无授权时返回空列表
     */
    List<String> getKnowledgeIdListByRoleIdAndGroup(String roleId, String groupId);

    /**
     * 查该角色**全部**已授权的输出要求 id（跨所有知识分组）
     *
     * <p><b>为什么需要它</b>：配置页的「知识输出授权」原本是"左选分组 → 右勾知识库"，
     * 按 `(roleId, groupId)` 一小组一小组配；2026-09-22 客户要求改成与「指标 / 知识」
     * 两个 Tab 一致的**树形整体勾选**（父级可全选），因此需要一次拿全量做回显。</p>
     *
     * @param roleId 角色主键（{@code sys_role.id}）
     * @return 已授权的输出要求 id 列表（去重前的原始值）；无授权返回空列表
     */
    List<String> getAllKnowledgeIdListByRoleId(String roleId);

    /**
     * **整体覆盖**该角色在**所有知识分组**下的输出要求授权
     *
     * <p>语义：先按 {@code role_id} 全删，再按传入的 id 列表逐条插入
     * （每条按 `knowledge_base_params.groupid` 反查所属分组写回 {@code group_id}，
     * 保持与 {@link #saveRoleKnowledgeOutput} 一致的存储结构）。</p>
     *
     * <p>⚠️ 页面侧必须保证传入的是**全量**（树加载完整）—— 缺失的 id 会被当作"取消授权"删掉。</p>
     *
     * @param roleId   角色主键
     * @param paramIds 逗号分隔的输出要求 id；空/空白表示清空该角色的全部输出授权
     */
    void saveRoleKnowledgeOutputAll(String roleId, String paramIds);
}
