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
-- 注意：admin 角色走特判 —— AuthService#getUserMenuPermissions 对 role_code='admin'
--       直接返回 ["*"]，前端 MainLayout 把 "*" 解析为「全量菜单可见」，
--       因此 admin 那行的 menu_permissions 实际不参与渲染。这里照样更新，
--       是为了让数据本身准确（万一将来去掉 admin 特判，授权数据就是对的）。
--
-- 执行：本地库 127.0.0.1:5432/bosz，schema as_agent
-- ============================================================================

SET search_path = as_agent, public;

-- 角色 1：admin（系统管理员）—— 报告管理 + 系统管理 + agent 三个菜单
UPDATE sys_role
SET menu_permissions = '["/reports","/users","/roles","/agent/index-config","/agent/knowledge-config","/agent/rule"]'
WHERE id = 1;

-- 角色 2：khjl（客户经理）—— 报告管理 + agent 三个菜单
-- ⚠️ 业务授权范围需业务方确认：指标配置 / 知识配置管理属于「配置类」功能，
--    是否应开放给客户经理，请按行内权限规范复核后调整本行。
UPDATE sys_role
SET menu_permissions = '["/reports","/agent/index-config","/agent/knowledge-config","/agent/rule"]'
WHERE id = 2;

-- 校验（如需人工核对，把下面两行的注释去掉后单独执行）：
-- SELECT id, role_code, role_name, menu_permissions FROM sys_role ORDER BY id;
