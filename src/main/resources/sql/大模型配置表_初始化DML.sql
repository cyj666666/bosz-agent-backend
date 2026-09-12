-- =============================================================================
-- large_model_config 初始化 DML（AI 全文分析用）
-- =============================================================================
-- ⚠️ 这张表**已经存在**，不需要再建：建表语句在 sql/agent/agent_gauss_ddl.sql 第 3499 行，
--    直接执行本文件插一行配置即可（重复建表会报「表已存在」）。
--
-- 用途：AI 全文分析靠这张表取大模型网关的地址与密钥。
--       代码侧用 report.ai-analysis.lm-code 指定取哪一行（默认 default），
--       所以下面这行的 lm_code 要与 application.yml 的 lm-code 一致。
--
-- ⚠️ 执行前请替换：url（chat completions 完整地址）、api_key、model
-- ⚠️ 该表 lm_code 上有唯一索引，重复执行会报唯一键冲突；执行前先确认不存在。
-- =============================================================================

INSERT INTO large_model_config
    (lm_code, model, lm_name, url, api_key, lm_desc,
     use_flag, with_think, default_think_flag, max_tokens, model_config)
VALUES
    ('default',
     'TODO-模型名，如 qwen-max / deepseek-chat',
     '贷后报告全文分析',
     'TODO-完整地址，如 http://网关地址/v1/chat/completions',
     'TODO-api key',
     '用于报告详情页「AI分析全文」的大模型网关',
     'Y',
     'N',
     'N',
     4096,
     NULL);

-- 说明：
-- 1) 需要开启「深度思考」时，把 model_config 写成 JSON，会被原样并入请求体，例如：
--    '{"enable_thinking": true}'
--    各网关开启思考的字段名不统一（enable_thinking / thinking / enable_search…），
--    所以代码没有硬编码，统一由 model_config 承载，换网关不用改代码。
-- 2) max_tokens <= 0 表示不传该字段，交给网关默认值。
-- 3) use_flag 置 'N' 即停用该配置，代码会直接报「大模型配置已停用」。
