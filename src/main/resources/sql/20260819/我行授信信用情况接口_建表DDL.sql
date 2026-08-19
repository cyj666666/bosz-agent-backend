-- =====================================================================
-- 我行授信信用情况接口 · 数据落表 DDL（v1.1）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 设计约定：
--   1. 按接口嵌套层级拆分：1 张主表 + 2 张子表
--      - 主表 = 授信汇总基础字段 + 固贷产品对象 + 房地产开发贷款产品对象（均单条对象，并入主表）
--      - 子表1 = 借据信息数组（mainId -> 主表）
--      - 子表2 = 受托支付数组（mainId -> 借据表，二级嵌套）
--   2. 英文字段名 100% 照抄接口材料（驼峰/全大写保持），不做格式转换
--   3. 每张表公共字段：reportNo(报告编号)、customerId(信贷客户编号)、
--      customerName(客户名称)、inputtime(入库时间)
--   4. 子表 mainId 逐层指向直接上级表主键（不建物理外键）
--   5. 类型映射：材料 String -> VARCHAR；Number -> DECIMAL(18,2)；Integer -> INT；inputtime -> TIMESTAMP
--      （材料 creditDate 类型未定义，按 VARCHAR 处理）
--   6. reportNo / customerId / customerName 列均建索引
--   7. 接口返回直接追加插入，不做去重约束
--
-- 字段冲突处理（两个单条产品对象并入主表，字段同名，加前缀区分）：
--   - 固贷产品对象：nextPayDate等 5 字段 -> gdNextPayDate / gdPayPrinciPalamt / gdPayInterestamt / gdPayFineAmt / gdCompoundInterest
--   - 房地产开发贷款产品对象：nextPayDate等 5 字段 -> fdNextPayDate / fdPayPrinciPalamt / fdPayInterestamt / fdPayFineAmt / fdCompoundInterest
--
-- 语法适配（实测验证）：
--   - 建表语句内不写列注释/表注释/索引子句
--   - 注释用 COMMENT ON TABLE / COMMENT ON COLUMN 单独写
--   - 索引用 CREATE INDEX IF NOT EXISTS 单独建
--   - 主键：id BIGINT not null AUTO_INCREMENT + 表级 primary key (id)
-- =====================================================================

-- #####################################################################
-- 1. 授信信用情况主表（授信汇总 + 固贷/房开贷产品对象 + 入参并入）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_credit_info (
    id                  BIGINT not null AUTO_INCREMENT,
    reportNo            VARCHAR(64) NOT NULL,
    customerId          VARCHAR(64),
    customerName        VARCHAR(128),
    creditSum           DECIMAL(18,2),
    creditDate          VARCHAR(64),
    balance             DECIMAL(18,2),
    exposureAmount      DECIMAL(18,2),
    limitBalance        DECIMAL(18,2),
    groupAmount         DECIMAL(18,2),
    groupBalance        DECIMAL(18,2),
    latestOverdueDate   VARCHAR(64),
    gdOverdueCounts     VARCHAR(64),
    ajOverdueCounts     VARCHAR(64),
    gdNextPayDate       VARCHAR(64),
    gdPayPrinciPalamt   DECIMAL(18,2),
    gdPayInterestamt    DECIMAL(18,2),
    gdPayFineAmt        DECIMAL(18,2),
    gdCompoundInterest  DECIMAL(18,2),
    fdNextPayDate       VARCHAR(64),
    fdPayPrinciPalamt   DECIMAL(18,2),
    fdPayInterestamt    DECIMAL(18,2),
    fdPayFineAmt        DECIMAL(18,2),
    fdCompoundInterest  DECIMAL(18,2),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_credit_info IS '我行授信信用情况主表（授信汇总+固贷/房开贷对象）';
COMMENT ON COLUMN xd_credit_info.id IS '主键';
COMMENT ON COLUMN xd_credit_info.reportNo IS '报告编号';
COMMENT ON COLUMN xd_credit_info.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_credit_info.customerName IS '客户名称';
COMMENT ON COLUMN xd_credit_info.creditSum IS '授信金额';
COMMENT ON COLUMN xd_credit_info.creditDate IS '授信时点';
COMMENT ON COLUMN xd_credit_info.balance IS '总余额';
COMMENT ON COLUMN xd_credit_info.exposureAmount IS '敞口金额';
COMMENT ON COLUMN xd_credit_info.limitBalance IS '敞口余额';
COMMENT ON COLUMN xd_credit_info.groupAmount IS '集团授信金额';
COMMENT ON COLUMN xd_credit_info.groupBalance IS '集团总余额';
COMMENT ON COLUMN xd_credit_info.latestOverdueDate IS '企业当前最近一次逾期日期';
COMMENT ON COLUMN xd_credit_info.gdOverdueCounts IS '固贷产品近一年历史逾期次数';
COMMENT ON COLUMN xd_credit_info.ajOverdueCounts IS '按揭贷款产品近一年历史逾期次数';
COMMENT ON COLUMN xd_credit_info.gdNextPayDate IS '固贷产品-下次还款日';
COMMENT ON COLUMN xd_credit_info.gdPayPrinciPalamt IS '固贷产品-下次还款本金';
COMMENT ON COLUMN xd_credit_info.gdPayInterestamt IS '固贷产品-下次还款利息';
COMMENT ON COLUMN xd_credit_info.gdPayFineAmt IS '固贷产品-下次还款罚息';
COMMENT ON COLUMN xd_credit_info.gdCompoundInterest IS '固贷产品-下次还款复利';
COMMENT ON COLUMN xd_credit_info.fdNextPayDate IS '房地产开发贷款-下次还款日';
COMMENT ON COLUMN xd_credit_info.fdPayPrinciPalamt IS '房地产开发贷款-下次还款本金';
COMMENT ON COLUMN xd_credit_info.fdPayInterestamt IS '房地产开发贷款-下次还款利息';
COMMENT ON COLUMN xd_credit_info.fdPayFineAmt IS '房地产开发贷款-下次还款罚息';
COMMENT ON COLUMN xd_credit_info.fdCompoundInterest IS '房地产开发贷款-下次还款复利';
COMMENT ON COLUMN xd_credit_info.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_credit_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_credit_info (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_credit_info (customerName);

-- #####################################################################
-- 2. 借据信息表（借据信息数组）
--    mainId -> xd_credit_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_credit_loan (
    id                      BIGINT not null AUTO_INCREMENT,
    mainId                  BIGINT NOT NULL,
    reportNo                VARCHAR(64) NOT NULL,
    customerId              VARCHAR(64),
    customerName            VARCHAR(128),
    loanSerialNo            VARCHAR(64),
    loanStatus              VARCHAR(64),
    productName             VARCHAR(64),
    productBelongName       VARCHAR(64),
    balance                 DECIMAL(18,2),
    overdueBalance          DECIMAL(18,2),
    overdueInterestAmt      DECIMAL(18,2),
    purposeName             VARCHAR(64),
    loanChangeRptCounts     INT,
    loanChangeRptBalance    DECIMAL(18,2),
    isExtend                VARCHAR(64),
    extendBalance           DECIMAL(18,2),
    isRestructed            VARCHAR(64),
    restructedBalance       DECIMAL(18,2),
    occurType               VARCHAR(64),
    reorgTimes              INT,
    reorgBalance            DECIMAL(18,2),
    inputtime               TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_credit_loan IS '我行授信信用情况-借据信息表（借据信息数组）';
COMMENT ON COLUMN xd_credit_loan.id IS '主键';
COMMENT ON COLUMN xd_credit_loan.mainId IS '关联主表主键id（xd_credit_info.id）';
COMMENT ON COLUMN xd_credit_loan.reportNo IS '报告编号';
COMMENT ON COLUMN xd_credit_loan.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_credit_loan.customerName IS '客户名称';
COMMENT ON COLUMN xd_credit_loan.loanSerialNo IS '借据流水号';
COMMENT ON COLUMN xd_credit_loan.loanStatus IS '借据状态';
COMMENT ON COLUMN xd_credit_loan.productName IS '基础产品';
COMMENT ON COLUMN xd_credit_loan.productBelongName IS '产品归属';
COMMENT ON COLUMN xd_credit_loan.balance IS '借据余额';
COMMENT ON COLUMN xd_credit_loan.overdueBalance IS '期供欠本金额';
COMMENT ON COLUMN xd_credit_loan.overdueInterestAmt IS '期供欠息金额';
COMMENT ON COLUMN xd_credit_loan.purposeName IS '用途';
COMMENT ON COLUMN xd_credit_loan.loanChangeRptCounts IS '还款方式变更笔数';
COMMENT ON COLUMN xd_credit_loan.loanChangeRptBalance IS '还款方式变更贷款余额';
COMMENT ON COLUMN xd_credit_loan.isExtend IS '是否展期';
COMMENT ON COLUMN xd_credit_loan.extendBalance IS '展期贷款余额';
COMMENT ON COLUMN xd_credit_loan.isRestructed IS '是否重组优化贷款';
COMMENT ON COLUMN xd_credit_loan.restructedBalance IS '重组贷款余额';
COMMENT ON COLUMN xd_credit_loan.occurType IS '发生类型';
COMMENT ON COLUMN xd_credit_loan.reorgTimes IS '借新还旧次数';
COMMENT ON COLUMN xd_credit_loan.reorgBalance IS '借新还旧余额';
COMMENT ON COLUMN xd_credit_loan.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_credit_loan (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_credit_loan (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_credit_loan (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_credit_loan (customerName);

-- #####################################################################
-- 3. 受托支付表（受托支付数组，挂在借据下）
--    mainId -> xd_credit_loan.id（借据表）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_credit_payment (
    id              BIGINT not null AUTO_INCREMENT,
    mainId          BIGINT NOT NULL,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    customerName    VARCHAR(128),
    paymentMode     VARCHAR(64),
    paydate         VARCHAR(64),
    accountname     VARCHAR(128),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_credit_payment IS '我行授信信用情况-受托支付表（受托支付数组）';
COMMENT ON COLUMN xd_credit_payment.id IS '主键';
COMMENT ON COLUMN xd_credit_payment.mainId IS '关联借据表主键id（xd_credit_loan.id）';
COMMENT ON COLUMN xd_credit_payment.reportNo IS '报告编号';
COMMENT ON COLUMN xd_credit_payment.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_credit_payment.customerName IS '客户名称';
COMMENT ON COLUMN xd_credit_payment.paymentMode IS '支付方式(10 自主支付|20 受托支付|30 部分受托支付)';
COMMENT ON COLUMN xd_credit_payment.paydate IS '支付日期';
COMMENT ON COLUMN xd_credit_payment.accountname IS '收款人名称';
COMMENT ON COLUMN xd_credit_payment.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_credit_payment (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_credit_payment (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_credit_payment (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_credit_payment (customerName);
