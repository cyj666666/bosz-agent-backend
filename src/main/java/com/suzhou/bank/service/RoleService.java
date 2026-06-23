package com.suzhou.bank.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.SysRole;
import com.suzhou.bank.mapper.SysRoleMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

/**
 * 角色管理服务
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RoleService {

    private final SysRoleMapper roleMapper;

    public Page<SysRole> page(int page, int size) {
        return roleMapper.selectPage(new Page<>(page, size),
                new LambdaQueryWrapper<SysRole>().orderByAsc(SysRole::getId));
    }

    public List<SysRole> listAll() {
        return roleMapper.selectList(
                new LambdaQueryWrapper<SysRole>().orderByAsc(SysRole::getId));
    }

    public void save(SysRole role) {
        Long count = roleMapper.selectCount(
                new LambdaQueryWrapper<SysRole>().eq(SysRole::getRoleCode, role.getRoleCode()));
        if (count > 0) throw new RuntimeException("角色编码已存在");
        role.setCreatedAt(new Date());
        roleMapper.insert(role);
        log.info("角色创建成功: {}", role.getRoleCode());
    }

    public void update(SysRole role) {
        SysRole exist = roleMapper.selectById(role.getId());
        if (exist == null) throw new RuntimeException("角色不存在");
        if ("admin".equals(exist.getRoleCode())) {
            throw new RuntimeException("系统管理员角色不可修改");
        }
        exist.setRoleName(role.getRoleName());
        exist.setDescription(role.getDescription());
        exist.setMenuPermissions(role.getMenuPermissions());
        roleMapper.updateById(exist);
    }

    public void delete(Long id) {
        SysRole role = roleMapper.selectById(id);
        if (role == null) throw new RuntimeException("角色不存在");
        if ("admin".equals(role.getRoleCode())) {
            throw new RuntimeException("系统管理员角色不可删除");
        }
        roleMapper.deleteById(id);
        log.info("角色已删除: {}", role.getRoleCode());
    }
}