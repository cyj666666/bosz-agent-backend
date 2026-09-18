-- =====================================================================
-- 三个菜单 · DML · 本地库快照 · 08
--
-- 数据来源：**本地库** 127.0.0.1:5432/bosz  schema=as_agent（只读导出）
-- 快照时间：2026-09-18 13:46:27
-- 对应源文件：DML/08_数据_结果校验模板_大模型评估.sql
-- 执行前置：SET search_path = <schema>, public;
-- 说明：仅含 INSERT（纯数据快照，不含原文件里的 UPDATE / 校验语句）。
-- =====================================================================

-- 表 / 行数：prompt_verify_scene_info 1 行、prompt_verify_scene_relate_prompt_info 1 行
-- 合计 2 行
-- =====================================================================
-- DbDump 生成（来源 schema=as_agent，本地库快照）
-- 仅含 INSERT，执行前请先 SET search_path

-- ===== prompt_verify_scene_info (7 列) =====
INSERT INTO prompt_verify_scene_info (id,scene_code,scene_name,create_time,update_time,scene_group,scene_desc) VALUES ('1952350290730319874','大模型评估','大模型评估','2025-08-04 20:45:56','2025-08-04 20:45:56','Finance','');

-- ===== prompt_verify_scene_relate_prompt_info (10 列) =====
INSERT INTO prompt_verify_scene_relate_prompt_info (id,scene_id,large_model_code,prompt_name,prompt_template,status,create_time,update_time,expect_format,prompt_parameters) VALUES ('1952350710886334466','1952350290730319874','bosz-report-ai','大模型评估','#你是一位大模型输出结构验证的专家，擅长比对大模型的输入和输出结果，从多个维度判断大模型基于输入内容输出的结果质量

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

