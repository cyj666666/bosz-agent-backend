-- =====================================================================
-- 增量 DML：新增菜单「通用提示词管理」(/prompt-config) 的角色授权
-- 日期：2026-09-23（来源：20260923 测试问题统计 #4）
--
-- 【需求】系统管理下新增菜单「通用提示词管理」，列表展示 app_report_prompt
--         （提示词名称 / 系统提示词 / 备注 / 创建时间 / 更新时间），仅支持编辑「系统提示词」。
--
-- 【权限口径】admin-only（客户 2026-09-23 定）
--   · 后端：config/AuthInterceptor 已把 /api/report/prompt 与 /api/user、/api/role、
--           /api/agent/roleAuth 同列判定 —— menu_permissions 含系统管理菜单键之一即放行；
--           /prompt-config 已加进 SYSTEM_MENU_KEYS（常量已改，见代码）。
--   · 前端：/prompt-config 由 src/agent/menu.ts 的 agentSystemMenus 派生，
--           同时驱动「侧边菜单渲染」与「角色管理页的菜单权限可选项」两处。
--
-- 【🔴 为什么要跑这条脚本】
--   菜单可见性是**纯数据驱动**的：MainLayout 里子项渲染条件是
--   `allPower || granted.has(c.key)` —— 即 `menu_permissions` 里**必须有 "/prompt-config"**
--   （或含裸 "*"）。代码改了但数据没给 ⇒ **菜单不会出现**（后端接口能通过对 admin 的
--   role_code 兜底，但用户看不到入口）。
--
--   ⚠️ 等价的替代做法（不想跑脚本就手动点）：
--      用 admin 登录 → 系统管理 → 角色管理 → 编辑 admin → 「菜单权限」勾上
--      「系统管理-通用提示词管理（/prompt-config）」→ 保存。
--      本脚本只是把这一步自动化 + 幂等化。
--
-- 【幂等性】重复执行结果不变（已含该键 ⇒ 整行不动）
-- 【语法口径】全程只用「PG / MySQL 兼容模式交集语法」：
--   CASE WHEN / POSITION(str IN str) / REPLACE / IS NULL —— 两库均可执行。
--   ⛔ 不用 || （行内 M 模式下是逻辑或）、不用 REGEXP、不用 MODIFY。
-- =====================================================================

-- ---------------------------------------------------------------------
-- ① 授权：给 admin 追加 "/prompt-config"
--
--    四条分支的意义（按序命中）：
--      1) 已含该键            → 原样返回（**幂等**）
--      2) NULL 或 "[]"（无引号即空数组）→ 直接赋值成只含该键的数组（避免拼出 [,"/x"] 这种非法 JSON）
--      3) 非空数组            → 在末尾 `]` 前追加（菜单路径不含 `]`，REPLACE 不会误伤）
--      4) 其它意外形态        → 兜底赋成只含该键的数组
-- ---------------------------------------------------------------------
UPDATE sys_role
   SET menu_permissions = CASE
         WHEN POSITION('"/prompt-config"' IN menu_permissions) > 0
              THEN menu_permissions
         WHEN menu_permissions IS NULL OR POSITION('"', menu_permissions) = 0
              THEN '["/prompt-config"]'
         WHEN POSITION(']' IN menu_permissions) > 0
              THEN REPLACE(menu_permissions, ']', ',"/prompt-config"]')
         ELSE '["/prompt-config"]'
       END
 WHERE role_code = 'admin';

-- ---------------------------------------------------------------------
-- ② 复核（跑完看一眼）
--    预期：admin 的 menu_permissions 里出现 "/prompt-config"；
--          tec_admin / normal 不受影响（本脚本刻意只动 admin）。
-- ---------------------------------------------------------------------
SELECT role_code, role_name, menu_permissions
  FROM sys_role
 ORDER BY role_code;

-- ---------------------------------------------------------------------
-- ③ 可选：若希望其他角色也能看到「通用提示词管理」，按角色编码逐条执行
--    （⛔ 不要改成不带 WHERE 的全表 UPDATE —— 那等于把这个菜单发给所有角色）
-- ---------------------------------------------------------------------
-- UPDATE sys_role
--    SET menu_permissions = REPLACE(menu_permissions, ']', ',"/prompt-config"]')
--  WHERE role_code = 'tec_admin'
--    AND POSITION('"/prompt-config"' IN menu_permissions) = 0
--    AND POSITION('"', menu_permissions) > 0;
