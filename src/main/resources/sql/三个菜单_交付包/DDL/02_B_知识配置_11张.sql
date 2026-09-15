-- =====================================================================
-- 三个菜单 · 建表 DDL · 【B】 知识配置菜单
--
-- 本组表数：11 张
-- 执行前置：SET search_path = <schema>, public;
-- 说明：交付包推荐直接执行 DDL/00_全部_44张表_一次性执行.sql（一次跑通 44 张）；
--       本文件是把该脚本按菜单分组拆出来的一份，便于「只想重建某一组」时单独执行。
--       脚本内无外键、无序列依赖，但**组内表之间可能互相引用数据**，重建请按 A→E 顺序。
-- =====================================================================

-- =====================================================================
-- B. 知识配置菜单
-- =====================================================================

-- ---------------------------------------------------------------
-- [14/44] knowledge_base_group —— 知识库分组信息（分组树）
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [15/44] knowledge_base_params —— 知识库参数信息表（主表，知识库配置核心载荷）
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [16/44] knowledge_base_version —— 知识库版本管理（发布/历史版本）
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [17/44] knowledge_black_params_config —— 知识库黑盒参数配置表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [18/44] knowledge_black_params_config_version —— 知识库黑盒参数配置版本记录表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [19/44] knowledge_relate_index —— 知识库关联指标信息（细分参数配置）
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [20/44] knowledge_relate_index_version —— 知识库关联指标版本记录表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [21/44] knowledge_relate_input_param —— 知识库关联参数集（测试集）
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [22/44] knowledge_relate_input_param_version —— 知识库关联参数集版本记录表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [23/44] sys_role_knowledge —— 角色知识库权限表
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- [24/44] sys_role_knowledge_output —— 角色知识库输出要求权限表（决定 hasAuth）
-- ---------------------------------------------------------------
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
