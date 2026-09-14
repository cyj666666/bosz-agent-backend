package com.suzhou.bank.agent.service.impl;

import com.alibaba.fastjson.JSONArray;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.google.common.collect.Lists;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.mapper.AgentRoleMapper;
import com.suzhou.bank.agent.mapper.SysRoleAiUserMapper;
import com.suzhou.bank.agent.entity.SysRoleAiUserEntity;
import com.suzhou.bank.agent.service.ISysRoleAiUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

/**
 * @Description: 角色ai用户权限表
 * @Author: jeecg-boot
 * @Date: 2025-01-16
 * @Version: V1.0
 */
@Service
public class SysRoleAiUserServiceImpl extends ServiceImpl<SysRoleAiUserMapper, SysRoleAiUserEntity> implements ISysRoleAiUserService {

    /** 只读查角色（替代源工程注入的 Jeecg ISysRoleService） */
    @Autowired
    private AgentRoleMapper agentRoleMapper;

    @Override
    public List<String> getUserIdListByRoleId(List<String> roleIdList) {
        LambdaQueryWrapper<SysRoleAiUserEntity> wrapper = Wrappers.lambdaQuery();
        wrapper.select(SysRoleAiUserEntity::getUserId);
        wrapper.in(SysRoleAiUserEntity::getRoleId, roleIdList);
        List<SysRoleAiUserEntity> list = list(wrapper);
        if (CollectionUtils.isEmpty(list)) {
            return null;
        }
        return list.stream().map(SysRoleAiUserEntity::getUserId).collect(Collectors.toList());
    }

    @Override
    public boolean saveRoleAiUser(String roleId, JSONArray permissionIds) {
        if (CollectionUtils.isEmpty(permissionIds)) {
            return false;
        }
        // 查询出已存在的
        LambdaQueryWrapper<SysRoleAiUserEntity> wrapper = Wrappers.lambdaQuery();
        wrapper.eq(SysRoleAiUserEntity::getRoleId, roleId);
        wrapper.in(SysRoleAiUserEntity::getUserId, permissionIds);
        List<SysRoleAiUserEntity> oldRoleAiUserList = list(wrapper);

        // 过滤已存在的
        if (CollectionUtils.isNotEmpty(oldRoleAiUserList)) {
            permissionIds.removeAll(oldRoleAiUserList.stream().map(SysRoleAiUserEntity::getUserId).collect(Collectors.toList()));
        }
        if (CollectionUtils.isEmpty(permissionIds)) {
            return true;
        }

        // 新增关联用户
        List<SysRoleAiUserEntity> newRoleAiUserList = new ArrayList<>();
        permissionIds.forEach(p -> {
            SysRoleAiUserEntity roles = new SysRoleAiUserEntity();
            roles.setRoleId(roleId);
            roles.setUserId(String.valueOf(p));
            roles.setOperateDate(new Date());
            newRoleAiUserList.add(roles);
        });
        return saveBatch(newRoleAiUserList);
    }

    @Override
    public List<String> getAdminRoleId(String roleName) {
        if (StringUtils.isEmpty(roleName)) {
            return null;
        }
        List<String> roleCodeList = new ArrayList<>();
        if ("aiUser".equals(roleName)) {
            roleCodeList.addAll(Arrays.asList("aiuseradmin", "AiUserAdmin", "AIUSERADMIN"));
        } else {
            return null;
        }
        // 迁移改造点：源实现注入 Jeecg 的 ISysRoleService 并构造 SysRole 查询条件来查 sys_role。
        // 本工程不引 Jeecg 的 Service 体系，改用 agent 自己的 AgentRoleMapper（只读查询）。
        // 宿主 sys_role.id 是 bigint 自增（公司库是 VARCHAR(32)），故这里拿到 Long 后转成 String，
        // 以保持方法签名与源实现一致（调用方按 String 处理角色 id）。
        List<Long> roleIds = agentRoleMapper.selectRoleIdsByRoleCodes(roleCodeList);
        if (roleIds == null || roleIds.isEmpty()) {
            return new ArrayList<>();
        }
        return roleIds.stream().map(String::valueOf).collect(Collectors.toList());
    }
}
