-- ============================================================================
-- agent 模块建表脚本（as_agent schema 专用）—— 共 39 张表
-- ============================================================================
-- 来源：从公司交付的 agent_gauss_ddl.sql（179 张表 / 2742 条语句）中【精确抽取】子集，
--       除 search_path 外未做任何改写，保证与公司交付版逐字一致。
--
-- 表清单来源：com.suzhou.bank.agent.entity 下各实体的 @TableName 注解（脚本自动提取，
--   避免人工维护清单漏表）。当前覆盖三个菜单（指标配置 / 知识配置管理 / 智策引擎）的全部用表。
--
-- 为什么不能整份执行：
--   公司脚本的 search_path 是 bosz_test，且包含 JeecgBoot 的 sys_user / sys_role /
--   sys_user_role / sys_permission 等表。宿主库 as_agent 下【已存在同名表】，
--   直接执行会报 relation already exists。故只抽取 agent 模块代码真正引用的表。
--
-- 脚本是【幂等】的：已存在的表会报 "already exists" 并被跳过，可重复执行。
-- ============================================================================

SET search_path = as_agent, public;

-- 抽取语句共 661 条（CREATE TABLE + COMMENT + INDEX）

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

