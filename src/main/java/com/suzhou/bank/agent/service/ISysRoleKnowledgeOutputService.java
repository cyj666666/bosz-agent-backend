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
}
