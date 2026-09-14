package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.SysRoleKnowledgeEntity;

import java.util.List;

/**
 * @Description: 角色知识库权限表
 * @Author: jeecg-boot
 * @Date:   2025-01-16
 * @Version: V1.0
 */
public interface ISysRoleKnowledgeService extends IService<SysRoleKnowledgeEntity> {

    List<String> getKnowledgeIdListByRoleId(List<String> roleIdList);

    void saveRoleKnowledge(String roleId, String permissionIds, String lastPermissionIds);
}
