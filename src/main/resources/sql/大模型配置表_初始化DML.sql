-- =============================================================================
-- large_model_config：配置「AI 全文分析」用的大模型
-- =============================================================================
-- 表已存在（建表语句在 sql/agent/agent_gauss_ddl.sql:3499），本文件只负责插一行配置。
--
-- ⚠️ 本工程**自定义**这张表的字段语义（见下表），与其它工程的口径无关。
--    因此用本工程专属 lm_code = 'bosz-report-ai'，不与其它工程的行混用 ——
--    否则同一行会被两个工程按不同规则解读，必然有一边出错。
--
-- 代码侧通过 report.ai-analysis.lm-code 指定读哪一行（application.yml 默认就是下面这个 lm_code）。
-- =============================================================================
-- 字段语义（与 LargeModelGatewayClient / entity.LargeModelConfig 保持一致）
-- =============================================================================
--   lm_code            配置编码，代码按它取行                    必填
--   url                完整 chat completions 地址（含 /v1/chat/completions）；代码原样请求，不做拼接   必填
--   api_key            明文 key，作为 Authorization: Bearer；留空则不带该头
--   model              请求体里的 model
--   default_think_flag 是否开启深度思考：Y 开 / N 关（默认）。开时请求体带 enable_thinking
--                      与 chat_template_kwargs（Qwen3 靠后者才真关得掉思考，避免思考过程混进正文）
--   max_tokens         > 0 才传 max_tokens，否则交给网关默认值
--   model_config       可选，额外请求参数 JSON 对象，原样并入请求体，如 '{"temperature":0.1}'
--   use_flag           有效标志：Y 可用；非 Y 会直接报「大模型配置已停用」
--   lm_name            中文名，仅界面展示
--   lm_desc            备注，不参与逻辑
--   with_think         保留列，代码不使用
--   create_time/update_time  不参与逻辑（交 DB 默认值即可）
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 【执行前替换】url / api_key / model 三处 TODO
-- -----------------------------------------------------------------------------
INSERT INTO large_model_config
    (lm_code, model, lm_name, url, api_key, lm_desc,
     use_flag, with_think, default_think_flag, max_tokens, model_config)
VALUES
    ('bosz-report-ai',
     'default',
     '贷后报告-AI全文分析',
     'TODO-完整地址，例：http://172.20.2.250:1035/v1/chat/completions',
     'TODO-明文 api key',
     '报告详情页「AI分析全文」使用；本工程自定义字段语义：api_key 明文、url 为完整地址',
     'Y',
     'N',
     'N',
     0,
     NULL);

-- 说明：
-- 1) max_tokens 填 0 表示不传该字段，由网关决定输出上限。
-- 2) 关闭思考就保持 default_think_flag = 'N'（推荐）。若某些模型必须开思考才能出好结果，
--    改成 'Y' 即可，不需要改代码。
-- 3) 想微调采样参数不必改代码，把 model_config 写成 JSON 对象即可，例如：
--    '{"temperature":0.1,"top_p":0.7}'
--    （model / messages / stream 由代码装配，写在这里也不会生效）
-- 4) 该表 lm_code 上有唯一索引，重复执行会报唯一键冲突；执行前先确认不存在：
--    SELECT id, lm_code FROM large_model_config WHERE lm_code = 'bosz-report-ai';
-- 5) 换网关或换模型：直接改这一行（或另插一行再把 report.ai-analysis.lm-code 指过去）。
-- -----------------------------------------------------------------------------
