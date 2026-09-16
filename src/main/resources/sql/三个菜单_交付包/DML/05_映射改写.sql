-- =====================================================================
-- 三个菜单 · DML 步骤 2/4 —— 映射改写
--
-- 🔴🔴 **每次重导数据之后，都必须重新执行本文件！**
--    因为 01~04 的数据文件里存的是**公司口径**（导出时还没改写）：
--      · index_params.script 里引用的是公司的数据源 id
--      · knowledge_base_params.large_model_code 是公司的模型 code
--      · large_model_content 的 JSON key 也是公司的模型 code
--    重导会把改写结果**整片覆盖**掉。典型症状（后端报错）：
--      ERROR ... 数据源信息不存在,dataSourceId:2095447359636992001
--    或者智策引擎报「未找到大模型配置」。
--
-- 执行前置：数据文件 01~04 已全部导入完成
-- 自动化：下面全部用**子查询**从目标库实时取值，**一般不需要手工替换**。
--         ⚠️ 若目标库有**多条**数据源、或**多个**启用中的模型，子查询会取 id 最小的那个 ——
--            这种情况请把子查询换成你确认的那一个（例如 (SELECT id FROM sys_data_source WHERE code='xxx')）。
-- 幂等：可重复执行（UPDATE 是覆盖式，跑几次结果一样）
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

-- ④ 「模型信息」里**嵌套的** largeModelCode 也要换
--    ⚠️ ③ 只换了 JSON 的 **key**（`"Qwen3-32B":`），**漏了嵌套 value** ——
--       条件组里还有一处 `"modelInfo":{"largeModelCode":"Qwen3-32B"}`。
--       漏改的后果：知识库「配置 → 详情页」右栏「输出要求 → 模型信息」显示的是**公司库的旧模型名**，
--       而目标库的模型下拉里根本没有这个 code → 用户看到"模型信息不是我的库里的模型"。
--    三列都可能有，且形态不同：
--       contentdesc        （当前模型的输出要求片段，形态 `"largeModelCode":"Qwen3-32B"`）
--       input_condition    （输入条件，同样是 `"largeModelCode":"Qwen3-32B"`）
--       large_model_content（整张 map，内部引号是**转义**过的 `\"largeModelCode\":\"Qwen3-32B\"`）
--    → 所以这里**直接对整个文本做裸串替换**，两种形态一次覆盖（同一模型换 code，语义无损）。
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, 'Qwen3-32B',
                             (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1))
 WHERE contentdesc LIKE '%Qwen3-32B%';

UPDATE knowledge_base_params
   SET input_condition = replace(input_condition, 'Qwen3-32B',
                             (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1))
 WHERE input_condition LIKE '%Qwen3-32B%';

UPDATE knowledge_base_params
   SET large_model_content = replace(large_model_content, 'Qwen3-32B',
                             (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1))
 WHERE large_model_content LIKE '%Qwen3-32B%';

-- 版本表同名列（注意：版本表叫 **content_desc**，参数表叫 contentdesc，别写错）
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

-- 历史残留小写 `qwen3`（公司库里改过模型 code，key 与嵌套 value 都留过小写形态）
UPDATE knowledge_base_params
   SET contentdesc = replace(replace(contentdesc, '"qwen3":', '"' || (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1) || '":'),
                             '"largeModelCode":"qwen3"',
                             '"largeModelCode":"' || (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1) || '"')
 WHERE contentdesc LIKE '%qwen3%';

UPDATE knowledge_base_params
   SET input_condition = replace(input_condition, '"largeModelCode":"qwen3"',
                             '"largeModelCode":"' || (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1) || '"')
 WHERE input_condition LIKE '%qwen3%';

-- 说明：历史记录表 call_llm_record.large_model_code **保留原值**（它记录当时真实调用的模型），不改。
