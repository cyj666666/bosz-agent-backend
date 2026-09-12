-- =====================================================================
-- agent_gauss_ddl.sql 自包含版（v7，GaussDB 兼容 MySQL 版可直接执行）
--   1. SET search_path = bosz_test, public：全部 179 张表建到 bosz_test
--   2. 语法已对齐 sql/20260819/app层/app_贷后报告_建表脚本.sql：类型 VARCHAR/CHAR/DECIMAL/TEXT/
--      TIMESTAMP/INT/BIGINT；主键内联 PRIMARY KEY (...)；id 统一 BIGINT NOT NULL AUTO_INCREMENT；
--      索引 CREATE [UNIQUE] INDEX；不再使用 COLLATE "C" / USING ubtree / storage_type=USTORE /
--      TABLESPACE / 表级 WITH(...) / CREATE SEQUENCE（50 个序列已全部并入 AUTO_INCREMENT）
--   3. 2026-09-12 精简：移除 36 张 app_ 前缀贷后报告业务表（含与该脚本重复的 34 张 + app_tax_info
--      + app_specific_loan_check_info），保留 app_api_financial_analysis_dd_* 3 张及 app_space_* 5 张；
--      本文件表数 215 -> 179
-- 前置条件：schema bosz_test 必须已存在（不存在先执行 CREATE SCHEMA bosz_test）
-- =====================================================================

SET search_path = bosz_test, public;

-- ================= 原脚本内容（179 张表 + 约束 + 注释 + 索引） =================
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

CREATE TABLE agent_conversation_history (
    conversation_id        VARCHAR(50) NOT NULL,
    session_no             VARCHAR(50) NOT NULL,
    agent_id               VARCHAR(32) NOT NULL,
    question               VARCHAR(1024) NOT NULL,
    question_class         VARCHAR(128),
    target_node            VARCHAR(128),
    target_detail          json,
    start_time             VARCHAR(40),
    answer                 TEXT,
    PRIMARY KEY (conversation_id, session_no)
);
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
CREATE INDEX idx_start_time ON agent_conversation_history (start_time);
CREATE INDEX idx_session_no ON agent_conversation_history (session_no);
CREATE INDEX idx_agent_id ON agent_conversation_history (agent_id);

CREATE TABLE agent_index_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    index_name             VARCHAR(100) NOT NULL,
    index_code             VARCHAR(32) NOT NULL,
    index_topic            VARCHAR(100),
    use_flag               VARCHAR(1) NOT NULL,
    synonym_word           TEXT,
    key_word               TEXT,
    center_key_word        TEXT,
    entity_type            VARCHAR(500),
    inner_priority         VARCHAR(50),
    source_type            VARCHAR(200),
    external_priority      VARCHAR(50),
    rec_group              VARCHAR(400),
    rec_question           VARCHAR(400),
    has_index_rela         VARCHAR(1),
    remark                 TEXT,
    input_time             VARCHAR(40) DEFAULT '' NOT NULL,
    update_time            VARCHAR(40) DEFAULT '' NOT NULL,
    index_desc             TEXT,
    sample_question        TEXT,
    object_type            VARCHAR(256),
    index_classification   VARCHAR(100),
    index_prompt           TEXT,
    final_result_flag      VARCHAR(1) DEFAULT 'N',
    final_result_content   VARCHAR(2000),
    rec_enterprise         VARCHAR(400),
    none_test_flag         VARCHAR(100) DEFAULT '1' NOT NULL,
    source_card_channel    VARCHAR(100),
    large_model_code       VARCHAR(100),
    large_model_content    VARCHAR(2000),
    rela_knowledge_id      VARCHAR(100),
    large_model_flag       VARCHAR(1) DEFAULT 'Y',
    PRIMARY KEY (id)
);
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
CREATE INDEX use_flag_2 ON agent_index_config (use_flag);
CREATE INDEX source_type ON agent_index_config (source_type);
CREATE INDEX index_code_3 ON agent_index_config (index_code);
CREATE INDEX index_code_2 ON agent_index_config (index_code);
CREATE INDEX use_flag ON agent_index_config (use_flag);
CREATE INDEX index_name ON agent_index_config (index_name);
CREATE UNIQUE INDEX agent_index_config_index_code_idx ON agent_index_config (index_code, source_type, none_test_flag);

CREATE TABLE agent_memory (
    mem_key                VARCHAR(128) NOT NULL,
    mem_content            TEXT,
    update_time            VARCHAR(40) NOT NULL,
    PRIMARY KEY (mem_key)
);
COMMENT ON TABLE agent_memory IS '智能体记忆';
COMMENT ON COLUMN agent_memory.mem_key IS '记忆主键';
COMMENT ON COLUMN agent_memory.mem_content IS '记忆内容';
COMMENT ON COLUMN agent_memory.update_time IS '更新时间';

CREATE TABLE agent_reply_message (
    agent_id               VARCHAR(128) NOT NULL,
    session_no             VARCHAR(50) NOT NULL,
    sort_no                BIGINT NOT NULL,
    sse_message            json,
    generated_time         VARCHAR(40) NOT NULL,
    session_msg_no         VARCHAR(128) DEFAULT '' NOT NULL,
    PRIMARY KEY (session_no, session_msg_no, sort_no)
);
COMMENT ON TABLE agent_reply_message IS '智能体问答记录表';
COMMENT ON COLUMN agent_reply_message.agent_id IS '智能体ID';
COMMENT ON COLUMN agent_reply_message.session_no IS '会话号';
COMMENT ON COLUMN agent_reply_message.sort_no IS '排序号';
COMMENT ON COLUMN agent_reply_message.sse_message IS '服务器发送事件消息';
COMMENT ON COLUMN agent_reply_message.generated_time IS '生成时间';
CREATE INDEX generated_time ON agent_reply_message (generated_time);
CREATE INDEX sort_no ON agent_reply_message (sort_no);
CREATE INDEX agent_id_session_no ON agent_reply_message (agent_id, session_no);

CREATE TABLE agent_rule (
    id                       BIGINT NOT NULL AUTO_INCREMENT,
    rule_name                VARCHAR(255),
    rule_text                VARCHAR(1000),
    parsed_expression        VARCHAR(1000),
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

CREATE TABLE agent_rule_prompt (
    key                    VARCHAR(300) NOT NULL,
    prompt                 TEXT NOT NULL,
    PRIMARY KEY (key)
);
COMMENT ON TABLE agent_rule_prompt IS 'Agent大模型提示词配置表';
COMMENT ON COLUMN agent_rule_prompt.key IS '提示词唯一标识key';
COMMENT ON COLUMN agent_rule_prompt.prompt IS 'prompt提示词内容';

CREATE TABLE agent_search_history (
    agent_id               VARCHAR(128) NOT NULL,
    session_no             VARCHAR(100) NOT NULL,
    user_id                VARCHAR(128) NOT NULL,
    question               VARCHAR(1024),
    start_time             VARCHAR(40),
    final_answer           TEXT,
    end_time               VARCHAR(40),
    edit_final_answer      TEXT,
    fav_final_answer       SMALLINT,
    status                 VARCHAR(20) DEFAULT 'running' NOT NULL,
    session_msg_no         VARCHAR(128) DEFAULT '' NOT NULL,
    async                  SMALLINT DEFAULT 0,
    PRIMARY KEY (session_no, session_msg_no)
);
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
CREATE INDEX agent_id_user_id ON agent_search_history (agent_id, user_id);
CREATE INDEX idx_user_id ON agent_search_history (user_id);

CREATE TABLE agent_search_memory (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    agent_id               VARCHAR(128) NOT NULL,
    session_no             VARCHAR(50) NOT NULL,
    mem_type               VARCHAR(128) NOT NULL,
    mem_content            TEXT,
    generated_time         VARCHAR(40) NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE agent_search_memory IS '智能体问答记录表';
COMMENT ON COLUMN agent_search_memory.id IS 'ID';
COMMENT ON COLUMN agent_search_memory.agent_id IS '智能体ID';
COMMENT ON COLUMN agent_search_memory.session_no IS '会话号';
COMMENT ON COLUMN agent_search_memory.mem_type IS '记忆类型';
COMMENT ON COLUMN agent_search_memory.mem_content IS '记忆内容';
COMMENT ON COLUMN agent_search_memory.generated_time IS '生成时间';
CREATE INDEX idx_mem_type ON agent_search_memory (mem_type);

CREATE TABLE agent_tool_call_message (
    session_no             VARCHAR(100) NOT NULL,
    tool_name              VARCHAR(128) NOT NULL,
    call_id                VARCHAR(200) NOT NULL,
    agent_id               VARCHAR(32) NOT NULL,
    parallel_key           VARCHAR(256) NOT NULL,
    tool_args              TEXT,
    agent_name             VARCHAR(128) NOT NULL,
    start_time             VARCHAR(40) NOT NULL,
    call_time              VARCHAR(40) NOT NULL,
    finish_time            VARCHAR(40),
    end_time               VARCHAR(40),
    interrupt_time         VARCHAR(40),
    tool_result            TEXT,
    interrupt_result       TEXT,
    status                 VARCHAR(20),
    state_store_path       VARCHAR(512) DEFAULT '',
    session_msg_no         VARCHAR(128) DEFAULT '' NOT NULL,
    PRIMARY KEY (session_no, tool_name, call_id, parallel_key)
);
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
CREATE INDEX start_time ON agent_tool_call_message (start_time);
CREATE INDEX session_no ON agent_tool_call_message (session_no);
CREATE INDEX idx_call_id ON agent_tool_call_message (call_id);

CREATE TABLE ai_agent_info (
    ai_agent_id            VARCHAR(64) NOT NULL,
    ai_agent_name          VARCHAR(255) NOT NULL,
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_metric_id         VARCHAR(64),
    status                 VARCHAR(10) NOT NULL,
    agent_topic            VARCHAR(80) DEFAULT '' NOT NULL,
    PRIMARY KEY (ai_agent_id)
);
COMMENT ON TABLE ai_agent_info IS '主题智能体信息表';
COMMENT ON COLUMN ai_agent_info.ai_agent_id IS '主题智能体ID';
COMMENT ON COLUMN ai_agent_info.ai_agent_name IS '主题智能体名称';
COMMENT ON COLUMN ai_agent_info.input_time IS '创建时间';
COMMENT ON COLUMN ai_agent_info.update_time IS '更新时间';
COMMENT ON COLUMN ai_agent_info.data_metric_id IS '主题智能体关联的工作流指标ID';
COMMENT ON COLUMN ai_agent_info.status IS '标志位';

CREATE TABLE ai_component_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    catalog_code           VARCHAR(100) NOT NULL,
    catalog_name           VARCHAR(200) NOT NULL,
    catlaog_classification VARCHAR(40) NOT NULL,
    catalog_status         VARCHAR(2),
    input_time             VARCHAR(40),
    update_time            VARCHAR(40),
    catalog_desc           TEXT,
    icon                   VARCHAR(500),
    order_no               INT,
    catalog_prompt         VARCHAR(1000),
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX catalog_code ON ai_component_config (catalog_code);

CREATE TABLE ai_menu_config (
    id                     VARCHAR(32) NOT NULL,
    menu_code              VARCHAR(200) NOT NULL,
    menu_name              VARCHAR(200),
    status                 VARCHAR(2) DEFAULT 'Y',
    url                    VARCHAR(500),
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    order_num              INT DEFAULT 0,
    icon                   VARCHAR(500),
    component_url          VARCHAR(200),
    PRIMARY KEY (id)
);
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
CREATE INDEX input_time_idx ON ai_menu_config (input_time);
CREATE INDEX menu_code_idx ON ai_menu_config (menu_code);

CREATE TABLE amar_claw_memory_backups (
    _id                    BIGINT NOT NULL AUTO_INCREMENT,
    id                     VARCHAR(32) NOT NULL,
    user_id                VARCHAR(32) NOT NULL,
    container_id           VARCHAR(32),
    backup_type            VARCHAR(20) DEFAULT 'auto',
    backup_path            VARCHAR(500),
    backup_size            BIGINT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (_id)
);
COMMENT ON TABLE amar_claw_memory_backups IS '记忆备份表';
COMMENT ON COLUMN amar_claw_memory_backups._id IS '主键ID';
COMMENT ON COLUMN amar_claw_memory_backups.id IS '备份ID';
COMMENT ON COLUMN amar_claw_memory_backups.user_id IS '用户ID';
COMMENT ON COLUMN amar_claw_memory_backups.container_id IS '容器ID';
COMMENT ON COLUMN amar_claw_memory_backups.backup_type IS '备份类型: auto/manual';
COMMENT ON COLUMN amar_claw_memory_backups.backup_path IS '备份路径';
COMMENT ON COLUMN amar_claw_memory_backups.backup_size IS '备份大小';
COMMENT ON COLUMN amar_claw_memory_backups.created_at IS '创建时间';

CREATE TABLE api_db_cache (
    id                     VARCHAR(32) NOT NULL,
    cache_key              VARCHAR(100),
    cache_value            TEXT,
    input_time             VARCHAR(20),
    PRIMARY KEY (id)
);
COMMENT ON TABLE api_db_cache IS '接口缓存表';

CREATE TABLE app_api_financial_analysis_dd_cashflow (
    userid                  VARCHAR(50) NOT NULL,
    reportdate              VARCHAR(50) NOT NULL,
    combinetype             VARCHAR(50) NOT NULL,
    companyname             VARCHAR(200) NOT NULL,
    sessionno               VARCHAR(50) NOT NULL,
    excelid                 VARCHAR(50),
    excelurl                VARCHAR(500),
    uptime                  TIMESTAMP,
    reportno                VARCHAR(50),
    acceptinvrec            DECIMAL(38,18),
    addpledgetdeposit       DECIMAL(38,18),
    buyfilassetpay          DECIMAL(38,18),
    buygoodsservicepay      DECIMAL(38,18),
    buysubsidiarypay        DECIMAL(38,18),
    cashequibeginning       DECIMAL(38,18),
    cashequiending          DECIMAL(38,18),
    cashequiendingbalance   DECIMAL(38,18),
    cashequiendingother     DECIMAL(38,18),
    dispfilassetrec         DECIMAL(38,18),
    disposalinvrec          DECIMAL(38,18),
    dispsubsidiaryrec       DECIMAL(38,18),
    divipay                 DECIMAL(38,18),
    diviprofitorintpay      DECIMAL(38,18),
    effectexchangerate      DECIMAL(38,18),
    employeepay             DECIMAL(38,18),
    finaflowbalance         DECIMAL(38,18),
    finaflowinbalance       DECIMAL(38,18),
    finaflowinother         DECIMAL(38,18),
    finaflowother           DECIMAL(38,18),
    finaflowoutbalance      DECIMAL(38,18),
    finaflowoutother        DECIMAL(38,18),
    getsubsidiarypay        DECIMAL(38,18),
    indemnitypay            DECIMAL(38,18),
    intandcommpay           DECIMAL(38,18),
    intandcommrec           DECIMAL(38,18),
    invflowbalance          DECIMAL(38,18),
    invflowinbalance        DECIMAL(38,18),
    invflowinother          DECIMAL(38,18),
    invflowother            DECIMAL(38,18),
    invflowoutbalance       DECIMAL(38,18),
    invflowoutother         DECIMAL(38,18),
    invincomerec            DECIMAL(38,18),
    invpay                  DECIMAL(38,18),
    issuebondrec            DECIMAL(38,18),
    loanrec                 DECIMAL(38,18),
    ndloanadvances          DECIMAL(38,18),
    netfinacashflow         DECIMAL(38,18),
    netinvcashflow          DECIMAL(38,18),
    netoperatecashflow      DECIMAL(38,18),
    netrirec                DECIMAL(38,18),
    niborrowfromcbank       DECIMAL(38,18),
    niborrowfromfi          DECIMAL(38,18),
    niborrowfund            DECIMAL(38,18),
    nibuybackfund           DECIMAL(38,18),
    nicashequi              DECIMAL(38,18),
    nicashequibalance       DECIMAL(38,18),
    nicashequiother         DECIMAL(38,18),
    nideposit               DECIMAL(38,18),
    nidepositincbankfi      DECIMAL(38,18),
    nidisptradefasset       DECIMAL(38,18),
    niinsureddepositinv     DECIMAL(38,18),
    niloanadvances          DECIMAL(38,18),
    nipledgeloan            DECIMAL(38,18),
    operateflowbalance      DECIMAL(38,18),
    operateflowinbalance    DECIMAL(38,18),
    operateflowinother      DECIMAL(38,18),
    operateflowother        DECIMAL(38,18),
    operateflowoutbalance   DECIMAL(38,18),
    operateflowoutother     DECIMAL(38,18),
    otherfinapay            DECIMAL(38,18),
    otherfinarec            DECIMAL(38,18),
    otherinvpay             DECIMAL(38,18),
    otherinvrec             DECIMAL(38,18),
    otheroperatepay         DECIMAL(38,18),
    otheroperaterec         DECIMAL(38,18),
    premiumrec              DECIMAL(38,18),
    reducepledgetdeposit    DECIMAL(38,18),
    repaydebtpay            DECIMAL(38,18),
    salegoodsservicerec     DECIMAL(38,18),
    subsidiaryaccept        DECIMAL(38,18),
    subsidiarypay           DECIMAL(38,18),
    subsidiaryreductcapital DECIMAL(38,18),
    sumfinaflowin           DECIMAL(38,18),
    sumfinaflowout          DECIMAL(38,18),
    suminvflowin            DECIMAL(38,18),
    suminvflowout           DECIMAL(38,18),
    sumoperateflowin        DECIMAL(38,18),
    sumoperateflowout       DECIMAL(38,18),
    taxpay                  DECIMAL(38,18),
    taxreturnrec            DECIMAL(38,18),
    PRIMARY KEY (userid, reportdate, combinetype, companyname)
);
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

CREATE TABLE app_api_financial_analysis_dd_debt (
    userid                     VARCHAR(50) NOT NULL,
    reportdate                 VARCHAR(50) NOT NULL,
    combinetype                VARCHAR(50) NOT NULL,
    companyname                VARCHAR(200) NOT NULL,
    sessionno                  VARCHAR(50) NOT NULL,
    excelid                    VARCHAR(50),
    excelurl                   VARCHAR(500),
    uptime                     TIMESTAMP,
    reportno                   VARCHAR(50),
    monetaryfund               DECIMAL(38,18),
    settlementprovision        DECIMAL(38,18),
    lendfund                   DECIMAL(38,18),
    tradefasset                DECIMAL(38,18),
    billrec                    DECIMAL(38,18),
    accountrec                 DECIMAL(38,18),
    advancepay                 DECIMAL(38,18),
    premiumrec                 DECIMAL(38,18),
    rirec                      DECIMAL(38,18),
    ricontactreserverec        DECIMAL(38,18),
    interestrec                DECIMAL(38,18),
    dividendrec                DECIMAL(38,18),
    otherrec                   DECIMAL(38,18),
    exportrebaterec            DECIMAL(38,18),
    subsidyrec                 DECIMAL(38,18),
    internalrec                DECIMAL(38,18),
    buysellbackfasset          DECIMAL(38,18),
    inventory                  DECIMAL(38,18),
    nonlassetoneyear           DECIMAL(38,18),
    otherlasset                DECIMAL(38,18),
    lassetother                DECIMAL(38,18),
    lassetbalance              DECIMAL(38,18),
    sumlasset                  DECIMAL(38,18),
    loanadvances               DECIMAL(38,18),
    saleablefasset             DECIMAL(38,18),
    heldmaturityinv            DECIMAL(38,18),
    ltrec                      DECIMAL(38,18),
    ltequityinv                DECIMAL(38,18),
    estateinvest               DECIMAL(38,18),
    fixedasset                 DECIMAL(38,18),
    constructionprogress       DECIMAL(38,18),
    constructionmaterial       DECIMAL(38,18),
    liquidatefixedasset        DECIMAL(38,18),
    productbiologyasset        DECIMAL(38,18),
    oilgasasset                DECIMAL(38,18),
    intangibleasset            DECIMAL(38,18),
    developexp                 DECIMAL(38,18),
    goodwill                   DECIMAL(38,18),
    ltdeferasset               DECIMAL(38,18),
    deferincometaxasset        DECIMAL(38,18),
    othernonlasset             DECIMAL(38,18),
    nonlassetother             DECIMAL(38,18),
    nonlassetbalance           DECIMAL(38,18),
    sumnonlasset               DECIMAL(38,18),
    assetother                 DECIMAL(38,18),
    assetbalance               DECIMAL(38,18),
    sumasset                   DECIMAL(38,18),
    stborrow                   DECIMAL(38,18),
    borrowfromcbank            DECIMAL(38,18),
    deposit                    DECIMAL(38,18),
    borrowfund                 DECIMAL(38,18),
    tradefliab                 DECIMAL(38,18),
    billpay                    DECIMAL(38,18),
    accountpay                 DECIMAL(38,18),
    advancereceive             DECIMAL(38,18),
    sellbuybackfasset          DECIMAL(38,18),
    commpay                    DECIMAL(38,18),
    salarypay                  DECIMAL(38,18),
    taxpay                     DECIMAL(38,18),
    interestpay                DECIMAL(38,18),
    dividendpay                DECIMAL(38,18),
    ripay                      DECIMAL(38,18),
    internalpay                DECIMAL(38,18),
    otherpay                   DECIMAL(38,18),
    anticipatelliab            DECIMAL(38,18),
    contactreserve             DECIMAL(38,18),
    agenttradesecurity         DECIMAL(38,18),
    agentuwsecurity            DECIMAL(38,18),
    deferincomeoneyear         DECIMAL(38,18),
    stbondrec                  DECIMAL(38,18),
    nonlliaboneyear            DECIMAL(38,18),
    otherlliab                 DECIMAL(38,18),
    lliabother                 DECIMAL(38,18),
    lliabbalance               DECIMAL(38,18),
    sumlliab                   DECIMAL(38,18),
    ltborrow                   DECIMAL(38,18),
    bondpay                    DECIMAL(38,18),
    sustainbond                DECIMAL(38,18),
    preferstocbond             DECIMAL(38,18),
    ltaccountpay               DECIMAL(38,18),
    specialpay                 DECIMAL(38,18),
    anticipateliab             DECIMAL(38,18),
    deferincome                DECIMAL(38,18),
    deferincometaxliab         DECIMAL(38,18),
    othernonlliab              DECIMAL(38,18),
    nonlliabother              DECIMAL(38,18),
    nonlliabbalance            DECIMAL(38,18),
    sumnonlliab                DECIMAL(38,18),
    liabother                  DECIMAL(38,18),
    liabbalance                DECIMAL(38,18),
    sumliab                    DECIMAL(38,18),
    sharecapital               DECIMAL(38,18),
    capitalreserve             DECIMAL(38,18),
    inventoryshare             DECIMAL(38,18),
    specialreserve             DECIMAL(38,18),
    surplusreserve             DECIMAL(38,18),
    generalriskprepare         DECIMAL(38,18),
    unconfirminvloss           DECIMAL(38,18),
    retainedearning            DECIMAL(38,18),
    plancashdivi               DECIMAL(38,18),
    diffconversionfc           DECIMAL(38,18),
    parentequityother          DECIMAL(38,18),
    parentequitybalance        DECIMAL(38,18),
    sumparentequity            DECIMAL(38,18),
    minorityequity             DECIMAL(38,18),
    shequityother              DECIMAL(38,18),
    shequitybalance            DECIMAL(38,18),
    sumshequity                DECIMAL(48,18),
    liabshequityother          DECIMAL(38,18),
    liabshequitybalance        DECIMAL(38,18),
    sumliabshequity            DECIMAL(38,18),
    ltsalarypay                DECIMAL(38,18),
    fvaluefasset               DECIMAL(38,18),
    definefvaluefasset         DECIMAL(38,18),
    fvaluefliab                DECIMAL(38,18),
    definefvaluefliab          DECIMAL(38,18),
    otherequity                DECIMAL(38,18),
    otherequityother           DECIMAL(38,18),
    othercincome               DECIMAL(38,18),
    clheldsaleass              DECIMAL(38,18),
    clheldsaleliab             DECIMAL(38,18),
    othernonfasset             DECIMAL(38,18),
    otherequityinv             DECIMAL(38,18),
    derivefliab                DECIMAL(38,18),
    contractliab               DECIMAL(38,18),
    amorcostfasset             DECIMAL(38,18),
    heldsaleass                DECIMAL(38,18),
    fvaluecompfasset           DECIMAL(38,18),
    amorcostfliabfld           DECIMAL(38,18),
    drawingexp                 DECIMAL(38,18),
    contractasset              DECIMAL(38,18),
    accountbillrec             DECIMAL(38,18),
    heldsaleliab               DECIMAL(38,18),
    derivefasset               DECIMAL(38,18),
    accountbillpay             DECIMAL(38,18),
    shortfinancing             DECIMAL(30,18),
    credinv                    DECIMAL(38,18),
    fvaluecompfassetfld        DECIMAL(38,18),
    othcredinv                 DECIMAL(38,18),
    marginoutfund              DECIMAL(30,4),
    amorcostfliab              DECIMAL(38,18),
    amorcostfassetfld          DECIMAL(38,18),
    totalotherrece             DECIMAL(38,18),
    financerece                DECIMAL(38,18),
    userightasset              DECIMAL(38,18),
    leaseliab                  DECIMAL(38,18),
    tradefinassetnotfvtpl      DECIMAL(38,18),
    tradefinliabnotfvtpl       DECIMAL(38,18),
    totalotherpayable          DECIMAL(38,18),
    consumptivebiologicalasset DECIMAL(30,4),
    PRIMARY KEY (userid, reportdate, combinetype, companyname)
);
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

CREATE TABLE app_api_financial_analysis_dd_profit (
    userid                 VARCHAR(50) NOT NULL,
    reportdate             VARCHAR(50) NOT NULL,
    combinetype            VARCHAR(50) NOT NULL,
    companyname            VARCHAR(200) NOT NULL,
    sessionno              VARCHAR(50) NOT NULL,
    excelid                VARCHAR(50),
    excelurl               VARCHAR(500),
    uptime                 TIMESTAMP,
    reportno               VARCHAR(50),
    assetdevalueloss       DECIMAL(38,18),
    basiceps               DECIMAL(38,18),
    cincomebalance1        DECIMAL(38,18),
    cincomebalance2        DECIMAL(38,18),
    combinednetprofitb     DECIMAL(38,18),
    commexp                DECIMAL(38,18),
    commreve               DECIMAL(38,18),
    dilutedeps             DECIMAL(38,18),
    exchangeincome         DECIMAL(38,18),
    financeexp             DECIMAL(38,18),
    fvalueincome           DECIMAL(38,18),
    incometax              DECIMAL(38,18),
    intexp                 DECIMAL(38,18),
    intreve                DECIMAL(38,18),
    investincome           DECIMAL(38,18),
    investjointincome      DECIMAL(38,18),
    manageexp              DECIMAL(38,18),
    minoritycincome        DECIMAL(38,18),
    minorityincome         DECIMAL(38,18),
    minorityothercincome   DECIMAL(38,18),
    netcontactreserve      DECIMAL(38,18),
    netindemnityexp        DECIMAL(38,18),
    netprofit              DECIMAL(38,18),
    netprofitbalance1      DECIMAL(38,18),
    netprofitbalance2      DECIMAL(38,18),
    netprofitother1        DECIMAL(38,18),
    netprofitother2        DECIMAL(38,18),
    nonlassetnetloss       DECIMAL(38,18),
    nonoperateexp          DECIMAL(38,18),
    nonoperatereve         DECIMAL(38,18),
    operateexp             DECIMAL(38,18),
    operateprofit          DECIMAL(38,18),
    operateprofitbalance   DECIMAL(38,18),
    operateprofitother     DECIMAL(38,18),
    operatereve            DECIMAL(38,18),
    operatetax             DECIMAL(38,18),
    othercincome           DECIMAL(38,18),
    otherexp               DECIMAL(38,18),
    otherreve              DECIMAL(38,18),
    parentcincome          DECIMAL(38,18),
    parentnetprofit        DECIMAL(38,18),
    parentothercincome     DECIMAL(38,18),
    policydiviexp          DECIMAL(38,18),
    premiumearned          DECIMAL(38,18),
    rdexp                  DECIMAL(38,18),
    riexp                  DECIMAL(38,18),
    saleexp                DECIMAL(38,18),
    sumcincome             DECIMAL(38,18),
    sumprofit              DECIMAL(38,18),
    sumprofitbalance       DECIMAL(38,18),
    sumprofitother         DECIMAL(38,18),
    surrenderpremium       DECIMAL(38,18),
    totaloperateexp        DECIMAL(38,18),
    totaloperateexpother   DECIMAL(38,18),
    totaloperatereve       DECIMAL(38,18),
    totaloperatereveother  DECIMAL(38,18),
    unconfirminvloss       DECIMAL(38,18),
    fvalueosalable         DECIMAL(38,18),
    maturityrecsalable     DECIMAL(38,18),
    effectivecaflhedging   DECIMAL(38,18),
    diffconversionfc       DECIMAL(38,18),
    othercincomeother      DECIMAL(38,18),
    othercincomebalance    DECIMAL(38,18),
    nonlassetreve          DECIMAL(38,18),
    parothcinother         DECIMAL(38,18),
    parothcinbala          DECIMAL(38,18),
    combinedsumcincomeb    DECIMAL(38,18),
    sumcincomeother        DECIMAL(38,18),
    adisposalincome        DECIMAL(38,18),
    continuousonprofit     DECIMAL(38,18),
    terminationonprofit    DECIMAL(38,18),
    miotherincome          DECIMAL(38,18),
    ofwintexp              DECIMAL(38,18),
    ofwintreve             DECIMAL(38,18),
    otherequityinvfvalue   DECIMAL(38,18),
    credriskfvalue         DECIMAL(38,18),
    othcredinvfvalue       DECIMAL(38,18),
    fassetrecother         DECIMAL(38,18),
    othcredinvcred         DECIMAL(38,18),
    creddevalueloss        DECIMAL(38,18),
    netexhedgincome        DECIMAL(38,18),
    ofwrdexp               DECIMAL(38,18),
    acfendincome           DECIMAL(38,18),
    assetimpairmentincome  DECIMAL(38,18),
    creditimpairmentincome DECIMAL(38,18),
    PRIMARY KEY (userid, reportdate, combinetype, companyname)
);
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

CREATE TABLE app_space_config (
    space_id               BIGINT NOT NULL AUTO_INCREMENT,
    space_name             VARCHAR(100),
    space_desc             VARCHAR(1000),
    relation_account       VARCHAR(2000),
    index_space_flag       VARCHAR(1) DEFAULT 'N',
    index_content          TEXT,
    default_prompt         VARCHAR(1000),
    sort_no                INT DEFAULT 0,
    space_status           VARCHAR(1) DEFAULT 'Y',
    upload_flag            VARCHAR(1) DEFAULT 'N',
    input_time             VARCHAR(20),
    update_time            VARCHAR(20),
    relation_org           VARCHAR(500),
    space_code             VARCHAR(100),
    finance_upload_flag    VARCHAR(2) DEFAULT 'N',
    welcome_content        VARCHAR(100),
    black_icon             VARCHAR(500),
    icon                   VARCHAR(500),
    PRIMARY KEY (space_id)
);
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

CREATE TABLE app_space_inspiration_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    space_id               INT,
    belong_group           VARCHAR(100),
    question               VARCHAR(500),
    status                 VARCHAR(1) DEFAULT 'Y',
    sort_no                INT DEFAULT 0,
    input_time             VARCHAR(20),
    update_time            VARCHAR(20),
    question_type          VARCHAR(32),
    entity_type            VARCHAR(40),
    entity_name            VARCHAR(200),
    index_code             VARCHAR(100),
    index_id               VARCHAR(32),
    show_deepseek          VARCHAR(10) DEFAULT 'N',
    hover_flag             VARCHAR(100) DEFAULT '',
    PRIMARY KEY (id)
);
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

CREATE TABLE app_space_relate_account (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    account                VARCHAR(100),
    relate_org             VARCHAR(100),
    space_id               VARCHAR(1000),
    status                 VARCHAR(1) DEFAULT 'Y',
    sort_no                INT DEFAULT 0,
    input_time             VARCHAR(20),
    update_time            VARCHAR(20),
    do_auth_index          VARCHAR(2) DEFAULT 'Y' NOT NULL,
    report_text_type       VARCHAR(10) DEFAULT 'h5',
    relate_knowledge       VARCHAR(2000),
    relate_menu            VARCHAR(2000),
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX account ON app_space_relate_account (account);

CREATE TABLE app_space_relate_agent (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    space_id               INT,
    agent_id               INT,
    sort_no                INT DEFAULT 0,
    status                 VARCHAR(1) DEFAULT 'Y',
    input_time             VARCHAR(20),
    update_time            VARCHAR(20),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_space_relate_agent IS '应用空间关联Agent信息表';
COMMENT ON COLUMN app_space_relate_agent.id IS '主键ID';
COMMENT ON COLUMN app_space_relate_agent.space_id IS '关联空间ID';
COMMENT ON COLUMN app_space_relate_agent.agent_id IS '关联AgentId';
COMMENT ON COLUMN app_space_relate_agent.sort_no IS '排序号';
COMMENT ON COLUMN app_space_relate_agent.status IS '关联状态;Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN app_space_relate_agent.input_time IS '创建时间';
COMMENT ON COLUMN app_space_relate_agent.update_time IS '更新时间';

CREATE TABLE app_space_relate_knowledge (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    space_id               INT,
    label_code_level_1     VARCHAR(100),
    label_name_level_1     VARCHAR(200),
    label_code_level_2     VARCHAR(100),
    label_name_level_2     VARCHAR(200),
    label_code_level_3     VARCHAR(100),
    label_name_level_3     VARCHAR(200),
    label_code_level_4     VARCHAR(100),
    label_name_level_4     VARCHAR(200),
    label_dict_code        VARCHAR(32),
    status                 VARCHAR(1) DEFAULT 'Y',
    sort_no                INT DEFAULT 0,
    input_time             VARCHAR(20),
    update_time            VARCHAR(20),
    PRIMARY KEY (id)
);
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

CREATE TABLE bank_internal_indicators_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    question_category      VARCHAR(100),
    category               VARCHAR(100),
    sub_category           VARCHAR(100),
    indicator_code         TEXT,
    indicator              TEXT,
    indicator_show_code    TEXT,
    indicator_show         TEXT,
    key_word               TEXT,
    source_table           VARCHAR(100),
    empty_indicator_method VARCHAR(100),
    org_account            VARCHAR(400),
    PRIMARY KEY (id)
);
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

CREATE TABLE bank_module_info (
    _id                    BIGINT NOT NULL AUTO_INCREMENT,
    bankid                 VARCHAR(1000),
    modulecode             VARCHAR(1000),
    largemodelcode         VARCHAR(1000),
    PRIMARY KEY (_id)
);
COMMENT ON COLUMN bank_module_info._id IS '主键ID';

CREATE TABLE batch_prompt_task (
    id                     VARCHAR(100) NOT NULL,
    trace_id               VARCHAR(32),
    knowledge_code         VARCHAR(100),
    prompt_content         TEXT,
    operate_time           VARCHAR(20),
    ent_name               VARCHAR(200),
    PRIMARY KEY (id)
);
COMMENT ON TABLE batch_prompt_task IS '知识库批量任务表';
COMMENT ON COLUMN batch_prompt_task.trace_id IS '追踪ID';
COMMENT ON COLUMN batch_prompt_task.knowledge_code IS '知识库编码';
COMMENT ON COLUMN batch_prompt_task.prompt_content IS '文案内容';
COMMENT ON COLUMN batch_prompt_task.operate_time IS '操作时间';
COMMENT ON COLUMN batch_prompt_task.ent_name IS '企业名称';

CREATE TABLE call_llm_record (
    hub_account            VARCHAR(256) NOT NULL,
    trace_id               VARCHAR(64) NOT NULL,
    sort_no                BIGINT NOT NULL,
    request_time           VARCHAR(40) NOT NULL,
    status                 INT,
    content                TEXT,
    request_body           TEXT,
    response_time          VARCHAR(40),
    large_model_code       VARCHAR(64),
    api_key                VARCHAR(256),
    prompt_tokens          BIGINT,
    completion_tokens      BIGINT,
    session_msg_no         VARCHAR(64),
    PRIMARY KEY (trace_id, sort_no)
);

CREATE TABLE ces_field_kongj (
    id                     VARCHAR(36) NOT NULL,
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    name                   VARCHAR(32),
    sex                    VARCHAR(32),
    radio                  VARCHAR(32),
    checkbox               VARCHAR(32),
    sel_mut                VARCHAR(32),
    sel_search             VARCHAR(32),
    birthday               TIMESTAMP,
    pic                    VARCHAR(1000),
    files                  VARCHAR(1000),
    remakr                 TEXT,
    fuwenb                 TEXT,
    user_sel               VARCHAR(200),
    dep_sel                VARCHAR(200),
    ddd                    DECIMAL(10,0),
    PRIMARY KEY (id)
);
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

CREATE TABLE ces_order_customer (
    id                     VARCHAR(36) NOT NULL,
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    name                   VARCHAR(32),
    sex                    VARCHAR(1),
    birthday               TIMESTAMP,
    age                    INT,
    address                VARCHAR(300),
    order_main_id          VARCHAR(32),
    PRIMARY KEY (id)
);
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

CREATE TABLE ces_order_goods (
    id                     VARCHAR(36) NOT NULL,
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    good_name              VARCHAR(32),
    price                  DECIMAL(38,18),
    num                    INT,
    zong_price             DECIMAL(38,18),
    order_main_id          VARCHAR(32),
    PRIMARY KEY (id)
);
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

CREATE TABLE ces_order_main (
    id                     VARCHAR(36) NOT NULL,
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    order_code             VARCHAR(32),
    xd_date                TIMESTAMP,
    money                  DECIMAL(38,18),
    remark                 VARCHAR(500),
    PRIMARY KEY (id)
);
COMMENT ON COLUMN ces_order_main.create_by IS '创建人';
COMMENT ON COLUMN ces_order_main.create_time IS '创建日期';
COMMENT ON COLUMN ces_order_main.update_by IS '更新人';
COMMENT ON COLUMN ces_order_main.update_time IS '更新日期';
COMMENT ON COLUMN ces_order_main.sys_org_code IS '所属部门';
COMMENT ON COLUMN ces_order_main.order_code IS '订单编码';
COMMENT ON COLUMN ces_order_main.xd_date IS '下单时间';
COMMENT ON COLUMN ces_order_main.money IS '订单总额';
COMMENT ON COLUMN ces_order_main.remark IS '备注';

CREATE TABLE ces_shop_goods (
    id                     VARCHAR(36) NOT NULL,
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    name                   VARCHAR(32),
    price                  DECIMAL(10,5),
    chuc_date              TIMESTAMP,
    contents               TEXT,
    good_type_id           VARCHAR(32),
    PRIMARY KEY (id)
);
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

CREATE TABLE ces_shop_type (
    id                     VARCHAR(36) NOT NULL,
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    name                   VARCHAR(32),
    content                VARCHAR(200),
    pics                   VARCHAR(500),
    pid                    VARCHAR(32),
    has_child              VARCHAR(3),
    PRIMARY KEY (id)
);
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

CREATE TABLE chat_session_msg_feedback (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    user_id                VARCHAR(64) DEFAULT '' NOT NULL,
    client_id              VARCHAR(64) DEFAULT '' NOT NULL,
    session_msg_no         VARCHAR(64) DEFAULT '' NOT NULL,
    grade                  INT DEFAULT 100 NOT NULL,
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    feedback_text          VARCHAR(256) DEFAULT '' NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE chat_session_msg_feedback IS '会话答复评价';
COMMENT ON COLUMN chat_session_msg_feedback.id IS '主键';
COMMENT ON COLUMN chat_session_msg_feedback.user_id IS '用户身份识别码';
COMMENT ON COLUMN chat_session_msg_feedback.client_id IS '项目识别码';
COMMENT ON COLUMN chat_session_msg_feedback.session_msg_no IS '会话问答no';
COMMENT ON COLUMN chat_session_msg_feedback.grade IS '100拇指向上、1拇指向下，11回答错误，12回答模糊，13还可以更好，14答非所问，99自定义；默认值是100';
COMMENT ON COLUMN chat_session_msg_feedback.input_time IS '创建时间';
COMMENT ON COLUMN chat_session_msg_feedback.update_time IS '更新时间';
COMMENT ON COLUMN chat_session_msg_feedback.feedback_text IS '反馈文本';
CREATE UNIQUE INDEX session_msg_no_unique ON chat_session_msg_feedback (session_msg_no);

CREATE TABLE client_agent_index_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    index_name             VARCHAR(100) NOT NULL,
    index_code             VARCHAR(32) NOT NULL,
    index_topic            VARCHAR(100),
    use_flag               VARCHAR(1) DEFAULT 'Y' NOT NULL,
    synonym_word           TEXT,
    key_word               TEXT,
    center_key_word        TEXT,
    entity_type            VARCHAR(500),
    inner_priority         VARCHAR(50),
    source_type            VARCHAR(200),
    external_priority      VARCHAR(50),
    rec_group              VARCHAR(400),
    rec_question           VARCHAR(400),
    has_index_rela         VARCHAR(1),
    remark                 TEXT,
    input_time             VARCHAR(40) NOT NULL,
    update_time            VARCHAR(40) NOT NULL,
    index_desc             TEXT,
    sample_question        TEXT,
    object_type            VARCHAR(256),
    index_classification   VARCHAR(100),
    visible_flag           VARCHAR(1) DEFAULT 'Y',
    index_prompt           TEXT,
    hub_account            VARCHAR(200),
    none_test_flag         VARCHAR(2) DEFAULT '1' NOT NULL,
    final_result_flag      VARCHAR(1) DEFAULT 'N',
    rec_enterprise         VARCHAR(400),
    text_type              VARCHAR(100) DEFAULT 'h5',
    source_card_channel    VARCHAR(100),
    large_model_code       VARCHAR(100),
    large_model_content    VARCHAR(2000),
    rela_knowledge_id      VARCHAR(100),
    large_model_flag       VARCHAR(1) DEFAULT 'Y',
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX client_agent_index_config_un ON client_agent_index_config (index_code, source_type, hub_account, none_test_flag);

CREATE TABLE coze_cache_industry_mapping (
    id                         BIGINT NOT NULL AUTO_INCREMENT,
    ent_name                   VARCHAR(255),
    national_standard_industry VARCHAR(255),
    model_parsed_industry      VARCHAR(255),
    user_input_industry        VARCHAR(255),
    cached_industry            VARCHAR(255),
    final_output_industry      VARCHAR(255),
    created_at                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    product                    VARCHAR(800),
    PRIMARY KEY (id)
);
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

CREATE TABLE data_entname_indname_reference_records (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    ent_name               VARCHAR(200),
    ind_name               VARCHAR(200),
    PRIMARY KEY (id)
);
COMMENT ON TABLE data_entname_indname_reference_records IS '企业行业对照信息表';
COMMENT ON COLUMN data_entname_indname_reference_records.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN data_entname_indname_reference_records.ent_name IS '企业名称';
COMMENT ON COLUMN data_entname_indname_reference_records.ind_name IS '行业名称';

CREATE TABLE data_relate_account (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    data_id                INT,
    account_id             INT,
    relate_time            VARCHAR(40),
    relate_status          VARCHAR(2) DEFAULT '1',
    is_internal            VARCHAR(2) DEFAULT 'N',
    prefix_url             VARCHAR(1000),
    PRIMARY KEY (id)
);
COMMENT ON TABLE data_relate_account IS '数据更新关联机构表';
COMMENT ON COLUMN data_relate_account.id IS '主键ID';
COMMENT ON COLUMN data_relate_account.data_id IS '数据ID';
COMMENT ON COLUMN data_relate_account.account_id IS '关联机构ID';
COMMENT ON COLUMN data_relate_account.relate_time IS '关联时间';
COMMENT ON COLUMN data_relate_account.relate_status IS '关联状态;1已关联 2已取消';
COMMENT ON COLUMN data_relate_account.is_internal IS '是否内部使用 Y是 N否';
COMMENT ON COLUMN data_relate_account.prefix_url IS '外部相对路径前缀';

CREATE TABLE data_update_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    title                  VARCHAR(100) NOT NULL,
    parent_id              INT,
    parent_title           VARCHAR(100),
    user_evaluation        TEXT,
    app_channel            VARCHAR(50),
    app_type               VARCHAR(50),
    use_status             VARCHAR(2) DEFAULT 'N',
    sort_no                INT,
    content_text           TEXT,
    input_time             VARCHAR(40) NOT NULL,
    update_time            VARCHAR(40) NOT NULL,
    sort_time              VARCHAR(40),
    remark                 TEXT,
    is_public              VARCHAR(2) DEFAULT 'N',
    PRIMARY KEY (id)
);
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

CREATE TABLE demo_field_def_val_main (
    id                     VARCHAR(36) NOT NULL,
    code                   VARCHAR(200),
    name                   VARCHAR(200),
    sex                    VARCHAR(200),
    address                VARCHAR(200),
    address_param          VARCHAR(32),
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    PRIMARY KEY (id)
);
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

CREATE TABLE demo_field_def_val_sub (
    id                     VARCHAR(36) NOT NULL,
    code                   VARCHAR(200),
    name                   VARCHAR(200),
    "date"                 VARCHAR(200),
    main_id                VARCHAR(200),
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON COLUMN demo_field_def_val_sub.code IS '编码';
COMMENT ON COLUMN demo_field_def_val_sub.name IS '名称';
COMMENT ON COLUMN demo_field_def_val_sub."date" IS '日期';
COMMENT ON COLUMN demo_field_def_val_sub.main_id IS '主表ID';
COMMENT ON COLUMN demo_field_def_val_sub.create_by IS '创建人';
COMMENT ON COLUMN demo_field_def_val_sub.create_time IS '创建日期';
COMMENT ON COLUMN demo_field_def_val_sub.update_by IS '更新人';
COMMENT ON COLUMN demo_field_def_val_sub.update_time IS '更新日期';
COMMENT ON COLUMN demo_field_def_val_sub.sys_org_code IS '所属部门';

CREATE TABLE ent_rel_shortname_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    ent_rel_name           VARCHAR(200),
    ent_name               VARCHAR(200),
    dw_ins_date            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status                 VARCHAR(10),
    PRIMARY KEY (id)
);
COMMENT ON TABLE ent_rel_shortname_info IS '人工维护企业简称表';
COMMENT ON COLUMN ent_rel_shortname_info.id IS '主键';
COMMENT ON COLUMN ent_rel_shortname_info.ent_rel_name IS '企业简称';
COMMENT ON COLUMN ent_rel_shortname_info.ent_name IS '企业全称';
COMMENT ON COLUMN ent_rel_shortname_info.status IS '数据状态';

CREATE TABLE ent_srd_task (
    task_id                 VARCHAR(45) NOT NULL,
    file_name               VARCHAR(1000),
    user_uuid               VARCHAR(200) NOT NULL,
    ent_count               INT DEFAULT 0,
    parse_status            VARCHAR(40) DEFAULT '初始化' NOT NULL,
    parsing_percentage      INT DEFAULT 0,
    task_from_stage         SMALLINT NOT NULL,
    task_status             VARCHAR(40) DEFAULT '初始化' NOT NULL,
    screening_failed_count  INT DEFAULT 0,
    input_time              VARCHAR(24) NOT NULL,
    update_time             VARCHAR(24) NOT NULL,
    screening_success_count INT,
    PRIMARY KEY (task_id)
);
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

CREATE TABLE ext_intf_manage (
    id                     VARCHAR(32) NOT NULL,
    supplier_id            VARCHAR(100),
    intf_no                VARCHAR(100),
    intf_name              VARCHAR(200),
    intf_path              VARCHAR(200),
    intf_type_name         VARCHAR(200),
    intf_request_type      VARCHAR(50),
    intf_time_out          INT DEFAULT 0,
    intf_status            VARCHAR(2) DEFAULT '1',
    intf_desc              VARCHAR(500),
    refer_intf_no          VARCHAR(100),
    refer_intf_status      VARCHAR(2) DEFAULT '1',
    async_save             VARCHAR(2) DEFAULT '0',
    battle_flag            VARCHAR(2) DEFAULT '0',
    battle_report_content  VARCHAR(1000),
    before_handler         VARCHAR(100),
    input_user_id          VARCHAR(100),
    input_user_name        VARCHAR(100),
    input_time             VARCHAR(20),
    update_user_id         VARCHAR(100),
    update_user_name       VARCHAR(100),
    update_time            VARCHAR(20),
    intf_structure         TEXT,
    PRIMARY KEY (id)
);
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

CREATE TABLE ext_intf_param_define (
    id                     VARCHAR(32) NOT NULL,
    supplier_id            VARCHAR(100),
    param_code             VARCHAR(100),
    param_type             VARCHAR(10),
    param_value            VARCHAR(2000),
    input_user_id          VARCHAR(100),
    input_user_name        VARCHAR(100),
    input_time             VARCHAR(20),
    update_user_id         VARCHAR(100),
    update_user_name       VARCHAR(100),
    update_time            VARCHAR(20),
    param_position         VARCHAR(10) DEFAULT '1',
    param_is_required      VARCHAR(2) DEFAULT '0',
    PRIMARY KEY (id)
);
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

CREATE TABLE ext_intf_param_manage (
    id                     VARCHAR(32) NOT NULL,
    supplier_id            VARCHAR(100),
    intf_no                VARCHAR(100),
    param_code             VARCHAR(100),
    param_name             VARCHAR(200),
    param_type             VARCHAR(10),
    param_is_required      VARCHAR(2),
    param_position         VARCHAR(10),
    param_source           VARCHAR(20),
    param_value            VARCHAR(200),
    input_user_id          VARCHAR(100),
    input_user_name        VARCHAR(100),
    input_time             VARCHAR(20),
    update_user_id         VARCHAR(100),
    update_user_name       VARCHAR(100),
    update_time            VARCHAR(20),
    source_type_detail     VARCHAR(100),
    source_param_code      VARCHAR(100),
    source_param_type      VARCHAR(10),
    child_param_code       VARCHAR(100),
    child_param_name       VARCHAR(100),
    child_param_type       VARCHAR(10),
    source_field_dict_id   VARCHAR(100),
    source_field           VARCHAR(100),
    source_field_name      VARCHAR(100),
    PRIMARY KEY (id)
);
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

CREATE TABLE ext_intf_supplier_manage (
    supplier_id            VARCHAR(100) NOT NULL,
    supplier_name          VARCHAR(200),
    intf_type              VARCHAR(10),
    intf_path              VARCHAR(100),
    status                 VARCHAR(2),
    input_user_id          VARCHAR(100),
    input_user_name        VARCHAR(100),
    input_time             VARCHAR(20),
    update_user_id         VARCHAR(100),
    update_user_name       VARCHAR(100),
    update_time            VARCHAR(20),
    PRIMARY KEY (supplier_id)
);
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

CREATE TABLE financial_abnormal_transaction_info (
    id                     VARCHAR(32) NOT NULL,
    uuid                   VARCHAR(64),
    batch_id               VARCHAR(20),
    task_id                VARCHAR(20),
    ent_name               VARCHAR(100),
    account_no             VARCHAR(100),
    label_name             VARCHAR(20),
    amount                 VARCHAR(100),
    abnormal_type          VARCHAR(100),
    year_month_str         VARCHAR(20),
    trade_date             VARCHAR(20),
    transfer_name          VARCHAR(100),
    trade_time             VARCHAR(20),
    trans_type             VARCHAR(1000),
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
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

CREATE TABLE financial_batch_task_records (
    id                     VARCHAR(32) NOT NULL,
    uuid                   VARCHAR(64),
    batch_id               VARCHAR(20),
    task_id                VARCHAR(20),
    status                 VARCHAR(20) DEFAULT 'init',
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE financial_batch_task_records IS '批次任务记录表';
COMMENT ON COLUMN financial_batch_task_records.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN financial_batch_task_records.uuid IS 'uuid';
COMMENT ON COLUMN financial_batch_task_records.batch_id IS '批次ID';
COMMENT ON COLUMN financial_batch_task_records.task_id IS '任务ID';
COMMENT ON COLUMN financial_batch_task_records.status IS '任务状态 init 待处理 processing 处理中 finished 已完成 failed 失败';
COMMENT ON COLUMN financial_batch_task_records.create_time IS '关联关系创建时间';
COMMENT ON COLUMN financial_batch_task_records.update_time IS '关联关系更新时间';

CREATE TABLE financial_core_income_expenditure_info (
    id                          VARCHAR(32) NOT NULL,
    uuid                        VARCHAR(64),
    batch_id                    VARCHAR(20),
    task_id                     VARCHAR(20),
    ent_name                    VARCHAR(100),
    label_name                  VARCHAR(10),
    proportion                  DECIMAL(18,2),
    trade_amount_format         VARCHAR(100),
    trade_num                   INT,
    avg_trade_amount_format     VARCHAR(100),
    merge_trans                 VARCHAR(10),
    business_proportion         DECIMAL(18,2),
    business_trade_amount       DECIMAL(18,2),
    transfer_name               VARCHAR(100),
    business_proportion_format  VARCHAR(100),
    trade_amount                DECIMAL(18,2),
    avg_trade_amount            DECIMAL(18,2),
    trans_business_trade_amount DECIMAL(18,2),
    proportion_format           VARCHAR(200),
    create_time                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
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

CREATE TABLE financial_counterparty_info (
    id                     VARCHAR(32) NOT NULL,
    uuid                   VARCHAR(64),
    batch_id               VARCHAR(20),
    task_id                VARCHAR(20),
    ent_name               VARCHAR(100),
    name                   VARCHAR(100),
    transfer_name          VARCHAR(100),
    amount_list            TEXT,
    income_format          VARCHAR(200),
    expenditure            DECIMAL(18,2),
    income                 DECIMAL(18,2),
    expenditure_format     VARCHAR(200),
    diff_amount            VARCHAR(200),
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
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

CREATE TABLE financial_direct_relation_info (
    id                     VARCHAR(32) NOT NULL,
    uuid                   VARCHAR(64),
    batch_id               VARCHAR(20),
    task_id                VARCHAR(20),
    ent_name               VARCHAR(100),
    income_format          VARCHAR(200),
    expenditure            DECIMAL(18,2),
    income                 DECIMAL(18,2),
    expenditure_format     VARCHAR(200),
    diff_amount            VARCHAR(200),
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
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

CREATE TABLE financial_focus_counterparty_info (
    id                     VARCHAR(32) NOT NULL,
    uuid                   VARCHAR(64),
    batch_id               VARCHAR(20),
    task_id                VARCHAR(20),
    ent_name               VARCHAR(100),
    transfer_name          VARCHAR(100),
    income_amount          DECIMAL(18,2),
    income_trade_amount    VARCHAR(100),
    income_ratio           VARCHAR(100),
    expend_amount          DECIMAL(18,2),
    expend_trade_amount    VARCHAR(100),
    expend_ratio           VARCHAR(100),
    follow_rule            VARCHAR(10),
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
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

CREATE TABLE financial_main_info (
    id                       VARCHAR(32) NOT NULL,
    uuid                     VARCHAR(64),
    batch_id                 VARCHAR(20),
    task_id                  VARCHAR(20),
    ent_name                 VARCHAR(100),
    cash_flow_total_format   VARCHAR(100),
    balance_day_format       VARCHAR(100),
    profit_loss_total_format VARCHAR(100),
    income_total_format      VARCHAR(100),
    expenditure_total_format VARCHAR(100),
    create_time              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
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

CREATE TABLE financial_profit_loss_info (
    id                                 VARCHAR(32) NOT NULL,
    uuid                               VARCHAR(64),
    batch_id                           VARCHAR(20),
    task_id                            VARCHAR(20),
    ent_name                           VARCHAR(100),
    label_name                         VARCHAR(10),
    profit_loss_total                  DECIMAL(18,2),
    profit_loss_total_format           VARCHAR(100),
    income_total                       DECIMAL(18,2),
    income_total_format                VARCHAR(100),
    average_monthly_income             DECIMAL(18,2),
    average_monthly_income_format      VARCHAR(100),
    average_monthly_expenditure        DECIMAL(18,2),
    average_monthly_expenditure_format VARCHAR(100),
    year_income                        DECIMAL(18,2),
    year_income_format                 VARCHAR(100),
    year_expenditure                   DECIMAL(18,2),
    year_expenditure_format            VARCHAR(100),
    expenditure_total                  DECIMAL(18,2),
    expenditure_total_format           VARCHAR(100),
    average_monthly_profit_loss        DECIMAL(18,2),
    average_monthly_profit_loss_format VARCHAR(100),
    create_time                        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time                        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
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

CREATE TABLE financial_transaction_records (
    _id                    BIGINT NOT NULL AUTO_INCREMENT,
    id                     VARCHAR(64) NOT NULL,
    line_id                VARCHAR(32) NOT NULL,
    uuid                   VARCHAR(64),
    batch_id               VARCHAR(20),
    task_id                VARCHAR(20),
    page                   INT,
    "row"                  INT,
    trade_date             VARCHAR(20),
    trade_date_local       VARCHAR(20),
    trade_time             VARCHAR(20),
    name                   VARCHAR(100),
    account_no             VARCHAR(50),
    transfer_name          VARCHAR(100),
    transfer_account_no    VARCHAR(50),
    transfer_bank_name     VARCHAR(100),
    transaction_type       VARCHAR(2000),
    amount                 VARCHAR(20),
    amount_cny             DECIMAL(18,2),
    amount_format          DECIMAL(18,2),
    balance                VARCHAR(20),
    balance_format         DECIMAL(18,2),
    balance_cny            DECIMAL(18,2),
    notes                  VARCHAR(100),
    trans_type             VARCHAR(200),
    running_days           INT,
    label_name             VARCHAR(50),
    norm_ids               VARCHAR(255),
    label_type             VARCHAR(2),
    label_source           VARCHAR(50),
    in_or_out              VARCHAR(2),
    cuser                  VARCHAR(20),
    ctime                  BIGINT,
    error_type             VARCHAR(10),
    year_and_month         INT,
    trade_date_format      VARCHAR(20),
    is_del                 VARCHAR(2) DEFAULT '0',
    ds_note                VARCHAR(100),
    alter_label_type       VARCHAR(2),
    muser                  VARCHAR(20),
    mtime                  VARCHAR(20),
    delete_flag            VARCHAR(2),
    holiday_name           VARCHAR(50),
    label_con_type         VARCHAR(20),
    recp_task_id           VARCHAR(50),
    recp_flow_id           VARCHAR(50),
    pay_notes              VARCHAR(100),
    proportion             DECIMAL(10,2),
    total                  DECIMAL(18,2),
    relevance_amount       DECIMAL(18,2),
    postscript             VARCHAR(100),
    purpose                VARCHAR(1000),
    remark                 VARCHAR(255),
    currency               VARCHAR(10) DEFAULT 'CNY',
    interest               DECIMAL(18,2),
    is_abnormal            VARCHAR(2),
    truth_check            SMALLINT,
    abnormal_type          VARCHAR(20),
    bank_name              VARCHAR(100),
    bank_code              VARCHAR(20),
    bank_logo              VARCHAR(255),
    bank_cid               VARCHAR(50),
    lend_type_name         VARCHAR(50),
    order_date             VARCHAR(20),
    order_money            DECIMAL(18,2),
    trade_date_time        VARCHAR(20),
    contact_info           VARCHAR(100),
    address                VARCHAR(255),
    transfer_contact_info  VARCHAR(100),
    transfer_address       VARCHAR(255),
    means_payment          VARCHAR(50),
    wx_or_zfb              VARCHAR(10),
    num_amount             DECIMAL(18,2) DEFAULT 0.00,
    num_balance            DECIMAL(18,2) DEFAULT 0.00,
    PRIMARY KEY (_id)
);
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

CREATE TABLE finatial_records (
    task_id                BIGINT NOT NULL AUTO_INCREMENT,
    sent_content           TEXT NOT NULL,
    status                 VARCHAR(20) DEFAULT 'pending' NOT NULL,
    upload_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (task_id)
);
COMMENT ON TABLE finatial_records IS '财务上传数据记录表';
COMMENT ON COLUMN finatial_records.task_id IS '任务id(自增主键)';
COMMENT ON COLUMN finatial_records.sent_content IS '存放的json数据';
COMMENT ON COLUMN finatial_records.status IS '任务状态';
COMMENT ON COLUMN finatial_records.upload_time IS '上传时间';

CREATE TABLE finatial_upload_task (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    user_id                VARCHAR(64) DEFAULT '' NOT NULL,
    session_no             VARCHAR(100) DEFAULT '' NOT NULL,
    file_id                VARCHAR(2048) DEFAULT '' NOT NULL,
    file_name              VARCHAR(500) DEFAULT '' NOT NULL,
    file_path              VARCHAR(500) DEFAULT '' NOT NULL,
    file_size              INT DEFAULT 0 NOT NULL,
    parsing_state          VARCHAR(20) DEFAULT 'parsing' NOT NULL,
    ent_name               VARCHAR(256) DEFAULT '' NOT NULL,
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fail_reason            VARCHAR(2000),
    PRIMARY KEY (id)
);
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

CREATE TABLE graphs_info (
    user_id                VARCHAR(64),
    graph_id               VARCHAR(64) NOT NULL,
    biz_type               VARCHAR(256),
    graph_desc             TEXT,
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status                 VARCHAR(50),
    graph_summary          TEXT,
    node_classification    TEXT,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (graph_id)
);
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

CREATE TABLE index_agent_rela (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    index_id               INT,
    index_status           VARCHAR(1) DEFAULT 'Y',
    rec_group              VARCHAR(400),
    rec_question           VARCHAR(400),
    agent_id               INT,
    extra_column           TEXT,
    index_agent_prompt     TEXT,
    PRIMARY KEY (id)
);
COMMENT ON TABLE index_agent_rela IS '指标Agent关联表';
COMMENT ON COLUMN index_agent_rela.id IS '主键ID';
COMMENT ON COLUMN index_agent_rela.index_id IS '关联指标ID';
COMMENT ON COLUMN index_agent_rela.index_status IS '关联指标状态;Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN index_agent_rela.rec_group IS '推荐分组';
COMMENT ON COLUMN index_agent_rela.rec_question IS '推荐问题';
COMMENT ON COLUMN index_agent_rela.agent_id IS '智能体ID';
COMMENT ON COLUMN index_agent_rela.extra_column IS '扩展指标值报告流程';
COMMENT ON COLUMN index_agent_rela.index_agent_prompt IS 'prompt配置管理';
CREATE UNIQUE INDEX idx_source_agent_index ON index_agent_rela (index_id, agent_id);

CREATE TABLE index_base_group (
    groupid                VARCHAR(32) NOT NULL,
    groupvalue             VARCHAR(100),
    groupname              VARCHAR(200),
    parentgroupid          VARCHAR(32),
    parentgroupname        VARCHAR(200),
    sortno                 VARCHAR(10) DEFAULT '0',
    groupstatus            VARCHAR(10) DEFAULT '1',
    inputtime              VARCHAR(32),
    updatetime             VARCHAR(32),
    PRIMARY KEY (groupid)
);
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

CREATE TABLE index_detail_code_library (
    _id                           BIGINT NOT NULL AUTO_INCREMENT,
    index_detail_name             VARCHAR(100),
    index_detail_code             VARCHAR(32),
    index_detail_layer1_item_name VARCHAR(100),
    index_detail_layer1_item_code VARCHAR(32),
    index_detail_layer2_item_name VARCHAR(100),
    index_detail_layer2_item_code VARCHAR(32),
    index_detail_layer3_item_name VARCHAR(100),
    index_detail_layer3_item_code VARCHAR(32),
    synonym_word                  TEXT,
    key_word                      TEXT,
    PRIMARY KEY (_id)
);
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

CREATE TABLE index_detail_config (
    id                      BIGINT NOT NULL AUTO_INCREMENT,
    index_id                INT,
    index_detail_name       VARCHAR(100),
    source_type_detail      VARCHAR(32),
    default_value           VARCHAR(128),
    remark                  VARCHAR(200),
    param_value_id          VARCHAR(266),
    index_detail_field      VARCHAR(100),
    index_detail_field_type VARCHAR(100),
    ai_identify_param       VARCHAR(100),
    sample_question         VARCHAR(200),
    PRIMARY KEY (id)
);
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

CREATE TABLE index_info_temp (
    _id                    BIGINT NOT NULL AUTO_INCREMENT,
    paramno                VARCHAR(32),
    paramid                VARCHAR(200),
    paramname              VARCHAR(200),
    PRIMARY KEY (_id)
);
COMMENT ON COLUMN index_info_temp._id IS '主键ID';

CREATE TABLE index_label_rela (
    index_name             VARCHAR(100) NOT NULL,
    index_code             VARCHAR(32) NOT NULL,
    source_type            VARCHAR(200) NOT NULL,
    label_database_type    VARCHAR(20) DEFAULT '分类知识库' NOT NULL,
    label_name_level_1     VARCHAR(100),
    label_code_level_1     VARCHAR(32),
    label_name_level_2     VARCHAR(100),
    label_code_level_2     VARCHAR(32),
    label_name_level_3     VARCHAR(100),
    label_code_level_3     VARCHAR(100),
    label_name_level_4     VARCHAR(100),
    label_code_level_4     VARCHAR(100),
    interface_no           VARCHAR(256),
    label_database         VARCHAR(100),
    label_table            VARCHAR(100),
    label_column           VARCHAR(100),
    label_vectordb_addr    VARCHAR(100),
    label_dict_code_1      VARCHAR(100),
    label_dict_code_2      VARCHAR(100),
    label_dict_code_3      VARCHAR(100),
    label_dict_code_4      VARCHAR(100),
    knowledge_id           VARCHAR(100),
    PRIMARY KEY (index_code, source_type)
);
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

CREATE TABLE index_params (
    paramno                VARCHAR(32) NOT NULL,
    paramid                VARCHAR(100),
    paramname              VARCHAR(200),
    paramtype              VARCHAR(10),
    codemethod             VARCHAR(20),
    codeno                 VARCHAR(120),
    required               VARCHAR(10),
    readonly               VARCHAR(10),
    defaultformat          VARCHAR(120),
    inputmethod            VARCHAR(40),
    fromparamno            VARCHAR(32),
    defaultvalue           VARCHAR(2000),
    parentparamno          VARCHAR(32),
    publicparamstatus      VARCHAR(10),
    modelno                VARCHAR(32),
    initmethod             VARCHAR(100),
    datamethod             VARCHAR(10),
    parentparamname        VARCHAR(200),
    reportversion          VARCHAR(100),
    versionno              VARCHAR(100),
    paramsource            VARCHAR(100),
    charttype              VARCHAR(100),
    sortno                 VARCHAR(10),
    placeholder            VARCHAR(2000),
    acturecolumn           VARCHAR(100),
    columnlength           VARCHAR(100),
    columntype             VARCHAR(100),
    columnremark           VARCHAR(100),
    columnisnull           VARCHAR(100),
    columncomment          VARCHAR(100),
    columnfromtable        VARCHAR(100),
    columnfromdatasource   VARCHAR(100),
    otherconfig            VARCHAR(1000),
    scripttype             VARCHAR(100),
    script                 TEXT,
    validators             VARCHAR(500),
    chartinitmethod        VARCHAR(100),
    inputuserid            VARCHAR(32),
    inputorgid             VARCHAR(32),
    inputtime              VARCHAR(32),
    updateuserid           VARCHAR(32),
    updateorgid            VARCHAR(32),
    updatetime             VARCHAR(32),
    supplierid             VARCHAR(100),
    intfno                 VARCHAR(100),
    intfparams             VARCHAR(3000),
    intffield              TEXT,
    intffieldtype          VARCHAR(10),
    structure              TEXT,
    extendfield            TEXT,
    otherno                VARCHAR(100),
    count_field            TEXT,
    is_online              SMALLINT DEFAULT 0,
    metric_intro           VARCHAR(500) DEFAULT '',
    data_unit              VARCHAR(50) DEFAULT '',
    data_example           VARCHAR(1000) DEFAULT '',
    data_type              VARCHAR(30) DEFAULT '',
    data_content_parse     TEXT,
    paramkey               VARCHAR(200),
    PRIMARY KEY (paramno)
);
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

CREATE TABLE index_params_temp (
    _id                    BIGINT NOT NULL AUTO_INCREMENT,
    paramno                VARCHAR(32),
    intfparams             TEXT,
    script                 TEXT,
    scripttype             VARCHAR(10),
    PRIMARY KEY (_id)
);
COMMENT ON COLUMN index_params_temp._id IS '主键ID';

CREATE TABLE index_params_version (
    id                     VARCHAR(32) NOT NULL,
    paramno                VARCHAR(32) NOT NULL,
    paramversion           VARCHAR(100) NOT NULL,
    paramid                VARCHAR(100),
    paramname              VARCHAR(200),
    paramtype              VARCHAR(10),
    codemethod             VARCHAR(20),
    codeno                 VARCHAR(120),
    required               VARCHAR(10),
    readonly               VARCHAR(10),
    defaultformat          VARCHAR(120),
    inputmethod            VARCHAR(40),
    fromparamno            VARCHAR(32),
    defaultvalue           VARCHAR(2000),
    parentparamno          VARCHAR(32),
    publicparamstatus      VARCHAR(10),
    modelno                VARCHAR(32),
    initmethod             VARCHAR(100),
    datamethod             VARCHAR(10),
    parentparamname        VARCHAR(200),
    reportversion          VARCHAR(100),
    versionno              VARCHAR(100),
    paramsource            VARCHAR(100),
    charttype              VARCHAR(100),
    sortno                 VARCHAR(10),
    placeholder            VARCHAR(2000),
    acturecolumn           VARCHAR(100),
    columnlength           VARCHAR(100),
    columntype             VARCHAR(100),
    columnremark           VARCHAR(100),
    columnisnull           VARCHAR(100),
    columncomment          VARCHAR(100),
    columnfromtable        VARCHAR(100),
    columnfromdatasource   VARCHAR(100),
    otherconfig            VARCHAR(1000),
    scripttype             VARCHAR(10),
    script                 TEXT,
    validators             VARCHAR(500),
    chartinitmethod        VARCHAR(100),
    inputuserid            VARCHAR(32),
    inputorgid             VARCHAR(32),
    inputtime              VARCHAR(32),
    updateuserid           VARCHAR(32),
    updateorgid            VARCHAR(32),
    updatetime             VARCHAR(32),
    supplierid             VARCHAR(100),
    intfno                 VARCHAR(100),
    intfparams             VARCHAR(3000),
    intffield              TEXT,
    intffieldtype          VARCHAR(10),
    structure              TEXT,
    extendfield            TEXT,
    otherno                VARCHAR(100),
    count_field            TEXT,
    PRIMARY KEY (id)
);
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

CREATE TABLE index_relate_index_info (
    id                     VARCHAR(32) NOT NULL,
    param_no               VARCHAR(64),
    relate_param_no        VARCHAR(64),
    relate_param_id        VARCHAR(200),
    relate_param_name      VARCHAR(200),
    relate_group_id        VARCHAR(64),
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);
COMMENT ON TABLE index_relate_index_info IS '指标关联指标信息表';
COMMENT ON COLUMN index_relate_index_info.id IS '主键id';
COMMENT ON COLUMN index_relate_index_info.param_no IS '指标编号';
COMMENT ON COLUMN index_relate_index_info.relate_param_no IS '关联指标编号';
COMMENT ON COLUMN index_relate_index_info.relate_param_id IS '关联指标编码';
COMMENT ON COLUMN index_relate_index_info.relate_param_name IS '关联指标名称';
COMMENT ON COLUMN index_relate_index_info.relate_group_id IS '关联指标分组ID';
COMMENT ON COLUMN index_relate_index_info.create_time IS '创建时间';
COMMENT ON COLUMN index_relate_index_info.update_time IS '更新时间';

CREATE TABLE index_relate_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    index_id               VARCHAR(100),
    relate_index_id        VARCHAR(100),
    relate_time            VARCHAR(40),
    comment                VARCHAR(500),
    PRIMARY KEY (id)
);
COMMENT ON TABLE index_relate_info IS '指标关联信息表';
COMMENT ON COLUMN index_relate_info.index_id IS '指标ID';
COMMENT ON COLUMN index_relate_info.relate_index_id IS '关联指标ID';
COMMENT ON COLUMN index_relate_info.relate_time IS '关联时间';
COMMENT ON COLUMN index_relate_info.comment IS '备注';

CREATE TABLE index_relate_knowledge_info (
    id                     VARCHAR(32) NOT NULL,
    param_no               VARCHAR(64),
    relate_knowledge_no    VARCHAR(64),
    relate_knowledge_code  VARCHAR(500),
    relate_knowledge_name  VARCHAR(200),
    relate_group_id        VARCHAR(64),
    relate_items           VARCHAR(500),
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);
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

CREATE TABLE jeecg_monthly_growth_analysis (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    year                   VARCHAR(50),
    month                  VARCHAR(50),
    main_income            DECIMAL(18,2) DEFAULT 0.00,
    other_income           DECIMAL(18,2) DEFAULT 0.00,
    PRIMARY KEY (id)
);
COMMENT ON COLUMN jeecg_monthly_growth_analysis.month IS '月份';
COMMENT ON COLUMN jeecg_monthly_growth_analysis.main_income IS '佣金/主营收入';
COMMENT ON COLUMN jeecg_monthly_growth_analysis.other_income IS '其他收入';

CREATE TABLE jeecg_order_customer (
    id                     VARCHAR(32) NOT NULL,
    name                   VARCHAR(100) NOT NULL,
    sex                    VARCHAR(4),
    idcard                 VARCHAR(18),
    idcard_pic             VARCHAR(500),
    telphone               VARCHAR(32),
    order_id               VARCHAR(32) NOT NULL,
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    PRIMARY KEY (id)
);
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

CREATE TABLE jeecg_order_main (
    id                     VARCHAR(32) NOT NULL,
    order_code             VARCHAR(50),
    ctype                  VARCHAR(500),
    order_date             TIMESTAMP,
    order_money            DECIMAL(10,3),
    content                VARCHAR(500),
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    PRIMARY KEY (id)
);
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

CREATE TABLE jeecg_order_ticket (
    id                     VARCHAR(32) NOT NULL,
    ticket_code            VARCHAR(100) NOT NULL,
    tickect_date           TIMESTAMP,
    order_id               VARCHAR(32) NOT NULL,
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    PRIMARY KEY (id)
);
COMMENT ON COLUMN jeecg_order_ticket.id IS '主键';
COMMENT ON COLUMN jeecg_order_ticket.ticket_code IS '航班号';
COMMENT ON COLUMN jeecg_order_ticket.tickect_date IS '航班时间';
COMMENT ON COLUMN jeecg_order_ticket.order_id IS '外键';
COMMENT ON COLUMN jeecg_order_ticket.create_by IS '创建人';
COMMENT ON COLUMN jeecg_order_ticket.create_time IS '创建时间';
COMMENT ON COLUMN jeecg_order_ticket.update_by IS '修改人';
COMMENT ON COLUMN jeecg_order_ticket.update_time IS '修改时间';

CREATE TABLE jeecg_project_nature_income (
    id                       BIGINT NOT NULL AUTO_INCREMENT,
    nature                   VARCHAR(50) NOT NULL,
    insurance_fee            DECIMAL(18,2) DEFAULT 0.00,
    risk_consulting_fee      DECIMAL(18,2) DEFAULT 0.00,
    evaluation_fee           DECIMAL(18,2) DEFAULT 0.00,
    insurance_evaluation_fee DECIMAL(18,2) DEFAULT 0.00,
    bidding_consulting_fee   DECIMAL(18,2) DEFAULT 0.00,
    interol_consulting_fee   DECIMAL(18,2) DEFAULT 0.00,
    PRIMARY KEY (id)
);
COMMENT ON COLUMN jeecg_project_nature_income.nature IS '项目性质';
COMMENT ON COLUMN jeecg_project_nature_income.insurance_fee IS '保险经纪佣金费';
COMMENT ON COLUMN jeecg_project_nature_income.risk_consulting_fee IS '风险咨询费';
COMMENT ON COLUMN jeecg_project_nature_income.evaluation_fee IS '承保公估评估费';
COMMENT ON COLUMN jeecg_project_nature_income.insurance_evaluation_fee IS '保险公估费';
COMMENT ON COLUMN jeecg_project_nature_income.bidding_consulting_fee IS '投标咨询费';
COMMENT ON COLUMN jeecg_project_nature_income.interol_consulting_fee IS '内控咨询费';

CREATE TABLE knowledge_base_group (
    groupid                VARCHAR(32) NOT NULL,
    groupname              VARCHAR(200),
    parentgroupid          VARCHAR(32),
    parentgroupname        VARCHAR(200),
    sortno                 VARCHAR(10),
    groupstatus            VARCHAR(10) DEFAULT '1',
    inputtime              VARCHAR(32),
    updatetime             VARCHAR(32),
    groupvalue             VARCHAR(100),
    grouptype              VARCHAR(20) DEFAULT 'get_knowledge',
    PRIMARY KEY (groupid)
);
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

CREATE TABLE knowledge_base_params (
    paramid                VARCHAR(32) NOT NULL,
    paramno                VARCHAR(500),
    paramname              VARCHAR(200),
    paramtype              VARCHAR(10),
    paramentitytype        VARCHAR(10),
    paramlabel             VARCHAR(500),
    modelno                VARCHAR(32),
    parentparamid          VARCHAR(32),
    parentparamname        VARCHAR(200),
    reportversion          VARCHAR(100),
    sortno                 VARCHAR(10),
    prompt                 TEXT,
    agentid                VARCHAR(1000),
    otherconfig            VARCHAR(1000),
    paramstatus            VARCHAR(10) DEFAULT 'Y',
    inputuserid            VARCHAR(32),
    inputtime              VARCHAR(32),
    updateuserid           VARCHAR(32),
    updatetime             VARCHAR(32),
    groupid                VARCHAR(100),
    "online"               VARCHAR(10) DEFAULT 'N',
    prompttype             VARCHAR(10) DEFAULT 'basic',
    contentdesc            TEXT,
    input_param            TEXT,
    large_model_code       VARCHAR(1000),
    trace_config           TEXT,
    image_config           TEXT,
    whole_source_config    TEXT,
    large_model_content    TEXT,
    relate_index_set       TEXT,
    black_content_desc     VARCHAR(2000),
    black_model_code       VARCHAR(100),
    is_markdown            VARCHAR(2) DEFAULT 'N',
    param_description      VARCHAR(5000),
    input_condition        TEXT,
    is_client_search       VARCHAR(2) DEFAULT 'N',
    is_online_search       VARCHAR(2) DEFAULT 'N',
    input_index            TEXT,
    large_model_param      TEXT,
    is_top                 VARCHAR(2) DEFAULT 'N',
    splitter_param         TEXT,
    tool_parameters_config TEXT,
    is_cloud_search        VARCHAR(2) DEFAULT 'N',
    user_prompt            TEXT,
    split_strategy_param   TEXT,
    business_experience    TEXT,
    PRIMARY KEY (paramid)
);
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

CREATE TABLE knowledge_base_version (
    id                     VARCHAR(32) NOT NULL,
    param_id               VARCHAR(32) NOT NULL,
    version_no             VARCHAR(200) NOT NULL,
    version_name           VARCHAR(200),
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_user_id         VARCHAR(20),
    create_user_name       VARCHAR(20),
    sort_no                INT DEFAULT 0,
    latest_flag            INT DEFAULT 1,
    prompt                 TEXT,
    content_desc           TEXT,
    large_model_code       VARCHAR(100),
    trace_config           TEXT,
    large_model_content    TEXT,
    image_config           TEXT,
    whole_source_config    TEXT,
    relate_index_set       TEXT,
    black_content_desc     VARCHAR(2000),
    black_model_code       VARCHAR(100),
    input_condition        TEXT,
    input_index            TEXT,
    large_model_param      VARCHAR(2000) DEFAULT '',
    is_top                 VARCHAR(2) DEFAULT 'N',
    splitter_param         TEXT,
    is_cloud_search        VARCHAR(2) DEFAULT 'N',
    is_markdown            VARCHAR(2) DEFAULT 'N',
    is_online_search       VARCHAR(2) DEFAULT 'N',
    is_client_search       VARCHAR(2) DEFAULT 'N',
    user_prompt            TEXT,
    split_strategy_param   TEXT,
    business_experience    TEXT,
    PRIMARY KEY (id)
);
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

CREATE TABLE knowledge_black_params_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    relate_knowledge_id    VARCHAR(32),
    param_no               VARCHAR(32),
    param_code             VARCHAR(32),
    param_type             VARCHAR(10),
    param_name             VARCHAR(200),
    param_desc             VARCHAR(500),
    param_value            VARCHAR(1000),
    param_status           VARCHAR(2) DEFAULT 'Y',
    relate_dict_id         VARCHAR(32),
    relate_source_param    VARCHAR(200),
    relate_param_code      VARCHAR(200),
    relate_param_name      VARCHAR(200),
    show_name              VARCHAR(200),
    sort_no                VARCHAR(10),
    input_time             VARCHAR(32),
    update_time            VARCHAR(32),
    relate_dict_value      VARCHAR(1000),
    PRIMARY KEY (id)
);
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

CREATE TABLE knowledge_black_params_config_version (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    relate_knowledge_id    VARCHAR(32),
    version_no             VARCHAR(100) NOT NULL,
    param_no               VARCHAR(32),
    param_code             VARCHAR(32),
    param_type             VARCHAR(10),
    param_name             VARCHAR(200),
    param_desc             VARCHAR(500),
    param_value            VARCHAR(1000),
    param_status           VARCHAR(2) DEFAULT 'Y',
    relate_dict_id         VARCHAR(32),
    relate_source_param    VARCHAR(200),
    relate_param_code      VARCHAR(200),
    relate_param_name      VARCHAR(200),
    show_name              VARCHAR(200),
    sort_no                VARCHAR(10),
    input_time             VARCHAR(32),
    update_time            VARCHAR(32),
    relate_dict_value      VARCHAR(1000),
    PRIMARY KEY (id)
);
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

CREATE TABLE knowledge_query_result (
    id                     VARCHAR(100) NOT NULL,
    trace_id               VARCHAR(100),
    knowledge_code         VARCHAR(100),
    supplier_id            VARCHAR(100),
    intf_no                VARCHAR(100),
    intf_param             TEXT,
    script_sql             TEXT,
    sql_param              TEXT,
    query_status           VARCHAR(1) DEFAULT 'Y',
    query_type             INT DEFAULT 0,
    query_result           TEXT,
    query_time             VARCHAR(40),
    cost_time              INT,
    comment                VARCHAR(500),
    PRIMARY KEY (id)
);
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

CREATE TABLE knowledge_query_result_for_batch (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    trace_id               VARCHAR(100),
    knowledge_code         VARCHAR(100),
    supplier_id            VARCHAR(100),
    intf_no                VARCHAR(100),
    intf_param             TEXT,
    script_sql             VARCHAR(2000),
    sql_param              VARCHAR(500),
    query_status           VARCHAR(1) DEFAULT 'Y',
    query_type             INT DEFAULT 0,
    query_result           TEXT,
    query_time             VARCHAR(40),
    cost_time              INT,
    comment                VARCHAR(500),
    PRIMARY KEY (id)
);
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

CREATE TABLE knowledge_relate_index (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    knowledge_id           VARCHAR(64),
    index_no               VARCHAR(64),
    parent_index_no        VARCHAR(64),
    index_name             VARCHAR(200),
    index_type             VARCHAR(10),
    supplier_id            VARCHAR(64),
    intf_no                VARCHAR(64),
    add_type               VARCHAR(20) DEFAULT 'add',
    trace_status           CHAR(2) DEFAULT 'N' NOT NULL,
    trace_card_status      CHAR(2) DEFAULT 'N' NOT NULL,
    trace_config           TEXT,
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
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

CREATE TABLE knowledge_relate_index_version (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    knowledge_id           VARCHAR(64),
    version_no             VARCHAR(100) NOT NULL,
    index_no               VARCHAR(64),
    parent_index_no        VARCHAR(64),
    index_name             VARCHAR(200),
    index_type             VARCHAR(10),
    supplier_id            VARCHAR(64),
    intf_no                VARCHAR(64),
    add_type               VARCHAR(20) DEFAULT 'add',
    trace_status           CHAR(2) DEFAULT 'N' NOT NULL,
    trace_card_status      CHAR(2) DEFAULT 'N' NOT NULL,
    trace_config           TEXT,
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
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

CREATE TABLE knowledge_relate_input_param (
    id                     VARCHAR(32) NOT NULL,
    knowledge_id           VARCHAR(64),
    input_param            VARCHAR(2000),
    input_param_name       VARCHAR(100),
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE knowledge_relate_input_param IS '知识库关联参数集';
COMMENT ON COLUMN knowledge_relate_input_param.id IS '主键ID';
COMMENT ON COLUMN knowledge_relate_input_param.knowledge_id IS '知识库ID';
COMMENT ON COLUMN knowledge_relate_input_param.input_param IS '参数集';
COMMENT ON COLUMN knowledge_relate_input_param.input_param_name IS '参数集名称';
COMMENT ON COLUMN knowledge_relate_input_param.input_time IS '创建时间';
COMMENT ON COLUMN knowledge_relate_input_param.update_time IS '更新时间';

CREATE TABLE knowledge_relate_input_param_version (
    id                     VARCHAR(32) NOT NULL,
    knowledge_id           VARCHAR(64),
    version_no             VARCHAR(100) NOT NULL,
    input_param            VARCHAR(2000),
    input_param_name       VARCHAR(100),
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE knowledge_relate_input_param_version IS '知识库关联参数集版本记录表';
COMMENT ON COLUMN knowledge_relate_input_param_version.id IS '主键ID';
COMMENT ON COLUMN knowledge_relate_input_param_version.knowledge_id IS '知识库ID';
COMMENT ON COLUMN knowledge_relate_input_param_version.version_no IS '版本号';
COMMENT ON COLUMN knowledge_relate_input_param_version.input_param IS '参数集';
COMMENT ON COLUMN knowledge_relate_input_param_version.input_param_name IS '参数集名称';
COMMENT ON COLUMN knowledge_relate_input_param_version.input_time IS '创建时间';
COMMENT ON COLUMN knowledge_relate_input_param_version.update_time IS '更新时间';

CREATE TABLE knowledge_sync_task (
    id                     VARCHAR(32) NOT NULL,
    sync_type              VARCHAR(32) NOT NULL,
    sync_status            VARCHAR(20) DEFAULT 'new' NOT NULL,
    user_id                VARCHAR(64) DEFAULT '' NOT NULL,
    user_name              VARCHAR(64) DEFAULT '' NOT NULL,
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    finish_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    cost_time              INT DEFAULT 0 NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE knowledge_sync_task IS '知识库同步任务记录表';
COMMENT ON COLUMN knowledge_sync_task.id IS '主键id';
COMMENT ON COLUMN knowledge_sync_task.sync_type IS 'knowledge-知识库同步, index-指标同步, apiSource-API数据源同步, dataSource-SQL数据源';
COMMENT ON COLUMN knowledge_sync_task.sync_status IS 'new-新建任务；processing-同步中；success-同步成功；failed-同步失败；';
COMMENT ON COLUMN knowledge_sync_task.user_id IS '同步用户ID';
COMMENT ON COLUMN knowledge_sync_task.user_name IS '同步用户名称';
COMMENT ON COLUMN knowledge_sync_task.input_time IS '创建时间';
COMMENT ON COLUMN knowledge_sync_task.finish_time IS '完成时间';
COMMENT ON COLUMN knowledge_sync_task.cost_time IS '耗时（毫秒）';

CREATE TABLE knowledge_sync_task_exception_record (
    id                     VARCHAR(32) NOT NULL,
    task_id                VARCHAR(32) NOT NULL,
    exception_stage        VARCHAR(100) NOT NULL,
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fail_reason            TEXT,
    PRIMARY KEY (id)
);
COMMENT ON TABLE knowledge_sync_task_exception_record IS '知识库同步任务异常记录表';
COMMENT ON COLUMN knowledge_sync_task_exception_record.id IS '主键id';
COMMENT ON COLUMN knowledge_sync_task_exception_record.task_id IS '任务id';
COMMENT ON COLUMN knowledge_sync_task_exception_record.exception_stage IS '异常阶段：init-数据查询阶段；knowledge-同步知识库配置阶段；knowledge_relate_index-同步知识库溯源阶段；knowledge_black_params-同步知识库黑盒参数阶段；knowledge_input_param-同步知识库参数集阶段；knowledge_group-同步知识库分组阶段；index-同步指标配置阶段；index_group-同步指标分组阶段；source-同步数据源阶段；';
COMMENT ON COLUMN knowledge_sync_task_exception_record.input_time IS '创建时间';
COMMENT ON COLUMN knowledge_sync_task_exception_record.fail_reason IS '失败原因';

CREATE TABLE large_model_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    lm_code                VARCHAR(100) NOT NULL,
    model                  VARCHAR(100),
    lm_name                VARCHAR(256),
    url                    VARCHAR(2000),
    api_key                VARCHAR(5000),
    lm_desc                TEXT,
    use_flag               VARCHAR(2) DEFAULT 'Y' NOT NULL,
    with_think             VARCHAR(10) DEFAULT 'N',
    default_think_flag     VARCHAR(4) DEFAULT 'N',
    max_tokens             INT DEFAULT 0,
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    model_config           TEXT,
    PRIMARY KEY (id)
);
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

CREATE TABLE largemodel_queue (
    queueid                VARCHAR(100) NOT NULL,
    hubaccount             VARCHAR(100) NOT NULL,
    modulecode             VARCHAR(300) NOT NULL,
    largemodelcode         VARCHAR(300) NOT NULL,
    largemodelreqkey       VARCHAR(300) NOT NULL,
    processstatus          VARCHAR(300) DEFAULT 'ready' NOT NULL,
    queuereason            VARCHAR(300),
    begintime              VARCHAR(20),
    endtime                VARCHAR(20),
    inputtime              VARCHAR(20) NOT NULL,
    updatetime             VARCHAR(20) NOT NULL,
    PRIMARY KEY (queueid)
);
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

CREATE TABLE llm_batch_analysis_task (
    task_id                VARCHAR(32) NOT NULL,
    user_id                VARCHAR(32) NOT NULL,
    prompt                 TEXT,
    model_codes            VARCHAR(2000) NOT NULL,
    start_time             TIMESTAMP,
    end_time               TIMESTAMP,
    status                 VARCHAR(20),
    failure_reason         TEXT,
    evaluation_prompt      TEXT,
    total_rounds           INT DEFAULT 10 NOT NULL,
    hallucination_check    VARCHAR(2) DEFAULT 'N' NOT NULL,
    hallucination_prompt   TEXT,
    evaluation_title       VARCHAR(50),
    evaluation_comment     TEXT,
    other_relate_prompt    TEXT,
    evaluate_model         VARCHAR(100),
    relate_dataset         VARCHAR(2000),
    evaluate_dimension     VARCHAR(2000),
    PRIMARY KEY (task_id)
);
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

CREATE TABLE llm_batch_analysis_task_detail (
    task_id                VARCHAR(32) NOT NULL,
    model_code             VARCHAR(128) NOT NULL,
    round_num              INT NOT NULL,
    model_result           TEXT,
    hallucination_result   TEXT,
    evaluation_result      TEXT,
    start_time             VARCHAR(40) NOT NULL,
    model_end_time         VARCHAR(40),
    evaluation_end_time    VARCHAR(40),
    hallucination_end_time VARCHAR(40),
    status                 VARCHAR(20),
    evaluation_score       json,
    failure_reason         TEXT,
    evaluation_status      VARCHAR(20),
    hallucination_status   VARCHAR(20),
    evaluation_comment     TEXT,
    dataset_id             VARCHAR(32),
    ent_name               VARCHAR(100) DEFAULT '',
    prompt_code            VARCHAR(200) DEFAULT '' NOT NULL,
    dataset_uid            VARCHAR(32) DEFAULT '' NOT NULL,
    PRIMARY KEY (task_id, model_code, round_num, dataset_uid, prompt_code)
);
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

CREATE TABLE llm_batch_analysis_task_hallucination (
    task_id                VARCHAR(32) NOT NULL,
    model_code             VARCHAR(128) NOT NULL,
    round_num              INT NOT NULL,
    sequence_num           VARCHAR(36) NOT NULL,
    hallucination_type     TEXT,
    hallucination_desc     TEXT,
    evaluation_source      VARCHAR(50),
    manual_review_result   VARCHAR(20),
    reviewer               VARCHAR(50),
    review_time            VARCHAR(40),
    review_notes           TEXT,
    prompt_code            VARCHAR(200),
    PRIMARY KEY (task_id, model_code, round_num, sequence_num)
);
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

CREATE TABLE llm_evaluate_dataset_management (
    id                     VARCHAR(32) NOT NULL,
    dataset_code           VARCHAR(100) NOT NULL,
    dataset_desc           TEXT,
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_by              VARCHAR(50),
    update_time            TIMESTAMP,
    update_by              VARCHAR(50),
    PRIMARY KEY (id)
);
COMMENT ON TABLE llm_evaluate_dataset_management IS '大模型评估测试集';
COMMENT ON COLUMN llm_evaluate_dataset_management.id IS '主键ID';
COMMENT ON COLUMN llm_evaluate_dataset_management.dataset_code IS '测试集编号';
COMMENT ON COLUMN llm_evaluate_dataset_management.dataset_desc IS '测试集描述';
COMMENT ON COLUMN llm_evaluate_dataset_management.input_time IS '创建时间';
COMMENT ON COLUMN llm_evaluate_dataset_management.create_by IS '创建人';
COMMENT ON COLUMN llm_evaluate_dataset_management.update_time IS '更新时间';
COMMENT ON COLUMN llm_evaluate_dataset_management.update_by IS '更新人';

CREATE TABLE llm_evaluate_dataset_management_detail (
    id                     VARCHAR(32) NOT NULL,
    dataset_id             VARCHAR(32) NOT NULL,
    ent_name               VARCHAR(100) NOT NULL,
    prompt_code            VARCHAR(100) NOT NULL,
    prompt                 TEXT,
    expected_output        TEXT,
    input_time             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_by              VARCHAR(50),
    update_time            TIMESTAMP,
    update_by              VARCHAR(50),
    requirements           TEXT,
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX ent_code_idx ON llm_evaluate_dataset_management_detail (ent_name, prompt_code, dataset_id);

CREATE TABLE login_verfication_code (
    id                     VARCHAR(64) NOT NULL,
    user_id                VARCHAR(50),
    verfication_code       VARCHAR(200),
    input_time             VARCHAR(50),
    PRIMARY KEY (id)
);
COMMENT ON COLUMN login_verfication_code.user_id IS '用户id';
COMMENT ON COLUMN login_verfication_code.verfication_code IS '验证码';
COMMENT ON COLUMN login_verfication_code.input_time IS '插入时间';

CREATE TABLE message_push_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    content_text           TEXT,
    input_time             VARCHAR(40) NOT NULL,
    update_time            VARCHAR(40) NOT NULL,
    push_time              VARCHAR(40),
    push_channel           VARCHAR(200),
    push_flag              VARCHAR(2) DEFAULT '1',
    push_status            VARCHAR(2) DEFAULT '1',
    remark                 VARCHAR(500),
    title                  VARCHAR(200),
    PRIMARY KEY (id)
);
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

CREATE TABLE message_relate_account (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    message_id             INT,
    account_id             INT,
    relate_time            VARCHAR(40),
    relate_status          VARCHAR(2) DEFAULT '1',
    PRIMARY KEY (id)
);
COMMENT ON TABLE message_relate_account IS '消息推送关联机构表';
COMMENT ON COLUMN message_relate_account.id IS '主键ID';
COMMENT ON COLUMN message_relate_account.message_id IS '消息ID';
COMMENT ON COLUMN message_relate_account.account_id IS '关联账号ID';
COMMENT ON COLUMN message_relate_account.relate_time IS '关联时间';
COMMENT ON COLUMN message_relate_account.relate_status IS '关联状态;1已关联 2已取消';

CREATE TABLE module_code_prompt_cache (
    module_code            VARCHAR(200) NOT NULL,
    module_name            VARCHAR(200),
    params                 TEXT,
    params_md5             VARCHAR(200) NOT NULL,
    prompt                 TEXT,
    status                 VARCHAR(1) DEFAULT 'Y',
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (module_code, params_md5)
);
COMMENT ON TABLE module_code_prompt_cache IS '知识库文案缓存表';
COMMENT ON COLUMN module_code_prompt_cache.module_code IS '知识库编码';
COMMENT ON COLUMN module_code_prompt_cache.module_name IS '知识库名称';
COMMENT ON COLUMN module_code_prompt_cache.params IS '请求参数';
COMMENT ON COLUMN module_code_prompt_cache.params_md5 IS '请求参数md5';
COMMENT ON COLUMN module_code_prompt_cache.prompt IS '文案内容';
COMMENT ON COLUMN module_code_prompt_cache.status IS '缓存状态;Y表示有效，N表示无效，默认Y';
COMMENT ON COLUMN module_code_prompt_cache.create_time IS '创建时间';
COMMENT ON COLUMN module_code_prompt_cache.update_time IS '更新时间';

CREATE TABLE ocr_parse_task (
    task_id                VARCHAR(64) NOT NULL,
    file_name              VARCHAR(512) NOT NULL,
    file_type              VARCHAR(32) NOT NULL,
    status                 VARCHAR(32) NOT NULL,
    source_file_path       VARCHAR(1024) NOT NULL,
    storage_type           VARCHAR(32) NOT NULL,
    result                 TEXT,
    result_content_json    TEXT,
    error                  TEXT,
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (task_id)
);

CREATE TABLE open_api_conf (
    id                      VARCHAR(32) NOT NULL,
    provider_id             VARCHAR(100),
    api_code                VARCHAR(50) NOT NULL,
    api_type                VARCHAR(50) NOT NULL,
    api_desc                VARCHAR(500) NOT NULL,
    api_category_code       VARCHAR(50),
    upstream_path           VARCHAR(255),
    http_method             VARCHAR(10) NOT NULL,
    message_type            VARCHAR(10),
    header                  VARCHAR(3000),
    request_param           VARCHAR(3000) NOT NULL,
    success_code_field      VARCHAR(20),
    success_code_value      VARCHAR(20),
    response_biz_data_field VARCHAR(100),
    response_biz_data_type  VARCHAR(100),
    response_param          VARCHAR(3000),
    stream_flag             VARCHAR(5) DEFAULT 'false',
    create_time             VARCHAR(20),
    create_by               VARCHAR(32),
    update_time             VARCHAR(20),
    update_by               VARCHAR(32),
    api_name                VARCHAR(200),
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX idx_api_code ON open_api_conf (api_code);

CREATE TABLE package_agent_index_config (
    id                     VARCHAR(32) NOT NULL,
    index_name             VARCHAR(100) NOT NULL,
    index_code             VARCHAR(32) NOT NULL,
    index_topic            VARCHAR(100),
    use_flag               VARCHAR(1) DEFAULT 'Y' NOT NULL,
    synonym_word           TEXT,
    key_word               TEXT,
    center_key_word        TEXT,
    entity_type            VARCHAR(200),
    inner_priority         VARCHAR(50),
    source_type            VARCHAR(200),
    external_priority      VARCHAR(50),
    rec_group              VARCHAR(400),
    rec_question           VARCHAR(400),
    has_index_rela         VARCHAR(1),
    remark                 TEXT,
    input_time             VARCHAR(40) NOT NULL,
    update_time            VARCHAR(40) NOT NULL,
    index_desc             TEXT,
    sample_question        TEXT,
    object_type            VARCHAR(256),
    index_classification   VARCHAR(100),
    visible_flag           VARCHAR(1) DEFAULT 'Y',
    index_prompt           TEXT,
    hub_account            VARCHAR(200),
    none_test_flag         VARCHAR(100) DEFAULT '1' NOT NULL,
    final_result_flag      VARCHAR(1) DEFAULT 'N',
    rec_enterprise         VARCHAR(400),
    text_type              VARCHAR(100) DEFAULT 'H5',
    source_card_channel    VARCHAR(100),
    large_model_code       VARCHAR(100),
    large_model_content    VARCHAR(2000),
    rela_knowledge_id      VARCHAR(100),
    large_model_flag       VARCHAR(1) DEFAULT 'Y',
    is_recommend           VARCHAR(2) DEFAULT 'N',
    recommend_weight       INT DEFAULT 0,
    PRIMARY KEY (id)
);
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

CREATE TABLE post_glm_records (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    question               TEXT,
    answer                 TEXT,
    remark1                VARCHAR(400),
    remark2                VARCHAR(400),
    remark3                VARCHAR(400),
    createtime             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    time_cost              VARCHAR(400),
    PRIMARY KEY (id)
);
COMMENT ON TABLE post_glm_records IS '请求glm记录表';
COMMENT ON COLUMN post_glm_records.question IS '问题';
COMMENT ON COLUMN post_glm_records.answer IS '答案';
COMMENT ON COLUMN post_glm_records.remark1 IS '备注1';
COMMENT ON COLUMN post_glm_records.remark2 IS '备注2';
COMMENT ON COLUMN post_glm_records.remark3 IS '备注3';

CREATE TABLE prompt_query_result (
    id                     VARCHAR(32) NOT NULL,
    module_code            VARCHAR(100),
    module_name            VARCHAR(100),
    ent_name               VARCHAR(100),
    is_muti_ent            VARCHAR(10),
    query_param            TEXT,
    result_mode            VARCHAR(10),
    query_status           VARCHAR(1),
    cost_time              INT,
    query_result           TEXT,
    fail_reason            TEXT,
    query_time             VARCHAR(40),
    comment                VARCHAR(500),
    trace_id               VARCHAR(100),
    end_time               VARCHAR(20),
    PRIMARY KEY (id)
);
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

CREATE TABLE prompt_verify_running_result_compare_task (
    id                       VARCHAR(64) NOT NULL,
    scene_id                 VARCHAR(64),
    result_id_list           VARCHAR(500),
    standard_result_id       VARCHAR(100),
    create_time              VARCHAR(20),
    start_time               VARCHAR(20),
    end_time                 VARCHAR(20),
    compare_result_summary   VARCHAR(2000),
    compare_result_statistic TEXT,
    status                   VARCHAR(20) DEFAULT 'init' NOT NULL,
    PRIMARY KEY (id)
);
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

CREATE TABLE prompt_verify_running_task (
    id                     VARCHAR(64) NOT NULL,
    scene_id               VARCHAR(64),
    prompt_id              VARCHAR(64),
    prompt_template        TEXT,
    task_name              VARCHAR(200),
    task_desc              VARCHAR(500),
    large_model_code_list  VARCHAR(1000),
    create_time            VARCHAR(20),
    update_time            VARCHAR(20),
    task_status            VARCHAR(20) DEFAULT 'none' NOT NULL,
    concurrent_num         INT,
    PRIMARY KEY (id)
);
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

CREATE TABLE prompt_verify_running_task_detail (
    id                     VARCHAR(64) NOT NULL,
    task_id                VARCHAR(64),
    prompt_params          TEXT,
    prompt_template        TEXT,
    prompt_params_md5      VARCHAR(200),
    PRIMARY KEY (id)
);
COMMENT ON TABLE prompt_verify_running_task_detail IS '大模型校验任务详情表';
COMMENT ON COLUMN prompt_verify_running_task_detail.id IS '主键ID';
COMMENT ON COLUMN prompt_verify_running_task_detail.task_id IS '关联任务ID';
COMMENT ON COLUMN prompt_verify_running_task_detail.prompt_params IS 'prompt参数信息';
COMMENT ON COLUMN prompt_verify_running_task_detail.prompt_template IS 'prompt模板信息';
COMMENT ON COLUMN prompt_verify_running_task_detail.prompt_params_md5 IS 'prompt参数唯一键';

CREATE TABLE prompt_verify_running_task_result (
    id                     VARCHAR(64) NOT NULL,
    task_id                VARCHAR(64),
    start_time             VARCHAR(20),
    end_time               VARCHAR(20),
    evaluation             VARCHAR(1000),
    prompt_template        TEXT,
    large_model_code       VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE prompt_verify_running_task_result IS '大模型校验任务结果表';
COMMENT ON COLUMN prompt_verify_running_task_result.id IS '主键ID';
COMMENT ON COLUMN prompt_verify_running_task_result.task_id IS '任务ID';
COMMENT ON COLUMN prompt_verify_running_task_result.start_time IS '开始时间';
COMMENT ON COLUMN prompt_verify_running_task_result.end_time IS '结束时间';
COMMENT ON COLUMN prompt_verify_running_task_result.evaluation IS '综合评价';

CREATE TABLE prompt_verify_running_task_result_detail (
    task_result_id         VARCHAR(64),
    task_detail_id         VARCHAR(64),
    task_time              DECIMAL(10,4),
    prompt_params_md5      VARCHAR(200),
    prompt_result          TEXT,
    format_standard        VARCHAR(2),
    id                     VARCHAR(64) NOT NULL,
    start_time             VARCHAR(64),
    end_time               VARCHAR(64),
    error_msg              TEXT,
    expect_format          VARCHAR(50),
    prompt_sample          TEXT,
    PRIMARY KEY (id)
);
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

CREATE TABLE qianxun_knowledge_base_info (
    knowledge_id           VARCHAR(64) NOT NULL,
    knowledge_code         VARCHAR(255) NOT NULL,
    knowledge_name         VARCHAR(50),
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    create_user_id         VARCHAR(50),
    belong_user_id         VARCHAR(50),
    knowledge_desc         TEXT,
    PRIMARY KEY (knowledge_id)
);
COMMENT ON TABLE qianxun_knowledge_base_info IS '知识库信息表';
COMMENT ON COLUMN qianxun_knowledge_base_info.knowledge_id IS '知识库唯一标识，自增主键';
COMMENT ON COLUMN qianxun_knowledge_base_info.knowledge_code IS '知识库code';
COMMENT ON COLUMN qianxun_knowledge_base_info.knowledge_name IS '知识库名称';
COMMENT ON COLUMN qianxun_knowledge_base_info.create_time IS '知识库创建时间';
COMMENT ON COLUMN qianxun_knowledge_base_info.update_time IS '知识库更新时间';
COMMENT ON COLUMN qianxun_knowledge_base_info.create_user_id IS '创建用户id,agent平台的用户';
COMMENT ON COLUMN qianxun_knowledge_base_info.belong_user_id IS '某个用户的私人知识库,千寻用户';
COMMENT ON COLUMN qianxun_knowledge_base_info.knowledge_desc IS '知识描述';

CREATE TABLE qianxun_knowledge_base_upload_file_info (
    file_id                VARCHAR(64) NOT NULL,
    knowledge_id           VARCHAR(64),
    file_name              VARCHAR(255) NOT NULL,
    file_extension         VARCHAR(10) NOT NULL,
    user_uuid              VARCHAR(64),
    session_no             VARCHAR(64),
    file_size              BIGINT DEFAULT 0 NOT NULL,
    file_storage_path      VARCHAR(255) NOT NULL,
    upload_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    finish_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description            TEXT,
    file_flag              VARCHAR(20) DEFAULT '0',
    parse_status           VARCHAR(30) DEFAULT 'uploading',
    fail_count             INT DEFAULT 0,
    PRIMARY KEY (file_id)
);
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

CREATE TABLE qianxun_order_info (
    order_id                    VARCHAR(32) NOT NULL,
    order_name                  VARCHAR(32) NOT NULL,
    org_id                      VARCHAR(64) NOT NULL,
    is_all_user                 SMALLINT DEFAULT 0 NOT NULL,
    is_long_term                SMALLINT DEFAULT 0 NOT NULL,
    consumption_method          VARCHAR(50) NOT NULL,
    count_limit                 BIGINT DEFAULT 0,
    consumption_org_count       BIGINT DEFAULT 0,
    consumption_object          VARCHAR(50) NOT NULL,
    is_online                   VARCHAR(2) DEFAULT 'N',
    order_description           TEXT,
    create_time                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expire_date                 VARCHAR(10),
    org_id_list                 VARCHAR(500),
    ai_component_display_format VARCHAR(50) DEFAULT 'H5',
    is_resource                 VARCHAR(2) DEFAULT 'Y',
    qianxun_version             VARCHAR(100) DEFAULT 'classic-经典版',
    PRIMARY KEY (order_id)
);
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

CREATE TABLE qianxun_organization_info (
    id                          VARCHAR(64) NOT NULL,
    org_id                      VARCHAR(64),
    org_name                    VARCHAR(255),
    parent_id                   VARCHAR(64),
    org_description             TEXT,
    hub_account                 VARCHAR(100),
    create_time                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    sort_no                     INT,
    ai_component_display_format VARCHAR(50),
    origin_org_id               VARCHAR(64),
    app_key                     VARCHAR(500),
    app_key_expire_date         VARCHAR(20),
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX qianxun_organization_info_org_id_idx ON qianxun_organization_info (org_id, hub_account);
CREATE UNIQUE INDEX org_id ON qianxun_organization_info (org_id);

CREATE TABLE qianxun_package_ai_component_relation (
    id                     VARCHAR(32) NOT NULL,
    package_id             VARCHAR(32),
    ai_component_id        INT,
    status                 VARCHAR(2) DEFAULT 'Y',
    sort_no                INT,
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE qianxun_package_ai_component_relation IS '千寻套餐关联智能组件信息表';
COMMENT ON COLUMN qianxun_package_ai_component_relation.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_ai_component_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_ai_component_relation.ai_component_id IS '智能组件ID，关联智能组件信息表中的id';
COMMENT ON COLUMN qianxun_package_ai_component_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_ai_component_relation.sort_no IS '排序号';
COMMENT ON COLUMN qianxun_package_ai_component_relation.create_time IS '关联关系创建时间';
COMMENT ON COLUMN qianxun_package_ai_component_relation.update_time IS '关联关系更新时间';

CREATE TABLE qianxun_package_index_relation (
    id                     VARCHAR(32) NOT NULL,
    package_id             VARCHAR(32),
    index_id               INT,
    status                 VARCHAR(2) DEFAULT 'Y',
    is_visible             VARCHAR(2) DEFAULT 'Y',
    sort_no                INT,
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    relate_index_id        VARCHAR(100),
    PRIMARY KEY (id)
);
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

CREATE TABLE qianxun_package_info (
    package_id             VARCHAR(32) NOT NULL,
    package_name           VARCHAR(255) NOT NULL,
    package_desc           TEXT,
    status                 VARCHAR(2) DEFAULT 'Y',
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (package_id)
);
COMMENT ON TABLE qianxun_package_info IS '套餐基本信息表';
COMMENT ON COLUMN qianxun_package_info.package_id IS '套餐唯一标识';
COMMENT ON COLUMN qianxun_package_info.package_name IS '套餐名称';
COMMENT ON COLUMN qianxun_package_info.package_desc IS '套餐详细描述';
COMMENT ON COLUMN qianxun_package_info.status IS '套餐有效标志位，Y表示已上架，N表示已下架';
COMMENT ON COLUMN qianxun_package_info.create_time IS '套餐信息创建时间';
COMMENT ON COLUMN qianxun_package_info.update_time IS '套餐信息更新时间';

CREATE TABLE qianxun_package_knowledge_relation (
    id                     VARCHAR(32) NOT NULL,
    package_id             VARCHAR(32),
    knowledge_id           VARCHAR(64),
    status                 VARCHAR(2) DEFAULT 'Y',
    sort_no                INT,
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE qianxun_package_knowledge_relation IS '千寻套餐关联知识库信息表';
COMMENT ON COLUMN qianxun_package_knowledge_relation.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_knowledge_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_knowledge_relation.knowledge_id IS '知识库ID，关联知识库信息表中的knowledge_id';
COMMENT ON COLUMN qianxun_package_knowledge_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_knowledge_relation.sort_no IS '排序号';
COMMENT ON COLUMN qianxun_package_knowledge_relation.create_time IS '关联关系创建时间';
COMMENT ON COLUMN qianxun_package_knowledge_relation.update_time IS '关联关系更新时间';

CREATE TABLE qianxun_package_menu_relation (
    id                     VARCHAR(32) NOT NULL,
    package_id             VARCHAR(32),
    menu_id                VARCHAR(32),
    status                 VARCHAR(2) DEFAULT 'Y',
    sort_no                INT,
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE qianxun_package_menu_relation IS '千寻套餐关联千寻菜单信息表';
COMMENT ON COLUMN qianxun_package_menu_relation.id IS '关联记录的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_menu_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_menu_relation.menu_id IS '千寻菜单ID，千寻菜单配置表中的id';
COMMENT ON COLUMN qianxun_package_menu_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_menu_relation.sort_no IS '排序号';
COMMENT ON COLUMN qianxun_package_menu_relation.create_time IS '关联记录的创建时间';
COMMENT ON COLUMN qianxun_package_menu_relation.update_time IS '关联记录的更新时间';

CREATE TABLE qianxun_package_order_relation (
    id                     VARCHAR(32) NOT NULL,
    package_id             VARCHAR(32),
    order_id               VARCHAR(32),
    status                 VARCHAR(2) DEFAULT 'Y',
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE qianxun_package_order_relation IS '订单关联套餐表';
COMMENT ON COLUMN qianxun_package_order_relation.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_order_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_order_relation.order_id IS '订单ID，关联订单信息表中的 order_id';
COMMENT ON COLUMN qianxun_package_order_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_order_relation.create_time IS '关联关系创建时间';
COMMENT ON COLUMN qianxun_package_order_relation.update_time IS '关联关系更新时间';

CREATE TABLE qianxun_package_space_relation (
    id                     VARCHAR(32) NOT NULL,
    package_id             VARCHAR(32),
    space_id               INT,
    status                 VARCHAR(2) DEFAULT 'Y',
    sort_no                INT,
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE qianxun_package_space_relation IS '千寻套餐关联空间信息表';
COMMENT ON COLUMN qianxun_package_space_relation.id IS '关联记录的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_package_space_relation.package_id IS '套餐 ID，关联套餐信息表中的 package_id';
COMMENT ON COLUMN qianxun_package_space_relation.space_id IS '空间ID，关联空间信息表中的 space_id';
COMMENT ON COLUMN qianxun_package_space_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_package_space_relation.sort_no IS '排序号';
COMMENT ON COLUMN qianxun_package_space_relation.create_time IS '关联记录的创建时间';
COMMENT ON COLUMN qianxun_package_space_relation.update_time IS '关联记录的更新时间';

CREATE TABLE qianxun_source_cards (
    session_msg_no         VARCHAR(200) NOT NULL,
    source_card_content    TEXT,
    PRIMARY KEY (session_msg_no)
);

CREATE TABLE qianxun_user_info (
    id                     VARCHAR(64) NOT NULL,
    user_id                VARCHAR(64),
    user_name              VARCHAR(255),
    org_id                 VARCHAR(64),
    phone_number           VARCHAR(100),
    password               VARCHAR(255),
    salt                   VARCHAR(255),
    label                  VARCHAR(1000),
    email                  VARCHAR(100),
    status                 VARCHAR(1) DEFAULT 'Y',
    last_active_time       TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    user_source            VARCHAR(50),
    remark                 VARCHAR(50),
    origin_user_id         VARCHAR(64),
    org_id_list            VARCHAR(500),
    app_key                VARCHAR(500),
    app_key_expire_date    VARCHAR(20),
    PRIMARY KEY (id)
);
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

CREATE TABLE qianxun_user_log (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    user_id                VARCHAR(80) NOT NULL,
    hub_account            VARCHAR(80) DEFAULT '' NOT NULL,
    org_id                 VARCHAR(80) DEFAULT '' NOT NULL,
    env_type               VARCHAR(40) DEFAULT '' NOT NULL,
    version_type           VARCHAR(40) DEFAULT '' NOT NULL,
    hub_source             VARCHAR(80) DEFAULT '' NOT NULL,
    session_no             VARCHAR(80) NOT NULL,
    session_msg_no         VARCHAR(80) NOT NULL,
    parent_session_msg_no  VARCHAR(64) DEFAULT '' NOT NULL,
    msg                    TEXT,
    session_msg_start_time TIMESTAMP,
    first_session_msg_time TIMESTAMP,
    session_msg_end_time   TIMESTAMP,
    phone_no               VARCHAR(200),
    org_info               VARCHAR(200) DEFAULT '' NOT NULL,
    answer_result          TEXT,
    org_name               VARCHAR(1000),
    role_name              VARCHAR(1000),
    menu_name              VARCHAR(500),
    menu_name_code         VARCHAR(500),
    order_id               VARCHAR(100),
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX session_msg_no_2_unique ON qianxun_user_log (session_msg_no);

CREATE TABLE qianxun_user_order_relation (
    id                     VARCHAR(32) NOT NULL,
    user_id                VARCHAR(64),
    order_id               VARCHAR(32),
    status                 VARCHAR(2) DEFAULT 'Y',
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    consumption_user_count BIGINT DEFAULT 0,
    PRIMARY KEY (id)
);
COMMENT ON TABLE qianxun_user_order_relation IS '订单关联用户表';
COMMENT ON COLUMN qianxun_user_order_relation.id IS '关联关系的唯一标识，自增主键';
COMMENT ON COLUMN qianxun_user_order_relation.user_id IS '用户通用唯一识别码，关联用户信息表中的 user_uuid';
COMMENT ON COLUMN qianxun_user_order_relation.order_id IS '订单 ID，关联订单信息表中的 order_id';
COMMENT ON COLUMN qianxun_user_order_relation.status IS '关联状态，Y有效，N无效';
COMMENT ON COLUMN qianxun_user_order_relation.create_time IS '关联关系创建时间';
COMMENT ON COLUMN qianxun_user_order_relation.update_time IS '关联关系更新时间';
COMMENT ON COLUMN qianxun_user_order_relation.consumption_user_count IS '订单按用户可用消费次数';
CREATE UNIQUE INDEX qianxun_user_order_relation_user_id_idx ON qianxun_user_order_relation (user_id, order_id);

CREATE TABLE rasa_agent_logs (
    session_msg_no         VARCHAR(64) NOT NULL,
    agent_code             VARCHAR(256) NOT NULL,
    start_time             VARCHAR(40) NOT NULL,
    hub_account            VARCHAR(80) NOT NULL,
    PRIMARY KEY (session_msg_no, agent_code, hub_account)
);
COMMENT ON COLUMN rasa_agent_logs.session_msg_no IS '问题id';
COMMENT ON COLUMN rasa_agent_logs.agent_code IS 'Agent code';
COMMENT ON COLUMN rasa_agent_logs.start_time IS '问答时间';
COMMENT ON COLUMN rasa_agent_logs.hub_account IS 'hub账号';

CREATE TABLE rasa_chat_detail_info (
    id                                         BIGINT NOT NULL AUTO_INCREMENT,
    session_no                                 VARCHAR(64) DEFAULT '' NOT NULL,
    session_msg_no                             VARCHAR(64) DEFAULT '' NOT NULL,
    report_no                                  VARCHAR(64),
    user_id                                    VARCHAR(64) DEFAULT '' NOT NULL,
    hub_account                                VARCHAR(64) DEFAULT '' NOT NULL,
    role_type                                  VARCHAR(64) DEFAULT '' NOT NULL,
    plugin_name                                VARCHAR(200) DEFAULT '' NOT NULL,
    knowledge_ids                              VARCHAR(200),
    question                                   TEXT,
    start_time                                 TIMESTAMP,
    end_time                                   TIMESTAMP,
    intent                                     TEXT,
    question_cls                               TEXT,
    nlu                                        TEXT,
    ner                                        TEXT,
    statistics_info                            TEXT,
    intent_info                                TEXT,
    content_match_info                         TEXT,
    agent_code                                 TEXT,
    agent_info                                 TEXT,
    fallback_info                              TEXT,
    results                                    TEXT,
    actions_time_cost                          VARCHAR(256),
    rewrite_question                           TEXT,
    question_topic                             VARCHAR(100),
    question_answer_validation_class           VARCHAR(200),
    question_answer_validation_original_reault TEXT,
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX session_msg_no ON rasa_chat_detail_info (session_msg_no);

CREATE TABLE rasa_index_logs (
    session_msg_no         VARCHAR(64) NOT NULL,
    index_name             VARCHAR(256) NOT NULL,
    source_type            VARCHAR(256) NOT NULL,
    start_time             VARCHAR(40) NOT NULL,
    index_classification   VARCHAR(40),
    hub_account            VARCHAR(80) NOT NULL,
    PRIMARY KEY (session_msg_no, index_name, source_type, hub_account)
);
COMMENT ON COLUMN rasa_index_logs.session_msg_no IS '问题id';
COMMENT ON COLUMN rasa_index_logs.index_name IS '组件名';
COMMENT ON COLUMN rasa_index_logs.source_type IS 'source_type';
COMMENT ON COLUMN rasa_index_logs.start_time IS '问答时间';
COMMENT ON COLUMN rasa_index_logs.hub_account IS 'hub账号';

CREATE TABLE rasa_question_time_cost_percent_line (
    hour_str               VARCHAR(64) NOT NULL,
    line_80                DECIMAL(38,18) NOT NULL,
    line_85                DECIMAL(38,18) NOT NULL,
    line_90                DECIMAL(38,18) NOT NULL,
    line_95                DECIMAL(38,18) NOT NULL,
    line_99                DECIMAL(38,18) NOT NULL,
    PRIMARY KEY (hour_str)
);
COMMENT ON COLUMN rasa_question_time_cost_percent_line.hour_str IS '小时';
COMMENT ON COLUMN rasa_question_time_cost_percent_line.line_80 IS '80%line';
COMMENT ON COLUMN rasa_question_time_cost_percent_line.line_85 IS '85%line';
COMMENT ON COLUMN rasa_question_time_cost_percent_line.line_90 IS '90%line';
COMMENT ON COLUMN rasa_question_time_cost_percent_line.line_95 IS '95%line';
COMMENT ON COLUMN rasa_question_time_cost_percent_line.line_99 IS '99%line';

CREATE TABLE rasa_user_by_day (
    day_str                VARCHAR(20) NOT NULL,
    day_new_user           BIGINT DEFAULT 0 NOT NULL,
    day_user               BIGINT DEFAULT 0 NOT NULL,
    hub_account            VARCHAR(80) NOT NULL,
    day_count_user         BIGINT DEFAULT 0 NOT NULL,
    day_qa                 INT DEFAULT 0 NOT NULL,
    PRIMARY KEY (day_str, hub_account)
);
COMMENT ON COLUMN rasa_user_by_day.day_str IS '天';
COMMENT ON COLUMN rasa_user_by_day.day_new_user IS '新用户';
COMMENT ON COLUMN rasa_user_by_day.day_user IS '用户';
COMMENT ON COLUMN rasa_user_by_day.hub_account IS 'hub账号';
COMMENT ON COLUMN rasa_user_by_day.day_count_user IS '累计用户';
COMMENT ON COLUMN rasa_user_by_day.day_qa IS '当天问答次数';

CREATE TABLE rela_index_config (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    index_id               INT,
    rela_index_id          INT,
    rela_index_status      VARCHAR(2) DEFAULT 'Y',
    PRIMARY KEY (id)
);
COMMENT ON TABLE rela_index_config IS '关联指标配置表';
COMMENT ON COLUMN rela_index_config.id IS '主键ID';
COMMENT ON COLUMN rela_index_config.index_id IS '指标ID';
COMMENT ON COLUMN rela_index_config.rela_index_id IS '关联指标ID';
COMMENT ON COLUMN rela_index_config.rela_index_status IS '关联指标状态';
CREATE UNIQUE INDEX idx_rela_index_code ON rela_index_config (index_id, rela_index_id);

CREATE TABLE report_version (
    reportversion          VARCHAR(32) NOT NULL,
    versionno              VARCHAR(10) NOT NULL,
    label                  VARCHAR(200),
    mark                   VARCHAR(200),
    createtime             VARCHAR(32),
    creatorid              VARCHAR(20),
    creatorname            VARCHAR(20),
    modifytime             VARCHAR(32),
    modifierid             VARCHAR(20),
    modifiername           VARCHAR(20),
    sortno                 VARCHAR(10),
    operation              VARCHAR(10) DEFAULT '1' NOT NULL,
    PRIMARY KEY (reportversion, versionno)
);
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

CREATE TABLE rule_check_upload_report_files (
    id                     VARCHAR(40) NOT NULL,
    session_no             VARCHAR(50) NOT NULL,
    user_id                VARCHAR(32) NOT NULL,
    ent_name               VARCHAR(256) NOT NULL,
    file_name              VARCHAR(256) NOT NULL,
    markdown_content       TEXT,
    segments               json,
    upload_time            VARCHAR(40) NOT NULL,
    update_time            VARCHAR(40),
    status                 VARCHAR(20) NOT NULL,
    local_path             VARCHAR(256),
    PRIMARY KEY (id)
);
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

CREATE TABLE rule_check_upload_rule_files (
    id                     VARCHAR(40) NOT NULL,
    session_no             VARCHAR(50) NOT NULL,
    user_id                VARCHAR(32) NOT NULL,
    file_name              VARCHAR(256) NOT NULL,
    markdown_content       TEXT,
    rules                  json,
    upload_time            VARCHAR(40) NOT NULL,
    update_time            VARCHAR(40),
    status                 VARCHAR(20) NOT NULL,
    local_path             VARCHAR(256),
    segments               json,
    PRIMARY KEY (id)
);
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

CREATE TABLE scene_inflect_info (
    _id                    BIGINT NOT NULL AUTO_INCREMENT,
    scenename              VARCHAR(255),
    prompt                 TEXT,
    largemodelcode         VARCHAR(255),
    expectformat           VARCHAR(255),
    PRIMARY KEY (_id)
);
COMMENT ON COLUMN scene_inflect_info._id IS '主键ID';

CREATE TABLE sence_relate_info (
    _id                    BIGINT NOT NULL AUTO_INCREMENT,
    id                     DECIMAL(22,0),
    knowledge_name         VARCHAR(255),
    knowledge_code         VARCHAR(255),
    knowledge_desc         VARCHAR(255),
    parent_group_value     VARCHAR(255),
    parent_group_name      VARCHAR(255),
    group_value            VARCHAR(255),
    group_name             VARCHAR(255),
    scenename              VARCHAR(255),
    prompt                 TEXT,
    largemodelcode         VARCHAR(255),
    expectformat           VARCHAR(255),
    PRIMARY KEY (_id)
);
COMMENT ON COLUMN sence_relate_info._id IS '主键ID';

CREATE TABLE sync_knowledge_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    knowledge_code         VARCHAR(100) NOT NULL,
    sync_flag              VARCHAR(2) DEFAULT 'Y' NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE sync_knowledge_info IS '知识库同步信息表';
COMMENT ON COLUMN sync_knowledge_info.id IS '主键ID';
COMMENT ON COLUMN sync_knowledge_info.knowledge_code IS '知识库编码';
COMMENT ON COLUMN sync_knowledge_info.sync_flag IS '同步标记 Y-同步 N-不同步';

CREATE TABLE sys_announcement (
    id                     VARCHAR(32) NOT NULL,
    titile                 VARCHAR(100),
    msg_content            TEXT,
    start_time             TIMESTAMP,
    end_time               TIMESTAMP,
    sender                 VARCHAR(100),
    priority               VARCHAR(255),
    msg_category           VARCHAR(10) DEFAULT '2' NOT NULL,
    send_status            VARCHAR(10),
    send_time              TIMESTAMP,
    cancel_time            TIMESTAMP,
    del_flag               VARCHAR(1),
    bus_type               VARCHAR(20),
    bus_id                 VARCHAR(50),
    open_type              VARCHAR(20),
    open_page              VARCHAR(255),
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    user_ids               TEXT,
    msg_abstract           TEXT,
    dt_task_id             VARCHAR(100),
    PRIMARY KEY (id)
);
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

CREATE TABLE sys_announcement_send (
    _id                    BIGINT NOT NULL AUTO_INCREMENT,
    id                     VARCHAR(32),
    annt_id                VARCHAR(32),
    user_id                VARCHAR(32),
    read_flag              VARCHAR(10),
    read_time              TIMESTAMP,
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    PRIMARY KEY (_id)
);
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

CREATE TABLE sys_api_info (
    id                     VARCHAR(32) NOT NULL,
    api_name               VARCHAR(200),
    api_des                VARCHAR(200),
    api_path               VARCHAR(200),
    perm_code              VARCHAR(200),
    perm_desc              VARCHAR(200),
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_api_info IS '接口信息表';
COMMENT ON COLUMN sys_api_info.id IS '主键id';
COMMENT ON COLUMN sys_api_info.api_name IS '接口名称';
COMMENT ON COLUMN sys_api_info.api_des IS '接口路径';
COMMENT ON COLUMN sys_api_info.api_path IS '接口路径';
COMMENT ON COLUMN sys_api_info.perm_code IS '权限编码';
COMMENT ON COLUMN sys_api_info.perm_desc IS '接口描述';
COMMENT ON COLUMN sys_api_info.create_time IS '创建时间';
COMMENT ON COLUMN sys_api_info.update_time IS '更新时间';

CREATE TABLE sys_category (
    id                     VARCHAR(36) NOT NULL,
    pid                    VARCHAR(36),
    name                   VARCHAR(100),
    code                   VARCHAR(100),
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    has_child              VARCHAR(3) DEFAULT '0',
    param_value            VARCHAR(100),
    param_status           VARCHAR(1) DEFAULT 'Y',
    synonym_word           VARCHAR(100),
    key_word               VARCHAR(1000),
    rela_table             VARCHAR(100),
    field_attr             VARCHAR(100),
    remark                 VARCHAR(500),
    hit_independently      VARCHAR(32) DEFAULT 'N',
    source_type_detail     VARCHAR(100),
    source_field_type      VARCHAR(100),
    param_desc             VARCHAR(1000),
    sample_question        VARCHAR(1000),
    PRIMARY KEY (id)
);
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

CREATE TABLE sys_check_rule (
    id                     VARCHAR(32) NOT NULL,
    rule_name              VARCHAR(100),
    rule_code              VARCHAR(100),
    rule_json              VARCHAR(1024),
    rule_description       VARCHAR(200),
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    PRIMARY KEY (id)
);
COMMENT ON COLUMN sys_check_rule.id IS '主键id';
COMMENT ON COLUMN sys_check_rule.rule_name IS '规则名称';
COMMENT ON COLUMN sys_check_rule.rule_code IS '规则Code';
COMMENT ON COLUMN sys_check_rule.rule_json IS '规则JSON';
COMMENT ON COLUMN sys_check_rule.rule_description IS '规则描述';
COMMENT ON COLUMN sys_check_rule.update_by IS '更新人';
COMMENT ON COLUMN sys_check_rule.update_time IS '更新时间';
COMMENT ON COLUMN sys_check_rule.create_by IS '创建人';
COMMENT ON COLUMN sys_check_rule.create_time IS '创建时间';
CREATE UNIQUE INDEX uni_sys_check_rule_code ON sys_check_rule (rule_code);

CREATE TABLE sys_data_log (
    id                     VARCHAR(32) NOT NULL,
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    data_table             VARCHAR(32),
    data_id                VARCHAR(32),
    data_content           TEXT,
    data_version           INT,
    PRIMARY KEY (id)
);
COMMENT ON COLUMN sys_data_log.id IS 'id';
COMMENT ON COLUMN sys_data_log.create_by IS '创建人登录名称';
COMMENT ON COLUMN sys_data_log.create_time IS '创建日期';
COMMENT ON COLUMN sys_data_log.update_by IS '更新人登录名称';
COMMENT ON COLUMN sys_data_log.update_time IS '更新日期';
COMMENT ON COLUMN sys_data_log.data_table IS '表名';
COMMENT ON COLUMN sys_data_log.data_id IS '数据ID';
COMMENT ON COLUMN sys_data_log.data_content IS '数据内容';
COMMENT ON COLUMN sys_data_log.data_version IS '版本号';

CREATE TABLE sys_data_source (
    id                     VARCHAR(36) NOT NULL,
    code                   VARCHAR(100),
    name                   VARCHAR(100),
    remark                 VARCHAR(200),
    db_type                VARCHAR(10),
    db_driver              VARCHAR(100),
    db_url                 VARCHAR(500),
    db_name                VARCHAR(100),
    db_username            VARCHAR(100),
    db_password            VARCHAR(100),
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX sys_data_source_code_uni ON sys_data_source (code);

CREATE TABLE sys_depart (
    id                     VARCHAR(32) NOT NULL,
    parent_id              VARCHAR(32),
    depart_name            VARCHAR(100) NOT NULL,
    depart_name_en         VARCHAR(500),
    depart_name_abbr       VARCHAR(500),
    depart_order           INT DEFAULT 0,
    description            VARCHAR(500),
    org_category           VARCHAR(10) DEFAULT '1' NOT NULL,
    org_type               VARCHAR(10),
    org_code               VARCHAR(64) NOT NULL,
    mobile                 VARCHAR(32),
    fax                    VARCHAR(32),
    address                VARCHAR(100),
    memo                   VARCHAR(500),
    status                 VARCHAR(1),
    del_flag               VARCHAR(1),
    qywx_identifier        VARCHAR(100),
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    datadate               VARCHAR(200),
    PRIMARY KEY (id)
);
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

CREATE TABLE sys_depart_permission (
    id                     VARCHAR(32) NOT NULL,
    depart_id              VARCHAR(32),
    permission_id          VARCHAR(32),
    data_rule_ids          VARCHAR(1000),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_depart_permission IS '部门权限表';
COMMENT ON COLUMN sys_depart_permission.depart_id IS '部门id';
COMMENT ON COLUMN sys_depart_permission.permission_id IS '权限id';
COMMENT ON COLUMN sys_depart_permission.data_rule_ids IS '数据规则id';

CREATE TABLE sys_depart_role (
    id                     VARCHAR(32) NOT NULL,
    depart_id              VARCHAR(32),
    role_name              VARCHAR(200),
    role_code              VARCHAR(100),
    description            VARCHAR(255),
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_depart_role IS '部门角色表';
COMMENT ON COLUMN sys_depart_role.depart_id IS '部门id';
COMMENT ON COLUMN sys_depart_role.role_name IS '部门角色名称';
COMMENT ON COLUMN sys_depart_role.role_code IS '部门角色编码';
COMMENT ON COLUMN sys_depart_role.description IS '描述';
COMMENT ON COLUMN sys_depart_role.create_by IS '创建人';
COMMENT ON COLUMN sys_depart_role.create_time IS '创建时间';
COMMENT ON COLUMN sys_depart_role.update_by IS '更新人';
COMMENT ON COLUMN sys_depart_role.update_time IS '更新时间';

CREATE TABLE sys_depart_role_permission (
    id                     VARCHAR(32) NOT NULL,
    depart_id              VARCHAR(32),
    role_id                VARCHAR(32),
    permission_id          VARCHAR(32),
    data_rule_ids          VARCHAR(1000),
    operate_date           TIMESTAMP,
    operate_ip             VARCHAR(20),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_depart_role_permission IS '部门角色权限表';
COMMENT ON COLUMN sys_depart_role_permission.depart_id IS '部门id';
COMMENT ON COLUMN sys_depart_role_permission.role_id IS '角色id';
COMMENT ON COLUMN sys_depart_role_permission.permission_id IS '权限id';
COMMENT ON COLUMN sys_depart_role_permission.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_depart_role_permission.operate_date IS '操作时间';
COMMENT ON COLUMN sys_depart_role_permission.operate_ip IS '操作ip';

CREATE TABLE sys_depart_role_user (
    id                     VARCHAR(32) NOT NULL,
    user_id                VARCHAR(32),
    drole_id               VARCHAR(32),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_depart_role_user IS '部门角色用户表';
COMMENT ON COLUMN sys_depart_role_user.id IS '主键id';
COMMENT ON COLUMN sys_depart_role_user.user_id IS '用户id';
COMMENT ON COLUMN sys_depart_role_user.drole_id IS '角色id';

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

CREATE TABLE sys_fill_rule (
    id                     VARCHAR(32) NOT NULL,
    rule_name              VARCHAR(100),
    rule_code              VARCHAR(100),
    rule_class             VARCHAR(100),
    rule_params            VARCHAR(200),
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    PRIMARY KEY (id)
);
COMMENT ON COLUMN sys_fill_rule.id IS '主键ID';
COMMENT ON COLUMN sys_fill_rule.rule_name IS '规则名称';
COMMENT ON COLUMN sys_fill_rule.rule_code IS '规则Code';
COMMENT ON COLUMN sys_fill_rule.rule_class IS '规则实现类';
COMMENT ON COLUMN sys_fill_rule.rule_params IS '规则参数';
COMMENT ON COLUMN sys_fill_rule.update_by IS '修改人';
COMMENT ON COLUMN sys_fill_rule.update_time IS '修改时间';
COMMENT ON COLUMN sys_fill_rule.create_by IS '创建人';
COMMENT ON COLUMN sys_fill_rule.create_time IS '创建时间';
CREATE UNIQUE INDEX uni_sys_fill_rule_code ON sys_fill_rule (rule_code);

CREATE TABLE sys_gateway_route (
    id                     VARCHAR(36) NOT NULL,
    router_id              VARCHAR(50),
    name                   VARCHAR(32),
    uri                    VARCHAR(32),
    predicates             TEXT,
    filters                TEXT,
    retryable              INT,
    strip_prefix           INT,
    persistable            INT,
    show_api               INT,
    status                 INT,
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(64),
    PRIMARY KEY (id)
);
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

CREATE TABLE sys_log (
    id                     VARCHAR(32) NOT NULL,
    log_type               INT,
    log_content            VARCHAR(1000),
    operate_type           INT,
    userid                 VARCHAR(32),
    username               VARCHAR(100),
    ip                     VARCHAR(100),
    method                 VARCHAR(500),
    request_url            VARCHAR(255),
    request_param          TEXT,
    request_type           VARCHAR(10),
    cost_time              BIGINT,
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    PRIMARY KEY (id)
);
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

CREATE TABLE sys_page_view_log (
    id                         BIGINT NOT NULL AUTO_INCREMENT,
    user_id                    VARCHAR(32),
    source_first_level_module  VARCHAR(20),
    source_second_level_module VARCHAR(20),
    source_hash                VARCHAR(50),
    source_page_name           VARCHAR(100),
    source_page_url            VARCHAR(400),
    source_page_param          TEXT,
    dest_first_level_module    VARCHAR(20),
    dest_second_level_module   VARCHAR(20),
    dest_hash                  VARCHAR(50),
    dest_page_name             VARCHAR(400),
    dest_page_url              VARCHAR(400),
    dest_page_param            TEXT,
    user_agent                 VARCHAR(200),
    user_ip                    VARCHAR(32),
    create_time                VARCHAR(20),
    access_time                VARCHAR(20),
    session_msg_no             VARCHAR(100),
    hub_account                VARCHAR(80) DEFAULT '' NOT NULL,
    org_name                   VARCHAR(1000),
    role_name                  VARCHAR(1000),
    menu_name                  VARCHAR(500),
    menu_name_code             VARCHAR(500),
    PRIMARY KEY (id)
);
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

CREATE TABLE sys_permission (
    id                     VARCHAR(32) NOT NULL,
    parent_id              VARCHAR(32),
    name                   VARCHAR(100),
    url                    VARCHAR(255),
    component              VARCHAR(255),
    component_name         VARCHAR(100),
    redirect               VARCHAR(255),
    menu_type              INT,
    perms                  VARCHAR(255),
    perms_type             VARCHAR(10) DEFAULT '0',
    sort_no                DECIMAL(8,2),
    always_show            SMALLINT,
    icon                   VARCHAR(100),
    is_route               SMALLINT DEFAULT 1,
    is_leaf                SMALLINT,
    keep_alive             SMALLINT,
    hidden                 INT DEFAULT 0,
    description            VARCHAR(255),
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    del_flag               INT DEFAULT 0,
    rule_flag              INT DEFAULT 0,
    status                 VARCHAR(2),
    internal_or_external   SMALLINT,
    is_show                DECIMAL(11,0),
    PRIMARY KEY (id)
);
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

CREATE TABLE sys_permission_data_rule (
    id                     VARCHAR(32) NOT NULL,
    permission_id          VARCHAR(32),
    rule_name              VARCHAR(50),
    rule_column            VARCHAR(50),
    rule_conditions        VARCHAR(50),
    rule_value             VARCHAR(300),
    status                 VARCHAR(3),
    create_time            TIMESTAMP,
    create_by              VARCHAR(32),
    update_time            TIMESTAMP,
    update_by              VARCHAR(32),
    PRIMARY KEY (id)
);
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

CREATE TABLE sys_position (
    id                     VARCHAR(32) NOT NULL,
    code                   VARCHAR(100),
    name                   VARCHAR(100),
    post_rank              VARCHAR(2),
    company_id             VARCHAR(255),
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(50),
    PRIMARY KEY (id)
);
COMMENT ON COLUMN sys_position.code IS '职务编码';
COMMENT ON COLUMN sys_position.name IS '职务名称';
COMMENT ON COLUMN sys_position.post_rank IS '职级';
COMMENT ON COLUMN sys_position.company_id IS '公司id';
COMMENT ON COLUMN sys_position.create_by IS '创建人';
COMMENT ON COLUMN sys_position.create_time IS '创建时间';
COMMENT ON COLUMN sys_position.update_by IS '修改人';
COMMENT ON COLUMN sys_position.update_time IS '修改时间';
COMMENT ON COLUMN sys_position.sys_org_code IS '组织机构编码';
CREATE UNIQUE INDEX uniq_code ON sys_position (code);

CREATE TABLE sys_quartz_job (
    id                     VARCHAR(32) NOT NULL,
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    del_flag               INT,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    job_class_name         VARCHAR(255),
    cron_expression        VARCHAR(255),
    parameter              VARCHAR(255),
    description            VARCHAR(255),
    status                 INT,
    PRIMARY KEY (id)
);
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

CREATE TABLE sys_role (
    id                     VARCHAR(32) NOT NULL,
    role_name              VARCHAR(200),
    role_code              VARCHAR(100) NOT NULL,
    description            VARCHAR(255),
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_role IS '角色表';
COMMENT ON COLUMN sys_role.id IS '主键id';
COMMENT ON COLUMN sys_role.role_name IS '角色名称';
COMMENT ON COLUMN sys_role.role_code IS '角色编码';
COMMENT ON COLUMN sys_role.description IS '描述';
COMMENT ON COLUMN sys_role.create_by IS '创建人';
COMMENT ON COLUMN sys_role.create_time IS '创建时间';
COMMENT ON COLUMN sys_role.update_by IS '更新人';
COMMENT ON COLUMN sys_role.update_time IS '更新时间';
CREATE UNIQUE INDEX uniq_sys_role_role_code ON sys_role (role_code);

CREATE TABLE sys_role_ai_user (
    id                     VARCHAR(100) NOT NULL,
    role_id                VARCHAR(32),
    user_id                VARCHAR(100),
    data_rule_ids          VARCHAR(1000),
    operate_date           TIMESTAMP,
    operate_ip             VARCHAR(20),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_role_ai_user IS '角色ai用户权限表';
COMMENT ON COLUMN sys_role_ai_user.role_id IS '角色id';
COMMENT ON COLUMN sys_role_ai_user.user_id IS '权限id';
COMMENT ON COLUMN sys_role_ai_user.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_role_ai_user.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_ai_user.operate_ip IS '操作ip';

CREATE TABLE sys_role_index (
    id                     VARCHAR(32) NOT NULL,
    role_id                VARCHAR(32),
    index_id               VARCHAR(32),
    data_rule_ids          VARCHAR(1000),
    operate_date           TIMESTAMP,
    operate_ip             VARCHAR(20),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_role_index IS '角色指标权限表';
COMMENT ON COLUMN sys_role_index.role_id IS '角色id';
COMMENT ON COLUMN sys_role_index.index_id IS '权限id';
COMMENT ON COLUMN sys_role_index.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_role_index.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_index.operate_ip IS '操作ip';

CREATE TABLE sys_role_knowledge (
    id                     VARCHAR(32) NOT NULL,
    role_id                VARCHAR(32),
    knowledge_id           VARCHAR(32),
    data_rule_ids          VARCHAR(1000),
    operate_date           TIMESTAMP,
    operate_ip             VARCHAR(20),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_role_knowledge IS '角色知识库权限表';
COMMENT ON COLUMN sys_role_knowledge.role_id IS '角色id';
COMMENT ON COLUMN sys_role_knowledge.knowledge_id IS '权限id';
COMMENT ON COLUMN sys_role_knowledge.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_role_knowledge.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_knowledge.operate_ip IS '操作ip';

CREATE TABLE sys_role_knowledge_output (
    id                     VARCHAR(32) NOT NULL,
    role_id                VARCHAR(32),
    group_id               VARCHAR(32),
    knowledge_id           VARCHAR(32),
    operate_date           TIMESTAMP,
    operate_ip             VARCHAR(20),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_role_knowledge_output IS '角色知识库输出要求权限表';
COMMENT ON COLUMN sys_role_knowledge_output.role_id IS '角色id';
COMMENT ON COLUMN sys_role_knowledge_output.group_id IS '知识库分组ID';
COMMENT ON COLUMN sys_role_knowledge_output.knowledge_id IS '知识库ID';
COMMENT ON COLUMN sys_role_knowledge_output.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_knowledge_output.operate_ip IS '操作ip';

CREATE TABLE sys_role_module (
    id                     VARCHAR(32) NOT NULL,
    role_id                VARCHAR(32),
    module_source          INT,
    data_rule_ids          VARCHAR(1000),
    operate_date           TIMESTAMP,
    operate_ip             VARCHAR(20),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_role_module IS '角色组件权限表';
COMMENT ON COLUMN sys_role_module.role_id IS '角色id';
COMMENT ON COLUMN sys_role_module.module_source IS '权限id';
COMMENT ON COLUMN sys_role_module.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_role_module.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_module.operate_ip IS '操作ip';

CREATE TABLE sys_role_permission (
    id                     VARCHAR(32) NOT NULL,
    role_id                VARCHAR(32),
    permission_id          VARCHAR(32),
    data_rule_ids          VARCHAR(1000),
    operate_date           TIMESTAMP,
    operate_ip             VARCHAR(20),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_role_permission IS '角色权限表';
COMMENT ON COLUMN sys_role_permission.role_id IS '角色id';
COMMENT ON COLUMN sys_role_permission.permission_id IS '权限id';
COMMENT ON COLUMN sys_role_permission.data_rule_ids IS '数据权限ids';
COMMENT ON COLUMN sys_role_permission.operate_date IS '操作时间';
COMMENT ON COLUMN sys_role_permission.operate_ip IS '操作ip';

CREATE TABLE sys_tenant (
    id                     INT NOT NULL,
    name                   VARCHAR(100),
    create_time            TIMESTAMP,
    create_by              VARCHAR(100),
    begin_date             TIMESTAMP,
    end_date               TIMESTAMP,
    status                 INT,
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_tenant IS '多租户信息表';
COMMENT ON COLUMN sys_tenant.id IS '租户编码';
COMMENT ON COLUMN sys_tenant.name IS '租户名称';
COMMENT ON COLUMN sys_tenant.create_time IS '创建时间';
COMMENT ON COLUMN sys_tenant.create_by IS '创建人';
COMMENT ON COLUMN sys_tenant.begin_date IS '开始时间';
COMMENT ON COLUMN sys_tenant.end_date IS '结束时间';
COMMENT ON COLUMN sys_tenant.status IS '状态 1正常 0冻结';

CREATE TABLE sys_third_account (
    id                     VARCHAR(32) NOT NULL,
    sys_user_id            VARCHAR(32),
    third_type             VARCHAR(255),
    avatar                 VARCHAR(255),
    status                 SMALLINT,
    del_flag               SMALLINT,
    realname               VARCHAR(100),
    third_user_uuid        VARCHAR(100),
    third_user_id          VARCHAR(100),
    PRIMARY KEY (id)
);
COMMENT ON COLUMN sys_third_account.id IS '编号';
COMMENT ON COLUMN sys_third_account.sys_user_id IS '第三方登录id';
COMMENT ON COLUMN sys_third_account.third_type IS '登录来源';
COMMENT ON COLUMN sys_third_account.avatar IS '头像';
COMMENT ON COLUMN sys_third_account.status IS '状态(1-正常,2-冻结)';
COMMENT ON COLUMN sys_third_account.del_flag IS '删除状态(0-正常,1-已删除)';
COMMENT ON COLUMN sys_third_account.realname IS '真实姓名';
COMMENT ON COLUMN sys_third_account.third_user_uuid IS '第三方账号';
COMMENT ON COLUMN sys_third_account.third_user_id IS '第三方app用户账号';

CREATE TABLE sys_user (
    id                     VARCHAR(64) NOT NULL,
    username               VARCHAR(100),
    realname               VARCHAR(100),
    password               VARCHAR(255),
    salt                   VARCHAR(45),
    avatar                 VARCHAR(255),
    birthday               TIMESTAMP,
    sex                    SMALLINT,
    email                  VARCHAR(45),
    phone                  VARCHAR(45),
    org_code               VARCHAR(64),
    status                 SMALLINT,
    del_flag               SMALLINT,
    third_id               VARCHAR(100),
    third_type             VARCHAR(100),
    activiti_sync          SMALLINT,
    work_no                VARCHAR(100),
    post                   VARCHAR(100),
    telephone              VARCHAR(45),
    create_by              VARCHAR(32),
    create_time            TIMESTAMP,
    update_by              VARCHAR(32),
    update_time            TIMESTAMP,
    user_identity          SMALLINT,
    depart_ids             TEXT,
    rel_tenant_ids         VARCHAR(100),
    client_id              VARCHAR(64),
    datadate               VARCHAR(200),
    user_login_name        VARCHAR(100),
    PRIMARY KEY (id)
);
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

CREATE TABLE sys_user_agent (
    id                     VARCHAR(32) NOT NULL,
    user_name              VARCHAR(100),
    agent_user_name        VARCHAR(100),
    start_time             TIMESTAMP,
    end_time               TIMESTAMP,
    status                 VARCHAR(2),
    create_name            VARCHAR(50),
    create_by              VARCHAR(50),
    create_time            TIMESTAMP,
    update_name            VARCHAR(50),
    update_by              VARCHAR(50),
    update_time            TIMESTAMP,
    sys_org_code           VARCHAR(50),
    sys_company_code       VARCHAR(50),
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX uniq_username ON sys_user_agent (user_name);

CREATE TABLE sys_user_api (
    id                     VARCHAR(32) NOT NULL,
    user_id                VARCHAR(32),
    api_id                 VARCHAR(32),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_user_api IS '用户接口表';
COMMENT ON COLUMN sys_user_api.id IS '主键id';
COMMENT ON COLUMN sys_user_api.user_id IS '用户id';
COMMENT ON COLUMN sys_user_api.api_id IS '接口id';

CREATE TABLE sys_user_depart (
    id                     VARCHAR(32) NOT NULL,
    user_id                VARCHAR(32),
    dep_id                 VARCHAR(32),
    datadate               VARCHAR(200),
    PRIMARY KEY (id)
);
COMMENT ON COLUMN sys_user_depart.id IS 'id';
COMMENT ON COLUMN sys_user_depart.user_id IS '用户id';
COMMENT ON COLUMN sys_user_depart.dep_id IS '部门id';

CREATE TABLE sys_user_role (
    id                     VARCHAR(32) NOT NULL,
    user_id                VARCHAR(32),
    role_id                VARCHAR(32),
    PRIMARY KEY (id)
);
COMMENT ON TABLE sys_user_role IS '用户角色表';
COMMENT ON COLUMN sys_user_role.id IS '主键id';
COMMENT ON COLUMN sys_user_role.user_id IS '用户id';
COMMENT ON COLUMN sys_user_role.role_id IS '角色id';

CREATE TABLE tasks_qa_industry_parse (
    task_id                VARCHAR(100) NOT NULL,
    notice_title           VARCHAR(1000),
    url                    VARCHAR(1000),
    file_name              VARCHAR(1000),
    file_type              VARCHAR(100),
    pubdate                VARCHAR(100),
    source                 VARCHAR(1000),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatetime             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status                 VARCHAR(100) DEFAULT 'init',
    userid                 VARCHAR(100),
    error_info             TEXT,
    ftp_url                VARCHAR(1000),
    original_no            VARCHAR(100),
    PRIMARY KEY (task_id)
);
COMMENT ON COLUMN tasks_qa_industry_parse.task_id IS 'md5';

CREATE TABLE tool_management (
    id                     VARCHAR(32) NOT NULL,
    tool_category          VARCHAR(50) NOT NULL,
    tool_name              VARCHAR(100) NOT NULL,
    tool_description       VARCHAR(500),
    tool_parameters        TEXT,
    impl_type              VARCHAR(20) DEFAULT 'custom',
    module_code            VARCHAR(100),
    module_code_parameters TEXT,
    tool_status            VARCHAR(2) DEFAULT 'Y',
    create_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cn_label               VARCHAR(200),
    en_label               VARCHAR(200),
    PRIMARY KEY (id)
);
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
CREATE UNIQUE INDEX idx_type_tool ON tool_management (tool_name, tool_category, impl_type);

CREATE TABLE trace_query_result (
    id                        BIGINT NOT NULL AUTO_INCREMENT,
    trace_id                  VARCHAR(100),
    knowledge_code            VARCHAR(100),
    query_status              VARCHAR(1) DEFAULT 'Y',
    query_result              TEXT,
    query_time                VARCHAR(40),
    cost_time                 INT,
    comment                   VARCHAR(500),
    app_source_query_result   VARCHAR(100),
    image_query_result        TEXT,
    whole_source_query_result TEXT,
    image_cost_time           INT,
    whole_source_cost_time    INT,
    PRIMARY KEY (id)
);
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

CREATE TABLE workflow_return_records (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    session_msg_no         VARCHAR(64) DEFAULT '' NOT NULL,
    user_id                VARCHAR(64) DEFAULT '' NOT NULL,
    question               TEXT,
    question_rewrite       TEXT,
    start_time             TEXT,
    end_time               TEXT,
    content                TEXT,
    "desc"                 TEXT,
    source_site            TEXT,
    site_url               TEXT,
    "date"                 TEXT,
    data_source            TEXT,
    PRIMARY KEY (id)
);
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

ALTER TABLE agent_rule MODIFY COLUMN rule_text TEXT;
ALTER TABLE agent_rule MODIFY COLUMN parsed_expression TEXT;
ALTER TABLE index_params MODIFY COLUMN columncomment VARCHAR(1000);
