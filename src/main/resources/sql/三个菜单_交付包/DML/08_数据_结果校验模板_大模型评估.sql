-- =====================================================================
-- 三个菜单 · DML 步骤 —— 「结果校验」提示词模板（场景：大模型评估）
--
-- 为什么需要这一份：
--   知识库配置 → 预览 → 「结果校验」按钮，后端会读
--     prompt_verify_scene_info（scene_name = 大模型评估）
--     + prompt_verify_scene_relate_prompt_info
--   取 prompt_template 作为校验提示词模板（占位符 {rewrite_question} / {answer} / {cur_time}）。
--   **不导入这两行，点「校验」不会有任何输出** ——
--   后端只会记一条「结果校验时，未查询到相关模版信息！」然后直接结束 SSE 流。
--   实测：公司库（172.20.2.19:8000/bosz_test）这两张表本身也是 0 行，
--   所以这份数据来源于源工程仓库 doc/db/mysql/DML.sql 的原始行（逐字提取、未改写）。
--
-- 内容：
--   ① prompt_verify_scene_info               —— 1 行（场景定义）
--   ② prompt_verify_scene_relate_prompt_info —— 1 行（该场景的校验提示词模板）
--   ③ 把模板上的 large_model_code 对齐到目标环境启用中的模型
--
-- 执行前置：DDL 已建表（prompt_verify_scene_info / prompt_verify_scene_relate_prompt_info
--           属「三个菜单」的共用支撑表，见 DDL/05_E_覆盖率补漏_5张.sql）。
-- 幂等性：纯 INSERT，主键冲突即报错（id 为固定雪花号）；要重跑请先删这两行。
-- 与 05_映射改写.sql 的关系：两者互不依赖，顺序无所谓（③ 自带子查询，自动对齐）。
--
-- ⚠️ 下面 ② 的 prompt_template 是**多行文本**（内含换行与 JSON 示例），属正常，勿手工折行/重排。
-- =====================================================================

-- ① 场景：大模型评估
INSERT INTO prompt_verify_scene_info (id,scene_code,scene_name,create_time,update_time,scene_desc,scene_group) VALUES ('1952350290730319874','大模型评估','大模型评估','2025-08-04 20:45:56','2025-08-04 20:45:56','','Finance');

-- ② 该场景下的校验提示词模板（多行文本，逐字来自源仓库，未改写）
INSERT INTO prompt_verify_scene_relate_prompt_info (id,scene_id,large_model_code,prompt_name,prompt_template,status,create_time,update_time,expect_format,prompt_parameters) VALUES ('1952350710886334466','1952350290730319874','h20-telecom-r1','大模型评估','#你是一位大模型输出结构验证的专家，擅长比对大模型的输入和输出结果，从多个维度判断大模型基于输入内容输出的结果质量

#当前时间为{cur_time}

#验证维度包括以下内容：
1、验证大模型数值输出的准确性，对比大模型输出结果中涉及的数值和输入内容中的数值是否一致，是否存在单位、百分比转换错误、数值计算错误的问题，如发现问题按照以下格式输出：
{"类型":"数值错误","具体描述":输出结果中的xxx数值或者指标与输入内容中的xxx数值或者指标不一致}
注意：1.大模型对输入数值的四舍五入不算数值错误 2."X个百分点"和"X%"是相等的，不算错误

2、验证大模型输出内容前后一致性，对比大模型输出结果的上下文描述内容，判断是否存在上下文中事实描述矛盾或者分析矛盾，如发现问题按照以下格式输出：
{{"类型":"逻辑前后矛盾","具体描述":输出结果中的"xxx"与上文中的"xxx"的描述前后矛盾}}

3、验证大模型输出内容是否存在幻觉，对比大模型输出结果的事实型内容是否与输入内容中的内容一致，是否存在超出输入内容内容的事实性内容幻觉问题，如发现问题按照以下格式输出：
{"类型":"事实性幻觉","具体描述":输出结果中的"xxx"与输入内容中的xxx描述不符，或者输出结果中的"xxx"未出现在输入内容中}

4、验证大模型输出内容是否事实类客观描述占比较少，基于客观描述的大模型主观发挥较多，如发现问题按照以下格式输出：
{"类型":"主观描述过多","具体描述":"大模型主观描述占比xxx%以上"}

##若从上述4个维度经验证后发现大模型输出结果没有问题，问答结果仅输出{"类型":"符合要求"}

#输入内容：
{rewrite_question}

#大模型输出内容：
{answer}','Y','2025-08-04 20:47:37','2025-12-12 14:31:25','json','[
  {
    "name": "cur_time",
    "description": "当前时间为",
    "type": "string"
  },
  {
    "name": "rewrite_question",
    "description": "改写问题",
    "type": "string"
  },
  {
    "name": "answer",
    "description": "回答",
    "type": "string"
  }
]');

-- ③ 对齐 large_model_code 到目标环境「启用中」的模型
--    源数据上的值是公司环境的模型 code（h20-telecom-r1），目标环境通常没有这个模型。
--    后端只在请求未带 largeModelCode 时才回落到这个值，改掉可避免「非法的大模型CODE」。
UPDATE prompt_verify_scene_relate_prompt_info
   SET large_model_code = (SELECT lm_code FROM large_model_config WHERE use_flag = 'Y' ORDER BY id LIMIT 1)
 WHERE id = '1952350710886334466';
