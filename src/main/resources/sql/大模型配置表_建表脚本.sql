-- =============================================================================
-- 大模型配置表 large_model_config
-- =============================================================================
-- 说明：平台级配置表，供各业务模块按 lm_code 取用大模型网关的地址与密钥。
--       由用户提供原始 DDL，此处补充表注释与索引，字段口径保持不变。
-- 约定：不使用 IF NOT EXISTS（客户侧 init_db_gaussdb.sql 里才加）；
--       不使用反引号 / ENGINE / CHARSET；COMMENT ON 独立语句；索引名全库唯一。
-- =============================================================================

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

CREATE UNIQUE INDEX uk_large_model_config_lm_code ON large_model_config (lm_code);
CREATE INDEX idx_large_model_config_use_flag ON large_model_config (use_flag);

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
