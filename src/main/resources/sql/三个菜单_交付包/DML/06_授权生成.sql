-- =====================================================================
-- 三个菜单 · DML 步骤 3/4 —— 授权生成（全部落到 admin）
--
-- 🔴 为什么必须执行这一步：
--    知识库页的「分组树」和「列表」都会先查 sys_role_knowledge 做权限过滤，
--    查不到就直接返回 0 条 —— 而**代码里对 admin 没有豁免**
--    （只有指标侧有 agent.index.role-filter-bypass-roles: [admin]）。
--    所以这两张表为空时，admin 打开「知识配置」看到的是**空白页**。
--    同理 sys_role_knowledge_output 决定「输出要求 / 核心提示词 / 分段与检索策略」区块是否可见。
--
-- 前置：数据文件 01~04 已导入、06_映射改写.sql 已执行
-- 自动化：admin 的角色 id 用子查询取，**无需手工替换**
-- 幂等：带 NOT EXISTS，可重复执行
-- =====================================================================

-- ① 把【全部知识库分组】授权给 admin
--    过滤列口径：sys_role_knowledge.knowledge_id 存的是 knowledge_base_group.groupid
INSERT INTO sys_role_knowledge (id, role_id, knowledge_id, operate_date, operate_ip)
SELECT md5('rk-' || g.groupid),
       (SELECT id::text FROM sys_role WHERE role_code = 'admin' LIMIT 1),
       g.groupid, now(), '127.0.0.1'
  FROM knowledge_base_group g
 WHERE NOT EXISTS (
         SELECT 1 FROM sys_role_knowledge s
          WHERE s.role_id = (SELECT id::text FROM sys_role WHERE role_code = 'admin' LIMIT 1)
            AND s.knowledge_id = g.groupid);

-- ② 把【全部知识库】的「输出要求」权限给 admin
--    判权口径：checkKnowledgeOutputAuth → role_id in (...) AND knowledge_id = paramId
--    即 knowledge_id 存的是 knowledge_base_params.paramid（主键）
INSERT INTO sys_role_knowledge_output (id, role_id, group_id, knowledge_id, operate_date)
SELECT md5('rko-' || k.paramid),
       (SELECT id::text FROM sys_role WHERE role_code = 'admin' LIMIT 1),
       k.groupid, k.paramid, now()
  FROM knowledge_base_params k
 WHERE NOT EXISTS (
         SELECT 1 FROM sys_role_knowledge_output s
          WHERE s.role_id = (SELECT id::text FROM sys_role WHERE role_code = 'admin' LIMIT 1)
            AND s.knowledge_id = k.paramid);

-- ③ 菜单可见性：**无需数据**
--    AuthService 里「角色编码 = admin」会直接返回 menus = ["*"]，前端 MainLayout/AuthGuard 全放行，
--    **不读 sys_role.menu_permissions**。所以只要 admin 的 role_code 是 'admin' 就能看到三个菜单。
--    （非 admin 角色才需要在「角色管理 → 菜单权限」里勾选：
--      /agent/index-config、/agent/knowledge-config、/agent/rule）

-- 不想用 admin 而要落到别的角色时，把上面两处
--   (SELECT id::text FROM sys_role WHERE role_code = 'admin' LIMIT 1)
-- 换成目标角色的 id 即可（role_id 列是 varchar，注意加 ::text）。
