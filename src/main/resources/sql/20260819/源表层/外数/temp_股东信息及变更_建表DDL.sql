-- =====================================================================
-- 股东信息 / 股东信息-变更 · 数据落表 DDL（v1.2）
-- 数据来源：temp.xlsx（A列数据类别 = 股东信息 | 股东信息-变更）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 设计约定：
--   1. 按 A 列数据类别拆 2 张表：股东信息表 + 股东信息-变更表
--   2. 英文字段名 100% 照抄材料 J 列（下划线小写风格，如 stock_num、is_quoted、before_percent），不做格式转换
--   3. 中文注释按材料 C 列（材料笔误已修正："变更后持股比例是"修正为"变更后持股比例"）
--   4. 每张表公共字段：reportNo(报告编号)、customerId(信贷客户编号)、
--      customerName(客户名称)、inputtime(入库时间)
--   5. 字段类型统一 VARCHAR（材料未给类型列，按用户要求全部 VARCHAR）
--   6. reportNo / customerId / customerName 列均建索引
--   7. 接口返回直接追加插入，不做去重约束
--
-- 字段处理说明：
--   - 股东信息表"是否国有企业"（C列）材料 J 列无英文字段名，按材料下划线风格自拟 is_state_owned
--
-- 语法适配（实测验证）：
--   - 建表语句内不写列注释/表注释/索引子句
--   - 注释用 COMMENT ON TABLE / COMMENT ON COLUMN 单独写
--   - 索引用 CREATE INDEX IF NOT EXISTS 单独建
--   - 主键：id BIGINT not null AUTO_INCREMENT + 表级 primary key (id)
-- =====================================================================

-- #####################################################################
-- 1. 股东信息表（A列=股东信息）
-- #####################################################################
CREATE TABLE IF NOT EXISTS ws_shareholder_info (
    id              BIGINT not null AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    customerName    VARCHAR(128),
    name            VARCHAR(128),
    stock_num       VARCHAR(64),
    amount          VARCHAR(64),
    stock_percent   VARCHAR(64),
    is_quoted       VARCHAR(64),
    is_state_owned  VARCHAR(64),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE ws_shareholder_info IS '外数-股东信息表';
COMMENT ON COLUMN ws_shareholder_info.id IS '主键';
COMMENT ON COLUMN ws_shareholder_info.reportNo IS '报告编号';
COMMENT ON COLUMN ws_shareholder_info.customerId IS '信贷客户编号';
COMMENT ON COLUMN ws_shareholder_info.customerName IS '客户名称';
COMMENT ON COLUMN ws_shareholder_info.name IS '股东名称';
COMMENT ON COLUMN ws_shareholder_info.stock_num IS '股东持股数';
COMMENT ON COLUMN ws_shareholder_info.amount IS '股东出资金额';
COMMENT ON COLUMN ws_shareholder_info.stock_percent IS '股东出资比例';
COMMENT ON COLUMN ws_shareholder_info.is_quoted IS '是否上市';
COMMENT ON COLUMN ws_shareholder_info.is_state_owned IS '是否国有企业';
COMMENT ON COLUMN ws_shareholder_info.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_reportNo ON ws_shareholder_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON ws_shareholder_info (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON ws_shareholder_info (customerName);

-- #####################################################################
-- 2. 股东信息-变更表（A列=股东信息-变更）
-- #####################################################################
CREATE TABLE IF NOT EXISTS ws_shareholder_change (
    id              BIGINT not null AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    customerName    VARCHAR(128),
    name            VARCHAR(128),
    change_date     VARCHAR(64),
    before_percent  VARCHAR(64),
    after_percent   VARCHAR(64),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE ws_shareholder_change IS '外数-股东信息-变更表';
COMMENT ON COLUMN ws_shareholder_change.id IS '主键';
COMMENT ON COLUMN ws_shareholder_change.reportNo IS '报告编号';
COMMENT ON COLUMN ws_shareholder_change.customerId IS '信贷客户编号';
COMMENT ON COLUMN ws_shareholder_change.customerName IS '客户名称';
COMMENT ON COLUMN ws_shareholder_change.name IS '股东名称';
COMMENT ON COLUMN ws_shareholder_change.change_date IS '股权变更时间';
COMMENT ON COLUMN ws_shareholder_change.before_percent IS '变更前持股比例';
COMMENT ON COLUMN ws_shareholder_change.after_percent IS '变更后持股比例';
COMMENT ON COLUMN ws_shareholder_change.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_reportNo ON ws_shareholder_change (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON ws_shareholder_change (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON ws_shareholder_change (customerName);
