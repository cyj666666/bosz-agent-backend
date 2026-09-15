-- =====================================================================
-- 【仅本地自测用 · 不入交付包】
-- 修复：知识库「模型信息」显示旧模型 Qwen3-32B
--
-- 背景：库里 `large_model_code` 和 `large_model_content` 的 **JSON key** 都已是 bosz-report-ai，
--       但条件组里**嵌套的** `"modelInfo":{"largeModelCode":"Qwen3-32B"}` 没被改写 ——
--       原来的 `05_映射改写.sql` 只 `replace('"Qwen3-32B":')`（带冒号的 key 形态），
--       匹配不到后面跟 `}` 的 value 形态。
--       详情页右栏「输出要求 → 模型信息」读的正是这个嵌套字段 → 于是显示 Qwen3-32B。
--
-- 目标库：本机 127.0.0.1:5432/bosz 的 as_agent（应用 dev 档实际连的库）
-- 执行前置：SET search_path = as_agent, public;
-- 幂等：replace 到目标 code 后再跑不会变（WHERE 也命中不了），可重复执行。
-- =====================================================================

-- ① contentdesc（当前模型的输出要求片段）—— 实测 86 行
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, 'Qwen3-32B',
                             (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1))
 WHERE contentdesc LIKE '%Qwen3-32B%';

-- ② input_condition（输入条件）—— 实测 27 行
UPDATE knowledge_base_params
   SET input_condition = replace(input_condition, 'Qwen3-32B',
                             (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1))
 WHERE input_condition LIKE '%Qwen3-32B%';

-- ③ large_model_content（整张 map，引号是转义形态）—— 实测 86 行
UPDATE knowledge_base_params
   SET large_model_content = replace(large_model_content, 'Qwen3-32B',
                             (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1))
 WHERE large_model_content LIKE '%Qwen3-32B%';

-- ④ 版本表同名列（注意：版本表叫 content_desc，参数表叫 contentdesc）
UPDATE knowledge_base_version
   SET content_desc = replace(content_desc, 'Qwen3-32B',
                             (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1))
 WHERE content_desc LIKE '%Qwen3-32B%';

UPDATE knowledge_base_version
   SET input_condition = replace(input_condition, 'Qwen3-32B',
                             (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1))
 WHERE input_condition LIKE '%Qwen3-32B%';

UPDATE knowledge_base_version
   SET large_model_content = replace(large_model_content, 'Qwen3-32B',
                             (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1))
 WHERE large_model_content LIKE '%Qwen3-32B%';

-- ⑤ 历史残留小写 qwen3（本地实测参数表已为 0，防御性执行；版本表同样处理）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '"largeModelCode":"qwen3"',
                             '"largeModelCode":"' || (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1) || '"')
 WHERE contentdesc LIKE '%"largeModelCode":"qwen3"%';

UPDATE knowledge_base_params
   SET input_condition = replace(input_condition, '"largeModelCode":"qwen3"',
                             '"largeModelCode":"' || (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1) || '"')
 WHERE input_condition LIKE '%"largeModelCode":"qwen3"%';

UPDATE knowledge_base_params
   SET large_model_content = replace(large_model_content, '"qwen3":',
                             '"' || (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1) || '":')
 WHERE large_model_content LIKE '%"qwen3":%';

UPDATE knowledge_base_version
   SET large_model_content = replace(large_model_content, '"qwen3":',
                             '"' || (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1) || '":')
 WHERE large_model_content LIKE '%"qwen3":%';

-- =====================================================================
-- 校验：以下 5 条应全部为 0
-- =====================================================================
SELECT 'params.contentdesc 残留'      AS 检查项, count(*) AS 实际值 FROM knowledge_base_params  WHERE contentdesc       LIKE '%Qwen3-32B%'
UNION ALL SELECT 'params.input_condition 残留', count(*) FROM knowledge_base_params  WHERE input_condition LIKE '%Qwen3-32B%'
UNION ALL SELECT 'params.large_model_content 残留', count(*) FROM knowledge_base_params  WHERE large_model_content LIKE '%Qwen3-32B%'
UNION ALL SELECT 'version.content_desc 残留',  count(*) FROM knowledge_base_version WHERE content_desc    LIKE '%Qwen3-32B%'
UNION ALL SELECT 'version.large_model_content 残留', count(*) FROM knowledge_base_version WHERE large_model_content LIKE '%Qwen3-32B%'
ORDER BY 1;
