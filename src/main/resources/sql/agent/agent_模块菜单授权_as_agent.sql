-- ============================================================================
-- agent 模块 —— 菜单授权数据（as_agent schema）
-- ============================================================================
-- 目的：让宿主侧边栏能显示 agent 模块的三个新菜单。
--
-- 背景（重要，避免以后误判）：
--   宿主的菜单可见性由 sys_role.menu_permissions 控制（JSON 数组，元素是前端路由 path）。
--   bosz-agent-frontend 的 AuthGuard / MainLayout 消费它，路径必须与
--   src/agent/routes.tsx 里的 path 逐字一致：
--       /agent/index-config        指标配置
--       /agent/knowledge-config    知识配置管理
--       /agent/rule                智策引擎
--
-- 同时清理 4 条已删除菜单的失效路径（这些页面已从 bosz-agent-frontend 移除，
-- 留在授权数据里会让人误以为还有入口）：
--       /customers      客户管理（已删）
--       /data-config    数据源配置（已删）
--       /indicators     指标数据（已删）
--       /rules          知识库管理（已删）
--
-- 2026-09-22 口径（第二次调整 · 最终版，客户确认）：
--
--   ①【菜单权限】admin 存**具体清单**，**不再用 ["*"]**。
--      管理员默认只看：报告管理 + 智策引擎 + 系统管理（用户管理 / 角色管理 / 数据授权）；
--      「指标配置」「知识配置管理」需由管理员在角色管理页**另行授予**（含给 admin 自己授）。
--   ②【系统管理接口准入】AuthInterceptor 判「menu_permissions 含 /users、/roles、/role-auth 之一」
--      （语义 = 能看系统管理菜单就能用系统管理接口），另保留 role_code=='admin' 兜底防自锁。
--   ③【数据可见性】**不再有任何"菜单全通"旁路** —— 完全由数据表决定：
--        sys_role_index（指标分组）/ sys_role_knowledge（知识分组）/
--        sys_role_knowledge_output（知识库的"输出要求"）
--      ⇒ 新增分组后需到「数据授权」页重新勾选（或跑增量 DML 灌全量）。
--   ④ "*" 机制本身**仍保留**：menu_permissions 含 "*" 的角色侧边栏全渲染 + 路由全放行，
--      但它**不再影响数据可见性**。
--
--   ⇒ 若 admin 仍存 ["*"]：会多出「指标配置 / 知识配置管理」两个菜单，与上面"默认只看三个"不符
--     （且老版本曾把它当作数据旁路判据，容易误读），故必须为下面的具体清单。
--   配套改动：AuthInitializer#initDefaultAdmin、sql/三个菜单_执行步骤.md 的建号 SQL、
--             20260922_增量_角色菜单全通口径统一.sql（老环境升级用，已按新口径重写）。
-- ============================================================================

SET search_path = as_agent, public;

-- 角色 1：admin（系统管理员）—— 报告管理 + 智策引擎 + 系统管理（用户/角色/数据授权）
UPDATE sys_role
SET menu_permissions = '["/reports","/agent/rule","/users","/roles","/role-auth"]'
WHERE id = 1;

-- 角色 2：khjl（客户经理）—— 报告管理 + agent 三个菜单
-- ⚠️ 业务授权范围需业务方确认：指标配置 / 知识配置管理属于「配置类」功能，
--    是否应开放给客户经理，请按行内权限规范复核后调整本行。
-- 🔴 2026-09-22 补充：客户确定的角色模型是 admin / tec_admin / normal 三角色，**不含客户经理**。
--    曹哥已明确「客户经理这个角色**外网可以不要了**」⇒ 外网清理脚本见
--    `sql/agent/外网专用_清理客户经理角色_20260922.sql`（⛔ 那份**只给外网**，别同步行内 —— 行内有真实客户经理）。
--    行内是否保留 khjl **仍待确认**，故本行保持原值、本次未改动。
UPDATE sys_role
SET menu_permissions = '["/reports","/agent/index-config","/agent/knowledge-config","/agent/rule"]'
WHERE id = 2;

-- 校验（如需人工核对，把下面两行的注释去掉后单独执行）：
-- SELECT id, role_code, role_name, menu_permissions FROM sys_role ORDER BY id;
