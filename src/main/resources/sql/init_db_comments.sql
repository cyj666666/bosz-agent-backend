-- =============================================
-- GaussDB 表注释 & 字段注释
-- 来源：MySQL suzhou_bank_report 库原始注释
-- 生成时间：Wed Jun 24 19:47:04 CST 2026
-- 执行方式：通过 GaussDBInit 或 psql 连接后执行
-- =============================================

-- ====== app_report_ai_analysis (报告AI全文分析表) ======
COMMENT ON TABLE app_report_ai_analysis IS '报告详情-AI全文分析表（挂在报告编号上、保留多次，同一报告同时只允许一次进行中）';
COMMENT ON COLUMN app_report_ai_analysis.id IS '主键（自增）';
COMMENT ON COLUMN app_report_ai_analysis.reportNo IS '报告编号（归档维度，同一报告可保留多次分析记录）';
COMMENT ON COLUMN app_report_ai_analysis.checkTaskNo IS '日检流水号（冗余，便于按流水号追溯）';
COMMENT ON COLUMN app_report_ai_analysis.customerId IS '客户编号';
COMMENT ON COLUMN app_report_ai_analysis.customerName IS '客户名称';
COMMENT ON COLUMN app_report_ai_analysis.status IS '分析状态：RUNNING-进行中 / DONE-已完成 / FAILED-失败';
COMMENT ON COLUMN app_report_ai_analysis.analysisContent IS '分析正文（成品HTML片段，前端直接渲染）';
COMMENT ON COLUMN app_report_ai_analysis.summary IS '综合结论摘要';
COMMENT ON COLUMN app_report_ai_analysis.riskLevel IS '大模型给出的总体风险等级';
COMMENT ON COLUMN app_report_ai_analysis.lmCode IS '所用大模型配置编码（large_model_config.lm_code）';
COMMENT ON COLUMN app_report_ai_analysis.modelName IS '实际调用的模型名';
COMMENT ON COLUMN app_report_ai_analysis.sourceSnapshot IS '送进大模型的素材快照（正文摘取 + 外部数据，便于追溯与复算）';
COMMENT ON COLUMN app_report_ai_analysis.promptSnapshot IS '实际使用的提示词快照';
COMMENT ON COLUMN app_report_ai_analysis.operatorNo IS '触发人账号';
COMMENT ON COLUMN app_report_ai_analysis.operatorName IS '触发人姓名';
COMMENT ON COLUMN app_report_ai_analysis.costMillis IS '大模型调用耗时（毫秒）';
COMMENT ON COLUMN app_report_ai_analysis.failReason IS '失败原因（超1000字符截断）';
COMMENT ON COLUMN app_report_ai_analysis.generateTime IS '分析完成时间';
COMMENT ON COLUMN app_report_ai_analysis.inputtime IS '创建时间（默认当前时间）';

-- ====== app_report_prompt (报告提示词表) ======
COMMENT ON TABLE app_report_prompt IS '报告提示词表（按 promptCode 取用，改提示词无需改代码；查不到回落到代码兜底常量）';
COMMENT ON COLUMN app_report_prompt.id IS '主键（自增）';
COMMENT ON COLUMN app_report_prompt.promptCode IS '提示词编码（唯一）：AI_FULL_ANALYSIS-全文分析 / WARNING_ADVICE-预警建议';
COMMENT ON COLUMN app_report_prompt.promptName IS '提示词名称（界面展示用）';
COMMENT ON COLUMN app_report_prompt.sceneType IS '场景分类（AI_ANALYSIS 等，便于分组管理）';
COMMENT ON COLUMN app_report_prompt.systemPrompt IS '系统提示词（角色、要求、输出格式）';
COMMENT ON COLUMN app_report_prompt.userPromptTemplate IS '用户提示词模板，用 {material} 占位，调用时替换为素材';
COMMENT ON COLUMN app_report_prompt.isEnabled IS '是否启用：Y-启用 N-停用（停用则回落到代码兜底常量）';
COMMENT ON COLUMN app_report_prompt.remark IS '备注';
COMMENT ON COLUMN app_report_prompt.inputtime IS '创建时间（默认当前时间）';
COMMENT ON COLUMN app_report_prompt.updateTime IS '更新时间';

-- ====== app_report_warning_advice_batch (报告预警建议批次表) ======
COMMENT ON TABLE app_report_warning_advice_batch IS '报告预警建议批次表（一行=一次生成，承载状态/核心提示/模型信息/失败原因）';
COMMENT ON COLUMN app_report_warning_advice_batch.id IS '主键（自增）';
COMMENT ON COLUMN app_report_warning_advice_batch.reportNo IS '报告编号（归档维度，同一报告可保留多次）';
COMMENT ON COLUMN app_report_warning_advice_batch.checkTaskNo IS '日检流水号（冗余，便于按流水号追溯）';
COMMENT ON COLUMN app_report_warning_advice_batch.analysisId IS '基于哪一次全文分析生成（app_report_ai_analysis.id）';
COMMENT ON COLUMN app_report_warning_advice_batch.customerId IS '客户编号';
COMMENT ON COLUMN app_report_warning_advice_batch.customerName IS '客户名称';
COMMENT ON COLUMN app_report_warning_advice_batch.status IS '生成状态：RUNNING-进行中 / DONE-已完成 / FAILED-失败';
COMMENT ON COLUMN app_report_warning_advice_batch.coreTip IS '核心提示（模型总结，1~3句话概括最需关注的风险）';
COMMENT ON COLUMN app_report_warning_advice_batch.promptCode IS '所用提示词编码（app_report_prompt.promptCode）';
COMMENT ON COLUMN app_report_warning_advice_batch.lmCode IS '所用大模型配置编码（large_model_config.lm_code）';
COMMENT ON COLUMN app_report_warning_advice_batch.modelName IS '实际调用的模型名';
COMMENT ON COLUMN app_report_warning_advice_batch.sourceSnapshot IS '送进大模型的素材快照（便于追溯与复算）';
COMMENT ON COLUMN app_report_warning_advice_batch.promptSnapshot IS '实际使用的提示词快照';
COMMENT ON COLUMN app_report_warning_advice_batch.operatorNo IS '触发人账号';
COMMENT ON COLUMN app_report_warning_advice_batch.operatorName IS '触发人姓名';
COMMENT ON COLUMN app_report_warning_advice_batch.costMillis IS '大模型调用耗时（毫秒）';
COMMENT ON COLUMN app_report_warning_advice_batch.failReason IS '失败原因（超1000字符截断）';
COMMENT ON COLUMN app_report_warning_advice_batch.generateTime IS '生成完成时间';
COMMENT ON COLUMN app_report_warning_advice_batch.inputtime IS '创建时间（默认当前时间）';

-- ====== app_report_warning_advice (报告预警建议明细表) ======
COMMENT ON TABLE app_report_warning_advice IS '报告预警建议明细表（一行=一条预警信号，逐条采纳/不采纳）';
COMMENT ON COLUMN app_report_warning_advice.id IS '主键（自增）';
COMMENT ON COLUMN app_report_warning_advice.batchId IS '所属批次（app_report_warning_advice_batch.id）';
COMMENT ON COLUMN app_report_warning_advice.reportNo IS '报告编号（冗余，便于直接按报告查询）';
COMMENT ON COLUMN app_report_warning_advice.seqNo IS '序号（模型输出顺序，已按红>橙>黄排序）';
COMMENT ON COLUMN app_report_warning_advice.warningLevel IS '建议预警等级：RED-红色 / ORANGE-橙色 / YELLOW-黄色';
COMMENT ON COLUMN app_report_warning_advice.signalDesc IS '预警信号描述';
COMMENT ON COLUMN app_report_warning_advice.triggerCondition IS '触发条件/判断依据';
COMMENT ON COLUMN app_report_warning_advice.sourceText IS '原文依据（引用原文关键句）';
COMMENT ON COLUMN app_report_warning_advice.riskDesc IS '风险点描述（未关联到风险点时为空）';
COMMENT ON COLUMN app_report_warning_advice.chapter IS '所在章节/段落';
COMMENT ON COLUMN app_report_warning_advice.status IS '处理状态：PENDING-待处理 / ADOPTED-已采纳 / INVALID-无效';
COMMENT ON COLUMN app_report_warning_advice.operatorNo IS '处理人账号';
COMMENT ON COLUMN app_report_warning_advice.operatorName IS '处理人姓名';
COMMENT ON COLUMN app_report_warning_advice.operateTime IS '处理时间';
COMMENT ON COLUMN app_report_warning_advice.inputtime IS '创建时间（默认当前时间）';

-- ====== app_report_risk_edit_log (报告风险要点修改记录表) ======
COMMENT ON TABLE app_report_risk_edit_log IS '报告详情-风险要点修改记录表（归档维度：同日检流水号 + 同风险要点）';
COMMENT ON COLUMN app_report_risk_edit_log.id IS '主键（自增）';
COMMENT ON COLUMN app_report_risk_edit_log.checkTaskNo IS '日检流水号（归档维度①，跨版本追溯用）';
COMMENT ON COLUMN app_report_risk_edit_log.blockCode IS '风险要点编号（=内容块编号，归档维度②）';
COMMENT ON COLUMN app_report_risk_edit_log.reportNo IS '产生本次修改的报告编号（追溯是哪一版改的）';
COMMENT ON COLUMN app_report_risk_edit_log.blockName IS '风险要点名称（冗余，便于单独展示）';
COMMENT ON COLUMN app_report_risk_edit_log.catalogCode IS '所属目录编号（冗余）';
COMMENT ON COLUMN app_report_risk_edit_log.customerId IS '客户编号（冗余）';
COMMENT ON COLUMN app_report_risk_edit_log.customerName IS '客户名称（冗余）';
COMMENT ON COLUMN app_report_risk_edit_log.contentBefore IS '修改前文案（审计对比用）';
COMMENT ON COLUMN app_report_risk_edit_log.contentAfter IS '修改后文案（列表展示用）';
COMMENT ON COLUMN app_report_risk_edit_log.operatorNo IS '修改人账号';
COMMENT ON COLUMN app_report_risk_edit_log.operatorName IS '修改人姓名（取 sys_user.real_name，取不到回落账号）';
COMMENT ON COLUMN app_report_risk_edit_log.inputtime IS '修改时间（默认当前时间）';

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
COMMENT ON COLUMN knowledge_rule.sort_order IS '排序序号（对应经验库规则框架顺序）';

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

-- ====== large_model_config (大模型配置表) ======
-- 说明：该表的建表语句在 sql/agent/agent_gauss_ddl.sql（第 3499 行），此处只补注释
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
COMMENT ON COLUMN report.report_no IS '报告编号（业务唯一键，关联内容实例表与AI风险表）';
COMMENT ON COLUMN report.customer_id IS '客户编号';
COMMENT ON COLUMN report.customer_name IS '客户名称';
COMMENT ON COLUMN report.check_task_no IS '日检任务编号（日检流水号）';
COMMENT ON COLUMN report.user_no IS '用户编号';
COMMENT ON COLUMN report.version IS '报告版本号（整数 1/2/3…，同一日检流水号下区分历史版本；仅已完成（888）时赋予，失败/未完成可为空；展示时由前端拼 V 前缀）';
COMMENT ON COLUMN report.report_title IS '报告标题';
COMMENT ON COLUMN report.report_type IS '报告类型';
COMMENT ON COLUMN report.status IS '报告状态（111-待开始 000-进行中 888-已完成 999-失败）';
COMMENT ON COLUMN report.fail_reason IS '失败原因（生成过程发生技术类/业务类异常时记录详细信息，成功时为空）';
COMMENT ON COLUMN report.know_kit_task_id IS '关联Know-Kit任务ID';
COMMENT ON COLUMN report.content_html IS '报告HTML内容';
COMMENT ON COLUMN report.data_snapshot IS '数据快照JSON';
COMMENT ON COLUMN report.created_at IS '创建时间';
COMMENT ON COLUMN report.updated_at IS '更新时间';

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
COMMENT ON COLUMN rule_scenario.created_at IS '创建时间';
COMMENT ON COLUMN text_data.created_at IS '创建时间';
