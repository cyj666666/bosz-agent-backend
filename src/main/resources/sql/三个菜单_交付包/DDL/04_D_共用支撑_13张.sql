-- =====================================================================
-- 三个菜单 · 建表 DDL · 【D】 三菜单共用 / 支撑表
--
-- 本组表数：13 张
-- 执行前置：SET search_path = <schema>, public;
-- 说明：交付包推荐直接执行 DDL/00_全部_44张表_一次性执行.sql（一次跑通 44 张）；
--       本文件是把该脚本按菜单分组拆出来的一份，便于「只想重建某一组」时单独执行。
--       脚本内无外键、无序列依赖，但**组内表之间可能互相引用数据**，重建请按 A→E 顺序。
-- =====================================================================

-- =====================================================================
-- D. 三菜单共用 / 支撑表
-- =====================================================================

-- ---------------------------------------------------------------
-- [27/44] large_model_config —— 大模型配置（三菜单共用：模型下拉、参数、调用）
-- ---------------------------------------------------------------
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
-- ↑ 下面这条表级注释为【本工程补写】（源 DDL 未提供），措辞按该表列注释口径归纳
COMMENT ON TABLE large_model_config IS '大模型配置表';
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

-- ---------------------------------------------------------------
-- [28/44] sys_role_ai_user —— 角色 AI 用户权限表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [29/44] knowledge_query_result —— 知识库查询记录表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [30/44] knowledge_query_result_for_batch —— 知识库批量查询记录表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [31/44] knowledge_sync_task —— 知识库同步任务记录表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [32/44] knowledge_sync_task_exception_record —— 知识库同步任务异常记录表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [33/44] sync_knowledge_info —— 知识库同步信息表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [34/44] module_code_prompt_cache —— 知识库文案缓存表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [35/44] prompt_query_result —— prompt 请求结果记录表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [36/44] trace_query_result —— 溯源查询记录表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [37/44] call_llm_record —— 大模型调用记录表
-- ---------------------------------------------------------------
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
-- ↑ 下面这条表级注释为【本工程补写】（源 DDL 未提供），措辞按该表列注释口径归纳
COMMENT ON TABLE call_llm_record IS '大模型调用记录表';

-- ---------------------------------------------------------------
-- [38/44] open_api_conf —— openapi 定义
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [39/44] tool_management —— 大模型工具管理表
-- ---------------------------------------------------------------
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
