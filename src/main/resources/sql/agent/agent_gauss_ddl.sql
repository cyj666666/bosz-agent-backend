-- =====================================================================
-- agent_gauss_ddl.sql 自包含版（v6，openGauss/高斯DB 直接执行）
--   1. SET search_path = bosz_test, public：保证全部 213 张表（含第一张 agent_config）都建到 bosz_test
--   2. 补建 50 个自增序列（openGauss 不支持 CREATE SEQUENCE IF NOT EXISTS，用纯 CREATE SEQUENCE；
--      全新库一次成功；若库中已有部分序列，对应行报 already exists 时跳过该行即可）
--   3. 全部 character varying/character 列显式 COLLATE "C"：openGauss lc_collate 为 C 时必需，否则报
--      Un-support feature: type varchar cannot be set to binary collation
-- 前置条件：schema bosz_test 必须已存在（不存在先执行 CREATE SCHEMA bosz_test）
-- =====================================================================

SET search_path = bosz_test, public;

-- ---------- 自增序列（50） ----------
CREATE SEQUENCE agent_config_id_seq;
CREATE SEQUENCE agent_index_config_id_seq;
CREATE SEQUENCE agent_rule_id_seq;
CREATE SEQUENCE agent_search_memory_id_seq;
CREATE SEQUENCE ai_component_config_id_seq;
CREATE SEQUENCE amar_claw_memory_backups__id_seq;
CREATE SEQUENCE app_space_config_space_id_seq;
CREATE SEQUENCE app_space_inspiration_config_id_seq;
CREATE SEQUENCE app_space_relate_account_id_seq;
CREATE SEQUENCE app_space_relate_agent_id_seq;
CREATE SEQUENCE app_space_relate_knowledge_id_seq;
CREATE SEQUENCE bank_internal_indicators_config_id_seq;
CREATE SEQUENCE bank_module_info__id_seq;
CREATE SEQUENCE chat_session_msg_feedback_id_seq;
CREATE SEQUENCE client_agent_index_config_id_seq;
CREATE SEQUENCE coze_cache_industry_mapping_id_seq;
CREATE SEQUENCE data_entname_indname_reference_records_id_seq;
CREATE SEQUENCE data_relate_account_id_seq;
CREATE SEQUENCE data_update_config_id_seq;
CREATE SEQUENCE ent_rel_shortname_info_id_seq;
CREATE SEQUENCE financial_transaction_records__id_seq;
CREATE SEQUENCE finatial_records_task_id_seq;
CREATE SEQUENCE finatial_upload_task_id_seq;
CREATE SEQUENCE index_agent_rela_id_seq;
CREATE SEQUENCE index_detail_code_library__id_seq;
CREATE SEQUENCE index_detail_config_id_seq;
CREATE SEQUENCE index_info_temp__id_seq;
CREATE SEQUENCE index_params_temp__id_seq;
CREATE SEQUENCE index_relate_info_id_seq;
CREATE SEQUENCE jeecg_monthly_growth_analysis_id_seq;
CREATE SEQUENCE jeecg_project_nature_income_id_seq;
CREATE SEQUENCE knowledge_black_params_config_id_seq;
CREATE SEQUENCE knowledge_black_params_config_version_id_seq;
CREATE SEQUENCE knowledge_query_result_for_batch_id_seq;
CREATE SEQUENCE knowledge_relate_index_id_seq;
CREATE SEQUENCE knowledge_relate_index_version_id_seq;
CREATE SEQUENCE large_model_config_id_seq;
CREATE SEQUENCE message_push_config_id_seq;
CREATE SEQUENCE message_relate_account_id_seq;
CREATE SEQUENCE post_glm_records_id_seq;
CREATE SEQUENCE qianxun_user_log_id_seq;
CREATE SEQUENCE rasa_chat_detail_info_id_seq;
CREATE SEQUENCE rela_index_config_id_seq;
CREATE SEQUENCE scene_inflect_info__id_seq;
CREATE SEQUENCE sence_relate_info__id_seq;
CREATE SEQUENCE sync_knowledge_info_id_seq;
CREATE SEQUENCE sys_announcement_send__id_seq;
CREATE SEQUENCE sys_page_view_log_id_seq;
CREATE SEQUENCE trace_query_result_id_seq;
CREATE SEQUENCE workflow_return_records_id_seq;

-- ================= 原脚本内容（213 张表 + 约束 + 注释 + 索引） =================
CREATE TABLE agent_config (
    id integer DEFAULT nextval('agent_config_id_seq'::regclass) NOT NULL,
    agent_name character varying(100) COLLATE "C" NOT NULL,
    agent_code character varying(32) COLLATE "C" NOT NULL,
    entity_type character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    agent_topic character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    agent_addr character varying(500) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    agent_detail text,
    agent_prompt text,
    has_statistics character varying(1) COLLATE "C" DEFAULT NULL::character varying,
    agent_status character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    input_time character varying(40) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    update_time character varying(40) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    agent_param_tpl text,
    large_model_code character varying(100) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
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
CREATE INDEX agent_status ON agent_config USING ubtree (agent_status) WITH (storage_type=USTORE) TABLESPACE pg_default;
ALTER TABLE agent_config ADD CONSTRAINT agent_name UNIQUE USING ubtree (agent_name) WITH (storage_type=USTORE);
ALTER TABLE agent_config ADD CONSTRAINT agent_code UNIQUE USING ubtree (agent_code) WITH (storage_type=USTORE);
ALTER TABLE agent_config ADD CONSTRAINT agent_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE agent_conversation_history (
    conversation_id character varying(50) COLLATE "C" NOT NULL,
    session_no character varying(50) COLLATE "C" NOT NULL,
    agent_id character varying(32) COLLATE "C" NOT NULL,
    question character varying(1024) COLLATE "C" NOT NULL,
    question_class character varying(128) COLLATE "C" DEFAULT NULL::character varying,
    target_node character varying(128) COLLATE "C" DEFAULT NULL::character varying,
    target_detail json,
    start_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    answer text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE agent_conversation_history IS '智能体会话历史记录表';
COMMENT ON COLUMN agent_conversation_history.conversation_id IS '会话编号';
COMMENT ON COLUMN agent_conversation_history.session_no IS '问题编号';
COMMENT ON COLUMN agent_conversation_history.agent_id IS '智能体ID';
COMMENT ON COLUMN agent_conversation_history.question IS '和智能体交互的问题';
COMMENT ON COLUMN agent_conversation_history.question_class IS '问题分类,枚举：new_question, re_run, re_generate, invliad_question';
COMMENT ON COLUMN agent_conversation_history.target_node IS '目标节点';
COMMENT ON COLUMN agent_conversation_history.target_detail IS '目标细节';
COMMENT ON COLUMN agent_conversation_history.start_time IS '开始时间';
COMMENT ON COLUMN agent_conversation_history.answer IS '智能体回答';
CREATE INDEX idx_start_time ON agent_conversation_history USING ubtree (start_time) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_session_no ON agent_conversation_history USING ubtree (session_no) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_agent_id ON agent_conversation_history USING ubtree (agent_id) WITH (storage_type=USTORE) TABLESPACE pg_default;
ALTER TABLE agent_conversation_history ADD CONSTRAINT agent_conversation_history_pkey PRIMARY KEY USING ubtree  (conversation_id, session_no) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE agent_index_config (
    id integer DEFAULT nextval('agent_index_config_id_seq'::regclass) NOT NULL,
    index_name character varying(100) COLLATE "C" NOT NULL,
    index_code character varying(32) COLLATE "C" NOT NULL,
    index_topic character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    use_flag character varying(1) COLLATE "C" NOT NULL,
    synonym_word text,
    key_word text,
    center_key_word text,
    entity_type character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    inner_priority character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    source_type character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    external_priority character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    rec_group character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    rec_question character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    has_index_rela character varying(1) COLLATE "C" DEFAULT NULL::character varying,
    remark text,
    input_time character varying(40) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    update_time character varying(40) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    index_desc text,
    sample_question text,
    object_type character varying(256) COLLATE "C" DEFAULT NULL::character varying,
    index_classification character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    index_prompt text,
    final_result_flag character varying(1) COLLATE "C" DEFAULT 'N'::character varying,
    final_result_content character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    rec_enterprise character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    none_test_flag character varying(100) COLLATE "C" DEFAULT '1'::character varying NOT NULL,
    source_card_channel character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    large_model_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    large_model_content character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    rela_knowledge_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    large_model_flag character varying(1) COLLATE "C" DEFAULT 'Y'::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN agent_index_config.index_name IS '指标名称';
COMMENT ON COLUMN agent_index_config.index_code IS '指标编码';
COMMENT ON COLUMN agent_index_config.index_topic IS '指标主题分类';
COMMENT ON COLUMN agent_index_config.use_flag IS '是否有效 Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN agent_index_config.synonym_word IS '同义词';
COMMENT ON COLUMN agent_index_config.key_word IS '关键字';
COMMENT ON COLUMN agent_index_config.center_key_word IS '核心关键词';
COMMENT ON COLUMN agent_index_config.entity_type IS '主体类型';
COMMENT ON COLUMN agent_index_config.inner_priority IS '优先级';
COMMENT ON COLUMN agent_index_config.source_type IS '数据来源';
COMMENT ON COLUMN agent_index_config.external_priority IS '外部优先级';
COMMENT ON COLUMN agent_index_config.rec_group IS '推荐分组';
COMMENT ON COLUMN agent_index_config.rec_question IS '推荐问题';
COMMENT ON COLUMN agent_index_config.has_index_rela IS '是否有关联指标';
COMMENT ON COLUMN agent_index_config.remark IS '备注';
COMMENT ON COLUMN agent_index_config.input_time IS '入库时间';
COMMENT ON COLUMN agent_index_config.update_time IS '更新时间';
COMMENT ON COLUMN agent_index_config.index_desc IS '指标描述';
COMMENT ON COLUMN agent_index_config.sample_question IS '实例问题';
COMMENT ON COLUMN agent_index_config.object_type IS '企业类型';
COMMENT ON COLUMN agent_index_config.index_classification IS '组件分类';
COMMENT ON COLUMN agent_index_config.index_prompt IS '组件prompt';
COMMENT ON COLUMN agent_index_config.final_result_flag IS '是否无数据舆情兜底';
COMMENT ON COLUMN agent_index_config.final_result_content IS '兜底文案';
COMMENT ON COLUMN agent_index_config.rec_enterprise IS '推荐企业';
COMMENT ON COLUMN agent_index_config.none_test_flag IS '非测试标志位';
COMMENT ON COLUMN agent_index_config.source_card_channel IS '朔源卡片展示渠道(pc、app)';
COMMENT ON COLUMN agent_index_config.large_model_code IS '大模型编码';
COMMENT ON COLUMN agent_index_config.large_model_content IS '不同大模型对应的输出要求';
COMMENT ON COLUMN agent_index_config.rela_knowledge_id IS '组件关联知识库ID';
COMMENT ON COLUMN agent_index_config.large_model_flag IS '是否走大模型标志，默认Y（ N否，Y是 ）';
CREATE INDEX use_flag_2 ON agent_index_config USING ubtree (use_flag) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX source_type ON agent_index_config USING ubtree (source_type) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX index_code_3 ON agent_index_config USING ubtree (index_code) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX index_code_2 ON agent_index_config USING ubtree (index_code) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX use_flag ON agent_index_config USING ubtree (use_flag) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX index_name ON agent_index_config USING ubtree (index_name) WITH (storage_type=USTORE) TABLESPACE pg_default;
ALTER TABLE agent_index_config ADD CONSTRAINT agent_index_config_index_code_idx UNIQUE USING ubtree (index_code, source_type, none_test_flag) WITH (storage_type=USTORE);
ALTER TABLE agent_index_config ADD CONSTRAINT agent_index_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE agent_memory (
    mem_key character varying(128) COLLATE "C" NOT NULL,
    mem_content text,
    update_time character varying(40) COLLATE "C" NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE agent_memory IS '智能体记忆';
COMMENT ON COLUMN agent_memory.mem_key IS '记忆主键';
COMMENT ON COLUMN agent_memory.mem_content IS '记忆内容';
COMMENT ON COLUMN agent_memory.update_time IS '更新时间';
ALTER TABLE agent_memory ADD CONSTRAINT agent_memory_pkey PRIMARY KEY USING ubtree  (mem_key) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE agent_reply_message (
    agent_id character varying(128) COLLATE "C" NOT NULL,
    session_no character varying(50) COLLATE "C" NOT NULL,
    sort_no bigint NOT NULL,
    sse_message json,
    generated_time character varying(40) COLLATE "C" NOT NULL,
    session_msg_no character varying(128) COLLATE "C" DEFAULT ''::character varying NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE agent_reply_message IS '智能体问答记录表';
COMMENT ON COLUMN agent_reply_message.agent_id IS '智能体ID';
COMMENT ON COLUMN agent_reply_message.session_no IS '会话号';
COMMENT ON COLUMN agent_reply_message.sort_no IS '排序号';
COMMENT ON COLUMN agent_reply_message.sse_message IS '服务器发送事件消息';
COMMENT ON COLUMN agent_reply_message.generated_time IS '生成时间';
CREATE INDEX generated_time ON agent_reply_message USING ubtree (generated_time) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX sort_no ON agent_reply_message USING ubtree (sort_no) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX agent_id_session_no ON agent_reply_message USING ubtree (agent_id, session_no) WITH (storage_type=USTORE) TABLESPACE pg_default;
ALTER TABLE agent_reply_message ADD CONSTRAINT agent_reply_message_pkey PRIMARY KEY USING ubtree  (session_no, session_msg_no, sort_no) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE agent_rule (
    id integer DEFAULT nextval('agent_rule_id_seq'::regclass) NOT NULL,
    rule_name character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    rule_text character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    parsed_expression character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    rule_status character(1) COLLATE "C" DEFAULT NULL::bpchar,
    input_time character varying(30) COLLATE "C" DEFAULT NULL::character varying,
    input_user character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(30) COLLATE "C" DEFAULT NULL::character varying,
    update_user character varying(30) COLLATE "C" DEFAULT NULL::character varying,
    prompt_key character varying(300) COLLATE "C" DEFAULT NULL::character varying,
    topic1 character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    topic2 character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    threshold_config text,
    risk_remark text,
    disposal_advice text,
    additional_analysis text,
    rule_code character varying(200) COLLATE "C" NOT NULL,
    additional_analysis_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    rule_struct character varying(300) COLLATE "C" DEFAULT NULL::character varying,
    fact_analysis text,
    request_params character varying(2000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
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
ALTER TABLE agent_rule ADD CONSTRAINT uk_agent_rule_rule_code UNIQUE USING ubtree (rule_code) WITH (storage_type=USTORE);
ALTER TABLE agent_rule ADD CONSTRAINT agent_rule_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE agent_rule_prompt (
    key character varying(300) COLLATE "C" NOT NULL,
    prompt text NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE agent_rule_prompt IS 'Agent大模型提示词配置表';
COMMENT ON COLUMN agent_rule_prompt.key IS '提示词唯一标识key';
COMMENT ON COLUMN agent_rule_prompt.prompt IS 'prompt提示词内容';
ALTER TABLE agent_rule_prompt ADD CONSTRAINT agent_rule_prompt_pkey PRIMARY KEY USING ubtree  (key) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE agent_search_history (
    agent_id character varying(128) COLLATE "C" NOT NULL,
    session_no character varying(100) COLLATE "C" NOT NULL,
    user_id character varying(128) COLLATE "C" NOT NULL,
    question character varying(1024) COLLATE "C" DEFAULT NULL::character varying,
    start_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    final_answer text,
    end_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    edit_final_answer text,
    fav_final_answer smallint,
    status character varying(20) COLLATE "C" DEFAULT 'running'::character varying NOT NULL,
    session_msg_no character varying(128) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    async smallint DEFAULT 0::smallint
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE agent_search_history IS '智能体问答记录表';
COMMENT ON COLUMN agent_search_history.agent_id IS '智能体ID';
COMMENT ON COLUMN agent_search_history.user_id IS '用户ID';
COMMENT ON COLUMN agent_search_history.question IS '问题';
COMMENT ON COLUMN agent_search_history.start_time IS '开始时间';
COMMENT ON COLUMN agent_search_history.final_answer IS '最终答案';
COMMENT ON COLUMN agent_search_history.end_time IS '结束时间';
COMMENT ON COLUMN agent_search_history.edit_final_answer IS '最终答案编辑';
COMMENT ON COLUMN agent_search_history.fav_final_answer IS '喜欢这个答案:0或1';
COMMENT ON COLUMN agent_search_history.status IS '当前智能体的运行状态';
COMMENT ON COLUMN agent_search_history.async IS '是否异步发起的智能体任务,1:是,0否';
CREATE INDEX agent_id_user_id ON agent_search_history USING ubtree (agent_id, user_id) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_user_id ON agent_search_history USING ubtree (user_id) WITH (storage_type=USTORE) TABLESPACE pg_default;
ALTER TABLE agent_search_history ADD CONSTRAINT agent_search_history_pkey PRIMARY KEY USING ubtree  (session_no, session_msg_no) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE agent_search_memory (
    id bigint DEFAULT nextval('agent_search_memory_id_seq'::regclass) NOT NULL,
    agent_id character varying(128) COLLATE "C" NOT NULL,
    session_no character varying(50) COLLATE "C" NOT NULL,
    mem_type character varying(128) COLLATE "C" NOT NULL,
    mem_content text,
    generated_time character varying(40) COLLATE "C" NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE agent_search_memory IS '智能体问答记录表';
COMMENT ON COLUMN agent_search_memory.id IS 'ID';
COMMENT ON COLUMN agent_search_memory.agent_id IS '智能体ID';
COMMENT ON COLUMN agent_search_memory.session_no IS '会话号';
COMMENT ON COLUMN agent_search_memory.mem_type IS '记忆类型';
COMMENT ON COLUMN agent_search_memory.mem_content IS '记忆内容';
COMMENT ON COLUMN agent_search_memory.generated_time IS '生成时间';
CREATE INDEX idx_mem_type ON agent_search_memory USING ubtree (mem_type) WITH (storage_type=USTORE) TABLESPACE pg_default;
ALTER TABLE agent_search_memory ADD CONSTRAINT agent_search_memory_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE agent_tool_call_message (
    session_no character varying(100) COLLATE "C" NOT NULL,
    tool_name character varying(128) COLLATE "C" NOT NULL,
    call_id character varying(200) COLLATE "C" NOT NULL,
    agent_id character varying(32) COLLATE "C" NOT NULL,
    parallel_key character varying(256) COLLATE "C" NOT NULL,
    tool_args text,
    agent_name character varying(128) COLLATE "C" NOT NULL,
    start_time character varying(40) COLLATE "C" NOT NULL,
    call_time character varying(40) COLLATE "C" NOT NULL,
    finish_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    end_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    interrupt_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    tool_result text,
    interrupt_result text,
    status character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    state_store_path character varying(512) COLLATE "C" DEFAULT ''::character varying,
    session_msg_no character varying(128) COLLATE "C" DEFAULT ''::character varying NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE agent_tool_call_message IS '智能体工具调用记录表';
COMMENT ON COLUMN agent_tool_call_message.tool_name IS '工具名称';
COMMENT ON COLUMN agent_tool_call_message.call_id IS '调用ID';
COMMENT ON COLUMN agent_tool_call_message.agent_id IS '代理ID';
COMMENT ON COLUMN agent_tool_call_message.agent_name IS '智能体名称';
COMMENT ON COLUMN agent_tool_call_message.start_time IS '开始时间';
COMMENT ON COLUMN agent_tool_call_message.call_time IS '调用时间';
COMMENT ON COLUMN agent_tool_call_message.finish_time IS '完成时间';
COMMENT ON COLUMN agent_tool_call_message.end_time IS '结束时间';
COMMENT ON COLUMN agent_tool_call_message.interrupt_time IS '中断时间';
COMMENT ON COLUMN agent_tool_call_message.interrupt_result IS '中断结果';
COMMENT ON COLUMN agent_tool_call_message.status IS '工具调用结果状态';
CREATE INDEX start_time ON agent_tool_call_message USING ubtree (start_time) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX session_no ON agent_tool_call_message USING ubtree (session_no) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_call_id ON agent_tool_call_message USING ubtree (call_id) WITH (storage_type=USTORE) TABLESPACE pg_default;
ALTER TABLE agent_tool_call_message ADD CONSTRAINT agent_tool_call_message_pkey PRIMARY KEY USING ubtree  (session_no, tool_name, call_id, parallel_key) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ai_agent_info (
    ai_agent_id character varying(64) COLLATE "C" NOT NULL,
    ai_agent_name character varying(255) COLLATE "C" NOT NULL,
    input_time timestamp without time zone DEFAULT pg_systimestamp(),
    update_time timestamp without time zone DEFAULT pg_systimestamp(),
    data_metric_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(10) COLLATE "C" NOT NULL,
    agent_topic character varying(80) COLLATE "C" DEFAULT ''::character varying NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE ai_agent_info IS '主题智能体信息表';
COMMENT ON COLUMN ai_agent_info.ai_agent_id IS '主题智能体ID';
COMMENT ON COLUMN ai_agent_info.ai_agent_name IS '主题智能体名称';
COMMENT ON COLUMN ai_agent_info.input_time IS '创建时间';
COMMENT ON COLUMN ai_agent_info.update_time IS '更新时间';
COMMENT ON COLUMN ai_agent_info.data_metric_id IS '主题智能体关联的工作流指标ID';
COMMENT ON COLUMN ai_agent_info.status IS '标志位';
ALTER TABLE ai_agent_info ADD CONSTRAINT ai_agent_info_pkey PRIMARY KEY USING ubtree  (ai_agent_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ai_component_config (
    id integer DEFAULT nextval('ai_component_config_id_seq'::regclass) NOT NULL,
    catalog_code character varying(100) COLLATE "C" NOT NULL,
    catalog_name character varying(200) COLLATE "C" NOT NULL,
    catlaog_classification character varying(40) COLLATE "C" NOT NULL,
    catalog_status character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    input_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    catalog_desc text,
    icon character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    order_no integer,
    catalog_prompt character varying(1000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN ai_component_config.id IS 'id';
COMMENT ON COLUMN ai_component_config.catalog_code IS '组件code';
COMMENT ON COLUMN ai_component_config.catalog_name IS '组件名称';
COMMENT ON COLUMN ai_component_config.catlaog_classification IS '组件类型';
COMMENT ON COLUMN ai_component_config.catalog_status IS '失效标志位,Y|N';
COMMENT ON COLUMN ai_component_config.input_time IS '插入时间';
COMMENT ON COLUMN ai_component_config.update_time IS '更新时间';
COMMENT ON COLUMN ai_component_config.icon IS '组件图标';
COMMENT ON COLUMN ai_component_config.order_no IS '排序';
COMMENT ON COLUMN ai_component_config.catalog_prompt IS '组件提示语';
ALTER TABLE ai_component_config ADD CONSTRAINT catalog_code UNIQUE USING ubtree (catalog_code) WITH (storage_type=USTORE);
ALTER TABLE ai_component_config ADD CONSTRAINT ai_component_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ai_menu_config (
    id character varying(32) COLLATE "C" NOT NULL,
    menu_code character varying(200) COLLATE "C" NOT NULL,
    menu_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    url character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    input_time timestamp without time zone DEFAULT pg_systimestamp(),
    update_time timestamp without time zone DEFAULT pg_systimestamp(),
    order_num integer DEFAULT 0,
    icon character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    component_url character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE ai_menu_config IS '千寻菜单配置表';
COMMENT ON COLUMN ai_menu_config.menu_code IS '菜单编码';
COMMENT ON COLUMN ai_menu_config.menu_name IS '菜单名称';
COMMENT ON COLUMN ai_menu_config.status IS '状态Y-有效 N-无效';
COMMENT ON COLUMN ai_menu_config.url IS '菜单路径';
COMMENT ON COLUMN ai_menu_config.input_time IS '创建时间';
COMMENT ON COLUMN ai_menu_config.update_time IS '更新时间';
COMMENT ON COLUMN ai_menu_config.order_num IS '排序';
COMMENT ON COLUMN ai_menu_config.icon IS '菜单图标';
COMMENT ON COLUMN ai_menu_config.component_url IS '菜单前端组件地址';
CREATE INDEX input_time_idx ON ai_menu_config USING ubtree (input_time) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX menu_code_idx ON ai_menu_config USING ubtree (menu_code) WITH (storage_type=USTORE) TABLESPACE pg_default;
ALTER TABLE ai_menu_config ADD CONSTRAINT ai_menu_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE amar_claw_memory_backups (
    _id bigint DEFAULT nextval('amar_claw_memory_backups__id_seq'::regclass) NOT NULL,
    id character varying(32) COLLATE "C" NOT NULL,
    user_id character varying(32) COLLATE "C" NOT NULL,
    container_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    backup_type character varying(20) COLLATE "C" DEFAULT 'auto'::character varying,
    backup_path character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    backup_size bigint,
    created_at timestamp without time zone DEFAULT pg_systimestamp()
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE amar_claw_memory_backups IS '记忆备份表';
COMMENT ON COLUMN amar_claw_memory_backups._id IS '主键ID';
COMMENT ON COLUMN amar_claw_memory_backups.id IS '备份ID';
COMMENT ON COLUMN amar_claw_memory_backups.user_id IS '用户ID';
COMMENT ON COLUMN amar_claw_memory_backups.container_id IS '容器ID';
COMMENT ON COLUMN amar_claw_memory_backups.backup_type IS '备份类型: auto/manual';
COMMENT ON COLUMN amar_claw_memory_backups.backup_path IS '备份路径';
COMMENT ON COLUMN amar_claw_memory_backups.backup_size IS '备份大小';
COMMENT ON COLUMN amar_claw_memory_backups.created_at IS '创建时间';
ALTER TABLE amar_claw_memory_backups ADD CONSTRAINT amar_claw_memory_backups_pkey PRIMARY KEY USING ubtree  (_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE api_db_cache (
    id character varying(32) COLLATE "C" NOT NULL,
    cache_key character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    cache_value text,
    input_time character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE api_db_cache IS '接口缓存表';
ALTER TABLE api_db_cache ADD CONSTRAINT api_db_cache_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE app_api_financial_analysis_dd_cashflow (
    userid character varying(50) COLLATE "C" NOT NULL,
    reportdate character varying(50) COLLATE "C" NOT NULL,
    combinetype character varying(50) COLLATE "C" NOT NULL,
    companyname character varying(200) COLLATE "C" NOT NULL,
    sessionno character varying(50) COLLATE "C" NOT NULL,
    excelid character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    excelurl character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    uptime timestamp without time zone,
    reportno character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    acceptinvrec numeric(38,18) DEFAULT NULL::numeric,
    addpledgetdeposit numeric(38,18) DEFAULT NULL::numeric,
    buyfilassetpay numeric(38,18) DEFAULT NULL::numeric,
    buygoodsservicepay numeric(38,18) DEFAULT NULL::numeric,
    buysubsidiarypay numeric(38,18) DEFAULT NULL::numeric,
    cashequibeginning numeric(38,18) DEFAULT NULL::numeric,
    cashequiending numeric(38,18) DEFAULT NULL::numeric,
    cashequiendingbalance numeric(38,18) DEFAULT NULL::numeric,
    cashequiendingother numeric(38,18) DEFAULT NULL::numeric,
    dispfilassetrec numeric(38,18) DEFAULT NULL::numeric,
    disposalinvrec numeric(38,18) DEFAULT NULL::numeric,
    dispsubsidiaryrec numeric(38,18) DEFAULT NULL::numeric,
    divipay numeric(38,18) DEFAULT NULL::numeric,
    diviprofitorintpay numeric(38,18) DEFAULT NULL::numeric,
    effectexchangerate numeric(38,18) DEFAULT NULL::numeric,
    employeepay numeric(38,18) DEFAULT NULL::numeric,
    finaflowbalance numeric(38,18) DEFAULT NULL::numeric,
    finaflowinbalance numeric(38,18) DEFAULT NULL::numeric,
    finaflowinother numeric(38,18) DEFAULT NULL::numeric,
    finaflowother numeric(38,18) DEFAULT NULL::numeric,
    finaflowoutbalance numeric(38,18) DEFAULT NULL::numeric,
    finaflowoutother numeric(38,18) DEFAULT NULL::numeric,
    getsubsidiarypay numeric(38,18) DEFAULT NULL::numeric,
    indemnitypay numeric(38,18) DEFAULT NULL::numeric,
    intandcommpay numeric(38,18) DEFAULT NULL::numeric,
    intandcommrec numeric(38,18) DEFAULT NULL::numeric,
    invflowbalance numeric(38,18) DEFAULT NULL::numeric,
    invflowinbalance numeric(38,18) DEFAULT NULL::numeric,
    invflowinother numeric(38,18) DEFAULT NULL::numeric,
    invflowother numeric(38,18) DEFAULT NULL::numeric,
    invflowoutbalance numeric(38,18) DEFAULT NULL::numeric,
    invflowoutother numeric(38,18) DEFAULT NULL::numeric,
    invincomerec numeric(38,18) DEFAULT NULL::numeric,
    invpay numeric(38,18) DEFAULT NULL::numeric,
    issuebondrec numeric(38,18) DEFAULT NULL::numeric,
    loanrec numeric(38,18) DEFAULT NULL::numeric,
    ndloanadvances numeric(38,18) DEFAULT NULL::numeric,
    netfinacashflow numeric(38,18) DEFAULT NULL::numeric,
    netinvcashflow numeric(38,18) DEFAULT NULL::numeric,
    netoperatecashflow numeric(38,18) DEFAULT NULL::numeric,
    netrirec numeric(38,18) DEFAULT NULL::numeric,
    niborrowfromcbank numeric(38,18) DEFAULT NULL::numeric,
    niborrowfromfi numeric(38,18) DEFAULT NULL::numeric,
    niborrowfund numeric(38,18) DEFAULT NULL::numeric,
    nibuybackfund numeric(38,18) DEFAULT NULL::numeric,
    nicashequi numeric(38,18) DEFAULT NULL::numeric,
    nicashequibalance numeric(38,18) DEFAULT NULL::numeric,
    nicashequiother numeric(38,18) DEFAULT NULL::numeric,
    nideposit numeric(38,18) DEFAULT NULL::numeric,
    nidepositincbankfi numeric(38,18) DEFAULT NULL::numeric,
    nidisptradefasset numeric(38,18) DEFAULT NULL::numeric,
    niinsureddepositinv numeric(38,18) DEFAULT NULL::numeric,
    niloanadvances numeric(38,18) DEFAULT NULL::numeric,
    nipledgeloan numeric(38,18) DEFAULT NULL::numeric,
    operateflowbalance numeric(38,18) DEFAULT NULL::numeric,
    operateflowinbalance numeric(38,18) DEFAULT NULL::numeric,
    operateflowinother numeric(38,18) DEFAULT NULL::numeric,
    operateflowother numeric(38,18) DEFAULT NULL::numeric,
    operateflowoutbalance numeric(38,18) DEFAULT NULL::numeric,
    operateflowoutother numeric(38,18) DEFAULT NULL::numeric,
    otherfinapay numeric(38,18) DEFAULT NULL::numeric,
    otherfinarec numeric(38,18) DEFAULT NULL::numeric,
    otherinvpay numeric(38,18) DEFAULT NULL::numeric,
    otherinvrec numeric(38,18) DEFAULT NULL::numeric,
    otheroperatepay numeric(38,18) DEFAULT NULL::numeric,
    otheroperaterec numeric(38,18) DEFAULT NULL::numeric,
    premiumrec numeric(38,18) DEFAULT NULL::numeric,
    reducepledgetdeposit numeric(38,18) DEFAULT NULL::numeric,
    repaydebtpay numeric(38,18) DEFAULT NULL::numeric,
    salegoodsservicerec numeric(38,18) DEFAULT NULL::numeric,
    subsidiaryaccept numeric(38,18) DEFAULT NULL::numeric,
    subsidiarypay numeric(38,18) DEFAULT NULL::numeric,
    subsidiaryreductcapital numeric(38,18) DEFAULT NULL::numeric,
    sumfinaflowin numeric(38,18) DEFAULT NULL::numeric,
    sumfinaflowout numeric(38,18) DEFAULT NULL::numeric,
    suminvflowin numeric(38,18) DEFAULT NULL::numeric,
    suminvflowout numeric(38,18) DEFAULT NULL::numeric,
    sumoperateflowin numeric(38,18) DEFAULT NULL::numeric,
    sumoperateflowout numeric(38,18) DEFAULT NULL::numeric,
    taxpay numeric(38,18) DEFAULT NULL::numeric,
    taxreturnrec numeric(38,18) DEFAULT NULL::numeric
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_api_financial_analysis_dd_cashflow IS '现金流量表';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.userid IS '用户id';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.reportdate IS '报表日期';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.combinetype IS '报表合并类型';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.companyname IS '公司名称';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.sessionno IS '对话框编码';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.excelid IS '上传表id';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.excelurl IS '上传表url';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.uptime IS '上传时间';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.reportno IS '报告编号';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.acceptinvrec IS '吸收投资收到的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.addpledgetdeposit IS '增加质押和定期存款所支付的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.buyfilassetpay IS '购建固定资产、无形资产和其他长期资产支付的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.buygoodsservicepay IS '购买商品、接受劳务支付的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.buysubsidiarypay IS '购买子公司少数股权而支付的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.cashequibeginning IS '期初现金及现金等价物余额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.cashequiending IS '期末现金及现金等价物余额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.cashequiendingbalance IS '期末现金及现金等价物余额平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.cashequiendingother IS '期末现金及现金等价物余额其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.dispfilassetrec IS '处置固定资产、无形资产和其他长期资产收回的现金净额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.disposalinvrec IS '收回投资收到的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.dispsubsidiaryrec IS '处置子公司及其他营业单位收到的现金净额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.divipay IS '支付保单红利的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.diviprofitorintpay IS '分配股利、利润或偿付利息支付的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.effectexchangerate IS '汇率变动对现金及现金等价物的影响';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.employeepay IS '支付给职工以及为职工支付的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.finaflowbalance IS '筹资活动产生的现金流量净额平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.finaflowinbalance IS '筹资活动现金流入平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.finaflowinother IS '筹资活动现金流入其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.finaflowother IS '筹资活动产生的现金流量净额其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.finaflowoutbalance IS '筹资活动现金流出平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.finaflowoutother IS '筹资活动现金流出其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.getsubsidiarypay IS '取得子公司及其他营业单位支付的现金净额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.indemnitypay IS '支付原保险合同赔付款项的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.intandcommpay IS '支付利息、手续费及佣金的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.intandcommrec IS '收取利息、手续费及佣金的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.invflowbalance IS '投资活动产生的现金流量净额平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.invflowinbalance IS '投资活动现金流入平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.invflowinother IS '投资活动现金流入其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.invflowother IS '投资活动产生的现金流量净额其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.invflowoutbalance IS '投资活动现金流出平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.invflowoutother IS '投资活动现金流出其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.invincomerec IS '取得投资收益收到的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.invpay IS '投资支付的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.issuebondrec IS '发行债券收到的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.loanrec IS '取得借款收到的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.ndloanadvances IS '发放贷款及垫款的净减少额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.netfinacashflow IS '筹资活动产生的现金流量净额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.netinvcashflow IS '投资活动产生的现金流量净额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.netoperatecashflow IS '经营活动产生的现金流量净额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.netrirec IS '收到再保险业务现金净额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.niborrowfromcbank IS '向中央银行借款净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.niborrowfromfi IS '向其他金融机构拆入资金净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.niborrowfund IS '拆入资金净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.nibuybackfund IS '回购业务资金净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.nicashequi IS '现金及现金等价物净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.nicashequibalance IS '现金及现金等价物净增加额平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.nicashequiother IS '现金及现金等价物净增加额其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.nideposit IS '客户存款和同业存放款项净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.nidepositincbankfi IS '存放中央银行和同业款项净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.nidisptradefasset IS '处置交易性金融资产净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.niinsureddepositinv IS '保户储金及投资款净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.niloanadvances IS '客户贷款及垫款净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.nipledgeloan IS '质押贷款净增加额';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.operateflowbalance IS '经营活动产生的现金流量净额平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.operateflowinbalance IS '经营活动现金流入平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.operateflowinother IS '经营活动现金流入其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.operateflowother IS '经营活动产生的现金流量净额其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.operateflowoutbalance IS '经营活动现金流出平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.operateflowoutother IS '经营活动现金流出其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.otherfinapay IS '支付其他与筹资活动有关的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.otherfinarec IS '收到其他与筹资活动有关的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.otherinvpay IS '支付其他与投资活动有关的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.otherinvrec IS '收到其他与投资活动有关的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.otheroperatepay IS '支付其他与经营活动有关的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.otheroperaterec IS '收到其他与经营活动有关的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.premiumrec IS '收到原保险合同保费取得的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.reducepledgetdeposit IS '减少质押和定期存款所收到的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.repaydebtpay IS '偿还债务支付的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.salegoodsservicerec IS '销售商品、提供劳务收到的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.subsidiaryaccept IS '子公司吸收少数股东投资收到的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.subsidiarypay IS '子公司支付给少数股东的股利、利润';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.subsidiaryreductcapital IS '子公司减资支付给少数股东的现金';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.sumfinaflowin IS '筹资活动现金流入小计';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.sumfinaflowout IS '筹资活动现金流出小计';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.suminvflowin IS '投资活动现金流入小计';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.suminvflowout IS '投资活动现金流出小计';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.sumoperateflowin IS '经营活动现金流入小计';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.sumoperateflowout IS '经营活动现金流出小计';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.taxpay IS '支付的各项税费';
COMMENT ON COLUMN app_api_financial_analysis_dd_cashflow.taxreturnrec IS '收到的税费返还';
ALTER TABLE app_api_financial_analysis_dd_cashflow ADD CONSTRAINT app_api_financial_analysis_dd_cashflow_pkey PRIMARY KEY USING ubtree  (userid, reportdate, combinetype, companyname) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE app_api_financial_analysis_dd_debt (
    userid character varying(50) COLLATE "C" NOT NULL,
    reportdate character varying(50) COLLATE "C" NOT NULL,
    combinetype character varying(50) COLLATE "C" NOT NULL,
    companyname character varying(200) COLLATE "C" NOT NULL,
    sessionno character varying(50) COLLATE "C" NOT NULL,
    excelid character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    excelurl character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    uptime timestamp without time zone,
    reportno character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    monetaryfund numeric(38,18) DEFAULT NULL::numeric,
    settlementprovision numeric(38,18) DEFAULT NULL::numeric,
    lendfund numeric(38,18) DEFAULT NULL::numeric,
    tradefasset numeric(38,18) DEFAULT NULL::numeric,
    billrec numeric(38,18) DEFAULT NULL::numeric,
    accountrec numeric(38,18) DEFAULT NULL::numeric,
    advancepay numeric(38,18) DEFAULT NULL::numeric,
    premiumrec numeric(38,18) DEFAULT NULL::numeric,
    rirec numeric(38,18) DEFAULT NULL::numeric,
    ricontactreserverec numeric(38,18) DEFAULT NULL::numeric,
    interestrec numeric(38,18) DEFAULT NULL::numeric,
    dividendrec numeric(38,18) DEFAULT NULL::numeric,
    otherrec numeric(38,18) DEFAULT NULL::numeric,
    exportrebaterec numeric(38,18) DEFAULT NULL::numeric,
    subsidyrec numeric(38,18) DEFAULT NULL::numeric,
    internalrec numeric(38,18) DEFAULT NULL::numeric,
    buysellbackfasset numeric(38,18) DEFAULT NULL::numeric,
    inventory numeric(38,18) DEFAULT NULL::numeric,
    nonlassetoneyear numeric(38,18) DEFAULT NULL::numeric,
    otherlasset numeric(38,18) DEFAULT NULL::numeric,
    lassetother numeric(38,18) DEFAULT NULL::numeric,
    lassetbalance numeric(38,18) DEFAULT NULL::numeric,
    sumlasset numeric(38,18) DEFAULT NULL::numeric,
    loanadvances numeric(38,18) DEFAULT NULL::numeric,
    saleablefasset numeric(38,18) DEFAULT NULL::numeric,
    heldmaturityinv numeric(38,18) DEFAULT NULL::numeric,
    ltrec numeric(38,18) DEFAULT NULL::numeric,
    ltequityinv numeric(38,18) DEFAULT NULL::numeric,
    estateinvest numeric(38,18) DEFAULT NULL::numeric,
    fixedasset numeric(38,18) DEFAULT NULL::numeric,
    constructionprogress numeric(38,18) DEFAULT NULL::numeric,
    constructionmaterial numeric(38,18) DEFAULT NULL::numeric,
    liquidatefixedasset numeric(38,18) DEFAULT NULL::numeric,
    productbiologyasset numeric(38,18) DEFAULT NULL::numeric,
    oilgasasset numeric(38,18) DEFAULT NULL::numeric,
    intangibleasset numeric(38,18) DEFAULT NULL::numeric,
    developexp numeric(38,18) DEFAULT NULL::numeric,
    goodwill numeric(38,18) DEFAULT NULL::numeric,
    ltdeferasset numeric(38,18) DEFAULT NULL::numeric,
    deferincometaxasset numeric(38,18) DEFAULT NULL::numeric,
    othernonlasset numeric(38,18) DEFAULT NULL::numeric,
    nonlassetother numeric(38,18) DEFAULT NULL::numeric,
    nonlassetbalance numeric(38,18) DEFAULT NULL::numeric,
    sumnonlasset numeric(38,18) DEFAULT NULL::numeric,
    assetother numeric(38,18) DEFAULT NULL::numeric,
    assetbalance numeric(38,18) DEFAULT NULL::numeric,
    sumasset numeric(38,18) DEFAULT NULL::numeric,
    stborrow numeric(38,18) DEFAULT NULL::numeric,
    borrowfromcbank numeric(38,18) DEFAULT NULL::numeric,
    deposit numeric(38,18) DEFAULT NULL::numeric,
    borrowfund numeric(38,18) DEFAULT NULL::numeric,
    tradefliab numeric(38,18) DEFAULT NULL::numeric,
    billpay numeric(38,18) DEFAULT NULL::numeric,
    accountpay numeric(38,18) DEFAULT NULL::numeric,
    advancereceive numeric(38,18) DEFAULT NULL::numeric,
    sellbuybackfasset numeric(38,18) DEFAULT NULL::numeric,
    commpay numeric(38,18) DEFAULT NULL::numeric,
    salarypay numeric(38,18) DEFAULT NULL::numeric,
    taxpay numeric(38,18) DEFAULT NULL::numeric,
    interestpay numeric(38,18) DEFAULT NULL::numeric,
    dividendpay numeric(38,18) DEFAULT NULL::numeric,
    ripay numeric(38,18) DEFAULT NULL::numeric,
    internalpay numeric(38,18) DEFAULT NULL::numeric,
    otherpay numeric(38,18) DEFAULT NULL::numeric,
    anticipatelliab numeric(38,18) DEFAULT NULL::numeric,
    contactreserve numeric(38,18) DEFAULT NULL::numeric,
    agenttradesecurity numeric(38,18) DEFAULT NULL::numeric,
    agentuwsecurity numeric(38,18) DEFAULT NULL::numeric,
    deferincomeoneyear numeric(38,18) DEFAULT NULL::numeric,
    stbondrec numeric(38,18) DEFAULT NULL::numeric,
    nonlliaboneyear numeric(38,18) DEFAULT NULL::numeric,
    otherlliab numeric(38,18) DEFAULT NULL::numeric,
    lliabother numeric(38,18) DEFAULT NULL::numeric,
    lliabbalance numeric(38,18) DEFAULT NULL::numeric,
    sumlliab numeric(38,18) DEFAULT NULL::numeric,
    ltborrow numeric(38,18) DEFAULT NULL::numeric,
    bondpay numeric(38,18) DEFAULT NULL::numeric,
    sustainbond numeric(38,18) DEFAULT NULL::numeric,
    preferstocbond numeric(38,18) DEFAULT NULL::numeric,
    ltaccountpay numeric(38,18) DEFAULT NULL::numeric,
    specialpay numeric(38,18) DEFAULT NULL::numeric,
    anticipateliab numeric(38,18) DEFAULT NULL::numeric,
    deferincome numeric(38,18) DEFAULT NULL::numeric,
    deferincometaxliab numeric(38,18) DEFAULT NULL::numeric,
    othernonlliab numeric(38,18) DEFAULT NULL::numeric,
    nonlliabother numeric(38,18) DEFAULT NULL::numeric,
    nonlliabbalance numeric(38,18) DEFAULT NULL::numeric,
    sumnonlliab numeric(38,18) DEFAULT NULL::numeric,
    liabother numeric(38,18) DEFAULT NULL::numeric,
    liabbalance numeric(38,18) DEFAULT NULL::numeric,
    sumliab numeric(38,18) DEFAULT NULL::numeric,
    sharecapital numeric(38,18) DEFAULT NULL::numeric,
    capitalreserve numeric(38,18) DEFAULT NULL::numeric,
    inventoryshare numeric(38,18) DEFAULT NULL::numeric,
    specialreserve numeric(38,18) DEFAULT NULL::numeric,
    surplusreserve numeric(38,18) DEFAULT NULL::numeric,
    generalriskprepare numeric(38,18) DEFAULT NULL::numeric,
    unconfirminvloss numeric(38,18) DEFAULT NULL::numeric,
    retainedearning numeric(38,18) DEFAULT NULL::numeric,
    plancashdivi numeric(38,18) DEFAULT NULL::numeric,
    diffconversionfc numeric(38,18) DEFAULT NULL::numeric,
    parentequityother numeric(38,18) DEFAULT NULL::numeric,
    parentequitybalance numeric(38,18) DEFAULT NULL::numeric,
    sumparentequity numeric(38,18) DEFAULT NULL::numeric,
    minorityequity numeric(38,18) DEFAULT NULL::numeric,
    shequityother numeric(38,18) DEFAULT NULL::numeric,
    shequitybalance numeric(38,18) DEFAULT NULL::numeric,
    sumshequity numeric(48,18) DEFAULT NULL::numeric,
    liabshequityother numeric(38,18) DEFAULT NULL::numeric,
    liabshequitybalance numeric(38,18) DEFAULT NULL::numeric,
    sumliabshequity numeric(38,18) DEFAULT NULL::numeric,
    ltsalarypay numeric(38,18) DEFAULT NULL::numeric,
    fvaluefasset numeric(38,18) DEFAULT NULL::numeric,
    definefvaluefasset numeric(38,18) DEFAULT NULL::numeric,
    fvaluefliab numeric(38,18) DEFAULT NULL::numeric,
    definefvaluefliab numeric(38,18) DEFAULT NULL::numeric,
    otherequity numeric(38,18) DEFAULT NULL::numeric,
    otherequityother numeric(38,18) DEFAULT NULL::numeric,
    othercincome numeric(38,18) DEFAULT NULL::numeric,
    clheldsaleass numeric(38,18) DEFAULT NULL::numeric,
    clheldsaleliab numeric(38,18) DEFAULT NULL::numeric,
    othernonfasset numeric(38,18) DEFAULT NULL::numeric,
    otherequityinv numeric(38,18) DEFAULT NULL::numeric,
    derivefliab numeric(38,18) DEFAULT NULL::numeric,
    contractliab numeric(38,18) DEFAULT NULL::numeric,
    amorcostfasset numeric(38,18) DEFAULT NULL::numeric,
    heldsaleass numeric(38,18) DEFAULT NULL::numeric,
    fvaluecompfasset numeric(38,18) DEFAULT NULL::numeric,
    amorcostfliabfld numeric(38,18) DEFAULT NULL::numeric,
    drawingexp numeric(38,18) DEFAULT NULL::numeric,
    contractasset numeric(38,18) DEFAULT NULL::numeric,
    accountbillrec numeric(38,18) DEFAULT NULL::numeric,
    heldsaleliab numeric(38,18) DEFAULT NULL::numeric,
    derivefasset numeric(38,18) DEFAULT NULL::numeric,
    accountbillpay numeric(38,18) DEFAULT NULL::numeric,
    shortfinancing numeric(30,18) DEFAULT NULL::numeric,
    credinv numeric(38,18) DEFAULT NULL::numeric,
    fvaluecompfassetfld numeric(38,18) DEFAULT NULL::numeric,
    othcredinv numeric(38,18) DEFAULT NULL::numeric,
    marginoutfund numeric(30,4) DEFAULT NULL::numeric,
    amorcostfliab numeric(38,18) DEFAULT NULL::numeric,
    amorcostfassetfld numeric(38,18) DEFAULT NULL::numeric,
    totalotherrece numeric(38,18) DEFAULT NULL::numeric,
    financerece numeric(38,18) DEFAULT NULL::numeric,
    userightasset numeric(38,18) DEFAULT NULL::numeric,
    leaseliab numeric(38,18) DEFAULT NULL::numeric,
    tradefinassetnotfvtpl numeric(38,18) DEFAULT NULL::numeric,
    tradefinliabnotfvtpl numeric(38,18) DEFAULT NULL::numeric,
    totalotherpayable numeric(38,18) DEFAULT NULL::numeric,
    consumptivebiologicalasset numeric(30,4) DEFAULT NULL::numeric
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_api_financial_analysis_dd_debt IS '资产负债表';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.userid IS '用户id';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.reportdate IS '报表日期';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.combinetype IS '报表合并类型';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.companyname IS '公司名称';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sessionno IS '对话框编码';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.excelid IS '上传表id';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.excelurl IS '上传表url';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.uptime IS '上传时间';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.reportno IS '报告编号';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.monetaryfund IS '货币资金';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.settlementprovision IS '结算备付金';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.lendfund IS '拆出资金';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.tradefasset IS '其中:交易性金融资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.billrec IS '应收票据';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.accountrec IS '应收账款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.advancepay IS '预付款项';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.premiumrec IS '应收保费';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.rirec IS '应收分保账款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.ricontactreserverec IS '应收分保合同准备金';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.interestrec IS '应收利息';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.dividendrec IS '应收股利';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.otherrec IS '其他应收款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.exportrebaterec IS '应收出口退税';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.subsidyrec IS '应收补贴款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.internalrec IS '内部应收款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.buysellbackfasset IS '买入返售金融资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.inventory IS '存货';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.nonlassetoneyear IS '一年内到期的非流动资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.otherlasset IS '其他流动资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.lassetother IS '流动资产其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.lassetbalance IS '流动资产平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sumlasset IS '流动资产合计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.loanadvances IS '发放委托贷款及垫款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.saleablefasset IS '可供出售金融资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.heldmaturityinv IS '持有至到期投资';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.ltrec IS '长期应收款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.ltequityinv IS '长期股权投资';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.estateinvest IS '投资性房地产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.fixedasset IS '固定资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.constructionprogress IS '在建工程';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.constructionmaterial IS '工程物资';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.liquidatefixedasset IS '固定资产清理';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.productbiologyasset IS '生产性生物资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.oilgasasset IS '油气资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.intangibleasset IS '无形资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.developexp IS '开发支出';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.goodwill IS '商誉';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.ltdeferasset IS '长期待摊费用';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.deferincometaxasset IS '递延所得税资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.othernonlasset IS '其他非流动资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.nonlassetother IS '非流动资产其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.nonlassetbalance IS '非流动资产平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sumnonlasset IS '非流动资产合计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.assetother IS '资产其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.assetbalance IS '资产平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sumasset IS '资产总计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.stborrow IS '短期借款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.borrowfromcbank IS '向中央银行借款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.deposit IS '吸收存款及同业存放';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.borrowfund IS '拆入资金';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.tradefliab IS '其中:交易性金融负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.billpay IS '应付票据';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.accountpay IS '应付账款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.advancereceive IS '预收款项';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sellbuybackfasset IS '卖出回购金融资产款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.commpay IS '应付手续费及佣金';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.salarypay IS '应付职工薪酬';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.taxpay IS '应交税费';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.interestpay IS '应付利息';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.dividendpay IS '应付股利';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.ripay IS '应付分保账款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.internalpay IS '内部应付款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.otherpay IS '其他应付款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.anticipatelliab IS '预计流动负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.contactreserve IS '保险合同准备金';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.agenttradesecurity IS '代理买卖证券款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.agentuwsecurity IS '代理承销证券款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.deferincomeoneyear IS '一年内的递延收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.stbondrec IS '应付短期债券';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.nonlliaboneyear IS '一年内到期的非流动负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.otherlliab IS '其他流动负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.lliabother IS '流动负债其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.lliabbalance IS '流动负债平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sumlliab IS '流动负债合计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.ltborrow IS '长期借款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.bondpay IS '应付债券';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sustainbond IS '其中:永续债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.preferstocbond IS '其中:优先股';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.ltaccountpay IS '长期应付款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.specialpay IS '专项应付款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.anticipateliab IS '预计负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.deferincome IS '递延收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.deferincometaxliab IS '递延所得税负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.othernonlliab IS '其他非流动负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.nonlliabother IS '非流动负债其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.nonlliabbalance IS '非流动负债平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sumnonlliab IS '非流动负债合计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.liabother IS '负债其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.liabbalance IS '负债平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sumliab IS '负债合计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sharecapital IS '实收资本（或股本）';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.capitalreserve IS '资本公积';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.inventoryshare IS '库存股';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.specialreserve IS '专项储备';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.surplusreserve IS '盈余公积';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.generalriskprepare IS '一般风险准备';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.unconfirminvloss IS '未确定的投资损失';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.retainedearning IS '未分配利润';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.plancashdivi IS '拟分配现金股利';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.diffconversionfc IS '外币报表折算差额';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.parentequityother IS '归属于母公司股东权益其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.parentequitybalance IS '归属于母公司股东权益平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sumparentequity IS '归属于母公司股东权益合计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.minorityequity IS '少数股东权益';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.shequityother IS '股东权益其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.shequitybalance IS '股东权益平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sumshequity IS '股东权益合计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.liabshequityother IS '负债和股东权益其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.liabshequitybalance IS '负债和股东权益平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.sumliabshequity IS '负债和股东权益合计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.ltsalarypay IS '长期应付职工薪酬';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.fvaluefasset IS '以公允价值计量且其变动计入当期损益的金融资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.definefvaluefasset IS '指定为以公允价值计量且其变动计入当期损益的金融资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.fvaluefliab IS '以公允价值计量且其变动计入当期损益的金融负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.definefvaluefliab IS '指定以公允价值计量且其变动计入当期损益的金融负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.otherequity IS '其他权益工具';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.otherequityother IS '其中:其他其他权益工具';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.othercincome IS '其他综合收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.clheldsaleass IS '划分为持有待售的资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.clheldsaleliab IS '划分为持有待售的负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.othernonfasset IS '其他非流动金融资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.otherequityinv IS '其他权益工具投资';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.derivefliab IS '衍生金融负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.contractliab IS '合同负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.amorcostfasset IS '以摊余成本计量的金融资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.heldsaleass IS '持有待售资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.fvaluecompfasset IS '以公允价值计量且其变动计入其他综合收益的金融资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.amorcostfliabfld IS '以摊余成本计量的金融负债（非流动）';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.drawingexp IS '预提费用';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.contractasset IS '合同资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.accountbillrec IS '应收票据及应收账款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.heldsaleliab IS '持有待售负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.derivefasset IS '衍生金融资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.accountbillpay IS '应付票据及应付账款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.shortfinancing IS '应付短期融资款';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.credinv IS '债权投资';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.fvaluecompfassetfld IS '以公允价值计量且其变动计入其他综合收益的金融资产（非流动）';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.othcredinv IS '其他债权投资';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.marginoutfund IS '融出资金';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.amorcostfliab IS '以摊余成本计量的金融负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.amorcostfassetfld IS '以摊余成本计量的金融资产（非流动）';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.totalotherrece IS '其他应收款合计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.financerece IS '应收款项融资';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.userightasset IS '使用权资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.leaseliab IS '租赁负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.tradefinassetnotfvtpl IS '交易性金融资产';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.tradefinliabnotfvtpl IS '交易性金融负债';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.totalotherpayable IS '其他应付款合计';
COMMENT ON COLUMN app_api_financial_analysis_dd_debt.consumptivebiologicalasset IS '消耗性生物资产';
ALTER TABLE app_api_financial_analysis_dd_debt ADD CONSTRAINT app_api_financial_analysis_dd_debt_pkey PRIMARY KEY USING ubtree  (userid, reportdate, combinetype, companyname) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE app_api_financial_analysis_dd_profit (
    userid character varying(50) COLLATE "C" NOT NULL,
    reportdate character varying(50) COLLATE "C" NOT NULL,
    combinetype character varying(50) COLLATE "C" NOT NULL,
    companyname character varying(200) COLLATE "C" NOT NULL,
    sessionno character varying(50) COLLATE "C" NOT NULL,
    excelid character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    excelurl character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    uptime timestamp without time zone,
    reportno character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    assetdevalueloss numeric(38,18) DEFAULT NULL::numeric,
    basiceps numeric(38,18) DEFAULT NULL::numeric,
    cincomebalance1 numeric(38,18) DEFAULT NULL::numeric,
    cincomebalance2 numeric(38,18) DEFAULT NULL::numeric,
    combinednetprofitb numeric(38,18) DEFAULT NULL::numeric,
    commexp numeric(38,18) DEFAULT NULL::numeric,
    commreve numeric(38,18) DEFAULT NULL::numeric,
    dilutedeps numeric(38,18) DEFAULT NULL::numeric,
    exchangeincome numeric(38,18) DEFAULT NULL::numeric,
    financeexp numeric(38,18) DEFAULT NULL::numeric,
    fvalueincome numeric(38,18) DEFAULT NULL::numeric,
    incometax numeric(38,18) DEFAULT NULL::numeric,
    intexp numeric(38,18) DEFAULT NULL::numeric,
    intreve numeric(38,18) DEFAULT NULL::numeric,
    investincome numeric(38,18) DEFAULT NULL::numeric,
    investjointincome numeric(38,18) DEFAULT NULL::numeric,
    manageexp numeric(38,18) DEFAULT NULL::numeric,
    minoritycincome numeric(38,18) DEFAULT NULL::numeric,
    minorityincome numeric(38,18) DEFAULT NULL::numeric,
    minorityothercincome numeric(38,18) DEFAULT NULL::numeric,
    netcontactreserve numeric(38,18) DEFAULT NULL::numeric,
    netindemnityexp numeric(38,18) DEFAULT NULL::numeric,
    netprofit numeric(38,18) DEFAULT NULL::numeric,
    netprofitbalance1 numeric(38,18) DEFAULT NULL::numeric,
    netprofitbalance2 numeric(38,18) DEFAULT NULL::numeric,
    netprofitother1 numeric(38,18) DEFAULT NULL::numeric,
    netprofitother2 numeric(38,18) DEFAULT NULL::numeric,
    nonlassetnetloss numeric(38,18) DEFAULT NULL::numeric,
    nonoperateexp numeric(38,18) DEFAULT NULL::numeric,
    nonoperatereve numeric(38,18) DEFAULT NULL::numeric,
    operateexp numeric(38,18) DEFAULT NULL::numeric,
    operateprofit numeric(38,18) DEFAULT NULL::numeric,
    operateprofitbalance numeric(38,18) DEFAULT NULL::numeric,
    operateprofitother numeric(38,18) DEFAULT NULL::numeric,
    operatereve numeric(38,18) DEFAULT NULL::numeric,
    operatetax numeric(38,18) DEFAULT NULL::numeric,
    othercincome numeric(38,18) DEFAULT NULL::numeric,
    otherexp numeric(38,18) DEFAULT NULL::numeric,
    otherreve numeric(38,18) DEFAULT NULL::numeric,
    parentcincome numeric(38,18) DEFAULT NULL::numeric,
    parentnetprofit numeric(38,18) DEFAULT NULL::numeric,
    parentothercincome numeric(38,18) DEFAULT NULL::numeric,
    policydiviexp numeric(38,18) DEFAULT NULL::numeric,
    premiumearned numeric(38,18) DEFAULT NULL::numeric,
    rdexp numeric(38,18) DEFAULT NULL::numeric,
    riexp numeric(38,18) DEFAULT NULL::numeric,
    saleexp numeric(38,18) DEFAULT NULL::numeric,
    sumcincome numeric(38,18) DEFAULT NULL::numeric,
    sumprofit numeric(38,18) DEFAULT NULL::numeric,
    sumprofitbalance numeric(38,18) DEFAULT NULL::numeric,
    sumprofitother numeric(38,18) DEFAULT NULL::numeric,
    surrenderpremium numeric(38,18) DEFAULT NULL::numeric,
    totaloperateexp numeric(38,18) DEFAULT NULL::numeric,
    totaloperateexpother numeric(38,18) DEFAULT NULL::numeric,
    totaloperatereve numeric(38,18) DEFAULT NULL::numeric,
    totaloperatereveother numeric(38,18) DEFAULT NULL::numeric,
    unconfirminvloss numeric(38,18) DEFAULT NULL::numeric,
    fvalueosalable numeric(38,18) DEFAULT NULL::numeric,
    maturityrecsalable numeric(38,18) DEFAULT NULL::numeric,
    effectivecaflhedging numeric(38,18) DEFAULT NULL::numeric,
    diffconversionfc numeric(38,18) DEFAULT NULL::numeric,
    othercincomeother numeric(38,18) DEFAULT NULL::numeric,
    othercincomebalance numeric(38,18) DEFAULT NULL::numeric,
    nonlassetreve numeric(38,18) DEFAULT NULL::numeric,
    parothcinother numeric(38,18) DEFAULT NULL::numeric,
    parothcinbala numeric(38,18) DEFAULT NULL::numeric,
    combinedsumcincomeb numeric(38,18) DEFAULT NULL::numeric,
    sumcincomeother numeric(38,18) DEFAULT NULL::numeric,
    adisposalincome numeric(38,18) DEFAULT NULL::numeric,
    continuousonprofit numeric(38,18) DEFAULT NULL::numeric,
    terminationonprofit numeric(38,18) DEFAULT NULL::numeric,
    miotherincome numeric(38,18) DEFAULT NULL::numeric,
    ofwintexp numeric(38,18) DEFAULT NULL::numeric,
    ofwintreve numeric(38,18) DEFAULT NULL::numeric,
    otherequityinvfvalue numeric(38,18) DEFAULT NULL::numeric,
    credriskfvalue numeric(38,18) DEFAULT NULL::numeric,
    othcredinvfvalue numeric(38,18) DEFAULT NULL::numeric,
    fassetrecother numeric(38,18) DEFAULT NULL::numeric,
    othcredinvcred numeric(38,18) DEFAULT NULL::numeric,
    creddevalueloss numeric(38,18) DEFAULT NULL::numeric,
    netexhedgincome numeric(38,18) DEFAULT NULL::numeric,
    ofwrdexp numeric(38,18) DEFAULT NULL::numeric,
    acfendincome numeric(38,18) DEFAULT NULL::numeric,
    assetimpairmentincome numeric(38,18) DEFAULT NULL::numeric,
    creditimpairmentincome numeric(38,18) DEFAULT NULL::numeric
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_api_financial_analysis_dd_profit IS '利润表';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.userid IS '用户id';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.reportdate IS '报表日期';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.combinetype IS '报表合并类型';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.companyname IS '公司名称';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.sessionno IS '对话框编码';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.excelid IS '上传表id';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.excelurl IS '上传表url';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.uptime IS '上传时间';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.reportno IS '报告编号';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.assetdevalueloss IS '资产减值损失';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.basiceps IS '基本每股收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.cincomebalance1 IS '综合收益平衡项目1';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.cincomebalance2 IS '综合收益平衡项目2';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.combinednetprofitb IS '被合并方在合并前实现利润';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.commexp IS '手续费及佣金支出';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.commreve IS '手续费及佣金收入';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.dilutedeps IS '稀释每股收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.exchangeincome IS '汇兑收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.financeexp IS '财务费用';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.fvalueincome IS '公允价值变动收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.incometax IS '所得税费用';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.intexp IS '利息支出';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.intreve IS '利息收入';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.investincome IS '投资收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.investjointincome IS '对联营企业和合营企业的投资收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.manageexp IS '管理费用';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.minoritycincome IS '归属于少数股东的综合收益总额';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.minorityincome IS '少数股东损益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.minorityothercincome IS '归属于少数股东的其他综合收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.netcontactreserve IS '提取保险合同准备金净额';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.netindemnityexp IS '赔付支出净额';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.netprofit IS '净利润';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.netprofitbalance1 IS '净利润平衡项目1';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.netprofitbalance2 IS '净利润平衡项目2';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.netprofitother1 IS '影响净利润的其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.netprofitother2 IS '净利润其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.nonlassetnetloss IS '非流动资产处置净损失';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.nonoperateexp IS '营业外支出';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.nonoperatereve IS '营业外收入';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.operateexp IS '营业成本';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.operateprofit IS '营业利润';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.operateprofitbalance IS '营业利润平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.operateprofitother IS '营业利润其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.operatereve IS '营业收入';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.operatetax IS '营业税金及附加';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.othercincome IS '其他综合收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.otherexp IS '其他业务成本';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.otherreve IS '其他业务收入';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.parentcincome IS '归属于母公司所有者的综合收益总额';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.parentnetprofit IS '归属于母公司股东的净利润';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.parentothercincome IS '归属于母公司股东的其他综合收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.policydiviexp IS '保单红利支出';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.premiumearned IS '已赚保费';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.rdexp IS '研发费用';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.riexp IS '分保费用';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.saleexp IS '销售费用';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.sumcincome IS '综合收益总额';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.sumprofit IS '利润总额';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.sumprofitbalance IS '利润总额平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.sumprofitother IS '影响利润总额的其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.surrenderpremium IS '退保金';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.totaloperateexp IS '营业总成本';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.totaloperateexpother IS '营业总成本其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.totaloperatereve IS '营业总收入';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.totaloperatereveother IS '营业总收入其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.unconfirminvloss IS '未确认投资损失';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.fvalueosalable IS '可供出售金融资产公允价值变动损益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.maturityrecsalable IS '持有至到期投资重分类为可供出售金融资产损益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.effectivecaflhedging IS '现金流量套期损益的有效部分';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.diffconversionfc IS '外币财务报表折算差额';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.othercincomeother IS '其他综合收益其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.othercincomebalance IS '其他综合收益平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.nonlassetreve IS '非流动资产处置利得';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.parothcinother IS '归属母公司所有者的其他综合收益其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.parothcinbala IS '归属母公司所有者的其他综合收益平衡项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.combinedsumcincomeb IS '被合并方在合并前实现综合收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.sumcincomeother IS '综合收益总额其他项目';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.adisposalincome IS '资产处置收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.continuousonprofit IS '持续经营净利润';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.terminationonprofit IS '终止经营净利润';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.miotherincome IS '其他收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.ofwintexp IS '其中:利息费用';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.ofwintreve IS '其中:利息收入';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.otherequityinvfvalue IS '其他权益工具投资公允价值变动';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.credriskfvalue IS '企业自身信用风险公允价值变动';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.othcredinvfvalue IS '其他债权投资公允价值变动';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.fassetrecother IS '金融资产重分类计入其他综合收益的金额';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.othcredinvcred IS '其他债权投资信用减值准备';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.creddevalueloss IS '信用减值损失';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.netexhedgincome IS '净敞口套期收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.ofwrdexp IS '其中:研发费用';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.acfendincome IS '以摊余成本计量的金融资产终止确认收益';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.assetimpairmentincome IS '资产减值损失(新)';
COMMENT ON COLUMN app_api_financial_analysis_dd_profit.creditimpairmentincome IS '信用减值损失(新)';
ALTER TABLE app_api_financial_analysis_dd_profit ADD CONSTRAINT app_api_financial_analysis_dd_profit_pkey PRIMARY KEY USING ubtree  (userid, reportdate, combinetype, companyname) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE app_capital_flow_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    loanserialno character varying(64) COLLATE "C",
    serialno character varying(128) COLLATE "C",
    capitalchecktasktype character varying(64) COLLATE "C",
    approvestatus character varying(64) COLLATE "C",
    ispurposeabnormal character varying(64) COLLATE "C",
    rectificationsituation character varying(128) COLLATE "C",
    rectificationdeadline character varying(32) COLLATE "C",
    rectificationexplanation text,
    identifyreason text,
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_capital_flow_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_capital_flow_info IS '资金回流/用途异常表';
COMMENT ON COLUMN app_capital_flow_info.reportno IS '报告编号';
COMMENT ON COLUMN app_capital_flow_info.customerid IS '客户编号';
COMMENT ON COLUMN app_capital_flow_info.customername IS '客户名称';
COMMENT ON COLUMN app_capital_flow_info.loanserialno IS '借据号';
COMMENT ON COLUMN app_capital_flow_info.serialno IS '流水号';
COMMENT ON COLUMN app_capital_flow_info.capitalchecktasktype IS '任务类型（码值：资金用途检查任务类型（码值待确认））';
COMMENT ON COLUMN app_capital_flow_info.approvestatus IS '审批状态（码值：审批通过/待审批/驳回（码值待确认））';
COMMENT ON COLUMN app_capital_flow_info.ispurposeabnormal IS '是否回流异常（码值：是/否）';
COMMENT ON COLUMN app_capital_flow_info.rectificationsituation IS '整改情况';
COMMENT ON COLUMN app_capital_flow_info.rectificationdeadline IS '整改期限';
COMMENT ON COLUMN app_capital_flow_info.rectificationexplanation IS '整改情况说明';
COMMENT ON COLUMN app_capital_flow_info.identifyreason IS '认定理由';
COMMENT ON COLUMN app_capital_flow_info.inputtime IS '入库时间';
CREATE INDEX idx_capital_flow_info_customerid ON app_capital_flow_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_capital_flow_info_reportno ON app_capital_flow_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_check_index_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    chineseid character varying(64) COLLATE "C",
    chinesename character varying(128) COLLATE "C",
    yesno character varying(32) COLLATE "C",
    remark text,
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_check_index_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_check_index_info IS '日常检查综合指标表';
COMMENT ON COLUMN app_check_index_info.reportno IS '报告编号';
COMMENT ON COLUMN app_check_index_info.customerid IS '客户编号';
COMMENT ON COLUMN app_check_index_info.customername IS '客户名称';
COMMENT ON COLUMN app_check_index_info.chineseid IS '指标编号';
COMMENT ON COLUMN app_check_index_info.chinesename IS '指标名称';
COMMENT ON COLUMN app_check_index_info.yesno IS '检查结论（是/否）';
COMMENT ON COLUMN app_check_index_info.remark IS '说明';
COMMENT ON COLUMN app_check_index_info.inputtime IS '入库时间';
CREATE INDEX idx_check_index_info_customerid ON app_check_index_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_check_index_info_reportno ON app_check_index_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_check_opinion_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    conditiondesc text,
    completestatus character varying(64) COLLATE "C",
    conditioninstruction text,
    realcompletetime character varying(32) COLLATE "C",
    itemcategory character varying(64) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_check_opinion_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_check_opinion_info IS '批复后续管理要求表';
COMMENT ON COLUMN app_check_opinion_info.reportno IS '报告编号';
COMMENT ON COLUMN app_check_opinion_info.customerid IS '客户编号';
COMMENT ON COLUMN app_check_opinion_info.customername IS '客户名称';
COMMENT ON COLUMN app_check_opinion_info.conditiondesc IS '批复后续管理要求';
COMMENT ON COLUMN app_check_opinion_info.completestatus IS '完成情况（码值：已完成/未完成/部分完成（码值待确认））';
COMMENT ON COLUMN app_check_opinion_info.conditioninstruction IS '情况说明';
COMMENT ON COLUMN app_check_opinion_info.realcompletetime IS '实际完成日期';
COMMENT ON COLUMN app_check_opinion_info.itemcategory IS '事项类别';
COMMENT ON COLUMN app_check_opinion_info.inputtime IS '入库时间';
CREATE INDEX idx_check_opinion_info_customerid ON app_check_opinion_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_check_opinion_info_reportno ON app_check_opinion_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_check_record_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    checkintime character varying(32) COLLATE "C",
    checkinaddress character varying(256) COLLATE "C",
    visitobj character varying(128) COLLATE "C",
    checkinobj character varying(128) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_check_record_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_check_record_info IS '现场检查打卡记录表';
COMMENT ON COLUMN app_check_record_info.reportno IS '报告编号';
COMMENT ON COLUMN app_check_record_info.customerid IS '客户编号';
COMMENT ON COLUMN app_check_record_info.customername IS '客户名称';
COMMENT ON COLUMN app_check_record_info.checkintime IS '打卡日期';
COMMENT ON COLUMN app_check_record_info.checkinaddress IS '打卡地址';
COMMENT ON COLUMN app_check_record_info.visitobj IS '拜访对象';
COMMENT ON COLUMN app_check_record_info.checkinobj IS '打卡对象';
COMMENT ON COLUMN app_check_record_info.inputtime IS '入库时间';
CREATE INDEX idx_check_record_info_customerid ON app_check_record_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_check_record_info_reportno ON app_check_record_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_collateral_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    owner character varying(128) COLLATE "C",
    clrtype character varying(64) COLLATE "C",
    clrname character varying(128) COLLATE "C",
    clrstatus character varying(64) COLLATE "C",
    valuationdate character varying(32) COLLATE "C",
    choicetypename character varying(64) COLLATE "C",
    evaluatevalue numeric(18,2),
    rightorder character varying(64) COLLATE "C",
    rightsum numeric(18,2),
    confirmdate character varying(32) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_collateral_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_collateral_info IS '押品主档表';
COMMENT ON COLUMN app_collateral_info.reportno IS '报告编号';
COMMENT ON COLUMN app_collateral_info.customerid IS '客户编号';
COMMENT ON COLUMN app_collateral_info.customername IS '客户名称';
COMMENT ON COLUMN app_collateral_info.owner IS '权属人';
COMMENT ON COLUMN app_collateral_info.clrtype IS '押品类型（码值：不动产/动产/权利类等，码值待确认）';
COMMENT ON COLUMN app_collateral_info.clrname IS '押品名称';
COMMENT ON COLUMN app_collateral_info.clrstatus IS '押品状态（码值：正常/查封/冻结/处置中，码值待确认）';
COMMENT ON COLUMN app_collateral_info.valuationdate IS '押品最新评估日期';
COMMENT ON COLUMN app_collateral_info.choicetypename IS '评估方式（评估价/协议作价）';
COMMENT ON COLUMN app_collateral_info.evaluatevalue IS '评估价值（万元）';
COMMENT ON COLUMN app_collateral_info.rightorder IS '顺位';
COMMENT ON COLUMN app_collateral_info.rightsum IS '权证金额（万元）';
COMMENT ON COLUMN app_collateral_info.confirmdate IS '认定日期';
COMMENT ON COLUMN app_collateral_info.inputtime IS '入库时间';
CREATE INDEX idx_collateral_info_customerid ON app_collateral_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_collateral_info_reportno ON app_collateral_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_collateral_mortgage_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    clrname character varying(128) COLLATE "C",
    pledgeserialno character varying(64) COLLATE "C",
    pledgeename character varying(128) COLLATE "C",
    guaranteescope character varying(256) COLLATE "C",
    pledgetypename character varying(64) COLLATE "C",
    maxcreditoramt numeric(18,2),
    startend character varying(64) COLLATE "C",
    registertimestamp character varying(32) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_collateral_mortgage_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_collateral_mortgage_info IS '押品他项权利/限制权利表';
COMMENT ON COLUMN app_collateral_mortgage_info.reportno IS '报告编号';
COMMENT ON COLUMN app_collateral_mortgage_info.customerid IS '客户编号';
COMMENT ON COLUMN app_collateral_mortgage_info.customername IS '客户名称';
COMMENT ON COLUMN app_collateral_mortgage_info.clrname IS '关联押品名称';
COMMENT ON COLUMN app_collateral_mortgage_info.pledgeserialno IS '不动产登记编号';
COMMENT ON COLUMN app_collateral_mortgage_info.pledgeename IS '他项权姓名';
COMMENT ON COLUMN app_collateral_mortgage_info.guaranteescope IS '担保范围';
COMMENT ON COLUMN app_collateral_mortgage_info.pledgetypename IS '抵押方式（码值：一般抵押/最高额抵押等，码值待确认）';
COMMENT ON COLUMN app_collateral_mortgage_info.maxcreditoramt IS '债权数额（万元）';
COMMENT ON COLUMN app_collateral_mortgage_info.startend IS '债务履行期限';
COMMENT ON COLUMN app_collateral_mortgage_info.registertimestamp IS '设定日期';
COMMENT ON COLUMN app_collateral_mortgage_info.inputtime IS '入库时间';
CREATE INDEX idx_collateral_mortgage_info_customerid ON app_collateral_mortgage_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_collateral_mortgage_info_reportno ON app_collateral_mortgage_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_collateral_restricted_right (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    attachmentorg character varying(128) COLLATE "C",
    attachmenttypename character varying(64) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_collateral_restricted_right_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_collateral_restricted_right IS '押品限制权利表';
COMMENT ON COLUMN app_collateral_restricted_right.reportno IS '报告编号';
COMMENT ON COLUMN app_collateral_restricted_right.customerid IS '客户编号';
COMMENT ON COLUMN app_collateral_restricted_right.customername IS '客户名称';
COMMENT ON COLUMN app_collateral_restricted_right.attachmentorg IS '限制权人';
COMMENT ON COLUMN app_collateral_restricted_right.attachmenttypename IS '查封类型（码值：轮候查封/正式查封等，码值待确认）';
COMMENT ON COLUMN app_collateral_restricted_right.inputtime IS '入库时间';
CREATE INDEX idx_collateral_restricted_right_customerid ON app_collateral_restricted_right USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_collateral_restricted_right_reportno ON app_collateral_restricted_right USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_credit_debt_detail (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    querytime character varying(32) COLLATE "C",
    zxreportno character varying(128) COLLATE "C",
    debttype character varying(64) COLLATE "C",
    orgcount integer,
    balance numeric(18,2),
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    subjecttype character varying(64) COLLATE "C",
    guarantorid character varying(64) COLLATE "C",
    guarantorname character varying(128) COLLATE "C",
    CONSTRAINT app_credit_debt_detail_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 49
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_credit_debt_detail IS '征信债务明细表（按类型一期一行）';
COMMENT ON COLUMN app_credit_debt_detail.reportno IS '报告编号';
COMMENT ON COLUMN app_credit_debt_detail.customerid IS '客户编号';
COMMENT ON COLUMN app_credit_debt_detail.customername IS '客户名称';
COMMENT ON COLUMN app_credit_debt_detail.querytime IS '征信查询时间';
COMMENT ON COLUMN app_credit_debt_detail.zxreportno IS '征信报告记录号';
COMMENT ON COLUMN app_credit_debt_detail.debttype IS '债务类型（中长期借款/短期借款/循环透支/贴现/银行承兑汇票/信用证/银行保函/其他担保交易）';
COMMENT ON COLUMN app_credit_debt_detail.orgcount IS '未结清机构数合计';
COMMENT ON COLUMN app_credit_debt_detail.balance IS '未结清余额合计（万元）';
COMMENT ON COLUMN app_credit_debt_detail.inputtime IS '入库时间';
COMMENT ON COLUMN app_credit_debt_detail.subjecttype IS '主体类型（码值：借款人/担保人）';
COMMENT ON COLUMN app_credit_debt_detail.guarantorid IS '担保人客户编号（subjectType=担保人时填写）';
COMMENT ON COLUMN app_credit_debt_detail.guarantorname IS '担保人名称（subjectType=担保人时填写）';
CREATE INDEX idx_credit_debt_detail_debttype ON app_credit_debt_detail USING ubtree (debttype) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_credit_debt_detail_customerid ON app_credit_debt_detail USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_credit_debt_detail_reportno ON app_credit_debt_detail USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_credit_query_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    querytime character varying(32) COLLATE "C",
    zxreportno character varying(128) COLLATE "C",
    loanquery12m integer,
    loanquery6m integer,
    loanquery3m integer,
    cardquery12m integer,
    cardquery6m integer,
    cardquery3m integer,
    selfquery1m integer,
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    guarantorid character varying(64) COLLATE "C",
    guarantorname character varying(128) COLLATE "C",
    CONSTRAINT app_credit_query_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 4
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_credit_query_info IS '征信查询次数表';
COMMENT ON COLUMN app_credit_query_info.reportno IS '报告编号';
COMMENT ON COLUMN app_credit_query_info.customerid IS '客户编号';
COMMENT ON COLUMN app_credit_query_info.customername IS '客户名称';
COMMENT ON COLUMN app_credit_query_info.querytime IS '征信查询时间';
COMMENT ON COLUMN app_credit_query_info.zxreportno IS '征信报告记录号';
COMMENT ON COLUMN app_credit_query_info.loanquery12m IS '近一年贷款审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.loanquery6m IS '近6个月贷款审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.loanquery3m IS '近3个月贷款审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.cardquery12m IS '近一年信用卡审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.cardquery6m IS '近6个月信用卡审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.cardquery3m IS '近3个月信用卡审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.selfquery1m IS '近1个月本人查询征信查询次数';
COMMENT ON COLUMN app_credit_query_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_credit_query_info.guarantorid IS '担保人客户编号';
COMMENT ON COLUMN app_credit_query_info.guarantorname IS '担保人名称';
CREATE INDEX idx_credit_query_info_customerid ON app_credit_query_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_credit_query_info_reportno ON app_credit_query_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_credit_report_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    querytime character varying(32) COLLATE "C",
    zxreportno character varying(128) COLLATE "C",
    expiredate character varying(32) COLLATE "C",
    overduetotal numeric(18,2),
    attentioncreditbal numeric(18,2),
    badcreditbal numeric(18,2),
    attentionguaranteebal numeric(18,2),
    badguaranteebal numeric(18,2),
    guaranteeoverduetotal numeric(18,2),
    guaranteeattentionbal numeric(18,2),
    guaranteebadbal numeric(18,2),
    extenddebtbal numeric(18,2),
    restructuredebtbal numeric(18,2),
    renewdebtbal numeric(18,2),
    transferdebtbal numeric(18,2),
    newolddebtbal numeric(18,2),
    nonbankliabtotal numeric(18,2),
    nonbankhighrateloan numeric(12,4),
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    subjecttype character varying(64) COLLATE "C",
    guarantorid character varying(64) COLLATE "C",
    guarantorname character varying(128) COLLATE "C",
    nonbankguaranteebal numeric(18,2),
    workingcapitalloanbal numeric(18,2),
    workingcapitalloan1ybal numeric(18,2),
    loanbankorgcount integer,
    guaranteebankorgcount integer,
    creditshorttermdiff numeric(18,2),
    creditlongtermdiff numeric(18,2),
    creditdebtdeviation numeric(12,4),
    guaranteenetasset numeric(12,4),
    guaranteebalanceexbank numeric(18,2),
    CONSTRAINT app_credit_report_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 7
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_credit_report_info IS '企业征信快照表（一期一行）';
COMMENT ON COLUMN app_credit_report_info.reportno IS '报告编号';
COMMENT ON COLUMN app_credit_report_info.customerid IS '客户编号';
COMMENT ON COLUMN app_credit_report_info.customername IS '客户名称';
COMMENT ON COLUMN app_credit_report_info.querytime IS '征信查询时间';
COMMENT ON COLUMN app_credit_report_info.zxreportno IS '征信报告记录号';
COMMENT ON COLUMN app_credit_report_info.expiredate IS '征信报告有效期';
COMMENT ON COLUMN app_credit_report_info.overduetotal IS '未结清信贷的逾期总额（万元）';
COMMENT ON COLUMN app_credit_report_info.attentioncreditbal IS '未结清关注类信贷余额（万元）';
COMMENT ON COLUMN app_credit_report_info.badcreditbal IS '未结清不良类借贷余额（万元）';
COMMENT ON COLUMN app_credit_report_info.attentionguaranteebal IS '未结清关注类担保交易余额（万元）';
COMMENT ON COLUMN app_credit_report_info.badguaranteebal IS '未结清不良类担保交易余额（万元）';
COMMENT ON COLUMN app_credit_report_info.guaranteeoverduetotal IS '对外担保（相关还款责任）未结清逾期类负债总额（万元）';
COMMENT ON COLUMN app_credit_report_info.guaranteeattentionbal IS '对外担保（相关还款责任）未结清关注类负债总额（万元）';
COMMENT ON COLUMN app_credit_report_info.guaranteebadbal IS '对外担保（相关还款责任）未结清不良类负债总额（万元）';
COMMENT ON COLUMN app_credit_report_info.extenddebtbal IS '展期债务未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.restructuredebtbal IS '重组债务未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.renewdebtbal IS '无还本续贷未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.transferdebtbal IS '其他机构转入未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.newolddebtbal IS '借新还旧债务未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.nonbankliabtotal IS '在非银机构负债合计（万元，上游直给：qy_fyjg_liab_tot/gr_fyjg_liab_tot）';
COMMENT ON COLUMN app_credit_report_info.nonbankhighrateloan IS '非银机构较高利率借款推算利率最大值（%，企业，上游直给：qy_fyjg_gjlv_loan_max；较高利率判断依据）';
COMMENT ON COLUMN app_credit_report_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_credit_report_info.subjecttype IS '主体类型（码值：借款人/担保人）';
COMMENT ON COLUMN app_credit_report_info.guarantorid IS '担保人客户编号（subjectType=担保人时填写）';
COMMENT ON COLUMN app_credit_report_info.guarantorname IS '担保人名称（subjectType=担保人时填写）';
COMMENT ON COLUMN app_credit_report_info.nonbankguaranteebal IS '在非银机构对外担保余额（万元，上游直给：qy_fyjg_dwdb_bal）';
COMMENT ON COLUMN app_credit_report_info.workingcapitalloanbal IS '流动资金贷款余额（万元，上游直给：qy_zhint_wjq_xyldk_bal）';
COMMENT ON COLUMN app_credit_report_info.workingcapitalloan1ybal IS '一年期以下的流动资金贷款余额（万元，上游直给：qy_zhint_wjq_xyldk_1year_bal）';
COMMENT ON COLUMN app_credit_report_info.loanbankorgcount IS '企业借贷交易合作银行及融资租赁机构数（上游直给：qy_jiedai_hzyh_org_cnt）';
COMMENT ON COLUMN app_credit_report_info.guaranteebankorgcount IS '企业担保交易合作银行及融资租赁机构数（上游直给：qy_danbao_hzyh_org_cnt）';
COMMENT ON COLUMN app_credit_report_info.creditshorttermdiff IS '征信短期借款未结清余额与财报短期借款相差（万元，加工结果默认已有）';
COMMENT ON COLUMN app_credit_report_info.creditlongtermdiff IS '征信中长期借款未结清余额与财报长期借款（含一年内到期的长期借款）相差（万元，加工结果默认已有）';
COMMENT ON COLUMN app_credit_report_info.creditdebtdeviation IS '征信债务与财报债务偏离度（%，加工结果默认已有）';
COMMENT ON COLUMN app_credit_report_info.guaranteenetasset IS '对外担保/净资产（%）';
COMMENT ON COLUMN app_credit_report_info.guaranteebalanceexbank IS '对外担保（相关还款责任）余额（剔除我行）（万元，上游直给：qy_dwdb_bal_exc_wx）';
CREATE INDEX idx_credit_report_info_customerid ON app_credit_report_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_credit_report_info_reportno ON app_credit_report_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_credit_use_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    creditsum numeric(18,2),
    balance numeric(18,2),
    exposureamount numeric(18,2),
    limitbalance numeric(18,2),
    groupamount numeric(18,2),
    groupbalance numeric(18,2),
    isgroup character varying(32) COLLATE "C",
    groupname character varying(128) COLLATE "C",
    creditdate character varying(32) COLLATE "C",
    latestoverduedate character varying(32) COLLATE "C",
    gdoverduecounts integer,
    ajoverduecounts integer,
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_credit_use_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_credit_use_info IS '授信用信概况表';
COMMENT ON COLUMN app_credit_use_info.reportno IS '报告编号';
COMMENT ON COLUMN app_credit_use_info.customerid IS '客户编号';
COMMENT ON COLUMN app_credit_use_info.customername IS '客户名称';
COMMENT ON COLUMN app_credit_use_info.creditsum IS '授信金额（万元）';
COMMENT ON COLUMN app_credit_use_info.balance IS '总余额（万元）';
COMMENT ON COLUMN app_credit_use_info.exposureamount IS '敞口金额（万元）';
COMMENT ON COLUMN app_credit_use_info.limitbalance IS '敞口余额（万元）';
COMMENT ON COLUMN app_credit_use_info.groupamount IS '集团授信金额（万元）';
COMMENT ON COLUMN app_credit_use_info.groupbalance IS '集团总余额（万元）';
COMMENT ON COLUMN app_credit_use_info.isgroup IS '是否集团客户（码值：是/否）';
COMMENT ON COLUMN app_credit_use_info.groupname IS '所属集团名称';
COMMENT ON COLUMN app_credit_use_info.creditdate IS '授信日期（授信时点，用于反查报表期）';
COMMENT ON COLUMN app_credit_use_info.latestoverduedate IS '企业当前最近一次逾期日期';
COMMENT ON COLUMN app_credit_use_info.gdoverduecounts IS '固贷产品近一年历史逾期次数';
COMMENT ON COLUMN app_credit_use_info.ajoverduecounts IS '按揭贷款产品近一年历史逾期次数（房开贷暂取此值，待确认）';
COMMENT ON COLUMN app_credit_use_info.inputtime IS '入库时间';
CREATE INDEX idx_credit_use_info_customerid ON app_credit_use_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_credit_use_info_reportno ON app_credit_use_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_customer_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    legalperson character varying(128) COLLATE "C",
    registercapital numeric(18,2),
    paidincapital numeric(18,2),
    industrytype character varying(64) COLLATE "C",
    holdtype character varying(64) COLLATE "C",
    actualcontroller character varying(128) COLLATE "C",
    officeaddress character varying(256) COLLATE "C",
    businessscope text,
    dangerlevel character varying(64) COLLATE "C",
    warninglevel character varying(64) COLLATE "C",
    isstateowned character varying(64) COLLATE "C",
    isfakestateowned character varying(64) COLLATE "C",
    islistedcompany character varying(32) COLLATE "C",
    groupname character varying(128) COLLATE "C",
    istechcompany character varying(64) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_customer_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_customer_info IS '客户工商概况表';
COMMENT ON COLUMN app_customer_info.reportno IS '报告编号';
COMMENT ON COLUMN app_customer_info.customerid IS '客户编号';
COMMENT ON COLUMN app_customer_info.customername IS '客户名称';
COMMENT ON COLUMN app_customer_info.legalperson IS '法定代表人';
COMMENT ON COLUMN app_customer_info.registercapital IS '注册资本（万元）';
COMMENT ON COLUMN app_customer_info.paidincapital IS '实收资本（万元）';
COMMENT ON COLUMN app_customer_info.industrytype IS '行业分类（码值：GB/T 4754 行业代码，码值待确认）';
COMMENT ON COLUMN app_customer_info.holdtype IS '控股类型（码值：国有绝对控股/国有相对控股/集体绝对控股/集体相对控股（国营），其余为民营）';
COMMENT ON COLUMN app_customer_info.actualcontroller IS '实际控制人';
COMMENT ON COLUMN app_customer_info.officeaddress IS '办公地址';
COMMENT ON COLUMN app_customer_info.businessscope IS '经营范围';
COMMENT ON COLUMN app_customer_info.dangerlevel IS '十级分类（码值：银行十级分类（1-4正常/5-6关注/7-8次级可疑/9-10损失，具体码值待确认））';
COMMENT ON COLUMN app_customer_info.warninglevel IS '预警等级（码值：高/中/低，码值待确认）';
COMMENT ON COLUMN app_customer_info.isstateowned IS '是否国资/国有担保（码值：是/否（由控股类型holdType判断））';
COMMENT ON COLUMN app_customer_info.isfakestateowned IS '是否假冒国企（码值：是/否）';
COMMENT ON COLUMN app_customer_info.islistedcompany IS '借款人是否上市公司（码值：是/否，中台接口）';
COMMENT ON COLUMN app_customer_info.groupname IS '所属集团名称';
COMMENT ON COLUMN app_customer_info.istechcompany IS '是否科创企业（码值：是/否）';
COMMENT ON COLUMN app_customer_info.inputtime IS '入库时间';
CREATE INDEX idx_customer_info_customerid ON app_customer_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_customer_info_reportno ON app_customer_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_early_warning_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    confirmtime character varying(32) COLLATE "C",
    inputdate character varying(32) COLLATE "C",
    approvestatusname character varying(64) COLLATE "C",
    phaseopinion text,
    endtime character varying(32) COLLATE "C",
    risktasktype character varying(64) COLLATE "C",
    tasktype character varying(64) COLLATE "C",
    warnlevel character varying(64) COLLATE "C",
    riskreason text,
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_early_warning_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_early_warning_info IS '预警任务台账表';
COMMENT ON COLUMN app_early_warning_info.reportno IS '报告编号';
COMMENT ON COLUMN app_early_warning_info.customerid IS '客户编号';
COMMENT ON COLUMN app_early_warning_info.customername IS '客户名称';
COMMENT ON COLUMN app_early_warning_info.confirmtime IS '预警本次认定时间';
COMMENT ON COLUMN app_early_warning_info.inputdate IS '预警本次发起时间';
COMMENT ON COLUMN app_early_warning_info.approvestatusname IS '审批状态（码值：审批通过/待审批/驳回（码值待确认））';
COMMENT ON COLUMN app_early_warning_info.phaseopinion IS '审批意见';
COMMENT ON COLUMN app_early_warning_info.endtime IS '审批日期';
COMMENT ON COLUMN app_early_warning_info.risktasktype IS '任务类型（码值：预警任务类型（码值待确认））';
COMMENT ON COLUMN app_early_warning_info.tasktype IS '任务类型（审批通过预警任务、最近一条预警任务）';
COMMENT ON COLUMN app_early_warning_info.warnlevel IS '客户风险等级（码值：高/中/低，码值待确认）';
COMMENT ON COLUMN app_early_warning_info.riskreason IS '风险原因';
COMMENT ON COLUMN app_early_warning_info.inputtime IS '入库时间';
CREATE INDEX idx_early_warning_info_customerid ON app_early_warning_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_early_warning_info_reportno ON app_early_warning_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_early_warning_signal_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    serialno character varying(64) COLLATE "C",
    riskmessage character varying(500) COLLATE "C",
    count integer,
    readycount integer,
    status character varying(64) COLLATE "C",
    warninglevel character varying(64) COLLATE "C",
    inputdate character varying(64) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_early_warning_signal_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_early_warning_signal_info IS '预警信号明细表';
COMMENT ON COLUMN app_early_warning_signal_info.reportno IS '报告编号';
COMMENT ON COLUMN app_early_warning_signal_info.customerid IS '客户编号';
COMMENT ON COLUMN app_early_warning_signal_info.customername IS '客户名称';
COMMENT ON COLUMN app_early_warning_signal_info.serialno IS '预警编号（近一年预警台账接口serialNo）';
COMMENT ON COLUMN app_early_warning_signal_info.riskmessage IS '风险原因';
COMMENT ON COLUMN app_early_warning_signal_info.count IS '数量';
COMMENT ON COLUMN app_early_warning_signal_info.readycount IS '待填写数量';
COMMENT ON COLUMN app_early_warning_signal_info.status IS '信号状态（近一年预警台账接口status）';
COMMENT ON COLUMN app_early_warning_signal_info.warninglevel IS '预警信号风险等级（接口warningLevel）';
COMMENT ON COLUMN app_early_warning_signal_info.inputdate IS '信号建立时间（接口inputDate）';
COMMENT ON COLUMN app_early_warning_signal_info.inputtime IS '入库时间';
CREATE INDEX idx_early_warning_signal_info_customerid ON app_early_warning_signal_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_early_warning_signal_info_reportno ON app_early_warning_signal_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_entrust_pay_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    paymentmode character varying(64) COLLATE "C",
    paydate character varying(32) COLLATE "C",
    accountname character varying(128) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_entrust_pay_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_entrust_pay_info IS '受托支付明细表';
COMMENT ON COLUMN app_entrust_pay_info.reportno IS '报告编号';
COMMENT ON COLUMN app_entrust_pay_info.customerid IS '客户编号';
COMMENT ON COLUMN app_entrust_pay_info.customername IS '客户名称';
COMMENT ON COLUMN app_entrust_pay_info.paymentmode IS '支付方式（码值：受托支付/自主支付，码值待确认）';
COMMENT ON COLUMN app_entrust_pay_info.paydate IS '支付日期';
COMMENT ON COLUMN app_entrust_pay_info.accountname IS '收款人名称';
COMMENT ON COLUMN app_entrust_pay_info.inputtime IS '入库时间';
CREATE INDEX idx_entrust_pay_info_customerid ON app_entrust_pay_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_entrust_pay_info_reportno ON app_entrust_pay_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_finance_index_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    accountmonth character varying(32) COLLATE "C",
    reportscope character varying(64) COLLATE "C",
    sheetno character varying(64) COLLATE "C",
    reportperiod character varying(64) COLLATE "C",
    indextype character varying(64) COLLATE "C",
    indexvalue numeric(18,2),
    yoyvalue numeric(12,4),
    changevalue numeric(18,2),
    changerate numeric(12,4),
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    currencyunit character varying(32) COLLATE "C",
    CONSTRAINT app_finance_index_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 211
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_finance_index_info IS '财务指标值表（一期一行一指标；同比/较年初等对比值由查询层计算，不落表）';
COMMENT ON COLUMN app_finance_index_info.reportno IS '报告编号';
COMMENT ON COLUMN app_finance_index_info.customerid IS '客户编号';
COMMENT ON COLUMN app_finance_index_info.customername IS '客户名称';
COMMENT ON COLUMN app_finance_index_info.accountmonth IS '会计月';
COMMENT ON COLUMN app_finance_index_info.reportscope IS '报表口径（码值：合并/本部）';
COMMENT ON COLUMN app_finance_index_info.sheetno IS '报表类型（码值：资产负债表/利润表/现金流量表等，码值待确认）';
COMMENT ON COLUMN app_finance_index_info.reportperiod IS '报表周期（码值：年报/半年报/季报/月报，码值待确认）';
COMMENT ON COLUMN app_finance_index_info.indextype IS '指标类型（金额科目：营收/净利润/实收资本/短期借款/长期借款/一年内到期长期借款/应收账款/其他应收款/应付票据/其他应付款/存货/总资产，单位万元；比率指标：资产负债率/销售利率/净利率，存百分数值，如65.43表示65.43%）';
COMMENT ON COLUMN app_finance_index_info.indexvalue IS '指标本期值（金额科目=万元；比率指标=百分数值，如65.43表示65.43%）';
COMMENT ON COLUMN app_finance_index_info.yoyvalue IS '同比（%）：该期值÷上年同期值−1；行级属性各期行自带，上游计算或加工层预填（默认已有）';
COMMENT ON COLUMN app_finance_index_info.changevalue IS '较年初变动（万元）：该期值−上年末(12月)值；行级属性各期行自带（默认已有）';
COMMENT ON COLUMN app_finance_index_info.changerate IS '较年初增幅（%）：(该期值−上年末值)÷上年末值；行级属性各期行自带（默认已有）';
COMMENT ON COLUMN app_finance_index_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_finance_index_info.currencyunit IS '货币单位（码值：元/千/万，样例为万）';
CREATE INDEX idx_finance_index_info_reportscope ON app_finance_index_info USING ubtree (reportscope) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_finance_index_info_accountmonth ON app_finance_index_info USING ubtree (accountmonth) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_finance_index_info_indextype ON app_finance_index_info USING ubtree (indextype) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_finance_index_info_customerid ON app_finance_index_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_finance_index_info_reportno ON app_finance_index_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_finance_report_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    accountmonth character varying(32) COLLATE "C",
    sheetno character varying(64) COLLATE "C",
    reportscope character varying(64) COLLATE "C",
    reportperiod character varying(64) COLLATE "C",
    auditflag character varying(32) COLLATE "C",
    currency character varying(32) COLLATE "C",
    reportstatus character varying(32) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    currencyunit character varying(32) COLLATE "C",
    CONSTRAINT app_finance_report_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 11
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_finance_report_info IS '财报主档表（一期一行）';
COMMENT ON COLUMN app_finance_report_info.reportno IS '报告编号';
COMMENT ON COLUMN app_finance_report_info.customerid IS '客户编号';
COMMENT ON COLUMN app_finance_report_info.customername IS '客户名称';
COMMENT ON COLUMN app_finance_report_info.accountmonth IS '会计月';
COMMENT ON COLUMN app_finance_report_info.sheetno IS '报表类型（码值：资产负债表/利润表/现金流量表等，码值待确认）';
COMMENT ON COLUMN app_finance_report_info.reportscope IS '报表口径（码值：合并/本部）';
COMMENT ON COLUMN app_finance_report_info.reportperiod IS '报表周期（码值：年报/半年报/季报/月报，码值待确认）';
COMMENT ON COLUMN app_finance_report_info.auditflag IS '是否审计（码值：是/否）';
COMMENT ON COLUMN app_finance_report_info.currency IS '报表币种';
COMMENT ON COLUMN app_finance_report_info.reportstatus IS '报表状态（锁定/未锁定，是否锁定状态判断依据）';
COMMENT ON COLUMN app_finance_report_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_finance_report_info.currencyunit IS '货币单位（码值：元/千/万，样例为万）';
CREATE INDEX idx_finance_report_info_accountmonth ON app_finance_report_info USING ubtree (accountmonth) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_finance_report_info_customerid ON app_finance_report_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_finance_report_info_reportno ON app_finance_report_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_guarantor_credit_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    guarantorname character varying(128) COLLATE "C",
    querytime character varying(32) COLLATE "C",
    zxreportno character varying(128) COLLATE "C",
    totalloanbal numeric(18,2),
    operateloanbal numeric(18,2),
    consumeloanbal numeric(18,2),
    houseloanbal numeric(18,2),
    otherloanbal numeric(18,2),
    totalloancount integer,
    operateloancount integer,
    consumeloancount integer,
    houseloancount integer,
    otherloancount integer,
    bzcbal numeric(18,2),
    badbal numeric(18,2),
    loancurrentoverdue numeric(18,2),
    cardcurrentoverdue numeric(18,2),
    guaranteeoverdueamt numeric(18,2),
    nonbankguaranteebal numeric(18,2),
    nonbankhighrateloan numeric(12,4),
    guaranteeabnormalbal numeric(18,2),
    extendbal numeric(18,2),
    delaybal numeric(18,2),
    creditabnormalbal numeric(18,2),
    acctabnormalbal numeric(18,2),
    cardabnormalbal numeric(18,2),
    guaranteehkabnormalbal numeric(18,2),
    credituserate numeric(12,4),
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    guarantorid character varying(64) COLLATE "C",
    nonbankliabtotal numeric(18,2),
    CONSTRAINT app_guarantor_credit_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 4
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_guarantor_credit_info IS '担保人征信表';
COMMENT ON COLUMN app_guarantor_credit_info.reportno IS '报告编号';
COMMENT ON COLUMN app_guarantor_credit_info.customerid IS '客户编号';
COMMENT ON COLUMN app_guarantor_credit_info.customername IS '客户名称';
COMMENT ON COLUMN app_guarantor_credit_info.guarantorname IS '担保人';
COMMENT ON COLUMN app_guarantor_credit_info.querytime IS '征信查询时间';
COMMENT ON COLUMN app_guarantor_credit_info.zxreportno IS '征信报告记录号';
COMMENT ON COLUMN app_guarantor_credit_info.totalloanbal IS '贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.operateloanbal IS '经营性贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.consumeloanbal IS '消费类贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.houseloanbal IS '住房类贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.otherloanbal IS '其他贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.totalloancount IS '贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.operateloancount IS '经营性贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.consumeloancount IS '消费类贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.houseloancount IS '住房类贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.otherloancount IS '其他贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.bzcbal IS '被追偿余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.badbal IS '呆账余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.loancurrentoverdue IS '贷款当前逾期总金额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.cardcurrentoverdue IS '贷记卡当前逾期总金额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.guaranteeoverdueamt IS '对外担保（相关还款责任）当前逾期金额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.nonbankguaranteebal IS '在非银机构对外担保余额（万元，上游直给：qy_fyjg_dwdb_bal/gr_fyjg_dwdb_bal）';
COMMENT ON COLUMN app_guarantor_credit_info.nonbankhighrateloan IS '非银机构较高利率借款推算利率最大值（%，上游直给：qy_fyjg_gjlv_loan_max/gr_fyjg_gjlv_loan_max；较高利率判断依据）';
COMMENT ON COLUMN app_guarantor_credit_info.guaranteeabnormalbal IS '对外担保（相关还款责任）五级分类非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.extendbal IS '展期债务余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.delaybal IS '落实金融困等政策银行主动延期债务余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.creditabnormalbal IS '未结清信贷五级分类非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.acctabnormalbal IS '未结清账户状态非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.cardabnormalbal IS '未销户贷记卡账户状态非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.guaranteehkabnormalbal IS '对外担保（相关还款责任）还款状态非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.credituserate IS '信用卡使用率（%）';
COMMENT ON COLUMN app_guarantor_credit_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_guarantor_credit_info.guarantorid IS '担保人客户编号';
COMMENT ON COLUMN app_guarantor_credit_info.nonbankliabtotal IS '在非银机构负债合计（万元，个人，上游直给：gr_fyjg_liab_tot）';
CREATE INDEX idx_guarantor_credit_info_guarantorname ON app_guarantor_credit_info USING ubtree (guarantorname) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_guarantor_credit_info_customerid ON app_guarantor_credit_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_guarantor_credit_info_reportno ON app_guarantor_credit_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_guarantor_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    guarantorname character varying(128) COLLATE "C",
    guarantortype character varying(32) COLLATE "C",
    isstateowned character varying(64) COLLATE "C",
    education character varying(64) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    guarantorid character varying(64) COLLATE "C",
    CONSTRAINT app_guarantor_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 3
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_guarantor_info IS '担保人信息表';
COMMENT ON COLUMN app_guarantor_info.reportno IS '报告编号';
COMMENT ON COLUMN app_guarantor_info.customerid IS '客户编号';
COMMENT ON COLUMN app_guarantor_info.customername IS '客户名称';
COMMENT ON COLUMN app_guarantor_info.guarantorname IS '担保人';
COMMENT ON COLUMN app_guarantor_info.guarantortype IS '担保人类型（法人/自然人）';
COMMENT ON COLUMN app_guarantor_info.isstateowned IS '是否国资/国有担保';
COMMENT ON COLUMN app_guarantor_info.education IS '学历（征信基本信息，接口zxBiEDULVL）';
COMMENT ON COLUMN app_guarantor_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_guarantor_info.guarantorid IS '担保人客户编号（行内接口字段）';
CREATE INDEX idx_guarantor_info_customerid ON app_guarantor_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_guarantor_info_reportno ON app_guarantor_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_guofa_report_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    querytime character varying(32) COLLATE "C",
    gfrevenue numeric(18,2),
    gfreceivable numeric(18,2),
    gfpayable numeric(18,2),
    gfinventory numeric(18,2),
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_guofa_report_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_guofa_report_info IS '国发征信信息表';
COMMENT ON COLUMN app_guofa_report_info.reportno IS '报告编号';
COMMENT ON COLUMN app_guofa_report_info.customerid IS '客户编号';
COMMENT ON COLUMN app_guofa_report_info.customername IS '客户名称';
COMMENT ON COLUMN app_guofa_report_info.querytime IS '国发征信查询时间';
COMMENT ON COLUMN app_guofa_report_info.gfrevenue IS '国发征信营收（万元，上游直给）';
COMMENT ON COLUMN app_guofa_report_info.gfreceivable IS '国发征信应收账款（万元，上游直给）';
COMMENT ON COLUMN app_guofa_report_info.gfpayable IS '国发征信应付账款（万元，上游直给）';
COMMENT ON COLUMN app_guofa_report_info.gfinventory IS '国发征信存货（万元，上游直给）';
COMMENT ON COLUMN app_guofa_report_info.inputtime IS '入库时间';
CREATE INDEX idx_guofa_report_info_querytime ON app_guofa_report_info USING ubtree (querytime) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_guofa_report_info_customerid ON app_guofa_report_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_guofa_report_info_reportno ON app_guofa_report_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_ic_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    snapshot_type character varying(32) COLLATE "C",
    iclegalperson character varying(128) COLLATE "C",
    icregistercapital numeric(18,2),
    icpaidincapital numeric(18,2),
    icbeneficiaryname character varying(128) COLLATE "C",
    systemactualcontroller character varying(128) COLLATE "C",
    icbeneficiarypercent numeric(12,4),
    isstateowned character varying(64) COLLATE "C",
    isfakestateowned character varying(64) COLLATE "C",
    cancellationdate character varying(32) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_ic_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_ic_info IS '工商登记信息表（客户级）';
COMMENT ON COLUMN app_ic_info.reportno IS '报告编号';
COMMENT ON COLUMN app_ic_info.customerid IS '客户编号';
COMMENT ON COLUMN app_ic_info.customername IS '客户名称';
COMMENT ON COLUMN app_ic_info.snapshot_type IS '快照类型（latest最新/atCredit授信时）';
COMMENT ON COLUMN app_ic_info.iclegalperson IS '工商法定代表人';
COMMENT ON COLUMN app_ic_info.icregistercapital IS '工商注册资本（万元）';
COMMENT ON COLUMN app_ic_info.icpaidincapital IS '工商实缴资本（万元）';
COMMENT ON COLUMN app_ic_info.icbeneficiaryname IS '工商受益人名称';
COMMENT ON COLUMN app_ic_info.systemactualcontroller IS '系统实际控制人（多时点快照，授信时/最新）';
COMMENT ON COLUMN app_ic_info.icbeneficiarypercent IS '工商受益人持股比例（%）';
COMMENT ON COLUMN app_ic_info.isstateowned IS '是否国有企业（工商口径）（码值：是/否（工商口径））';
COMMENT ON COLUMN app_ic_info.isfakestateowned IS '是否假冒国企（工商口径）（码值：是/否（工商口径））';
COMMENT ON COLUMN app_ic_info.cancellationdate IS '注销日期';
COMMENT ON COLUMN app_ic_info.inputtime IS '入库时间';
CREATE INDEX idx_ic_info_customerid ON app_ic_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_ic_info_reportno ON app_ic_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_ic_shareholder_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    snapshot_type character varying(32) COLLATE "C",
    icshareholdername character varying(128) COLLATE "C",
    icstocknum integer,
    icstockpercent numeric(12,4),
    icamount numeric(18,2),
    changetime character varying(32) COLLATE "C",
    percentbefore numeric(12,4),
    percentafter numeric(12,4),
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_ic_shareholder_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_ic_shareholder_info IS '工商股东变更表（股权变更历史：变更时间/变更前后比例，多时点快照）';
COMMENT ON COLUMN app_ic_shareholder_info.reportno IS '报告编号';
COMMENT ON COLUMN app_ic_shareholder_info.customerid IS '客户编号';
COMMENT ON COLUMN app_ic_shareholder_info.customername IS '客户名称';
COMMENT ON COLUMN app_ic_shareholder_info.snapshot_type IS '快照类型（latest最新/atCredit授信时）';
COMMENT ON COLUMN app_ic_shareholder_info.icshareholdername IS '工商股东名称';
COMMENT ON COLUMN app_ic_shareholder_info.icstocknum IS '工商股东持股数';
COMMENT ON COLUMN app_ic_shareholder_info.icstockpercent IS '工商股东持股比例（%）';
COMMENT ON COLUMN app_ic_shareholder_info.icamount IS '工商股东出资金额（万元）';
COMMENT ON COLUMN app_ic_shareholder_info.changetime IS '股权变更时间（授信时点后的变更）';
COMMENT ON COLUMN app_ic_shareholder_info.percentbefore IS '变更前持股比例（%）';
COMMENT ON COLUMN app_ic_shareholder_info.percentafter IS '变更后持股比例（%）';
COMMENT ON COLUMN app_ic_shareholder_info.inputtime IS '入库时间';
CREATE INDEX idx_ic_shareholder_info_customerid ON app_ic_shareholder_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_ic_shareholder_info_reportno ON app_ic_shareholder_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_loan_plan_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    producttype character varying(32) COLLATE "C",
    nextpaydate character varying(32) COLLATE "C",
    payprincipalamt numeric(18,2),
    payinterestamt numeric(18,2),
    payfineamt numeric(18,2),
    compoundinterest numeric(18,2),
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_loan_plan_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_loan_plan_info IS '贷款产品还本付息计划表';
COMMENT ON COLUMN app_loan_plan_info.reportno IS '报告编号';
COMMENT ON COLUMN app_loan_plan_info.customerid IS '客户编号';
COMMENT ON COLUMN app_loan_plan_info.customername IS '客户名称';
COMMENT ON COLUMN app_loan_plan_info.producttype IS '产品类型（码值：固贷/房地产开发贷款）';
COMMENT ON COLUMN app_loan_plan_info.nextpaydate IS '下次还款日';
COMMENT ON COLUMN app_loan_plan_info.payprincipalamt IS '下次还款本金（万元）';
COMMENT ON COLUMN app_loan_plan_info.payinterestamt IS '下次还款利息（万元）';
COMMENT ON COLUMN app_loan_plan_info.payfineamt IS '下次还款罚息（万元）';
COMMENT ON COLUMN app_loan_plan_info.compoundinterest IS '下次还款复利（万元）';
COMMENT ON COLUMN app_loan_plan_info.inputtime IS '入库时间';
CREATE INDEX idx_loan_plan_info_customerid ON app_loan_plan_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_loan_plan_info_reportno ON app_loan_plan_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_loan_receipt_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    loanserialno character varying(64) COLLATE "C",
    loanstatus character varying(64) COLLATE "C",
    productname character varying(128) COLLATE "C",
    producttype character varying(64) COLLATE "C",
    purposename character varying(128) COLLATE "C",
    balance numeric(18,2),
    productbelongname character varying(128) COLLATE "C",
    overduebalance numeric(18,2),
    overdueinterestamt numeric(18,2),
    isrestructed character varying(32) COLLATE "C",
    extendbalance numeric(18,2),
    restructedbalance numeric(18,2),
    reorgtimes integer,
    reorgbalance numeric(18,2),
    loanchangerptcounts integer,
    loanchangerptbalance numeric(18,2),
    occurtype character varying(32) COLLATE "C",
    isextend character varying(32) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_loan_receipt_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_loan_receipt_info IS '借据信息表';
COMMENT ON COLUMN app_loan_receipt_info.reportno IS '报告编号';
COMMENT ON COLUMN app_loan_receipt_info.customerid IS '客户编号';
COMMENT ON COLUMN app_loan_receipt_info.customername IS '客户名称';
COMMENT ON COLUMN app_loan_receipt_info.loanserialno IS '借据号';
COMMENT ON COLUMN app_loan_receipt_info.loanstatus IS '借据状态（码值：正常/逾期/欠息/结清/呆账（码值待确认））';
COMMENT ON COLUMN app_loan_receipt_info.productname IS '基础产品名称';
COMMENT ON COLUMN app_loan_receipt_info.producttype IS '产品类型（基础/组合/固贷/房地产）';
COMMENT ON COLUMN app_loan_receipt_info.purposename IS '用途';
COMMENT ON COLUMN app_loan_receipt_info.balance IS '借据余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.productbelongname IS '产品归属（组合产品）';
COMMENT ON COLUMN app_loan_receipt_info.overduebalance IS '期供欠本金额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.overdueinterestamt IS '期供欠息金额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.isrestructed IS '是否重组优化贷款（码值：是/否）';
COMMENT ON COLUMN app_loan_receipt_info.extendbalance IS '展期贷款余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.restructedbalance IS '重组贷款余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.reorgtimes IS '借新还旧次数';
COMMENT ON COLUMN app_loan_receipt_info.reorgbalance IS '借新还旧余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.loanchangerptcounts IS '还款方式变更笔数';
COMMENT ON COLUMN app_loan_receipt_info.loanchangerptbalance IS '还款方式变更贷款余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.occurtype IS '发生类型';
COMMENT ON COLUMN app_loan_receipt_info.isextend IS '是否展期（码值：是/否）';
COMMENT ON COLUMN app_loan_receipt_info.inputtime IS '入库时间';
CREATE INDEX idx_loan_receipt_info_customerid ON app_loan_receipt_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_loan_receipt_info_reportno ON app_loan_receipt_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_opinion_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    phaseopinion text,
    endtime character varying(32) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_opinion_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_opinion_info IS '贷后意见表';
COMMENT ON COLUMN app_opinion_info.reportno IS '报告编号';
COMMENT ON COLUMN app_opinion_info.customerid IS '客户编号';
COMMENT ON COLUMN app_opinion_info.customername IS '客户名称';
COMMENT ON COLUMN app_opinion_info.phaseopinion IS '审批意见';
COMMENT ON COLUMN app_opinion_info.endtime IS '审批日期';
COMMENT ON COLUMN app_opinion_info.inputtime IS '入库时间';
CREATE INDEX idx_opinion_info_customerid ON app_opinion_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_opinion_info_reportno ON app_opinion_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_payroll_stat_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    statmonth character varying(32) COLLATE "C",
    payrollcount integer,
    payrollamount numeric(18,2),
    countmom numeric(12,4),
    amountmom numeric(12,4),
    countyoy numeric(12,4),
    amountyoy numeric(12,4),
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_payroll_stat_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_payroll_stat_info IS '代发统计表（月粒度）';
COMMENT ON COLUMN app_payroll_stat_info.reportno IS '报告编号';
COMMENT ON COLUMN app_payroll_stat_info.customerid IS '客户编号';
COMMENT ON COLUMN app_payroll_stat_info.customername IS '客户名称';
COMMENT ON COLUMN app_payroll_stat_info.statmonth IS '统计月份';
COMMENT ON COLUMN app_payroll_stat_info.payrollcount IS '代发人数';
COMMENT ON COLUMN app_payroll_stat_info.payrollamount IS '代发金额（万元）';
COMMENT ON COLUMN app_payroll_stat_info.countmom IS '代发人数环比';
COMMENT ON COLUMN app_payroll_stat_info.amountmom IS '代发金额环比';
COMMENT ON COLUMN app_payroll_stat_info.countyoy IS '代发人数同比';
COMMENT ON COLUMN app_payroll_stat_info.amountyoy IS '代发金额同比';
COMMENT ON COLUMN app_payroll_stat_info.inputtime IS '入库时间';
CREATE INDEX idx_payroll_stat_info_customerid ON app_payroll_stat_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_payroll_stat_info_reportno ON app_payroll_stat_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_report_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    reporttitle character varying(128) COLLATE "C",
    checktaskno character varying(64) COLLATE "C",
    reportdate character varying(32) COLLATE "C",
    reportstatus character varying(32) COLLATE "C",
    generatorname character varying(64) COLLATE "C",
    generatetime timestamp without time zone,
    approvestatus character varying(32) COLLATE "C",
    approveopinion text,
    approvetime timestamp without time zone,
    reporturl character varying(256) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_report_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_report_info IS '贷后报告主表';
COMMENT ON COLUMN app_report_info.reportno IS '报告编号（一次贷后报告的记录号）';
COMMENT ON COLUMN app_report_info.customerid IS '客户编号';
COMMENT ON COLUMN app_report_info.customername IS '客户名称';
COMMENT ON COLUMN app_report_info.reporttitle IS '报告标题';
COMMENT ON COLUMN app_report_info.checktaskno IS '日检任务编号';
COMMENT ON COLUMN app_report_info.reportdate IS '报告日期（贷后检查日）';
COMMENT ON COLUMN app_report_info.reportstatus IS '报告状态（生成中/已生成/已审批）';
COMMENT ON COLUMN app_report_info.generatorname IS '生成人';
COMMENT ON COLUMN app_report_info.generatetime IS '生成时间';
COMMENT ON COLUMN app_report_info.approvestatus IS '审批状态（码值：待审批/审批通过/审批驳回（码值待确认））';
COMMENT ON COLUMN app_report_info.approveopinion IS '审批意见';
COMMENT ON COLUMN app_report_info.approvetime IS '审批时间';
COMMENT ON COLUMN app_report_info.reporturl IS '报告链接';
COMMENT ON COLUMN app_report_info.inputtime IS '入库时间';
CREATE UNIQUE INDEX uk_report_no ON app_report_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_reputation_event_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    subjecttype character varying(32) COLLATE "C",
    subjectname character varying(128) COLLATE "C",
    eventtime character varying(32) COLLATE "C",
    eventtype character varying(64) COLLATE "C",
    eventdesc text,
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_reputation_event_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_reputation_event_info IS '舆情事件明细表';
COMMENT ON COLUMN app_reputation_event_info.reportno IS '报告编号';
COMMENT ON COLUMN app_reputation_event_info.customerid IS '客户编号';
COMMENT ON COLUMN app_reputation_event_info.customername IS '客户名称';
COMMENT ON COLUMN app_reputation_event_info.subjecttype IS '主体类型（码值：借款人/股东）';
COMMENT ON COLUMN app_reputation_event_info.subjectname IS '主体名称（借款人名称/股东名称）';
COMMENT ON COLUMN app_reputation_event_info.eventtime IS '舆情发生时间';
COMMENT ON COLUMN app_reputation_event_info.eventtype IS '舆情类型（码值：证券市场违规/股票戴帽/退市风险/评级下调/高管无法履职/财务造假/其他，待确认）';
COMMENT ON COLUMN app_reputation_event_info.eventdesc IS '舆情事件描述';
COMMENT ON COLUMN app_reputation_event_info.inputtime IS '入库时间';
CREATE INDEX idx_reputation_event_info_customerid ON app_reputation_event_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_reputation_event_info_reportno ON app_reputation_event_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_settle_account_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    accountno character varying(64) COLLATE "C",
    accountstatus character varying(64) COLLATE "C",
    accountbalance numeric(18,2),
    frozenamount numeric(18,2),
    yearavgdeposit numeric(18,2),
    superviseflag character varying(64) COLLATE "C",
    propertyincome numeric(18,2),
    propertyincomeyoy numeric(18,2),
    propertyincomesupervised numeric(18,2),
    electricfeeincome numeric(18,2),
    electricfeeyoy numeric(18,2),
    electricfeesupervised numeric(18,2),
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_settle_account_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_settle_account_info IS '结算账户与资产表';
COMMENT ON COLUMN app_settle_account_info.reportno IS '报告编号';
COMMENT ON COLUMN app_settle_account_info.customerid IS '客户编号';
COMMENT ON COLUMN app_settle_account_info.customername IS '客户名称';
COMMENT ON COLUMN app_settle_account_info.accountno IS '账号';
COMMENT ON COLUMN app_settle_account_info.accountstatus IS '账户状态（码值：正常/冻结/销户，码值待确认）';
COMMENT ON COLUMN app_settle_account_info.accountbalance IS '账户余额（万元）';
COMMENT ON COLUMN app_settle_account_info.frozenamount IS '冻结金额（万元）';
COMMENT ON COLUMN app_settle_account_info.yearavgdeposit IS '年日均存款（万元）';
COMMENT ON COLUMN app_settle_account_info.superviseflag IS '监管标识（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_settle_account_info.propertyincome IS '当年物业收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_account_info.propertyincomeyoy IS '当年物业收入累计较上年同期（万元，接口待确认）';
COMMENT ON COLUMN app_settle_account_info.propertyincomesupervised IS '当年监管账户物业收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_account_info.electricfeeincome IS '当年电费收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_account_info.electricfeeyoy IS '当年电费收入累计较上年同期（万元，接口待确认）';
COMMENT ON COLUMN app_settle_account_info.electricfeesupervised IS '当年监管账户当年电费收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_account_info.inputtime IS '入库时间';
CREATE INDEX idx_settle_account_info_customerid ON app_settle_account_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_settle_account_info_reportno ON app_settle_account_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_settle_counterparty_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    counterpartyname character varying(128) COLLATE "C",
    direction character varying(16) COLLATE "C",
    amount numeric(18,2),
    rankno character varying(16) COLLATE "C",
    upstreamflag character varying(32) COLLATE "C",
    remark character varying(512) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_settle_counterparty_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_settle_counterparty_info IS '结算交易对手表';
COMMENT ON COLUMN app_settle_counterparty_info.reportno IS '报告编号';
COMMENT ON COLUMN app_settle_counterparty_info.customerid IS '客户编号';
COMMENT ON COLUMN app_settle_counterparty_info.customername IS '客户名称';
COMMENT ON COLUMN app_settle_counterparty_info.counterpartyname IS '交易对手名称';
COMMENT ON COLUMN app_settle_counterparty_info.direction IS '方向（借方/贷方）';
COMMENT ON COLUMN app_settle_counterparty_info.amount IS '发生额（万元）';
COMMENT ON COLUMN app_settle_counterparty_info.rankno IS '排名（TOP1-10）';
COMMENT ON COLUMN app_settle_counterparty_info.upstreamflag IS '是否前五大上游客户（码值：是/否）';
COMMENT ON COLUMN app_settle_counterparty_info.remark IS '交易备注（预留：备注含担保/借款/投资关键字贷方发生额筛选用，接口待补充）';
COMMENT ON COLUMN app_settle_counterparty_info.inputtime IS '入库时间';
CREATE INDEX idx_settle_counterparty_info_direction ON app_settle_counterparty_info USING ubtree (direction) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_settle_counterparty_info_customerid ON app_settle_counterparty_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_settle_counterparty_info_reportno ON app_settle_counterparty_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_shareholder_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    name character varying(128) COLLATE "C",
    stock_num integer,
    amount numeric(18,2),
    stock_percent numeric(12,4),
    is_quoted character varying(32) COLLATE "C",
    is_state_owned character varying(64) COLLATE "C",
    is_fake_state_owned character varying(32) COLLATE "C",
    is_listed_company character varying(32) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_shareholder_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_shareholder_info IS '工商股东信息表（最新时点快照，字段详细；与信贷系统股东 app_xd_shareholder_info 口径对比）';
COMMENT ON COLUMN app_shareholder_info.reportno IS '报告编号';
COMMENT ON COLUMN app_shareholder_info.customerid IS '客户编号';
COMMENT ON COLUMN app_shareholder_info.customername IS '客户名称';
COMMENT ON COLUMN app_shareholder_info.name IS '股东名称';
COMMENT ON COLUMN app_shareholder_info.stock_num IS '持股数';
COMMENT ON COLUMN app_shareholder_info.amount IS '应出资金额（万元）';
COMMENT ON COLUMN app_shareholder_info.stock_percent IS '持股比例（%）';
COMMENT ON COLUMN app_shareholder_info.is_quoted IS '是否已出资（码值：是/否）';
COMMENT ON COLUMN app_shareholder_info.is_state_owned IS '是否国资股东（码值：是/否）';
COMMENT ON COLUMN app_shareholder_info.is_fake_state_owned IS '股东假冒国企标签（码值：是/否；苏企查/中台按股东主体查询，仅企业股东有值，自然人股东为空）';
COMMENT ON COLUMN app_shareholder_info.is_listed_company IS '股东是否上市公司（码值：是/否，中台按股东主体查询）';
COMMENT ON COLUMN app_shareholder_info.inputtime IS '入库时间';
CREATE INDEX idx_shareholder_info_customerid ON app_shareholder_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_shareholder_info_reportno ON app_shareholder_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_space_config (
    space_id integer DEFAULT nextval('app_space_config_space_id_seq'::regclass) NOT NULL,
    space_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    space_desc character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    relation_account character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    index_space_flag character varying(1) COLLATE "C" DEFAULT 'N'::character varying,
    index_content text,
    default_prompt character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    sort_no integer DEFAULT 0,
    space_status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    upload_flag character varying(1) COLLATE "C" DEFAULT 'N'::character varying,
    input_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    relation_org character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    space_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    finance_upload_flag character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    welcome_content character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    black_icon character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    icon character varying(500) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_space_config IS '应用空间管理表';
COMMENT ON COLUMN app_space_config.space_id IS '空间ID';
COMMENT ON COLUMN app_space_config.space_name IS '空间名称';
COMMENT ON COLUMN app_space_config.space_desc IS '空间说明';
COMMENT ON COLUMN app_space_config.relation_account IS '关联账号';
COMMENT ON COLUMN app_space_config.index_space_flag IS '引导空间标识;Y表示是，N表示否，默认Y';
COMMENT ON COLUMN app_space_config.index_content IS '引导语';
COMMENT ON COLUMN app_space_config.default_prompt IS '兜底文案';
COMMENT ON COLUMN app_space_config.sort_no IS '排序号';
COMMENT ON COLUMN app_space_config.space_status IS '有效状态;Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN app_space_config.upload_flag IS '是否支持上传;Y表示是，N表示否，默认Y';
COMMENT ON COLUMN app_space_config.input_time IS '创建时间';
COMMENT ON COLUMN app_space_config.update_time IS '更新时间';
COMMENT ON COLUMN app_space_config.relation_org IS '关联机构';
COMMENT ON COLUMN app_space_config.space_code IS '空间编码';
COMMENT ON COLUMN app_space_config.finance_upload_flag IS '是否支持财务上传 Y是 N否 默认N';
COMMENT ON COLUMN app_space_config.welcome_content IS '欢迎语';
COMMENT ON COLUMN app_space_config.black_icon IS '有背景色的图标';
COMMENT ON COLUMN app_space_config.icon IS '图标';
ALTER TABLE app_space_config ADD CONSTRAINT app_space_config_pkey PRIMARY KEY USING ubtree  (space_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE app_space_inspiration_config (
    id integer DEFAULT nextval('app_space_inspiration_config_id_seq'::regclass) NOT NULL,
    space_id integer,
    belong_group character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    question character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    sort_no integer DEFAULT 0,
    input_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    question_type character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    entity_type character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    entity_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    index_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    index_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    show_deepseek character varying(10) COLLATE "C" DEFAULT 'N'::character varying,
    hover_flag character varying(100) COLLATE "C" DEFAULT ''::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_space_inspiration_config IS '应用空间灵感配置表';
COMMENT ON COLUMN app_space_inspiration_config.id IS '主键ID';
COMMENT ON COLUMN app_space_inspiration_config.space_id IS '关联空间ID';
COMMENT ON COLUMN app_space_inspiration_config.belong_group IS '所属分组';
COMMENT ON COLUMN app_space_inspiration_config.question IS '灵感问题';
COMMENT ON COLUMN app_space_inspiration_config.status IS '关联状态;Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN app_space_inspiration_config.sort_no IS '排序号';
COMMENT ON COLUMN app_space_inspiration_config.input_time IS '创建时间';
COMMENT ON COLUMN app_space_inspiration_config.update_time IS '更新时间';
COMMENT ON COLUMN app_space_inspiration_config.question_type IS '问题类型';
COMMENT ON COLUMN app_space_inspiration_config.entity_type IS '主体类型';
COMMENT ON COLUMN app_space_inspiration_config.entity_name IS '主体名称';
COMMENT ON COLUMN app_space_inspiration_config.index_code IS '组件编码';
COMMENT ON COLUMN app_space_inspiration_config.index_id IS '组件ID';
COMMENT ON COLUMN app_space_inspiration_config.show_deepseek IS '是否显示deepseek标识:Y | N';
COMMENT ON COLUMN app_space_inspiration_config.hover_flag IS '显示标志: 无, hot,new';
ALTER TABLE app_space_inspiration_config ADD CONSTRAINT app_space_inspiration_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE app_space_relate_account (
    id integer DEFAULT nextval('app_space_relate_account_id_seq'::regclass) NOT NULL,
    account character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    relate_org character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    space_id character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    sort_no integer DEFAULT 0,
    input_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    do_auth_index character varying(2) COLLATE "C" DEFAULT 'Y'::character varying NOT NULL,
    report_text_type character varying(10) COLLATE "C" DEFAULT 'h5'::character varying,
    relate_knowledge character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    relate_menu character varying(2000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_space_relate_account IS '应用空间关联账户信息表';
COMMENT ON COLUMN app_space_relate_account.id IS '主键ID';
COMMENT ON COLUMN app_space_relate_account.account IS '关联账号';
COMMENT ON COLUMN app_space_relate_account.relate_org IS '涉及机构';
COMMENT ON COLUMN app_space_relate_account.space_id IS '关联空间ID';
COMMENT ON COLUMN app_space_relate_account.status IS '关联状态;Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN app_space_relate_account.sort_no IS '排序号';
COMMENT ON COLUMN app_space_relate_account.input_time IS '创建时间';
COMMENT ON COLUMN app_space_relate_account.update_time IS '更新时间';
COMMENT ON COLUMN app_space_relate_account.do_auth_index IS '是否对这个账号进行组件限权';
COMMENT ON COLUMN app_space_relate_account.report_text_type IS '报告文本类型';
COMMENT ON COLUMN app_space_relate_account.relate_knowledge IS '关联知识库';
COMMENT ON COLUMN app_space_relate_account.relate_menu IS '关联菜单';
ALTER TABLE app_space_relate_account ADD CONSTRAINT account UNIQUE USING ubtree (account) WITH (storage_type=USTORE);
ALTER TABLE app_space_relate_account ADD CONSTRAINT app_space_relate_account_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE app_space_relate_agent (
    id integer DEFAULT nextval('app_space_relate_agent_id_seq'::regclass) NOT NULL,
    space_id integer,
    agent_id integer,
    sort_no integer DEFAULT 0,
    status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    input_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_space_relate_agent IS '应用空间关联Agent信息表';
COMMENT ON COLUMN app_space_relate_agent.id IS '主键ID';
COMMENT ON COLUMN app_space_relate_agent.space_id IS '关联空间ID';
COMMENT ON COLUMN app_space_relate_agent.agent_id IS '关联AgentId';
COMMENT ON COLUMN app_space_relate_agent.sort_no IS '排序号';
COMMENT ON COLUMN app_space_relate_agent.status IS '关联状态;Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN app_space_relate_agent.input_time IS '创建时间';
COMMENT ON COLUMN app_space_relate_agent.update_time IS '更新时间';
ALTER TABLE app_space_relate_agent ADD CONSTRAINT app_space_relate_agent_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE app_space_relate_knowledge (
    id integer DEFAULT nextval('app_space_relate_knowledge_id_seq'::regclass) NOT NULL,
    space_id integer,
    label_code_level_1 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_name_level_1 character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    label_code_level_2 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_name_level_2 character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    label_code_level_3 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_name_level_3 character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    label_code_level_4 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_name_level_4 character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    label_dict_code character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    sort_no integer DEFAULT 0,
    input_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_space_relate_knowledge IS '应用空间关联知识库信息表';
COMMENT ON COLUMN app_space_relate_knowledge.id IS '主键ID';
COMMENT ON COLUMN app_space_relate_knowledge.space_id IS '关联空间ID';
COMMENT ON COLUMN app_space_relate_knowledge.label_code_level_1 IS '一级知识库code';
COMMENT ON COLUMN app_space_relate_knowledge.label_name_level_1 IS '一级知识库名称';
COMMENT ON COLUMN app_space_relate_knowledge.label_code_level_2 IS '二级知识库code';
COMMENT ON COLUMN app_space_relate_knowledge.label_name_level_2 IS '一级知识库名称';
COMMENT ON COLUMN app_space_relate_knowledge.label_code_level_3 IS '三级知识库code';
COMMENT ON COLUMN app_space_relate_knowledge.label_name_level_3 IS '一级知识库名称';
COMMENT ON COLUMN app_space_relate_knowledge.label_code_level_4 IS '四级知识库code';
COMMENT ON COLUMN app_space_relate_knowledge.label_name_level_4 IS '一级知识库名称';
COMMENT ON COLUMN app_space_relate_knowledge.label_dict_code IS '知识库字典码值';
COMMENT ON COLUMN app_space_relate_knowledge.status IS '关联状态;Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN app_space_relate_knowledge.sort_no IS '排序号';
COMMENT ON COLUMN app_space_relate_knowledge.input_time IS '创建时间';
COMMENT ON COLUMN app_space_relate_knowledge.update_time IS '更新时间';
ALTER TABLE app_space_relate_knowledge ADD CONSTRAINT app_space_relate_knowledge_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE app_specific_loan_check_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    objectname character varying(64) COLLATE "C",
    productname character varying(128) COLLATE "C",
    productbelongname character varying(128) COLLATE "C",
    contractno character varying(64) COLLATE "C",
    businesssum numeric(18,2),
    balance numeric(18,2),
    duebilltotalbusinesssum numeric(18,2),
    nominalbalancesum numeric(18,2),
    repaysum numeric(18,2),
    purpose character varying(128) COLLATE "C",
    vouchtype character varying(32) COLLATE "C",
    projectbegindate character varying(32) COLLATE "C",
    projectfinishdate character varying(32) COLLATE "C",
    ifbulid character varying(32) COLLATE "C",
    ifconstructionexpect character varying(32) COLLATE "C",
    ifgetpermission character varying(32) COLLATE "C",
    ifmatch character varying(32) COLLATE "C",
    ifopenaccount character varying(32) COLLATE "C",
    ifsign character varying(32) COLLATE "C",
    ifoverinvest character varying(32) COLLATE "C",
    overinvest text,
    ifoperate character varying(32) COLLATE "C",
    ifrunexpect character varying(32) COLLATE "C",
    schedulecheckcondition text,
    lastschedulecheckcondition text,
    capitalcheckcondition text,
    lastcapitalcheckcondition text,
    purchasecheckcondition text,
    lastpurchasecheckcondition text,
    runcheckcondition text,
    lastruncheckcondition text,
    supervisecheckcondition text,
    lastsupervisecheckcondition text,
    capitalfundinvoiced numeric(18,2),
    capitalfunduninvoiced numeric(18,2),
    capitalfundused numeric(18,2),
    loanfundinvoiced numeric(18,2),
    loanfunduninvoiced numeric(18,2),
    loanfundused numeric(18,2),
    otherfundinvoiced numeric(18,2),
    otherfunduninvoiced numeric(18,2),
    otherfundused numeric(18,2),
    totalinvestinvoiced numeric(18,2),
    totalinvestuninvoiced numeric(18,2),
    totalinvestused numeric(18,2),
    explain text,
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_specific_loan_check_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_specific_loan_check_info IS '特定贷款检查表';
COMMENT ON COLUMN app_specific_loan_check_info.reportno IS '报告编号';
COMMENT ON COLUMN app_specific_loan_check_info.customerid IS '客户编号';
COMMENT ON COLUMN app_specific_loan_check_info.customername IS '客户名称';
COMMENT ON COLUMN app_specific_loan_check_info.objectname IS '对象名称（码值：固定资产/房地产开发贷款/经营性物业贷款/厂房通贷款）';
COMMENT ON COLUMN app_specific_loan_check_info.productname IS '基础产品';
COMMENT ON COLUMN app_specific_loan_check_info.productbelongname IS '产品归属';
COMMENT ON COLUMN app_specific_loan_check_info.contractno IS '业务合同编号';
COMMENT ON COLUMN app_specific_loan_check_info.businesssum IS '授信金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.balance IS '用信余额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.duebilltotalbusinesssum IS '用信金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.nominalbalancesum IS '用信敞口余额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.repaysum IS '已还本金（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.purpose IS '用途';
COMMENT ON COLUMN app_specific_loan_check_info.vouchtype IS '担保方式';
COMMENT ON COLUMN app_specific_loan_check_info.projectbegindate IS '项目启动年月';
COMMENT ON COLUMN app_specific_loan_check_info.projectfinishdate IS '（预计）项目完工年月';
COMMENT ON COLUMN app_specific_loan_check_info.ifbulid IS '是否建设期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifconstructionexpect IS '建设期进度是否符合预期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifgetpermission IS '是否取得预售证（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifmatch IS '资金使用是否与项目进度匹配（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifopenaccount IS '是否开立监管账户（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifsign IS '资金监管协议是否已签署（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifoverinvest IS '是否存在超投情况（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.overinvest IS '超投情况说明';
COMMENT ON COLUMN app_specific_loan_check_info.ifoperate IS '是否运营期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifrunexpect IS '运营是否符合预期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.schedulecheckcondition IS '项目建设进度本次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.lastschedulecheckcondition IS '项目建设进度前次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.capitalcheckcondition IS '项目资本金情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.lastcapitalcheckcondition IS '项目资本金情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.purchasecheckcondition IS '建安工程或设备采购支出情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.lastpurchasecheckcondition IS '建安工程或设备采购支出情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.runcheckcondition IS '运营检查本次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.lastruncheckcondition IS '运营检查前次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.supervisecheckcondition IS '资金监管情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.lastsupervisecheckcondition IS '资金监管情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.capitalfundinvoiced IS '资本金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.capitalfunduninvoiced IS '资本金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.capitalfundused IS '资本金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.loanfundinvoiced IS '贷款资金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.loanfunduninvoiced IS '贷款资金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.loanfundused IS '贷款资金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.otherfundinvoiced IS '其他资金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.otherfunduninvoiced IS '其他资金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.otherfundused IS '其他资金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.totalinvestinvoiced IS '总投资已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.totalinvestuninvoiced IS '总投资未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.totalinvestused IS '总投资已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.explain IS '说明';
COMMENT ON COLUMN app_specific_loan_check_info.inputtime IS '入库时间';
CREATE INDEX idx_specific_loan_check_info_customerid ON app_specific_loan_check_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_specific_loan_check_info_reportno ON app_specific_loan_check_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_tax_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    taxperiod character varying(32) COLLATE "C",
    monthlytaxsales numeric(18,2),
    yoychange numeric(18,2),
    yoyrate numeric(12,4),
    totalsalestax numeric(18,2),
    taxreceivable numeric(18,2),
    taxpayable numeric(18,2),
    taxinventory numeric(18,2),
    diffwithreport numeric(18,2),
    diffratewithreport numeric(12,4),
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_tax_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_tax_info IS '纳税数据表（增值税申报销售额，按月一期一行；同期对比/同比由查询层计算，不落表）';
COMMENT ON COLUMN app_tax_info.reportno IS '报告编号';
COMMENT ON COLUMN app_tax_info.customerid IS '客户编号';
COMMENT ON COLUMN app_tax_info.customername IS '客户名称';
COMMENT ON COLUMN app_tax_info.taxperiod IS '纳税期（按月，一期一行，如202603）';
COMMENT ON COLUMN app_tax_info.monthlytaxsales IS '每月增值税申报销售额（万元，预留：当前取数以 totalSalesTax 该期累计为准，本字段暂不使用）';
COMMENT ON COLUMN app_tax_info.yoychange IS '较上年同期变动额（万元）：该期累计−上年同期累计；行级属性各期行自带（如202512行=上年全年vs上上年全年、202603行=本期vs上年同期），默认已有';
COMMENT ON COLUMN app_tax_info.yoyrate IS '较上年同期同比（%）：变动额÷上年同期累计；行级属性各期行自带（同上），默认已有';
COMMENT ON COLUMN app_tax_info.totalsalestax IS '纳税申请总销售额累计（万元）：该纳税期累计数，如202603行=2026年1-3月累计、202512行=2025年全年累计、202503行=2025年1-3月累计；任何期间累计直接从对应 taxPeriod 行取';
COMMENT ON COLUMN app_tax_info.taxreceivable IS '税务申报应收账款（万元，上游直给，供与财报应收对比；无则NULL）';
COMMENT ON COLUMN app_tax_info.taxpayable IS '税务申报应付账款（万元，上游直给，供与财报应付对比；无则NULL）';
COMMENT ON COLUMN app_tax_info.taxinventory IS '税务申报存货（万元，上游直给，供与财报存货对比；无则NULL）';
COMMENT ON COLUMN app_tax_info.diffwithreport IS '与(本部)报表营收相差（万元）：该期累计纳税−该期本部营收；行级属性各期行自带，默认已有';
COMMENT ON COLUMN app_tax_info.diffratewithreport IS '与(本部)报表营收相差幅度（%）：相差额÷该期本部营收；行级属性各期行自带，默认已有';
COMMENT ON COLUMN app_tax_info.inputtime IS '入库时间';
CREATE INDEX idx_tax_info_taxperiod ON app_tax_info USING ubtree (taxperiod) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_tax_info_customerid ON app_tax_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_tax_info_reportno ON app_tax_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE app_xd_shareholder_info (
    id bigint AUTO_INCREMENT NOT NULL,
    reportno character varying(64) COLLATE "C" NOT NULL,
    customerid character varying(64) COLLATE "C",
    customername character varying(128) COLLATE "C",
    name character varying(128) COLLATE "C",
    investmentprop numeric(12,4),
    relationship character varying(128) COLLATE "C",
    currencytype character varying(64) COLLATE "C",
    oughtsum numeric(18,2),
    investmentsum numeric(18,2),
    investdate character varying(64) COLLATE "C",
    inputuserid character varying(64) COLLATE "C",
    inputorgid character varying(64) COLLATE "C",
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT app_xd_shareholder_info_pkey PRIMARY KEY (id)
) AUTO_INCREMENT = 1
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE app_xd_shareholder_info IS '信贷系统股东表（最新时点）';
COMMENT ON COLUMN app_xd_shareholder_info.reportno IS '报告编号';
COMMENT ON COLUMN app_xd_shareholder_info.customerid IS '客户编号';
COMMENT ON COLUMN app_xd_shareholder_info.customername IS '客户名称';
COMMENT ON COLUMN app_xd_shareholder_info.name IS '股东名称';
COMMENT ON COLUMN app_xd_shareholder_info.investmentprop IS '持股比例（%）';
COMMENT ON COLUMN app_xd_shareholder_info.relationship IS '出资方式';
COMMENT ON COLUMN app_xd_shareholder_info.currencytype IS '币种';
COMMENT ON COLUMN app_xd_shareholder_info.oughtsum IS '应出资金额（万元）';
COMMENT ON COLUMN app_xd_shareholder_info.investmentsum IS '实际投资金额（万元）';
COMMENT ON COLUMN app_xd_shareholder_info.investdate IS '投资时间';
COMMENT ON COLUMN app_xd_shareholder_info.inputuserid IS '登记人';
COMMENT ON COLUMN app_xd_shareholder_info.inputorgid IS '登记机构';
COMMENT ON COLUMN app_xd_shareholder_info.inputtime IS '入库时间';
CREATE INDEX idx_xd_shareholder_info_customerid ON app_xd_shareholder_info USING ubtree (customerid) WITH (storage_type=USTORE) TABLESPACE pg_default;
CREATE INDEX idx_xd_shareholder_info_reportno ON app_xd_shareholder_info USING ubtree (reportno) WITH (storage_type=USTORE) TABLESPACE pg_default;

SET search_path = bosz_test;
CREATE TABLE bank_internal_indicators_config (
    id integer DEFAULT nextval('bank_internal_indicators_config_id_seq'::regclass) NOT NULL,
    question_category character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    category character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    sub_category character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    indicator_code text,
    indicator text,
    indicator_show_code text,
    indicator_show text,
    key_word text,
    source_table character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    empty_indicator_method character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    org_account character varying(400) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE bank_internal_indicators_config IS '行内指标配置表';
COMMENT ON COLUMN bank_internal_indicators_config.question_category IS '问题大类';
COMMENT ON COLUMN bank_internal_indicators_config.category IS '指标大类';
COMMENT ON COLUMN bank_internal_indicators_config.sub_category IS '指标小类';
COMMENT ON COLUMN bank_internal_indicators_config.indicator_code IS '指标编码';
COMMENT ON COLUMN bank_internal_indicators_config.indicator IS '指标名称';
COMMENT ON COLUMN bank_internal_indicators_config.indicator_show_code IS '指标编码';
COMMENT ON COLUMN bank_internal_indicators_config.indicator_show IS '展示的指标名称';
COMMENT ON COLUMN bank_internal_indicators_config.key_word IS '问题关键词';
COMMENT ON COLUMN bank_internal_indicators_config.source_table IS '指标表';
COMMENT ON COLUMN bank_internal_indicators_config.empty_indicator_method IS '指标为空的处理方式';
COMMENT ON COLUMN bank_internal_indicators_config.org_account IS '机构账号';
ALTER TABLE bank_internal_indicators_config ADD CONSTRAINT bank_internal_indicators_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE bank_module_info (
    _id bigint DEFAULT nextval('bank_module_info__id_seq'::regclass) NOT NULL,
    bankid character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    modulecode character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    largemodelcode character varying(1000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN bank_module_info._id IS '主键ID';
ALTER TABLE bank_module_info ADD CONSTRAINT bank_module_info_pkey PRIMARY KEY USING ubtree  (_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE batch_prompt_task (
    id character varying(100) COLLATE "C" NOT NULL,
    trace_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    prompt_content text,
    operate_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE batch_prompt_task IS '知识库批量任务表';
COMMENT ON COLUMN batch_prompt_task.trace_id IS '追踪ID';
COMMENT ON COLUMN batch_prompt_task.knowledge_code IS '知识库编码';
COMMENT ON COLUMN batch_prompt_task.prompt_content IS '文案内容';
COMMENT ON COLUMN batch_prompt_task.operate_time IS '操作时间';
COMMENT ON COLUMN batch_prompt_task.ent_name IS '企业名称';
ALTER TABLE batch_prompt_task ADD CONSTRAINT batch_prompt_task_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE call_llm_record (
    hub_account character varying(256) COLLATE "C" NOT NULL,
    trace_id character varying(64) COLLATE "C" NOT NULL,
    sort_no bigint NOT NULL,
    request_time character varying(40) COLLATE "C" NOT NULL,
    status integer,
    content text,
    request_body text,
    response_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    large_model_code character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    api_key character varying(256) COLLATE "C" DEFAULT NULL::character varying,
    prompt_tokens bigint,
    completion_tokens bigint,
    session_msg_no character varying(64) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
ALTER TABLE call_llm_record ADD CONSTRAINT call_llm_record_pkey PRIMARY KEY USING ubtree  (trace_id, sort_no) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ces_field_kongj (
    id character varying(36) COLLATE "C" NOT NULL,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    sex character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    radio character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    checkbox character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    sel_mut character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    sel_search character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    birthday timestamp without time zone,
    pic character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    files character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    remakr text,
    fuwenb text,
    user_sel character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    dep_sel character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    ddd numeric(10,0) DEFAULT NULL::numeric
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN ces_field_kongj.id IS '主键';
COMMENT ON COLUMN ces_field_kongj.create_by IS '创建人';
COMMENT ON COLUMN ces_field_kongj.create_time IS '创建日期';
COMMENT ON COLUMN ces_field_kongj.update_by IS '更新人';
COMMENT ON COLUMN ces_field_kongj.update_time IS '更新日期';
COMMENT ON COLUMN ces_field_kongj.sys_org_code IS '所属部门';
COMMENT ON COLUMN ces_field_kongj.name IS '用户名';
COMMENT ON COLUMN ces_field_kongj.sex IS '下拉框';
COMMENT ON COLUMN ces_field_kongj.radio IS 'radio';
COMMENT ON COLUMN ces_field_kongj.checkbox IS 'checkbox';
COMMENT ON COLUMN ces_field_kongj.sel_mut IS '下拉多选';
COMMENT ON COLUMN ces_field_kongj.sel_search IS '下拉搜索';
COMMENT ON COLUMN ces_field_kongj.birthday IS '时间';
COMMENT ON COLUMN ces_field_kongj.pic IS '图片';
COMMENT ON COLUMN ces_field_kongj.files IS '文件';
COMMENT ON COLUMN ces_field_kongj.remakr IS 'markdown';
COMMENT ON COLUMN ces_field_kongj.fuwenb IS '富文本';
COMMENT ON COLUMN ces_field_kongj.user_sel IS '选择用户';
COMMENT ON COLUMN ces_field_kongj.dep_sel IS '选择部门';
COMMENT ON COLUMN ces_field_kongj.ddd IS 'DD类型';
ALTER TABLE ces_field_kongj ADD CONSTRAINT ces_field_kongj_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ces_order_customer (
    id character varying(36) COLLATE "C" NOT NULL,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    sex character varying(1) COLLATE "C" DEFAULT NULL::character varying,
    birthday timestamp without time zone,
    age integer,
    address character varying(300) COLLATE "C" DEFAULT NULL::character varying,
    order_main_id character varying(32) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN ces_order_customer.create_by IS '创建人';
COMMENT ON COLUMN ces_order_customer.create_time IS '创建日期';
COMMENT ON COLUMN ces_order_customer.update_by IS '更新人';
COMMENT ON COLUMN ces_order_customer.update_time IS '更新日期';
COMMENT ON COLUMN ces_order_customer.sys_org_code IS '所属部门';
COMMENT ON COLUMN ces_order_customer.name IS '客户名字';
COMMENT ON COLUMN ces_order_customer.sex IS '客户性别';
COMMENT ON COLUMN ces_order_customer.birthday IS '客户生日';
COMMENT ON COLUMN ces_order_customer.age IS '年龄';
COMMENT ON COLUMN ces_order_customer.address IS '常用地址';
COMMENT ON COLUMN ces_order_customer.order_main_id IS '订单ID';
ALTER TABLE ces_order_customer ADD CONSTRAINT ces_order_customer_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ces_order_goods (
    id character varying(36) COLLATE "C" NOT NULL,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    good_name character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    price numeric,
    num integer,
    zong_price numeric,
    order_main_id character varying(32) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN ces_order_goods.create_by IS '创建人';
COMMENT ON COLUMN ces_order_goods.create_time IS '创建日期';
COMMENT ON COLUMN ces_order_goods.update_by IS '更新人';
COMMENT ON COLUMN ces_order_goods.update_time IS '更新日期';
COMMENT ON COLUMN ces_order_goods.sys_org_code IS '所属部门';
COMMENT ON COLUMN ces_order_goods.good_name IS '商品名字';
COMMENT ON COLUMN ces_order_goods.price IS '价格';
COMMENT ON COLUMN ces_order_goods.num IS '数量';
COMMENT ON COLUMN ces_order_goods.zong_price IS '单品总价';
COMMENT ON COLUMN ces_order_goods.order_main_id IS '订单ID';
ALTER TABLE ces_order_goods ADD CONSTRAINT ces_order_goods_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ces_order_main (
    id character varying(36) COLLATE "C" NOT NULL,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    order_code character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    xd_date timestamp without time zone,
    money numeric,
    remark character varying(500) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN ces_order_main.create_by IS '创建人';
COMMENT ON COLUMN ces_order_main.create_time IS '创建日期';
COMMENT ON COLUMN ces_order_main.update_by IS '更新人';
COMMENT ON COLUMN ces_order_main.update_time IS '更新日期';
COMMENT ON COLUMN ces_order_main.sys_org_code IS '所属部门';
COMMENT ON COLUMN ces_order_main.order_code IS '订单编码';
COMMENT ON COLUMN ces_order_main.xd_date IS '下单时间';
COMMENT ON COLUMN ces_order_main.money IS '订单总额';
COMMENT ON COLUMN ces_order_main.remark IS '备注';
ALTER TABLE ces_order_main ADD CONSTRAINT ces_order_main_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ces_shop_goods (
    id character varying(36) COLLATE "C" NOT NULL,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    price numeric(10,5) DEFAULT NULL::numeric,
    chuc_date timestamp without time zone,
    contents text,
    good_type_id character varying(32) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN ces_shop_goods.id IS '主键';
COMMENT ON COLUMN ces_shop_goods.create_by IS '创建人';
COMMENT ON COLUMN ces_shop_goods.create_time IS '创建日期';
COMMENT ON COLUMN ces_shop_goods.update_by IS '更新人';
COMMENT ON COLUMN ces_shop_goods.update_time IS '更新日期';
COMMENT ON COLUMN ces_shop_goods.sys_org_code IS '所属部门';
COMMENT ON COLUMN ces_shop_goods.name IS '商品名字';
COMMENT ON COLUMN ces_shop_goods.price IS '价格';
COMMENT ON COLUMN ces_shop_goods.chuc_date IS '出厂时间';
COMMENT ON COLUMN ces_shop_goods.contents IS '商品简介';
COMMENT ON COLUMN ces_shop_goods.good_type_id IS '商品分类';
ALTER TABLE ces_shop_goods ADD CONSTRAINT ces_shop_goods_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ces_shop_type (
    id character varying(36) COLLATE "C" NOT NULL,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    content character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    pics character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    pid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    has_child character varying(3) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN ces_shop_type.create_by IS '创建人';
COMMENT ON COLUMN ces_shop_type.create_time IS '创建日期';
COMMENT ON COLUMN ces_shop_type.update_by IS '更新人';
COMMENT ON COLUMN ces_shop_type.update_time IS '更新日期';
COMMENT ON COLUMN ces_shop_type.sys_org_code IS '所属部门';
COMMENT ON COLUMN ces_shop_type.name IS '分类名字';
COMMENT ON COLUMN ces_shop_type.content IS '描述';
COMMENT ON COLUMN ces_shop_type.pics IS '图片';
COMMENT ON COLUMN ces_shop_type.pid IS '父级节点';
COMMENT ON COLUMN ces_shop_type.has_child IS '是否有子节点';
ALTER TABLE ces_shop_type ADD CONSTRAINT ces_shop_type_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE chat_session_msg_feedback (
    id integer DEFAULT nextval('chat_session_msg_feedback_id_seq'::regclass) NOT NULL,
    user_id character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    client_id character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    session_msg_no character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    grade integer DEFAULT 100 NOT NULL,
    input_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    feedback_text character varying(256) COLLATE "C" DEFAULT ''::character varying NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE chat_session_msg_feedback IS '会话答复评价';
COMMENT ON COLUMN chat_session_msg_feedback.id IS '主键';
COMMENT ON COLUMN chat_session_msg_feedback.user_id IS '用户身份识别码';
COMMENT ON COLUMN chat_session_msg_feedback.client_id IS '项目识别码';
COMMENT ON COLUMN chat_session_msg_feedback.session_msg_no IS '会话问答no';
COMMENT ON COLUMN chat_session_msg_feedback.grade IS '100拇指向上、1拇指向下，11回答错误，12回答模糊，13还可以更好，14答非所问，99自定义；默认值是100';
COMMENT ON COLUMN chat_session_msg_feedback.input_time IS '创建时间';
COMMENT ON COLUMN chat_session_msg_feedback.update_time IS '更新时间';
COMMENT ON COLUMN chat_session_msg_feedback.feedback_text IS '反馈文本';
ALTER TABLE chat_session_msg_feedback ADD CONSTRAINT session_msg_no_unique UNIQUE USING ubtree (session_msg_no) WITH (storage_type=USTORE);
ALTER TABLE chat_session_msg_feedback ADD CONSTRAINT chat_session_msg_feedback_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE client_agent_index_config (
    id integer DEFAULT nextval('client_agent_index_config_id_seq'::regclass) NOT NULL,
    index_name character varying(100) COLLATE "C" NOT NULL,
    index_code character varying(32) COLLATE "C" NOT NULL,
    index_topic character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    use_flag character varying(1) COLLATE "C" DEFAULT 'Y'::character varying NOT NULL,
    synonym_word text,
    key_word text,
    center_key_word text,
    entity_type character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    inner_priority character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    source_type character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    external_priority character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    rec_group character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    rec_question character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    has_index_rela character varying(1) COLLATE "C" DEFAULT NULL::character varying,
    remark text,
    input_time character varying(40) COLLATE "C" NOT NULL,
    update_time character varying(40) COLLATE "C" NOT NULL,
    index_desc text,
    sample_question text,
    object_type character varying(256) COLLATE "C" DEFAULT NULL::character varying,
    index_classification character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    visible_flag character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    index_prompt text,
    hub_account character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    none_test_flag character varying(2) COLLATE "C" DEFAULT '1'::character varying NOT NULL,
    final_result_flag character varying(1) COLLATE "C" DEFAULT 'N'::character varying,
    rec_enterprise character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    text_type character varying(100) COLLATE "C" DEFAULT 'h5'::character varying,
    source_card_channel character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    large_model_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    large_model_content character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    rela_knowledge_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    large_model_flag character varying(1) COLLATE "C" DEFAULT 'Y'::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE client_agent_index_config IS '客户组件配置表';
COMMENT ON COLUMN client_agent_index_config.index_name IS '组件名称';
COMMENT ON COLUMN client_agent_index_config.index_code IS '组件编码';
COMMENT ON COLUMN client_agent_index_config.index_topic IS '组件主题分类';
COMMENT ON COLUMN client_agent_index_config.use_flag IS '是否有效 Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN client_agent_index_config.synonym_word IS '同义词';
COMMENT ON COLUMN client_agent_index_config.key_word IS '关键字';
COMMENT ON COLUMN client_agent_index_config.center_key_word IS '核心关键词';
COMMENT ON COLUMN client_agent_index_config.entity_type IS '主体类型';
COMMENT ON COLUMN client_agent_index_config.inner_priority IS '优先级';
COMMENT ON COLUMN client_agent_index_config.source_type IS '数据来源';
COMMENT ON COLUMN client_agent_index_config.external_priority IS '外部优先级';
COMMENT ON COLUMN client_agent_index_config.rec_group IS '推荐分组';
COMMENT ON COLUMN client_agent_index_config.rec_question IS '推荐问题';
COMMENT ON COLUMN client_agent_index_config.has_index_rela IS '是否有关联组件';
COMMENT ON COLUMN client_agent_index_config.remark IS '备注';
COMMENT ON COLUMN client_agent_index_config.input_time IS '入库时间';
COMMENT ON COLUMN client_agent_index_config.update_time IS '更新时间';
COMMENT ON COLUMN client_agent_index_config.index_desc IS '组件描述';
COMMENT ON COLUMN client_agent_index_config.sample_question IS '实例问题';
COMMENT ON COLUMN client_agent_index_config.object_type IS '企业类型';
COMMENT ON COLUMN client_agent_index_config.index_classification IS '组件分类';
COMMENT ON COLUMN client_agent_index_config.visible_flag IS '是否可见 Y表示是，N表示否，默认Y';
COMMENT ON COLUMN client_agent_index_config.index_prompt IS '组件prompt';
COMMENT ON COLUMN client_agent_index_config.hub_account IS '关联账号';
COMMENT ON COLUMN client_agent_index_config.none_test_flag IS '非测试标志位';
COMMENT ON COLUMN client_agent_index_config.rec_enterprise IS '推荐企业';
COMMENT ON COLUMN client_agent_index_config.text_type IS '文本类型';
COMMENT ON COLUMN client_agent_index_config.source_card_channel IS '朔源卡片展示渠道(pc、app)';
COMMENT ON COLUMN client_agent_index_config.large_model_code IS '大模型编码';
COMMENT ON COLUMN client_agent_index_config.large_model_content IS '不同大模型对应的输出要求';
COMMENT ON COLUMN client_agent_index_config.rela_knowledge_id IS '组件关联知识库ID';
COMMENT ON COLUMN client_agent_index_config.large_model_flag IS '是否走大模型标志，默认Y（ N否，Y是 ）';
ALTER TABLE client_agent_index_config ADD CONSTRAINT client_agent_index_config_un UNIQUE USING ubtree (index_code, source_type, hub_account, none_test_flag) WITH (storage_type=USTORE);
ALTER TABLE client_agent_index_config ADD CONSTRAINT client_agent_index_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE coze_cache_industry_mapping (
    id integer DEFAULT nextval('coze_cache_industry_mapping_id_seq'::regclass) NOT NULL,
    ent_name character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    national_standard_industry character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    model_parsed_industry character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    user_input_industry character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    cached_industry character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    final_output_industry character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    created_at timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    product character varying(800) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE coze_cache_industry_mapping IS '行业映射表';
COMMENT ON COLUMN coze_cache_industry_mapping.id IS '自增主键';
COMMENT ON COLUMN coze_cache_industry_mapping.ent_name IS '企业名称';
COMMENT ON COLUMN coze_cache_industry_mapping.national_standard_industry IS '国标行业';
COMMENT ON COLUMN coze_cache_industry_mapping.model_parsed_industry IS '模型解析行业';
COMMENT ON COLUMN coze_cache_industry_mapping.user_input_industry IS '用户输入行业';
COMMENT ON COLUMN coze_cache_industry_mapping.cached_industry IS '缓存行业';
COMMENT ON COLUMN coze_cache_industry_mapping.final_output_industry IS '最终输出行业';
COMMENT ON COLUMN coze_cache_industry_mapping.created_at IS '插入时间';
COMMENT ON COLUMN coze_cache_industry_mapping.product IS '产品';
ALTER TABLE coze_cache_industry_mapping ADD CONSTRAINT coze_cache_industry_mapping_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE data_entname_indname_reference_records (
    id integer DEFAULT nextval('data_entname_indname_reference_records_id_seq'::regclass) NOT NULL,
    ent_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    ind_name character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE data_entname_indname_reference_records IS '企业行业对照信息表';
COMMENT ON COLUMN data_entname_indname_reference_records.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN data_entname_indname_reference_records.ent_name IS '企业名称';
COMMENT ON COLUMN data_entname_indname_reference_records.ind_name IS '行业名称';
ALTER TABLE data_entname_indname_reference_records ADD CONSTRAINT data_entname_indname_reference_records_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE data_relate_account (
    id integer DEFAULT nextval('data_relate_account_id_seq'::regclass) NOT NULL,
    data_id integer,
    account_id integer,
    relate_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    relate_status character varying(2) COLLATE "C" DEFAULT '1'::character varying,
    is_internal character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    prefix_url character varying(1000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE data_relate_account IS '数据更新关联机构表';
COMMENT ON COLUMN data_relate_account.id IS '主键ID';
COMMENT ON COLUMN data_relate_account.data_id IS '数据ID';
COMMENT ON COLUMN data_relate_account.account_id IS '关联机构ID';
COMMENT ON COLUMN data_relate_account.relate_time IS '关联时间';
COMMENT ON COLUMN data_relate_account.relate_status IS '关联状态;1已关联 2已取消';
COMMENT ON COLUMN data_relate_account.is_internal IS '是否内部使用 Y是 N否';
COMMENT ON COLUMN data_relate_account.prefix_url IS '外部相对路径前缀';
ALTER TABLE data_relate_account ADD CONSTRAINT data_relate_account_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE data_update_config (
    id integer DEFAULT nextval('data_update_config_id_seq'::regclass) NOT NULL,
    title character varying(100) COLLATE "C" NOT NULL,
    parent_id integer,
    parent_title character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    user_evaluation text,
    app_channel character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    app_type character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    use_status character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    sort_no integer,
    content_text text,
    input_time character varying(40) COLLATE "C" NOT NULL,
    update_time character varying(40) COLLATE "C" NOT NULL,
    sort_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    remark text,
    is_public character varying(2) COLLATE "C" DEFAULT 'N'::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE data_update_config IS '数据更新配置表';
COMMENT ON COLUMN data_update_config.id IS '主键ID';
COMMENT ON COLUMN data_update_config.title IS '标题名称';
COMMENT ON COLUMN data_update_config.parent_id IS '父标题ID';
COMMENT ON COLUMN data_update_config.parent_title IS '父标题名称';
COMMENT ON COLUMN data_update_config.user_evaluation IS '用户评价';
COMMENT ON COLUMN data_update_config.app_channel IS '应用渠道';
COMMENT ON COLUMN data_update_config.app_type IS '应用类型';
COMMENT ON COLUMN data_update_config.use_status IS '使用状态;N 未上线 Y 已上线';
COMMENT ON COLUMN data_update_config.sort_no IS '排序';
COMMENT ON COLUMN data_update_config.content_text IS '内容文本';
COMMENT ON COLUMN data_update_config.input_time IS '创建时间';
COMMENT ON COLUMN data_update_config.update_time IS '更新时间';
COMMENT ON COLUMN data_update_config.sort_time IS '排序时间';
COMMENT ON COLUMN data_update_config.remark IS '备注';
COMMENT ON COLUMN data_update_config.is_public IS '是否公开 N否 Y是';
ALTER TABLE data_update_config ADD CONSTRAINT data_update_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE demo_field_def_val_main (
    id character varying(36) COLLATE "C" NOT NULL,
    code character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    sex character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    address character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    address_param character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN demo_field_def_val_main.code IS '编码';
COMMENT ON COLUMN demo_field_def_val_main.name IS '姓名';
COMMENT ON COLUMN demo_field_def_val_main.sex IS '性别';
COMMENT ON COLUMN demo_field_def_val_main.address IS '地址';
COMMENT ON COLUMN demo_field_def_val_main.address_param IS '地址（传参）';
COMMENT ON COLUMN demo_field_def_val_main.create_by IS '创建人';
COMMENT ON COLUMN demo_field_def_val_main.create_time IS '创建日期';
COMMENT ON COLUMN demo_field_def_val_main.update_by IS '更新人';
COMMENT ON COLUMN demo_field_def_val_main.update_time IS '更新日期';
COMMENT ON COLUMN demo_field_def_val_main.sys_org_code IS '所属部门';
ALTER TABLE demo_field_def_val_main ADD CONSTRAINT demo_field_def_val_main_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE demo_field_def_val_sub (
    id character varying(36) COLLATE "C" NOT NULL,
    code character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    "date" character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    main_id character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN demo_field_def_val_sub.code IS '编码';
COMMENT ON COLUMN demo_field_def_val_sub.name IS '名称';
COMMENT ON COLUMN demo_field_def_val_sub."date" IS '日期';
COMMENT ON COLUMN demo_field_def_val_sub.main_id IS '主表ID';
COMMENT ON COLUMN demo_field_def_val_sub.create_by IS '创建人';
COMMENT ON COLUMN demo_field_def_val_sub.create_time IS '创建日期';
COMMENT ON COLUMN demo_field_def_val_sub.update_by IS '更新人';
COMMENT ON COLUMN demo_field_def_val_sub.update_time IS '更新日期';
COMMENT ON COLUMN demo_field_def_val_sub.sys_org_code IS '所属部门';
ALTER TABLE demo_field_def_val_sub ADD CONSTRAINT demo_field_def_val_sub_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ent_rel_shortname_info (
    id integer DEFAULT nextval('ent_rel_shortname_info_id_seq'::regclass) NOT NULL,
    ent_rel_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    dw_ins_date timestamp without time zone DEFAULT pg_systimestamp(),
    status character varying(10) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE ent_rel_shortname_info IS '人工维护企业简称表';
COMMENT ON COLUMN ent_rel_shortname_info.id IS '主键';
COMMENT ON COLUMN ent_rel_shortname_info.ent_rel_name IS '企业简称';
COMMENT ON COLUMN ent_rel_shortname_info.ent_name IS '企业全称';
COMMENT ON COLUMN ent_rel_shortname_info.status IS '数据状态';
ALTER TABLE ent_rel_shortname_info ADD CONSTRAINT ent_rel_shortname_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ent_srd_task (
    task_id character varying(45) COLLATE "C" NOT NULL,
    file_name character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    user_uuid character varying(200) COLLATE "C" NOT NULL,
    ent_count integer DEFAULT 0,
    parse_status character varying(40) COLLATE "C" DEFAULT '初始化'::character varying NOT NULL,
    parsing_percentage integer DEFAULT 0,
    task_from_stage smallint NOT NULL,
    task_status character varying(40) COLLATE "C" DEFAULT '初始化'::character varying NOT NULL,
    screening_failed_count integer DEFAULT 0,
    input_time character varying(24) COLLATE "C" NOT NULL,
    update_time character varying(24) COLLATE "C" NOT NULL,
    screening_success_count integer
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE ent_srd_task IS '企业名单任务表';
COMMENT ON COLUMN ent_srd_task.task_id IS '任务编号';
COMMENT ON COLUMN ent_srd_task.file_name IS '文件名称';
COMMENT ON COLUMN ent_srd_task.user_uuid IS '用户标识';
COMMENT ON COLUMN ent_srd_task.ent_count IS '解析出来的去重完的企业个数';
COMMENT ON COLUMN ent_srd_task.parse_status IS '解析状态:初始化, 解析中, 解析完成';
COMMENT ON COLUMN ent_srd_task.parsing_percentage IS '解析百分比:0-100';
COMMENT ON COLUMN ent_srd_task.task_from_stage IS '任务发起的阶段（0:筛查，1:推荐，2:尽调）';
COMMENT ON COLUMN ent_srd_task.task_status IS '任务状态:初始化,筛查中,筛查完成,筛查完成待推荐,推荐中,推荐完成';
COMMENT ON COLUMN ent_srd_task.screening_failed_count IS '筛查失败企业个数';
COMMENT ON COLUMN ent_srd_task.input_time IS '插入时间';
COMMENT ON COLUMN ent_srd_task.update_time IS '更新时间';
COMMENT ON COLUMN ent_srd_task.screening_success_count IS '筛查成功个数';
ALTER TABLE ent_srd_task ADD CONSTRAINT ent_srd_task_pkey PRIMARY KEY USING ubtree  (task_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ext_intf_manage (
    id character varying(32) COLLATE "C" NOT NULL,
    supplier_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intf_no character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intf_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    intf_path character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    intf_type_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    intf_request_type character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    intf_time_out integer DEFAULT 0,
    intf_status character varying(2) COLLATE "C" DEFAULT '1'::character varying,
    intf_desc character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    refer_intf_no character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    refer_intf_status character varying(2) COLLATE "C" DEFAULT '1'::character varying,
    async_save character varying(2) COLLATE "C" DEFAULT '0'::character varying,
    battle_flag character varying(2) COLLATE "C" DEFAULT '0'::character varying,
    battle_report_content character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    before_handler character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_user_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_user_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_user_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    update_user_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    intf_structure text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE ext_intf_manage IS '外部接口详细配置表';
COMMENT ON COLUMN ext_intf_manage.id IS '主键';
COMMENT ON COLUMN ext_intf_manage.supplier_id IS '服务编号';
COMMENT ON COLUMN ext_intf_manage.intf_no IS '接口编号';
COMMENT ON COLUMN ext_intf_manage.intf_name IS '接口名称';
COMMENT ON COLUMN ext_intf_manage.intf_path IS '接口请求地址';
COMMENT ON COLUMN ext_intf_manage.intf_type_name IS '接入形式';
COMMENT ON COLUMN ext_intf_manage.intf_request_type IS '请求方式';
COMMENT ON COLUMN ext_intf_manage.intf_time_out IS '请求超时时间，单位为秒';
COMMENT ON COLUMN ext_intf_manage.intf_status IS '接口状态 0 无效 1 有效';
COMMENT ON COLUMN ext_intf_manage.intf_desc IS '接口描述';
COMMENT ON COLUMN ext_intf_manage.refer_intf_no IS '依赖接口编号';
COMMENT ON COLUMN ext_intf_manage.refer_intf_status IS '依赖接口状态 0 无效 1 有效';
COMMENT ON COLUMN ext_intf_manage.async_save IS '是否异步存储 0 否 1是';
COMMENT ON COLUMN ext_intf_manage.battle_flag IS '是否为挡板数据 0 否 1是';
COMMENT ON COLUMN ext_intf_manage.battle_report_content IS '挡板报文';
COMMENT ON COLUMN ext_intf_manage.before_handler IS '输出报文处理-加密/转码';
COMMENT ON COLUMN ext_intf_manage.input_user_id IS '创建人id';
COMMENT ON COLUMN ext_intf_manage.input_user_name IS '创建人名称';
COMMENT ON COLUMN ext_intf_manage.input_time IS '创建时间';
COMMENT ON COLUMN ext_intf_manage.update_user_id IS '更新人id';
COMMENT ON COLUMN ext_intf_manage.update_user_name IS '更新人名称';
COMMENT ON COLUMN ext_intf_manage.update_time IS '更新时间';
ALTER TABLE ext_intf_manage ADD CONSTRAINT ext_intf_manage_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ext_intf_param_define (
    id character varying(32) COLLATE "C" NOT NULL,
    supplier_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    param_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    param_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    param_value character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    input_user_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_user_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_user_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    update_user_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    param_position character varying(10) COLLATE "C" DEFAULT '1'::character varying,
    param_is_required character varying(2) COLLATE "C" DEFAULT '0'::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE ext_intf_param_define IS '外部服务公共参数定义表';
COMMENT ON COLUMN ext_intf_param_define.id IS '主键';
COMMENT ON COLUMN ext_intf_param_define.supplier_id IS '服务编号';
COMMENT ON COLUMN ext_intf_param_define.param_code IS '参数名称';
COMMENT ON COLUMN ext_intf_param_define.param_type IS '参数类型';
COMMENT ON COLUMN ext_intf_param_define.param_value IS '参数值';
COMMENT ON COLUMN ext_intf_param_define.input_user_id IS '创建人id';
COMMENT ON COLUMN ext_intf_param_define.input_user_name IS '创建人名称';
COMMENT ON COLUMN ext_intf_param_define.input_time IS '创建时间';
COMMENT ON COLUMN ext_intf_param_define.update_user_id IS '更新人id';
COMMENT ON COLUMN ext_intf_param_define.update_user_name IS '更新人名称';
COMMENT ON COLUMN ext_intf_param_define.update_time IS '更新时间';
COMMENT ON COLUMN ext_intf_param_define.param_position IS '参数使用位置 1-报文体 2-报文头 3-URL 4-PATH';
COMMENT ON COLUMN ext_intf_param_define.param_is_required IS '参数是否必输（0否1是）';
ALTER TABLE ext_intf_param_define ADD CONSTRAINT ext_intf_param_define_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ext_intf_param_manage (
    id character varying(32) COLLATE "C" NOT NULL,
    supplier_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intf_no character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    param_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    param_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    param_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    param_is_required character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    param_position character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    param_source character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    param_value character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    input_user_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_user_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_user_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    update_user_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    source_type_detail character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    source_param_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    source_param_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    child_param_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    child_param_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    child_param_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    source_field_dict_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    source_field character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    source_field_name character varying(100) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE ext_intf_param_manage IS '外部接口参数配置表';
COMMENT ON COLUMN ext_intf_param_manage.id IS '主键';
COMMENT ON COLUMN ext_intf_param_manage.supplier_id IS '服务编号';
COMMENT ON COLUMN ext_intf_param_manage.intf_no IS '接口编号';
COMMENT ON COLUMN ext_intf_param_manage.param_code IS '参数名称';
COMMENT ON COLUMN ext_intf_param_manage.param_name IS '参数中文名称';
COMMENT ON COLUMN ext_intf_param_manage.param_type IS '参数类型';
COMMENT ON COLUMN ext_intf_param_manage.param_is_required IS '参数是否必输（0否1是）';
COMMENT ON COLUMN ext_intf_param_manage.param_position IS '参数使用位置 1-报文体 2-报文头 3-URL 4-PATH';
COMMENT ON COLUMN ext_intf_param_manage.param_source IS '参数取值来源';
COMMENT ON COLUMN ext_intf_param_manage.param_value IS '参数值';
COMMENT ON COLUMN ext_intf_param_manage.input_user_id IS '创建人id';
COMMENT ON COLUMN ext_intf_param_manage.input_user_name IS '创建人名称';
COMMENT ON COLUMN ext_intf_param_manage.input_time IS '创建时间';
COMMENT ON COLUMN ext_intf_param_manage.update_user_id IS '更新人id';
COMMENT ON COLUMN ext_intf_param_manage.update_user_name IS '更新人名称';
COMMENT ON COLUMN ext_intf_param_manage.update_time IS '更新时间';
COMMENT ON COLUMN ext_intf_param_manage.source_type_detail IS '细类类型';
COMMENT ON COLUMN ext_intf_param_manage.source_param_code IS '关联参数编码';
COMMENT ON COLUMN ext_intf_param_manage.source_param_type IS '关联查询字段类型1 字符串 2 整型 3 布尔类型 4 对象 5 列表';
COMMENT ON COLUMN ext_intf_param_manage.child_param_code IS '子参数名称';
COMMENT ON COLUMN ext_intf_param_manage.child_param_name IS '子参数名称';
COMMENT ON COLUMN ext_intf_param_manage.child_param_type IS '子参数类型1 字符串 2 整型 3 布尔类型 4 对象 5 列表';
COMMENT ON COLUMN ext_intf_param_manage.source_field_dict_id IS '关联细类字段字典ID';
COMMENT ON COLUMN ext_intf_param_manage.source_field IS '关联细类字段';
COMMENT ON COLUMN ext_intf_param_manage.source_field_name IS '关联细类字段名称';
ALTER TABLE ext_intf_param_manage ADD CONSTRAINT ext_intf_param_manage_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ext_intf_supplier_manage (
    supplier_id character varying(100) COLLATE "C" NOT NULL,
    supplier_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    intf_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    intf_path character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    input_user_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_user_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_user_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    update_user_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE ext_intf_supplier_manage IS '外部服务配置表';
COMMENT ON COLUMN ext_intf_supplier_manage.supplier_id IS '服务编号';
COMMENT ON COLUMN ext_intf_supplier_manage.supplier_name IS '服务名称';
COMMENT ON COLUMN ext_intf_supplier_manage.intf_type IS '接入形式';
COMMENT ON COLUMN ext_intf_supplier_manage.intf_path IS '接入地址';
COMMENT ON COLUMN ext_intf_supplier_manage.status IS '状态（0失效 1 有效）';
COMMENT ON COLUMN ext_intf_supplier_manage.input_user_id IS '创建人id';
COMMENT ON COLUMN ext_intf_supplier_manage.input_user_name IS '创建人名称';
COMMENT ON COLUMN ext_intf_supplier_manage.input_time IS '创建时间';
COMMENT ON COLUMN ext_intf_supplier_manage.update_user_id IS '更新人id';
COMMENT ON COLUMN ext_intf_supplier_manage.update_user_name IS '更新人名称';
COMMENT ON COLUMN ext_intf_supplier_manage.update_time IS '更新时间';
ALTER TABLE ext_intf_supplier_manage ADD CONSTRAINT ext_intf_supplier_manage_pkey PRIMARY KEY USING ubtree  (supplier_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE financial_abnormal_transaction_info (
    id character varying(32) COLLATE "C" NOT NULL,
    uuid character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    batch_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    task_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    account_no character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_name character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    amount character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    abnormal_type character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    year_month_str character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    trade_date character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    transfer_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    trade_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    trans_type character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE financial_abnormal_transaction_info IS '客户金融异常交易信息表';
COMMENT ON COLUMN financial_abnormal_transaction_info.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN financial_abnormal_transaction_info.uuid IS 'uuid';
COMMENT ON COLUMN financial_abnormal_transaction_info.batch_id IS '批次ID';
COMMENT ON COLUMN financial_abnormal_transaction_info.task_id IS '任务ID';
COMMENT ON COLUMN financial_abnormal_transaction_info.ent_name IS '企业名称';
COMMENT ON COLUMN financial_abnormal_transaction_info.account_no IS '对方账户';
COMMENT ON COLUMN financial_abnormal_transaction_info.label_name IS '流水分类';
COMMENT ON COLUMN financial_abnormal_transaction_info.amount IS '交易金额';
COMMENT ON COLUMN financial_abnormal_transaction_info.abnormal_type IS '异常交易风险点';
COMMENT ON COLUMN financial_abnormal_transaction_info.year_month_str IS '年月';
COMMENT ON COLUMN financial_abnormal_transaction_info.trade_date IS '交易日期';
COMMENT ON COLUMN financial_abnormal_transaction_info.transfer_name IS '对手方名称';
COMMENT ON COLUMN financial_abnormal_transaction_info.trade_time IS '交易时间';
COMMENT ON COLUMN financial_abnormal_transaction_info.trans_type IS '摘要';
COMMENT ON COLUMN financial_abnormal_transaction_info.create_time IS '创建时间';
COMMENT ON COLUMN financial_abnormal_transaction_info.update_time IS '更新时间';
ALTER TABLE financial_abnormal_transaction_info ADD CONSTRAINT financial_abnormal_transaction_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE financial_batch_task_records (
    id character varying(32) COLLATE "C" NOT NULL,
    uuid character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    batch_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    task_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(20) COLLATE "C" DEFAULT 'init'::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE financial_batch_task_records IS '批次任务记录表';
COMMENT ON COLUMN financial_batch_task_records.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN financial_batch_task_records.uuid IS 'uuid';
COMMENT ON COLUMN financial_batch_task_records.batch_id IS '批次ID';
COMMENT ON COLUMN financial_batch_task_records.task_id IS '任务ID';
COMMENT ON COLUMN financial_batch_task_records.status IS '任务状态 init 待处理 processing 处理中 finished 已完成 failed 失败';
COMMENT ON COLUMN financial_batch_task_records.create_time IS '关联关系创建时间';
COMMENT ON COLUMN financial_batch_task_records.update_time IS '关联关系更新时间';
ALTER TABLE financial_batch_task_records ADD CONSTRAINT financial_batch_task_records_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE financial_core_income_expenditure_info (
    id character varying(32) COLLATE "C" NOT NULL,
    uuid character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    batch_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    task_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_name character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    proportion numeric(18,2) DEFAULT NULL::numeric,
    trade_amount_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    trade_num integer,
    avg_trade_amount_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    merge_trans character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    business_proportion numeric(18,2) DEFAULT NULL::numeric,
    business_trade_amount numeric(18,2) DEFAULT NULL::numeric,
    transfer_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    business_proportion_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    trade_amount numeric(18,2) DEFAULT NULL::numeric,
    avg_trade_amount numeric(18,2) DEFAULT NULL::numeric,
    trans_business_trade_amount numeric(18,2) DEFAULT NULL::numeric,
    proportion_format character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE financial_core_income_expenditure_info IS '客户金融核心收支信息表';
COMMENT ON COLUMN financial_core_income_expenditure_info.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN financial_core_income_expenditure_info.uuid IS 'uuid';
COMMENT ON COLUMN financial_core_income_expenditure_info.batch_id IS '批次ID';
COMMENT ON COLUMN financial_core_income_expenditure_info.task_id IS '任务ID';
COMMENT ON COLUMN financial_core_income_expenditure_info.ent_name IS '企业名称';
COMMENT ON COLUMN financial_core_income_expenditure_info.label_name IS '收支类型 1 收入 2 支出';
COMMENT ON COLUMN financial_core_income_expenditure_info.proportion IS '占比';
COMMENT ON COLUMN financial_core_income_expenditure_info.trade_amount_format IS '金额总额（收入、支出）';
COMMENT ON COLUMN financial_core_income_expenditure_info.trade_num IS '交易笔数';
COMMENT ON COLUMN financial_core_income_expenditure_info.avg_trade_amount_format IS '单笔平均交易金额';
COMMENT ON COLUMN financial_core_income_expenditure_info.merge_trans IS '是否合并对方户名 true 是 false 否';
COMMENT ON COLUMN financial_core_income_expenditure_info.business_proportion IS '经营性占比';
COMMENT ON COLUMN financial_core_income_expenditure_info.business_trade_amount IS '经营性总额（收入、支出）';
COMMENT ON COLUMN financial_core_income_expenditure_info.transfer_name IS '交易名称';
COMMENT ON COLUMN financial_core_income_expenditure_info.business_proportion_format IS '经营性占比';
COMMENT ON COLUMN financial_core_income_expenditure_info.trade_amount IS '金额总额（收入、支出）';
COMMENT ON COLUMN financial_core_income_expenditure_info.avg_trade_amount IS '单笔平均交易金额';
COMMENT ON COLUMN financial_core_income_expenditure_info.trans_business_trade_amount IS '经营性总额（收入、支出）';
COMMENT ON COLUMN financial_core_income_expenditure_info.proportion_format IS '总收入占比';
COMMENT ON COLUMN financial_core_income_expenditure_info.create_time IS '创建时间';
COMMENT ON COLUMN financial_core_income_expenditure_info.update_time IS '更新时间';
ALTER TABLE financial_core_income_expenditure_info ADD CONSTRAINT financial_core_income_expenditure_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE financial_counterparty_info (
    id character varying(32) COLLATE "C" NOT NULL,
    uuid character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    batch_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    task_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    transfer_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    amount_list text,
    income_format character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    expenditure numeric(18,2) DEFAULT NULL::numeric,
    income numeric(18,2) DEFAULT NULL::numeric,
    expenditure_format character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    diff_amount character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE financial_counterparty_info IS '客户金融直接关联方对手信息表';
COMMENT ON COLUMN financial_counterparty_info.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN financial_counterparty_info.uuid IS 'uuid';
COMMENT ON COLUMN financial_counterparty_info.batch_id IS '批次ID';
COMMENT ON COLUMN financial_counterparty_info.task_id IS '任务ID';
COMMENT ON COLUMN financial_counterparty_info.ent_name IS '企业名称';
COMMENT ON COLUMN financial_counterparty_info.name IS '账号';
COMMENT ON COLUMN financial_counterparty_info.transfer_name IS '直接关联方（对方户名）';
COMMENT ON COLUMN financial_counterparty_info.amount_list IS '流入流出金额';
COMMENT ON COLUMN financial_counterparty_info.income_format IS '流入总额';
COMMENT ON COLUMN financial_counterparty_info.expenditure IS '支出金额';
COMMENT ON COLUMN financial_counterparty_info.income IS '收入金额';
COMMENT ON COLUMN financial_counterparty_info.expenditure_format IS '流出总额';
COMMENT ON COLUMN financial_counterparty_info.diff_amount IS '交易差额';
COMMENT ON COLUMN financial_counterparty_info.create_time IS '创建时间';
COMMENT ON COLUMN financial_counterparty_info.update_time IS '更新时间';
ALTER TABLE financial_counterparty_info ADD CONSTRAINT financial_counterparty_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE financial_direct_relation_info (
    id character varying(32) COLLATE "C" NOT NULL,
    uuid character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    batch_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    task_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    income_format character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    expenditure numeric(18,2) DEFAULT NULL::numeric,
    income numeric(18,2) DEFAULT NULL::numeric,
    expenditure_format character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    diff_amount character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE financial_direct_relation_info IS '客户金融直接关联方信息表';
COMMENT ON COLUMN financial_direct_relation_info.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN financial_direct_relation_info.uuid IS 'uuid';
COMMENT ON COLUMN financial_direct_relation_info.batch_id IS '批次ID';
COMMENT ON COLUMN financial_direct_relation_info.task_id IS '任务ID';
COMMENT ON COLUMN financial_direct_relation_info.ent_name IS '企业名称';
COMMENT ON COLUMN financial_direct_relation_info.income_format IS '流入总额';
COMMENT ON COLUMN financial_direct_relation_info.expenditure IS '支出金额';
COMMENT ON COLUMN financial_direct_relation_info.income IS '收入金额';
COMMENT ON COLUMN financial_direct_relation_info.expenditure_format IS '流出总额';
COMMENT ON COLUMN financial_direct_relation_info.diff_amount IS '交易差额';
COMMENT ON COLUMN financial_direct_relation_info.create_time IS '创建时间';
COMMENT ON COLUMN financial_direct_relation_info.update_time IS '更新时间';
ALTER TABLE financial_direct_relation_info ADD CONSTRAINT financial_direct_relation_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE financial_focus_counterparty_info (
    id character varying(32) COLLATE "C" NOT NULL,
    uuid character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    batch_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    task_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    transfer_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    income_amount numeric(18,2) DEFAULT NULL::numeric,
    income_trade_amount character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    income_ratio character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    expend_amount numeric(18,2) DEFAULT NULL::numeric,
    expend_trade_amount character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    expend_ratio character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    follow_rule character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE financial_focus_counterparty_info IS '客户金融需关注对手方信息表';
COMMENT ON COLUMN financial_focus_counterparty_info.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN financial_focus_counterparty_info.uuid IS 'uuid';
COMMENT ON COLUMN financial_focus_counterparty_info.batch_id IS '批次ID';
COMMENT ON COLUMN financial_focus_counterparty_info.task_id IS '任务ID';
COMMENT ON COLUMN financial_focus_counterparty_info.ent_name IS '企业名称';
COMMENT ON COLUMN financial_focus_counterparty_info.transfer_name IS '需关注对手方名称';
COMMENT ON COLUMN financial_focus_counterparty_info.income_amount IS '流入总额';
COMMENT ON COLUMN financial_focus_counterparty_info.income_trade_amount IS '流入总额-格式化';
COMMENT ON COLUMN financial_focus_counterparty_info.income_ratio IS '流入占比';
COMMENT ON COLUMN financial_focus_counterparty_info.expend_amount IS '支出总额';
COMMENT ON COLUMN financial_focus_counterparty_info.expend_trade_amount IS '支出总额-格式化';
COMMENT ON COLUMN financial_focus_counterparty_info.expend_ratio IS '支出占比';
COMMENT ON COLUMN financial_focus_counterparty_info.follow_rule IS '关注类型';
COMMENT ON COLUMN financial_focus_counterparty_info.create_time IS '创建时间';
COMMENT ON COLUMN financial_focus_counterparty_info.update_time IS '更新时间';
ALTER TABLE financial_focus_counterparty_info ADD CONSTRAINT financial_focus_counterparty_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE financial_main_info (
    id character varying(32) COLLATE "C" NOT NULL,
    uuid character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    batch_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    task_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    cash_flow_total_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    balance_day_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    profit_loss_total_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    income_total_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    expenditure_total_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE financial_main_info IS '客户金融主体信息表';
COMMENT ON COLUMN financial_main_info.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN financial_main_info.uuid IS 'uuid';
COMMENT ON COLUMN financial_main_info.batch_id IS '批次ID';
COMMENT ON COLUMN financial_main_info.task_id IS '任务ID';
COMMENT ON COLUMN financial_main_info.ent_name IS '企业名称';
COMMENT ON COLUMN financial_main_info.cash_flow_total_format IS '净现金流(格式化金额)';
COMMENT ON COLUMN financial_main_info.balance_day_format IS '日均余额';
COMMENT ON COLUMN financial_main_info.profit_loss_total_format IS '净收入总额(格式化金额)';
COMMENT ON COLUMN financial_main_info.income_total_format IS '收入总额';
COMMENT ON COLUMN financial_main_info.expenditure_total_format IS '支出总额';
COMMENT ON COLUMN financial_main_info.create_time IS '创建时间';
COMMENT ON COLUMN financial_main_info.update_time IS '更新时间';
ALTER TABLE financial_main_info ADD CONSTRAINT financial_main_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE financial_profit_loss_info (
    id character varying(32) COLLATE "C" NOT NULL,
    uuid character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    batch_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    task_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_name character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    profit_loss_total numeric(18,2) DEFAULT NULL::numeric,
    profit_loss_total_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    income_total numeric(18,2) DEFAULT NULL::numeric,
    income_total_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    average_monthly_income numeric(18,2) DEFAULT NULL::numeric,
    average_monthly_income_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    average_monthly_expenditure numeric(18,2) DEFAULT NULL::numeric,
    average_monthly_expenditure_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    year_income numeric(18,2) DEFAULT NULL::numeric,
    year_income_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    year_expenditure numeric(18,2) DEFAULT NULL::numeric,
    year_expenditure_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    expenditure_total numeric(18,2) DEFAULT NULL::numeric,
    expenditure_total_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    average_monthly_profit_loss numeric(18,2) DEFAULT NULL::numeric,
    average_monthly_profit_loss_format character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE financial_profit_loss_info IS '客户金融收支盈亏信息表';
COMMENT ON COLUMN financial_profit_loss_info.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN financial_profit_loss_info.uuid IS 'uuid';
COMMENT ON COLUMN financial_profit_loss_info.batch_id IS '批次ID';
COMMENT ON COLUMN financial_profit_loss_info.task_id IS '任务ID';
COMMENT ON COLUMN financial_profit_loss_info.ent_name IS '企业名称';
COMMENT ON COLUMN financial_profit_loss_info.label_name IS '收支类型 1 收入 2 支出';
COMMENT ON COLUMN financial_profit_loss_info.profit_loss_total IS '净利润';
COMMENT ON COLUMN financial_profit_loss_info.profit_loss_total_format IS '净现金流盈亏格式化';
COMMENT ON COLUMN financial_profit_loss_info.income_total IS '收入总额';
COMMENT ON COLUMN financial_profit_loss_info.income_total_format IS '收入总额格式化';
COMMENT ON COLUMN financial_profit_loss_info.average_monthly_income IS '月均收入';
COMMENT ON COLUMN financial_profit_loss_info.average_monthly_income_format IS '月均收入格式化';
COMMENT ON COLUMN financial_profit_loss_info.average_monthly_expenditure IS '月均支出';
COMMENT ON COLUMN financial_profit_loss_info.average_monthly_expenditure_format IS '月均支出格式化';
COMMENT ON COLUMN financial_profit_loss_info.year_income IS '年流入';
COMMENT ON COLUMN financial_profit_loss_info.year_income_format IS '年流入格式化';
COMMENT ON COLUMN financial_profit_loss_info.year_expenditure IS '年流出';
COMMENT ON COLUMN financial_profit_loss_info.year_expenditure_format IS '年流出格式化';
COMMENT ON COLUMN financial_profit_loss_info.expenditure_total IS '支出总额';
COMMENT ON COLUMN financial_profit_loss_info.expenditure_total_format IS '支出总额格式化';
COMMENT ON COLUMN financial_profit_loss_info.average_monthly_profit_loss IS '月均盈亏金额';
COMMENT ON COLUMN financial_profit_loss_info.average_monthly_profit_loss_format IS '月均盈亏金额格式化';
COMMENT ON COLUMN financial_profit_loss_info.create_time IS '创建时间';
COMMENT ON COLUMN financial_profit_loss_info.update_time IS '更新时间';
ALTER TABLE financial_profit_loss_info ADD CONSTRAINT financial_profit_loss_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE financial_transaction_records (
    _id bigint DEFAULT nextval('financial_transaction_records__id_seq'::regclass) NOT NULL,
    id character varying(64) COLLATE "C" NOT NULL,
    line_id character varying(32) COLLATE "C" NOT NULL,
    uuid character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    batch_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    task_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    page integer,
    "row" integer,
    trade_date character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    trade_date_local character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    trade_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    account_no character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    transfer_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    transfer_account_no character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    transfer_bank_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    transaction_type character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    amount character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    amount_cny numeric(18,2) DEFAULT NULL::numeric,
    amount_format numeric(18,2) DEFAULT NULL::numeric,
    balance character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    balance_format numeric(18,2) DEFAULT NULL::numeric,
    balance_cny numeric(18,2) DEFAULT NULL::numeric,
    notes character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    trans_type character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    running_days integer,
    label_name character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    norm_ids character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    label_type character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    label_source character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    in_or_out character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    cuser character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    ctime bigint,
    error_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    year_and_month integer,
    trade_date_format character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    is_del character varying(2) COLLATE "C" DEFAULT '0'::character varying,
    ds_note character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    alter_label_type character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    muser character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    mtime character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    delete_flag character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    holiday_name character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    label_con_type character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    recp_task_id character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    recp_flow_id character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    pay_notes character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    proportion numeric(10,2) DEFAULT NULL::numeric,
    total numeric(18,2) DEFAULT NULL::numeric,
    relevance_amount numeric(18,2) DEFAULT NULL::numeric,
    postscript character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    purpose character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    remark character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    currency character varying(10) COLLATE "C" DEFAULT 'CNY'::character varying,
    interest numeric(18,2) DEFAULT NULL::numeric,
    is_abnormal character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    truth_check smallint,
    abnormal_type character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    bank_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    bank_code character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    bank_logo character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    bank_cid character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    lend_type_name character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    order_date character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    order_money numeric(18,2) DEFAULT NULL::numeric,
    trade_date_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    contact_info character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    address character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    transfer_contact_info character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    transfer_address character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    means_payment character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    wx_or_zfb character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    num_amount numeric(18,2) DEFAULT 0.00,
    num_balance numeric(18,2) DEFAULT 0.00
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE financial_transaction_records IS '银行交易记录表';
COMMENT ON COLUMN financial_transaction_records._id IS '主键ID';
COMMENT ON COLUMN financial_transaction_records.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN financial_transaction_records.line_id IS '流水线ID';
COMMENT ON COLUMN financial_transaction_records.uuid IS 'uuid';
COMMENT ON COLUMN financial_transaction_records.batch_id IS '批次ID';
COMMENT ON COLUMN financial_transaction_records.task_id IS '任务ID';
COMMENT ON COLUMN financial_transaction_records.page IS '页码';
COMMENT ON COLUMN financial_transaction_records."row" IS '行号';
COMMENT ON COLUMN financial_transaction_records.trade_date IS '交易日期';
COMMENT ON COLUMN financial_transaction_records.trade_date_local IS '本地交易日期';
COMMENT ON COLUMN financial_transaction_records.trade_time IS '交易时间';
COMMENT ON COLUMN financial_transaction_records.name IS '账户名称';
COMMENT ON COLUMN financial_transaction_records.account_no IS '账号';
COMMENT ON COLUMN financial_transaction_records.transfer_name IS '对方账户名称';
COMMENT ON COLUMN financial_transaction_records.transfer_account_no IS '对方账号';
COMMENT ON COLUMN financial_transaction_records.transfer_bank_name IS '对方银行名称';
COMMENT ON COLUMN financial_transaction_records.transaction_type IS '交易类型';
COMMENT ON COLUMN financial_transaction_records.amount IS '金额(带格式)';
COMMENT ON COLUMN financial_transaction_records.amount_cny IS '人民币金额';
COMMENT ON COLUMN financial_transaction_records.amount_format IS '格式化金额';
COMMENT ON COLUMN financial_transaction_records.balance IS '余额(带格式)';
COMMENT ON COLUMN financial_transaction_records.balance_format IS '格式化余额';
COMMENT ON COLUMN financial_transaction_records.balance_cny IS '人民币余额';
COMMENT ON COLUMN financial_transaction_records.notes IS '备注';
COMMENT ON COLUMN financial_transaction_records.trans_type IS '交易类型代码';
COMMENT ON COLUMN financial_transaction_records.running_days IS '运行天数';
COMMENT ON COLUMN financial_transaction_records.label_name IS '标签名称';
COMMENT ON COLUMN financial_transaction_records.norm_ids IS '规范ID';
COMMENT ON COLUMN financial_transaction_records.label_type IS '标签类型';
COMMENT ON COLUMN financial_transaction_records.label_source IS '标签来源';
COMMENT ON COLUMN financial_transaction_records.in_or_out IS '收支方向(0-支出,1-收入)';
COMMENT ON COLUMN financial_transaction_records.cuser IS '创建人';
COMMENT ON COLUMN financial_transaction_records.ctime IS '创建时间戳';
COMMENT ON COLUMN financial_transaction_records.error_type IS '错误类型';
COMMENT ON COLUMN financial_transaction_records.year_and_month IS '年月(YYYYMM)';
COMMENT ON COLUMN financial_transaction_records.trade_date_format IS '格式化交易日期';
COMMENT ON COLUMN financial_transaction_records.is_del IS '是否删除(0-否,1-是)';
COMMENT ON COLUMN financial_transaction_records.ds_note IS '数据源备注';
COMMENT ON COLUMN financial_transaction_records.alter_label_type IS '变更标签类型';
COMMENT ON COLUMN financial_transaction_records.muser IS '修改人';
COMMENT ON COLUMN financial_transaction_records.mtime IS '修改时间';
COMMENT ON COLUMN financial_transaction_records.delete_flag IS '删除标志';
COMMENT ON COLUMN financial_transaction_records.holiday_name IS '节假日名称';
COMMENT ON COLUMN financial_transaction_records.label_con_type IS '标签内容类型';
COMMENT ON COLUMN financial_transaction_records.recp_task_id IS '接收任务ID';
COMMENT ON COLUMN financial_transaction_records.recp_flow_id IS '接收流程ID';
COMMENT ON COLUMN financial_transaction_records.pay_notes IS '支付备注';
COMMENT ON COLUMN financial_transaction_records.proportion IS '比例';
COMMENT ON COLUMN financial_transaction_records.total IS '总额';
COMMENT ON COLUMN financial_transaction_records.relevance_amount IS '相关金额';
COMMENT ON COLUMN financial_transaction_records.postscript IS '附言';
COMMENT ON COLUMN financial_transaction_records.purpose IS '用途';
COMMENT ON COLUMN financial_transaction_records.remark IS '备注';
COMMENT ON COLUMN financial_transaction_records.currency IS '货币';
COMMENT ON COLUMN financial_transaction_records.interest IS '利息';
COMMENT ON COLUMN financial_transaction_records.is_abnormal IS '是否异常';
COMMENT ON COLUMN financial_transaction_records.truth_check IS '真实性检查';
COMMENT ON COLUMN financial_transaction_records.abnormal_type IS '异常类型';
COMMENT ON COLUMN financial_transaction_records.bank_name IS '银行名称';
COMMENT ON COLUMN financial_transaction_records.bank_code IS '银行代码';
COMMENT ON COLUMN financial_transaction_records.bank_logo IS '银行logo';
COMMENT ON COLUMN financial_transaction_records.bank_cid IS '银行CID';
COMMENT ON COLUMN financial_transaction_records.lend_type_name IS '贷款类型名称';
COMMENT ON COLUMN financial_transaction_records.order_date IS '订单日期';
COMMENT ON COLUMN financial_transaction_records.order_money IS '订单金额';
COMMENT ON COLUMN financial_transaction_records.trade_date_time IS '交易日期时间';
COMMENT ON COLUMN financial_transaction_records.contact_info IS '联系方式';
COMMENT ON COLUMN financial_transaction_records.address IS '地址';
COMMENT ON COLUMN financial_transaction_records.transfer_contact_info IS '对方联系方式';
COMMENT ON COLUMN financial_transaction_records.transfer_address IS '对方地址';
COMMENT ON COLUMN financial_transaction_records.means_payment IS '支付方式';
COMMENT ON COLUMN financial_transaction_records.wx_or_zfb IS '微信或支付宝';
COMMENT ON COLUMN financial_transaction_records.num_amount IS '数字金额';
COMMENT ON COLUMN financial_transaction_records.num_balance IS '数字余额';
ALTER TABLE financial_transaction_records ADD CONSTRAINT financial_transaction_records_pkey PRIMARY KEY USING ubtree  (_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE finatial_records (
    task_id integer DEFAULT nextval('finatial_records_task_id_seq'::regclass) NOT NULL,
    sent_content text NOT NULL,
    status character varying(20) COLLATE "C" DEFAULT 'pending'::character varying NOT NULL,
    upload_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE finatial_records IS '财务上传数据记录表';
COMMENT ON COLUMN finatial_records.task_id IS '任务id(自增主键)';
COMMENT ON COLUMN finatial_records.sent_content IS '存放的json数据';
COMMENT ON COLUMN finatial_records.status IS '任务状态';
COMMENT ON COLUMN finatial_records.upload_time IS '上传时间';
ALTER TABLE finatial_records ADD CONSTRAINT finatial_records_pkey PRIMARY KEY USING ubtree  (task_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE finatial_upload_task (
    id integer DEFAULT nextval('finatial_upload_task_id_seq'::regclass) NOT NULL,
    user_id character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    session_no character varying(100) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    file_id character varying(2048) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    file_name character varying(500) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    file_path character varying(500) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    file_size integer DEFAULT 0 NOT NULL,
    parsing_state character varying(20) COLLATE "C" DEFAULT 'parsing'::character varying NOT NULL,
    ent_name character varying(256) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    input_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    fail_reason character varying(2000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE finatial_upload_task IS '财务上传任务表';
COMMENT ON COLUMN finatial_upload_task.id IS '任务id';
COMMENT ON COLUMN finatial_upload_task.user_id IS '用户身份识别码';
COMMENT ON COLUMN finatial_upload_task.session_no IS '会话no';
COMMENT ON COLUMN finatial_upload_task.file_id IS '文件id';
COMMENT ON COLUMN finatial_upload_task.file_name IS '文件名称';
COMMENT ON COLUMN finatial_upload_task.file_path IS '文件路径';
COMMENT ON COLUMN finatial_upload_task.file_size IS '文件路径';
COMMENT ON COLUMN finatial_upload_task.parsing_state IS 'parsing-财务报表解析中； processing-财务指标加工中；parse_success-解析成功；parse_failed-解析失败；';
COMMENT ON COLUMN finatial_upload_task.ent_name IS '企业名称';
COMMENT ON COLUMN finatial_upload_task.input_time IS '创建时间';
COMMENT ON COLUMN finatial_upload_task.update_time IS '更新时间';
COMMENT ON COLUMN finatial_upload_task.fail_reason IS '失败原因';
ALTER TABLE finatial_upload_task ADD CONSTRAINT finatial_upload_task_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE graphs_info (
    user_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    graph_id character varying(64) COLLATE "C" NOT NULL,
    biz_type character varying(256) COLLATE "C" DEFAULT NULL::character varying,
    graph_desc text,
    create_time timestamp without time zone DEFAULT pg_systimestamp(),
    status character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    graph_summary text,
    node_classification text,
    update_time timestamp without time zone DEFAULT pg_systimestamp()
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE graphs_info IS '图谱信息表';
COMMENT ON COLUMN graphs_info.user_id IS '构建子图的用户,根据用户区分是用户上传的图还是线下构建的图';
COMMENT ON COLUMN graphs_info.graph_id IS '子图id';
COMMENT ON COLUMN graphs_info.biz_type IS '业务信息：例如股权关联图谱，工商投资图谱等用于描述子图的业务属性';
COMMENT ON COLUMN graphs_info.graph_desc IS '子图描述';
COMMENT ON COLUMN graphs_info.create_time IS '子图构建时间';
COMMENT ON COLUMN graphs_info.status IS '状态: init=开始构建(还是个空图), propagating=子图扩建中(长点长边), node_classificating=节点分类中, graph_summarizing=子图洞见中, success=构建成功, failed=构建失败';
COMMENT ON COLUMN graphs_info.graph_summary IS '洞见';
COMMENT ON COLUMN graphs_info.node_classification IS '本体分类';
COMMENT ON COLUMN graphs_info.update_time IS '子图更新时间';
ALTER TABLE graphs_info ADD CONSTRAINT graphs_info_pkey PRIMARY KEY USING ubtree  (graph_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_agent_rela (
    id integer DEFAULT nextval('index_agent_rela_id_seq'::regclass) NOT NULL,
    index_id integer,
    index_status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    rec_group character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    rec_question character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    agent_id integer,
    extra_column text,
    index_agent_prompt text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE index_agent_rela IS '指标Agent关联表';
COMMENT ON COLUMN index_agent_rela.id IS '主键ID';
COMMENT ON COLUMN index_agent_rela.index_id IS '关联指标ID';
COMMENT ON COLUMN index_agent_rela.index_status IS '关联指标状态;Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN index_agent_rela.rec_group IS '推荐分组';
COMMENT ON COLUMN index_agent_rela.rec_question IS '推荐问题';
COMMENT ON COLUMN index_agent_rela.agent_id IS '智能体ID';
COMMENT ON COLUMN index_agent_rela.extra_column IS '扩展指标值报告流程';
COMMENT ON COLUMN index_agent_rela.index_agent_prompt IS 'prompt配置管理';
ALTER TABLE index_agent_rela ADD CONSTRAINT idx_source_agent_index UNIQUE USING ubtree (index_id, agent_id) WITH (storage_type=USTORE);
ALTER TABLE index_agent_rela ADD CONSTRAINT index_agent_rela_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_base_group (
    groupid character varying(32) COLLATE "C" NOT NULL,
    groupvalue character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    groupname character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    parentgroupid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    parentgroupname character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    sortno character varying(10) COLLATE "C" DEFAULT '0'::character varying,
    groupstatus character varying(10) COLLATE "C" DEFAULT '1'::character varying,
    inputtime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    updatetime character varying(32) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE index_base_group IS '分组信息';
COMMENT ON COLUMN index_base_group.groupid IS '知识库分组Id';
COMMENT ON COLUMN index_base_group.groupvalue IS '知识库分组编码';
COMMENT ON COLUMN index_base_group.groupname IS '知识库分组名称';
COMMENT ON COLUMN index_base_group.parentgroupid IS '父知识库分组Id';
COMMENT ON COLUMN index_base_group.parentgroupname IS '父知识库分组名称';
COMMENT ON COLUMN index_base_group.sortno IS '排序';
COMMENT ON COLUMN index_base_group.groupstatus IS '知识库分组状态 0无效 1有效';
COMMENT ON COLUMN index_base_group.inputtime IS '登记日期';
COMMENT ON COLUMN index_base_group.updatetime IS '更新日期';
ALTER TABLE index_base_group ADD CONSTRAINT index_base_group_pkey PRIMARY KEY USING ubtree  (groupid) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_detail_code_library (
    _id bigint DEFAULT nextval('index_detail_code_library__id_seq'::regclass) NOT NULL,
    index_detail_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    index_detail_code character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    index_detail_layer1_item_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    index_detail_layer1_item_code character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    index_detail_layer2_item_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    index_detail_layer2_item_code character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    index_detail_layer3_item_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    index_detail_layer3_item_code character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    synonym_word text,
    key_word text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN index_detail_code_library._id IS '主键ID';
COMMENT ON COLUMN index_detail_code_library.index_detail_name IS '指标分析维度名称';
COMMENT ON COLUMN index_detail_code_library.index_detail_code IS '指标分析维度编码';
COMMENT ON COLUMN index_detail_code_library.index_detail_layer1_item_name IS '指标分析维度一层枚举值名称';
COMMENT ON COLUMN index_detail_code_library.index_detail_layer1_item_code IS '指标分析维度一层枚举值编码';
COMMENT ON COLUMN index_detail_code_library.index_detail_layer2_item_name IS '指标分析维度二层枚举值名称';
COMMENT ON COLUMN index_detail_code_library.index_detail_layer2_item_code IS '指标分析维度二层枚举值编码';
COMMENT ON COLUMN index_detail_code_library.index_detail_layer3_item_name IS '指标分析维度三层枚举值名称';
COMMENT ON COLUMN index_detail_code_library.index_detail_layer3_item_code IS '指标分析维度三层枚举值编码';
COMMENT ON COLUMN index_detail_code_library.synonym_word IS '同义词';
COMMENT ON COLUMN index_detail_code_library.key_word IS '关键字';
ALTER TABLE index_detail_code_library ADD CONSTRAINT index_detail_code_library_pkey PRIMARY KEY USING ubtree  (_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_detail_config (
    id integer DEFAULT nextval('index_detail_config_id_seq'::regclass) NOT NULL,
    index_id integer,
    index_detail_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    source_type_detail character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    default_value character varying(128) COLLATE "C" DEFAULT NULL::character varying,
    remark character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    param_value_id character varying(266) COLLATE "C" DEFAULT NULL::character varying,
    index_detail_field character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    index_detail_field_type character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    ai_identify_param character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    sample_question character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE index_detail_config IS '指标分析维度配置表';
COMMENT ON COLUMN index_detail_config.id IS '主键ID';
COMMENT ON COLUMN index_detail_config.index_id IS '组件ID';
COMMENT ON COLUMN index_detail_config.index_detail_name IS '细类字段名称';
COMMENT ON COLUMN index_detail_config.source_type_detail IS '细类类型';
COMMENT ON COLUMN index_detail_config.default_value IS '默认值';
COMMENT ON COLUMN index_detail_config.remark IS '备注';
COMMENT ON COLUMN index_detail_config.param_value_id IS '细类字段关联ID';
COMMENT ON COLUMN index_detail_config.index_detail_field IS '细类字段编码';
COMMENT ON COLUMN index_detail_config.index_detail_field_type IS '细类字段类型';
COMMENT ON COLUMN index_detail_config.ai_identify_param IS 'AI识别参数';
COMMENT ON COLUMN index_detail_config.sample_question IS '示例问题';
ALTER TABLE index_detail_config ADD CONSTRAINT index_detail_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_info_temp (
    _id bigint DEFAULT nextval('index_info_temp__id_seq'::regclass) NOT NULL,
    paramno character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    paramid character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    paramname character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN index_info_temp._id IS '主键ID';
ALTER TABLE index_info_temp ADD CONSTRAINT index_info_temp_pkey PRIMARY KEY USING ubtree  (_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_label_rela (
    index_name character varying(100) COLLATE "C" NOT NULL,
    index_code character varying(32) COLLATE "C" NOT NULL,
    source_type character varying(200) COLLATE "C" NOT NULL,
    label_database_type character varying(20) COLLATE "C" DEFAULT '分类知识库'::character varying NOT NULL,
    label_name_level_1 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_code_level_1 character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    label_name_level_2 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_code_level_2 character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    label_name_level_3 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_code_level_3 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_name_level_4 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_code_level_4 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    interface_no character varying(256) COLLATE "C" DEFAULT NULL::character varying,
    label_database character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_table character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_column character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_vectordb_addr character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_dict_code_1 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_dict_code_2 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_dict_code_3 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    label_dict_code_4 character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_id character varying(100) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN index_label_rela.index_name IS '指标名称';
COMMENT ON COLUMN index_label_rela.index_code IS '指标编码';
COMMENT ON COLUMN index_label_rela.source_type IS '数据来源';
COMMENT ON COLUMN index_label_rela.label_database_type IS '知识库类型';
COMMENT ON COLUMN index_label_rela.label_name_level_1 IS '一级知识库名';
COMMENT ON COLUMN index_label_rela.label_code_level_1 IS '一级知识库code';
COMMENT ON COLUMN index_label_rela.label_name_level_2 IS '二级知识库名';
COMMENT ON COLUMN index_label_rela.label_code_level_2 IS '二级知识库code';
COMMENT ON COLUMN index_label_rela.label_name_level_3 IS '三级知识库名';
COMMENT ON COLUMN index_label_rela.label_code_level_3 IS '三级知识库code';
COMMENT ON COLUMN index_label_rela.label_name_level_4 IS '四级知识库名';
COMMENT ON COLUMN index_label_rela.label_code_level_4 IS '四级知识库code';
COMMENT ON COLUMN index_label_rela.interface_no IS '涉及接口';
COMMENT ON COLUMN index_label_rela.label_database IS '知识库库名';
COMMENT ON COLUMN index_label_rela.label_table IS '知识库表名';
COMMENT ON COLUMN index_label_rela.label_column IS '知识库字段名';
COMMENT ON COLUMN index_label_rela.label_vectordb_addr IS '向量库地址';
COMMENT ON COLUMN index_label_rela.label_dict_code_1 IS '一级知识库字典码值';
COMMENT ON COLUMN index_label_rela.label_dict_code_2 IS '二级知识库字典码值';
COMMENT ON COLUMN index_label_rela.label_dict_code_3 IS '三级知识库字典码值';
COMMENT ON COLUMN index_label_rela.label_dict_code_4 IS '四级知识库字典码值';
COMMENT ON COLUMN index_label_rela.knowledge_id IS '关联知识库ID';
ALTER TABLE index_label_rela ADD CONSTRAINT index_label_rela_pkey PRIMARY KEY USING ubtree  (index_code, source_type) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_params (
    paramno character varying(32) COLLATE "C" NOT NULL,
    paramid character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    paramname character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    paramtype character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    codemethod character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    codeno character varying(120) COLLATE "C" DEFAULT NULL::character varying,
    required character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    readonly character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    defaultformat character varying(120) COLLATE "C" DEFAULT NULL::character varying,
    inputmethod character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    fromparamno character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    defaultvalue character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    parentparamno character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    publicparamstatus character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    modelno character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    initmethod character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    datamethod character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    parentparamname character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    reportversion character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    versionno character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    paramsource character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    charttype character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    sortno character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    placeholder character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    acturecolumn character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columnlength character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columntype character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columnremark character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columnisnull character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columncomment character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columnfromtable character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columnfromdatasource character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    otherconfig character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    scripttype character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    script text,
    validators character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    chartinitmethod character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    inputuserid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    inputorgid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    inputtime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    updateuserid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    updateorgid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    updatetime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    supplierid character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intfno character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intfparams character varying(3000) COLLATE "C" DEFAULT NULL::character varying,
    intffield text,
    intffieldtype character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    structure text,
    extendfield text,
    otherno character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    count_field text,
    is_online smallint DEFAULT 0::smallint,
    metric_intro character varying(500) COLLATE "C" DEFAULT ''::character varying,
    data_unit character varying(50) COLLATE "C" DEFAULT ''::character varying,
    data_example character varying(1000) COLLATE "C" DEFAULT ''::character varying,
    data_type character varying(30) COLLATE "C" DEFAULT ''::character varying,
    data_content_parse text,
    paramkey character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE index_params IS '指标参数信息表';
COMMENT ON COLUMN index_params.paramno IS '指标流水号';
COMMENT ON COLUMN index_params.paramid IS '指标ID';
COMMENT ON COLUMN index_params.paramname IS '指标名称';
COMMENT ON COLUMN index_params.paramtype IS '指标类型';
COMMENT ON COLUMN index_params.codemethod IS '取值方式';
COMMENT ON COLUMN index_params.codeno IS '取值字段';
COMMENT ON COLUMN index_params.required IS '是否必输';
COMMENT ON COLUMN index_params.readonly IS '是否只读';
COMMENT ON COLUMN index_params.defaultformat IS '默认格式';
COMMENT ON COLUMN index_params.inputmethod IS '输入形式';
COMMENT ON COLUMN index_params.fromparamno IS '指标来源編号';
COMMENT ON COLUMN index_params.defaultvalue IS '指标默认值';
COMMENT ON COLUMN index_params.parentparamno IS '父指标ID';
COMMENT ON COLUMN index_params.publicparamstatus IS '公共指标状态';
COMMENT ON COLUMN index_params.modelno IS '所属模板流水号';
COMMENT ON COLUMN index_params.initmethod IS '初始化方法';
COMMENT ON COLUMN index_params.datamethod IS '指标值获取方式';
COMMENT ON COLUMN index_params.parentparamname IS '父指标名称';
COMMENT ON COLUMN index_params.reportversion IS '指标所属版本';
COMMENT ON COLUMN index_params.versionno IS '指标所属子版本';
COMMENT ON COLUMN index_params.paramsource IS '指标来源(1:XML配置转化；2:前台配置；3:数据源引入)';
COMMENT ON COLUMN index_params.charttype IS '图表细类';
COMMENT ON COLUMN index_params.sortno IS '排序';
COMMENT ON COLUMN index_params.placeholder IS '提示信息';
COMMENT ON COLUMN index_params.acturecolumn IS '字段名';
COMMENT ON COLUMN index_params.columnlength IS '字段长度';
COMMENT ON COLUMN index_params.columntype IS '数据类型';
COMMENT ON COLUMN index_params.columnremark IS '备注';
COMMENT ON COLUMN index_params.columnisnull IS '是否为空';
COMMENT ON COLUMN index_params.columncomment IS '注释';
COMMENT ON COLUMN index_params.columnfromtable IS '来源表';
COMMENT ON COLUMN index_params.columnfromdatasource IS '来源数据库';
COMMENT ON COLUMN index_params.otherconfig IS '其他配置';
COMMENT ON COLUMN index_params.scripttype IS '脚本类型 Sql/Java/Api';
COMMENT ON COLUMN index_params.script IS '脚本内容';
COMMENT ON COLUMN index_params.validators IS '校验规则';
COMMENT ON COLUMN index_params.chartinitmethod IS 'DiyECharts图表初始化方法';
COMMENT ON COLUMN index_params.inputuserid IS '登记人';
COMMENT ON COLUMN index_params.inputorgid IS '登记机构';
COMMENT ON COLUMN index_params.inputtime IS '登记日期';
COMMENT ON COLUMN index_params.updateuserid IS '更新用户';
COMMENT ON COLUMN index_params.updateorgid IS '更新机构';
COMMENT ON COLUMN index_params.updatetime IS '更新日期';
COMMENT ON COLUMN index_params.supplierid IS 'Api接口服务编号';
COMMENT ON COLUMN index_params.intfno IS 'Api接口编号';
COMMENT ON COLUMN index_params.intfparams IS 'Api接口参数（JSON字符串存储）';
COMMENT ON COLUMN index_params.intffield IS 'Api接口取值字段（层级结构存储）';
COMMENT ON COLUMN index_params.intffieldtype IS 'Api接口取值字段类型';
COMMENT ON COLUMN index_params.structure IS '接口结构';
COMMENT ON COLUMN index_params.extendfield IS '拓展字段';
COMMENT ON COLUMN index_params.otherno IS 'api层级编号';
COMMENT ON COLUMN index_params.count_field IS '统计字段';
COMMENT ON COLUMN index_params.is_online IS '是否上线语义指标 0-否 1-是';
COMMENT ON COLUMN index_params.metric_intro IS '指标介绍';
COMMENT ON COLUMN index_params.data_unit IS '数值单位';
COMMENT ON COLUMN index_params.data_example IS '数据样例';
COMMENT ON COLUMN index_params.data_type IS '数据类型';
COMMENT ON COLUMN index_params.data_content_parse IS '数据内容解析结果';
COMMENT ON COLUMN index_params.paramkey IS '指标唯一标志';
ALTER TABLE index_params ADD CONSTRAINT index_params_pkey PRIMARY KEY USING ubtree  (paramno) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_params_temp (
    _id bigint DEFAULT nextval('index_params_temp__id_seq'::regclass) NOT NULL,
    paramno character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    intfparams text,
    script text,
    scripttype character varying(10) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN index_params_temp._id IS '主键ID';
ALTER TABLE index_params_temp ADD CONSTRAINT index_params_temp_pkey PRIMARY KEY USING ubtree  (_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_params_version (
    id character varying(32) COLLATE "C" NOT NULL,
    paramno character varying(32) COLLATE "C" NOT NULL,
    paramversion character varying(100) COLLATE "C" NOT NULL,
    paramid character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    paramname character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    paramtype character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    codemethod character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    codeno character varying(120) COLLATE "C" DEFAULT NULL::character varying,
    required character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    readonly character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    defaultformat character varying(120) COLLATE "C" DEFAULT NULL::character varying,
    inputmethod character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    fromparamno character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    defaultvalue character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    parentparamno character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    publicparamstatus character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    modelno character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    initmethod character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    datamethod character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    parentparamname character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    reportversion character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    versionno character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    paramsource character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    charttype character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    sortno character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    placeholder character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    acturecolumn character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columnlength character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columntype character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columnremark character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columnisnull character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columncomment character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columnfromtable character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    columnfromdatasource character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    otherconfig character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    scripttype character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    script text,
    validators character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    chartinitmethod character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    inputuserid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    inputorgid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    inputtime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    updateuserid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    updateorgid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    updatetime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    supplierid character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intfno character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intfparams character varying(3000) COLLATE "C" DEFAULT NULL::character varying,
    intffield text,
    intffieldtype character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    structure text,
    extendfield text,
    otherno character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    count_field text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE index_params_version IS '指标参数版本信息表';
COMMENT ON COLUMN index_params_version.id IS '主键ID';
COMMENT ON COLUMN index_params_version.paramno IS '指标流水号';
COMMENT ON COLUMN index_params_version.paramversion IS '指标版本';
COMMENT ON COLUMN index_params_version.paramid IS '指标ID';
COMMENT ON COLUMN index_params_version.paramname IS '指标名称';
COMMENT ON COLUMN index_params_version.paramtype IS '指标类型';
COMMENT ON COLUMN index_params_version.codemethod IS '取值方式';
COMMENT ON COLUMN index_params_version.codeno IS '取值字段';
COMMENT ON COLUMN index_params_version.required IS '是否必输';
COMMENT ON COLUMN index_params_version.readonly IS '是否只读';
COMMENT ON COLUMN index_params_version.defaultformat IS '默认格式';
COMMENT ON COLUMN index_params_version.inputmethod IS '输入形式';
COMMENT ON COLUMN index_params_version.fromparamno IS '指标来源編号';
COMMENT ON COLUMN index_params_version.defaultvalue IS '指标默认值';
COMMENT ON COLUMN index_params_version.parentparamno IS '父指标ID';
COMMENT ON COLUMN index_params_version.publicparamstatus IS '公共指标状态';
COMMENT ON COLUMN index_params_version.modelno IS '所属模板流水号';
COMMENT ON COLUMN index_params_version.initmethod IS '初始化方法';
COMMENT ON COLUMN index_params_version.datamethod IS '指标值获取方式';
COMMENT ON COLUMN index_params_version.parentparamname IS '父指标名称';
COMMENT ON COLUMN index_params_version.reportversion IS '指标所属版本';
COMMENT ON COLUMN index_params_version.versionno IS '指标所属子版本';
COMMENT ON COLUMN index_params_version.paramsource IS '指标来源(1:XML配置转化；2:前台配置；3:数据源引入)';
COMMENT ON COLUMN index_params_version.charttype IS '图表细类';
COMMENT ON COLUMN index_params_version.sortno IS '排序';
COMMENT ON COLUMN index_params_version.placeholder IS '提示信息';
COMMENT ON COLUMN index_params_version.acturecolumn IS '字段名';
COMMENT ON COLUMN index_params_version.columnlength IS '字段长度';
COMMENT ON COLUMN index_params_version.columntype IS '数据类型';
COMMENT ON COLUMN index_params_version.columnremark IS '备注';
COMMENT ON COLUMN index_params_version.columnisnull IS '是否为空';
COMMENT ON COLUMN index_params_version.columncomment IS '注释';
COMMENT ON COLUMN index_params_version.columnfromtable IS '来源表';
COMMENT ON COLUMN index_params_version.columnfromdatasource IS '来源数据库';
COMMENT ON COLUMN index_params_version.otherconfig IS '其他配置';
COMMENT ON COLUMN index_params_version.scripttype IS '脚本类型 Sql/Java/Api';
COMMENT ON COLUMN index_params_version.script IS '脚本内容';
COMMENT ON COLUMN index_params_version.validators IS '校验规则';
COMMENT ON COLUMN index_params_version.chartinitmethod IS 'DiyECharts图表初始化方法';
COMMENT ON COLUMN index_params_version.inputuserid IS '登记人';
COMMENT ON COLUMN index_params_version.inputorgid IS '登记机构';
COMMENT ON COLUMN index_params_version.inputtime IS '登记日期';
COMMENT ON COLUMN index_params_version.updateuserid IS '更新用户';
COMMENT ON COLUMN index_params_version.updateorgid IS '更新机构';
COMMENT ON COLUMN index_params_version.updatetime IS '更新日期';
COMMENT ON COLUMN index_params_version.supplierid IS 'Api接口服务编号';
COMMENT ON COLUMN index_params_version.intfno IS 'Api接口编号';
COMMENT ON COLUMN index_params_version.intfparams IS 'Api接口参数（JSON字符串存储）';
COMMENT ON COLUMN index_params_version.intffield IS 'Api接口取值字段（层级结构存储）';
COMMENT ON COLUMN index_params_version.intffieldtype IS 'Api接口取值字段类型';
COMMENT ON COLUMN index_params_version.structure IS '接口结构';
COMMENT ON COLUMN index_params_version.extendfield IS '拓展字段';
COMMENT ON COLUMN index_params_version.otherno IS 'api层级编号';
COMMENT ON COLUMN index_params_version.count_field IS '统计字段';
ALTER TABLE index_params_version ADD CONSTRAINT index_params_version_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_relate_index_info (
    id character varying(32) COLLATE "C" NOT NULL,
    param_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    relate_param_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    relate_param_id character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    relate_param_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    relate_group_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp(),
    update_time timestamp without time zone DEFAULT pg_systimestamp()
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE index_relate_index_info IS '指标关联指标信息表';
COMMENT ON COLUMN index_relate_index_info.id IS '主键id';
COMMENT ON COLUMN index_relate_index_info.param_no IS '指标编号';
COMMENT ON COLUMN index_relate_index_info.relate_param_no IS '关联指标编号';
COMMENT ON COLUMN index_relate_index_info.relate_param_id IS '关联指标编码';
COMMENT ON COLUMN index_relate_index_info.relate_param_name IS '关联指标名称';
COMMENT ON COLUMN index_relate_index_info.relate_group_id IS '关联指标分组ID';
COMMENT ON COLUMN index_relate_index_info.create_time IS '创建时间';
COMMENT ON COLUMN index_relate_index_info.update_time IS '更新时间';
ALTER TABLE index_relate_index_info ADD CONSTRAINT index_relate_index_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_relate_info (
    id integer DEFAULT nextval('index_relate_info_id_seq'::regclass) NOT NULL,
    index_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    relate_index_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    relate_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    comment character varying(500) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE index_relate_info IS '指标关联信息表';
COMMENT ON COLUMN index_relate_info.index_id IS '指标ID';
COMMENT ON COLUMN index_relate_info.relate_index_id IS '关联指标ID';
COMMENT ON COLUMN index_relate_info.relate_time IS '关联时间';
COMMENT ON COLUMN index_relate_info.comment IS '备注';
ALTER TABLE index_relate_info ADD CONSTRAINT index_relate_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE index_relate_knowledge_info (
    id character varying(32) COLLATE "C" NOT NULL,
    param_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    relate_knowledge_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    relate_knowledge_code character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    relate_knowledge_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    relate_group_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    relate_items character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp(),
    update_time timestamp without time zone DEFAULT pg_systimestamp()
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE index_relate_knowledge_info IS '指标关联知识库信息表';
COMMENT ON COLUMN index_relate_knowledge_info.id IS '主键id';
COMMENT ON COLUMN index_relate_knowledge_info.param_no IS '指标编号';
COMMENT ON COLUMN index_relate_knowledge_info.relate_knowledge_no IS '关联知识库编号';
COMMENT ON COLUMN index_relate_knowledge_info.relate_knowledge_code IS '关联知识库编码';
COMMENT ON COLUMN index_relate_knowledge_info.relate_knowledge_name IS '关联知识库名称';
COMMENT ON COLUMN index_relate_knowledge_info.relate_group_id IS '关联知识库分组ID';
COMMENT ON COLUMN index_relate_knowledge_info.relate_items IS '关联知识库项，包含知识配置、溯源配置、图片配置、全部来源配置';
COMMENT ON COLUMN index_relate_knowledge_info.create_time IS '创建时间';
COMMENT ON COLUMN index_relate_knowledge_info.update_time IS '更新时间';
ALTER TABLE index_relate_knowledge_info ADD CONSTRAINT index_relate_knowledge_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE jeecg_monthly_growth_analysis (
    id integer DEFAULT nextval('jeecg_monthly_growth_analysis_id_seq'::regclass) NOT NULL,
    year character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    month character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    main_income numeric(18,2) DEFAULT 0.00,
    other_income numeric(18,2) DEFAULT 0.00
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN jeecg_monthly_growth_analysis.month IS '月份';
COMMENT ON COLUMN jeecg_monthly_growth_analysis.main_income IS '佣金/主营收入';
COMMENT ON COLUMN jeecg_monthly_growth_analysis.other_income IS '其他收入';
ALTER TABLE jeecg_monthly_growth_analysis ADD CONSTRAINT jeecg_monthly_growth_analysis_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE jeecg_order_customer (
    id character varying(32) COLLATE "C" NOT NULL,
    name character varying(100) COLLATE "C" NOT NULL,
    sex character varying(4) COLLATE "C" DEFAULT NULL::character varying,
    idcard character varying(18) COLLATE "C" DEFAULT NULL::character varying,
    idcard_pic character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    telphone character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    order_id character varying(32) COLLATE "C" NOT NULL,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN jeecg_order_customer.id IS '主键';
COMMENT ON COLUMN jeecg_order_customer.name IS '客户名';
COMMENT ON COLUMN jeecg_order_customer.sex IS '性别';
COMMENT ON COLUMN jeecg_order_customer.idcard IS '身份证号码';
COMMENT ON COLUMN jeecg_order_customer.idcard_pic IS '身份证扫描件';
COMMENT ON COLUMN jeecg_order_customer.telphone IS '电话1';
COMMENT ON COLUMN jeecg_order_customer.order_id IS '外键';
COMMENT ON COLUMN jeecg_order_customer.create_by IS '创建人';
COMMENT ON COLUMN jeecg_order_customer.create_time IS '创建时间';
COMMENT ON COLUMN jeecg_order_customer.update_by IS '修改人';
COMMENT ON COLUMN jeecg_order_customer.update_time IS '修改时间';
ALTER TABLE jeecg_order_customer ADD CONSTRAINT jeecg_order_customer_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE jeecg_order_main (
    id character varying(32) COLLATE "C" NOT NULL,
    order_code character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    ctype character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    order_date timestamp without time zone,
    order_money numeric(10,3) DEFAULT NULL::numeric,
    content character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN jeecg_order_main.id IS '主键';
COMMENT ON COLUMN jeecg_order_main.order_code IS '订单号';
COMMENT ON COLUMN jeecg_order_main.ctype IS '订单类型';
COMMENT ON COLUMN jeecg_order_main.order_date IS '订单日期';
COMMENT ON COLUMN jeecg_order_main.order_money IS '订单金额';
COMMENT ON COLUMN jeecg_order_main.content IS '订单备注';
COMMENT ON COLUMN jeecg_order_main.create_by IS '创建人';
COMMENT ON COLUMN jeecg_order_main.create_time IS '创建时间';
COMMENT ON COLUMN jeecg_order_main.update_by IS '修改人';
COMMENT ON COLUMN jeecg_order_main.update_time IS '修改时间';
ALTER TABLE jeecg_order_main ADD CONSTRAINT jeecg_order_main_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE jeecg_order_ticket (
    id character varying(32) COLLATE "C" NOT NULL,
    ticket_code character varying(100) COLLATE "C" NOT NULL,
    tickect_date timestamp without time zone,
    order_id character varying(32) COLLATE "C" NOT NULL,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN jeecg_order_ticket.id IS '主键';
COMMENT ON COLUMN jeecg_order_ticket.ticket_code IS '航班号';
COMMENT ON COLUMN jeecg_order_ticket.tickect_date IS '航班时间';
COMMENT ON COLUMN jeecg_order_ticket.order_id IS '外键';
COMMENT ON COLUMN jeecg_order_ticket.create_by IS '创建人';
COMMENT ON COLUMN jeecg_order_ticket.create_time IS '创建时间';
COMMENT ON COLUMN jeecg_order_ticket.update_by IS '修改人';
COMMENT ON COLUMN jeecg_order_ticket.update_time IS '修改时间';
ALTER TABLE jeecg_order_ticket ADD CONSTRAINT jeecg_order_ticket_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE jeecg_project_nature_income (
    id integer DEFAULT nextval('jeecg_project_nature_income_id_seq'::regclass) NOT NULL,
    nature character varying(50) COLLATE "C" NOT NULL,
    insurance_fee numeric(18,2) DEFAULT 0.00,
    risk_consulting_fee numeric(18,2) DEFAULT 0.00,
    evaluation_fee numeric(18,2) DEFAULT 0.00,
    insurance_evaluation_fee numeric(18,2) DEFAULT 0.00,
    bidding_consulting_fee numeric(18,2) DEFAULT 0.00,
    interol_consulting_fee numeric(18,2) DEFAULT 0.00
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN jeecg_project_nature_income.nature IS '项目性质';
COMMENT ON COLUMN jeecg_project_nature_income.insurance_fee IS '保险经纪佣金费';
COMMENT ON COLUMN jeecg_project_nature_income.risk_consulting_fee IS '风险咨询费';
COMMENT ON COLUMN jeecg_project_nature_income.evaluation_fee IS '承保公估评估费';
COMMENT ON COLUMN jeecg_project_nature_income.insurance_evaluation_fee IS '保险公估费';
COMMENT ON COLUMN jeecg_project_nature_income.bidding_consulting_fee IS '投标咨询费';
COMMENT ON COLUMN jeecg_project_nature_income.interol_consulting_fee IS '内控咨询费';
ALTER TABLE jeecg_project_nature_income ADD CONSTRAINT jeecg_project_nature_income_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_base_group (
    groupid character varying(32) COLLATE "C" NOT NULL,
    groupname character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    parentgroupid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    parentgroupname character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    sortno character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    groupstatus character varying(10) COLLATE "C" DEFAULT '1'::character varying,
    inputtime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    updatetime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    groupvalue character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    grouptype character varying(20) COLLATE "C" DEFAULT 'get_knowledge'::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_base_group IS '知识库分组信息';
COMMENT ON COLUMN knowledge_base_group.groupid IS '知识库分组Id';
COMMENT ON COLUMN knowledge_base_group.groupname IS '知识库分组名称';
COMMENT ON COLUMN knowledge_base_group.parentgroupid IS '父知识库分组Id';
COMMENT ON COLUMN knowledge_base_group.parentgroupname IS '父知识库分组名称';
COMMENT ON COLUMN knowledge_base_group.sortno IS '排序';
COMMENT ON COLUMN knowledge_base_group.groupstatus IS '知识库分组状态 0无效 1有效';
COMMENT ON COLUMN knowledge_base_group.inputtime IS '登记日期';
COMMENT ON COLUMN knowledge_base_group.updatetime IS '更新日期';
COMMENT ON COLUMN knowledge_base_group.groupvalue IS '知识库分组编码';
COMMENT ON COLUMN knowledge_base_group.grouptype IS '知识库分类 get_knowledge-知识库 apply_prompt-应用提示词 custom-用户自定义';
ALTER TABLE knowledge_base_group ADD CONSTRAINT knowledge_base_group_pkey PRIMARY KEY USING ubtree  (groupid) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_base_params (
    paramid character varying(32) COLLATE "C" NOT NULL,
    paramno character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    paramname character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    paramtype character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    paramentitytype character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    paramlabel character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    modelno character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    parentparamid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    parentparamname character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    reportversion character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    sortno character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    prompt text,
    agentid character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    otherconfig character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    paramstatus character varying(10) COLLATE "C" DEFAULT 'Y'::character varying,
    inputuserid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    inputtime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    updateuserid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    updatetime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    groupid character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    "online" character varying(10) COLLATE "C" DEFAULT 'N'::character varying,
    prompttype character varying(10) COLLATE "C" DEFAULT 'basic'::character varying,
    contentdesc text,
    input_param text,
    large_model_code character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    trace_config text,
    image_config text,
    whole_source_config text,
    large_model_content text,
    relate_index_set text,
    black_content_desc character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    black_model_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    is_markdown character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    param_description character varying(5000) COLLATE "C" DEFAULT NULL::character varying,
    input_condition text,
    is_client_search character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    is_online_search character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    input_index text,
    large_model_param text,
    is_top character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    splitter_param text,
    tool_parameters_config text,
    is_cloud_search character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    user_prompt text,
    split_strategy_param text,
    business_experience text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_base_params IS '知识库参数信息表';
COMMENT ON COLUMN knowledge_base_params.paramid IS '知识库流水号';
COMMENT ON COLUMN knowledge_base_params.paramno IS '知识库编号';
COMMENT ON COLUMN knowledge_base_params.paramname IS '知识库名称';
COMMENT ON COLUMN knowledge_base_params.paramtype IS '知识库类型 GROUP OBJECT';
COMMENT ON COLUMN knowledge_base_params.paramentitytype IS '知识库主体类型';
COMMENT ON COLUMN knowledge_base_params.paramlabel IS '知识库标签';
COMMENT ON COLUMN knowledge_base_params.modelno IS '所属模板流水号';
COMMENT ON COLUMN knowledge_base_params.parentparamid IS '父知识库ID';
COMMENT ON COLUMN knowledge_base_params.parentparamname IS '父知识库名称';
COMMENT ON COLUMN knowledge_base_params.reportversion IS '知识库所属版本';
COMMENT ON COLUMN knowledge_base_params.sortno IS '排序';
COMMENT ON COLUMN knowledge_base_params.prompt IS 'prompt配置';
COMMENT ON COLUMN knowledge_base_params.agentid IS '关联agent';
COMMENT ON COLUMN knowledge_base_params.otherconfig IS '其他配置';
COMMENT ON COLUMN knowledge_base_params.paramstatus IS '知识库状态 N无效 Y有效';
COMMENT ON COLUMN knowledge_base_params.inputuserid IS '登记人';
COMMENT ON COLUMN knowledge_base_params.inputtime IS '登记日期';
COMMENT ON COLUMN knowledge_base_params.updateuserid IS '更新用户';
COMMENT ON COLUMN knowledge_base_params.updatetime IS '更新日期';
COMMENT ON COLUMN knowledge_base_params.groupid IS '知识库分组ID';
COMMENT ON COLUMN knowledge_base_params."online" IS '是否上线 N否 Y是';
COMMENT ON COLUMN knowledge_base_params.prompttype IS 'prompt类型：basic 或 content';
COMMENT ON COLUMN knowledge_base_params.contentdesc IS '当prompt类型为content，需填此值';
COMMENT ON COLUMN knowledge_base_params.input_param IS '输入参数';
COMMENT ON COLUMN knowledge_base_params.large_model_code IS '大模型编码';
COMMENT ON COLUMN knowledge_base_params.trace_config IS '溯源配置';
COMMENT ON COLUMN knowledge_base_params.image_config IS '图片配置';
COMMENT ON COLUMN knowledge_base_params.whole_source_config IS '全部来源配置';
COMMENT ON COLUMN knowledge_base_params.large_model_content IS '不同大模型对应的输出要求';
COMMENT ON COLUMN knowledge_base_params.relate_index_set IS '知识库关联指标集合';
COMMENT ON COLUMN knowledge_base_params.black_content_desc IS '黑盒输出要求';
COMMENT ON COLUMN knowledge_base_params.black_model_code IS '黑盒大模型编码';
COMMENT ON COLUMN knowledge_base_params.is_markdown IS '是否markdown格式输出 Y是N否';
COMMENT ON COLUMN knowledge_base_params.param_description IS '知识库详细信息描述';
COMMENT ON COLUMN knowledge_base_params.input_condition IS '其他输出要求';
COMMENT ON COLUMN knowledge_base_params.is_client_search IS '是否在客户端查询 Y是 N否';
COMMENT ON COLUMN knowledge_base_params.is_online_search IS '是否云端查询 Y是N 否';
COMMENT ON COLUMN knowledge_base_params.input_index IS '输出指标配置';
COMMENT ON COLUMN knowledge_base_params.large_model_param IS '大模型属性参数，包括：systemContent: 文本系统提示词 topP: 浮点数top概率 temperature: 浮点数温度';
COMMENT ON COLUMN knowledge_base_params.is_top IS '输出要求是否置顶';
COMMENT ON COLUMN knowledge_base_params.splitter_param IS '拆分整合提示词参数配置';
COMMENT ON COLUMN knowledge_base_params.tool_parameters_config IS '知识库工具参数配置';
COMMENT ON COLUMN knowledge_base_params.is_cloud_search IS '是否走云端大模型渲染 Y是 N否';
COMMENT ON COLUMN knowledge_base_params.user_prompt IS '用户提示词';
COMMENT ON COLUMN knowledge_base_params.split_strategy_param IS '知识库拆分策略参数';
COMMENT ON COLUMN knowledge_base_params.business_experience IS '业务经验知识';
ALTER TABLE knowledge_base_params ADD CONSTRAINT knowledge_base_params_pkey PRIMARY KEY USING ubtree  (paramid) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_base_version (
    id character varying(32) COLLATE "C" NOT NULL,
    param_id character varying(32) COLLATE "C" NOT NULL,
    version_no character varying(200) COLLATE "C" NOT NULL,
    version_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp(),
    update_time timestamp without time zone DEFAULT pg_systimestamp(),
    create_user_id character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    create_user_name character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    sort_no integer DEFAULT 0,
    latest_flag integer DEFAULT 1,
    prompt text,
    content_desc text,
    large_model_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    trace_config text,
    large_model_content text,
    image_config text,
    whole_source_config text,
    relate_index_set text,
    black_content_desc character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    black_model_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_condition text,
    input_index text,
    large_model_param character varying(2000) COLLATE "C" DEFAULT ''::character varying,
    is_top character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    splitter_param text,
    is_cloud_search character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    is_markdown character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    is_online_search character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    is_client_search character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    user_prompt text,
    split_strategy_param text,
    business_experience text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_base_version IS '知识库版本管理';
COMMENT ON COLUMN knowledge_base_version.id IS '主键ID';
COMMENT ON COLUMN knowledge_base_version.param_id IS '知识库ID';
COMMENT ON COLUMN knowledge_base_version.version_no IS '版本编号';
COMMENT ON COLUMN knowledge_base_version.version_name IS '版本名称';
COMMENT ON COLUMN knowledge_base_version.create_time IS '版本创建时间';
COMMENT ON COLUMN knowledge_base_version.update_time IS '更新时间';
COMMENT ON COLUMN knowledge_base_version.create_user_id IS '创建人ID';
COMMENT ON COLUMN knowledge_base_version.create_user_name IS '创建人名字';
COMMENT ON COLUMN knowledge_base_version.sort_no IS '排序号';
COMMENT ON COLUMN knowledge_base_version.latest_flag IS '最新发布标志 1最新 0历史';
COMMENT ON COLUMN knowledge_base_version.prompt IS 'prompt配置';
COMMENT ON COLUMN knowledge_base_version.content_desc IS '输出要求';
COMMENT ON COLUMN knowledge_base_version.large_model_code IS '大模型编码';
COMMENT ON COLUMN knowledge_base_version.trace_config IS '溯源配置';
COMMENT ON COLUMN knowledge_base_version.large_model_content IS '不同大模型对应的输出要求';
COMMENT ON COLUMN knowledge_base_version.image_config IS '图片配置';
COMMENT ON COLUMN knowledge_base_version.whole_source_config IS '全部来源配置';
COMMENT ON COLUMN knowledge_base_version.relate_index_set IS '知识库关联指标集合';
COMMENT ON COLUMN knowledge_base_version.black_content_desc IS '黑盒输出要求';
COMMENT ON COLUMN knowledge_base_version.black_model_code IS '黑盒大模型编码';
COMMENT ON COLUMN knowledge_base_version.input_condition IS '其他输出要求';
COMMENT ON COLUMN knowledge_base_version.input_index IS '输出指标配置';
COMMENT ON COLUMN knowledge_base_version.large_model_param IS '大模型属性参数，包括：systemContent: 文本系统提示词 topP: 浮点数top概率 temperature: 浮点数温度';
COMMENT ON COLUMN knowledge_base_version.is_top IS '输出要求是否置顶';
COMMENT ON COLUMN knowledge_base_version.splitter_param IS '拆分整合提示词参数配置';
COMMENT ON COLUMN knowledge_base_version.is_cloud_search IS '是否走云端大模型渲染 Y是 N否';
COMMENT ON COLUMN knowledge_base_version.is_markdown IS '是否Markdown格式输出 Y是 N否';
COMMENT ON COLUMN knowledge_base_version.is_online_search IS '是否走云端查询 Y是 N否';
COMMENT ON COLUMN knowledge_base_version.is_client_search IS '是否走客户端查询 Y是 N否';
COMMENT ON COLUMN knowledge_base_version.user_prompt IS '用户提示词';
COMMENT ON COLUMN knowledge_base_version.split_strategy_param IS '知识库拆分策略参数';
COMMENT ON COLUMN knowledge_base_version.business_experience IS '业务经验知识';
ALTER TABLE knowledge_base_version ADD CONSTRAINT knowledge_base_version_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_black_params_config (
    id integer DEFAULT nextval('knowledge_black_params_config_id_seq'::regclass) NOT NULL,
    relate_knowledge_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    param_no character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    param_code character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    param_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    param_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    param_desc character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    param_value character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    param_status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    relate_dict_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    relate_source_param character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    relate_param_code character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    relate_param_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    show_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    sort_no character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    input_time character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    relate_dict_value character varying(1000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_black_params_config IS '知识库黑盒参数配置表';
COMMENT ON COLUMN knowledge_black_params_config.id IS '主键ID';
COMMENT ON COLUMN knowledge_black_params_config.relate_knowledge_id IS '关联知识库ID';
COMMENT ON COLUMN knowledge_black_params_config.param_no IS '关联参数ID';
COMMENT ON COLUMN knowledge_black_params_config.param_code IS '参数编码';
COMMENT ON COLUMN knowledge_black_params_config.param_type IS '参数类型';
COMMENT ON COLUMN knowledge_black_params_config.param_name IS '参数名称';
COMMENT ON COLUMN knowledge_black_params_config.param_desc IS '参数说明';
COMMENT ON COLUMN knowledge_black_params_config.param_value IS '参数值';
COMMENT ON COLUMN knowledge_black_params_config.param_status IS '参数状态 N无效 Y有效';
COMMENT ON COLUMN knowledge_black_params_config.relate_dict_id IS '关联数据字典ID';
COMMENT ON COLUMN knowledge_black_params_config.relate_source_param IS '关联细类参数';
COMMENT ON COLUMN knowledge_black_params_config.relate_param_code IS '关联细类参数编码';
COMMENT ON COLUMN knowledge_black_params_config.relate_param_name IS '关联细类参数名称';
COMMENT ON COLUMN knowledge_black_params_config.show_name IS '前端展示参数名称';
COMMENT ON COLUMN knowledge_black_params_config.sort_no IS '排序';
COMMENT ON COLUMN knowledge_black_params_config.input_time IS '登记日期';
COMMENT ON COLUMN knowledge_black_params_config.update_time IS '更新日期';
COMMENT ON COLUMN knowledge_black_params_config.relate_dict_value IS '关联数据字段值';
ALTER TABLE knowledge_black_params_config ADD CONSTRAINT knowledge_black_params_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_black_params_config_version (
    id integer DEFAULT nextval('knowledge_black_params_config_version_id_seq'::regclass) NOT NULL,
    relate_knowledge_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    version_no character varying(100) COLLATE "C" NOT NULL,
    param_no character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    param_code character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    param_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    param_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    param_desc character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    param_value character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    param_status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    relate_dict_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    relate_source_param character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    relate_param_code character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    relate_param_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    show_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    sort_no character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    input_time character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    relate_dict_value character varying(1000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_black_params_config_version IS '知识库黑盒参数配置版本记录表';
COMMENT ON COLUMN knowledge_black_params_config_version.id IS '主键ID';
COMMENT ON COLUMN knowledge_black_params_config_version.relate_knowledge_id IS '关联知识库ID';
COMMENT ON COLUMN knowledge_black_params_config_version.version_no IS '版本号';
COMMENT ON COLUMN knowledge_black_params_config_version.param_no IS '关联参数ID';
COMMENT ON COLUMN knowledge_black_params_config_version.param_code IS '参数编码';
COMMENT ON COLUMN knowledge_black_params_config_version.param_type IS '参数类型';
COMMENT ON COLUMN knowledge_black_params_config_version.param_name IS '参数名称';
COMMENT ON COLUMN knowledge_black_params_config_version.param_desc IS '参数说明';
COMMENT ON COLUMN knowledge_black_params_config_version.param_value IS '参数值';
COMMENT ON COLUMN knowledge_black_params_config_version.param_status IS '参数状态 N无效 Y有效';
COMMENT ON COLUMN knowledge_black_params_config_version.relate_dict_id IS '关联数据字典ID';
COMMENT ON COLUMN knowledge_black_params_config_version.relate_source_param IS '关联细类参数';
COMMENT ON COLUMN knowledge_black_params_config_version.relate_param_code IS '关联细类参数编码';
COMMENT ON COLUMN knowledge_black_params_config_version.relate_param_name IS '关联细类参数名称';
COMMENT ON COLUMN knowledge_black_params_config_version.show_name IS '前端展示参数名称';
COMMENT ON COLUMN knowledge_black_params_config_version.sort_no IS '排序';
COMMENT ON COLUMN knowledge_black_params_config_version.input_time IS '登记日期';
COMMENT ON COLUMN knowledge_black_params_config_version.update_time IS '更新日期';
COMMENT ON COLUMN knowledge_black_params_config_version.relate_dict_value IS '关联数据字段值';
ALTER TABLE knowledge_black_params_config_version ADD CONSTRAINT knowledge_black_params_config_version_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_query_result (
    id character varying(100) COLLATE "C" NOT NULL,
    trace_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    supplier_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intf_no character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intf_param text,
    script_sql text,
    sql_param text,
    query_status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    query_type integer DEFAULT 0,
    query_result text,
    query_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    cost_time integer,
    comment character varying(500) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_query_result IS '知识库查询记录表';
COMMENT ON COLUMN knowledge_query_result.trace_id IS '追踪ID';
COMMENT ON COLUMN knowledge_query_result.knowledge_code IS '关联知识库编码';
COMMENT ON COLUMN knowledge_query_result.supplier_id IS '服务编号';
COMMENT ON COLUMN knowledge_query_result.intf_no IS '接口编号';
COMMENT ON COLUMN knowledge_query_result.intf_param IS '接口请求参数';
COMMENT ON COLUMN knowledge_query_result.script_sql IS 'sql脚本';
COMMENT ON COLUMN knowledge_query_result.sql_param IS 'sql脚本关联参数';
COMMENT ON COLUMN knowledge_query_result.query_status IS '请求状态; Y成功 ; N失败';
COMMENT ON COLUMN knowledge_query_result.query_type IS '查询类型0未知 1接口 2数据源';
COMMENT ON COLUMN knowledge_query_result.query_result IS '请求结果';
COMMENT ON COLUMN knowledge_query_result.query_time IS '请求时间';
COMMENT ON COLUMN knowledge_query_result.cost_time IS '花费时间;请求总耗时，单位毫秒';
COMMENT ON COLUMN knowledge_query_result.comment IS '备注';
ALTER TABLE knowledge_query_result ADD CONSTRAINT knowledge_query_result_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_query_result_for_batch (
    id integer DEFAULT nextval('knowledge_query_result_for_batch_id_seq'::regclass) NOT NULL,
    trace_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    supplier_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intf_no character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    intf_param text,
    script_sql character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    sql_param character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    query_status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    query_type integer DEFAULT 0,
    query_result text,
    query_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    cost_time integer,
    comment character varying(500) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_query_result_for_batch IS '知识库查批量询记录表';
COMMENT ON COLUMN knowledge_query_result_for_batch.trace_id IS '追踪ID';
COMMENT ON COLUMN knowledge_query_result_for_batch.knowledge_code IS '关联知识库编码';
COMMENT ON COLUMN knowledge_query_result_for_batch.supplier_id IS '服务编号';
COMMENT ON COLUMN knowledge_query_result_for_batch.intf_no IS '接口编号';
COMMENT ON COLUMN knowledge_query_result_for_batch.intf_param IS '接口请求参数';
COMMENT ON COLUMN knowledge_query_result_for_batch.script_sql IS 'sql脚本';
COMMENT ON COLUMN knowledge_query_result_for_batch.sql_param IS 'sql脚本关联参数';
COMMENT ON COLUMN knowledge_query_result_for_batch.query_status IS '请求状态; Y成功 ; N失败';
COMMENT ON COLUMN knowledge_query_result_for_batch.query_type IS '查询类型0未知 1接口 2数据源';
COMMENT ON COLUMN knowledge_query_result_for_batch.query_result IS '请求结果';
COMMENT ON COLUMN knowledge_query_result_for_batch.query_time IS '请求时间';
COMMENT ON COLUMN knowledge_query_result_for_batch.cost_time IS '花费时间;请求总耗时，单位毫秒';
COMMENT ON COLUMN knowledge_query_result_for_batch.comment IS '备注';
ALTER TABLE knowledge_query_result_for_batch ADD CONSTRAINT knowledge_query_result_for_batch_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_relate_index (
    id integer DEFAULT nextval('knowledge_relate_index_id_seq'::regclass) NOT NULL,
    knowledge_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    index_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    parent_index_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    index_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    index_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    supplier_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    intf_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    add_type character varying(20) COLLATE "C" DEFAULT 'add'::character varying,
    trace_status character(2) COLLATE "C" DEFAULT 'N'::bpchar NOT NULL,
    trace_card_status character(2) COLLATE "C" DEFAULT 'N'::bpchar NOT NULL,
    trace_config text,
    input_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_relate_index IS '知识库关联指标信息';
COMMENT ON COLUMN knowledge_relate_index.id IS '主键ID';
COMMENT ON COLUMN knowledge_relate_index.knowledge_id IS '知识库ID';
COMMENT ON COLUMN knowledge_relate_index.index_no IS '指标编号';
COMMENT ON COLUMN knowledge_relate_index.parent_index_no IS '父级指标编号';
COMMENT ON COLUMN knowledge_relate_index.index_name IS '指标名称';
COMMENT ON COLUMN knowledge_relate_index.index_type IS '指标类型';
COMMENT ON COLUMN knowledge_relate_index.supplier_id IS '关联接口服务ID';
COMMENT ON COLUMN knowledge_relate_index.intf_no IS '关联接口编号';
COMMENT ON COLUMN knowledge_relate_index.add_type IS '添加类型 add-新增，bland-知识库绑定';
COMMENT ON COLUMN knowledge_relate_index.trace_status IS '是否溯源 Y：是，N：否';
COMMENT ON COLUMN knowledge_relate_index.trace_card_status IS '是否溯源卡片 Y：是，N：否';
COMMENT ON COLUMN knowledge_relate_index.trace_config IS '溯源配置';
COMMENT ON COLUMN knowledge_relate_index.input_time IS '创建时间';
COMMENT ON COLUMN knowledge_relate_index.update_time IS '更新时间';
ALTER TABLE knowledge_relate_index ADD CONSTRAINT knowledge_relate_index_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_relate_index_version (
    id integer DEFAULT nextval('knowledge_relate_index_version_id_seq'::regclass) NOT NULL,
    knowledge_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    version_no character varying(100) COLLATE "C" NOT NULL,
    index_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    parent_index_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    index_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    index_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    supplier_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    intf_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    add_type character varying(20) COLLATE "C" DEFAULT 'add'::character varying,
    trace_status character(2) COLLATE "C" DEFAULT 'N'::bpchar NOT NULL,
    trace_card_status character(2) COLLATE "C" DEFAULT 'N'::bpchar NOT NULL,
    trace_config text,
    input_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_relate_index_version IS '知识库关联指标版本记录表';
COMMENT ON COLUMN knowledge_relate_index_version.id IS '主键ID';
COMMENT ON COLUMN knowledge_relate_index_version.knowledge_id IS '知识库ID';
COMMENT ON COLUMN knowledge_relate_index_version.version_no IS '版本号';
COMMENT ON COLUMN knowledge_relate_index_version.index_no IS '指标编号';
COMMENT ON COLUMN knowledge_relate_index_version.parent_index_no IS '父级指标编号';
COMMENT ON COLUMN knowledge_relate_index_version.index_name IS '指标名称';
COMMENT ON COLUMN knowledge_relate_index_version.index_type IS '指标类型';
COMMENT ON COLUMN knowledge_relate_index_version.supplier_id IS '关联接口服务ID';
COMMENT ON COLUMN knowledge_relate_index_version.intf_no IS '关联接口编号';
COMMENT ON COLUMN knowledge_relate_index_version.add_type IS '添加类型 add-新增，bland-知识库绑定';
COMMENT ON COLUMN knowledge_relate_index_version.trace_status IS '是否溯源 Y：是，N：否';
COMMENT ON COLUMN knowledge_relate_index_version.trace_card_status IS '是否溯源卡片 Y：是，N：否';
COMMENT ON COLUMN knowledge_relate_index_version.trace_config IS '溯源配置';
COMMENT ON COLUMN knowledge_relate_index_version.input_time IS '创建时间';
COMMENT ON COLUMN knowledge_relate_index_version.update_time IS '更新时间';
ALTER TABLE knowledge_relate_index_version ADD CONSTRAINT knowledge_relate_index_version_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_relate_input_param (
    id character varying(32) COLLATE "C" NOT NULL,
    knowledge_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    input_param character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    input_param_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_relate_input_param IS '知识库关联参数集';
COMMENT ON COLUMN knowledge_relate_input_param.id IS '主键ID';
COMMENT ON COLUMN knowledge_relate_input_param.knowledge_id IS '知识库ID';
COMMENT ON COLUMN knowledge_relate_input_param.input_param IS '参数集';
COMMENT ON COLUMN knowledge_relate_input_param.input_param_name IS '参数集名称';
COMMENT ON COLUMN knowledge_relate_input_param.input_time IS '创建时间';
COMMENT ON COLUMN knowledge_relate_input_param.update_time IS '更新时间';
ALTER TABLE knowledge_relate_input_param ADD CONSTRAINT knowledge_relate_input_param_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_relate_input_param_version (
    id character varying(32) COLLATE "C" NOT NULL,
    knowledge_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    version_no character varying(100) COLLATE "C" NOT NULL,
    input_param character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    input_param_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    input_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_relate_input_param_version IS '知识库关联参数集版本记录表';
COMMENT ON COLUMN knowledge_relate_input_param_version.id IS '主键ID';
COMMENT ON COLUMN knowledge_relate_input_param_version.knowledge_id IS '知识库ID';
COMMENT ON COLUMN knowledge_relate_input_param_version.version_no IS '版本号';
COMMENT ON COLUMN knowledge_relate_input_param_version.input_param IS '参数集';
COMMENT ON COLUMN knowledge_relate_input_param_version.input_param_name IS '参数集名称';
COMMENT ON COLUMN knowledge_relate_input_param_version.input_time IS '创建时间';
COMMENT ON COLUMN knowledge_relate_input_param_version.update_time IS '更新时间';
ALTER TABLE knowledge_relate_input_param_version ADD CONSTRAINT knowledge_relate_input_param_version_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_sync_task (
    id character varying(32) COLLATE "C" NOT NULL,
    sync_type character varying(32) COLLATE "C" NOT NULL,
    sync_status character varying(20) COLLATE "C" DEFAULT 'new'::character varying NOT NULL,
    user_id character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    user_name character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    input_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    finish_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    cost_time integer DEFAULT 0 NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_sync_task IS '知识库同步任务记录表';
COMMENT ON COLUMN knowledge_sync_task.id IS '主键id';
COMMENT ON COLUMN knowledge_sync_task.sync_type IS 'knowledge-知识库同步, index-指标同步, apiSource-API数据源同步, dataSource-SQL数据源';
COMMENT ON COLUMN knowledge_sync_task.sync_status IS 'new-新建任务；processing-同步中；success-同步成功；failed-同步失败；';
COMMENT ON COLUMN knowledge_sync_task.user_id IS '同步用户ID';
COMMENT ON COLUMN knowledge_sync_task.user_name IS '同步用户名称';
COMMENT ON COLUMN knowledge_sync_task.input_time IS '创建时间';
COMMENT ON COLUMN knowledge_sync_task.finish_time IS '完成时间';
COMMENT ON COLUMN knowledge_sync_task.cost_time IS '耗时（毫秒）';
ALTER TABLE knowledge_sync_task ADD CONSTRAINT knowledge_sync_task_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE knowledge_sync_task_exception_record (
    id character varying(32) COLLATE "C" NOT NULL,
    task_id character varying(32) COLLATE "C" NOT NULL,
    exception_stage character varying(100) COLLATE "C" NOT NULL,
    input_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    fail_reason text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE knowledge_sync_task_exception_record IS '知识库同步任务异常记录表';
COMMENT ON COLUMN knowledge_sync_task_exception_record.id IS '主键id';
COMMENT ON COLUMN knowledge_sync_task_exception_record.task_id IS '任务id';
COMMENT ON COLUMN knowledge_sync_task_exception_record.exception_stage IS '异常阶段：init-数据查询阶段；knowledge-同步知识库配置阶段；knowledge_relate_index-同步知识库溯源阶段；knowledge_black_params-同步知识库黑盒参数阶段；knowledge_input_param-同步知识库参数集阶段；knowledge_group-同步知识库分组阶段；index-同步指标配置阶段；index_group-同步指标分组阶段；source-同步数据源阶段；';
COMMENT ON COLUMN knowledge_sync_task_exception_record.input_time IS '创建时间';
COMMENT ON COLUMN knowledge_sync_task_exception_record.fail_reason IS '失败原因';
ALTER TABLE knowledge_sync_task_exception_record ADD CONSTRAINT knowledge_sync_task_exception_record_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE large_model_config (
    id integer DEFAULT nextval('large_model_config_id_seq'::regclass) NOT NULL,
    lm_code character varying(100) COLLATE "C" NOT NULL,
    model character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    lm_name character varying(256) COLLATE "C" DEFAULT NULL::character varying,
    url character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    api_key character varying(5000) COLLATE "C" DEFAULT NULL::character varying,
    lm_desc text,
    use_flag character varying(2) COLLATE "C" DEFAULT 'Y'::character varying NOT NULL,
    with_think character varying(10) COLLATE "C" DEFAULT 'N'::character varying,
    default_think_flag character varying(4) COLLATE "C" DEFAULT 'N'::character varying,
    max_tokens integer DEFAULT 0,
    create_time timestamp without time zone DEFAULT pg_systimestamp(),
    update_time timestamp without time zone DEFAULT pg_systimestamp(),
    model_config text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN large_model_config.id IS '大模型唯一ID';
COMMENT ON COLUMN large_model_config.lm_code IS '大模型唯一CODE';
COMMENT ON COLUMN large_model_config.model IS '模型';
COMMENT ON COLUMN large_model_config.lm_name IS '大模型名称';
COMMENT ON COLUMN large_model_config.url IS '大模型地址URL';
COMMENT ON COLUMN large_model_config.api_key IS 'api key';
COMMENT ON COLUMN large_model_config.lm_desc IS '大模型描述';
COMMENT ON COLUMN large_model_config.use_flag IS '有效标志位';
COMMENT ON COLUMN large_model_config.with_think IS '是否带思考';
COMMENT ON COLUMN large_model_config.default_think_flag IS '默认是否开启思考, Y:开启,N:不开启';
COMMENT ON COLUMN large_model_config.max_tokens IS '最大token数';
COMMENT ON COLUMN large_model_config.create_time IS '创建时间';
COMMENT ON COLUMN large_model_config.update_time IS '更新时间';
COMMENT ON COLUMN large_model_config.model_config IS '模型配置';
ALTER TABLE large_model_config ADD CONSTRAINT large_model_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE largemodel_queue (
    queueid character varying(100) COLLATE "C" NOT NULL,
    hubaccount character varying(100) COLLATE "C" NOT NULL,
    modulecode character varying(300) COLLATE "C" NOT NULL,
    largemodelcode character varying(300) COLLATE "C" NOT NULL,
    largemodelreqkey character varying(300) COLLATE "C" NOT NULL,
    processstatus character varying(300) COLLATE "C" DEFAULT 'ready'::character varying NOT NULL,
    queuereason character varying(300) COLLATE "C" DEFAULT NULL::character varying,
    begintime character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    endtime character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    inputtime character varying(20) COLLATE "C" NOT NULL,
    updatetime character varying(20) COLLATE "C" NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE largemodel_queue IS '大模型请求队列表';
COMMENT ON COLUMN largemodel_queue.queueid IS '队列Id';
COMMENT ON COLUMN largemodel_queue.hubaccount IS 'hub账号';
COMMENT ON COLUMN largemodel_queue.modulecode IS '组件code';
COMMENT ON COLUMN largemodel_queue.largemodelcode IS '组件code';
COMMENT ON COLUMN largemodel_queue.largemodelreqkey IS '大模型入参key';
COMMENT ON COLUMN largemodel_queue.processstatus IS '大模型处理状态 ready;running;finish';
COMMENT ON COLUMN largemodel_queue.queuereason IS '加入队列原因';
COMMENT ON COLUMN largemodel_queue.begintime IS '大模型开始时间';
COMMENT ON COLUMN largemodel_queue.endtime IS '大模型开始时间';
COMMENT ON COLUMN largemodel_queue.inputtime IS '入库时间';
COMMENT ON COLUMN largemodel_queue.updatetime IS '更新时间';
ALTER TABLE largemodel_queue ADD CONSTRAINT largemodel_queue_pkey PRIMARY KEY USING ubtree  (queueid) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE llm_batch_analysis_task (
    task_id character varying(32) COLLATE "C" NOT NULL,
    user_id character varying(32) COLLATE "C" NOT NULL,
    prompt text,
    model_codes character varying(2000) COLLATE "C" NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    status character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    failure_reason text,
    evaluation_prompt text,
    total_rounds integer DEFAULT 10 NOT NULL,
    hallucination_check character varying(2) COLLATE "C" DEFAULT 'N'::character varying NOT NULL,
    hallucination_prompt text,
    evaluation_title character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    evaluation_comment text,
    other_relate_prompt text,
    evaluate_model character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    relate_dataset character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    evaluate_dimension character varying(2000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE llm_batch_analysis_task IS '大模型跑批任务表';
COMMENT ON COLUMN llm_batch_analysis_task.task_id IS '任务ID';
COMMENT ON COLUMN llm_batch_analysis_task.user_id IS '用户ID';
COMMENT ON COLUMN llm_batch_analysis_task.prompt IS '文案提示词';
COMMENT ON COLUMN llm_batch_analysis_task.model_codes IS '模型列表';
COMMENT ON COLUMN llm_batch_analysis_task.start_time IS '开始时间';
COMMENT ON COLUMN llm_batch_analysis_task.end_time IS '结束时间';
COMMENT ON COLUMN llm_batch_analysis_task.status IS '任务状态：init(初始化), running(跑中), success(全部跑完), failed(全部跑完但失败)';
COMMENT ON COLUMN llm_batch_analysis_task.failure_reason IS '失败原因';
COMMENT ON COLUMN llm_batch_analysis_task.evaluation_prompt IS '效果评估提示词';
COMMENT ON COLUMN llm_batch_analysis_task.total_rounds IS '执行次数';
COMMENT ON COLUMN llm_batch_analysis_task.hallucination_check IS '是否同步进行模型幻觉校验 N否 Y是';
COMMENT ON COLUMN llm_batch_analysis_task.hallucination_prompt IS '幻觉检查提示词';
COMMENT ON COLUMN llm_batch_analysis_task.evaluation_title IS ' 评估标题';
COMMENT ON COLUMN llm_batch_analysis_task.other_relate_prompt IS '其它关联提示词：value_hallucination_prompt-数值幻觉提示词，incorrect_meaning_prompt-曲解原义提示词，value_judgment_prompt-价值判断提示词，style_matching_prompt-文风适配提示词';
COMMENT ON COLUMN llm_batch_analysis_task.evaluate_model IS '评估模型';
COMMENT ON COLUMN llm_batch_analysis_task.relate_dataset IS '关联测试集';
COMMENT ON COLUMN llm_batch_analysis_task.evaluate_dimension IS '评估维度';
ALTER TABLE llm_batch_analysis_task ADD CONSTRAINT llm_batch_analysis_task_pkey PRIMARY KEY USING ubtree  (task_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE llm_batch_analysis_task_detail (
    task_id character varying(32) COLLATE "C" NOT NULL,
    model_code character varying(128) COLLATE "C" NOT NULL,
    round_num integer NOT NULL,
    model_result text,
    hallucination_result text,
    evaluation_result text,
    start_time character varying(40) COLLATE "C" NOT NULL,
    model_end_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    evaluation_end_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    hallucination_end_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    evaluation_score json,
    failure_reason text,
    evaluation_status character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    hallucination_status character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    evaluation_comment text,
    dataset_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(100) COLLATE "C" DEFAULT ''::character varying,
    prompt_code character varying(200) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    dataset_uid character varying(32) COLLATE "C" DEFAULT ''::character varying NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE llm_batch_analysis_task_detail IS '大模型跑批任务明细表';
COMMENT ON COLUMN llm_batch_analysis_task_detail.task_id IS '任务ID';
COMMENT ON COLUMN llm_batch_analysis_task_detail.model_code IS '模型编码';
COMMENT ON COLUMN llm_batch_analysis_task_detail.round_num IS '轮次';
COMMENT ON COLUMN llm_batch_analysis_task_detail.hallucination_result IS '幻觉检查结果';
COMMENT ON COLUMN llm_batch_analysis_task_detail.evaluation_result IS '评估结果';
COMMENT ON COLUMN llm_batch_analysis_task_detail.start_time IS '开始时间';
COMMENT ON COLUMN llm_batch_analysis_task_detail.model_end_time IS '模型结束时间';
COMMENT ON COLUMN llm_batch_analysis_task_detail.evaluation_end_time IS '评估结束时间';
COMMENT ON COLUMN llm_batch_analysis_task_detail.hallucination_end_time IS '幻觉检查结束时间';
COMMENT ON COLUMN llm_batch_analysis_task_detail.status IS '任务状态：init(初始化), analyzing(大模型分析中:模型生成), analysis_success(大模型分析成功), analysis_failed(大模型分析失败)';
COMMENT ON COLUMN llm_batch_analysis_task_detail.evaluation_score IS '多维度打分';
COMMENT ON COLUMN llm_batch_analysis_task_detail.evaluation_status IS '任务状态：evaluating(大模型评估中),evaluation_failed(大模型评估失败), evaluation_success(大模型评估成功)';
COMMENT ON COLUMN llm_batch_analysis_task_detail.hallucination_status IS '任务状态：reviewing(幻觉检查中), review_success(幻觉检查成功), review_failed(幻觉检查失败)';
COMMENT ON COLUMN llm_batch_analysis_task_detail.dataset_id IS '测试集ID';
COMMENT ON COLUMN llm_batch_analysis_task_detail.ent_name IS '企业名称';
COMMENT ON COLUMN llm_batch_analysis_task_detail.prompt_code IS '提示词编号';
COMMENT ON COLUMN llm_batch_analysis_task_detail.dataset_uid IS '数据集uuid';
ALTER TABLE llm_batch_analysis_task_detail ADD CONSTRAINT llm_batch_analysis_task_detail_pkey PRIMARY KEY USING ubtree  (task_id, model_code, round_num, dataset_uid, prompt_code) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE llm_batch_analysis_task_hallucination (
    task_id character varying(32) COLLATE "C" NOT NULL,
    model_code character varying(128) COLLATE "C" NOT NULL,
    round_num integer NOT NULL,
    sequence_num character varying(36) COLLATE "C" NOT NULL,
    hallucination_type text,
    hallucination_desc text,
    evaluation_source character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    manual_review_result character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    reviewer character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    review_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    review_notes text,
    prompt_code character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE llm_batch_analysis_task_hallucination IS '大模型跑批任务明细幻觉信息表';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.task_id IS '任务ID';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.model_code IS '模型编码';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.round_num IS '轮次';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.sequence_num IS '序列编号';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.hallucination_type IS '幻觉类型：数值错误、曲解原义、存在无意义观点';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.hallucination_desc IS '幻觉描述';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.evaluation_source IS '评估来源';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.manual_review_result IS '人工审核结果';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.reviewer IS '审核人';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.review_time IS '审核时间';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.review_notes IS '审核备注';
COMMENT ON COLUMN llm_batch_analysis_task_hallucination.prompt_code IS '提示词编号';
ALTER TABLE llm_batch_analysis_task_hallucination ADD CONSTRAINT llm_batch_analysis_task_hallucination_pkey PRIMARY KEY USING ubtree  (task_id, model_code, round_num, sequence_num) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE llm_evaluate_dataset_management (
    id character varying(32) COLLATE "C" NOT NULL,
    dataset_code character varying(100) COLLATE "C" NOT NULL,
    dataset_desc text,
    input_time timestamp without time zone DEFAULT pg_systimestamp(),
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE llm_evaluate_dataset_management IS '大模型评估测试集';
COMMENT ON COLUMN llm_evaluate_dataset_management.id IS '主键ID';
COMMENT ON COLUMN llm_evaluate_dataset_management.dataset_code IS '测试集编号';
COMMENT ON COLUMN llm_evaluate_dataset_management.dataset_desc IS '测试集描述';
COMMENT ON COLUMN llm_evaluate_dataset_management.input_time IS '创建时间';
COMMENT ON COLUMN llm_evaluate_dataset_management.create_by IS '创建人';
COMMENT ON COLUMN llm_evaluate_dataset_management.update_time IS '更新时间';
COMMENT ON COLUMN llm_evaluate_dataset_management.update_by IS '更新人';
ALTER TABLE llm_evaluate_dataset_management ADD CONSTRAINT llm_evaluate_dataset_management_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE llm_evaluate_dataset_management_detail (
    id character varying(32) COLLATE "C" NOT NULL,
    dataset_id character varying(32) COLLATE "C" NOT NULL,
    ent_name character varying(100) COLLATE "C" NOT NULL,
    prompt_code character varying(100) COLLATE "C" NOT NULL,
    prompt text,
    expected_output text,
    input_time timestamp without time zone DEFAULT pg_systimestamp(),
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    requirements text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE llm_evaluate_dataset_management_detail IS '大模型评估测试集明细';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.id IS '主键ID';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.dataset_id IS '测试集ID';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.ent_name IS '企业名称';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.prompt_code IS '编号';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.prompt IS '提示词内容';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.expected_output IS '预期输出内容';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.input_time IS '创建时间';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.create_by IS '创建人';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.update_time IS '更新时间';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.update_by IS '更新人';
COMMENT ON COLUMN llm_evaluate_dataset_management_detail.requirements IS '输出要求';
ALTER TABLE llm_evaluate_dataset_management_detail ADD CONSTRAINT ent_code_idx UNIQUE USING ubtree (ent_name, prompt_code, dataset_id) WITH (storage_type=USTORE);
ALTER TABLE llm_evaluate_dataset_management_detail ADD CONSTRAINT llm_evaluate_dataset_management_detail_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE login_verfication_code (
    id character varying(64) COLLATE "C" NOT NULL,
    user_id character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    verfication_code character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    input_time character varying(50) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN login_verfication_code.user_id IS '用户id';
COMMENT ON COLUMN login_verfication_code.verfication_code IS '验证码';
COMMENT ON COLUMN login_verfication_code.input_time IS '插入时间';
ALTER TABLE login_verfication_code ADD CONSTRAINT login_verfication_code_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE message_push_config (
    id integer DEFAULT nextval('message_push_config_id_seq'::regclass) NOT NULL,
    content_text text,
    input_time character varying(40) COLLATE "C" NOT NULL,
    update_time character varying(40) COLLATE "C" NOT NULL,
    push_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    push_channel character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    push_flag character varying(2) COLLATE "C" DEFAULT '1'::character varying,
    push_status character varying(2) COLLATE "C" DEFAULT '1'::character varying,
    remark character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    title character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE message_push_config IS '消息推送配置表';
COMMENT ON COLUMN message_push_config.id IS '主键ID';
COMMENT ON COLUMN message_push_config.content_text IS '消息文本内容';
COMMENT ON COLUMN message_push_config.input_time IS '入库时间';
COMMENT ON COLUMN message_push_config.update_time IS '更新时间';
COMMENT ON COLUMN message_push_config.push_time IS '推送时间';
COMMENT ON COLUMN message_push_config.push_channel IS '推送渠道';
COMMENT ON COLUMN message_push_config.push_flag IS '是否推送;0否 1是';
COMMENT ON COLUMN message_push_config.push_status IS '推送状态;1待推送 2已推送 3定时推送';
COMMENT ON COLUMN message_push_config.remark IS '备注';
COMMENT ON COLUMN message_push_config.title IS '消息标题';
ALTER TABLE message_push_config ADD CONSTRAINT message_push_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE message_relate_account (
    id integer DEFAULT nextval('message_relate_account_id_seq'::regclass) NOT NULL,
    message_id integer,
    account_id integer,
    relate_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    relate_status character varying(2) COLLATE "C" DEFAULT '1'::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE message_relate_account IS '消息推送关联机构表';
COMMENT ON COLUMN message_relate_account.id IS '主键ID';
COMMENT ON COLUMN message_relate_account.message_id IS '消息ID';
COMMENT ON COLUMN message_relate_account.account_id IS '关联账号ID';
COMMENT ON COLUMN message_relate_account.relate_time IS '关联时间';
COMMENT ON COLUMN message_relate_account.relate_status IS '关联状态;1已关联 2已取消';
ALTER TABLE message_relate_account ADD CONSTRAINT message_relate_account_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE module_code_prompt_cache (
    module_code character varying(200) COLLATE "C" NOT NULL,
    module_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    params text,
    params_md5 character varying(200) COLLATE "C" NOT NULL,
    prompt text,
    status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE module_code_prompt_cache IS '知识库文案缓存表';
COMMENT ON COLUMN module_code_prompt_cache.module_code IS '知识库编码';
COMMENT ON COLUMN module_code_prompt_cache.module_name IS '知识库名称';
COMMENT ON COLUMN module_code_prompt_cache.params IS '请求参数';
COMMENT ON COLUMN module_code_prompt_cache.params_md5 IS '请求参数md5';
COMMENT ON COLUMN module_code_prompt_cache.prompt IS '文案内容';
COMMENT ON COLUMN module_code_prompt_cache.status IS '缓存状态;Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN module_code_prompt_cache.create_time IS '创建时间';
COMMENT ON COLUMN module_code_prompt_cache.update_time IS '更新时间';
ALTER TABLE module_code_prompt_cache ADD CONSTRAINT module_code_prompt_cache_pkey PRIMARY KEY USING ubtree  (module_code, params_md5) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE ocr_parse_task (
    task_id character varying(64) COLLATE "C" NOT NULL,
    file_name character varying(512) COLLATE "C" NOT NULL,
    file_type character varying(32) COLLATE "C" NOT NULL,
    status character varying(32) COLLATE "C" NOT NULL,
    source_file_path character varying(1024) COLLATE "C" NOT NULL,
    storage_type character varying(32) COLLATE "C" NOT NULL,
    result text,
    result_content_json text,
    error text,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
ALTER TABLE ocr_parse_task ADD CONSTRAINT ocr_parse_task_pkey PRIMARY KEY USING ubtree  (task_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE open_api_conf (
    id character varying(32) COLLATE "C" NOT NULL,
    provider_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    api_code character varying(50) COLLATE "C" NOT NULL,
    api_type character varying(50) COLLATE "C" NOT NULL,
    api_desc character varying(500) COLLATE "C" NOT NULL,
    api_category_code character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    upstream_path character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    http_method character varying(10) COLLATE "C" NOT NULL,
    message_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    header character varying(3000) COLLATE "C" DEFAULT NULL::character varying,
    request_param character varying(3000) COLLATE "C" NOT NULL,
    success_code_field character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    success_code_value character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    response_biz_data_field character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    response_biz_data_type character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    response_param character varying(3000) COLLATE "C" DEFAULT NULL::character varying,
    stream_flag character varying(5) COLLATE "C" DEFAULT 'false'::character varying,
    create_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    api_name character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE open_api_conf IS 'api_openapi定义';
COMMENT ON COLUMN open_api_conf.id IS '主键';
COMMENT ON COLUMN open_api_conf.provider_id IS '关联供应商ID，针对第三方接口，参考ext_intf_supplier_manage表的supplier_id，针对hub接口填固定值hub、custom接口固定值custom，知识库接口固定值knowledge';
COMMENT ON COLUMN open_api_conf.api_code IS 'api接口编号';
COMMENT ON COLUMN open_api_conf.api_type IS 'api类型，枚举值：hub、knowledge、custom（针对智能体封装的python工具服务）、third(其他第三方上游接口)';
COMMENT ON COLUMN open_api_conf.api_desc IS 'api接口描述';
COMMENT ON COLUMN open_api_conf.api_category_code IS 'api业务分类编号,同一个业务分类下，provider_id必须相同。针对custom自定义服务，此值必填';
COMMENT ON COLUMN open_api_conf.upstream_path IS '上游API路径（拼接在base_url后）,针对hub接口配置为具体的填trans_code编号，针对知识库作为工具使用，填具体的module_code';
COMMENT ON COLUMN open_api_conf.http_method IS '请求方式：GET/POST/PUT/DELETE';
COMMENT ON COLUMN open_api_conf.message_type IS '针对provider_id为第三方接口且为POST请求时，需要设置该值：支持json、form两种方式，不填默认就是json';
COMMENT ON COLUMN open_api_conf.header IS '请求头，json array格式，格式为[{name:请求头的名称,value:请求头的值}]，每个请求头对应一个jsonarray元素的定义';
COMMENT ON COLUMN open_api_conf.request_param IS '请求参数定义，格式统一，json array格式定义，每个元素为json对象，有属性： name、type、desc、required、defaultValue、toolParamFlag(boolean型，true表示为工具参数，false表示不是工具参数，open api生成时，不会输出该参数定义)、location(表示参数所在位置，枚举值：headerqueryodypath)、enums(枚举值，jsonarray，每个元素为字符串)';
COMMENT ON COLUMN open_api_conf.success_code_field IS '接口调用响应业务成功码字段，针对api_ytpe等于other时，必填';
COMMENT ON COLUMN open_api_conf.success_code_value IS '接口调用响应业务成功码字段对应的成功码值，针对api_ytpe等于other时，必填';
COMMENT ON COLUMN open_api_conf.response_biz_data_field IS '成功响应时的业务数据根字段';
COMMENT ON COLUMN open_api_conf.response_biz_data_type IS '成功响应时的业务数据类型，枚举值:object（对象）、array（数组）';
COMMENT ON COLUMN open_api_conf.response_param IS '响应参数字段定义，格式统一，json array格式定义，每个元素为json对象，案例[{name:字段名,desc:字段描述,type:数据类型-枚举类型：string（字符串）、number(数字)、boolean（布尔类型）、array（数组、里面的元素只能是基础类型）}]';
COMMENT ON COLUMN open_api_conf.stream_flag IS '是否流式接口，主要针对custom自定义工具接口，默认false';
COMMENT ON COLUMN open_api_conf.create_time IS '创建时间';
COMMENT ON COLUMN open_api_conf.create_by IS '创建人';
COMMENT ON COLUMN open_api_conf.update_time IS '更新时间';
COMMENT ON COLUMN open_api_conf.update_by IS '更新人';
COMMENT ON COLUMN open_api_conf.api_name IS '工具展示中文名';
ALTER TABLE open_api_conf ADD CONSTRAINT idx_api_code UNIQUE USING ubtree (api_code) WITH (storage_type=USTORE);
ALTER TABLE open_api_conf ADD CONSTRAINT open_api_conf_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE package_agent_index_config (
    id character varying(32) COLLATE "C" NOT NULL,
    index_name character varying(100) COLLATE "C" NOT NULL,
    index_code character varying(32) COLLATE "C" NOT NULL,
    index_topic character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    use_flag character varying(1) COLLATE "C" DEFAULT 'Y'::character varying NOT NULL,
    synonym_word text,
    key_word text,
    center_key_word text,
    entity_type character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    inner_priority character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    source_type character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    external_priority character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    rec_group character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    rec_question character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    has_index_rela character varying(1) COLLATE "C" DEFAULT NULL::character varying,
    remark text,
    input_time character varying(40) COLLATE "C" NOT NULL,
    update_time character varying(40) COLLATE "C" NOT NULL,
    index_desc text,
    sample_question text,
    object_type character varying(256) COLLATE "C" DEFAULT NULL::character varying,
    index_classification character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    visible_flag character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    index_prompt text,
    hub_account character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    none_test_flag character varying(100) COLLATE "C" DEFAULT '1'::character varying NOT NULL,
    final_result_flag character varying(1) COLLATE "C" DEFAULT 'N'::character varying,
    rec_enterprise character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    text_type character varying(100) COLLATE "C" DEFAULT 'H5'::character varying,
    source_card_channel character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    large_model_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    large_model_content character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    rela_knowledge_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    large_model_flag character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    is_recommend character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    recommend_weight integer DEFAULT 0
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE package_agent_index_config IS '套餐关联组件配置表';
COMMENT ON COLUMN package_agent_index_config.index_name IS '组件名称';
COMMENT ON COLUMN package_agent_index_config.index_code IS '组件编码';
COMMENT ON COLUMN package_agent_index_config.index_topic IS '组件主题分类';
COMMENT ON COLUMN package_agent_index_config.use_flag IS '是否有效 Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN package_agent_index_config.synonym_word IS '同义词';
COMMENT ON COLUMN package_agent_index_config.key_word IS '关键字';
COMMENT ON COLUMN package_agent_index_config.center_key_word IS '核心关键词';
COMMENT ON COLUMN package_agent_index_config.entity_type IS '主体类型';
COMMENT ON COLUMN package_agent_index_config.inner_priority IS '优先级';
COMMENT ON COLUMN package_agent_index_config.source_type IS '数据来源';
COMMENT ON COLUMN package_agent_index_config.external_priority IS '外部优先级';
COMMENT ON COLUMN package_agent_index_config.rec_group IS '推荐分组';
COMMENT ON COLUMN package_agent_index_config.rec_question IS '推荐问题';
COMMENT ON COLUMN package_agent_index_config.has_index_rela IS '是否有关联组件';
COMMENT ON COLUMN package_agent_index_config.remark IS '备注';
COMMENT ON COLUMN package_agent_index_config.input_time IS '入库时间';
COMMENT ON COLUMN package_agent_index_config.update_time IS '更新时间';
COMMENT ON COLUMN package_agent_index_config.index_desc IS '组件描述';
COMMENT ON COLUMN package_agent_index_config.sample_question IS '实例问题';
COMMENT ON COLUMN package_agent_index_config.object_type IS '企业类型';
COMMENT ON COLUMN package_agent_index_config.index_classification IS '组件分类';
COMMENT ON COLUMN package_agent_index_config.visible_flag IS '是否可见 Y表示是，N表示否，默认Y';
COMMENT ON COLUMN package_agent_index_config.index_prompt IS '组件prompt';
COMMENT ON COLUMN package_agent_index_config.hub_account IS '关联账号';
COMMENT ON COLUMN package_agent_index_config.none_test_flag IS '非测试标志位';
COMMENT ON COLUMN package_agent_index_config.final_result_flag IS '是否无数据舆情兜底 Y表示是 N表示否，默认Y';
COMMENT ON COLUMN package_agent_index_config.rec_enterprise IS '推荐企业';
COMMENT ON COLUMN package_agent_index_config.text_type IS '文本类型';
COMMENT ON COLUMN package_agent_index_config.source_card_channel IS '朔源卡片展示渠道(pc、app)';
COMMENT ON COLUMN package_agent_index_config.large_model_code IS '大模型编码';
COMMENT ON COLUMN package_agent_index_config.large_model_content IS '不同大模型对应的输出要求';
COMMENT ON COLUMN package_agent_index_config.rela_knowledge_id IS '组件关联知识库ID';
COMMENT ON COLUMN package_agent_index_config.large_model_flag IS '是否走大模型标志，默认Y（ N否，Y是 ）';
COMMENT ON COLUMN package_agent_index_config.is_recommend IS '否放入推荐问题池 Y 是 N 否';
COMMENT ON COLUMN package_agent_index_config.recommend_weight IS '推荐问题权重';
ALTER TABLE package_agent_index_config ADD CONSTRAINT package_agent_index_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE post_glm_records (
    id integer DEFAULT nextval('post_glm_records_id_seq'::regclass) NOT NULL,
    question text,
    answer text,
    remark1 character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    remark2 character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    remark3 character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    createtime timestamp without time zone DEFAULT pg_systimestamp(),
    time_cost character varying(400) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE post_glm_records IS '请求glm记录表';
COMMENT ON COLUMN post_glm_records.question IS '问题';
COMMENT ON COLUMN post_glm_records.answer IS '答案';
COMMENT ON COLUMN post_glm_records.remark1 IS '备注1';
COMMENT ON COLUMN post_glm_records.remark2 IS '备注2';
COMMENT ON COLUMN post_glm_records.remark3 IS '备注3';
ALTER TABLE post_glm_records ADD CONSTRAINT post_glm_records_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE prompt_query_result (
    id character varying(32) COLLATE "C" NOT NULL,
    module_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    module_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    ent_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    is_muti_ent character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    query_param text,
    result_mode character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    query_status character varying(1) COLLATE "C" DEFAULT NULL::character varying,
    cost_time integer,
    query_result text,
    fail_reason text,
    query_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    comment character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    trace_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    end_time character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE prompt_query_result IS 'prompt请求结果记录表';
COMMENT ON COLUMN prompt_query_result.module_code IS '模块编码';
COMMENT ON COLUMN prompt_query_result.module_name IS '模块名称';
COMMENT ON COLUMN prompt_query_result.ent_name IS '主体名称';
COMMENT ON COLUMN prompt_query_result.is_muti_ent IS '是否多主体 1是 0否';
COMMENT ON COLUMN prompt_query_result.query_param IS '请求参数';
COMMENT ON COLUMN prompt_query_result.result_mode IS '结果类型;agent：命中agent平台取值方式；prompt：命中prompt平台取值方式';
COMMENT ON COLUMN prompt_query_result.query_status IS '请求状态;1 成功 ; 0 失败';
COMMENT ON COLUMN prompt_query_result.cost_time IS '花费时间;请求总耗时，单位毫秒';
COMMENT ON COLUMN prompt_query_result.fail_reason IS '失败原因';
COMMENT ON COLUMN prompt_query_result.query_time IS '请求时间';
COMMENT ON COLUMN prompt_query_result.comment IS '备注';
COMMENT ON COLUMN prompt_query_result.trace_id IS '追踪ID';
COMMENT ON COLUMN prompt_query_result.end_time IS '请求结束时间';
ALTER TABLE prompt_query_result ADD CONSTRAINT prompt_query_result_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE prompt_verify_running_result_compare_task (
    id character varying(64) COLLATE "C" NOT NULL,
    scene_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    result_id_list character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    standard_result_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    create_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    start_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    end_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    compare_result_summary character varying(2000) COLLATE "C" DEFAULT NULL::character varying,
    compare_result_statistic text,
    status character varying(20) COLLATE "C" DEFAULT 'init'::character varying NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE prompt_verify_running_result_compare_task IS '大模型校验结果对比表';
COMMENT ON COLUMN prompt_verify_running_result_compare_task.id IS '主键ID';
COMMENT ON COLUMN prompt_verify_running_result_compare_task.scene_id IS '场景ID';
COMMENT ON COLUMN prompt_verify_running_result_compare_task.result_id_list IS '任务结果ID集合';
COMMENT ON COLUMN prompt_verify_running_result_compare_task.standard_result_id IS '标准对比结果ID';
COMMENT ON COLUMN prompt_verify_running_result_compare_task.create_time IS '创建时间';
COMMENT ON COLUMN prompt_verify_running_result_compare_task.start_time IS '开始时间';
COMMENT ON COLUMN prompt_verify_running_result_compare_task.end_time IS '结束时间';
COMMENT ON COLUMN prompt_verify_running_result_compare_task.compare_result_summary IS '对比结果';
COMMENT ON COLUMN prompt_verify_running_result_compare_task.status IS '对比状态（ init-初始化状态 running-运行中 success-运行成功 fail-运行失败）';
ALTER TABLE prompt_verify_running_result_compare_task ADD CONSTRAINT prompt_verify_running_result_compare_task_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE prompt_verify_running_task (
    id character varying(64) COLLATE "C" NOT NULL,
    scene_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    prompt_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    prompt_template text,
    task_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    task_desc character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    large_model_code_list character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    create_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    task_status character varying(20) COLLATE "C" DEFAULT 'none'::character varying NOT NULL,
    concurrent_num integer
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE prompt_verify_running_task IS '大模型校验任务表';
COMMENT ON COLUMN prompt_verify_running_task.id IS '主键ID';
COMMENT ON COLUMN prompt_verify_running_task.scene_id IS '场景ID';
COMMENT ON COLUMN prompt_verify_running_task.prompt_id IS '场景关联promptID';
COMMENT ON COLUMN prompt_verify_running_task.task_name IS '任务名称';
COMMENT ON COLUMN prompt_verify_running_task.task_desc IS '任务描述';
COMMENT ON COLUMN prompt_verify_running_task.large_model_code_list IS '关联大模型列表';
COMMENT ON COLUMN prompt_verify_running_task.create_time IS '创建时间';
COMMENT ON COLUMN prompt_verify_running_task.update_time IS '更新时间';
COMMENT ON COLUMN prompt_verify_running_task.task_status IS '任务状态（none-无状态 init-初始化状态 running-运行中 success-运行成功 fail-运行失败）';
COMMENT ON COLUMN prompt_verify_running_task.concurrent_num IS '并发数';
ALTER TABLE prompt_verify_running_task ADD CONSTRAINT prompt_verify_running_task_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE prompt_verify_running_task_detail (
    id character varying(64) COLLATE "C" NOT NULL,
    task_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    prompt_params text,
    prompt_template text,
    prompt_params_md5 character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE prompt_verify_running_task_detail IS '大模型校验任务详情表';
COMMENT ON COLUMN prompt_verify_running_task_detail.id IS '主键ID';
COMMENT ON COLUMN prompt_verify_running_task_detail.task_id IS '关联任务ID';
COMMENT ON COLUMN prompt_verify_running_task_detail.prompt_params IS 'prompt参数信息';
COMMENT ON COLUMN prompt_verify_running_task_detail.prompt_template IS 'prompt模板信息';
COMMENT ON COLUMN prompt_verify_running_task_detail.prompt_params_md5 IS 'prompt参数唯一键';
ALTER TABLE prompt_verify_running_task_detail ADD CONSTRAINT prompt_verify_running_task_detail_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE prompt_verify_running_task_result (
    id character varying(64) COLLATE "C" NOT NULL,
    task_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    start_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    end_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    evaluation character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    prompt_template text,
    large_model_code character varying(64) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE prompt_verify_running_task_result IS '大模型校验任务结果表';
COMMENT ON COLUMN prompt_verify_running_task_result.id IS '主键ID';
COMMENT ON COLUMN prompt_verify_running_task_result.task_id IS '任务ID';
COMMENT ON COLUMN prompt_verify_running_task_result.start_time IS '开始时间';
COMMENT ON COLUMN prompt_verify_running_task_result.end_time IS '结束时间';
COMMENT ON COLUMN prompt_verify_running_task_result.evaluation IS '综合评价';
ALTER TABLE prompt_verify_running_task_result ADD CONSTRAINT prompt_verify_running_task_result_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE prompt_verify_running_task_result_detail (
    task_result_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    task_detail_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    task_time numeric(10,4) DEFAULT NULL::numeric,
    prompt_params_md5 character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    prompt_result text,
    format_standard character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    id character varying(64) COLLATE "C" NOT NULL,
    start_time character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    end_time character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    error_msg text,
    expect_format character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    prompt_sample text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE prompt_verify_running_task_result_detail IS '大模型校验任务结果明细表';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.task_result_id IS '任务结果ID';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.task_detail_id IS '任务详情ID';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.task_time IS '耗时';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.prompt_params_md5 IS 'prompt参数唯一键';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.prompt_result IS 'prompt结果';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.format_standard IS '格式是否满足标准（Y-是 N-否）';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.id IS '主键ID';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.start_time IS '开始时间';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.end_time IS '结束时间';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.error_msg IS '错误信息';
COMMENT ON COLUMN prompt_verify_running_task_result_detail.expect_format IS '期望格式';
ALTER TABLE prompt_verify_running_task_result_detail ADD CONSTRAINT prompt_verify_running_task_result_detail_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE prompt_verify_scene_info (
    id character varying(64) COLLATE "C" NOT NULL,
    scene_code character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    scene_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    create_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    scene_group character varying(100) COLLATE "C" DEFAULT ''::character varying,
    scene_desc character varying(1000) COLLATE "C" DEFAULT ''::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE prompt_verify_scene_info IS '场景信息表';
COMMENT ON COLUMN prompt_verify_scene_info.id IS '主键ID';
COMMENT ON COLUMN prompt_verify_scene_info.scene_code IS '场景编码';
COMMENT ON COLUMN prompt_verify_scene_info.scene_name IS '场景名称';
COMMENT ON COLUMN prompt_verify_scene_info.create_time IS '创建时间';
COMMENT ON COLUMN prompt_verify_scene_info.update_time IS '更新时间';
COMMENT ON COLUMN prompt_verify_scene_info.scene_group IS '场景分组';
COMMENT ON COLUMN prompt_verify_scene_info.scene_desc IS '场景描述';
ALTER TABLE prompt_verify_scene_info ADD CONSTRAINT scene_name UNIQUE USING ubtree (scene_name) WITH (storage_type=USTORE);
ALTER TABLE prompt_verify_scene_info ADD CONSTRAINT scene_code_idx UNIQUE USING ubtree (scene_code) WITH (storage_type=USTORE);
ALTER TABLE prompt_verify_scene_info ADD CONSTRAINT prompt_verify_scene_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE prompt_verify_scene_relate_prompt_info (
    id character varying(64) COLLATE "C" NOT NULL,
    scene_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    large_model_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    prompt_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    prompt_template text,
    status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying NOT NULL,
    create_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    update_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    expect_format character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    prompt_parameters text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
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
ALTER TABLE prompt_verify_scene_relate_prompt_info ADD CONSTRAINT prompt_verify_scene_relate_prompt_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_knowledge_base_info (
    knowledge_id character varying(64) COLLATE "C" NOT NULL,
    knowledge_code character varying(255) COLLATE "C" NOT NULL,
    knowledge_name character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    create_user_id character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    belong_user_id character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_desc text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_knowledge_base_info IS '知识库信息表';
COMMENT ON COLUMN qianxun_knowledge_base_info.knowledge_id IS '知识库唯一标识，自增主键';
COMMENT ON COLUMN qianxun_knowledge_base_info.knowledge_code IS '知识库code';
COMMENT ON COLUMN qianxun_knowledge_base_info.knowledge_name IS '知识库名称';
COMMENT ON COLUMN qianxun_knowledge_base_info.create_time IS '知识库创建时间';
COMMENT ON COLUMN qianxun_knowledge_base_info.update_time IS '知识库更新时间';
COMMENT ON COLUMN qianxun_knowledge_base_info.create_user_id IS '创建用户id,agent平台的用户';
COMMENT ON COLUMN qianxun_knowledge_base_info.belong_user_id IS '某个用户的私人知识库,千寻用户';
COMMENT ON COLUMN qianxun_knowledge_base_info.knowledge_desc IS '知识描述';
ALTER TABLE qianxun_knowledge_base_info ADD CONSTRAINT qianxun_knowledge_base_info_pkey PRIMARY KEY USING ubtree  (knowledge_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_knowledge_base_upload_file_info (
    file_id character varying(64) COLLATE "C" NOT NULL,
    knowledge_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    file_name character varying(255) COLLATE "C" NOT NULL,
    file_extension character varying(10) COLLATE "C" NOT NULL,
    user_uuid character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    session_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    file_size bigint DEFAULT 0::bigint NOT NULL,
    file_storage_path character varying(255) COLLATE "C" NOT NULL,
    upload_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    finish_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    description text,
    file_flag character varying(20) COLLATE "C" DEFAULT '0'::character varying,
    parse_status character varying(30) COLLATE "C" DEFAULT 'uploading'::character varying,
    fail_count integer DEFAULT 0
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_knowledge_base_upload_file_info IS '知识库上传文件信息表';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.file_id IS '文件记录的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.knowledge_id IS '关联的知识库 ID，对应 knowledge_base_info 表中的 knowledge_id';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.file_name IS '上传文件的名称';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.file_extension IS '文件的扩展名，如 .pdf, .docx';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.user_uuid IS '上传文件的用户id';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.session_no IS '上传文件的会话id,留待后续按会话控制时使用';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.file_size IS '文件的大小，单位为字节';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.file_storage_path IS '文件在存储系统中的路径';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.upload_time IS '文件上传的时间';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.finish_time IS '文件完成解析的时间';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.description IS '文件的描述信息，简要说明文件内容';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.file_flag IS '0:用户单个上传文件,1:用户知识库上传文件,2:用户单个上传文件+用户知识库上传文件';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.parse_status IS E'文件解析状态: \\r\\nuploading - 上传中\\r\\nupload_failed - 上传失败\\r\\nuploaded_success - 上传成功\\r\\nparsing - 解析中\\r\\nparse_success - 解析成功\\r\\nparse_failed - 解析失败';
COMMENT ON COLUMN qianxun_knowledge_base_upload_file_info.fail_count IS '失败次数';
ALTER TABLE qianxun_knowledge_base_upload_file_info ADD CONSTRAINT qianxun_knowledge_base_upload_file_info_pkey PRIMARY KEY USING ubtree  (file_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_order_info (
    order_id character varying(32) COLLATE "C" NOT NULL,
    order_name character varying(32) COLLATE "C" NOT NULL,
    org_id character varying(64) COLLATE "C" NOT NULL,
    is_all_user smallint DEFAULT 0::smallint NOT NULL,
    is_long_term smallint DEFAULT 0::smallint NOT NULL,
    consumption_method character varying(50) COLLATE "C" NOT NULL,
    count_limit bigint DEFAULT 0::bigint,
    consumption_org_count bigint DEFAULT 0::bigint,
    consumption_object character varying(50) COLLATE "C" NOT NULL,
    is_online character varying(2) COLLATE "C" DEFAULT 'N'::character varying,
    order_description text,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    expire_date character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    org_id_list character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    ai_component_display_format character varying(50) COLLATE "C" DEFAULT 'H5'::character varying,
    is_resource character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    qianxun_version character varying(100) COLLATE "C" DEFAULT 'classic-经典版'::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_order_info IS '千寻订单信息表';
COMMENT ON COLUMN qianxun_order_info.order_id IS '订单的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_order_info.order_name IS '订单名称';
COMMENT ON COLUMN qianxun_order_info.org_id IS '所属机构 ID，关联机构信息表中的 uuid';
COMMENT ON COLUMN qianxun_order_info.is_all_user IS '是否限制用户，1 表示限制，0 表示不限制';
COMMENT ON COLUMN qianxun_order_info.is_long_term IS '是否长期（有效期不过期），1 表示长期，0 表示非长期';
COMMENT ON COLUMN qianxun_order_info.consumption_method IS '消费方式，枚举值为次/天、累计、无限制';
COMMENT ON COLUMN qianxun_order_info.count_limit IS '次数上限';
COMMENT ON COLUMN qianxun_order_info.consumption_org_count IS '订单按机构可用消费次数';
COMMENT ON COLUMN qianxun_order_info.consumption_object IS '消费对象，枚举值为公用、每个用户';
COMMENT ON COLUMN qianxun_order_info.is_online IS '状态，Y已上架，N已下架';
COMMENT ON COLUMN qianxun_order_info.order_description IS '订单描述';
COMMENT ON COLUMN qianxun_order_info.create_time IS '关联关系创建时间';
COMMENT ON COLUMN qianxun_order_info.update_time IS '关联关系更新时间';
COMMENT ON COLUMN qianxun_order_info.expire_date IS '订单有效期（当是否长期字段值为0时，必填）';
COMMENT ON COLUMN qianxun_order_info.org_id_list IS '所属机构层级';
COMMENT ON COLUMN qianxun_order_info.ai_component_display_format IS '智能组件呈现格式: pdf,png,h5';
COMMENT ON COLUMN qianxun_order_info.is_resource IS '是否需要溯源 Y 是 N否';
COMMENT ON COLUMN qianxun_order_info.qianxun_version IS '千寻版本类型：classic经典版 simple-简约版';
ALTER TABLE qianxun_order_info ADD CONSTRAINT qianxun_order_info_pkey PRIMARY KEY USING ubtree  (order_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_organization_info (
    id character varying(64) COLLATE "C" NOT NULL,
    org_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    org_name character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    parent_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    org_description text,
    hub_account character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    sort_no integer,
    ai_component_display_format character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    origin_org_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    app_key character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    app_key_expire_date character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_organization_info IS '千寻机构信息表';
COMMENT ON COLUMN qianxun_organization_info.id IS '机构 ID，唯一标识每个机构';
COMMENT ON COLUMN qianxun_organization_info.org_id IS '机构ID，用于第三方数据同步';
COMMENT ON COLUMN qianxun_organization_info.org_name IS '机构名称';
COMMENT ON COLUMN qianxun_organization_info.parent_id IS '上级机构 ID，若为顶级机构则为 NULL';
COMMENT ON COLUMN qianxun_organization_info.org_description IS '机构描述信息';
COMMENT ON COLUMN qianxun_organization_info.hub_account IS '机构关联hub账号';
COMMENT ON COLUMN qianxun_organization_info.create_time IS '机构创建时间';
COMMENT ON COLUMN qianxun_organization_info.update_time IS '机构信息更新时间';
COMMENT ON COLUMN qianxun_organization_info.sort_no IS '排序号';
COMMENT ON COLUMN qianxun_organization_info.ai_component_display_format IS '智能组件呈现格式: pdf,png,h5';
COMMENT ON COLUMN qianxun_organization_info.origin_org_id IS '同步机构ID';
COMMENT ON COLUMN qianxun_organization_info.app_key IS 'appkey值，登录使用';
COMMENT ON COLUMN qianxun_organization_info.app_key_expire_date IS 'appkey到期日期';
ALTER TABLE qianxun_organization_info ADD CONSTRAINT qianxun_organization_info_org_id_idx UNIQUE USING ubtree (org_id, hub_account) WITH (storage_type=USTORE);
ALTER TABLE qianxun_organization_info ADD CONSTRAINT org_id UNIQUE USING ubtree (org_id) WITH (storage_type=USTORE);
ALTER TABLE qianxun_organization_info ADD CONSTRAINT qianxun_organization_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_package_ai_component_relation (
    id character varying(32) COLLATE "C" NOT NULL,
    package_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    ai_component_id integer,
    status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    sort_no integer,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_package_ai_component_relation IS '千寻套餐关联智能组件信息表';
COMMENT ON COLUMN qianxun_package_ai_component_relation.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_ai_component_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_ai_component_relation.ai_component_id IS '智能组件ID，关联智能组件信息表中的id';
COMMENT ON COLUMN qianxun_package_ai_component_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_ai_component_relation.sort_no IS '排序号';
COMMENT ON COLUMN qianxun_package_ai_component_relation.create_time IS '关联关系创建时间';
COMMENT ON COLUMN qianxun_package_ai_component_relation.update_time IS '关联关系更新时间';
ALTER TABLE qianxun_package_ai_component_relation ADD CONSTRAINT qianxun_package_ai_component_relation_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_package_index_relation (
    id character varying(32) COLLATE "C" NOT NULL,
    package_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    index_id integer,
    status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    is_visible character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    sort_no integer,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    relate_index_id character varying(100) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_package_index_relation IS '千寻套餐关联组件信息表';
COMMENT ON COLUMN qianxun_package_index_relation.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_index_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_index_relation.index_id IS '组件ID，关联组件信息表中的 id';
COMMENT ON COLUMN qianxun_package_index_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_index_relation.is_visible IS '是否可见，Y可见，N不可见';
COMMENT ON COLUMN qianxun_package_index_relation.sort_no IS '排序号';
COMMENT ON COLUMN qianxun_package_index_relation.create_time IS '关联关系创建时间';
COMMENT ON COLUMN qianxun_package_index_relation.update_time IS '关联关系更新时间';
COMMENT ON COLUMN qianxun_package_index_relation.relate_index_id IS '组件信息关联ID（对应package_agent_index_config表ID）';
ALTER TABLE qianxun_package_index_relation ADD CONSTRAINT qianxun_package_index_relation_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_package_info (
    package_id character varying(32) COLLATE "C" NOT NULL,
    package_name character varying(255) COLLATE "C" NOT NULL,
    package_desc text,
    status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_package_info IS '套餐基本信息表';
COMMENT ON COLUMN qianxun_package_info.package_id IS '套餐唯一标识';
COMMENT ON COLUMN qianxun_package_info.package_name IS '套餐名称';
COMMENT ON COLUMN qianxun_package_info.package_desc IS '套餐详细描述';
COMMENT ON COLUMN qianxun_package_info.status IS '套餐有效标志位，Y表示已上架，N表示已下架';
COMMENT ON COLUMN qianxun_package_info.create_time IS '套餐信息创建时间';
COMMENT ON COLUMN qianxun_package_info.update_time IS '套餐信息更新时间';
ALTER TABLE qianxun_package_info ADD CONSTRAINT qianxun_package_info_pkey PRIMARY KEY USING ubtree  (package_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_package_knowledge_relation (
    id character varying(32) COLLATE "C" NOT NULL,
    package_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    sort_no integer,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_package_knowledge_relation IS '千寻套餐关联知识库信息表';
COMMENT ON COLUMN qianxun_package_knowledge_relation.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_knowledge_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_knowledge_relation.knowledge_id IS '知识库ID，关联知识库信息表中的knowledge_id';
COMMENT ON COLUMN qianxun_package_knowledge_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_knowledge_relation.sort_no IS '排序号';
COMMENT ON COLUMN qianxun_package_knowledge_relation.create_time IS '关联关系创建时间';
COMMENT ON COLUMN qianxun_package_knowledge_relation.update_time IS '关联关系更新时间';
ALTER TABLE qianxun_package_knowledge_relation ADD CONSTRAINT qianxun_package_knowledge_relation_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_package_menu_relation (
    id character varying(32) COLLATE "C" NOT NULL,
    package_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    menu_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    sort_no integer,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_package_menu_relation IS '千寻套餐关联千寻菜单信息表';
COMMENT ON COLUMN qianxun_package_menu_relation.id IS '关联记录的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_menu_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_menu_relation.menu_id IS '千寻菜单ID，千寻菜单配置表中的id';
COMMENT ON COLUMN qianxun_package_menu_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_menu_relation.sort_no IS '排序号';
COMMENT ON COLUMN qianxun_package_menu_relation.create_time IS '关联记录的创建时间';
COMMENT ON COLUMN qianxun_package_menu_relation.update_time IS '关联记录的更新时间';
ALTER TABLE qianxun_package_menu_relation ADD CONSTRAINT qianxun_package_menu_relation_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_package_order_relation (
    id character varying(32) COLLATE "C" NOT NULL,
    package_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    order_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_package_order_relation IS '订单关联套餐表';
COMMENT ON COLUMN qianxun_package_order_relation.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_order_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_order_relation.order_id IS '订单ID，关联订单信息表中的 order_id';
COMMENT ON COLUMN qianxun_package_order_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_order_relation.create_time IS '关联关系创建时间';
COMMENT ON COLUMN qianxun_package_order_relation.update_time IS '关联关系更新时间';
ALTER TABLE qianxun_package_order_relation ADD CONSTRAINT qianxun_package_order_relation_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_package_space_relation (
    id character varying(32) COLLATE "C" NOT NULL,
    package_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    space_id integer,
    status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    sort_no integer,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_package_space_relation IS '千寻套餐关联空间信息表';
COMMENT ON COLUMN qianxun_package_space_relation.id IS '关联记录的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_space_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_space_relation.space_id IS '空间ID，关联空间信息表中的 space_id';
COMMENT ON COLUMN qianxun_package_space_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_space_relation.sort_no IS '排序号';
COMMENT ON COLUMN qianxun_package_space_relation.create_time IS '关联记录的创建时间';
COMMENT ON COLUMN qianxun_package_space_relation.update_time IS '关联记录的更新时间';
ALTER TABLE qianxun_package_space_relation ADD CONSTRAINT qianxun_package_space_relation_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_source_cards (
    session_msg_no character varying(200) COLLATE "C" NOT NULL,
    source_card_content text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
ALTER TABLE qianxun_source_cards ADD CONSTRAINT qianxun_source_cards_pkey PRIMARY KEY USING ubtree  (session_msg_no) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_user_info (
    id character varying(64) COLLATE "C" NOT NULL,
    user_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    user_name character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    org_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    phone_number character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    password character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    salt character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    label character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    email character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    last_active_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    user_source character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    remark character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    origin_user_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    org_id_list character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    app_key character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    app_key_expire_date character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_user_info IS '千寻用户信息表';
COMMENT ON COLUMN qianxun_user_info.id IS '用户通用唯一识别码，用于唯一标识用户';
COMMENT ON COLUMN qianxun_user_info.user_id IS '用户id，用于外部数据同步';
COMMENT ON COLUMN qianxun_user_info.user_name IS '用户姓名';
COMMENT ON COLUMN qianxun_user_info.org_id IS '所属机构 ID';
COMMENT ON COLUMN qianxun_user_info.phone_number IS '用户电话号码';
COMMENT ON COLUMN qianxun_user_info.password IS '用户登录密码';
COMMENT ON COLUMN qianxun_user_info.salt IS '用户登录密码盐';
COMMENT ON COLUMN qianxun_user_info.label IS '用户标签';
COMMENT ON COLUMN qianxun_user_info.email IS '邮箱';
COMMENT ON COLUMN qianxun_user_info.status IS '用户有效标志位，Y表示有效，N表示无效';
COMMENT ON COLUMN qianxun_user_info.last_active_time IS '用户最后一次活跃使用的时间';
COMMENT ON COLUMN qianxun_user_info.create_time IS '用户信息创建时间或者同步进来的时间';
COMMENT ON COLUMN qianxun_user_info.update_time IS '用户信息更新时间';
COMMENT ON COLUMN qianxun_user_info.user_source IS '用户来源';
COMMENT ON COLUMN qianxun_user_info.remark IS '备注';
COMMENT ON COLUMN qianxun_user_info.origin_user_id IS '同步用户ID';
COMMENT ON COLUMN qianxun_user_info.org_id_list IS '所属机构层级';
COMMENT ON COLUMN qianxun_user_info.app_key IS 'appkey值，登录使用';
COMMENT ON COLUMN qianxun_user_info.app_key_expire_date IS 'appkey到期日期';
ALTER TABLE qianxun_user_info ADD CONSTRAINT qianxun_user_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_user_log (
    id integer DEFAULT nextval('qianxun_user_log_id_seq'::regclass) NOT NULL,
    user_id character varying(80) COLLATE "C" NOT NULL,
    hub_account character varying(80) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    org_id character varying(80) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    env_type character varying(40) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    version_type character varying(40) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    hub_source character varying(80) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    session_no character varying(80) COLLATE "C" NOT NULL,
    session_msg_no character varying(80) COLLATE "C" NOT NULL,
    parent_session_msg_no character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    msg text,
    session_msg_start_time timestamp without time zone,
    first_session_msg_time timestamp without time zone,
    session_msg_end_time timestamp without time zone,
    phone_no character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    org_info character varying(200) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    answer_result text,
    org_name character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    role_name character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    menu_name character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    menu_name_code character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    order_id character varying(100) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_user_log IS '千寻提问处理时间埋点信息表';
COMMENT ON COLUMN qianxun_user_log.id IS '自增主键';
COMMENT ON COLUMN qianxun_user_log.user_id IS '用户id';
COMMENT ON COLUMN qianxun_user_log.hub_account IS '云服务账号';
COMMENT ON COLUMN qianxun_user_log.org_id IS '机构id';
COMMENT ON COLUMN qianxun_user_log.env_type IS '环境';
COMMENT ON COLUMN qianxun_user_log.version_type IS '版本类型';
COMMENT ON COLUMN qianxun_user_log.hub_source IS '机构';
COMMENT ON COLUMN qianxun_user_log.session_no IS '会话id';
COMMENT ON COLUMN qianxun_user_log.session_msg_no IS '会话问答id';
COMMENT ON COLUMN qianxun_user_log.parent_session_msg_no IS '答复对应的提问session_msg_no';
COMMENT ON COLUMN qianxun_user_log.msg IS '回话问题';
COMMENT ON COLUMN qianxun_user_log.session_msg_start_time IS '会话问答开始时间';
COMMENT ON COLUMN qianxun_user_log.first_session_msg_time IS '会话问答第一个消息时间';
COMMENT ON COLUMN qianxun_user_log.session_msg_end_time IS '会话问答结束时间';
COMMENT ON COLUMN qianxun_user_log.org_info IS '所属机构';
COMMENT ON COLUMN qianxun_user_log.answer_result IS '问答给最终用户的输出';
COMMENT ON COLUMN qianxun_user_log.menu_name_code IS '菜单名称编码';
COMMENT ON COLUMN qianxun_user_log.order_id IS '订单编号';
ALTER TABLE qianxun_user_log ADD CONSTRAINT session_msg_no_2_unique UNIQUE USING ubtree (session_msg_no) WITH (storage_type=USTORE);
ALTER TABLE qianxun_user_log ADD CONSTRAINT qianxun_user_log_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE qianxun_user_order_relation (
    id character varying(32) COLLATE "C" NOT NULL,
    user_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    order_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    update_time timestamp without time zone DEFAULT pg_systimestamp() NOT NULL,
    consumption_user_count bigint DEFAULT 0::bigint
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE qianxun_user_order_relation IS '订单关联用户表';
COMMENT ON COLUMN qianxun_user_order_relation.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_user_order_relation.user_id IS '用户通用唯一识别码，关联用户信息表中的 user_uuid';
COMMENT ON COLUMN qianxun_user_order_relation.order_id IS '订单 ID，关联订单信息表中的 order_id';
COMMENT ON COLUMN qianxun_user_order_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_user_order_relation.create_time IS '关联关系创建时间';
COMMENT ON COLUMN qianxun_user_order_relation.update_time IS '关联关系更新时间';
COMMENT ON COLUMN qianxun_user_order_relation.consumption_user_count IS '订单按用户可用消费次数';
ALTER TABLE qianxun_user_order_relation ADD CONSTRAINT qianxun_user_order_relation_user_id_idx UNIQUE USING ubtree (user_id, order_id) WITH (storage_type=USTORE);
ALTER TABLE qianxun_user_order_relation ADD CONSTRAINT qianxun_user_order_relation_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE rasa_agent_logs (
    session_msg_no character varying(64) COLLATE "C" NOT NULL,
    agent_code character varying(256) COLLATE "C" NOT NULL,
    start_time character varying(40) COLLATE "C" NOT NULL,
    hub_account character varying(80) COLLATE "C" NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN rasa_agent_logs.session_msg_no IS '问题id';
COMMENT ON COLUMN rasa_agent_logs.agent_code IS 'Agent code';
COMMENT ON COLUMN rasa_agent_logs.start_time IS '问答时间';
COMMENT ON COLUMN rasa_agent_logs.hub_account IS 'hub账号';
ALTER TABLE rasa_agent_logs ADD CONSTRAINT rasa_agent_logs_pkey PRIMARY KEY USING ubtree  (session_msg_no, agent_code, hub_account) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE rasa_chat_detail_info (
    id integer DEFAULT nextval('rasa_chat_detail_info_id_seq'::regclass) NOT NULL,
    session_no character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    session_msg_no character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    report_no character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    user_id character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    hub_account character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    role_type character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    plugin_name character varying(200) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    knowledge_ids character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    question text,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    intent text,
    question_cls text,
    nlu text,
    ner text,
    statistics_info text,
    intent_info text,
    content_match_info text,
    agent_code text,
    agent_info text,
    fallback_info text,
    results text,
    actions_time_cost character varying(256) COLLATE "C" DEFAULT NULL::character varying,
    rewrite_question text,
    question_topic character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    question_answer_validation_class character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    question_answer_validation_original_reault text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE rasa_chat_detail_info IS 'rasa问答记录表';
COMMENT ON COLUMN rasa_chat_detail_info.id IS '主键';
COMMENT ON COLUMN rasa_chat_detail_info.session_no IS '会话no';
COMMENT ON COLUMN rasa_chat_detail_info.session_msg_no IS '会话中问题no';
COMMENT ON COLUMN rasa_chat_detail_info.report_no IS 'report_no';
COMMENT ON COLUMN rasa_chat_detail_info.user_id IS '用户id';
COMMENT ON COLUMN rasa_chat_detail_info.role_type IS '角色, 区分是否PF';
COMMENT ON COLUMN rasa_chat_detail_info.plugin_name IS '插件名称';
COMMENT ON COLUMN rasa_chat_detail_info.knowledge_ids IS '知识id';
COMMENT ON COLUMN rasa_chat_detail_info.question IS '问题';
COMMENT ON COLUMN rasa_chat_detail_info.start_time IS '问题开始时间';
COMMENT ON COLUMN rasa_chat_detail_info.end_time IS '问题完成时间';
COMMENT ON COLUMN rasa_chat_detail_info.intent IS '问题意图分类';
COMMENT ON COLUMN rasa_chat_detail_info.question_cls IS '问题主体分类';
COMMENT ON COLUMN rasa_chat_detail_info.nlu IS '问题关键词抽取';
COMMENT ON COLUMN rasa_chat_detail_info.ner IS '企业实体识别';
COMMENT ON COLUMN rasa_chat_detail_info.statistics_info IS '是否统计类问题及年报问答统计或基础问答统计';
COMMENT ON COLUMN rasa_chat_detail_info.intent_info IS '其他意图信息: 展示完整目录、打招呼等';
COMMENT ON COLUMN rasa_chat_detail_info.content_match_info IS '组件匹配';
COMMENT ON COLUMN rasa_chat_detail_info.agent_code IS 'agent_code';
COMMENT ON COLUMN rasa_chat_detail_info.agent_info IS 'agent信息';
COMMENT ON COLUMN rasa_chat_detail_info.fallback_info IS '兜底信息';
COMMENT ON COLUMN rasa_chat_detail_info.results IS '问题结果';
COMMENT ON COLUMN rasa_chat_detail_info.question_topic IS '问题分类主题';
COMMENT ON COLUMN rasa_chat_detail_info.question_answer_validation_class IS '问答结果分类';
COMMENT ON COLUMN rasa_chat_detail_info.question_answer_validation_original_reault IS '问答结果分类原始结果';
ALTER TABLE rasa_chat_detail_info ADD CONSTRAINT session_msg_no UNIQUE USING ubtree (session_msg_no) WITH (storage_type=USTORE);
ALTER TABLE rasa_chat_detail_info ADD CONSTRAINT rasa_chat_detail_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE rasa_index_logs (
    session_msg_no character varying(64) COLLATE "C" NOT NULL,
    index_name character varying(256) COLLATE "C" NOT NULL,
    source_type character varying(256) COLLATE "C" NOT NULL,
    start_time character varying(40) COLLATE "C" NOT NULL,
    index_classification character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    hub_account character varying(80) COLLATE "C" NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN rasa_index_logs.session_msg_no IS '问题id';
COMMENT ON COLUMN rasa_index_logs.index_name IS '组件名';
COMMENT ON COLUMN rasa_index_logs.source_type IS 'source_type';
COMMENT ON COLUMN rasa_index_logs.start_time IS '问答时间';
COMMENT ON COLUMN rasa_index_logs.hub_account IS 'hub账号';
ALTER TABLE rasa_index_logs ADD CONSTRAINT rasa_index_logs_pkey PRIMARY KEY USING ubtree  (session_msg_no, index_name, source_type, hub_account) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE rasa_question_time_cost_percent_line (
    hour_str character varying(64) COLLATE "C" NOT NULL,
    line_80 numeric NOT NULL,
    line_85 numeric NOT NULL,
    line_90 numeric NOT NULL,
    line_95 numeric NOT NULL,
    line_99 numeric NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN rasa_question_time_cost_percent_line.hour_str IS '小时';
COMMENT ON COLUMN rasa_question_time_cost_percent_line.line_80 IS '80%line';
COMMENT ON COLUMN rasa_question_time_cost_percent_line.line_85 IS '85%line';
COMMENT ON COLUMN rasa_question_time_cost_percent_line.line_90 IS '90%line';
COMMENT ON COLUMN rasa_question_time_cost_percent_line.line_95 IS '95%line';
COMMENT ON COLUMN rasa_question_time_cost_percent_line.line_99 IS '99%line';
ALTER TABLE rasa_question_time_cost_percent_line ADD CONSTRAINT rasa_question_time_cost_percent_line_pkey PRIMARY KEY USING ubtree  (hour_str) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE rasa_user_by_day (
    day_str character varying(20) COLLATE "C" NOT NULL,
    day_new_user bigint DEFAULT 0::bigint NOT NULL,
    day_user bigint DEFAULT 0::bigint NOT NULL,
    hub_account character varying(80) COLLATE "C" NOT NULL,
    day_count_user bigint DEFAULT 0::bigint NOT NULL,
    day_qa integer DEFAULT 0 NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN rasa_user_by_day.day_str IS '天';
COMMENT ON COLUMN rasa_user_by_day.day_new_user IS '新用户';
COMMENT ON COLUMN rasa_user_by_day.day_user IS '用户';
COMMENT ON COLUMN rasa_user_by_day.hub_account IS 'hub账号';
COMMENT ON COLUMN rasa_user_by_day.day_count_user IS '累计用户';
COMMENT ON COLUMN rasa_user_by_day.day_qa IS '当天问答次数';
ALTER TABLE rasa_user_by_day ADD CONSTRAINT rasa_user_by_day_pkey PRIMARY KEY USING ubtree  (day_str, hub_account) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE rela_index_config (
    id integer DEFAULT nextval('rela_index_config_id_seq'::regclass) NOT NULL,
    index_id integer,
    rela_index_id integer,
    rela_index_status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE rela_index_config IS '关联指标配置表';
COMMENT ON COLUMN rela_index_config.id IS '主键ID';
COMMENT ON COLUMN rela_index_config.index_id IS '指标ID';
COMMENT ON COLUMN rela_index_config.rela_index_id IS '关联指标ID';
COMMENT ON COLUMN rela_index_config.rela_index_status IS '关联指标状态';
ALTER TABLE rela_index_config ADD CONSTRAINT idx_rela_index_code UNIQUE USING ubtree (index_id, rela_index_id) WITH (storage_type=USTORE);
ALTER TABLE rela_index_config ADD CONSTRAINT rela_index_config_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE report_version (
    reportversion character varying(32) COLLATE "C" NOT NULL,
    versionno character varying(10) COLLATE "C" NOT NULL,
    label character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    mark character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    createtime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    creatorid character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    creatorname character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    modifytime character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    modifierid character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    modifiername character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    sortno character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    operation character varying(10) COLLATE "C" DEFAULT '1'::character varying NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE report_version IS '报告版本信息';
COMMENT ON COLUMN report_version.reportversion IS '报告版本';
COMMENT ON COLUMN report_version.versionno IS '版本号';
COMMENT ON COLUMN report_version.label IS '版本标签';
COMMENT ON COLUMN report_version.mark IS ';';
COMMENT ON COLUMN report_version.createtime IS '版本创建时间';
COMMENT ON COLUMN report_version.creatorid IS '创建人ID';
COMMENT ON COLUMN report_version.creatorname IS '创建人名字';
COMMENT ON COLUMN report_version.modifytime IS '修改时间';
COMMENT ON COLUMN report_version.modifierid IS '修改人ID';
COMMENT ON COLUMN report_version.modifiername IS '修改人人名字';
COMMENT ON COLUMN report_version.sortno IS '排序号';
COMMENT ON COLUMN report_version.operation IS '是否可操作标识1是0否';
ALTER TABLE report_version ADD CONSTRAINT report_version_pkey PRIMARY KEY USING ubtree  (reportversion, versionno) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE rule_check_upload_report_files (
    id character varying(40) COLLATE "C" NOT NULL,
    session_no character varying(50) COLLATE "C" NOT NULL,
    user_id character varying(32) COLLATE "C" NOT NULL,
    ent_name character varying(256) COLLATE "C" NOT NULL,
    file_name character varying(256) COLLATE "C" NOT NULL,
    markdown_content text,
    segments json,
    upload_time character varying(40) COLLATE "C" NOT NULL,
    update_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(20) COLLATE "C" NOT NULL,
    local_path character varying(256) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE rule_check_upload_report_files IS '规则检查上传的报告文件表';
COMMENT ON COLUMN rule_check_upload_report_files.id IS 'ID';
COMMENT ON COLUMN rule_check_upload_report_files.session_no IS '会话编号';
COMMENT ON COLUMN rule_check_upload_report_files.user_id IS '用户ID';
COMMENT ON COLUMN rule_check_upload_report_files.ent_name IS '企业名称';
COMMENT ON COLUMN rule_check_upload_report_files.file_name IS '文件名';
COMMENT ON COLUMN rule_check_upload_report_files.markdown_content IS 'Markdown内容';
COMMENT ON COLUMN rule_check_upload_report_files.segments IS '分段内容';
COMMENT ON COLUMN rule_check_upload_report_files.upload_time IS '上传时间';
COMMENT ON COLUMN rule_check_upload_report_files.update_time IS '更新时间';
COMMENT ON COLUMN rule_check_upload_report_files.status IS '状态：init(初始化), uploading(上传中), upload_success(上传成功), upload_failed(上传失败), parsing(解析中), parse_success(解析成功), parse_failed(解析失败)';
COMMENT ON COLUMN rule_check_upload_report_files.local_path IS '本地路径';
ALTER TABLE rule_check_upload_report_files ADD CONSTRAINT rule_check_upload_report_files_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE rule_check_upload_rule_files (
    id character varying(40) COLLATE "C" NOT NULL,
    session_no character varying(50) COLLATE "C" NOT NULL,
    user_id character varying(32) COLLATE "C" NOT NULL,
    file_name character varying(256) COLLATE "C" NOT NULL,
    markdown_content text,
    rules json,
    upload_time character varying(40) COLLATE "C" NOT NULL,
    update_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(20) COLLATE "C" NOT NULL,
    local_path character varying(256) COLLATE "C" DEFAULT NULL::character varying,
    segments json
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE rule_check_upload_rule_files IS '规则检查上传的制度文件表';
COMMENT ON COLUMN rule_check_upload_rule_files.id IS 'ID';
COMMENT ON COLUMN rule_check_upload_rule_files.session_no IS '会话编号';
COMMENT ON COLUMN rule_check_upload_rule_files.user_id IS '用户ID';
COMMENT ON COLUMN rule_check_upload_rule_files.file_name IS '文件名';
COMMENT ON COLUMN rule_check_upload_rule_files.markdown_content IS 'Markdown内容';
COMMENT ON COLUMN rule_check_upload_rule_files.rules IS '规则内容';
COMMENT ON COLUMN rule_check_upload_rule_files.upload_time IS '上传时间';
COMMENT ON COLUMN rule_check_upload_rule_files.update_time IS '更新时间';
COMMENT ON COLUMN rule_check_upload_rule_files.status IS '状态：init(初始化), uploading(上传中), upload_success(上传成功), upload_failed(上传失败), parsing(解析中), parse_success(解析成功), parse_failed(解析失败)';
COMMENT ON COLUMN rule_check_upload_rule_files.local_path IS '本地路径';
COMMENT ON COLUMN rule_check_upload_rule_files.segments IS '切分文档';
ALTER TABLE rule_check_upload_rule_files ADD CONSTRAINT rule_check_upload_rule_files_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE scene_inflect_info (
    _id bigint DEFAULT nextval('scene_inflect_info__id_seq'::regclass) NOT NULL,
    scenename character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    prompt text,
    largemodelcode character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    expectformat character varying(255) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN scene_inflect_info._id IS '主键ID';
ALTER TABLE scene_inflect_info ADD CONSTRAINT scene_inflect_info_pkey PRIMARY KEY USING ubtree  (_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sence_relate_info (
    _id bigint DEFAULT nextval('sence_relate_info__id_seq'::regclass) NOT NULL,
    id numeric(22,0) DEFAULT NULL::numeric,
    knowledge_name character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_code character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_desc character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    parent_group_value character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    parent_group_name character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    group_value character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    group_name character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    scenename character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    prompt text,
    largemodelcode character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    expectformat character varying(255) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sence_relate_info._id IS '主键ID';
ALTER TABLE sence_relate_info ADD CONSTRAINT sence_relate_info_pkey PRIMARY KEY USING ubtree  (_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sync_knowledge_info (
    id integer DEFAULT nextval('sync_knowledge_info_id_seq'::regclass) NOT NULL,
    knowledge_code character varying(100) COLLATE "C" NOT NULL,
    sync_flag character varying(2) COLLATE "C" DEFAULT 'Y'::character varying NOT NULL
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sync_knowledge_info IS '知识库同步信息表';
COMMENT ON COLUMN sync_knowledge_info.id IS '主键ID';
COMMENT ON COLUMN sync_knowledge_info.knowledge_code IS '知识库编码';
COMMENT ON COLUMN sync_knowledge_info.sync_flag IS '同步标记 Y-同步 N-不同步';
ALTER TABLE sync_knowledge_info ADD CONSTRAINT sync_knowledge_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_announcement (
    id character varying(32) COLLATE "C" NOT NULL,
    titile character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    msg_content text,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    sender character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    priority character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    msg_category character varying(10) COLLATE "C" DEFAULT '2'::character varying NOT NULL,
    send_status character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    send_time timestamp without time zone,
    cancel_time timestamp without time zone,
    del_flag character varying(1) COLLATE "C" DEFAULT NULL::character varying,
    bus_type character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    bus_id character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    open_type character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    open_page character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    user_ids text,
    msg_abstract text,
    dt_task_id character varying(100) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_announcement IS '系统通告表';
COMMENT ON COLUMN sys_announcement.titile IS '标题';
COMMENT ON COLUMN sys_announcement.msg_content IS '内容';
COMMENT ON COLUMN sys_announcement.start_time IS '开始时间';
COMMENT ON COLUMN sys_announcement.end_time IS '结束时间';
COMMENT ON COLUMN sys_announcement.sender IS '发布人';
COMMENT ON COLUMN sys_announcement.priority IS '优先级（L低，M中，H高）';
COMMENT ON COLUMN sys_announcement.msg_category IS '消息类型1:通知公告2:系统消息';
COMMENT ON COLUMN sys_announcement.send_status IS '发布状态（0未发布，1已发布，2已撤销）';
COMMENT ON COLUMN sys_announcement.send_time IS '发布时间';
COMMENT ON COLUMN sys_announcement.cancel_time IS '撤销时间';
COMMENT ON COLUMN sys_announcement.del_flag IS '删除状态（0，正常，1已删除）';
COMMENT ON COLUMN sys_announcement.bus_type IS '业务类型(email:邮件 bpm:流程)';
COMMENT ON COLUMN sys_announcement.bus_id IS '业务id';
COMMENT ON COLUMN sys_announcement.open_type IS '打开方式(组件：component 路由：url)';
COMMENT ON COLUMN sys_announcement.open_page IS '组件/路由 地址';
COMMENT ON COLUMN sys_announcement.create_by IS '创建人';
COMMENT ON COLUMN sys_announcement.create_time IS '创建时间';
COMMENT ON COLUMN sys_announcement.update_by IS '更新人';
COMMENT ON COLUMN sys_announcement.update_time IS '更新时间';
COMMENT ON COLUMN sys_announcement.user_ids IS '指定用户';
COMMENT ON COLUMN sys_announcement.msg_abstract IS '摘要';
COMMENT ON COLUMN sys_announcement.dt_task_id IS '钉钉task_id，用于撤回消息';
ALTER TABLE sys_announcement ADD CONSTRAINT sys_announcement_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_announcement_send (
    _id bigint DEFAULT nextval('sys_announcement_send__id_seq'::regclass) NOT NULL,
    id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    annt_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    user_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    read_flag character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    read_time timestamp without time zone,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_announcement_send IS '用户通告阅读标记表';
COMMENT ON COLUMN sys_announcement_send._id IS '主键ID';
COMMENT ON COLUMN sys_announcement_send.annt_id IS '通告ID';
COMMENT ON COLUMN sys_announcement_send.user_id IS '用户id';
COMMENT ON COLUMN sys_announcement_send.read_flag IS '阅读状态（0未读，1已读）';
COMMENT ON COLUMN sys_announcement_send.read_time IS '阅读时间';
COMMENT ON COLUMN sys_announcement_send.create_by IS '创建人';
COMMENT ON COLUMN sys_announcement_send.create_time IS '创建时间';
COMMENT ON COLUMN sys_announcement_send.update_by IS '更新人';
COMMENT ON COLUMN sys_announcement_send.update_time IS '更新时间';
ALTER TABLE sys_announcement_send ADD CONSTRAINT sys_announcement_send_pkey PRIMARY KEY USING ubtree  (_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_api_info (
    id character varying(32) COLLATE "C" NOT NULL,
    api_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    api_des character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    api_path character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    perm_code character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    perm_desc character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp(),
    update_time timestamp without time zone DEFAULT pg_systimestamp()
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_api_info IS '接口信息表';
COMMENT ON COLUMN sys_api_info.id IS '主键id';
COMMENT ON COLUMN sys_api_info.api_name IS '接口名称';
COMMENT ON COLUMN sys_api_info.api_des IS '接口路径';
COMMENT ON COLUMN sys_api_info.api_path IS '接口路径';
COMMENT ON COLUMN sys_api_info.perm_code IS '权限编码';
COMMENT ON COLUMN sys_api_info.perm_desc IS '接口描述';
COMMENT ON COLUMN sys_api_info.create_time IS '创建时间';
COMMENT ON COLUMN sys_api_info.update_time IS '更新时间';
ALTER TABLE sys_api_info ADD CONSTRAINT sys_api_info_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_category (
    id character varying(36) COLLATE "C" NOT NULL,
    pid character varying(36) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    has_child character varying(3) COLLATE "C" DEFAULT '0'::character varying,
    param_value character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    param_status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    synonym_word character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    key_word character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    rela_table character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    field_attr character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    remark character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    hit_independently character varying(32) COLLATE "C" DEFAULT 'N'::character varying,
    source_type_detail character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    source_field_type character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    param_desc character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    sample_question character varying(1000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_category.pid IS '父级节点';
COMMENT ON COLUMN sys_category.name IS '类型名称';
COMMENT ON COLUMN sys_category.code IS '类型编码';
COMMENT ON COLUMN sys_category.create_by IS '创建人';
COMMENT ON COLUMN sys_category.create_time IS '创建日期';
COMMENT ON COLUMN sys_category.update_by IS '更新人';
COMMENT ON COLUMN sys_category.update_time IS '更新日期';
COMMENT ON COLUMN sys_category.sys_org_code IS '所属部门';
COMMENT ON COLUMN sys_category.has_child IS '是否有子节点';
COMMENT ON COLUMN sys_category.param_value IS '参数码值';
COMMENT ON COLUMN sys_category.param_status IS '参数状态 Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN sys_category.synonym_word IS '同义词';
COMMENT ON COLUMN sys_category.key_word IS '关键词';
COMMENT ON COLUMN sys_category.rela_table IS '关联表';
COMMENT ON COLUMN sys_category.field_attr IS '字段属性';
COMMENT ON COLUMN sys_category.remark IS '备注';
COMMENT ON COLUMN sys_category.hit_independently IS '是否可独立命中';
COMMENT ON COLUMN sys_category.source_type_detail IS '细类类型';
COMMENT ON COLUMN sys_category.source_field_type IS '细类字段类型';
COMMENT ON COLUMN sys_category.param_desc IS '参数描述';
COMMENT ON COLUMN sys_category.sample_question IS '示例问题描述';
ALTER TABLE sys_category ADD CONSTRAINT sys_category_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_check_rule (
    id character varying(32) COLLATE "C" NOT NULL,
    rule_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    rule_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    rule_json character varying(1024) COLLATE "C" DEFAULT NULL::character varying,
    rule_description character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_check_rule.id IS '主键id';
COMMENT ON COLUMN sys_check_rule.rule_name IS '规则名称';
COMMENT ON COLUMN sys_check_rule.rule_code IS '规则Code';
COMMENT ON COLUMN sys_check_rule.rule_json IS '规则JSON';
COMMENT ON COLUMN sys_check_rule.rule_description IS '规则描述';
COMMENT ON COLUMN sys_check_rule.update_by IS '更新人';
COMMENT ON COLUMN sys_check_rule.update_time IS '更新时间';
COMMENT ON COLUMN sys_check_rule.create_by IS '创建人';
COMMENT ON COLUMN sys_check_rule.create_time IS '创建时间';
ALTER TABLE sys_check_rule ADD CONSTRAINT uni_sys_check_rule_code UNIQUE USING ubtree (rule_code) WITH (storage_type=USTORE);
ALTER TABLE sys_check_rule ADD CONSTRAINT sys_check_rule_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_data_log (
    id character varying(32) COLLATE "C" NOT NULL,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    data_table character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    data_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    data_content text,
    data_version integer
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_data_log.id IS 'id';
COMMENT ON COLUMN sys_data_log.create_by IS '创建人登录名称';
COMMENT ON COLUMN sys_data_log.create_time IS '创建日期';
COMMENT ON COLUMN sys_data_log.update_by IS '更新人登录名称';
COMMENT ON COLUMN sys_data_log.update_time IS '更新日期';
COMMENT ON COLUMN sys_data_log.data_table IS '表名';
COMMENT ON COLUMN sys_data_log.data_id IS '数据ID';
COMMENT ON COLUMN sys_data_log.data_content IS '数据内容';
COMMENT ON COLUMN sys_data_log.data_version IS '版本号';
ALTER TABLE sys_data_log ADD CONSTRAINT sys_data_log_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_data_source (
    id character varying(36) COLLATE "C" NOT NULL,
    code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    remark character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    db_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    db_driver character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    db_url character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    db_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    db_username character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    db_password character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_data_source.code IS '数据源编码';
COMMENT ON COLUMN sys_data_source.name IS '数据源名称';
COMMENT ON COLUMN sys_data_source.remark IS '备注';
COMMENT ON COLUMN sys_data_source.db_type IS '数据库类型';
COMMENT ON COLUMN sys_data_source.db_driver IS '驱动类';
COMMENT ON COLUMN sys_data_source.db_url IS '数据源地址';
COMMENT ON COLUMN sys_data_source.db_name IS '数据库名称';
COMMENT ON COLUMN sys_data_source.db_username IS '用户名';
COMMENT ON COLUMN sys_data_source.db_password IS '密码';
COMMENT ON COLUMN sys_data_source.create_by IS '创建人';
COMMENT ON COLUMN sys_data_source.create_time IS '创建日期';
COMMENT ON COLUMN sys_data_source.update_by IS '更新人';
COMMENT ON COLUMN sys_data_source.update_time IS '更新日期';
COMMENT ON COLUMN sys_data_source.sys_org_code IS '所属部门';
ALTER TABLE sys_data_source ADD CONSTRAINT sys_data_source_code_uni UNIQUE USING ubtree (code) WITH (storage_type=USTORE);
ALTER TABLE sys_data_source ADD CONSTRAINT sys_data_source_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_depart (
    id character varying(32) COLLATE "C" NOT NULL,
    parent_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    depart_name character varying(100) COLLATE "C" NOT NULL,
    depart_name_en character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    depart_name_abbr character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    depart_order integer DEFAULT 0,
    description character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    org_category character varying(10) COLLATE "C" DEFAULT '1'::character varying NOT NULL,
    org_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    org_code character varying(64) COLLATE "C" NOT NULL,
    mobile character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    fax character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    address character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    memo character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(1) COLLATE "C" DEFAULT NULL::character varying,
    del_flag character varying(1) COLLATE "C" DEFAULT NULL::character varying,
    qywx_identifier character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    datadate character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_depart IS '组织机构表';
COMMENT ON COLUMN sys_depart.id IS 'ID';
COMMENT ON COLUMN sys_depart.parent_id IS '父机构ID';
COMMENT ON COLUMN sys_depart.depart_name IS '机构/部门名称';
COMMENT ON COLUMN sys_depart.depart_name_en IS '英文名';
COMMENT ON COLUMN sys_depart.depart_name_abbr IS '缩写';
COMMENT ON COLUMN sys_depart.depart_order IS '排序';
COMMENT ON COLUMN sys_depart.description IS '描述';
COMMENT ON COLUMN sys_depart.org_category IS '机构类别 1公司，2组织机构，2岗位';
COMMENT ON COLUMN sys_depart.org_type IS '机构类型 1一级部门 2子部门';
COMMENT ON COLUMN sys_depart.org_code IS '机构编码';
COMMENT ON COLUMN sys_depart.mobile IS '手机号';
COMMENT ON COLUMN sys_depart.fax IS '传真';
COMMENT ON COLUMN sys_depart.address IS '地址';
COMMENT ON COLUMN sys_depart.memo IS '备注';
COMMENT ON COLUMN sys_depart.status IS '状态（1启用，0不启用）';
COMMENT ON COLUMN sys_depart.del_flag IS '删除状态（0，正常，1已删除）';
COMMENT ON COLUMN sys_depart.qywx_identifier IS '对接企业微信的ID';
COMMENT ON COLUMN sys_depart.create_by IS '创建人';
COMMENT ON COLUMN sys_depart.create_time IS '创建日期';
COMMENT ON COLUMN sys_depart.update_by IS '更新人';
COMMENT ON COLUMN sys_depart.update_time IS '更新日期';
ALTER TABLE sys_depart ADD CONSTRAINT sys_depart_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_depart_permission (
    id character varying(32) COLLATE "C" NOT NULL,
    depart_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    permission_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    data_rule_ids character varying(1000) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_depart_permission IS '部门权限表';
COMMENT ON COLUMN sys_depart_permission.depart_id IS '部门id';
COMMENT ON COLUMN sys_depart_permission.permission_id IS '权限id';
COMMENT ON COLUMN sys_depart_permission.data_rule_ids IS '数据规则id';
ALTER TABLE sys_depart_permission ADD CONSTRAINT sys_depart_permission_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_depart_role (
    id character varying(32) COLLATE "C" NOT NULL,
    depart_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    role_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    role_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    description character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_depart_role IS '部门角色表';
COMMENT ON COLUMN sys_depart_role.depart_id IS '部门id';
COMMENT ON COLUMN sys_depart_role.role_name IS '部门角色名称';
COMMENT ON COLUMN sys_depart_role.role_code IS '部门角色编码';
COMMENT ON COLUMN sys_depart_role.description IS '描述';
COMMENT ON COLUMN sys_depart_role.create_by IS '创建人';
COMMENT ON COLUMN sys_depart_role.create_time IS '创建时间';
COMMENT ON COLUMN sys_depart_role.update_by IS '更新人';
COMMENT ON COLUMN sys_depart_role.update_time IS '更新时间';
ALTER TABLE sys_depart_role ADD CONSTRAINT sys_depart_role_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_depart_role_permission (
    id character varying(32) COLLATE "C" NOT NULL,
    depart_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    role_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    permission_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    data_rule_ids character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    operate_date timestamp without time zone,
    operate_ip character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_depart_role_permission IS '部门角色权限表';
COMMENT ON COLUMN sys_depart_role_permission.depart_id IS '部门id';
COMMENT ON COLUMN sys_depart_role_permission.role_id IS '角色id';
COMMENT ON COLUMN sys_depart_role_permission.permission_id IS '权限id';
COMMENT ON COLUMN sys_depart_role_permission.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_depart_role_permission.operate_date IS '操作时间';
COMMENT ON COLUMN sys_depart_role_permission.operate_ip IS '操作ip';
ALTER TABLE sys_depart_role_permission ADD CONSTRAINT sys_depart_role_permission_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_depart_role_user (
    id character varying(32) COLLATE "C" NOT NULL,
    user_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    drole_id character varying(32) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_depart_role_user IS '部门角色用户表';
COMMENT ON COLUMN sys_depart_role_user.id IS '主键id';
COMMENT ON COLUMN sys_depart_role_user.user_id IS '用户id';
COMMENT ON COLUMN sys_depart_role_user.drole_id IS '角色id';
ALTER TABLE sys_depart_role_user ADD CONSTRAINT sys_depart_role_user_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_dict (
    id character varying(32) COLLATE "C" NOT NULL,
    dict_name character varying(100) COLLATE "C" NOT NULL,
    dict_code character varying(100) COLLATE "C" NOT NULL,
    description character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    del_flag integer,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    type integer DEFAULT 0
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_dict.dict_name IS '字典名称';
COMMENT ON COLUMN sys_dict.dict_code IS '字典编码';
COMMENT ON COLUMN sys_dict.description IS '描述';
COMMENT ON COLUMN sys_dict.del_flag IS '删除状态';
COMMENT ON COLUMN sys_dict.create_by IS '创建人';
COMMENT ON COLUMN sys_dict.create_time IS '创建时间';
COMMENT ON COLUMN sys_dict.update_by IS '更新人';
COMMENT ON COLUMN sys_dict.update_time IS '更新时间';
COMMENT ON COLUMN sys_dict.type IS '字典类型0为string,1为number';
ALTER TABLE sys_dict ADD CONSTRAINT indextable_dict_code UNIQUE USING ubtree (dict_code) WITH (storage_type=USTORE);
ALTER TABLE sys_dict ADD CONSTRAINT sys_dict_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_dict_item (
    id character varying(32) COLLATE "C" NOT NULL,
    dict_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    item_text character varying(100) COLLATE "C" NOT NULL,
    item_value character varying(100) COLLATE "C" NOT NULL,
    description character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    sort_order integer,
    status integer,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    synonym_word character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    key_word character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    rela_table character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    field_attr character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    remark character varying(100) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
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
ALTER TABLE sys_dict_item ADD CONSTRAINT sys_dict_item_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_fill_rule (
    id character varying(32) COLLATE "C" NOT NULL,
    rule_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    rule_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    rule_class character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    rule_params character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_fill_rule.id IS '主键ID';
COMMENT ON COLUMN sys_fill_rule.rule_name IS '规则名称';
COMMENT ON COLUMN sys_fill_rule.rule_code IS '规则Code';
COMMENT ON COLUMN sys_fill_rule.rule_class IS '规则实现类';
COMMENT ON COLUMN sys_fill_rule.rule_params IS '规则参数';
COMMENT ON COLUMN sys_fill_rule.update_by IS '修改人';
COMMENT ON COLUMN sys_fill_rule.update_time IS '修改时间';
COMMENT ON COLUMN sys_fill_rule.create_by IS '创建人';
COMMENT ON COLUMN sys_fill_rule.create_time IS '创建时间';
ALTER TABLE sys_fill_rule ADD CONSTRAINT uni_sys_fill_rule_code UNIQUE USING ubtree (rule_code) WITH (storage_type=USTORE);
ALTER TABLE sys_fill_rule ADD CONSTRAINT sys_fill_rule_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_gateway_route (
    id character varying(36) COLLATE "C" NOT NULL,
    router_id character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    uri character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    predicates text,
    filters text,
    retryable integer,
    strip_prefix integer,
    persistable integer,
    show_api integer,
    status integer,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_gateway_route.router_id IS '路由ID';
COMMENT ON COLUMN sys_gateway_route.name IS '服务名';
COMMENT ON COLUMN sys_gateway_route.uri IS '服务地址';
COMMENT ON COLUMN sys_gateway_route.predicates IS '断言';
COMMENT ON COLUMN sys_gateway_route.filters IS '过滤器';
COMMENT ON COLUMN sys_gateway_route.retryable IS '是否重试:0-否 1-是';
COMMENT ON COLUMN sys_gateway_route.strip_prefix IS '是否忽略前缀0-否 1-是';
COMMENT ON COLUMN sys_gateway_route.persistable IS '是否为保留数据:0-否 1-是';
COMMENT ON COLUMN sys_gateway_route.show_api IS '是否在接口文档中展示:0-否 1-是';
COMMENT ON COLUMN sys_gateway_route.status IS '状态:0-无效 1-有效';
COMMENT ON COLUMN sys_gateway_route.create_by IS '创建人';
COMMENT ON COLUMN sys_gateway_route.create_time IS '创建日期';
COMMENT ON COLUMN sys_gateway_route.update_by IS '更新人';
COMMENT ON COLUMN sys_gateway_route.update_time IS '更新日期';
COMMENT ON COLUMN sys_gateway_route.sys_org_code IS '所属部门';
ALTER TABLE sys_gateway_route ADD CONSTRAINT sys_gateway_route_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_log (
    id character varying(32) COLLATE "C" NOT NULL,
    log_type integer,
    log_content character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    operate_type integer,
    userid character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    username character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    ip character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    method character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    request_url character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    request_param text,
    request_type character varying(10) COLLATE "C" DEFAULT NULL::character varying,
    cost_time bigint,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_log IS '系统日志表';
COMMENT ON COLUMN sys_log.log_type IS '日志类型（1登录日志，2操作日志）';
COMMENT ON COLUMN sys_log.log_content IS '日志内容';
COMMENT ON COLUMN sys_log.operate_type IS '操作类型';
COMMENT ON COLUMN sys_log.userid IS '操作用户账号';
COMMENT ON COLUMN sys_log.username IS '操作用户名称';
COMMENT ON COLUMN sys_log.ip IS 'IP';
COMMENT ON COLUMN sys_log.method IS '请求java方法';
COMMENT ON COLUMN sys_log.request_url IS '请求路径';
COMMENT ON COLUMN sys_log.request_param IS '请求参数';
COMMENT ON COLUMN sys_log.request_type IS '请求类型';
COMMENT ON COLUMN sys_log.cost_time IS '耗时';
COMMENT ON COLUMN sys_log.create_by IS '创建人';
COMMENT ON COLUMN sys_log.create_time IS '创建时间';
COMMENT ON COLUMN sys_log.update_by IS '更新人';
COMMENT ON COLUMN sys_log.update_time IS '更新时间';
ALTER TABLE sys_log ADD CONSTRAINT sys_log_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_page_view_log (
    id integer DEFAULT nextval('sys_page_view_log_id_seq'::regclass) NOT NULL,
    user_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    source_first_level_module character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    source_second_level_module character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    source_hash character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    source_page_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    source_page_url character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    source_page_param text,
    dest_first_level_module character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    dest_second_level_module character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    dest_hash character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    dest_page_name character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    dest_page_url character varying(400) COLLATE "C" DEFAULT NULL::character varying,
    dest_page_param text,
    user_agent character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    user_ip character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    access_time character varying(20) COLLATE "C" DEFAULT NULL::character varying,
    session_msg_no character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    hub_account character varying(80) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    org_name character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    role_name character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    menu_name character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    menu_name_code character varying(500) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_page_view_log IS '系统页面访问记录表';
COMMENT ON COLUMN sys_page_view_log.user_id IS '用户id';
COMMENT ON COLUMN sys_page_view_log.source_first_level_module IS '来源页面所属一级模块';
COMMENT ON COLUMN sys_page_view_log.source_second_level_module IS '来源页面所属二级模块';
COMMENT ON COLUMN sys_page_view_log.source_hash IS '来源页面所属描点';
COMMENT ON COLUMN sys_page_view_log.source_page_name IS '来源组件名字';
COMMENT ON COLUMN sys_page_view_log.source_page_url IS '来源组件URL';
COMMENT ON COLUMN sys_page_view_log.source_page_param IS '来源组件请求参数';
COMMENT ON COLUMN sys_page_view_log.dest_first_level_module IS '目标页面所属一级模块';
COMMENT ON COLUMN sys_page_view_log.dest_second_level_module IS '目标页面所属二级模块';
COMMENT ON COLUMN sys_page_view_log.dest_hash IS '目标页面所属描点';
COMMENT ON COLUMN sys_page_view_log.dest_page_name IS '目标组件名字';
COMMENT ON COLUMN sys_page_view_log.dest_page_url IS '目标组件URL';
COMMENT ON COLUMN sys_page_view_log.dest_page_param IS '目标组件请求参数';
COMMENT ON COLUMN sys_page_view_log.user_agent IS '用户代理（浏览器）';
COMMENT ON COLUMN sys_page_view_log.user_ip IS '用户IP';
COMMENT ON COLUMN sys_page_view_log.create_time IS '创建时间';
COMMENT ON COLUMN sys_page_view_log.access_time IS '访问时间';
COMMENT ON COLUMN sys_page_view_log.hub_account IS '云服务账号';
COMMENT ON COLUMN sys_page_view_log.org_name IS '机构名称';
COMMENT ON COLUMN sys_page_view_log.role_name IS '角色名称';
COMMENT ON COLUMN sys_page_view_log.menu_name IS '菜单名称';
COMMENT ON COLUMN sys_page_view_log.menu_name_code IS '菜单名称码值';
ALTER TABLE sys_page_view_log ADD CONSTRAINT sys_page_view_log_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_permission (
    id character varying(32) COLLATE "C" NOT NULL,
    parent_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    url character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    component character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    component_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    redirect character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    menu_type integer,
    perms character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    perms_type character varying(10) COLLATE "C" DEFAULT '0'::character varying,
    sort_no numeric(8,2) DEFAULT NULL::numeric,
    always_show smallint,
    icon character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    is_route smallint DEFAULT 1::smallint,
    is_leaf smallint,
    keep_alive smallint,
    hidden integer DEFAULT 0,
    description character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    del_flag integer DEFAULT 0,
    rule_flag integer DEFAULT 0,
    status character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    internal_or_external smallint,
    is_show numeric(11,0) DEFAULT NULL::numeric
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_permission IS '菜单权限表';
COMMENT ON COLUMN sys_permission.id IS '主键id';
COMMENT ON COLUMN sys_permission.parent_id IS '父id';
COMMENT ON COLUMN sys_permission.name IS '菜单标题';
COMMENT ON COLUMN sys_permission.url IS '路径';
COMMENT ON COLUMN sys_permission.component IS '组件';
COMMENT ON COLUMN sys_permission.component_name IS '组件名字';
COMMENT ON COLUMN sys_permission.redirect IS '一级菜单跳转地址';
COMMENT ON COLUMN sys_permission.menu_type IS '菜单类型(0:一级菜单; 1:子菜单:2:按钮权限)';
COMMENT ON COLUMN sys_permission.perms IS '菜单权限编码';
COMMENT ON COLUMN sys_permission.perms_type IS '权限策略1显示2禁用';
COMMENT ON COLUMN sys_permission.sort_no IS '菜单排序';
COMMENT ON COLUMN sys_permission.always_show IS '聚合子路由: 1是0否';
COMMENT ON COLUMN sys_permission.icon IS '菜单图标';
COMMENT ON COLUMN sys_permission.is_route IS '是否路由菜单: 0:不是 1:是（默认值1）';
COMMENT ON COLUMN sys_permission.is_leaf IS '是否叶子节点: 1:是 0:不是';
COMMENT ON COLUMN sys_permission.keep_alive IS '是否缓存该页面: 1:是 0:不是';
COMMENT ON COLUMN sys_permission.hidden IS '是否隐藏路由: 0否,1是';
COMMENT ON COLUMN sys_permission.description IS '描述';
COMMENT ON COLUMN sys_permission.create_by IS '创建人';
COMMENT ON COLUMN sys_permission.create_time IS '创建时间';
COMMENT ON COLUMN sys_permission.update_by IS '更新人';
COMMENT ON COLUMN sys_permission.update_time IS '更新时间';
COMMENT ON COLUMN sys_permission.del_flag IS '删除状态 0正常 1已删除';
COMMENT ON COLUMN sys_permission.rule_flag IS '是否添加数据权限1是0否';
COMMENT ON COLUMN sys_permission.status IS '按钮权限状态(0无效1有效)';
COMMENT ON COLUMN sys_permission.internal_or_external IS '外链菜单打开方式 0/内部打开 1/外部打开';
ALTER TABLE sys_permission ADD CONSTRAINT sys_permission_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_permission_data_rule (
    id character varying(32) COLLATE "C" NOT NULL,
    permission_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    rule_name character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    rule_column character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    rule_conditions character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    rule_value character varying(300) COLLATE "C" DEFAULT NULL::character varying,
    status character varying(3) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_permission_data_rule.id IS 'ID';
COMMENT ON COLUMN sys_permission_data_rule.permission_id IS '菜单ID';
COMMENT ON COLUMN sys_permission_data_rule.rule_name IS '规则名称';
COMMENT ON COLUMN sys_permission_data_rule.rule_column IS '字段';
COMMENT ON COLUMN sys_permission_data_rule.rule_conditions IS '条件';
COMMENT ON COLUMN sys_permission_data_rule.rule_value IS '规则值';
COMMENT ON COLUMN sys_permission_data_rule.status IS '权限有效状态1有0否';
COMMENT ON COLUMN sys_permission_data_rule.create_time IS '创建时间';
COMMENT ON COLUMN sys_permission_data_rule.update_time IS '修改时间';
COMMENT ON COLUMN sys_permission_data_rule.update_by IS '修改人';
ALTER TABLE sys_permission_data_rule ADD CONSTRAINT sys_permission_data_rule_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_position (
    id character varying(32) COLLATE "C" NOT NULL,
    code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    post_rank character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    company_id character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(50) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_position.code IS '职务编码';
COMMENT ON COLUMN sys_position.name IS '职务名称';
COMMENT ON COLUMN sys_position.post_rank IS '职级';
COMMENT ON COLUMN sys_position.company_id IS '公司id';
COMMENT ON COLUMN sys_position.create_by IS '创建人';
COMMENT ON COLUMN sys_position.create_time IS '创建时间';
COMMENT ON COLUMN sys_position.update_by IS '修改人';
COMMENT ON COLUMN sys_position.update_time IS '修改时间';
COMMENT ON COLUMN sys_position.sys_org_code IS '组织机构编码';
ALTER TABLE sys_position ADD CONSTRAINT uniq_code UNIQUE USING ubtree (code) WITH (storage_type=USTORE);
ALTER TABLE sys_position ADD CONSTRAINT sys_position_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_quartz_job (
    id character varying(32) COLLATE "C" NOT NULL,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    del_flag integer,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    job_class_name character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    cron_expression character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    parameter character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    description character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    status integer
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_quartz_job.create_by IS '创建人';
COMMENT ON COLUMN sys_quartz_job.create_time IS '创建时间';
COMMENT ON COLUMN sys_quartz_job.del_flag IS '删除状态';
COMMENT ON COLUMN sys_quartz_job.update_by IS '修改人';
COMMENT ON COLUMN sys_quartz_job.update_time IS '修改时间';
COMMENT ON COLUMN sys_quartz_job.job_class_name IS '任务类名';
COMMENT ON COLUMN sys_quartz_job.cron_expression IS 'cron表达式';
COMMENT ON COLUMN sys_quartz_job.parameter IS '参数';
COMMENT ON COLUMN sys_quartz_job.description IS '描述';
COMMENT ON COLUMN sys_quartz_job.status IS '状态 0正常 -1停止';
ALTER TABLE sys_quartz_job ADD CONSTRAINT sys_quartz_job_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_role (
    id character varying(32) COLLATE "C" NOT NULL,
    role_name character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    role_code character varying(100) COLLATE "C" NOT NULL,
    description character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_role IS '角色表';
COMMENT ON COLUMN sys_role.id IS '主键id';
COMMENT ON COLUMN sys_role.role_name IS '角色名称';
COMMENT ON COLUMN sys_role.role_code IS '角色编码';
COMMENT ON COLUMN sys_role.description IS '描述';
COMMENT ON COLUMN sys_role.create_by IS '创建人';
COMMENT ON COLUMN sys_role.create_time IS '创建时间';
COMMENT ON COLUMN sys_role.update_by IS '更新人';
COMMENT ON COLUMN sys_role.update_time IS '更新时间';
ALTER TABLE sys_role ADD CONSTRAINT uniq_sys_role_role_code UNIQUE USING ubtree (role_code) WITH (storage_type=USTORE);
ALTER TABLE sys_role ADD CONSTRAINT sys_role_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_role_ai_user (
    id character varying(100) COLLATE "C" NOT NULL,
    role_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    user_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    data_rule_ids character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    operate_date timestamp without time zone,
    operate_ip character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_role_ai_user IS '角色ai用户权限表';
COMMENT ON COLUMN sys_role_ai_user.role_id IS '角色id';
COMMENT ON COLUMN sys_role_ai_user.user_id IS '权限id';
COMMENT ON COLUMN sys_role_ai_user.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_role_ai_user.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_ai_user.operate_ip IS '操作ip';
ALTER TABLE sys_role_ai_user ADD CONSTRAINT sys_role_ai_user_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_role_index (
    id character varying(32) COLLATE "C" NOT NULL,
    role_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    index_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    data_rule_ids character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    operate_date timestamp without time zone,
    operate_ip character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_role_index IS '角色指标权限表';
COMMENT ON COLUMN sys_role_index.role_id IS '角色id';
COMMENT ON COLUMN sys_role_index.index_id IS '权限id';
COMMENT ON COLUMN sys_role_index.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_role_index.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_index.operate_ip IS '操作ip';
ALTER TABLE sys_role_index ADD CONSTRAINT sys_role_index_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_role_knowledge (
    id character varying(32) COLLATE "C" NOT NULL,
    role_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    data_rule_ids character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    operate_date timestamp without time zone,
    operate_ip character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_role_knowledge IS '角色知识库权限表';
COMMENT ON COLUMN sys_role_knowledge.role_id IS '角色id';
COMMENT ON COLUMN sys_role_knowledge.knowledge_id IS '权限id';
COMMENT ON COLUMN sys_role_knowledge.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_role_knowledge.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_knowledge.operate_ip IS '操作ip';
ALTER TABLE sys_role_knowledge ADD CONSTRAINT sys_role_knowledge_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_role_knowledge_output (
    id character varying(32) COLLATE "C" NOT NULL,
    role_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    group_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    operate_date timestamp without time zone,
    operate_ip character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_role_knowledge_output IS '角色知识库输出要求权限表';
COMMENT ON COLUMN sys_role_knowledge_output.role_id IS '角色id';
COMMENT ON COLUMN sys_role_knowledge_output.group_id IS '知识库分组ID';
COMMENT ON COLUMN sys_role_knowledge_output.knowledge_id IS '知识库ID';
COMMENT ON COLUMN sys_role_knowledge_output.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_knowledge_output.operate_ip IS '操作ip';
ALTER TABLE sys_role_knowledge_output ADD CONSTRAINT sys_role_knowledge_output_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_role_module (
    id character varying(32) COLLATE "C" NOT NULL,
    role_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    module_source integer,
    data_rule_ids character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    operate_date timestamp without time zone,
    operate_ip character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_role_module IS '角色组件权限表';
COMMENT ON COLUMN sys_role_module.role_id IS '角色id';
COMMENT ON COLUMN sys_role_module.module_source IS '权限id';
COMMENT ON COLUMN sys_role_module.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_role_module.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_module.operate_ip IS '操作ip';
ALTER TABLE sys_role_module ADD CONSTRAINT sys_role_module_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_role_permission (
    id character varying(32) COLLATE "C" NOT NULL,
    role_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    permission_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    data_rule_ids character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    operate_date timestamp without time zone,
    operate_ip character varying(20) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_role_permission IS '角色权限表';
COMMENT ON COLUMN sys_role_permission.role_id IS '角色id';
COMMENT ON COLUMN sys_role_permission.permission_id IS '权限id';
COMMENT ON COLUMN sys_role_permission.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_role_permission.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_permission.operate_ip IS '操作ip';
ALTER TABLE sys_role_permission ADD CONSTRAINT sys_role_permission_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_tenant (
    id integer NOT NULL,
    name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    create_by character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    begin_date timestamp without time zone,
    end_date timestamp without time zone,
    status integer
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_tenant IS '多租户信息表';
COMMENT ON COLUMN sys_tenant.id IS '租户编码';
COMMENT ON COLUMN sys_tenant.name IS '租户名称';
COMMENT ON COLUMN sys_tenant.create_time IS '创建时间';
COMMENT ON COLUMN sys_tenant.create_by IS '创建人';
COMMENT ON COLUMN sys_tenant.begin_date IS '开始时间';
COMMENT ON COLUMN sys_tenant.end_date IS '结束时间';
COMMENT ON COLUMN sys_tenant.status IS '状态 1正常 0冻结';
ALTER TABLE sys_tenant ADD CONSTRAINT sys_tenant_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_third_account (
    id character varying(32) COLLATE "C" NOT NULL,
    sys_user_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    third_type character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    avatar character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    status smallint,
    del_flag smallint,
    realname character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    third_user_uuid character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    third_user_id character varying(100) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_third_account.id IS '编号';
COMMENT ON COLUMN sys_third_account.sys_user_id IS '第三方登录id';
COMMENT ON COLUMN sys_third_account.third_type IS '登录来源';
COMMENT ON COLUMN sys_third_account.avatar IS '头像';
COMMENT ON COLUMN sys_third_account.status IS '状态(1-正常,2-冻结)';
COMMENT ON COLUMN sys_third_account.del_flag IS '删除状态(0-正常,1-已删除)';
COMMENT ON COLUMN sys_third_account.realname IS '真实姓名';
COMMENT ON COLUMN sys_third_account.third_user_uuid IS '第三方账号';
COMMENT ON COLUMN sys_third_account.third_user_id IS '第三方app用户账号';
ALTER TABLE sys_third_account ADD CONSTRAINT sys_third_account_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_user (
    id character varying(64) COLLATE "C" NOT NULL,
    username character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    realname character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    password character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    salt character varying(45) COLLATE "C" DEFAULT NULL::character varying,
    avatar character varying(255) COLLATE "C" DEFAULT NULL::character varying,
    birthday timestamp without time zone,
    sex smallint,
    email character varying(45) COLLATE "C" DEFAULT NULL::character varying,
    phone character varying(45) COLLATE "C" DEFAULT NULL::character varying,
    org_code character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    status smallint,
    del_flag smallint,
    third_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    third_type character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    activiti_sync smallint,
    work_no character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    post character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    telephone character varying(45) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_by character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    user_identity smallint,
    depart_ids text,
    rel_tenant_ids character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    client_id character varying(64) COLLATE "C" DEFAULT NULL::character varying,
    datadate character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    user_login_name character varying(100) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_user IS '用户表';
COMMENT ON COLUMN sys_user.id IS '主键id';
COMMENT ON COLUMN sys_user.username IS '登录账号';
COMMENT ON COLUMN sys_user.realname IS '真实姓名';
COMMENT ON COLUMN sys_user.password IS '密码';
COMMENT ON COLUMN sys_user.salt IS 'md5密码盐';
COMMENT ON COLUMN sys_user.avatar IS '头像';
COMMENT ON COLUMN sys_user.birthday IS '生日';
COMMENT ON COLUMN sys_user.sex IS '性别(0-默认未知,1-男,2-女)';
COMMENT ON COLUMN sys_user.email IS '电子邮件';
COMMENT ON COLUMN sys_user.phone IS '电话';
COMMENT ON COLUMN sys_user.org_code IS '机构编码';
COMMENT ON COLUMN sys_user.status IS '性别(1-正常,2-冻结)';
COMMENT ON COLUMN sys_user.del_flag IS '删除状态(0-正常,1-已删除)';
COMMENT ON COLUMN sys_user.third_id IS '第三方登录的唯一标识';
COMMENT ON COLUMN sys_user.third_type IS '第三方类型';
COMMENT ON COLUMN sys_user.activiti_sync IS '同步工作流引擎(1-同步,0-不同步)';
COMMENT ON COLUMN sys_user.work_no IS '工号，唯一键';
COMMENT ON COLUMN sys_user.post IS '职务，关联职务表';
COMMENT ON COLUMN sys_user.telephone IS '座机号';
COMMENT ON COLUMN sys_user.create_by IS '创建人';
COMMENT ON COLUMN sys_user.create_time IS '创建时间';
COMMENT ON COLUMN sys_user.update_by IS '更新人';
COMMENT ON COLUMN sys_user.update_time IS '更新时间';
COMMENT ON COLUMN sys_user.user_identity IS '身份（1普通成员 2上级）';
COMMENT ON COLUMN sys_user.depart_ids IS '负责部门';
COMMENT ON COLUMN sys_user.rel_tenant_ids IS '多租户标识';
COMMENT ON COLUMN sys_user.client_id IS '设备ID';
COMMENT ON COLUMN sys_user.user_login_name IS '登录账号';
ALTER TABLE sys_user ADD CONSTRAINT sys_user_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_user_agent (
    id character varying(32) COLLATE "C" NOT NULL,
    user_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    agent_user_name character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    status character varying(2) COLLATE "C" DEFAULT NULL::character varying,
    create_name character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    create_time timestamp without time zone,
    update_name character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_by character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    update_time timestamp without time zone,
    sys_org_code character varying(50) COLLATE "C" DEFAULT NULL::character varying,
    sys_company_code character varying(50) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_user_agent IS '用户代理人设置';
COMMENT ON COLUMN sys_user_agent.id IS '序号';
COMMENT ON COLUMN sys_user_agent.user_name IS '用户名';
COMMENT ON COLUMN sys_user_agent.agent_user_name IS '代理人用户名';
COMMENT ON COLUMN sys_user_agent.start_time IS '代理开始时间';
COMMENT ON COLUMN sys_user_agent.end_time IS '代理结束时间';
COMMENT ON COLUMN sys_user_agent.status IS '状态0无效1有效';
COMMENT ON COLUMN sys_user_agent.create_name IS '创建人名称';
COMMENT ON COLUMN sys_user_agent.create_by IS '创建人登录名称';
COMMENT ON COLUMN sys_user_agent.create_time IS '创建日期';
COMMENT ON COLUMN sys_user_agent.update_name IS '更新人名称';
COMMENT ON COLUMN sys_user_agent.update_by IS '更新人登录名称';
COMMENT ON COLUMN sys_user_agent.update_time IS '更新日期';
COMMENT ON COLUMN sys_user_agent.sys_org_code IS '所属部门';
COMMENT ON COLUMN sys_user_agent.sys_company_code IS '所属公司';
ALTER TABLE sys_user_agent ADD CONSTRAINT uniq_username UNIQUE USING ubtree (user_name) WITH (storage_type=USTORE);
ALTER TABLE sys_user_agent ADD CONSTRAINT sys_user_agent_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_user_api (
    id character varying(32) COLLATE "C" NOT NULL,
    user_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    api_id character varying(32) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_user_api IS '用户接口表';
COMMENT ON COLUMN sys_user_api.id IS '主键id';
COMMENT ON COLUMN sys_user_api.user_id IS '用户id';
COMMENT ON COLUMN sys_user_api.api_id IS '接口id';
ALTER TABLE sys_user_api ADD CONSTRAINT sys_user_api_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_user_depart (
    id character varying(32) COLLATE "C" NOT NULL,
    user_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    dep_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    datadate character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN sys_user_depart.id IS 'id';
COMMENT ON COLUMN sys_user_depart.user_id IS '用户id';
COMMENT ON COLUMN sys_user_depart.dep_id IS '部门id';
ALTER TABLE sys_user_depart ADD CONSTRAINT sys_user_depart_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE sys_user_role (
    id character varying(32) COLLATE "C" NOT NULL,
    user_id character varying(32) COLLATE "C" DEFAULT NULL::character varying,
    role_id character varying(32) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE sys_user_role IS '用户角色表';
COMMENT ON COLUMN sys_user_role.id IS '主键id';
COMMENT ON COLUMN sys_user_role.user_id IS '用户id';
COMMENT ON COLUMN sys_user_role.role_id IS '角色id';
ALTER TABLE sys_user_role ADD CONSTRAINT sys_user_role_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE tasks_qa_industry_parse (
    task_id character varying(100) COLLATE "C" NOT NULL,
    notice_title character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    url character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    file_name character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    file_type character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    pubdate character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    source character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    inputtime timestamp without time zone DEFAULT pg_systimestamp(),
    updatetime timestamp without time zone DEFAULT pg_systimestamp(),
    status character varying(100) COLLATE "C" DEFAULT 'init'::character varying,
    userid character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    error_info text,
    ftp_url character varying(1000) COLLATE "C" DEFAULT NULL::character varying,
    original_no character varying(100) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON COLUMN tasks_qa_industry_parse.task_id IS 'md5';
ALTER TABLE tasks_qa_industry_parse ADD CONSTRAINT tasks_qa_industry_parse_pkey PRIMARY KEY USING ubtree  (task_id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE tool_management (
    id character varying(32) COLLATE "C" NOT NULL,
    tool_category character varying(50) COLLATE "C" NOT NULL,
    tool_name character varying(100) COLLATE "C" NOT NULL,
    tool_description character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    tool_parameters text,
    impl_type character varying(20) COLLATE "C" DEFAULT 'custom'::character varying,
    module_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    module_code_parameters text,
    tool_status character varying(2) COLLATE "C" DEFAULT 'Y'::character varying,
    create_time timestamp without time zone DEFAULT pg_systimestamp(),
    update_time timestamp without time zone DEFAULT pg_systimestamp(),
    cn_label character varying(200) COLLATE "C" DEFAULT NULL::character varying,
    en_label character varying(200) COLLATE "C" DEFAULT NULL::character varying
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE tool_management IS '大模型工具管理表';
COMMENT ON COLUMN tool_management.id IS '主键ID';
COMMENT ON COLUMN tool_management.tool_category IS '工具大类';
COMMENT ON COLUMN tool_management.tool_name IS '工具名称';
COMMENT ON COLUMN tool_management.tool_description IS '工具描述';
COMMENT ON COLUMN tool_management.tool_parameters IS '工具自定义参数';
COMMENT ON COLUMN tool_management.impl_type IS '关联工具类型 get_knowledge-知识库 apply_prompt-应用提示词 custom-用户自定义';
COMMENT ON COLUMN tool_management.module_code IS '关联工具编码';
COMMENT ON COLUMN tool_management.module_code_parameters IS '关联工具参数';
COMMENT ON COLUMN tool_management.tool_status IS '工具状态：N-停用，Y-正常';
COMMENT ON COLUMN tool_management.create_time IS '创建时间';
COMMENT ON COLUMN tool_management.update_time IS '更新时间';
COMMENT ON COLUMN tool_management.cn_label IS '工具中文展示名';
COMMENT ON COLUMN tool_management.en_label IS '工具英文展示名';
ALTER TABLE tool_management ADD CONSTRAINT idx_type_tool UNIQUE USING ubtree (tool_name, tool_category, impl_type) WITH (storage_type=USTORE);
ALTER TABLE tool_management ADD CONSTRAINT tool_management_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE trace_query_result (
    id integer DEFAULT nextval('trace_query_result_id_seq'::regclass) NOT NULL,
    trace_id character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    knowledge_code character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    query_status character varying(1) COLLATE "C" DEFAULT 'Y'::character varying,
    query_result text,
    query_time character varying(40) COLLATE "C" DEFAULT NULL::character varying,
    cost_time integer,
    comment character varying(500) COLLATE "C" DEFAULT NULL::character varying,
    app_source_query_result character varying(100) COLLATE "C" DEFAULT NULL::character varying,
    image_query_result text,
    whole_source_query_result text,
    image_cost_time integer,
    whole_source_cost_time integer
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE trace_query_result IS '溯源查询记录表';
COMMENT ON COLUMN trace_query_result.trace_id IS '追踪ID';
COMMENT ON COLUMN trace_query_result.knowledge_code IS '关联知识库编码';
COMMENT ON COLUMN trace_query_result.query_status IS '请求状态; Y成功 ; N失败';
COMMENT ON COLUMN trace_query_result.query_result IS '溯源配置请求结果';
COMMENT ON COLUMN trace_query_result.query_time IS '请求时间';
COMMENT ON COLUMN trace_query_result.cost_time IS '溯源配置花费时间(单位毫秒)';
COMMENT ON COLUMN trace_query_result.comment IS '备注';
COMMENT ON COLUMN trace_query_result.app_source_query_result IS 'APP的page页面请求结果';
COMMENT ON COLUMN trace_query_result.image_query_result IS '图片配置请求结果';
COMMENT ON COLUMN trace_query_result.whole_source_query_result IS '全部来源配置请求结果';
COMMENT ON COLUMN trace_query_result.image_cost_time IS '图片配置请求结果';
COMMENT ON COLUMN trace_query_result.whole_source_cost_time IS '全部来源配置话费时间(单位毫秒)';
ALTER TABLE trace_query_result ADD CONSTRAINT trace_query_result_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

SET search_path = bosz_test;
CREATE TABLE workflow_return_records (
    id integer DEFAULT nextval('workflow_return_records_id_seq'::regclass) NOT NULL,
    session_msg_no character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    user_id character varying(64) COLLATE "C" DEFAULT ''::character varying NOT NULL,
    question text,
    question_rewrite text,
    start_time text,
    end_time text,
    content text,
    "desc" text,
    source_site text,
    site_url text,
    "date" text,
    data_source text
)
WITH (orientation=row, compression=no, storage_type=USTORE, segment=off);
COMMENT ON TABLE workflow_return_records IS 'workflow返回记录表';
COMMENT ON COLUMN workflow_return_records.id IS '主键';
COMMENT ON COLUMN workflow_return_records.session_msg_no IS '会话中问题no';
COMMENT ON COLUMN workflow_return_records.user_id IS '用户id';
COMMENT ON COLUMN workflow_return_records.question IS '问题';
COMMENT ON COLUMN workflow_return_records.question_rewrite IS '问题改写';
COMMENT ON COLUMN workflow_return_records.start_time IS '问题开始时间';
COMMENT ON COLUMN workflow_return_records.end_time IS '问题结束时间';
COMMENT ON COLUMN workflow_return_records.content IS '内容';
COMMENT ON COLUMN workflow_return_records."desc" IS '标题';
COMMENT ON COLUMN workflow_return_records.source_site IS '来源网站';
COMMENT ON COLUMN workflow_return_records.site_url IS '来源网站';
COMMENT ON COLUMN workflow_return_records."date" IS '时间';
COMMENT ON COLUMN workflow_return_records.data_source IS '数据来源';
ALTER TABLE workflow_return_records ADD CONSTRAINT workflow_return_records_pkey PRIMARY KEY USING ubtree  (id) WITH (storage_type=USTORE);

