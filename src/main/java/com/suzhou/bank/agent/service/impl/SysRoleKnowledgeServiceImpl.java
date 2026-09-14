package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.suzhou.bank.agent.util.IpUtils;
import com.suzhou.bank.agent.util.WebContextUtils;
import com.suzhou.bank.agent.config.AgentSpringContext;
import com.suzhou.bank.agent.util.OConvertUtils;
import com.suzhou.bank.agent.mapper.SysRoleKnowledgeMapper;
import com.suzhou.bank.agent.entity.SysRoleKnowledgeEntity;
import com.suzhou.bank.agent.service.ISysRoleKnowledgeService;
import com.suzhou.bank.agent.util.ParamUtil;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletRequest;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

/**
 * @Description: 角色知识库权限表
 * @Author: jeecg-boot
 * @Date: 2025-01-16
 * @Version: V1.0
 */
@Service
public class SysRoleKnowledgeServiceImpl extends ServiceImpl<SysRoleKnowledgeMapper, SysRoleKnowledgeEntity> implements ISysRoleKnowledgeService {

    @Override
    public List<String> getKnowledgeIdListByRoleId(List<String> roleIdList) {
        LambdaQueryWrapper<SysRoleKnowledgeEntity> wrapper = Wrappers.lambdaQuery();
        wrapper.select(SysRoleKnowledgeEntity::getKnowledgeId);
        wrapper.in(SysRoleKnowledgeEntity::getRoleId, roleIdList);
        List<SysRoleKnowledgeEntity> list = list(wrapper);
        if (CollectionUtils.isEmpty(list)) {
            return null;
        }
        return list.stream().map(SysRoleKnowledgeEntity::getKnowledgeId).collect(Collectors.toList());
    }

    @Async
    @Override
    public void saveRoleKnowledge(String roleId, String permissionIds, String lastPermissionIds) {
        String ip = "";
        try {
            // 获取request
            HttpServletRequest request = WebContextUtils.getHttpServletRequest();
            // 获取IP地址
            ip = IpUtils.getIpAddr(request);
        } catch (Exception e) {
            ip = "127.0.0.1";
        }
        List<String> add = ParamUtil.getDiff(lastPermissionIds, permissionIds);
        if (add != null && !add.isEmpty()) {
            List<SysRoleKnowledgeEntity> list = new ArrayList<>();
            Date date = new Date();
            for (String p : add) {
                if (OConvertUtils.isNotEmpty(p)) {
                    SysRoleKnowledgeEntity roles = new SysRoleKnowledgeEntity();
                    roles.setRoleId(roleId);
                    roles.setKnowledgeId(p);
                    roles.setOperateDate(date);
                    roles.setOperateIp(ip);
                    list.add(roles);
                }
            }
            saveBatch(list);
        }

        List<String> delete = ParamUtil.getDiff(permissionIds, lastPermissionIds);
        if (delete != null && !delete.isEmpty()) {
            LambdaUpdateWrapper<SysRoleKnowledgeEntity> wrapper = Wrappers.lambdaUpdate();
            wrapper.eq(SysRoleKnowledgeEntity::getRoleId, roleId);
            wrapper.in(SysRoleKnowledgeEntity::getKnowledgeId, delete);
            remove(wrapper);
        }
    }
}
