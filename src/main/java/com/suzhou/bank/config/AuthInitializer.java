package com.suzhou.bank.config;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.mapper.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.jdbc.ScriptRunner;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.Statement;
import java.util.Date;

/**
 * 认证初始化
 * <p>启动时自动建表、创建默认角色、创建默认管理员并分配 admin 角色。
 * 首次启动无需手动执行 SQL。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuthInitializer implements CommandLineRunner {

    private final SysUserMapper sysUserMapper;
    private final SysRoleMapper sysRoleMapper;
    private final SysUserRoleMapper sysUserRoleMapper;
    private final DataSource dataSource;

    @Override
    public void run(String... args) {
        // 自动建表
        try {
            try (Connection conn = dataSource.getConnection()) {
                ScriptRunner runner = new ScriptRunner(conn);
                runner.setStopOnError(false);
                runner.runScript(new InputStreamReader(
                        new ClassPathResource("init_auth_gaussdb.sql").getInputStream(),
                        StandardCharsets.UTF_8));
                log.info("认证相关表初始化完成");
            }
        } catch (Exception e) {
            log.warn("认证表初始化失败(可能已存在): {}", e.getMessage());
        }

        // 兼容旧表：补齐缺失的列
        try {
            try (Connection conn = dataSource.getConnection();
                 Statement stmt = conn.createStatement()) {
                stmt.execute("ALTER TABLE sys_role ADD COLUMN menu_permissions VARCHAR(512) DEFAULT '[]'");
                log.info("sys_role 表已补齐 menu_permissions 列");
            }
        } catch (Exception ignored) {
            // 列已存在则忽略
        }

        // 指标数据表
        try {
            try (Connection conn = dataSource.getConnection();
                 Statement stmt = conn.createStatement()) {
                stmt.execute("CREATE TABLE IF NOT EXISTS indicator_data ("
                        + "id BIGINT NOT NULL AUTO_INCREMENT,"
                        + "customer_id BIGINT NOT NULL,"
                        + "indicator_key VARCHAR(128) NOT NULL,"
                        + "indicator_name VARCHAR(128) NOT NULL,"
                        + "current_value VARCHAR(128),"
                        + "previous_value VARCHAR(128),"
                        + "change_desc VARCHAR(128),"
                        + "data_unit VARCHAR(32),"
                        + "domain VARCHAR(64),"
                        + "period VARCHAR(32),"
                        + "sort_order INT DEFAULT 0,"
                        + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                        + "PRIMARY KEY (id)"
                        + ")");
                log.info("indicator_data 表已就绪");
            }
        } catch (Exception e) {
            log.warn("indicator_data 表初始化失败: {}", e.getMessage());
        }

        // 示例数据：每次重启清空后重新初始化，保证和 init_sample_data.sql 严格一致
        try {
            try (Connection conn = dataSource.getConnection();
                 Statement stmt = conn.createStatement()) {
                // 清空示例数据（SQL 中 ID 全部通过子查询动态引用，无需重置自增）
                stmt.execute("DELETE FROM rule_condition");
                stmt.execute("DELETE FROM rule_tag");
                stmt.execute("DELETE FROM knowledge_rule");
                stmt.execute("DELETE FROM indicator_data");
                stmt.execute("DELETE FROM customer");
                stmt.execute("DELETE FROM rule_scenario");
                // 重新初始化
                ScriptRunner runner = new ScriptRunner(conn);
                runner.setStopOnError(true);
                runner.runScript(new InputStreamReader(
                        new ClassPathResource("init_sample_data.sql").getInputStream(),
                        StandardCharsets.UTF_8));
                log.info("示例数据初始化完成");
            }
        } catch (Exception e) {
            log.warn("示例数据初始化失败: {}", e.getMessage());
        }

        // 创建默认 admin 角色（admin 菜单权限由 AuthService.ALL_MENUS 统一管理，不依赖数据库字段）
        SysRole adminRole = sysRoleMapper.selectOne(
                new LambdaQueryWrapper<SysRole>().eq(SysRole::getRoleCode, "admin"));
        if (adminRole == null) {
            try {
                adminRole = new SysRole();
                adminRole.setRoleCode("admin");
                adminRole.setRoleName("系统管理员");
                adminRole.setDescription("拥有所有权限");
                adminRole.setMenuPermissions("[]");
                adminRole.setCreatedAt(new Date());
                sysRoleMapper.insert(adminRole);
                log.info("默认角色已创建: admin");
            } catch (Exception e) {
                log.warn("默认角色创建失败: {}", e.getMessage());
            }
        }

        // 创建默认管理员
        try {
            Long count = sysUserMapper.selectCount(
                    new LambdaQueryWrapper<SysUser>().eq(SysUser::getUsername, "admin"));
            if (count == 0) {
                SysUser admin = new SysUser();
                admin.setUsername("admin");
                admin.setPassword(new BCryptPasswordEncoder().encode("admin123"));
                admin.setRealName("系统管理员");
                admin.setStatus(1);
                admin.setCreatedAt(new Date());
                sysUserMapper.insert(admin);
                log.info("默认管理员账号已创建: admin / admin123");
            }
        } catch (Exception e) {
            log.warn("默认管理员创建失败: {}", e.getMessage());
        }

        // 分配 admin 角色给 admin 用户
        try {
            SysUser adminUser = sysUserMapper.selectOne(
                    new LambdaQueryWrapper<SysUser>().eq(SysUser::getUsername, "admin"));
            SysRole existRole = sysRoleMapper.selectOne(
                    new LambdaQueryWrapper<SysRole>().eq(SysRole::getRoleCode, "admin"));
            if (adminUser != null && existRole != null) {
                Long urCount = sysUserRoleMapper.selectCount(
                        new LambdaQueryWrapper<SysUserRole>()
                                .eq(SysUserRole::getUserId, adminUser.getId())
                                .eq(SysUserRole::getRoleId, existRole.getId()));
                if (urCount == 0) {
                    SysUserRole ur = new SysUserRole();
                    ur.setUserId(adminUser.getId());
                    ur.setRoleId(existRole.getId());
                    sysUserRoleMapper.insert(ur);
                    log.info("admin 用户已分配管理员角色");
                }
            }
        } catch (Exception e) {
            log.warn("角色分配失败: {}", e.getMessage());
        }
    }
}