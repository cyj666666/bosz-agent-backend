-- =============================================
-- GaussDB 表注释 & 字段注释
-- 来源：MySQL suzhou_bank_report 库原始注释
-- 生成时间：Wed Jun 24 19:47:04 CST 2026
-- 执行方式：通过 GaussDBInit 或 psql 连接后执行
-- =============================================

-- ====== collector_config (采集器配置表) ======
COMMENT ON TABLE collector_config IS '采集器配置表';
COMMENT ON COLUMN collector_config.id IS '主键ID';
COMMENT ON COLUMN collector_config.config_name IS '配置名称';
COMMENT ON COLUMN collector_config.collector_type IS '采集器类型';
COMMENT ON COLUMN collector_config.config_json IS '采集器配置JSON';
COMMENT ON COLUMN collector_config.cron_expression IS '定时cron表达式';
COMMENT ON COLUMN collector_config.enabled IS '是否启用';

-- ====== credit_record (用信记录表) ======
COMMENT ON TABLE credit_record IS '用信记录表';
COMMENT ON COLUMN credit_record.id IS '主键ID';
COMMENT ON COLUMN credit_record.customer_id IS '客户ID';
COMMENT ON COLUMN credit_record.contract_no IS '合同编号';
COMMENT ON COLUMN credit_record.loan_type IS '贷款种类';
COMMENT ON COLUMN credit_record.currency IS '币种';
COMMENT ON COLUMN credit_record.loan_amount IS '贷款金额';
COMMENT ON COLUMN credit_record.loan_balance IS '贷款余额';
COMMENT ON COLUMN credit_record.start_date IS '贷款起始日';
COMMENT ON COLUMN credit_record.end_date IS '贷款到期日';
COMMENT ON COLUMN credit_record.loan_purpose IS '贷款用途';
COMMENT ON COLUMN credit_record.guarantee_type IS '担保情况';

-- ====== customer (客户主表) ======
COMMENT ON TABLE customer IS '客户主表';
COMMENT ON COLUMN customer.id IS '主键ID';
COMMENT ON COLUMN customer.company_name IS '企业名称';
COMMENT ON COLUMN customer.credit_code IS '统一社会信用代码';
COMMENT ON COLUMN customer.legal_person IS '法定代表人';
COMMENT ON COLUMN customer.actual_controller IS '实际控制人';
COMMENT ON COLUMN customer.registered_capital IS '注册资本';
COMMENT ON COLUMN customer.paid_capital IS '实缴资本';
COMMENT ON COLUMN customer.establish_date IS '成立日期';
COMMENT ON COLUMN customer.industry IS '所属行业';
COMMENT ON COLUMN customer.biz_scope IS '主营业务';
COMMENT ON COLUMN customer.register_address IS '注册地址';
COMMENT ON COLUMN customer.holding_type IS '控股类型';
COMMENT ON COLUMN customer.shareholder IS '股东';
COMMENT ON COLUMN customer.group_name IS '所属集团';
COMMENT ON COLUMN customer.customer_type IS '客户类型';
COMMENT ON COLUMN customer.first_loan_date IS '首贷日期';
COMMENT ON COLUMN customer.last_approval_date IS '最新批复日期';
COMMENT ON COLUMN customer.main_bank IS '基本开户行';
COMMENT ON COLUMN customer.settlement_bank IS '主要结算行';
COMMENT ON COLUMN customer.status IS '状态';

-- ====== indicator_data (结构化指标数据表) ======
COMMENT ON TABLE indicator_data IS '结构化指标数据表';
COMMENT ON COLUMN indicator_data.id IS '主键ID';
COMMENT ON COLUMN indicator_data.customer_id IS '客户ID';
COMMENT ON COLUMN indicator_data.indicator_key IS '指标编码';
COMMENT ON COLUMN indicator_data.indicator_name IS '指标名称';
COMMENT ON COLUMN indicator_data.current_value IS '本期值';
COMMENT ON COLUMN indicator_data.previous_value IS '上期值';
COMMENT ON COLUMN indicator_data.change_desc IS '变化描述';
COMMENT ON COLUMN indicator_data.data_unit IS '单位';
COMMENT ON COLUMN indicator_data.domain IS '数据域';
COMMENT ON COLUMN indicator_data.period IS '数据期间';
COMMENT ON COLUMN indicator_data.sort_order IS '排序';

-- ====== knowledge_rule (风险判定规则表) ======
COMMENT ON TABLE knowledge_rule IS '风险判定规则表';
COMMENT ON COLUMN knowledge_rule.id IS '主键ID';
COMMENT ON COLUMN knowledge_rule.rule_code IS '规则编号';
COMMENT ON COLUMN knowledge_rule.rule_name IS '规则名称';
COMMENT ON COLUMN knowledge_rule.rule_type IS '规则类型';
COMMENT ON COLUMN knowledge_rule.description IS '规则说明';
COMMENT ON COLUMN knowledge_rule.enabled IS '是否启用';

-- ====== know_kit_task (Know-Kit任务记录表) ======
COMMENT ON TABLE know_kit_task IS 'Know-Kit任务记录表';
COMMENT ON COLUMN know_kit_task.id IS '主键ID';
COMMENT ON COLUMN know_kit_task.customer_id IS '客户ID';
COMMENT ON COLUMN know_kit_task.scenario_tags IS '场景标签';
COMMENT ON COLUMN know_kit_task.request_json IS '请求JSON';
COMMENT ON COLUMN know_kit_task.response_json IS '响应JSON';
COMMENT ON COLUMN know_kit_task.status IS '任务状态';
COMMENT ON COLUMN know_kit_task.error_msg IS '错误信息';
COMMENT ON COLUMN know_kit_task.completed_at IS '完成时间';

-- ====== parser_config (解析器配置表) ======
COMMENT ON TABLE parser_config IS '解析器配置表';
COMMENT ON COLUMN parser_config.id IS '主键ID';
COMMENT ON COLUMN parser_config.collector_id IS '关联采集器ID';
COMMENT ON COLUMN parser_config.parser_type IS '解析器类型';
COMMENT ON COLUMN parser_config.config_json IS '解析配置JSON';
COMMENT ON COLUMN parser_config.domain IS '数据域';
COMMENT ON COLUMN parser_config.sort_order IS '执行顺序';

-- ====== raw_data_log (原始数据日志表) ======
COMMENT ON TABLE raw_data_log IS '原始数据日志表';
COMMENT ON COLUMN raw_data_log.id IS '主键ID';
COMMENT ON COLUMN raw_data_log.collector_id IS '采集器ID';
COMMENT ON COLUMN raw_data_log.raw_content IS '原始数据内容';
COMMENT ON COLUMN raw_data_log.content_type IS '内容类型';
COMMENT ON COLUMN raw_data_log.file_path IS '文件路径';
COMMENT ON COLUMN raw_data_log.collect_time IS '采集时间';
COMMENT ON COLUMN raw_data_log.customer_id IS '对应客户ID';
COMMENT ON COLUMN raw_data_log.success IS '是否成功';
COMMENT ON COLUMN raw_data_log.error_msg IS '错误信息';

-- ====== report (报告主表) ======
COMMENT ON TABLE report IS '报告主表';
COMMENT ON COLUMN report.id IS '主键ID';
COMMENT ON COLUMN report.customer_id IS '客户ID';
COMMENT ON COLUMN report.report_title IS '报告标题';
COMMENT ON COLUMN report.report_type IS '报告类型';
COMMENT ON COLUMN report.status IS '报告状态';
COMMENT ON COLUMN report.know_kit_task_id IS '关联Know-Kit任务ID';
COMMENT ON COLUMN report.content_html IS '报告HTML内容';
COMMENT ON COLUMN report.data_snapshot IS '数据快照JSON';

-- ====== rule_condition (规则条件表) ======
COMMENT ON TABLE rule_condition IS '规则条件表';
COMMENT ON COLUMN rule_condition.id IS '主键ID';
COMMENT ON COLUMN rule_condition.rule_id IS '规则ID';
COMMENT ON COLUMN rule_condition.indicator_key IS '指标编码';
COMMENT ON COLUMN rule_condition.operator IS '运算符';
COMMENT ON COLUMN rule_condition.threshold IS '阈值';
COMMENT ON COLUMN rule_condition.logic_order IS '条件顺序';
COMMENT ON COLUMN rule_condition.logic_connector IS '逻辑连接符';

-- ====== rule_scenario (场景定义表) ======
COMMENT ON TABLE rule_scenario IS '场景定义表';
COMMENT ON COLUMN rule_scenario.id IS '主键ID';
COMMENT ON COLUMN rule_scenario.scenario_code IS '场景编码';
COMMENT ON COLUMN rule_scenario.scenario_name IS '场景名称';
COMMENT ON COLUMN rule_scenario.description IS '场景描述';

-- ====== rule_tag (规则标签表) ======
COMMENT ON TABLE rule_tag IS '规则标签表';
COMMENT ON COLUMN rule_tag.id IS '主键ID';
COMMENT ON COLUMN rule_tag.rule_id IS '规则ID';
COMMENT ON COLUMN rule_tag.tag_type IS '标签类型';
COMMENT ON COLUMN rule_tag.tag_value IS '标签值';

-- ====== sys_role (角色表) ======
COMMENT ON TABLE sys_role IS '角色表';
COMMENT ON COLUMN sys_role.id IS '主键';
COMMENT ON COLUMN sys_role.role_code IS '角色编码';
COMMENT ON COLUMN sys_role.role_name IS '角色名称';
COMMENT ON COLUMN sys_role.description IS '描述';
COMMENT ON COLUMN sys_role.menu_permissions IS '菜单权限 JSON数组';
COMMENT ON COLUMN sys_role.created_at IS '创建时间';

-- ====== sys_user (系统用户表) ======
COMMENT ON TABLE sys_user IS '系统用户表';
COMMENT ON COLUMN sys_user.id IS '主键';
COMMENT ON COLUMN sys_user.username IS '用户名';
COMMENT ON COLUMN sys_user.password IS '密码（BCrypt 加密）';
COMMENT ON COLUMN sys_user.real_name IS '真实姓名';
COMMENT ON COLUMN sys_user.status IS '状态 1=启用 0=禁用';
COMMENT ON COLUMN sys_user.created_at IS '创建时间';

-- ====== sys_user_role (用户角色关联表) ======
COMMENT ON TABLE sys_user_role IS '用户角色关联表';
COMMENT ON COLUMN sys_user_role.id IS '主键';
COMMENT ON COLUMN sys_user_role.user_id IS '用户ID';
COMMENT ON COLUMN sys_user_role.role_id IS '角色ID';

-- ====== text_data (文本数据表) ======
COMMENT ON TABLE text_data IS '文本数据表';
COMMENT ON COLUMN text_data.id IS '主键ID';
COMMENT ON COLUMN text_data.customer_id IS '客户ID';
COMMENT ON COLUMN text_data.text_type IS '文本类型';
COMMENT ON COLUMN text_data.domain IS '数据域';
COMMENT ON COLUMN text_data.title IS '文本标题';
COMMENT ON COLUMN text_data.content IS '文本内容';
COMMENT ON COLUMN text_data.period IS '数据期间';


-- ====== 以下为 MySQL 中缺注释的字段，自动补齐 ======
COMMENT ON COLUMN collector_config.created_at IS '创建时间';
COMMENT ON COLUMN collector_config.updated_at IS '更新时间';
COMMENT ON COLUMN credit_record.created_at IS '创建时间';
COMMENT ON COLUMN customer.created_at IS '创建时间';
COMMENT ON COLUMN customer.updated_at IS '更新时间';
COMMENT ON COLUMN indicator_data.created_at IS '创建时间';
COMMENT ON COLUMN knowledge_rule.created_at IS '创建时间';
COMMENT ON COLUMN knowledge_rule.updated_at IS '更新时间';
COMMENT ON COLUMN know_kit_task.created_at IS '创建时间';
COMMENT ON COLUMN parser_config.created_at IS '创建时间';
COMMENT ON COLUMN parser_config.updated_at IS '更新时间';
COMMENT ON COLUMN raw_data_log.created_at IS '创建时间';
COMMENT ON COLUMN report.created_at IS '创建时间';
COMMENT ON COLUMN report.updated_at IS '更新时间';
COMMENT ON COLUMN rule_scenario.created_at IS '创建时间';
COMMENT ON COLUMN text_data.created_at IS '创建时间';
