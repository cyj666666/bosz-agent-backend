package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.entity.SysRoleKnowledgeOutputEntity;
import com.suzhou.bank.agent.mapper.SysRoleKnowledgeOutputMapper;
import com.suzhou.bank.agent.service.ISysRoleKnowledgeOutputService;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * @Description: 角色知识库输出要求权限表
 * @Author: jeecg-boot
 * @Date:   2026-01-04
 * @Version: V1.0
 */
@Service
public class SysRoleKnowledgeOutputServiceImpl extends ServiceImpl<SysRoleKnowledgeOutputMapper, SysRoleKnowledgeOutputEntity> implements ISysRoleKnowledgeOutputService {


    @Override
    public void saveRoleKnowledgeOutput(String roleId, String groupId, String paramIds) {
        // 先删除旧数据
        LambdaUpdateWrapper<SysRoleKnowledgeOutputEntity> wrapper = Wrappers.lambdaUpdate();
        wrapper.eq(SysRoleKnowledgeOutputEntity::getRoleId, roleId);
        wrapper.eq(SysRoleKnowledgeOutputEntity::getGroupId, groupId);
        remove(wrapper);

        // 插入新数据
        if (StringUtils.isNotBlank(paramIds)) {
            String[] paramIdArray = paramIds.split(",");
            List<SysRoleKnowledgeOutputEntity> list = new ArrayList<>();
            for (String paramId : paramIdArray) {
                SysRoleKnowledgeOutputEntity entity = new SysRoleKnowledgeOutputEntity();
                entity.setRoleId(roleId);
                entity.setGroupId(groupId);
                entity.setKnowledgeId(paramId);
                entity.setOperateDate(new Date());
                list.add(entity);
            }
            saveBatch(list);
        }
    }

    @Override
    public boolean checkKnowledgeOutputAuth(List<String> roleIdList, String paramId) {
        if (roleIdList == null || roleIdList.isEmpty()) {
            return false;
        }
        // 检查角色是否有知识库输出要求权限
        LambdaUpdateWrapper<SysRoleKnowledgeOutputEntity> wrapper = Wrappers.lambdaUpdate();
        wrapper.in(SysRoleKnowledgeOutputEntity::getRoleId, roleIdList);
        wrapper.eq(SysRoleKnowledgeOutputEntity::getKnowledgeId, paramId);
        return count(wrapper) > 0;
    }
}
