-- =====================================================================
-- 信贷财务数据接口 · 数据落表 DDL（v1.2）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 设计约定：
--   1. 按接口嵌套层级拆分：1 张主表 + 1 张子表
--      （入参不单独建表，财报表 reportInfoArray 作为主表，入参字段并入主表）
--   2. 英文字段名 100% 照抄接口材料（驼峰/全大写保持），不做格式转换
--   3. 每张表公共字段：reportNo(报告编号)、customerId(客户编号)、mfCustomerId(核心客户编号)、
--      customerName(客户名称)、inputtime(入库时间)、reportTypeNo(报表类型)
--      （本接口无"日检申请流水号"字段，故不设 serialNo）
--   4. 子表 mainId 逐层指向直接上级表主键（不建物理外键）：
--      xd_financial_subject.mainId -> xd_financial_report.id
--   5. 类型映射：材料 [string] -> VARCHAR；inputtime -> TIMESTAMP
--   6. reportNo / customerId / mfCustomerId / customerName / reportTypeNo 列均建索引
--   7. 接口返回直接追加插入，不做去重约束
--
-- 语法适配（实测验证）：
--   - 建表语句内不写列注释/表注释/索引子句
--   - 注释用 COMMENT ON TABLE / COMMENT ON COLUMN 单独写
--   - 索引用 CREATE INDEX IF NOT EXISTS 单独建
--   - 主键：id BIGINT not null AUTO_INCREMENT + 表级 primary key (id)
-- =====================================================================

-- #####################################################################
-- 1. 财报信息主表（出参 reportInfoArray 财报数组 + 请求入参字段）
--    说明：材料 reportNo（财报编号）与公共字段 reportNo（报告编号）同名冲突，
--          （库列名不区分大小写）落表改名 finReportNo
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_financial_report (
    id                  BIGINT not null AUTO_INCREMENT,
    reportNo            VARCHAR(64) NOT NULL,
    customerId          VARCHAR(64),
    customerName        VARCHAR(128),
    mfCustomerId        VARCHAR(64),
    reportTypeNo        VARCHAR(64),
    certType            VARCHAR(64),
    certNo              VARCHAR(64),
    corpOrgId           VARCHAR(64),
    finReportNo         VARCHAR(64),
    accountMonth        VARCHAR(64),
    reportScope         VARCHAR(64),
    reportPeriod        VARCHAR(64),
    monetaryUnit        VARCHAR(64),
    currency            VARCHAR(64),
    auditFlag           VARCHAR(64),
    auditOpinion        VARCHAR(1000),
    auditingAgency      VARCHAR(128),
    reportStatus        VARCHAR(64),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_financial_report IS '信贷财务数据-财报信息主表（reportInfoArray+入参）';
COMMENT ON COLUMN xd_financial_report.id IS '主键';
COMMENT ON COLUMN xd_financial_report.reportNo IS '报告编号';
COMMENT ON COLUMN xd_financial_report.customerId IS '客户编号';
COMMENT ON COLUMN xd_financial_report.customerName IS '客户名称';
COMMENT ON COLUMN xd_financial_report.mfCustomerId IS '核心客户编号';
COMMENT ON COLUMN xd_financial_report.reportTypeNo IS '报表类型';
COMMENT ON COLUMN xd_financial_report.certType IS '证件类型';
COMMENT ON COLUMN xd_financial_report.certNo IS '证件号';
COMMENT ON COLUMN xd_financial_report.corpOrgId IS '法人机构号';
COMMENT ON COLUMN xd_financial_report.finReportNo IS '财报编号';
COMMENT ON COLUMN xd_financial_report.accountMonth IS '会计月';
COMMENT ON COLUMN xd_financial_report.reportScope IS '财报口径(1合并,2本部，3汇总)';
COMMENT ON COLUMN xd_financial_report.reportPeriod IS '报表周期';
COMMENT ON COLUMN xd_financial_report.monetaryUnit IS '货币单位（1元，1000千，10000万，100000十万，1000000百万，10000000千万，100000000亿）';
COMMENT ON COLUMN xd_financial_report.currency IS '币种(CNY人民币元,EUR欧元,GBP英镑,HKD香港元,JPY日元,MOP澳门元,RUB俄罗斯卢布,USD美元,AUD澳大利亚元)';
COMMENT ON COLUMN xd_financial_report.auditFlag IS '审计标志';
COMMENT ON COLUMN xd_financial_report.auditOpinion IS '审计意见';
COMMENT ON COLUMN xd_financial_report.auditingAgency IS '审计机构';
COMMENT ON COLUMN xd_financial_report.reportStatus IS '报表状态(Open录入,Finished完成,TmpLocked临时锁定,Locked锁定,OcrPreConfirm OCR待确认,OcrPreEdit OCR待修改)';
COMMENT ON COLUMN xd_financial_report.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_financial_report (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_financial_report (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_financial_report (customerName);
CREATE INDEX IF NOT EXISTS idx_mfCustomerId ON xd_financial_report (mfCustomerId);
CREATE INDEX IF NOT EXISTS idx_reportTypeNo ON xd_financial_report (reportTypeNo);

-- #####################################################################
-- 2. 财报科目表（出参 subjectNoArr 财报科目数组，挂在财报下）
--    mainId -> xd_financial_report.id（财报表）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_financial_subject (
    id              BIGINT not null AUTO_INCREMENT,
    mainId          BIGINT NOT NULL,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    customerName    VARCHAR(128),
    mfCustomerId    VARCHAR(64),
    reportTypeNo    VARCHAR(64),
    sheetNo         VARCHAR(64),
    subjectNo       VARCHAR(64),
    subjectName     VARCHAR(128),
    value1          VARCHAR(64),
    value2          VARCHAR(64),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_financial_subject IS '信贷财务数据-财报科目表（subjectNoArr）';
COMMENT ON COLUMN xd_financial_subject.id IS '主键';
COMMENT ON COLUMN xd_financial_subject.mainId IS '关联财报表主键id（xd_financial_report.id）';
COMMENT ON COLUMN xd_financial_subject.reportNo IS '报告编号';
COMMENT ON COLUMN xd_financial_subject.customerId IS '客户编号';
COMMENT ON COLUMN xd_financial_subject.customerName IS '客户名称';
COMMENT ON COLUMN xd_financial_subject.mfCustomerId IS '核心客户编号';
COMMENT ON COLUMN xd_financial_subject.reportTypeNo IS '报表类型';
COMMENT ON COLUMN xd_financial_subject.sheetNo IS '科目所在财报类型';
COMMENT ON COLUMN xd_financial_subject.subjectNo IS '科目号';
COMMENT ON COLUMN xd_financial_subject.subjectName IS '科目名称';
COMMENT ON COLUMN xd_financial_subject.value1 IS '期初值';
COMMENT ON COLUMN xd_financial_subject.value2 IS '期末值';
COMMENT ON COLUMN xd_financial_subject.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_financial_subject (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_financial_subject (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_financial_subject (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_financial_subject (customerName);
CREATE INDEX IF NOT EXISTS idx_mfCustomerId ON xd_financial_subject (mfCustomerId);
CREATE INDEX IF NOT EXISTS idx_reportTypeNo ON xd_financial_subject (reportTypeNo);
