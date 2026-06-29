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
import java.util.Date;

/**
 * 应用初始化
 * <p>启动时先 DROP 旧业务表 → 执行 DDL 建表 → 加载示例数据 → 创建默认管理员。
 * DROP 后重建确保每次表结构都是最新的。</p>
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
        // 1. 认证权限表 DDL
        runSqlScript("sql/init_auth_gaussdb.sql", false, "认证相关表");

        // 2. 业务表 DDL（含列迁移补齐）
        runSqlScript("sql/init_db_gaussdb.sql", false, "业务表");

        // 3. 示例数据 DML
        initSampleData();

        // 4. 创建默认角色和用户
        initDefaultAdmin();
    }

    /** 执行 classpath 下的 SQL 脚本文件 */
    private void runSqlScript(String fileName, boolean stopOnError, String logLabel) {
        try {
            try (Connection conn = dataSource.getConnection()) {
                ScriptRunner runner = new ScriptRunner(conn);
                runner.setStopOnError(stopOnError);
                if (!stopOnError) {
                    runner.setErrorLogWriter(null); // 容错模式下静默（如 ALTER TABLE 列已存在）
                }
                runner.runScript(new InputStreamReader(
                        new ClassPathResource(fileName).getInputStream(),
                        StandardCharsets.UTF_8));
                log.info("{} 初始化完成", logLabel);
            }
        } catch (Exception e) {
            log.warn("{} 初始化失败: {}", logLabel, e.getMessage());
        }
    }

    /** 示例数据：每次重启重新初始化（DELETE+INSERT 均由 SQL 文件接管） */
    private void initSampleData() {
        try {
            try (Connection conn = dataSource.getConnection()) {
                ScriptRunner runner = new ScriptRunner(conn);
                runner.setStopOnError(true);
                runner.runScript(new InputStreamReader(
                        new ClassPathResource("sql/init_sample_data.sql").getInputStream(),
                        StandardCharsets.UTF_8));
                log.info("示例数据初始化完成");
            }
        } catch (Exception e) {
            log.warn("示例数据初始化失败: {}", e.getMessage());
        }
    }

    /** 创建默认管理员角色和用户 */
    private void initDefaultAdmin() {
        // admin 菜单权限由 AuthService.ALL_MENUS 统一管理
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
