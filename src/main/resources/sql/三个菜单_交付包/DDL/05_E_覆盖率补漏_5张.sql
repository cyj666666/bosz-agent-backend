-- =====================================================================
-- 三个菜单 · 建表 DDL · 【E】 代码真实查询、但不在实体映射里的表（覆盖率补漏，2026-09-15 加）
--
-- 本组表数：5 张
-- 执行前置：SET search_path = <schema>, public;
-- 说明：交付包推荐直接执行 DDL/00_全部_44张表_一次性执行.sql（一次跑通 44 张）；
--       本文件是把该脚本按菜单分组拆出来的一份，便于「只想重建某一组」时单独执行。
--       脚本内无外键、无序列依赖，但**组内表之间可能互相引用数据**，重建请按 A→E 顺序。
-- =====================================================================

-- =====================================================================
-- E. 代码真实查询、但不在实体映射里的表（覆盖率补漏，2026-09-15 加）
-- =====================================================================

-- ---------------------------------------------------------------
-- [40/44] sys_dict —— agent 模块自带字典主表（AgentDictMapper / AgentDictCache 直查，非宿主表）
-- ---------------------------------------------------------------
CREATE TABLE sys_dict (
    id                     VARCHAR(32) NOT NULL,
    dict_name              VARCHAR(100) NOT NULL,
    dict_code              VARCHAR(100) NOT NULL,
    description            VARCHAR(255),
    del_flag               INT,
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    type                   INT DEFAULT 0,
    PRIMARY KEY (id)
);
-- ↑ 下面这条表级注释为【本工程补写】（源 DDL 未提供），措辞按该表列注释口径归纳
COMMENT ON TABLE sys_dict IS '数据字典表';
COMMENT ON COLUMN sys_dict.dict_name IS '字典名称';
COMMENT ON COLUMN sys_dict.dict_code IS '字典编码';
COMMENT ON COLUMN sys_dict.description IS '描述';
COMMENT ON COLUMN sys_dict.del_flag IS '删除状态';
COMMENT ON COLUMN sys_dict.create_by IS '创建人';
COMMENT ON COLUMN sys_dict.create_time IS '创建时间';
COMMENT ON COLUMN sys_dict.update_by IS '更新人';
COMMENT ON COLUMN sys_dict.update_time IS '更新时间';
COMMENT ON COLUMN sys_dict.type IS '字典类型0为string,1为number';
CREATE UNIQUE INDEX indextable_dict_code ON sys_dict (dict_code);

-- ---------------------------------------------------------------
-- [41/44] sys_dict_item —— agent 模块自带字典项
-- ---------------------------------------------------------------
CREATE TABLE sys_dict_item (
    id                     VARCHAR(32) NOT NULL,
    dict_id                VARCHAR(32),
    item_text              VARCHAR(100) NOT NULL,
    item_value             VARCHAR(100) NOT NULL,
    description            VARCHAR(255),
    sort_order             INT,
    status                 INT,
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    synonym_word           VARCHAR(100),
    key_word               VARCHAR(500),
    rela_table             VARCHAR(100),
    field_attr             VARCHAR(400),
    remark                 VARCHAR(100),
    PRIMARY KEY (id)
);
-- ↑ 下面这条表级注释为【本工程补写】（源 DDL 未提供），措辞按该表列注释口径归纳
COMMENT ON TABLE sys_dict_item IS '数据字典项表';
COMMENT ON COLUMN sys_dict_item.dict_id IS '字典id';
COMMENT ON COLUMN sys_dict_item.item_text IS '字典项文本';
COMMENT ON COLUMN sys_dict_item.item_value IS '字典项值';
COMMENT ON COLUMN sys_dict_item.description IS '描述';
COMMENT ON COLUMN sys_dict_item.sort_order IS '排序';
COMMENT ON COLUMN sys_dict_item.status IS '状态（1启用 0不启用）';
COMMENT ON COLUMN sys_dict_item.synonym_word IS '同义词';
COMMENT ON COLUMN sys_dict_item.key_word IS '关键词';
COMMENT ON COLUMN sys_dict_item.rela_table IS '关联表';
COMMENT ON COLUMN sys_dict_item.field_attr IS '字段属性';
COMMENT ON COLUMN sys_dict_item.remark IS '备注';

-- ---------------------------------------------------------------
-- [42/44] agent_config —— 智能体配置（知识库/指标配置的「关联 Agent」下拉；AgentConfigMapper 直查）
-- ---------------------------------------------------------------
CREATE TABLE agent_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    agent_name             VARCHAR(100) NOT NULL,
    agent_code             VARCHAR(32) NOT NULL,
    entity_type            VARCHAR(40),
    agent_topic            VARCHAR(100),
    agent_addr             VARCHAR(500) DEFAULT '' NOT NULL,
    agent_detail           TEXT,
    agent_prompt           TEXT,
    has_statistics         VARCHAR(1),
    agent_status           VARCHAR(20),
    input_time             VARCHAR(40) DEFAULT '' NOT NULL,
    update_time            VARCHAR(40) DEFAULT '' NOT NULL,
    agent_param_tpl        TEXT,
    large_model_code       VARCHAR(100),
    PRIMARY KEY (id)
);
-- ↑ 下面这条表级注释为【本工程补写】（源 DDL 未提供），措辞按该表列注释口径归纳
COMMENT ON TABLE agent_config IS '智能体配置表';
COMMENT ON COLUMN agent_config.agent_name IS '智能体名称';
COMMENT ON COLUMN agent_config.agent_code IS '智能体编码';
COMMENT ON COLUMN agent_config.entity_type IS '主体类型';
COMMENT ON COLUMN agent_config.agent_topic IS '智能体主题分类';
COMMENT ON COLUMN agent_config.agent_addr IS '智能体服务地址';
COMMENT ON COLUMN agent_config.agent_detail IS '智能体功能描述';
COMMENT ON COLUMN agent_config.agent_prompt IS '智能体默认Prompt';
COMMENT ON COLUMN agent_config.has_statistics IS '智能体是否支持统计';
COMMENT ON COLUMN agent_config.agent_status IS '智能体类型';
COMMENT ON COLUMN agent_config.input_time IS '入库时间';
COMMENT ON COLUMN agent_config.update_time IS '更新时间';
COMMENT ON COLUMN agent_config.agent_param_tpl IS '服务请求参数模板';
COMMENT ON COLUMN agent_config.large_model_code IS '大模型编码';
CREATE INDEX agent_status ON agent_config (agent_status);
CREATE UNIQUE INDEX agent_name ON agent_config (agent_name);
CREATE UNIQUE INDEX agent_code ON agent_config (agent_code);

-- ---------------------------------------------------------------
-- [43/44] prompt_verify_scene_info —— 大模型校验场景（指标配置取「大模型评估」的提示词模板）
-- ---------------------------------------------------------------
CREATE TABLE prompt_verify_scene_info (
    id                     VARCHAR(64) NOT NULL,
    scene_code             VARCHAR(200),
    scene_name             VARCHAR(200),
    create_time            VARCHAR(20),
    update_time            VARCHAR(20),
    scene_group            VARCHAR(100) DEFAULT '',
    scene_desc             VARCHAR(1000) DEFAULT '',
    PRIMARY KEY (id)
);
COMMENT ON TABLE prompt_verify_scene_info IS '场景信息表';
COMMENT ON COLUMN prompt_verify_scene_info.id IS '主键ID';
COMMENT ON COLUMN prompt_verify_scene_info.scene_code IS '场景编码';
COMMENT ON COLUMN prompt_verify_scene_info.scene_name IS '场景名称';
COMMENT ON COLUMN prompt_verify_scene_info.create_time IS '创建时间';
COMMENT ON COLUMN prompt_verify_scene_info.update_time IS '更新时间';
COMMENT ON COLUMN prompt_verify_scene_info.scene_group IS '场景分组';
COMMENT ON COLUMN prompt_verify_scene_info.scene_desc IS '场景描述';
CREATE UNIQUE INDEX scene_name ON prompt_verify_scene_info (scene_name);
CREATE UNIQUE INDEX scene_code_idx ON prompt_verify_scene_info (scene_code);

-- ---------------------------------------------------------------
-- [44/44] prompt_verify_scene_relate_prompt_info —— 场景关联 prompt（与上一张连表查询）
-- ---------------------------------------------------------------
CREATE TABLE prompt_verify_scene_relate_prompt_info (
    id                     VARCHAR(64) NOT NULL,
    scene_id               VARCHAR(64),
    large_model_code       VARCHAR(100),
    prompt_name            VARCHAR(200),
    prompt_template        TEXT,
    status                 VARCHAR(2) DEFAULT 'Y' NOT NULL,
    create_time            VARCHAR(20),
    update_time            VARCHAR(20),
    expect_format          VARCHAR(255),
    prompt_parameters      TEXT,
    PRIMARY KEY (id)
);
COMMENT ON TABLE prompt_verify_scene_relate_prompt_info IS '场景关联prompt信息表';
COMMENT ON COLUMN prompt_verify_scene_relate_prompt_info.id IS '主键ID';
COMMENT ON COLUMN prompt_verify_scene_relate_prompt_info.scene_id IS '场景ID';
COMMENT ON COLUMN prompt_verify_scene_relate_prompt_info.large_model_code IS '默认大模型编码';
COMMENT ON COLUMN prompt_verify_scene_relate_prompt_info.prompt_name IS 'prompt名称';
COMMENT ON COLUMN prompt_verify_scene_relate_prompt_info.status IS '状态（Y 有效 N 无效）';
COMMENT ON COLUMN prompt_verify_scene_relate_prompt_info.create_time IS '创建时间';
COMMENT ON COLUMN prompt_verify_scene_relate_prompt_info.update_time IS '更新时间';
COMMENT ON COLUMN prompt_verify_scene_relate_prompt_info.expect_format IS '期望格式（json、text)';
COMMENT ON COLUMN prompt_verify_scene_relate_prompt_info.prompt_parameters IS 'prompt解析参数';
