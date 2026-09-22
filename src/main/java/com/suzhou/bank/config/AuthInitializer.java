package com.suzhou.bank.config;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.mapper.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.jdbc.ScriptRunner;
import org.springframework.beans.factory.annotation.Value;
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
 * <p><b>启动期 SQL 自动执行默认关闭</b>（{@code app.init-sql-on-startup=false}）：
 * DDL/DML 一律人工执行，应用启动不再改库 —— 库结构由人工/发布流程掌控。</p>
 * <p>确需在空库上快速拉起时，把该配置置 true，会依次执行：
 * 认证表 DDL → 业务表 DDL → 示例数据 DML → 创建默认管理员。</p>
 *
 * <p>相关脚本（均需人工执行）：</p>
 * <ul>
 *   <li>{@code sql/init_auth_gaussdb.sql} —— 认证权限表</li>
 *   <li>{@code sql/init_db_gaussdb.sql} —— 平台与业务表（含列迁移补齐）</li>
 *   <li>{@code sql/init_db_comments.sql} —— 表/列注释</li>
 *   <li>{@code sql/init_sample_data.sql} —— 示例数据</li>
 * </ul>
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

    /** 是否在启动时自动执行 SQL 初始化（DDL/DML）；默认 false，不随启动跑 */
    @Value("${app.init-sql-on-startup:false}")
    private boolean initSqlOnStartup;

    @Override
    public void run(String... args) {
        if (!initSqlOnStartup) {
            log.info("启动期 SQL 初始化已关闭（app.init-sql-on-startup=false）—— "
                    + "DDL/DML 请人工执行：sql/init_auth_gaussdb.sql、sql/init_db_gaussdb.sql、"
                    + "sql/init_db_comments.sql、sql/init_sample_data.sql");
            return;
        }
        log.warn("已开启启动期 SQL 初始化（app.init-sql-on-startup=true），即将执行 DDL/DML");

        // 1. 认证权限表 DDL
        runSqlScript("sql/init_auth_gaussdb.sql", false, "认证相关表");

        // 2. 平台与业务表 DDL（含列迁移补齐）
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
        // 🔴 admin 的 menu_permissions = 具体清单（2026-09-22 客户最终确定的角色模型）。
        //    管理员**默认只看**：报告管理 / 智策引擎 / 系统管理（用户管理、角色管理、数据授权）；
        //    「指标配置」「知识配置管理」需由管理员在角色管理页另行授予（包括给 admin 自己）。
        //
        //    ⚠️ 不要改回 ["*"]：数据旁路已按新口径**整体移除**，"*" 现在只影响前端菜单渲染，
        //       而它同时会让 admin 多出「指标配置 / 知识配置管理」两个菜单 —— 与上面"默认只看三个"不符。
        //
        //    这份值有三处消费点：AuthService#getUserMenuPermissions（登录返回 menus）、
        //    前端路由守卫 / MainLayout 菜单渲染、AuthInterceptor#isSystemAdmin（系统管理接口准入）。
        //    若建成 "[]"，admin 登录后**侧边栏全空**。
        //    AuthInterceptor 另保留 role_code=='admin' 兜底，防"把 /users、/roles 取消勾选后无法进角色管理页"的自锁。
        SysRole adminRole = sysRoleMapper.selectOne(
                new LambdaQueryWrapper<SysRole>().eq(SysRole::getRoleCode, "admin"));
        if (adminRole == null) {
            try {
                adminRole = new SysRole();
                adminRole.setRoleCode("admin");
                adminRole.setRoleName("系统管理员");
                adminRole.setDescription("拥有所有权限");
                adminRole.setMenuPermissions(
                        "[\"/reports\",\"/agent/rule\",\"/users\",\"/roles\",\"/role-auth\"]");
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
