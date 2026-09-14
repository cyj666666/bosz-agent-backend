package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.SysRoleIndexEntity;

import java.util.List;

/**
 * @Description: 角色指标权限表
 * @Author: jeecg-boot
 * @Date:   2025-01-16
 * @Version: V1.0
 */
public interface ISysRoleIndexService extends IService<SysRoleIndexEntity> {

    List<String> getIndexIdListByRoleId(List<String> roleIdList);

    void saveRoleIndex(String roleId, String permissionIds, String lastPermissionIds);

}
