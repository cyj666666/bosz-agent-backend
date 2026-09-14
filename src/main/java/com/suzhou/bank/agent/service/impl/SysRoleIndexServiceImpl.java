package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.suzhou.bank.agent.util.IpUtils;
import com.suzhou.bank.agent.util.WebContextUtils;
import com.suzhou.bank.agent.util.OConvertUtils;import com.suzhou.bank.agent.mapper.SysRoleIndexMapper;
import com.suzhou.bank.agent.entity.SysRoleIndexEntity;
import com.suzhou.bank.agent.service.ISysRoleIndexService;
import com.suzhou.bank.agent.util.ParamUtil;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletRequest;
import java.util.*;
import java.util.stream.Collectors;

/**
 * @Description: 角色指标权限表
 * @Author: jeecg-boot
 * @Date: 2025-01-16
 * @Version: V1.0
 */
@Service
public class SysRoleIndexServiceImpl extends ServiceImpl<SysRoleIndexMapper, SysRoleIndexEntity> implements ISysRoleIndexService {

    @Override
    public List<String> getIndexIdListByRoleId(List<String> roleIdList) {
        LambdaQueryWrapper<SysRoleIndexEntity> wrapper = Wrappers.lambdaQuery();
        wrapper.select(SysRoleIndexEntity::getIndexId);
        wrapper.in(SysRoleIndexEntity::getRoleId, roleIdList);
        List<SysRoleIndexEntity> list = list(wrapper);
        if (CollectionUtils.isEmpty(list)) {
            return null;
        }
        return list.stream().map(SysRoleIndexEntity::getIndexId).collect(Collectors.toList());
    }

    @Async
    @Override
    public void saveRoleIndex(String roleId, String permissionIds, String lastPermissionIds) {
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
            List<SysRoleIndexEntity> list = new ArrayList<>();
            Date date = new Date();
            for (String p : add) {
                if (OConvertUtils.isNotEmpty(p)) {
                    SysRoleIndexEntity roles = new SysRoleIndexEntity();
                    roles.setRoleId(roleId);
                    roles.setIndexId(p);
                    roles.setOperateDate(date);
                    roles.setOperateIp(ip);
                    list.add(roles);
                }
            }
            saveBatch(list);
        }

        List<String> delete = ParamUtil.getDiff(permissionIds, lastPermissionIds);
        if (delete != null && !delete.isEmpty()) {
            LambdaUpdateWrapper<SysRoleIndexEntity> wrapper = Wrappers.lambdaUpdate();
            wrapper.eq(SysRoleIndexEntity::getRoleId, roleId);
            wrapper.in(SysRoleIndexEntity::getIndexId, delete);
            remove(wrapper);
        }
    }
}
