-- =============================================
-- GaussDB (MySQL兼容版) 业务表建表脚本
-- 数据类型适配：
--   DATETIME → TIMESTAMP
--   TINYINT(1) → SMALLINT
--   MEDIUMTEXT → TEXT
--   ON UPDATE CURRENT_TIMESTAMP → 触发器实现
-- =============================================

-- 客户表
CREATE TABLE IF NOT EXISTS customer (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    company_name VARCHAR(200) NOT NULL,
    credit_code VARCHAR(50),
    legal_person VARCHAR(50),
    actual_controller VARCHAR(50),
    registered_capital VARCHAR(50),
    paid_capital VARCHAR(50),
    establish_date DATE,
    industry VARCHAR(100),
    biz_scope TEXT,
    register_address VARCHAR(300),
    holding_type VARCHAR(30),
    shareholder VARCHAR(500),
    group_name VARCHAR(200),
    customer_type VARCHAR(30),
    first_loan_date DATE,
    last_approval_date DATE,
    main_bank VARCHAR(200),
    settlement_bank VARCHAR(200),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_company_name ON customer (company_name);

-- 采集配置表
CREATE TABLE IF NOT EXISTS collector_config (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    config_name VARCHAR(100) NOT NULL,
    collector_type VARCHAR(30) NOT NULL,
    config_json TEXT NOT NULL,
    cron_expression VARCHAR(50),
    enabled SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_collector_type ON collector_config (collector_type);

-- 解析配置表
CREATE TABLE IF NOT EXISTS parser_config (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    collector_id BIGINT NOT NULL,
    parser_type VARCHAR(30) NOT NULL,
    config_json TEXT NOT NULL,
    domain VARCHAR(30) NOT NULL,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_collector ON parser_config (collector_id);

-- 原始数据日志
CREATE TABLE IF NOT EXISTS raw_data_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    collector_id BIGINT,
    raw_content TEXT,
    content_type VARCHAR(50),
    file_path VARCHAR(500),
    collect_time TIMESTAMP NOT NULL,
    customer_id BIGINT,
    success SMALLINT DEFAULT 1,
    error_msg TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_raw_customer ON raw_data_log (customer_id);
CREATE INDEX IF NOT EXISTS idx_raw_collect_time ON raw_data_log (collect_time);

-- 指标数据表
CREATE TABLE IF NOT EXISTS indicator_data (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id BIGINT NOT NULL,
    indicator_key VARCHAR(100) NOT NULL,
    indicator_name VARCHAR(200) NOT NULL,
    current_value VARCHAR(100),
    previous_value VARCHAR(100),
    change_desc VARCHAR(100),
    data_unit VARCHAR(50),
    domain VARCHAR(30) NOT NULL,
    period VARCHAR(30),
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_indicator_customer_domain ON indicator_data (customer_id, domain);
CREATE INDEX IF NOT EXISTS idx_indicator_customer_key ON indicator_data (customer_id, indicator_key);

-- 文本数据表
CREATE TABLE IF NOT EXISTS text_data (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id BIGINT NOT NULL,
    text_type VARCHAR(50) NOT NULL,
    domain VARCHAR(30) NOT NULL,
    title VARCHAR(300),
    content TEXT NOT NULL,
    period VARCHAR(30),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_text_customer_domain ON text_data (customer_id, domain);

-- 授信记录表
CREATE TABLE IF NOT EXISTS credit_record (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id BIGINT NOT NULL,
    contract_no VARCHAR(100),
    loan_type VARCHAR(30),
    currency VARCHAR(10),
    loan_amount VARCHAR(50),
    loan_balance VARCHAR(50),
    start_date DATE,
    end_date DATE,
    loan_purpose VARCHAR(200),
    guarantee_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_credit_customer ON credit_record (customer_id);

-- 知识规则表
CREATE TABLE IF NOT EXISTS knowledge_rule (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    rule_code VARCHAR(50) NOT NULL,
    rule_name VARCHAR(200) NOT NULL,
    rule_type VARCHAR(30) NOT NULL,
    description TEXT,
    enabled SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_knowledge_rule_code ON knowledge_rule (rule_code);

-- 规则条件表
CREATE TABLE IF NOT EXISTS rule_condition (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    rule_id BIGINT NOT NULL,
    indicator_key VARCHAR(100) NOT NULL,
    operator VARCHAR(20) NOT NULL,
    threshold VARCHAR(50),
    logic_order INT DEFAULT 1,
    logic_connector VARCHAR(5) DEFAULT 'AND'
);
CREATE INDEX IF NOT EXISTS idx_rule_condition_rule ON rule_condition (rule_id);

-- 规则标签表
CREATE TABLE IF NOT EXISTS rule_tag (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    rule_id BIGINT NOT NULL,
    tag_type VARCHAR(30) NOT NULL,
    tag_value VARCHAR(100) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_rule_tag_type_value ON rule_tag (tag_type, tag_value);
CREATE INDEX IF NOT EXISTS idx_rule_tag_rule ON rule_tag (rule_id);

-- 规则场景表
CREATE TABLE IF NOT EXISTS rule_scenario (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    scenario_code VARCHAR(50) NOT NULL,
    scenario_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_scenario_code ON rule_scenario (scenario_code);

-- KnowKit 任务表
CREATE TABLE IF NOT EXISTS know_kit_task (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id BIGINT NOT NULL,
    scenario_tags VARCHAR(500),
    request_json TEXT,
    response_json TEXT,
    status VARCHAR(20) DEFAULT 'PENDING',
    error_msg TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_kit_customer ON know_kit_task (customer_id);
CREATE INDEX IF NOT EXISTS idx_kit_status ON know_kit_task (status);

-- 报告表
CREATE TABLE IF NOT EXISTS report (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id BIGINT NOT NULL,
    report_title VARCHAR(300) NOT NULL,
    report_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'DRAFT',
    know_kit_task_id BIGINT,
    content_html TEXT,
    data_snapshot TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_report_customer ON report (customer_id);
CREATE INDEX IF NOT EXISTS idx_report_type ON report (report_type);
