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
-- 2026-09-22 口径统一（重要）：
--   admin 的 menu_permissions 由「具体清单」改为 **["*"]**（裸星号 = 菜单全通）。
--   理由：`AuthService#getUserMenuPermissions` 已移除 `role_code=='admin'` 硬编码，
--         改为「合并各角色 menu_permissions，含 '*' 即返回 ["*"]」；
--         前端 `menus.includes('*')` 是唯一触发「侧边栏全渲染」的条件。
--   ⇒ 若 admin 仍存具体清单（不含 '*'）：侧边栏只渲染清单里的项，
--     **新加的菜单（如 /role-auth 数据授权）不会出现**，且登录返回的 menus 与
--     接口准入（AuthInterceptor 另有 role_code=='admin' 兜底）会不一致。
--   配套改动：AuthInitializer#initDefaultAdmin、sql/三个菜单_执行步骤.md 的建号 SQL、
--             20260922_增量_角色菜单全通口径统一.sql（老环境升级用）。
--
--   注：admin 那行的值即便写错，接口侧仍有 `role_code=='admin'` 兜底、
--       不会把自己锁在系统管理之外；但**菜单可见性只认数据**，故必须为 ["*"]。
--
-- 执行：本地库 127.0.0.1:5432/bosz，schema as_agent
-- ============================================================================

SET search_path = as_agent, public;

-- 角色 1：admin（系统管理员）—— 菜单全通（*）
UPDATE sys_role
SET menu_permissions = '["*"]'
WHERE id = 1;

-- 角色 2：khjl（客户经理）—— 报告管理 + agent 三个菜单
-- ⚠️ 业务授权范围需业务方确认：指标配置 / 知识配置管理属于「配置类」功能，
--    是否应开放给客户经理，请按行内权限规范复核后调整本行。
UPDATE sys_role
SET menu_permissions = '["/reports","/agent/index-config","/agent/knowledge-config","/agent/rule"]'
WHERE id = 2;

-- 校验（如需人工核对，把下面两行的注释去掉后单独执行）：
-- SELECT id, role_code, role_name, menu_permissions FROM sys_role ORDER BY id;
