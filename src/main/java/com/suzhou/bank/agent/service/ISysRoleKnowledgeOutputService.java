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
}
