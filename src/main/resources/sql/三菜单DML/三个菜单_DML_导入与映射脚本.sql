-- =====================================================================
-- 苏州银行「贷后管理智能体」— 三个菜单 DML 导入与映射脚本（骨架）
--
-- 准则：以本平台（宿主）配置为准；公司数据导入后向本平台适配；
--       只保 admin 可用；涉及的数据全导。
-- 配套文档：同目录 三个菜单_DML方案_以本平台为准.md
--
-- ⚠️ 本脚本由两部分组成：
--   【Part A】数据搬运 —— 需你先从公司库导出（见 §0 的 pg_dump 模板），本脚本不含 INSERT 数据
--   【Part B】映射改写 + 授权生成 + 校验 —— 本脚本可直接执行
--
-- ⚠️ 执行前必须先：
--   ① 目标库的 44 张表已建（《三个菜单_建表DDL》）
--   ② 宿主 RBAC 已就位（sys_user / sys_role / sys_user_role）
--   ③ 已 SET search_path = <目标schema>, public;
-- =====================================================================


-- =====================================================================
-- §0  参数区（执行前把 __XXX__ 全部替换掉）
-- =====================================================================
-- 本平台基准值（不要改这些基准本身，只是让你核对）
--   角色：sys_role.id = '1'（role_code = admin）
--   模型：large_model_config.lm_code = 'bosz-report-ai'
--   数据源：sys_data_source.id = 'bosz-dev-local-0001'（本地）/ 现场用自己的 id
--
-- 👇 需要你填的：
--   __TARGET_SCHEMA__       目标 schema 名（如 bosz_test / as_agent）
--   __DATA_SOURCE_ID__      目标库 sys_data_source.id（指标 script 要指向它）
--   __OLD_DATA_SOURCE_ID__  公司库数据源 id（默认 2095447359636992001）
--   __LM_CODE__             目标库大模型 code（应等于 yml 的 agent.rule.parse-model-code）
--   __OLD_LM_CODE__         公司库模型 code（默认 Qwen3-32B）
--   __ADMIN_ROLE_ID__       目标库 admin 的 sys_role.id（本平台 = 1）

-- =====================================================================
-- §0.1  从公司库导出数据（在公司库侧执行，示意）
-- =====================================================================
-- 需要搬运的 16 张表（顺序即建议导入顺序）：
--   基础：sys_dict, sys_dict_item
--   指标：index_base_group, index_params, index_relate_knowledge_info
--   知识：knowledge_base_group, knowledge_base_params, knowledge_base_version,
--         knowledge_relate_index, knowledge_relate_input_param
--   规则：agent_rule
--   历史：call_llm_record, knowledge_query_result, prompt_query_result
--   （授权 sys_role_knowledge / sys_role_knowledge_output 不导，由 §B2 生成；
--     sys_role_index 不导）
--
-- pg_dump 模板（在公司库所在机器执行；--data-only 只导数据不建表）：
--   pg_dump -h 172.20.2.19 -p 8000 -U bosz_test -d bosz_test \
--           --schema=bosz_test --data-only --no-owner --no-privileges \
--           -t bosz_test.sys_dict -t bosz_test.sys_dict_item \
--           -t bosz_test.index_base_group -t bosz_test.index_params \
--           -t bosz_test.index_relate_knowledge_info \
--           -t bosz_test.knowledge_base_group -t bosz_test.knowledge_base_params \
--           -t bosz_test.knowledge_base_version \
--           -t bosz_test.knowledge_relate_index -t bosz_test.knowledge_relate_input_param \
--           -t bosz_test.agent_rule \
--           -f agent_dml_data.sql
--   历史记录量大，建议单独分批导出：
--   pg_dump ... -t bosz_test.call_llm_record -f agent_hist_call_llm.sql
--   pg_dump ... -t bosz_test.knowledge_query_result -f agent_hist_kq.sql
--   pg_dump ... -t bosz_test.prompt_query_result -f agent_hist_pq.sql
--
-- ⚠️ 导出文件里含 schema 名前缀时，导入前统一替换成 __TARGET_SCHEMA__。
-- ⚠️ 授权表/用户表/角色表/数据源表/模型表 —— 不属于本步导出范围。


-- =====================================================================
-- §B1  映射改写（数据搬完之后立刻执行；顺序不可乱）
-- =====================================================================

-- ---- B1.1 指标 script 里的数据源 id → 目标库的数据源 ----
-- 公司 134 条非空 script 全部指向公司那条数据源；不改则「SQL 预览 / 取数」找不到数据源。
UPDATE index_params
   SET script = replace(script, '__OLD_DATA_SOURCE_ID__', '__DATA_SOURCE_ID__')
 WHERE script LIKE '%__OLD_DATA_SOURCE_ID__%';

-- ---- B1.2 大模型编码（主表 / 版本表 / JSON key）----
UPDATE knowledge_base_params
   SET large_model_code = '__LM_CODE__'
 WHERE large_model_code <> '__LM_CODE__';

UPDATE knowledge_base_version
   SET large_model_code = '__LM_CODE__'
 WHERE large_model_code <> '__LM_CODE__';

-- large_model_content 是 {"模型code": 条件组JSON} 的字符串，key 也在里面；
-- 新旧 key 都要换，否则编辑器切到该模型时取不到「输出要求」（会静默覆盖数据）。
UPDATE knowledge_base_params
   SET large_model_content =
       replace(replace(large_model_content, '"__OLD_LM_CODE__":', '"__LM_CODE__":'),
                       '"qwen3":',               '"__LM_CODE__":')
 WHERE large_model_content LIKE '%"__OLD_LM_CODE__":%'
    OR large_model_content LIKE '%"qwen3":%';

UPDATE knowledge_base_version
   SET large_model_content =
       replace(replace(large_model_content, '"__OLD_LM_CODE__":', '"__LM_CODE__":'),
                       '"qwen3":',               '"__LM_CODE__":')
 WHERE large_model_content LIKE '%"__OLD_LM_CODE__":%'
    OR large_model_content LIKE '%"qwen3":%';

-- 说明：call_llm_record.large_model_code **保留原值**（它记录当时真实调用的模型），不动。


-- =====================================================================
-- §B2  授权生成（★ 决定 admin 能不能看到知识库 —— 不执行则知识库页全空）
-- =====================================================================
-- 代码依据：
--   pageKnowledgeBaseParamsList / queryKnowledgeBaseGroupTree 都先取
--   getKnowledgeIdListByRoleId()（查 sys_role_knowledge），为空直接 return 0 条；
--   group/query 的 authFlag 默认 true → 分组树也走过滤。
--   指标侧有 role-filter-bypass-roles: [admin] 放行，知识库侧**没有**。

-- ---- B2.1 sys_role_knowledge：把【全部知识库分组】授权给 admin ----
INSERT INTO sys_role_knowledge (id, role_id, knowledge_id, operate_date, operate_ip)
SELECT md5('rk-' || g.groupid), '__ADMIN_ROLE_ID__', g.groupid, now(), '127.0.0.1'
  FROM knowledge_base_group g
 WHERE NOT EXISTS (
         SELECT 1 FROM sys_role_knowledge s
          WHERE s.role_id = '__ADMIN_ROLE_ID__' AND s.knowledge_id = g.groupid);

-- ---- B2.2 sys_role_knowledge_output：把【全部知识库】的输出要求权限给 admin ----
-- 决定「输出要求 / 核心提示词 / 分段与检索策略」区块是否可见。
-- 公司库该表只有 1 条孤值（对不上任何对象）→ 必须新造。
INSERT INTO sys_role_knowledge_output (id, role_id, group_id, knowledge_id, operate_date)
SELECT md5('rko-' || k.paramid), '__ADMIN_ROLE_ID__', k.groupid, k.paramid, now()
  FROM knowledge_base_params k
 WHERE NOT EXISTS (
         SELECT 1 FROM sys_role_knowledge_output s
          WHERE s.role_id = '__ADMIN_ROLE_ID__' AND s.knowledge_id = k.paramid);

-- ---- B2.3 （可选保险项）sys_role_index ----
-- admin 在指标侧有 bypass，正常用不到；生成它可保证"即使 bypass 被关掉 admin 仍全可见"。
-- INSERT INTO sys_role_index (id, role_id, index_id, operate_date, operate_ip)
-- SELECT md5('ri-' || p.paramid), '__ADMIN_ROLE_ID__', p.paramid, now(), '127.0.0.1'
--   FROM index_params p
--  WHERE NOT EXISTS (
--          SELECT 1 FROM sys_role_index s
--           WHERE s.role_id = '__ADMIN_ROLE_ID__' AND s.index_id = p.paramid);

-- ---- B2.4 清掉可能被误带进来的旧授权（可选，若数据里混入了公司 role_id）----
-- DELETE FROM sys_role_knowledge        WHERE role_id <> '__ADMIN_ROLE_ID__';
-- DELETE FROM sys_role_knowledge_output WHERE role_id <> '__ADMIN_ROLE_ID__';


-- =====================================================================
-- §B3  校验（照跑，期望值写在行尾注释里）
-- =====================================================================

-- 【基础配置】
SELECT 'lm_code 是否对齐 yml' AS chk, count(*) AS v
  FROM large_model_config WHERE lm_code = '__LM_CODE__';                                   -- 期望 ≥1
SELECT 'data_source 是否有' AS chk, count(*) AS v FROM sys_data_source;                     -- 期望 ≥1
SELECT 'menu_permissions' AS chk, menu_permissions FROM sys_role WHERE id = 1;               -- 期望含 3 条 /agent/*
SELECT 'dict_item 分布' AS chk, dict_code, count(*) FROM sys_dict_item GROUP BY dict_code;   -- 只有 5 个字典有项

-- 【业务配置】
SELECT '知识库↔分组 命中' AS chk, count(*) AS total, count(g.groupid) AS matched
  FROM knowledge_base_params k LEFT JOIN knowledge_base_group g ON g.groupid = k.groupid;    -- 期望 86 / 86
SELECT '数据源改写残留' AS chk, count(*) AS v
  FROM index_params WHERE script LIKE '%__OLD_DATA_SOURCE_ID__%';                            -- 期望 0
SELECT '模型编码残留' AS chk, count(*) AS v
  FROM knowledge_base_params WHERE large_model_code <> '__LM_CODE__';                         -- 期望 0
SELECT 'content key 残留' AS chk, count(*) AS v
  FROM knowledge_base_params WHERE large_model_content LIKE '%"__OLD_LM_CODE__":%';           -- 期望 0

-- 【授权 ★】
SELECT 'admin 知识库分组授权' AS chk, count(*) AS v
  FROM sys_role_knowledge WHERE role_id = '__ADMIN_ROLE_ID__';                               -- 期望 = 分组总数
SELECT '授权↔分组 命中' AS chk, count(*) AS total, count(g.groupid) AS matched
  FROM sys_role_knowledge s LEFT JOIN knowledge_base_group g ON g.groupid = s.knowledge_id;  -- 期望 全命中
SELECT 'admin 输出要求授权' AS chk, count(*) AS v
  FROM sys_role_knowledge_output WHERE role_id = '__ADMIN_ROLE_ID__';                         -- 期望 = 知识库总数
SELECT 'role_id 是否只剩 admin' AS chk, role_id, count(*)
  FROM sys_role_knowledge GROUP BY role_id;                                                  -- 期望只有 1 行

-- 【行数基线（按需对照，公司库实测值）】
--   index_base_group 40 / index_params 1086 / index_relate_knowledge_info 492
--   knowledge_base_group 25 / knowledge_base_params 86 / knowledge_base_version 1
--   knowledge_relate_index 493 / knowledge_relate_input_param 9 / agent_rule 42
--   sys_dict 88 / sys_dict_item 24
--   call_llm_record 8635 / knowledge_query_result 3776 / prompt_query_result 1466


-- =====================================================================
-- §B4  冒烟（admin 登录后逐页点）
-- =====================================================================
-- ① 指标配置：分组树展开 → 列表 1086 → 打开一条 → 数据源下拉有值 → SQL 预览出结果
--              → KnowledgeCode 向导四步可走
-- ② 知识配置：分组树展开（空 = B2.1 没执行）→ 列表 86 → 打开编辑器
--              → 切大模型时「输出要求」跟着换（第 4 项修复点）
--              → 右栏 4 个模型参数（top概率 / 温度 / 是否输出思考 / 系统提示词）可编辑
--              → 预览出流式结果（报"未找到大模型配置" = 模型编码没对齐）
-- ③ 智策引擎：列表 42 → 打开表单 → 「AI 分析」出流式结果
--
-- 若 ② 的「输出要求 / 核心提示词 / 分段与检索策略」区块不显示 → B2.2 没执行或无效果
--   （校验：SELECT count(*) FROM sys_role_knowledge_output WHERE role_id='__ADMIN_ROLE_ID__';）
-- =====================================================================
