-- =====================================================================
-- 增量 DML：三角色 + 菜单权限 + 数据授权（口径统一 · 最终版）
-- 日期：2026-09-22（客户确认）
--
-- ⚠️ 文件名沿用旧名（20260922_增量_角色菜单全通口径统一.sql），但内容已按
--    **第二次口径调整**完全重写 —— 旧版讲的是「menu_permissions 含 * = 菜单全通
--    + 数据全通」，该模型已被客户推翻（管理员不再持有 *，数据旁路整体移除）。
--    执行时以本文件为准。
-- =====================================================================
--
-- 【本次确定的三角色模型】
--
--   ① admin（系统管理员）—— 已存在，本脚本只改其 menu_permissions
--        默认可见菜单：报告管理 + 智策引擎 + 系统管理（用户管理 / 角色管理 / 数据授权）
--        默认数据授权：指标分组 / 知识分组 / 知识库「输出要求」= **全量**
--        「指标配置」「知识配置管理」两个菜单**需由管理员另行授予**（包括给 admin 自己）
--
--   ② tec_admin（科技管理员）—— 本脚本新建
--        默认可见菜单：报告管理 + 智策引擎
--        默认数据授权：**全量**（与 admin 相同）
--        「指标配置」「知识配置管理」需管理员授予
--
--   ③ normal（普通用户）—— 本脚本新建
--        菜单为空（登录后侧边栏无任何菜单，页面提示"暂无可用菜单"）
--        数据授权为空
--        只能通过**信贷发起的报告链接**查看详情页（/credit/report 是独立页，不经过菜单）
--
-- 【三个消费点 —— 改一处必须三处一起想】
--
--   ① 菜单可见性：sys_role.menu_permissions（JSON 数组，元素 = 前端路由 path）
--        · 含裸 "*" ⇒ 侧边栏全渲染 + 路由守卫全放行（**机制保留，但不再影响数据**）
--        · 与前端 MainLayout 的菜单渲染、RoleList 的"菜单权限"可选项逐字一致
--
--   ② 系统管理接口准入：AuthInterceptor#isSystemAdmin
--        · menu_permissions 含 "/users"、"/roles"、"/role-auth" **之一** ⇒ 放行
--          （语义 = 能看系统管理菜单就能用系统管理接口）
--        · **另保留 role_code == 'admin' 兜底**，原因见下
--
--   ③ 数据可见性：**纯数据表驱动，已无任何"菜单全通"旁路**
--        · 指标      = sys_role_index             （存 index_base_group.groupid）
--        · 知识      = sys_role_knowledge         （存 knowledge_base_group.groupid）
--        · 输出要求  = sys_role_knowledge_output  （存 knowledge_base_params.paramid + 所属 group_id）
--      ⇒ 新增分组 / 知识库后，需到「数据授权」页重新勾选（或重跑本脚本第 2 节）。
--        这是去掉旁路后**已知且已接受**的代价。
--
-- 【🔴 为什么 admin 兜底不能删】
--   AuthInterceptor 守的 /api/user、/api/role 正是**系统管理自己的入口**。
--   角色管理页的「菜单权限」多选框可以把 admin 的 /users、/roles 全部取消勾选
--   ⇒ 改完 admin 立刻失去系统管理权限，而改回来又必须先进入角色管理页 ⇒ **永久锁死**。
--   故按 role_code == 'admin' 兜底放行；它与主口径是「或」关系，**不削弱主口径**。
--
-- 【⚠️ 数据与代码必须同批上线】
--   · 只改数据不改代码 ⇒ AuthInterceptor 仍按旧口径（含 "*"）判 ⇒ admin 调
--     /api/agent/roleAuth 会 403，数据授权页直接打不开。
--   · 只改代码不改数据 ⇒ admin 菜单仍是 ["*"] ⇒ 侧边栏多出「指标配置 / 知识配置管理」
--     （与"默认只看三个"不符）；且第 2 节授权数据缺失时，指标 / 知识页**空白**
--     —— 旁路已删除，没有兜底。
--
-- 【执行前提】
--   · 目标 schema：as_agent（行内按实际 schema 调整 search_path）
--   · 幂等：全部语句可重复执行（新增前置 NOT EXISTS 判断，不依赖唯一约束 ——
--     openGauss 基线不支持 INSERT ... ON CONFLICT DO NOTHING）
-- =====================================================================

SET search_path = as_agent, public;

-- =====================================================================
-- 1. 角色
-- =====================================================================

-- 1.1 新建「科技管理员」（已存在则跳过）
--     id 用 MAX(id)+1 显式取号，不依赖 AUTO_INCREMENT 的具体行为（两库兼容更稳）
INSERT INTO sys_role (id, role_code, role_name, description, menu_permissions, created_at)
SELECT (SELECT COALESCE(MAX(id), 0) + 1 FROM sys_role),
       'tec_admin',
       '科技管理员',
       '默认可见报告管理与智策引擎；指标配置 / 知识配置管理需管理员授予',
       '["/reports","/agent/rule"]',
       CURRENT_TIMESTAMP
 WHERE NOT EXISTS (SELECT 1 FROM sys_role WHERE role_code = 'tec_admin');

-- 1.2 新建「普通用户」（已存在则跳过）
--     菜单为空数组 [] ⇒ 登录后侧边栏无菜单，前端走「暂无可用菜单」占位页
INSERT INTO sys_role (id, role_code, role_name, description, menu_permissions, created_at)
SELECT (SELECT COALESCE(MAX(id), 0) + 1 FROM sys_role),
       'normal',
       '普通用户',
       '无菜单权限，仅可通过信贷发起的报告链接查看详情页',
       '[]',
       CURRENT_TIMESTAMP
 WHERE NOT EXISTS (SELECT 1 FROM sys_role WHERE role_code = 'normal');

-- 1.3 admin：菜单改为具体清单（不再是 ["*"]）
--     报告管理 /reports + 智策引擎 /agent/rule + 系统管理（/users + /roles + /role-auth）
--     ⚠️ 若写成 ["*"]：侧边栏会多出「指标配置 / 知识配置管理」两个菜单。
UPDATE sys_role
   SET menu_permissions = '["/reports","/agent/rule","/users","/roles","/role-auth"]'
 WHERE role_code = 'admin';

-- ⚠️ khjl（客户经理）本脚本**不动** —— 它当前是
--     ["/reports","/agent/index-config","/agent/knowledge-config","/agent/rule"]，
--     与"普通用户菜单为空"的新模型不一致，归属待业务确认后再单独调整。

-- =====================================================================
-- 2. 数据授权 —— 给 admin / tec_admin 灌「全量」
--    对应「数据授权」页三套 Tab 各自的"全选"效果
-- =====================================================================

-- 2.1 指标分组授权（Tab① 指标授权）
--     灌「全部启用中的分组」（index_base_group.groupstatus = '1'）
--     口径依据：sys_role_index.index_id 存的是**分组编号**（列表按 parent_param_no、
--     分组树按 groupid 过滤；源工程同样在此列混存少量指标编号，页面勾选只会写分组编号）
INSERT INTO sys_role_index (id, role_id, index_id, operate_date, operate_ip)
SELECT md5(r.role_code || '|IDX|' || g.groupid),
       r.id::text,
       g.groupid,
       CURRENT_TIMESTAMP,
       'init-dml'
  FROM sys_role r
 CROSS JOIN index_base_group g
 WHERE r.role_code IN ('admin', 'tec_admin')
   AND g.groupstatus = '1'
   AND NOT EXISTS (SELECT 1 FROM sys_role_index x
                    WHERE x.role_id = r.id::text
                      AND x.index_id = g.groupid);

-- 2.2 知识分组授权（Tab② 知识授权）
--     灌「全部启用中的知识分组」（knowledge_base_group.groupstatus = '1'）
INSERT INTO sys_role_knowledge (id, role_id, knowledge_id, operate_date, operate_ip)
SELECT md5(r.role_code || '|KB|' || g.groupid),
       r.id::text,
       g.groupid,
       CURRENT_TIMESTAMP,
       'init-dml'
  FROM sys_role r
 CROSS JOIN knowledge_base_group g
 WHERE r.role_code IN ('admin', 'tec_admin')
   AND g.groupstatus = '1'
   AND NOT EXISTS (SELECT 1 FROM sys_role_knowledge x
                    WHERE x.role_id = r.id::text
                      AND x.knowledge_id = g.groupid);

-- 2.3 知识库「输出要求」授权（Tab③ 知识输出授权）
--     灌「全部知识库」（knowledge_base_params.paramid），group_id 取该知识库自身所属分组
--     ⚠️ group_id 必须填对：后端保存是**按 (role_id, group_id) 整体覆盖**，
--        分组填错会让该组在下一次保存时被整组删掉
INSERT INTO sys_role_knowledge_output (id, role_id, group_id, knowledge_id, operate_date, operate_ip)
SELECT md5(r.role_code || '|KO|' || p.paramid),
       r.id::text,
       p.groupid,
       p.paramid,
       CURRENT_TIMESTAMP,
       'init-dml'
  FROM sys_role r
 CROSS JOIN knowledge_base_params p
 WHERE r.role_code IN ('admin', 'tec_admin')
   AND NOT EXISTS (SELECT 1 FROM sys_role_knowledge_output x
                    WHERE x.role_id = r.id::text
                      AND x.knowledge_id = p.paramid);

-- =====================================================================
-- 3. 核验（逐条执行，期望值见注释）
-- =====================================================================

-- 3.1 三 + 一个角色，admin 的 menu_permissions 应是具体清单（不含 "*"）
-- SELECT id, role_code, role_name, menu_permissions FROM sys_role ORDER BY id;

-- 3.2 指标分组授权数（admin / tec_admin 各自 = 启用分组总数，本地为 29）
-- SELECT r.role_code, count(1)
--   FROM sys_role r LEFT JOIN sys_role_index x ON x.role_id = r.id::text
--  GROUP BY r.role_code ORDER BY r.role_code;

-- 3.3 知识分组授权数（各自 = 启用知识分组总数，本地为 25）
-- SELECT r.role_code, count(1)
--   FROM sys_role r LEFT JOIN sys_role_knowledge x ON x.role_id = r.id::text
--  GROUP BY r.role_code ORDER BY r.role_code;

-- 3.4 知识库「输出要求」授权数（各自 = 知识库总数，本地为 84）
-- SELECT r.role_code, count(1)
--   FROM sys_role r LEFT JOIN sys_role_knowledge_output x ON x.role_id = r.id::text
--  GROUP BY r.role_code ORDER BY r.role_code;

-- 3.5 覆盖率自检：有任何"启用分组没被授权"的情况会列出来（期望 0 行）
-- SELECT 'index' AS kind, g.groupid, g.groupname, r.role_code
--   FROM sys_role r, index_base_group g
--  WHERE r.role_code IN ('admin','tec_admin') AND g.groupstatus = '1'
--    AND NOT EXISTS (SELECT 1 FROM sys_role_index x
--                     WHERE x.role_id = r.id::text AND x.index_id = g.groupid)
-- UNION ALL
-- SELECT 'knowledge', g.groupid, g.groupname, r.role_code
--   FROM sys_role r, knowledge_base_group g
--  WHERE r.role_code IN ('admin','tec_admin') AND g.groupstatus = '1'
--    AND NOT EXISTS (SELECT 1 FROM sys_role_knowledge x
--                     WHERE x.role_id = r.id::text AND x.knowledge_id = g.groupid);

-- =====================================================================
-- 4. 可选清理：admin 名下的 3 条"孤儿"输出要求授权
--    （knowledge_id 在 knowledge_base_params 里已不存在 —— 历史遗留，
--      不影响功能，仅影响核验计数：admin 会比 tec_admin 多 3 条）
--    需要清理时去掉下面两行注释再执行：
-- =====================================================================
-- DELETE FROM sys_role_knowledge_output x
--  WHERE NOT EXISTS (SELECT 1 FROM knowledge_base_params p WHERE p.paramid = x.knowledge_id);
