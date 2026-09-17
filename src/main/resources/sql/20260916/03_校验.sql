-- ====================================================================
-- 03_校验.sql —— 入参归一 + 冗余参数清理【后置自检】
--
-- 执行时机：02_入参规范化.sql 跑完之后
--
-- 判定标准：
--   A 类（应全部为 0）—— 旧写法与已废弃参数不应再残留
--   B 类（应大于 0）  —— 目标态确已到位，且准则要求的条件仍在
--   C 类（应大于 0）  —— 防误改：表字段名 / 提示词文案 / SQL 列引用 / 表间关联
--
-- ⚠️ 本文件只校验「参数名」与「参数条件」层面。
--    「reportNo + entName 必须落在每个查询块的每张表上」这条准则由
--    _tools/SqlScopeValidator.java 负责，见 _tools/SQL范围限定校验报告.txt
--
-- ⚠️ 本文件不使用 FILTER 语法（openGauss 不支持），一律用 sum(case when ... end)
-- ====================================================================


-- ==================== A. 残留检查（应全部为 0）====================

-- A1 index_params.script：SQL 占位符的旧「全小写」写法
SELECT 'A1 script 占位符小写残留' AS chk, count(*) AS should_be_zero
FROM index_params
WHERE script ~ ':(reportno|customerid|guarantorid|guarantorname|entname)([^A-Za-z0-9_]|$)';

-- A2 index_params.script：已废弃参数 customerId / guarantorId 的占位符应完全消失
SELECT 'A2 废弃占位符残留' AS chk, count(*) AS should_be_zero
FROM index_params
WHERE script ~ ':(customerId|guarantorId)([^A-Za-z0-9_]|$)';

-- A3 index_params.script：paramData 声明（旧写法 + 已废弃参数）
SELECT 'A3 script paramData 残留' AS chk, count(*) AS should_be_zero
FROM index_params
WHERE script ~ '"name"\s*:\s*"(reportno|customerid|guarantorid|guarantorname|entname)"'
   OR script ~ '"name"\s*:\s*"(customerId|guarantorId)"';

-- A4 knowledge_base_params.relate_index_set：params[].field
SELECT 'A4 relate_index_set 残留' AS chk, count(*) AS should_be_zero
FROM knowledge_base_params
WHERE relate_index_set ~ '"field"\s*:\s*"(reportno|customerid|guarantorid|guarantorname|entname|customerId|guarantorId)"';

-- A5 knowledge_base_params.input_param：测试集参数名
SELECT 'A5 kb.input_param 残留' AS chk, count(*) AS should_be_zero
FROM knowledge_base_params
WHERE input_param ~ '"name"\s*:\s*"(reportno|customerid|guarantorid|guarantorname|entname|customerId|guarantorId)"';

-- A6 agent_rule.request_params：数组元素
SELECT 'A6 agent_rule 残留' AS chk, count(*) AS should_be_zero
FROM agent_rule
WHERE request_params ~ '"(reportno|customerid|guarantorid|guarantorname|entname|customerId|guarantorId)"';

-- A7 knowledge_relate_input_param.input_param（易漏表）
SELECT 'A7 relate_input_param 残留' AS chk, count(*) AS should_be_zero
FROM knowledge_relate_input_param
WHERE input_param ~ '"name"\s*:\s*"(reportno|customerid|guarantorid|guarantorname|entname|customerId|guarantorId)"';

-- A8 删除条件后不应留下「悬挂的 AND」或「空 WHERE」
SELECT 'A8 悬挂 AND 残留' AS chk, count(*) AS should_be_zero
FROM index_params
WHERE script ~* '(AND\s+AND)|(WHERE\s+AND)';


-- ==================== B. 目标态到位（应大于 0）====================

SELECT 'B1 含 :reportNo 的指标' AS chk, count(*) AS expect_gt_zero
FROM index_params WHERE script LIKE '%:reportNo%';

SELECT 'B2 含 :entName 的指标' AS chk, count(*) AS expect_gt_zero
FROM index_params WHERE script LIKE '%:entName%';

SELECT 'B3 含 :guarantorName 的指标' AS chk, count(*) AS expect_gt_zero
FROM index_params WHERE script LIKE '%:guarantorName%';

-- B4/B5【准则要求】名称条件必须仍然存在，不得被删除
SELECT 'B4 customername 列引用仍在' AS chk, count(*) AS expect_gt_zero
FROM index_params WHERE lower(script) LIKE '%customername%';

SELECT 'B5 guarantorname 列引用仍在' AS chk, count(*) AS expect_gt_zero
FROM index_params WHERE lower(script) LIKE '%guarantorname%';

-- B6 参数声明：reportNo 声明应已就位
SELECT 'B6 含 reportNo 声明的指标' AS chk, count(*) AS expect_gt_zero
FROM index_params WHERE script ~ '"name"\s*:\s*"reportNo"';


-- ==================== C. 防误改（应大于 0）====================

-- C1/C2 表字段名空间：paramid / acturecolumn 存「指标来源字段名」，不是入参名
SELECT 'C1 paramid=REPORTNO 仍在' AS chk, count(*) AS expect_gt_zero
FROM index_params WHERE paramid = 'REPORTNO';

SELECT 'C2 acturecolumn=REPORTNO 仍在' AS chk, count(*) AS expect_gt_zero
FROM index_params WHERE acturecolumn = 'REPORTNO';

-- C3/C4 提示词里对「输入数据字段」的说明文案（描述数据字段，不是入参）
SELECT 'C3 contentdesc 文案仍在' AS chk, count(*) AS expect_gt_zero
FROM knowledge_base_params WHERE contentdesc LIKE '%reportno%';

SELECT 'C4 large_model_content 文案仍在' AS chk, count(*) AS expect_gt_zero
FROM knowledge_base_params WHERE large_model_content LIKE '%reportno%';

-- C5 {{objectName}} 占位符机制（绑定入参 entName，必须保留）
SELECT 'C5 {{ }} 占位符仍在' AS chk, count(*) AS expect_gt_zero
FROM knowledge_base_params WHERE prompt LIKE '%{{%';

-- C6【关键】SQL 里的**表间关联**绝不能被删：ON a.customerid = b.customerId
SELECT 'C6 表间关联 customerid 仍在' AS chk, count(*) AS expect_gt_zero
FROM index_params
WHERE script ~* '\.[a-z_]*customerid\s*=\s*[a-z_]+\.customerid';

-- C7 SQL 里的列引用未被误改（列引用不是参数名）
SELECT 'C7 列引用 customername 仍在' AS chk, count(*) AS expect_gt_zero
FROM index_params WHERE lower(script) LIKE '%customername%';


-- ==================== D. 规模核对（与 02 号脚本对照）====================
-- 02_入参规范化.sql 预期 236 条 UPDATE：
--   归一+删条件 195 行（index_params 81 / kb.relate_index_set 73 / kb.input_param 23 /
--                       agent_rule 14 / relate_input_param 4）
--   Batch B 41 条（为规则补 reportNo + entName 声明）
--
-- D1 确认「参数名已是驼峰、且已无废弃参数」
SELECT 'D1 参数名规范化核对' AS chk,
       sum(case when script ~ ':(reportNo|entName|guarantorName)' then 1 else 0 end) AS camel_hits,
       sum(case when script ~ ':(reportno|customerid|guarantorid|guarantorname|entname|customerId|guarantorId)'
                then 1 else 0 end) AS bad_hits
FROM index_params
WHERE script IS NOT NULL AND trim(script) <> '';
