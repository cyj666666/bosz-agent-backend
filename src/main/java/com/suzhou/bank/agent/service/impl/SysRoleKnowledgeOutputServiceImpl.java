package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.entity.KnowledgeBaseParamsEntity;
import com.suzhou.bank.agent.entity.SysRoleKnowledgeOutputEntity;
import com.suzhou.bank.agent.mapper.SysRoleKnowledgeOutputMapper;
import com.suzhou.bank.agent.service.IKnowledgeBaseParamsService;
import com.suzhou.bank.agent.service.ISysRoleKnowledgeOutputService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

/**
 * @Description: 角色知识库输出要求权限表
 * @Author: jeecg-boot
 * @Date:   2026-01-04
 * @Version: V1.0
 */
@Service
public class SysRoleKnowledgeOutputServiceImpl extends ServiceImpl<SysRoleKnowledgeOutputMapper, SysRoleKnowledgeOutputEntity> implements ISysRoleKnowledgeOutputService {

    /**
     * 「整体覆盖保存」时按 knowledgeId 反查所属分组（{@code knowledge_base_params.groupid}）——
     * 表结构要求 {@code group_id} 必须落库，而调用方（配置页树勾选）只提供知识库 id。
     */
    @Autowired
    private IKnowledgeBaseParamsService knowledgeBaseParamsService;


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
    public List<String> getKnowledgeIdListByRoleIdAndGroup(String roleId, String groupId) {
        LambdaQueryWrapper<SysRoleKnowledgeOutputEntity> wrapper = Wrappers.lambdaQuery();
        wrapper.select(SysRoleKnowledgeOutputEntity::getKnowledgeId);
        wrapper.eq(SysRoleKnowledgeOutputEntity::getRoleId, roleId);
        wrapper.eq(SysRoleKnowledgeOutputEntity::getGroupId, groupId);
        return list(wrapper).stream()
                .map(SysRoleKnowledgeOutputEntity::getKnowledgeId)
                .collect(Collectors.toList());
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

    @Override
    public List<String> getAllKnowledgeIdListByRoleId(String roleId) {
        LambdaQueryWrapper<SysRoleKnowledgeOutputEntity> wrapper = Wrappers.lambdaQuery();
        wrapper.select(SysRoleKnowledgeOutputEntity::getKnowledgeId);
        wrapper.eq(SysRoleKnowledgeOutputEntity::getRoleId, roleId);
        return list(wrapper).stream()
                .map(SysRoleKnowledgeOutputEntity::getKnowledgeId)
                .collect(Collectors.toList());
    }

    @Override
    public void saveRoleKnowledgeOutputAll(String roleId, String paramIds) {
        // ① 按 roleId 全删（跨所有知识分组）—— 与「整体覆盖」语义一致
        LambdaUpdateWrapper<SysRoleKnowledgeOutputEntity> wrapper = Wrappers.lambdaUpdate();
        wrapper.eq(SysRoleKnowledgeOutputEntity::getRoleId, roleId);
        remove(wrapper);

        if (StringUtils.isBlank(paramIds)) {
            return;
        }

        List<String> idList = new ArrayList<>();
        for (String s : paramIds.split(",")) {
            if (StringUtils.isNotBlank(s)) {
                idList.add(s.trim());
            }
        }
        if (idList.isEmpty()) {
            return;
        }

        // ② 按 knowledgeId 反查所属分组 —— 查不到的（已被删除 / 不是知识库）直接跳过，
        //    避免写入 group_id 为空、以后按分组过滤时永远取不到的孤立记录
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> pWrapper = Wrappers.lambdaQuery();
        pWrapper.select(KnowledgeBaseParamsEntity::getParamId, KnowledgeBaseParamsEntity::getGroupId);
        pWrapper.in(KnowledgeBaseParamsEntity::getParamId, idList);
        List<KnowledgeBaseParamsEntity> paramsList = knowledgeBaseParamsService.list(pWrapper);
        if (paramsList == null || paramsList.isEmpty()) {
            return;
        }

        Date now = new Date();
        List<SysRoleKnowledgeOutputEntity> list = new ArrayList<>();
        for (KnowledgeBaseParamsEntity p : paramsList) {
            SysRoleKnowledgeOutputEntity entity = new SysRoleKnowledgeOutputEntity();
            entity.setRoleId(roleId);
            entity.setGroupId(p.getGroupId());
            entity.setKnowledgeId(p.getParamId());
            entity.setOperateDate(now);
            list.add(entity);
        }
        saveBatch(list);
    }
}
