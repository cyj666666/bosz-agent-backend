-- =====================================================================
-- 三个菜单 · 建表 DDL · 【C】 智策引擎菜单
--
-- 本组表数：2 张
-- 执行前置：SET search_path = <schema>, public;
-- 说明：交付包推荐直接执行 DDL/00_全部_44张表_一次性执行.sql（一次跑通 44 张）；
--       本文件是把该脚本按菜单分组拆出来的一份，便于「只想重建某一组」时单独执行。
--       脚本内无外键、无序列依赖，但**组内表之间可能互相引用数据**，重建请按 A→E 顺序。
-- =====================================================================

-- =====================================================================
-- C. 智策引擎菜单
-- =====================================================================

-- ---------------------------------------------------------------
-- [25/44] agent_rule —— 规则配置（主表）
-- ---------------------------------------------------------------
CREATE TABLE agent_rule (
    id                       BIGINT NOT NULL AUTO_INCREMENT,
    rule_name                VARCHAR(255),
    rule_text                TEXT,
    parsed_expression        TEXT,
    rule_status              CHAR(1),
    input_time               VARCHAR(30),
    input_user               VARCHAR(100),
    update_time              VARCHAR(30),
    update_user              VARCHAR(30),
    prompt_key               VARCHAR(300),
    topic1                   VARCHAR(200),
    topic2                   VARCHAR(200),
    threshold_config         TEXT,
    risk_remark              TEXT,
    disposal_advice          TEXT,
    additional_analysis      TEXT,
    rule_code                VARCHAR(200) NOT NULL,
    additional_analysis_name VARCHAR(200),
    rule_struct              VARCHAR(300),
    fact_analysis            TEXT,
    request_params           VARCHAR(2000),
    PRIMARY KEY (id)
);
COMMENT ON TABLE agent_rule IS '规则配置';
COMMENT ON COLUMN agent_rule.id IS '规则ID';
COMMENT ON COLUMN agent_rule.rule_name IS '规则名称';
COMMENT ON COLUMN agent_rule.rule_text IS '规则原文';
COMMENT ON COLUMN agent_rule.parsed_expression IS '解析逻辑表达式';
COMMENT ON COLUMN agent_rule.rule_status IS '规则状态 Y有效 N无效';
COMMENT ON COLUMN agent_rule.input_time IS '入库时间';
COMMENT ON COLUMN agent_rule.input_user IS '录入人';
COMMENT ON COLUMN agent_rule.update_time IS '更新时间';
COMMENT ON COLUMN agent_rule.update_user IS '更新人';
COMMENT ON COLUMN agent_rule.prompt_key IS '提示词key';
COMMENT ON COLUMN agent_rule.topic1 IS '一级主题';
COMMENT ON COLUMN agent_rule.topic2 IS '二级主题';
COMMENT ON COLUMN agent_rule.threshold_config IS '阈值设定';
COMMENT ON COLUMN agent_rule.risk_remark IS '风险释义';
COMMENT ON COLUMN agent_rule.disposal_advice IS '处置建议';
COMMENT ON COLUMN agent_rule.additional_analysis IS '补充分析';
COMMENT ON COLUMN agent_rule.rule_code IS '规则编码';
COMMENT ON COLUMN agent_rule.additional_analysis_name IS '补充分析名称';
COMMENT ON COLUMN agent_rule.rule_struct IS '规则结果结构';
COMMENT ON COLUMN agent_rule.fact_analysis IS '事实分析';
COMMENT ON COLUMN agent_rule.request_params IS '请求参数';
CREATE UNIQUE INDEX uk_agent_rule_rule_code ON agent_rule (rule_code);
-- ↑ 原公司脚本在此处有一条「事后加宽」语句：ALTER TABLE agent_rule MODIFY COLUMN rule_text TEXT;
--   本脚本已把它**内联进上面的列定义**（rule_text = TEXT，与公司库实际类型一致），故此处不再需要该语句。
--   原因：原写法是 MySQL 风格 `MODIFY COLUMN`，在纯 PG 模式的库上可能不被支持；内联后两种模式都能跑。
-- ↑ 原公司脚本在此处有一条「事后加宽」语句：ALTER TABLE agent_rule MODIFY COLUMN parsed_expression TEXT;
--   本脚本已把它**内联进上面的列定义**（parsed_expression = TEXT，与公司库实际类型一致），故此处不再需要该语句。
--   原因：原写法是 MySQL 风格 `MODIFY COLUMN`，在纯 PG 模式的库上可能不被支持；内联后两种模式都能跑。

-- ---------------------------------------------------------------
-- [26/44] agent_rule_prompt —— Agent 大模型提示词配置表
-- ---------------------------------------------------------------
CREATE TABLE agent_rule_prompt (
    key                    VARCHAR(300) NOT NULL,
    prompt                 TEXT NOT NULL,
    PRIMARY KEY (key)
);
COMMENT ON TABLE agent_rule_prompt IS 'Agent大模型提示词配置表';
COMMENT ON COLUMN agent_rule_prompt.key IS '提示词唯一标识key';
COMMENT ON COLUMN agent_rule_prompt.prompt IS 'prompt提示词内容';
