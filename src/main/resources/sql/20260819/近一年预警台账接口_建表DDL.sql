-- =====================================================================
-- 近一年预警台账接口 · 数据落表 DDL（v1.1）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 设计约定：
--   1. 接口仅含 1 个数组（预警信号台账数组），无嵌套结构，
--      采用单表落库，一行 = 一条预警信号
--   2. 英文字段名 100% 照抄接口材料（驼峰/全大写保持），不做格式转换
--   3. 公共字段：reportNo(报告编号)、customerId(信贷客户编号)、
--      inputtime(入库时间)
--      （本接口入参无客户名称字段，故不设 customerName）
--   4. 类型映射：材料 String -> VARCHAR；inputtime -> TIMESTAMP
--   5. reportNo / customerId 列均建索引
--   6. 接口返回直接追加插入，不做去重约束
--
-- 语法适配（实测验证）：
--   - 建表语句内不写列注释/表注释/索引子句
--   - 注释用 COMMENT ON TABLE / COMMENT ON COLUMN 单独写
--   - 索引用 CREATE INDEX IF NOT EXISTS 单独建
--   - 主键：id BIGINT not null AUTO_INCREMENT + 表级 primary key (id)
-- =====================================================================

-- #####################################################################
-- 1. 近一年预警台账表（预警信号台账数组）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_warning_ledger (
    id              BIGINT not null AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    serialNo        VARCHAR(64),
    riskMessage     VARCHAR(1000),
    status          VARCHAR(64),
    warningLevel    VARCHAR(64),
    inputDate       VARCHAR(64),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_warning_ledger IS '近一年预警台账表（预警信号台账数组）';
COMMENT ON COLUMN xd_warning_ledger.id IS '主键';
COMMENT ON COLUMN xd_warning_ledger.reportNo IS '报告编号';
COMMENT ON COLUMN xd_warning_ledger.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_warning_ledger.serialNo IS '预警编号';
COMMENT ON COLUMN xd_warning_ledger.riskMessage IS '风险原因';
COMMENT ON COLUMN xd_warning_ledger.status IS '信号状态(00 无预警|01 待认定|02 已认定|03 已调整|04 已解除)';
COMMENT ON COLUMN xd_warning_ledger.warningLevel IS '风险等级(1 无风险|2 风险排查|3 黄色预警|4 风险关注|5 橙色预警|6 红色预警)';
COMMENT ON COLUMN xd_warning_ledger.inputDate IS '信号建立时间';
COMMENT ON COLUMN xd_warning_ledger.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_warning_ledger (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_warning_ledger (customerId);
