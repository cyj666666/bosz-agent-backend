-- ====================================================================
-- 05_回滚_还原四列.sql —— 把 4 个字段还原到 20260916 迁移之前的状态
--
-- 用途：2026-09-17 执行 02 / 04 后发现「值首尾被写入多余换行」（生成器把
--       $mig$ 定界符单独放行导致），需要回滚后用修正过的脚本重跑。
--
-- ⚠️ 还原范围**仅限这 4 个列**，取自 01_备份.sql 建立的备份表；不触碰其它列。
-- ⚠️ 执行前提：备份表 bak_20260916_* 存在。
-- ====================================================================

-- 1) index_params.script
UPDATE index_params t SET script = b.script
  FROM bak_20260916_index_params b WHERE b.paramno = t.paramno;

-- 2) knowledge_base_params.relate_index_set / input_param
UPDATE knowledge_base_params t SET relate_index_set = b.relate_index_set, input_param = b.input_param
  FROM bak_20260916_kb_params b WHERE b.paramno = t.paramno;

-- 3) agent_rule.request_params
UPDATE agent_rule t SET request_params = b.request_params
  FROM bak_20260916_agent_rule b WHERE b.id = t.id;

-- 4) knowledge_relate_input_param.input_param
UPDATE knowledge_relate_input_param t SET input_param = b.input_param
  FROM bak_20260916_relate_input_param b WHERE b.id = t.id;


-- ====================================================================
-- 还原结果核对：四列的「首尾空白行数」应全部回到 0
-- ====================================================================
SELECT 'index_params.script 首尾空白' AS chk, count(*) AS should_be_zero
FROM index_params WHERE script LIKE E'\n%' OR script LIKE E'%\n'
UNION ALL SELECT 'kb.relate_index_set 首尾空白', count(*)
FROM knowledge_base_params WHERE relate_index_set LIKE E'\n%' OR relate_index_set LIKE E'%\n'
UNION ALL SELECT 'kb.input_param 首尾空白', count(*)
FROM knowledge_base_params WHERE input_param LIKE E'\n%' OR input_param LIKE E'%\n'
UNION ALL SELECT 'agent_rule.request_params 首尾空白', count(*)
FROM agent_rule WHERE request_params LIKE E'\n%' OR request_params LIKE E'%\n'
UNION ALL SELECT 'relate_input_param.input_param 首尾空白', count(*)
FROM knowledge_relate_input_param WHERE input_param LIKE E'\n%' OR input_param LIKE E'%\n';

-- 与备份表的逐行差异行数（应等于「本次迁移真正改动的行数」）
SELECT 'index_params 与备份不同行数' AS chk, count(*) AS rows_diff
FROM index_params p JOIN bak_20260916_index_params b ON p.paramno = b.paramno
WHERE p.script IS DISTINCT FROM b.script;
