-- ====================================================================
-- 01_备份.sql —— 入参规范化迁移【前置步骤】
--
-- 目的：迁移前把将被修改的「表 + 列」原样留存，任何一条 UPDATE 出问题
--       都能用备份表按 key 逐行还原。
--
-- ⚠️ 执行顺序：01_备份.sql  →  02_入参规范化.sql  →  03_校验.sql
-- ⚠️ 本脚本只做 CREATE TABLE ... AS SELECT，不修改任何业务表。
-- ====================================================================

-- 1) index_params.script（指标配置：SQL 条件 / paramData 声明 / 顶层键 / knowledgeParamList）
CREATE TABLE bak_20260916_index_params AS
SELECT paramno, script
FROM index_params;

-- 2) knowledge_base_params：relate_index_set（关联指标参数映射）与 input_param（测试集样例）
CREATE TABLE bak_20260916_kb_params AS
SELECT paramno, relate_index_set, input_param
FROM knowledge_base_params;

-- 3) agent_rule.request_params（规则的入参字段名数组）
CREATE TABLE bak_20260916_agent_rule AS
SELECT id, request_params
FROM agent_rule;

-- 4) knowledge_relate_input_param.input_param（知识库关联入参快照，容易被漏掉的一张表）
CREATE TABLE bak_20260916_relate_input_param AS
SELECT id, input_param
FROM knowledge_relate_input_param;


-- ====================================================================
-- 备份结果核对：四张备份表的行数应与下面「源表行数」完全一致
-- ====================================================================
SELECT 'src_index_params'          AS obj, count(*) AS rows FROM index_params
UNION ALL SELECT 'bak_index_params',           count(*) FROM bak_20260916_index_params
UNION ALL SELECT 'src_kb_params',              count(*) FROM knowledge_base_params
UNION ALL SELECT 'bak_kb_params',              count(*) FROM bak_20260916_kb_params
UNION ALL SELECT 'src_agent_rule',             count(*) FROM agent_rule
UNION ALL SELECT 'bak_agent_rule',             count(*) FROM bak_20260916_agent_rule
UNION ALL SELECT 'src_relate_input_param',     count(*) FROM knowledge_relate_input_param
UNION ALL SELECT 'bak_relate_input_param',     count(*) FROM bak_20260916_relate_input_param;


-- ====================================================================
-- 【回滚说明】如需整体回滚，执行下面语句（按 key 逐行还原，只还原本次改过的列）
-- ====================================================================
-- UPDATE index_params t SET script = b.script
--   FROM bak_20260916_index_params b WHERE b.paramno = t.paramno;
-- UPDATE knowledge_base_params t SET relate_index_set = b.relate_index_set, input_param = b.input_param
--   FROM bak_20260916_kb_params b WHERE b.paramno = t.paramno;
-- UPDATE agent_rule t SET request_params = b.request_params
--   FROM bak_20260916_agent_rule b WHERE b.id = t.id;
-- UPDATE knowledge_relate_input_param t SET input_param = b.input_param
--   FROM bak_20260916_relate_input_param b WHERE b.id = t.id;
--
-- 确认无误后再清理备份表：
-- DROP TABLE bak_20260916_index_params;
-- DROP TABLE bak_20260916_kb_params;
-- DROP TABLE bak_20260916_agent_rule;
-- DROP TABLE bak_20260916_relate_input_param;
