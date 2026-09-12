-- =============================================================================
-- large_model_config：配置「AI 全文分析」用的大模型
-- 目标模型：DeepSeek-V4.1-Flash（公网直连 DeepSeek 官方 API）
-- =============================================================================
-- 表已存在（建表语句在 sql/agent/agent_gauss_ddl.sql:3499），本文件只负责插一行配置。
--
-- ⚠️ 本工程**自定义**这张表的字段语义，与其它工程的口径无关。
--    因此用本工程专属 lm_code = 'bosz-report-ai'，不与其它工程的行混用。
--    代码侧通过 report.ai-analysis.lm-code 取行，application.yml 默认值就是这个，
--    所以下面这行插进去后**不需要改 yml、不需要改代码**。
--
-- 关于 url：填「代码要直接 POST 的完整地址」。
--   · 公网直连 DeepSeek 官方  → https://api.deepseek.com/chat/completions
--   · 走行内统一网关/代理     → 填那个网关的完整地址（形如 http://内网IP:端口/v1/chat/completions）
--   注意：某个工程的 172.20.2.250 只是它自己的内网网关，不是本工程必须用这个。
-- =============================================================================
-- 字段语义（与 LargeModelGatewayClient / entity.LargeModelConfig 保持一致）
-- =============================================================================
--   lm_code            配置编码，代码按它取行                    必填
--   url                完整 chat completions 地址；代码原样请求，不做任何拼接   必填
--   api_key            明文 key，作为 Authorization: Bearer；留空则不带该头
--   model              请求体里的 model，必须与网关侧登记的模型名一字不差（大小写敏感）
--   default_think_flag Y 开 / N 关（默认）。⚠️ 代码目前**无条件**传 enable_thinking
--                      与 chat_template_kwargs（Qwen 系推理后端的写法）；DeepSeek 用的是
--                      thinking:{type:...} + reasoning_effort。多数兼容网关会忽略未知字段，
--                      若返回 400 需改代码加开关
--   max_tokens         > 0 才传，否则交给网关默认值
--   model_config       可选，额外请求参数 JSON 对象，原样并入请求体。**代码不传 temperature /
--                      top_p / thinking，要调这些只能写在这里**，例：
--                      '{"thinking":{"type":"enabled"},"reasoning_effort":"high"}'
--   use_flag           Y 可用；非 Y 直接报「大模型配置已停用」
--   lm_name            中文名，仅界面展示
--   lm_desc            备注，不参与逻辑
--   with_think         保留列，代码不使用
--   create_time/update_time  不参与逻辑（交 DB 默认值即可）
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 第 0 步：先确认这行不存在（lm_code 上有唯一索引，已存在则改走文末的 UPDATE）
-- -----------------------------------------------------------------------------
-- SELECT id, lm_code, model, url, use_flag FROM large_model_config WHERE lm_code = 'bosz-report-ai';

-- -----------------------------------------------------------------------------
-- 第 1 步：插入配置 —— 只需替换下面 1 处 TODO（api_key）
-- -----------------------------------------------------------------------------
-- api_key 从 https://platform.deepseek.com/api_keys 申请，形如 sk-xxxxxxxx
INSERT INTO large_model_config
    (lm_code, model, lm_name, url, api_key, lm_desc,
     use_flag, with_think, default_think_flag, max_tokens, model_config)
VALUES
    ('bosz-report-ai',                                  -- 与 application.yml 的 lm-code 一致
     'deepseek-flash',                                  -- 当前有效的模型名（见下方说明）
     '贷后报告-AI全文分析',
     'https://api.deepseek.com/chat/completions',       -- 完整地址，代码原样 POST
     'TODO-你的 DeepSeek api key（sk-...）',
     'DeepSeek-V4.1-Flash，公网直连；用于报告详情页「AI分析全文」',
     'Y',                                               -- 启用
     'N',                                               -- with_think 不参与逻辑，固定 N
     'N',                                               -- 关思考（DeepSeek 默认即关）
     0,                                                 -- 0 = 不传 max_tokens，交网关默认
     NULL);                                             -- 要开思考见文末说明

-- 【model 为什么填 deepseek-flash 而不是 DeepSeek-V4.1-Flash】
--   DeepSeek 官方文档（2026-09-12）明确：模型名请使用 deepseek-flash；
--   旧名 deepseek-v4-flash / deepseek-v4-flash-vision-exp 仍可调用，但对应模型已下线，
--   请求由 DeepSeek-V4.1-Flash 模型承接、按 Flash 价格计费。
--   所以想要 DeepSeek-V4.1-Flash，就填 deepseek-flash。
--   另外「模型名」是网关侧登记的名字，必须一字不差（大小写敏感）。

-- -----------------------------------------------------------------------------
-- 备选：如果第 0 步查出这行已存在，改用 UPDATE
-- -----------------------------------------------------------------------------
-- UPDATE large_model_config
--    SET model = 'deepseek-flash',
--        lm_name = '贷后报告-AI全文分析',
--        url = 'https://api.deepseek.com/chat/completions',
--        api_key = 'TODO-你的 api key',
--        use_flag = 'Y',
--        default_think_flag = 'N',
--        max_tokens = 0,
--        model_config = NULL,
--        update_time = CURRENT_TIMESTAMP
--  WHERE lm_code = 'bosz-report-ai';

-- -----------------------------------------------------------------------------
-- 想开深度思考时：不用改代码，把 model_config 写成 DeepSeek 的写法即可
-- -----------------------------------------------------------------------------
-- UPDATE large_model_config
--    SET model_config = '{"thinking":{"type":"enabled"},"reasoning_effort":"high"}'
--  WHERE lm_code = 'bosz-report-ai';

-- -----------------------------------------------------------------------------
-- 配置完怎么验证（不需要重启后端 —— 代码每次调用都重新查这张表）
-- -----------------------------------------------------------------------------
-- 1) 详情页点「AI分析全文」→ 确认弹框 → 开始分析
-- 2) 失败时页面显示 fail_reason，常见几类：
--    · HTTP 404（…请确认 url 是完整的 chat completions 地址…）  → url 写错
--    · HTTP 401 / 403                                            → api_key 不对
--    · HTTP 402                                                  → 账户余额/额度问题
--    · HTTP 400                                                  → model 名不对，或网关不接受
--      enable_thinking / chat_template_kwargs（需改代码）
--    · 连接超时 / UnknownHost                                    → 运行环境没有公网出口，
--      需改走行内统一网关（把 url 换成网关地址）
-- 3) 想看实际发出去的请求，查 app_report_ai_analysis 的 source_snapshot / prompt_snapshot
-- -----------------------------------------------------------------------------
