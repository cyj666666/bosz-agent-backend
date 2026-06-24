package com.suzhou.bank.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.mapper.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 用户管理服务
 * <p>用户 CRUD + 密码管理 + 角色分配。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final SysUserMapper userMapper;
    private final SysUserRoleMapper userRoleMapper;
    private final SysRoleMapper roleMapper;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /** 分页查询用户列表，含角色信息 */
    public Page<SysUser> page(int page, int size, String keyword) {
        LambdaQueryWrapper<SysUser> w = new LambdaQueryWrapper<>();
        if (keyword != null && !keyword.isEmpty()) {
            w.and(q -> q.like(SysUser::getUsername, keyword).or().like(SysUser::getRealName, keyword));
        }
        w.orderByDesc(SysUser::getCreatedAt);
        return userMapper.selectPage(new Page<>(page, size), w);
    }

    /** 查询用户详情，含角色列表 */
    public SysUser getById(Long id) {
        SysUser user = userMapper.selectById(id);
        if (user != null) {
            List<String> roleCodes = getUserRoleCodes(id);
            // 用动态字段传递角色
            user.setPassword(null); // 不返回密码
            // roles 通过扩展字段返回——这里用 UserController 组装
        }
        return user;
    }

    /** 新增用户 */
    @Transactional
    public void save(SysUser user, List<Long> roleIds) {
        // 校验用户名唯一
        Long count = userMapper.selectCount(
                new LambdaQueryWrapper<SysUser>().eq(SysUser::getUsername, user.getUsername()));
        if (count > 0) {
            throw new RuntimeException("用户名已存在");
        }
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        user.setStatus(1);
        user.setCreatedAt(new Date());
        userMapper.insert(user);

        // 分配角色
        if (roleIds != null && !roleIds.isEmpty()) {
            saveUserRoles(user.getId(), roleIds);
        }
        log.info("用户创建成功: {}", user.getUsername());
    }

    /** 更新用户信息 */
    @Transactional
    public void update(SysUser user, List<Long> roleIds) {
        SysUser exist = userMapper.selectById(user.getId());
        if (exist == null) throw new RuntimeException("用户不存在");
        exist.setRealName(user.getRealName());
        exist.setStatus(user.getStatus());
        userMapper.updateById(exist);

        // 更新角色：先删后插
        if (roleIds != null) {
            userRoleMapper.delete(
                    new LambdaQueryWrapper<SysUserRole>().eq(SysUserRole::getUserId, user.getId()));
            saveUserRoles(user.getId(), roleIds);
        }
    }

    /** 删除用户（禁止删除自己和其他管理员） */
    public void delete(Long id, Long currentUserId) {
        if (id.equals(currentUserId)) {
            throw new RuntimeException("不能删除自己的账号");
        }
        List<String> roleCodes = getUserRoleCodes(id);
        if (roleCodes.contains("admin")) {
            throw new RuntimeException("不能删除管理员账号");
        }
        userRoleMapper.delete(new LambdaQueryWrapper<SysUserRole>().eq(SysUserRole::getUserId, id));
        userMapper.deleteById(id);
        log.info("用户已删除: {}", id);
    }

    /** 管理员重置用户密码为默认值 */
    @Transactional
    public String resetPassword(Long id) {
        String defaultPwd = "Abc12345";
        setPassword(id, defaultPwd);
        return defaultPwd;
    }

    /** 管理员手动设置用户密码 */
    @Transactional
    public void setPassword(Long id, String newPwd) {
        SysUser user = userMapper.selectById(id);
        if (user == null) throw new RuntimeException("用户不存在");
        user.setPassword(passwordEncoder.encode(newPwd));
        userMapper.updateById(user);
        log.info("密码已修改, userId={}", id);
    }

    /** 修改自己的密码 */
    public void changePassword(Long userId, String oldPwd, String newPwd) {
        SysUser user = userMapper.selectById(userId);
        if (user == null) throw new RuntimeException("用户不存在");
        if (!passwordEncoder.matches(oldPwd, user.getPassword())) {
            throw new RuntimeException("原密码错误");
        }
        user.setPassword(passwordEncoder.encode(newPwd));
        userMapper.updateById(user);
        log.info("密码已修改, userId={}", userId);
    }

    /** 查询用户角色编码列表 */
    public List<String> getUserRoleCodes(Long userId) {
        List<SysUserRole> userRoles = userRoleMapper.selectList(
                new LambdaQueryWrapper<SysUserRole>().eq(SysUserRole::getUserId, userId));
        if (userRoles.isEmpty()) return Collections.emptyList();
        List<Long> roleIds = userRoles.stream().map(SysUserRole::getRoleId).collect(Collectors.toList());
        return roleMapper.selectBatchIds(roleIds).stream()
                .map(SysRole::getRoleCode)
                .collect(Collectors.toList());
    }

    /** 查询用户的角色ID列表 */
    public List<Long> getUserRoleIds(Long userId) {
        return userRoleMapper.selectList(
                new LambdaQueryWrapper<SysUserRole>().eq(SysUserRole::getUserId, userId))
                .stream().map(SysUserRole::getRoleId).collect(Collectors.toList());
    }

    private void saveUserRoles(Long userId, List<Long> roleIds) {
        for (Long roleId : roleIds) {
            SysUserRole ur = new SysUserRole();
            ur.setUserId(userId);
            ur.setRoleId(roleId);
            userRoleMapper.insert(ur);
        }
    }
}