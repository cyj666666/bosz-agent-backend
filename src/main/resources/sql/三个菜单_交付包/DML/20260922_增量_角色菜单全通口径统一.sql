-- =====================================================================
-- 增量 DML：角色「菜单全通」口径统一
-- 日期：2026-09-22
-- =====================================================================
-- 【背景】原先「谁是管理员 / 谁能全通」散落在三处，且口径互不相同：
--   ① 宿主 AuthService#getUserMenuPermissions —— 写死 `roleCode == "admin"` ⇒ 直接返回 menus=["*"]，
--      导致库里 sys_role.menu_permissions 对 admin 形同虚设（改数据不生效）；
--   ② agent 指标侧 —— 靠 yml `agent.index.role-filter-bypass-roles: [admin]` 白名单放行；
--   ③ agent 知识侧 —— **没有任何 admin 豁免**（只有指标侧有）。
--
-- 【统一后的唯一口径】
--   sys_role.menu_permissions 里含「裸 *」（如 ["*"]）的角色
--     = 菜单全通（前端侧边菜单全渲染 + 路由守卫不拦截）
--     = 数据全通（agent 指标树 / 知识库不做角色过滤，返回"全部启用分组"）
--
-- 【代码侧已同步改造（本次一并交付）】
--   · AuthService#getUserMenuPermissions           → 合并各角色 menu_permissions，含 "*" 则返回 ["*"]
--   · AgentRoleMapper#countFullMenuRoles           → 【新增】按角色编码统计「menu_permissions 含 *」的角色数
--   · IndexConfigServiceImpl#getIndexIdListByRoleId → 用 countFullMenuRoles 放行（替代原 yml 白名单）
--   · KnowledgeBaseConfigServiceImpl#getKnowledgeIdListByRoleId → 【新增】同样的放行（补齐原知识侧缺失的豁免）
--   · AgentProperties#indexRoleFilterBypassRoles   → 字段已删除
--   · application.yml                              → agent.index.role-filter-bypass-roles 已移除
--
-- 【⚠️ 必须与代码同批上线】
--   只改代码不改数据 ⇒ admin 的 menus 会从 ["*"] 退化成那串具体清单，
--   数据层「含 *」判定不再命中 ⇒ **admin 反而看不到指标/知识**；
--   只改数据不改代码 ⇒ 代码仍走 `roleCode == "admin"` 硬编码，数据白改。
-- =====================================================================

UPDATE sys_role
   SET menu_permissions = '["*"]'
 WHERE role_code = 'admin';

-- ---------------------------------------------------------------------
-- 核验（应返回 2 行；admin 的 menu_permissions 应为 ["*"]，khjl 保持原清单不变）
-- ---------------------------------------------------------------------
-- SELECT id, role_code, role_name, menu_permissions FROM sys_role ORDER BY id;
