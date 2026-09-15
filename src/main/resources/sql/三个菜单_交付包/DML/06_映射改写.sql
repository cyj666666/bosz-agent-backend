-- =====================================================================
-- 三个菜单 · DML 步骤 2/4 —— 映射改写
--
-- 执行前置：数据文件 01~04 已全部导入完成
-- 为什么需要：数据是从公司库导出的，里面引用的「数据源 id / 大模型 code」是**公司口径**，
--             必须改成目标环境的口径，否则「SQL 预览 / 取数 / 大模型调用」会找不到对象。
-- 自动化：下面全部用**子查询**从目标库实时取值，**一般不需要手工替换**。
--         ⚠️ 若目标库有**多条**数据源、或**多个**启用中的模型，子查询会取 id 最小的那个 ——
--            这种情况请把子查询换成你确认的那一个（例如 (SELECT id FROM sys_data_source WHERE code='xxx')）。
-- =====================================================================

-- ① 指标 index_params.script 里引用的数据源 id
--    公司值 2095447359636992001 → 目标库的数据源 id
--    不改的后果：指标编辑页的「数据源下拉」回显不出来、SQL 预览/取数找不到数据源
UPDATE index_params
   SET script = replace(script,
                        '2095447359636992001',
                        (SELECT id FROM sys_data_source ORDER BY id LIMIT 1))
 WHERE script LIKE '%2095447359636992001%';

-- ② 大模型编码（知识库主表 + 版本表）→ 目标库启用中的模型 code
--    注意：这个 code 必须等于后端 yml 里的 agent.rule.parse-model-code（智策引擎解析用的模型）
UPDATE knowledge_base_params
   SET large_model_code = (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1)
 WHERE large_model_code IS NOT NULL
   AND large_model_code <> (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1);

UPDATE knowledge_base_version
   SET large_model_code = (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1)
 WHERE large_model_code IS NOT NULL
   AND large_model_code <> (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1);

-- ③ large_model_content 的 JSON **key** 也要换
--    该列是 {"模型code": 条件组JSON} 的字符串；key 不改的话，
--    知识库编辑器切到该模型时**取不到那份「输出要求」，用户一改一保存就会把数据覆盖掉**。
UPDATE knowledge_base_params
   SET large_model_content = replace(large_model_content,
                                     '"Qwen3-32B":',
                                     '"' || (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1) || '":')
 WHERE large_model_content LIKE '%"Qwen3-32B":%';

-- 历史残留 key（公司库里改过模型 code，留下过小写 qwen3）
UPDATE knowledge_base_params
   SET large_model_content = replace(large_model_content,
                                     '"qwen3":',
                                     '"' || (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1) || '":')
 WHERE large_model_content LIKE '%"qwen3":%';

UPDATE knowledge_base_version
   SET large_model_content = replace(large_model_content,
                                     '"Qwen3-32B":',
                                     '"' || (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1) || '":')
 WHERE large_model_content LIKE '%"Qwen3-32B":%';

-- 说明：历史记录表 call_llm_record.large_model_code **保留原值**（它记录当时真实调用的模型），不改。
