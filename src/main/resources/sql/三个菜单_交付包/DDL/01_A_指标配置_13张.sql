-- =====================================================================
-- 三个菜单 · 建表 DDL · 【A】 指标配置菜单
--
-- 本组表数：13 张
-- 执行前置：SET search_path = <schema>, public;
-- 说明：交付包推荐直接执行 DDL/00_全部_44张表_一次性执行.sql（一次跑通 44 张）；
--       本文件是把该脚本按菜单分组拆出来的一份，便于「只想重建某一组」时单独执行。
--       脚本内无外键、无序列依赖，但**组内表之间可能互相引用数据**，重建请按 A→E 顺序。
-- =====================================================================

-- =====================================================================
-- A. 指标配置菜单
-- =====================================================================

-- ---------------------------------------------------------------
-- [1/44] index_base_group —— 指标分组信息（分组树）
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [2/44] index_params —— 指标参数信息表（主表）
-- ---------------------------------------------------------------
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
    columncomment          VARCHAR(1000),
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
-- ↑ 原公司脚本在此处有一条「事后加宽」语句：ALTER TABLE index_params MODIFY COLUMN columncomment VARCHAR(1000);
--   本脚本已把它**内联进上面的列定义**（columncomment = VARCHAR(1000)，与公司库实际类型一致），故此处不再需要该语句。
--   原因：原写法是 MySQL 风格 `MODIFY COLUMN`，在纯 PG 模式的库上可能不被支持；内联后两种模式都能跑。

-- ---------------------------------------------------------------
-- [3/44] index_params_version —— 指标参数版本信息表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [4/44] index_relate_info —— 指标关联信息表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [5/44] index_relate_index_info —— 指标关联指标信息表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [6/44] index_relate_knowledge_info —— 指标关联知识库信息表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [7/44] sys_data_source —— 数据源配置（数据源管理 + 数据源 API 向导）
-- ---------------------------------------------------------------
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
-- ↑ 下面这条表级注释为【本工程补写】（源 DDL 未提供），措辞按该表列注释口径归纳
COMMENT ON TABLE sys_data_source IS '数据源配置表';
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

-- ---------------------------------------------------------------
-- [8/44] ext_intf_manage —— 外部接口详细配置表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [9/44] ext_intf_param_define —— 外部服务公共参数定义表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [10/44] ext_intf_param_manage —— 外部接口参数配置表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [11/44] ext_intf_supplier_manage —— 外部服务配置表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [12/44] sys_category —— 分类字典（指标分类树）
-- ---------------------------------------------------------------
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
-- ↑ 下面这条表级注释为【本工程补写】（源 DDL 未提供），措辞按该表列注释口径归纳
COMMENT ON TABLE sys_category IS '分类字典表';
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

-- ---------------------------------------------------------------
-- [13/44] sys_role_index —— 角色指标权限表（「角色→指标」过滤 + 授权）
-- ---------------------------------------------------------------
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
