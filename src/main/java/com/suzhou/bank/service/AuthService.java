package com.suzhou.bank.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.suzhou.bank.config.JwtUtil;
import com.suzhou.bank.entity.SysRole;
import com.suzhou.bank.entity.SysUser;
import com.suzhou.bank.entity.SysUserRole;
import com.suzhou.bank.mapper.SysRoleMapper;
import com.suzhou.bank.mapper.SysUserMapper;
import com.suzhou.bank.mapper.SysUserRoleMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.*;

import com.alibaba.fastjson2.JSON;
import java.util.stream.Collectors;

/**
 * 认证服务
 * <p>处理登录逻辑：校验用户名密码 → 查询角色 → 生成 JWT Token。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final SysUserMapper sysUserMapper;
    private final SysUserRoleMapper sysUserRoleMapper;
    private final SysRoleMapper sysRoleMapper;
    private final JwtUtil jwtUtil;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /**
     * 用户登录
     *
     * @param username 用户名
     * @param password 明文密码
     * @return { token, username, realName, roles }
     */
    public Map<String, Object> login(String username, String password) {
        SysUser user = sysUserMapper.selectOne(
                new LambdaQueryWrapper<SysUser>().eq(SysUser::getUsername, username));

        if (user == null) {
            throw new RuntimeException("用户名或密码错误");
        }
        if (user.getStatus() == null || user.getStatus() != 1) {
            throw new RuntimeException("账号已被禁用");
        }
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new RuntimeException("用户名或密码错误");
        }

        // 查询用户角色
        List<String> roleCodes = getUserRoleCodes(user.getId());

        // 合并所有角色的菜单权限
        Set<String> menuPermissions = getUserMenuPermissions(user.getId());

        String token = jwtUtil.generateToken(user.getId(), user.getUsername(), roleCodes);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("token", token);
        result.put("username", user.getUsername());
        result.put("realName", user.getRealName());
        result.put("roles", roleCodes);
        result.put("menus", menuPermissions);
        return result;
    }

    /** 查询用户的角色编码列表 */
    private List<String> getUserRoleCodes(Long userId) {
        List<SysUserRole> userRoles = sysUserRoleMapper.selectList(
                new LambdaQueryWrapper<SysUserRole>().eq(SysUserRole::getUserId, userId));
        if (userRoles.isEmpty()) return Collections.emptyList();
        List<Long> roleIds = userRoles.stream().map(SysUserRole::getRoleId).collect(Collectors.toList());
        return sysRoleMapper.selectBatchIds(roleIds).stream()
                .map(SysRole::getRoleCode)
                .collect(Collectors.toList());
    }

    /** 合并用户所有角色的菜单权限 */
    private Set<String> getUserMenuPermissions(Long userId) {
        List<SysUserRole> userRoles = sysUserRoleMapper.selectList(
                new LambdaQueryWrapper<SysUserRole>().eq(SysUserRole::getUserId, userId));
        if (userRoles.isEmpty()) return Collections.emptySet();

        List<Long> roleIds = userRoles.stream().map(SysUserRole::getRoleId).collect(Collectors.toList());
        List<SysRole> roles = sysRoleMapper.selectBatchIds(roleIds);

        // admin 角色：返回 "*" 标记，前端解析为全权限，后端不维护菜单列表
        boolean isAdmin = roles.stream().anyMatch(r -> "admin".equals(r.getRoleCode()));
        if (isAdmin) {
            return new LinkedHashSet<>(Collections.singletonList("*"));
        }

        Set<String> menus = new LinkedHashSet<>();
        for (SysRole role : roles) {
            if (role.getMenuPermissions() != null && !role.getMenuPermissions().isEmpty()) {
                List<String> perms = JSON.parseArray(role.getMenuPermissions(), String.class);
                menus.addAll(perms);
            }
        }
        return menus;
    }
}