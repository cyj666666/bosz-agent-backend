package com.suzhou.bank.agent.service;

import com.alibaba.fastjson.JSONArray;
import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.SysRoleAiUserEntity;

import java.util.List;

/**
 * @Description: 角色ai用户权限表
 * @Author: jeecg-boot
 * @Date:   2025-01-16
 * @Version: V1.0
 */
public interface ISysRoleAiUserService extends IService<SysRoleAiUserEntity> {

    List<String> getUserIdListByRoleId(List<String> roleIdList);

    boolean saveRoleAiUser(String roleId, JSONArray permissionIds);

    List<String> getAdminRoleId(String roleCode);

}
