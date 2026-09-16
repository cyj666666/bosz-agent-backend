-- =====================================================================
-- 苏州银行 对公客户日常定期检查（贷后）报告 数据表结构 V1.25
-- 版本日期：2026-09-11
-- 上一版本：V1.24（2026-09-11，app_gs_tax_sales_info 加 inputtime；app_gs_finance_data_info 的 financeReportType 改名 reportScope）
-- V1.25 变更：新建 app_graph_hit_info 企业图谱命中情况（14 字段：id + 4 公共 + 8 个"是/否"标志位，8 个字段名按"见名知意"推断；标志位类型 VARCHAR(8) DEFAULT NULL）
-- 数据库：高斯DB（GaussDB）
-- 设计依据：《数据映射细化V4.xlsx》
-- 共44张表（报告主表1 + 公共基础表13 + 模块明细表30）
-- V1.24 变更：
--   ① app_gs_tax_sales_info 增加 inputtime 字段（V1.23 时漏加，本版补齐）
--   ② app_gs_finance_data_info 的 financeReportType 改名为 reportScope（推断的 financeReportType 与现有 app_finance_index_info 等表命名风格不一致，改用 reportScope）
-- V1.23 变更：新建 2 张"国税数据"表（区别于 V1.15 已有的 app_guofa_report_info 国发征信），位置插在 app_guofa_report_info 之前：
--   ① app_gs_tax_sales_info 国税销售额表（9 字段，无 inputtime；物理 PK=id，业务 UNIQUE=(reportNo,customerId,taxPeriod)）
--   ② app_gs_finance_data_info 国税财务数据表（21 字段，含 inputtime + financeReportType 推断；与 guofa_report_info 对位，去 dataDate 加 financeReportType）
-- 数据库：高斯DB（GaussDB）
-- 设计依据：《数据映射细化V4.xlsx》
-- 共43张表（报告主表1 + 公共基础表13 + 模块明细表29）
-- V1.21 变更：app_credit_approval_manage_req_info.CONDITION 由 VARCHAR(1000) 扩为 TEXT（提前扩容，避免后续管理要求文本溢出）
-- V1.20 变更：新建 app_credit_approval_manage_req_info 授信批复管理要求表（9 字段：id/reportno/customerid/customername/inputtime/swqNo/CONDITION/PELATIVESERIALNO/checkDate；保留用户原拼写 swqNo / PELATIVESERIALNO / CONDITION；不擅自修正）
-- 数据库：高斯DB（GaussDB）
-- 设计依据：《数据映射细化V4.xlsx》
-- 共41张表（报告主表1 + 公共基础表13 + 模块明细表27）
-- 设计原则：公共+模块两层、一期一行、沿用J列字段名+驼峰；经验库规则所需源数据见正文模块表
-- 公共列：id / reportNo / customerId / customerName / inputtime
-- =====================================================================

-- ============================================================
-- 一、报告层（1张）
-- ============================================================

-- 报告主表：一次贷后报告一条记录，所有明细表的入口

CREATE TABLE IF NOT EXISTS app_report_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    reportTitle            VARCHAR(128),
    checkTaskNo            VARCHAR(64),
    reportDate             VARCHAR(32),
    reportStatus           VARCHAR(32),
    generatorName          VARCHAR(64),
    generateTime           TIMESTAMP,
    approveStatus          VARCHAR(32),
    approveOpinion         TEXT,
    approveTime            TIMESTAMP,
    reportUrl              VARCHAR(256),
    failReason             VARCHAR(2000),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_report_info IS '贷后报告主表';
COMMENT ON COLUMN app_report_info.reportNo IS '报告编号（一次贷后报告的记录号）';
COMMENT ON COLUMN app_report_info.customerId IS '客户编号';
COMMENT ON COLUMN app_report_info.customerName IS '客户名称';
COMMENT ON COLUMN app_report_info.reportTitle IS '报告标题';
COMMENT ON COLUMN app_report_info.checkTaskNo IS '日检任务编号';
COMMENT ON COLUMN app_report_info.reportDate IS '报告日期（贷后检查日）';
COMMENT ON COLUMN app_report_info.reportStatus IS '报告状态（码值：111-待开始 000-进行中 888-已完成 999-失败）';
COMMENT ON COLUMN app_report_info.generatorName IS '生成人';
COMMENT ON COLUMN app_report_info.generateTime IS '生成时间';
COMMENT ON COLUMN app_report_info.approveStatus IS '审批状态（码值：待审批/审批通过/审批驳回（码值待确认））';
COMMENT ON COLUMN app_report_info.approveOpinion IS '审批意见';
COMMENT ON COLUMN app_report_info.approveTime IS '审批时间';
COMMENT ON COLUMN app_report_info.reportUrl IS '报告链接';
COMMENT ON COLUMN app_report_info.failReason IS '失败原因（生成过程发生技术类/业务类异常时记录详细信息，成功时为空）';
COMMENT ON COLUMN app_report_info.inputtime IS '入库时间';
CREATE UNIQUE INDEX IF NOT EXISTS uk_report_no ON app_report_info (reportNo);

CREATE TABLE IF NOT EXISTS app_customer_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    legalPerson            VARCHAR(128),
    registerCapital        DECIMAL(18,2),
    paidInCapital          DECIMAL(18,2),
    industryType           VARCHAR(64),
    holdType               VARCHAR(64),
    actualController       VARCHAR(128),
    officeAddress          VARCHAR(256),
    businessScope          TEXT,
    dangerLevel            VARCHAR(64),
    warningLevel           VARCHAR(64),
    isStateOwned           VARCHAR(64),
    isListedCompany        VARCHAR(32),
    groupName              VARCHAR(128),
    isTechCompany          VARCHAR(64),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_customer_info IS '客户工商概况表';
COMMENT ON COLUMN app_customer_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_customer_info.customerId IS '客户编号';
COMMENT ON COLUMN app_customer_info.customerName IS '客户名称';
COMMENT ON COLUMN app_customer_info.legalPerson IS '法定代表人';
COMMENT ON COLUMN app_customer_info.registerCapital IS '注册资本（万元）';
COMMENT ON COLUMN app_customer_info.paidInCapital IS '实收资本（万元）';
COMMENT ON COLUMN app_customer_info.industryType IS '行业分类（码值：GB/T 4754 行业代码，码值待确认）';
COMMENT ON COLUMN app_customer_info.holdType IS '控股类型（码值：国有绝对控股/国有相对控股/集体绝对控股/集体相对控股/民营/个人绝对控股，码值待确认）';
COMMENT ON COLUMN app_customer_info.actualController IS '实际控制人';
COMMENT ON COLUMN app_customer_info.officeAddress IS '办公地址';
COMMENT ON COLUMN app_customer_info.businessScope IS '经营范围';
COMMENT ON COLUMN app_customer_info.dangerLevel IS '十级分类（码值：银行十级分类（1-4正常/5-6关注/7-8次级可疑/9-10损失，具体码值待确认））';
COMMENT ON COLUMN app_customer_info.warningLevel IS '预警等级（码值：高/中/低/黄色预警，码值待确认）';
COMMENT ON COLUMN app_customer_info.isStateOwned IS '是否国资/国有担保（码值：是/否（由控股类型holdType判断））';
COMMENT ON COLUMN app_customer_info.isListedCompany IS '借款人是否上市公司（码值：是/否，中台接口）';
COMMENT ON COLUMN app_customer_info.groupName IS '所属集团名称';
COMMENT ON COLUMN app_customer_info.isTechCompany IS '是否科创企业（码值：是/否）';
COMMENT ON COLUMN app_customer_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_customer_info_reportNo ON app_customer_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_customer_info_customerId ON app_customer_info (customerId);

CREATE TABLE IF NOT EXISTS app_ic_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    icLegalPerson          VARCHAR(128),
    icRegisterCapital      DECIMAL(18,2),
    icPaidInCapital        DECIMAL(18,2),
    icBeneficiaryName      VARCHAR(128),
    icBeneficiaryPercent   DECIMAL(12,4),
    isStateOwned           VARCHAR(64),
    isFakeStateOwned       VARCHAR(64),
    cancellationDate       VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_ic_info IS '工商登记信息表（客户级）';
COMMENT ON COLUMN app_ic_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_ic_info.customerId IS '客户编号';
COMMENT ON COLUMN app_ic_info.customerName IS '客户名称';
COMMENT ON COLUMN app_ic_info.icLegalPerson IS '工商法定代表人';
COMMENT ON COLUMN app_ic_info.icRegisterCapital IS '工商注册资本（万元）';
COMMENT ON COLUMN app_ic_info.icPaidInCapital IS '工商实缴资本（万元）';
COMMENT ON COLUMN app_ic_info.icBeneficiaryName IS '工商受益人名称';
COMMENT ON COLUMN app_ic_info.icBeneficiaryPercent IS '工商受益人持股比例（%）';
COMMENT ON COLUMN app_ic_info.isStateOwned IS '是否国有企业（工商口径）（码值：是/否（工商口径））';
COMMENT ON COLUMN app_ic_info.isFakeStateOwned IS '是否假冒国企（工商口径）（码值：是/否（工商口径））';
COMMENT ON COLUMN app_ic_info.cancellationDate IS '注销日期';
COMMENT ON COLUMN app_ic_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_ic_info_reportNo ON app_ic_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_ic_info_customerId ON app_ic_info (customerId);

CREATE TABLE IF NOT EXISTS app_ic_shareholder_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    snapshot_type          VARCHAR(32),
    icShareholderName      VARCHAR(128),
    icStockNum             INT,
    icStockPercent         DECIMAL(12,4),
    icAmount               DECIMAL(18,2),
    changeTime             VARCHAR(32),
    percentBefore          DECIMAL(12,4),
    percentAfter           DECIMAL(12,4),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_ic_shareholder_info IS '工商股东变更表（股权变更历史：变更时间/变更前后比例，多时点快照）';
COMMENT ON COLUMN app_ic_shareholder_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_ic_shareholder_info.customerId IS '客户编号';
COMMENT ON COLUMN app_ic_shareholder_info.customerName IS '客户名称';
COMMENT ON COLUMN app_ic_shareholder_info.snapshot_type IS '快照类型（latest最新/atCredit授信时）';
COMMENT ON COLUMN app_ic_shareholder_info.icShareholderName IS '工商股东名称';
COMMENT ON COLUMN app_ic_shareholder_info.icStockNum IS '工商股东持股数';
COMMENT ON COLUMN app_ic_shareholder_info.icStockPercent IS '工商股东持股比例（%）';
COMMENT ON COLUMN app_ic_shareholder_info.icAmount IS '工商股东出资金额（万元）';
COMMENT ON COLUMN app_ic_shareholder_info.changeTime IS '股权变更时间（授信时点后的变更）';
COMMENT ON COLUMN app_ic_shareholder_info.percentBefore IS '变更前持股比例（%）';
COMMENT ON COLUMN app_ic_shareholder_info.percentAfter IS '变更后持股比例（%）';
COMMENT ON COLUMN app_ic_shareholder_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_ic_shareholder_info_reportNo ON app_ic_shareholder_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_ic_shareholder_info_customerId ON app_ic_shareholder_info (customerId);

CREATE TABLE IF NOT EXISTS app_shareholder_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    name                   VARCHAR(128),
    stock_num              INT,
    amount                 DECIMAL(18,2),
    stock_percent          DECIMAL(12,4),
    is_quoted              VARCHAR(32),
    is_state_owned         VARCHAR(64),
    is_fake_state_owned    VARCHAR(32),
    is_listed_company      VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_shareholder_info IS '工商股东信息表（最新时点快照，字段详细；与信贷系统股东 app_xd_shareholder_info 口径对比）';
COMMENT ON COLUMN app_shareholder_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_shareholder_info.customerId IS '客户编号';
COMMENT ON COLUMN app_shareholder_info.customerName IS '客户名称';
COMMENT ON COLUMN app_shareholder_info.name IS '股东名称';
COMMENT ON COLUMN app_shareholder_info.stock_num IS '持股数';
COMMENT ON COLUMN app_shareholder_info.amount IS '应出资金额（万元）';
COMMENT ON COLUMN app_shareholder_info.stock_percent IS '持股比例（%）';
COMMENT ON COLUMN app_shareholder_info.is_quoted IS '是否已出资（码值：是/否）';
COMMENT ON COLUMN app_shareholder_info.is_state_owned IS '是否国资股东（码值：是/否）';
COMMENT ON COLUMN app_shareholder_info.is_fake_state_owned IS '股东假冒国企标签（码值：是/否；苏企查/中台按股东主体查询，仅企业股东有值，自然人股东为空）';
COMMENT ON COLUMN app_shareholder_info.is_listed_company IS '股东是否上市公司（码值：是/否，中台按股东主体查询）';
COMMENT ON COLUMN app_shareholder_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_shareholder_info_reportNo ON app_shareholder_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_shareholder_info_customerId ON app_shareholder_info (customerId);

CREATE TABLE IF NOT EXISTS app_xd_shareholder_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    name                   VARCHAR(128),
    investmentProp         DECIMAL(12,4),
    relationShip           VARCHAR(128),
    currencyType           VARCHAR(64),
    oughtSum               DECIMAL(18,2),
    investmentSum          DECIMAL(18,2),
    investDate             VARCHAR(64),
    inputUserId            VARCHAR(64),
    inputOrgId             VARCHAR(64),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_xd_shareholder_info IS '信贷系统股东表（最新时点）';
COMMENT ON COLUMN app_xd_shareholder_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_xd_shareholder_info.customerId IS '客户编号';
COMMENT ON COLUMN app_xd_shareholder_info.customerName IS '客户名称';
COMMENT ON COLUMN app_xd_shareholder_info.name IS '股东名称';
COMMENT ON COLUMN app_xd_shareholder_info.investmentProp IS '持股比例（%）';
COMMENT ON COLUMN app_xd_shareholder_info.relationShip IS '出资方式';
COMMENT ON COLUMN app_xd_shareholder_info.currencyType IS '币种';
COMMENT ON COLUMN app_xd_shareholder_info.oughtSum IS '应出资金额（万元）';
COMMENT ON COLUMN app_xd_shareholder_info.investmentSum IS '实际投资金额（万元）';
COMMENT ON COLUMN app_xd_shareholder_info.investDate IS '投资时间';
COMMENT ON COLUMN app_xd_shareholder_info.inputUserId IS '登记人';
COMMENT ON COLUMN app_xd_shareholder_info.inputOrgId IS '登记机构';
COMMENT ON COLUMN app_xd_shareholder_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_xd_shareholder_info_reportNo ON app_xd_shareholder_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_xd_shareholder_info_customerId ON app_xd_shareholder_info (customerId);

CREATE TABLE IF NOT EXISTS app_credit_use_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    creditSum              DECIMAL(18,2),
    balance                DECIMAL(18,2),
    exposureAmount         DECIMAL(18,2),
    limitBalance           DECIMAL(18,2),
    groupAmount            DECIMAL(18,2),
    groupBalance           DECIMAL(18,2),
    isGroup                VARCHAR(32),
    groupName              VARCHAR(128),
    creditDate             VARCHAR(32),
    latestOverdueDate      VARCHAR(32),
    gdOverdueCounts        INT,
    ajOverdueCounts        INT,
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_credit_use_info IS '授信用信概况表';
COMMENT ON COLUMN app_credit_use_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_credit_use_info.customerId IS '客户编号';
COMMENT ON COLUMN app_credit_use_info.customerName IS '客户名称';
COMMENT ON COLUMN app_credit_use_info.creditSum IS '授信金额（万元）';
COMMENT ON COLUMN app_credit_use_info.balance IS '总余额（万元）';
COMMENT ON COLUMN app_credit_use_info.exposureAmount IS '敞口金额（万元）';
COMMENT ON COLUMN app_credit_use_info.limitBalance IS '敞口余额（万元）';
COMMENT ON COLUMN app_credit_use_info.groupAmount IS '集团授信金额（万元）';
COMMENT ON COLUMN app_credit_use_info.groupBalance IS '集团总余额（万元）';
COMMENT ON COLUMN app_credit_use_info.isGroup IS '是否集团客户（码值：是/否）';
COMMENT ON COLUMN app_credit_use_info.groupName IS '所属集团名称';
COMMENT ON COLUMN app_credit_use_info.creditDate IS '授信日期（授信时点，用于反查报表期）';
COMMENT ON COLUMN app_credit_use_info.latestOverdueDate IS '企业当前最近一次逾期日期';
COMMENT ON COLUMN app_credit_use_info.gdOverdueCounts IS '固贷产品近一年历史逾期次数';
COMMENT ON COLUMN app_credit_use_info.ajOverdueCounts IS '按揭贷款产品近一年历史逾期次数（房开贷暂取此值，待确认）';
COMMENT ON COLUMN app_credit_use_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_credit_use_info_reportNo ON app_credit_use_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_credit_use_info_customerId ON app_credit_use_info (customerId);

CREATE TABLE IF NOT EXISTS app_loan_receipt_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    loanSerialNo           VARCHAR(64),
    loanStatus             VARCHAR(64),
    productName            VARCHAR(128),
    productType            VARCHAR(64),
    purposeName            VARCHAR(128),
    balance                DECIMAL(18,2),
    productBelongName      VARCHAR(128),
    overdueBalance         DECIMAL(18,2),
    overdueInterestAmt     DECIMAL(18,2),
    isRestructed           VARCHAR(32),
    extendBalance          DECIMAL(18,2),
    restructedBalance      DECIMAL(18,2),
    reorgTimes             INT,
    reorgBalance           DECIMAL(18,2),
    loanChangeRptCounts    INT,
    loanChangeRptBalance   DECIMAL(18,2),
    occurType              VARCHAR(32),
    isExtend               VARCHAR(32),
    fixedAssetLoan         VARCHAR(32),
    realEstateDevLoan      VARCHAR(32),
    nextPayDate            VARCHAR(32),
    payPrinciPalamt        DECIMAL(18,2),
    payInterestamt         DECIMAL(18,2),
    payFineAmt             DECIMAL(18,2),
    compoundinterest       DECIMAL(18,2),
    businessRate           DECIMAL(12,4),
    RepaymentPeriod        VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_loan_receipt_info IS '借据信息表';
COMMENT ON COLUMN app_loan_receipt_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_loan_receipt_info.customerId IS '客户编号';
COMMENT ON COLUMN app_loan_receipt_info.customerName IS '客户名称';
COMMENT ON COLUMN app_loan_receipt_info.loanSerialNo IS '借据号';
COMMENT ON COLUMN app_loan_receipt_info.loanStatus IS '借据状态（码值：正常/逾期/欠息/结清/呆账（码值待确认））';
COMMENT ON COLUMN app_loan_receipt_info.productName IS '基础产品名称';
COMMENT ON COLUMN app_loan_receipt_info.productType IS '产品类型（基础/组合/固贷/房地产）';
COMMENT ON COLUMN app_loan_receipt_info.purposeName IS '用途';
COMMENT ON COLUMN app_loan_receipt_info.balance IS '借据余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.productBelongName IS '产品归属（组合产品）';
COMMENT ON COLUMN app_loan_receipt_info.overdueBalance IS '期供欠本金额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.overdueInterestAmt IS '期供欠息金额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.isRestructed IS '是否重组优化贷款（码值：是/否）';
COMMENT ON COLUMN app_loan_receipt_info.extendBalance IS '展期贷款余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.restructedBalance IS '重组贷款余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.reorgTimes IS '借新还旧次数';
COMMENT ON COLUMN app_loan_receipt_info.reorgBalance IS '借新还旧余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.loanChangeRptCounts IS '还款方式变更笔数';
COMMENT ON COLUMN app_loan_receipt_info.loanChangeRptBalance IS '还款方式变更贷款余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.occurType IS '发生类型';
COMMENT ON COLUMN app_loan_receipt_info.isExtend IS '是否展期（码值：是/否）';
COMMENT ON COLUMN app_loan_receipt_info.fixedAssetLoan IS '是否固贷产品（码值：是/否）';
COMMENT ON COLUMN app_loan_receipt_info.realEstateDevLoan IS '是否房地产开发产品（码值：是/否）';
COMMENT ON COLUMN app_loan_receipt_info.nextPayDate IS '下次还款日（格式：YYYYMMDD）';
COMMENT ON COLUMN app_loan_receipt_info.payPrinciPalamt IS '下次还款本金（万元）';
COMMENT ON COLUMN app_loan_receipt_info.payInterestamt IS '下次还款利息（万元）';
COMMENT ON COLUMN app_loan_receipt_info.payFineAmt IS '下次还款罚息（万元）';
COMMENT ON COLUMN app_loan_receipt_info.compoundinterest IS '下次还款复利（万元）';
COMMENT ON COLUMN app_loan_receipt_info.businessRate IS '执行年利率（%）';
COMMENT ON COLUMN app_loan_receipt_info.RepaymentPeriod IS '付息频率';
COMMENT ON COLUMN app_loan_receipt_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_loan_receipt_info_reportNo ON app_loan_receipt_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_loan_receipt_info_customerId ON app_loan_receipt_info (customerId);

CREATE TABLE IF NOT EXISTS app_early_warning_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    serialNo               VARCHAR(64),
    confirmTime            VARCHAR(32),
    inputDate              VARCHAR(32),
    approveStatusName      VARCHAR(64),
    phaseOpinion           TEXT,
    endTime                VARCHAR(32),
    riskTaskType           VARCHAR(64),
    taskType               VARCHAR(64),
    warnLevel              VARCHAR(64),
    riskReason             TEXT,
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_early_warning_info IS '预警任务台账表';
COMMENT ON COLUMN app_early_warning_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_early_warning_info.customerId IS '客户编号';
COMMENT ON COLUMN app_early_warning_info.customerName IS '客户名称';
COMMENT ON COLUMN app_early_warning_info.serialNo IS '预警任务流水号';
COMMENT ON COLUMN app_early_warning_info.confirmTime IS '预警本次认定时间';
COMMENT ON COLUMN app_early_warning_info.inputDate IS '预警本次发起时间';
COMMENT ON COLUMN app_early_warning_info.approveStatusName IS '审批状态（码值：审批通过/待审批/驳回（码值待确认））';
COMMENT ON COLUMN app_early_warning_info.phaseOpinion IS '审批意见';
COMMENT ON COLUMN app_early_warning_info.endTime IS '审批日期';
COMMENT ON COLUMN app_early_warning_info.riskTaskType IS '任务类型（码值：预警任务类型（码值待确认））';
COMMENT ON COLUMN app_early_warning_info.taskType IS '任务类型（审批通过预警任务、最近一条预警任务）';
COMMENT ON COLUMN app_early_warning_info.warnLevel IS '客户风险等级（码值：高/中/低，码值待确认）';
COMMENT ON COLUMN app_early_warning_info.riskReason IS '风险原因';
COMMENT ON COLUMN app_early_warning_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_early_warning_info_reportNo ON app_early_warning_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_early_warning_info_customerId ON app_early_warning_info (customerId);

CREATE TABLE IF NOT EXISTS app_early_warning_signal_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    serialNo               VARCHAR(64),
    riskMessage            VARCHAR(500),
    count                  INT,
    readyCount             INT,
    status                 VARCHAR(64),
    warningLevel           VARCHAR(64),
    inputDate              VARCHAR(64),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_early_warning_signal_info IS '预警信号明细表';
COMMENT ON COLUMN app_early_warning_signal_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_early_warning_signal_info.customerId IS '客户编号';
COMMENT ON COLUMN app_early_warning_signal_info.customerName IS '客户名称';
COMMENT ON COLUMN app_early_warning_signal_info.serialNo IS '预警编号（近一年预警台账接口serialNo）';
COMMENT ON COLUMN app_early_warning_signal_info.riskMessage IS '风险原因';
COMMENT ON COLUMN app_early_warning_signal_info.count IS '数量';
COMMENT ON COLUMN app_early_warning_signal_info.readyCount IS '待填写数量';
COMMENT ON COLUMN app_early_warning_signal_info.status IS '信号状态（近一年预警台账接口status）';
COMMENT ON COLUMN app_early_warning_signal_info.warningLevel IS '预警信号风险等级（接口warningLevel）';
COMMENT ON COLUMN app_early_warning_signal_info.inputDate IS '信号建立时间（接口inputDate）';
COMMENT ON COLUMN app_early_warning_signal_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_early_warning_signal_info_reportNo ON app_early_warning_signal_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_early_warning_signal_info_customerId ON app_early_warning_signal_info (customerId);

CREATE TABLE IF NOT EXISTS app_early_warning_opinion_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    serialNo               VARCHAR(64),
    confirmTime            VARCHAR(32),
    seqNo                  INT,
    activeName             VARCHAR(64),
    approveUserName        VARCHAR(64),
    approveOrgName         VARCHAR(128),
    warningLevelName       VARCHAR(64),
    phaseOpinion           TEXT,
    endTime                VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_early_warning_opinion_info IS '预警意见表';
COMMENT ON COLUMN app_early_warning_opinion_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_early_warning_opinion_info.customerId IS '客户编号';
COMMENT ON COLUMN app_early_warning_opinion_info.customerName IS '客户名称';
COMMENT ON COLUMN app_early_warning_opinion_info.serialNo IS '预警任务流水号';
COMMENT ON COLUMN app_early_warning_opinion_info.confirmTime IS '预警本次认定时间';
COMMENT ON COLUMN app_early_warning_opinion_info.seqNo IS '序号';
COMMENT ON COLUMN app_early_warning_opinion_info.activeName IS '审批阶段';
COMMENT ON COLUMN app_early_warning_opinion_info.approveUserName IS '审批人';
COMMENT ON COLUMN app_early_warning_opinion_info.approveOrgName IS '所属机构';
COMMENT ON COLUMN app_early_warning_opinion_info.warningLevelName IS '认定等级';
COMMENT ON COLUMN app_early_warning_opinion_info.phaseOpinion IS '审批意见';
COMMENT ON COLUMN app_early_warning_opinion_info.endTime IS '审批日';
COMMENT ON COLUMN app_early_warning_opinion_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_early_warning_opinion_info_reportNo ON app_early_warning_opinion_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_early_warning_opinion_info_customerId ON app_early_warning_opinion_info (customerId);

CREATE TABLE IF NOT EXISTS app_collateral_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    clrId                  VARCHAR(64),
    owner                  VARCHAR(128),
    clrType                VARCHAR(64),
    clrName                VARCHAR(128),
    clrStatus              VARCHAR(64),
    valuationDate          VARCHAR(32),
    choiceTypeName         VARCHAR(64),
    evaluateValue          DECIMAL(18,2),
    rightOrder             VARCHAR(64),
    rightSum               DECIMAL(18,2),
    confirmDate            VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- ↓↓ 2026-09-16 结构变更（同事反馈）：新增四列，见 00_执行说明.md「第 1 步·附」
    dyqdj                  VARCHAR(2),
    yydj                   VARCHAR(2),
    cfdj                   VARCHAR(2),
    ygdj                   VARCHAR(2),
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_collateral_info IS '押品主档表';
COMMENT ON COLUMN app_collateral_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_collateral_info.customerId IS '客户编号';
COMMENT ON COLUMN app_collateral_info.customerName IS '客户名称';
COMMENT ON COLUMN app_collateral_info.clrId IS '押品编号';
COMMENT ON COLUMN app_collateral_info.owner IS '权属人';
COMMENT ON COLUMN app_collateral_info.clrType IS '押品类型（码值：不动产/动产/权利类等，码值待确认）';
COMMENT ON COLUMN app_collateral_info.clrName IS '押品名称';
COMMENT ON COLUMN app_collateral_info.clrStatus IS '押品状态（码值：正常/查封/冻结/处置中，码值待确认）';
COMMENT ON COLUMN app_collateral_info.valuationDate IS '押品最新评估日期';
COMMENT ON COLUMN app_collateral_info.choiceTypeName IS '评估方式（评估价/协议作价）';
COMMENT ON COLUMN app_collateral_info.evaluateValue IS '评估价值（万元）';
COMMENT ON COLUMN app_collateral_info.rightOrder IS '顺位';
COMMENT ON COLUMN app_collateral_info.rightSum IS '权证金额（万元）';
COMMENT ON COLUMN app_collateral_info.confirmDate IS '认定日期';
COMMENT ON COLUMN app_collateral_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_collateral_info.dyqdj IS '是否存在地役权登记';
COMMENT ON COLUMN app_collateral_info.yydj IS '是否存在异议登记';
COMMENT ON COLUMN app_collateral_info.cfdj IS '是否存在查封登记';
COMMENT ON COLUMN app_collateral_info.ygdj IS '是否存在预告登记';
CREATE INDEX IF NOT EXISTS idx_collateral_info_reportNo ON app_collateral_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_collateral_info_customerId ON app_collateral_info (customerId);
CREATE INDEX IF NOT EXISTS idx_collateral_info_clrId ON app_collateral_info (clrId);

CREATE TABLE IF NOT EXISTS app_collateral_mortgage_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    clrId                  VARCHAR(64),
    clrName                VARCHAR(128),
    pledgeSerialNo         VARCHAR(64),
    pledgeeName            VARCHAR(128),
    guaranteeScope         VARCHAR(256),
    pledgeTypeName         VARCHAR(64),
    maxCreditorAmt         DECIMAL(18,2),
    startEnd               VARCHAR(64),
    registerTimestamp      VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_collateral_mortgage_info IS '押品他项权利/限制权利表';
COMMENT ON COLUMN app_collateral_mortgage_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_collateral_mortgage_info.customerId IS '客户编号';
COMMENT ON COLUMN app_collateral_mortgage_info.customerName IS '客户名称';
COMMENT ON COLUMN app_collateral_mortgage_info.clrId IS '押品编号（关联 app_collateral_info.clrId）';
COMMENT ON COLUMN app_collateral_mortgage_info.clrName IS '关联押品名称';
COMMENT ON COLUMN app_collateral_mortgage_info.pledgeSerialNo IS '不动产登记编号';
COMMENT ON COLUMN app_collateral_mortgage_info.pledgeeName IS '他项权姓名';
COMMENT ON COLUMN app_collateral_mortgage_info.guaranteeScope IS '担保范围';
COMMENT ON COLUMN app_collateral_mortgage_info.pledgeTypeName IS '抵押方式（码值：一般抵押/最高额抵押等，码值待确认）';
COMMENT ON COLUMN app_collateral_mortgage_info.maxCreditorAmt IS '债权数额（万元）';
COMMENT ON COLUMN app_collateral_mortgage_info.startEnd IS '债务履行期限';
COMMENT ON COLUMN app_collateral_mortgage_info.registerTimestamp IS '设定日期';
COMMENT ON COLUMN app_collateral_mortgage_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_collateral_mortgage_info_reportNo ON app_collateral_mortgage_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_collateral_mortgage_info_customerId ON app_collateral_mortgage_info (customerId);
CREATE INDEX IF NOT EXISTS idx_collateral_mortgage_info_clrId ON app_collateral_mortgage_info (clrId);

CREATE TABLE IF NOT EXISTS app_collateral_restricted_right (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    clrId                  VARCHAR(64),
    attachmentOrg          VARCHAR(128),
    attachmentTypeName     VARCHAR(64),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_collateral_restricted_right IS '押品限制权利表';
COMMENT ON COLUMN app_collateral_restricted_right.reportNo IS '报告编号';
COMMENT ON COLUMN app_collateral_restricted_right.customerId IS '客户编号';
COMMENT ON COLUMN app_collateral_restricted_right.customerName IS '客户名称';
COMMENT ON COLUMN app_collateral_restricted_right.clrId IS '押品编号（关联 app_collateral_info.clrId）';
COMMENT ON COLUMN app_collateral_restricted_right.attachmentOrg IS '限制权人';
COMMENT ON COLUMN app_collateral_restricted_right.attachmentTypeName IS '查封类型（码值：轮候查封/正式查封等，码值待确认）';
COMMENT ON COLUMN app_collateral_restricted_right.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_collateral_restricted_right_reportNo ON app_collateral_restricted_right (reportNo);
CREATE INDEX IF NOT EXISTS idx_collateral_restricted_right_customerId ON app_collateral_restricted_right (customerId);
CREATE INDEX IF NOT EXISTS idx_collateral_restricted_right_clrId ON app_collateral_restricted_right (clrId);

CREATE TABLE IF NOT EXISTS app_settle_account_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    accountNo              VARCHAR(64),
    accountStatus          VARCHAR(64),
    accountBalance         DECIMAL(18,2),
    superviseFlag          VARCHAR(64),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_settle_account_info IS '结算账户表';
COMMENT ON COLUMN app_settle_account_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_settle_account_info.customerId IS '客户编号';
COMMENT ON COLUMN app_settle_account_info.customerName IS '客户名称';
COMMENT ON COLUMN app_settle_account_info.accountNo IS '账号';
COMMENT ON COLUMN app_settle_account_info.accountStatus IS '账户状态（码值：正常/冻结/销户，码值待确认）';
COMMENT ON COLUMN app_settle_account_info.accountBalance IS '账户余额（万元）';
COMMENT ON COLUMN app_settle_account_info.superviseFlag IS '监管标识（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_settle_account_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_settle_account_info_reportNo ON app_settle_account_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_settle_account_info_customerId ON app_settle_account_info (customerId);

CREATE TABLE IF NOT EXISTS app_settle_asset_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportNo                            VARCHAR(64) NOT NULL,
    customerId                          VARCHAR(64),
    customerName                        VARCHAR(128),
    frozenAmount                        DECIMAL(18,2),
    debitSameNameTransferRatio          DECIMAL(5,2),
    creditSameNameTransferRatio         DECIMAL(5,2),
    yearAvgDeposit                      DECIMAL(18,2),
    lastYearAvgDeposit                  DECIMAL(18,2),
    propertyIncome                      DECIMAL(18,2),
    propertyIncomeYoy                   DECIMAL(18,2),
    propertyIncomeSupervised            DECIMAL(18,2),
    electricFeeIncome                   DECIMAL(18,2),
    electricFeeYoy                      DECIMAL(18,2),
    electricFeeSupervised               DECIMAL(18,2),
    keywordCounterpartyCreditAmount     DECIMAL(18,2),
    keywordRemarkCreditAmount           DECIMAL(18,2),
    inputtime                           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_settle_asset_info IS '结算资产表';
COMMENT ON COLUMN app_settle_asset_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_settle_asset_info.customerId IS '客户编号';
COMMENT ON COLUMN app_settle_asset_info.customerName IS '客户名称';
COMMENT ON COLUMN app_settle_asset_info.frozenAmount IS '冻结金额（万元）';
COMMENT ON COLUMN app_settle_asset_info.debitSameNameTransferRatio IS '借方同名划转金额占比（%）';
COMMENT ON COLUMN app_settle_asset_info.creditSameNameTransferRatio IS '贷方同名划转金额占比（%）';
COMMENT ON COLUMN app_settle_asset_info.yearAvgDeposit IS '年日均存款（万元）';
COMMENT ON COLUMN app_settle_asset_info.lastYearAvgDeposit IS '上年年日均存款（万元）';
COMMENT ON COLUMN app_settle_asset_info.propertyIncome IS '当年物业收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.propertyIncomeYoy IS '当年物业收入累计较上年同期（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.propertyIncomeSupervised IS '当年监管账户物业收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.electricFeeIncome IS '当年电费收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.electricFeeYoy IS '当年电费收入累计较上年同期（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.electricFeeSupervised IS '当年监管账户当年电费收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.keywordCounterpartyCreditAmount IS '当年交易对手中出现小额贷款、担保等关键字的公司贷方发生额（万元）';
COMMENT ON COLUMN app_settle_asset_info.keywordRemarkCreditAmount IS '当年备注中有担保、借款、投资关键字贷方发生额（万元）';
COMMENT ON COLUMN app_settle_asset_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_settle_asset_info_reportNo ON app_settle_asset_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_settle_asset_info_customerId ON app_settle_asset_info (customerId);

CREATE TABLE IF NOT EXISTS app_opinion_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    phaseOpinion           TEXT,
    endTime                VARCHAR(32),
    approveUserName        VARCHAR(64),
    approveOrgName         VARCHAR(128),
    `group`                VARCHAR(64),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_opinion_info IS '贷后意见表';
COMMENT ON COLUMN app_opinion_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_opinion_info.customerId IS '客户编号';
COMMENT ON COLUMN app_opinion_info.customerName IS '客户名称';
COMMENT ON COLUMN app_opinion_info.phaseOpinion IS '审批意见';
COMMENT ON COLUMN app_opinion_info.endTime IS '审批日期';
COMMENT ON COLUMN app_opinion_info.approveUserName IS '审批人';
COMMENT ON COLUMN app_opinion_info.approveOrgName IS '所属机构';
COMMENT ON COLUMN app_opinion_info.`group` IS '检查分组';
COMMENT ON COLUMN app_opinion_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_opinion_info_reportNo ON app_opinion_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_opinion_info_customerId ON app_opinion_info (customerId);

CREATE TABLE IF NOT EXISTS app_finance_report_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    finReportNo            VARCHAR(64),
    accountMonth           VARCHAR(32),
    sheetNo                VARCHAR(64),
    reportScope            VARCHAR(64),
    reportPeriod           VARCHAR(64),
    auditFlag              VARCHAR(32),
    currency               VARCHAR(32),
    currencyUnit           VARCHAR(32),
    reportStatus           VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_finance_report_info IS '财报主档表（一期一行）';
COMMENT ON COLUMN app_finance_report_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_finance_report_info.customerId IS '客户编号';
COMMENT ON COLUMN app_finance_report_info.customerName IS '客户名称';
COMMENT ON COLUMN app_finance_report_info.finReportNo IS '财报编号（财务报表明细标识，关联指标明细）';
COMMENT ON COLUMN app_finance_report_info.accountMonth IS '会计月';
COMMENT ON COLUMN app_finance_report_info.sheetNo IS '报表类型（码值：资产负债表/利润表/现金流量表等，码值待确认）';
COMMENT ON COLUMN app_finance_report_info.reportScope IS '报表口径（码值：合并/本部）';
COMMENT ON COLUMN app_finance_report_info.reportPeriod IS '报表周期（码值：年报/半年报/季报/月报，码值待确认）';
COMMENT ON COLUMN app_finance_report_info.auditFlag IS '是否审计（码值：是/否）';
COMMENT ON COLUMN app_finance_report_info.currency IS '报表币种';
COMMENT ON COLUMN app_finance_report_info.currencyUnit IS '货币单位（码值：元/千/万，样例为万）';
COMMENT ON COLUMN app_finance_report_info.reportStatus IS '报表状态（锁定/未锁定，是否锁定状态判断依据）';
COMMENT ON COLUMN app_finance_report_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_finance_report_info_reportNo ON app_finance_report_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_finance_report_info_customerId ON app_finance_report_info (customerId);
CREATE INDEX IF NOT EXISTS idx_finance_report_info_accountMonth ON app_finance_report_info (accountMonth);

CREATE TABLE IF NOT EXISTS app_finance_index_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    finReportNo            VARCHAR(64),
    accountMonth           VARCHAR(32),
    reportScope            VARCHAR(64),
    sheetNo                VARCHAR(64),
    reportPeriod           VARCHAR(64),
    indexType              VARCHAR(64),
    indexValue             DECIMAL(18,2),
    yoyValue               DECIMAL(12,4),
    changeValue            DECIMAL(18,2),
    changeRate             DECIMAL(12,4),
    currencyUnit           VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_finance_index_info IS '财务指标值表（一期一行一指标；同比/较年初等对比值由查询层计算，不落表）';
COMMENT ON COLUMN app_finance_index_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_finance_index_info.customerId IS '客户编号';
COMMENT ON COLUMN app_finance_index_info.customerName IS '客户名称';
COMMENT ON COLUMN app_finance_index_info.finReportNo IS '财报编号（关联财报主档 app_finance_report_info.finReportNo）';
COMMENT ON COLUMN app_finance_index_info.accountMonth IS '会计月';
COMMENT ON COLUMN app_finance_index_info.reportScope IS '报表口径（码值：合并/本部）';
COMMENT ON COLUMN app_finance_index_info.sheetNo IS '报表类型（码值：资产负债表/利润表/现金流量表等，码值待确认）';
COMMENT ON COLUMN app_finance_index_info.reportPeriod IS '报表周期（码值：年报/半年报/季报/月报，码值待确认）';
COMMENT ON COLUMN app_finance_index_info.indexType IS '指标类型（金额科目：营收/净利润/实收资本/短期借款/长期借款/一年内到期长期借款/应收账款/其他应收款/应付票据/其他应付款/存货/总资产，单位万元；比率指标：资产负债率/销售利率/净利率，存百分数值，如65.43表示65.43%）';
COMMENT ON COLUMN app_finance_index_info.indexValue IS '指标本期值（金额科目=万元；比率指标=百分数值，如65.43表示65.43%）';
COMMENT ON COLUMN app_finance_index_info.yoyValue IS '同比（%）：该期值÷上年同期值−1；行级属性各期行自带，上游计算或加工层预填（默认已有）';
COMMENT ON COLUMN app_finance_index_info.changeValue IS '较年初变动（万元）：该期值−上年末(12月)值；行级属性各期行自带（默认已有）';
COMMENT ON COLUMN app_finance_index_info.changeRate IS '较年初增幅（%）：(该期值−上年末值)÷上年末值；行级属性各期行自带（默认已有）';
COMMENT ON COLUMN app_finance_index_info.currencyUnit IS '货币单位（码值：元/千/万，样例为万）';
COMMENT ON COLUMN app_finance_index_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_finance_index_info_reportNo ON app_finance_index_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_finance_index_info_customerId ON app_finance_index_info (customerId);
CREATE INDEX IF NOT EXISTS idx_finance_index_info_indexType ON app_finance_index_info (indexType);
CREATE INDEX IF NOT EXISTS idx_finance_index_info_accountMonth ON app_finance_index_info (accountMonth);
CREATE INDEX IF NOT EXISTS idx_finance_index_info_reportScope ON app_finance_index_info (reportScope);

CREATE TABLE IF NOT EXISTS app_credit_report_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    subjectType            VARCHAR(64),
    guarantorId            VARCHAR(64),
    guarantorName          VARCHAR(128),
    queryTime              VARCHAR(32),
    zxReportNo             VARCHAR(128),
    expireDate             VARCHAR(32),
    overdueTotal           DECIMAL(18,2),
    attentionCreditBal     DECIMAL(18,2),
    badCreditBal           DECIMAL(18,2),
    attentionGuaranteeBal  DECIMAL(18,2),
    badGuaranteeBal        DECIMAL(18,2),
    guaranteeOverdueTotal  DECIMAL(18,2),
    guaranteeAttentionBal  DECIMAL(18,2),
    guaranteeBadBal        DECIMAL(18,2),
    extendDebtBal          DECIMAL(18,2),
    restructureDebtBal     DECIMAL(18,2),
    renewDebtBal           DECIMAL(18,2),
    transferDebtBal        DECIMAL(18,2),
    newOldDebtBal          DECIMAL(18,2),
    nonBankLiabTotal       DECIMAL(18,2),
    nonBankHighRateLoan    DECIMAL(12,4),
    nonBankGuaranteeBal    DECIMAL(18,2),
    workingCapitalLoanBal  DECIMAL(18,2),
    workingCapitalLoan1yBal DECIMAL(18,2),
    loanBankOrgCount       INT,
    guaranteeBankOrgCount  INT,
    shortTermLoanOrgCount      INT,
    midLongTermLoanOrgCount    INT,
    revolvingOverdraftOrgCount INT,
    discountOrgCount           INT,
    bankAcceptanceBillOrgCount INT,
    letterOfCreditOrgCount     INT,
    bankGuaranteeOrgCount      INT,
    otherGuaranteeTradeOrgCount INT,
    shortTermLoanBal           DECIMAL(18,2),
    midLongTermLoanBal         DECIMAL(18,2),
    revolvingOverdraftBal      DECIMAL(18,2),
    discountBal                DECIMAL(18,2),
    bankAcceptanceBillBal      DECIMAL(18,2),
    letterOfCreditBal          DECIMAL(18,2),
    bankGuaranteeBal           DECIMAL(18,2),
    otherGuaranteeTradeBal     DECIMAL(18,2),
    creditShortTermDiff    DECIMAL(18,2),
    creditLongTermDiff     DECIMAL(18,2),
    creditDebtDeviation    DECIMAL(12,4),
    guaranteeNetAsset      DECIMAL(12,4),
    guaranteeBalanceExBank DECIMAL(18,2),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_credit_report_info IS '企业征信快照表（一期一行，subjectType区分借款人/担保人主体）';
COMMENT ON COLUMN app_credit_report_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_credit_report_info.customerId IS '客户编号';
COMMENT ON COLUMN app_credit_report_info.customerName IS '客户名称';
COMMENT ON COLUMN app_credit_report_info.subjectType IS '主体类型（码值：借款人/担保人）';
COMMENT ON COLUMN app_credit_report_info.guarantorId IS '担保人客户编号（subjectType=担保人时填写）';
COMMENT ON COLUMN app_credit_report_info.guarantorName IS '担保人名称（subjectType=担保人时填写）';
COMMENT ON COLUMN app_credit_report_info.queryTime IS '征信查询时间';
COMMENT ON COLUMN app_credit_report_info.zxReportNo IS '征信报告记录号';
COMMENT ON COLUMN app_credit_report_info.expireDate IS '征信报告有效期';
COMMENT ON COLUMN app_credit_report_info.overdueTotal IS '未结清信贷的逾期总额（万元）';
COMMENT ON COLUMN app_credit_report_info.attentionCreditBal IS '未结清关注类信贷余额（万元）';
COMMENT ON COLUMN app_credit_report_info.badCreditBal IS '未结清不良类借贷余额（万元）';
COMMENT ON COLUMN app_credit_report_info.attentionGuaranteeBal IS '未结清关注类担保交易余额（万元）';
COMMENT ON COLUMN app_credit_report_info.badGuaranteeBal IS '未结清不良类担保交易余额（万元）';
COMMENT ON COLUMN app_credit_report_info.guaranteeOverdueTotal IS '对外担保（相关还款责任）未结清逾期类负债总额（万元）';
COMMENT ON COLUMN app_credit_report_info.guaranteeAttentionBal IS '对外担保（相关还款责任）未结清关注类负债总额（万元）';
COMMENT ON COLUMN app_credit_report_info.guaranteeBadBal IS '对外担保（相关还款责任）未结清不良类负债总额（万元）';
COMMENT ON COLUMN app_credit_report_info.extendDebtBal IS '展期债务未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.restructureDebtBal IS '重组债务未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.renewDebtBal IS '无还本续贷未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.transferDebtBal IS '其他机构转入未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.newOldDebtBal IS '借新还旧债务未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.nonBankLiabTotal IS '在非银机构负债合计（万元，上游直给：qy_fyjg_liab_tot/gr_fyjg_liab_tot）';
COMMENT ON COLUMN app_credit_report_info.nonBankHighRateLoan IS '非银机构较高利率借款推算利率最大值（%，企业，上游直给：qy_fyjg_gjlv_loan_max；较高利率判断依据）';
COMMENT ON COLUMN app_credit_report_info.nonBankGuaranteeBal IS '在非银机构对外担保余额（万元，上游直给：qy_fyjg_dwdb_bal）';
COMMENT ON COLUMN app_credit_report_info.workingCapitalLoanBal IS '流动资金贷款余额（万元，上游直给：qy_zhint_wjq_xyldk_bal）';
COMMENT ON COLUMN app_credit_report_info.workingCapitalLoan1yBal IS '一年期以下的流动资金贷款余额（万元，上游直给：qy_zhint_wjq_xyldk_1year_bal）';
COMMENT ON COLUMN app_credit_report_info.loanBankOrgCount IS '企业借贷交易合作银行及融资租赁机构数（上游直给：qy_jiedai_hzyh_org_cnt）';
COMMENT ON COLUMN app_credit_report_info.guaranteeBankOrgCount IS '企业担保交易合作银行及融资租赁机构数（上游直给：qy_danbao_hzyh_org_cnt）';
COMMENT ON COLUMN app_credit_report_info.shortTermLoanOrgCount IS '短期借款未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.midLongTermLoanOrgCount IS '中长期借款未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.revolvingOverdraftOrgCount IS '循环透支未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.discountOrgCount IS '贴现未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.bankAcceptanceBillOrgCount IS '银行承兑汇票未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.letterOfCreditOrgCount IS '信用证未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.bankGuaranteeOrgCount IS '银行保函未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.otherGuaranteeTradeOrgCount IS '其他担保交易未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.shortTermLoanBal IS '短期借款未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.midLongTermLoanBal IS '中长期借款未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.revolvingOverdraftBal IS '循环透支未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.discountBal IS '贴现未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.bankAcceptanceBillBal IS '银行承兑汇票未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.letterOfCreditBal IS '信用证未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.bankGuaranteeBal IS '银行保函未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.otherGuaranteeTradeBal IS '其他担保交易未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.creditShortTermDiff IS '征信短期借款未结清余额与财报短期借款相差（万元，加工结果默认已有）';
COMMENT ON COLUMN app_credit_report_info.creditLongTermDiff IS '征信中长期借款未结清余额与财报长期借款（含一年内到期的长期借款）相差（万元，加工结果默认已有）';
COMMENT ON COLUMN app_credit_report_info.creditDebtDeviation IS '征信债务与财报债务偏离度（%，加工结果默认已有）';
COMMENT ON COLUMN app_credit_report_info.guaranteeNetAsset IS '对外担保/净资产（%）';
COMMENT ON COLUMN app_credit_report_info.guaranteeBalanceExBank IS '对外担保（相关还款责任）余额（剔除我行）（万元，上游直给：qy_dwdb_bal_exc_wx）';
COMMENT ON COLUMN app_credit_report_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_credit_report_info_reportNo ON app_credit_report_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_credit_report_info_customerId ON app_credit_report_info (customerId);

CREATE TABLE IF NOT EXISTS app_credit_debt_detail (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    subjectType            VARCHAR(64),
    guarantorId            VARCHAR(64),
    guarantorName          VARCHAR(128),
    queryTime              VARCHAR(32),
    zxReportNo             VARCHAR(128),
    debtType               VARCHAR(64),
    orgCount               INT,
    balance                DECIMAL(18,2),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_credit_debt_detail IS '征信债务明细表（按类型一期一行）';
COMMENT ON COLUMN app_credit_debt_detail.reportNo IS '报告编号';
COMMENT ON COLUMN app_credit_debt_detail.customerId IS '客户编号';
COMMENT ON COLUMN app_credit_debt_detail.customerName IS '客户名称';
COMMENT ON COLUMN app_credit_debt_detail.subjectType IS '主体类型（码值：借款人/担保人）';
COMMENT ON COLUMN app_credit_debt_detail.guarantorId IS '担保人客户编号（subjectType=担保人时填写）';
COMMENT ON COLUMN app_credit_debt_detail.guarantorName IS '担保人名称（subjectType=担保人时填写）';
COMMENT ON COLUMN app_credit_debt_detail.queryTime IS '征信查询时间';
COMMENT ON COLUMN app_credit_debt_detail.zxReportNo IS '征信报告记录号';
COMMENT ON COLUMN app_credit_debt_detail.debtType IS '债务类型（中长期借款/短期借款/循环透支/贴现/银行承兑汇票/信用证/银行保函/其他担保交易）';
COMMENT ON COLUMN app_credit_debt_detail.orgCount IS '未结清机构数合计';
COMMENT ON COLUMN app_credit_debt_detail.balance IS '未结清余额合计（万元）';
COMMENT ON COLUMN app_credit_debt_detail.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_credit_debt_detail_reportNo ON app_credit_debt_detail (reportNo);
CREATE INDEX IF NOT EXISTS idx_credit_debt_detail_customerId ON app_credit_debt_detail (customerId);
CREATE INDEX IF NOT EXISTS idx_credit_debt_detail_debtType ON app_credit_debt_detail (debtType);

CREATE TABLE IF NOT EXISTS app_guarantor_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    guarantorId            VARCHAR(64),
    guarantorName          VARCHAR(128),
    guarantorType          VARCHAR(32),
    isStateOwned           VARCHAR(64),
    education              VARCHAR(64),
    subjectType            VARCHAR(64),
    zxReportNoZX           VARCHAR(128),
    zxReportNosq           VARCHAR(128),
    zxReportNoSX           VARCHAR(128),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_guarantor_info IS '担保人信息表';
COMMENT ON COLUMN app_guarantor_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_guarantor_info.customerId IS '客户编号';
COMMENT ON COLUMN app_guarantor_info.customerName IS '客户名称';
COMMENT ON COLUMN app_guarantor_info.guarantorId IS '担保人客户编号（行内接口字段）';
COMMENT ON COLUMN app_guarantor_info.guarantorName IS '担保人';
COMMENT ON COLUMN app_guarantor_info.guarantorType IS '担保人类型（法人/自然人）';
COMMENT ON COLUMN app_guarantor_info.isStateOwned IS '是否国资/国有担保';
COMMENT ON COLUMN app_guarantor_info.education IS '学历（征信基本信息，接口zxBiEDULVL）';
COMMENT ON COLUMN app_guarantor_info.subjectType IS '主体类型（码值：借款人/担保人，2026-09-03 新增）';
COMMENT ON COLUMN app_guarantor_info.zxReportNoZX IS '征信报告记录号-最新（2026-09-03 新增，文件字段名 zxReportNoZX）';
COMMENT ON COLUMN app_guarantor_info.zxReportNosq IS '征信报告记录号-上期（2026-09-03 新增，文件字段名 zxReportNosq）';
COMMENT ON COLUMN app_guarantor_info.zxReportNoSX IS '征信报告记录号-授信（2026-09-03 新增，文件字段名 zxReportNoSX）';
COMMENT ON COLUMN app_guarantor_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_guarantor_info_reportNo ON app_guarantor_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_guarantor_info_customerId ON app_guarantor_info (customerId);

CREATE TABLE IF NOT EXISTS app_guarantor_credit_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    guarantorId            VARCHAR(64),
    guarantorName          VARCHAR(128),
    queryTime              VARCHAR(32),
    zxReportNo             VARCHAR(128),
    totalLoanBal           DECIMAL(18,2),
    operateLoanBal         DECIMAL(18,2),
    consumeLoanBal         DECIMAL(18,2),
    houseLoanBal           DECIMAL(18,2),
    otherLoanBal           DECIMAL(18,2),
    totalLoanCount         INT,
    operateLoanCount       INT,
    consumeLoanCount       INT,
    houseLoanCount         INT,
    otherLoanCount         INT,
    bzcBal                 DECIMAL(18,2),
    badBal                 DECIMAL(18,2),
    loanCurrentOverdue     DECIMAL(18,2),
    cardCurrentOverdue     DECIMAL(18,2),
    guaranteeOverdueAmt    DECIMAL(18,2),
    nonBankGuaranteeBal    DECIMAL(18,2),
    nonBankHighRateLoan    DECIMAL(12,4),
    guaranteeAbnormalBal   DECIMAL(18,2),
    extendBal              DECIMAL(18,2),
    delayBal               DECIMAL(18,2),
    creditAbnormalBal      DECIMAL(18,2),
    acctAbnormalBal        DECIMAL(18,2),
    cardAbnormalBal        DECIMAL(18,2),
    guaranteeHkAbnormalBal DECIMAL(18,2),
    creditUseRate          DECIMAL(12,4),
    nonBankLiabTotal       DECIMAL(18,2),
    loanQuery12m              INT,
    loanQuery6m               INT,
    loanQuery3m               INT,
    cardQuery12m              INT,
    cardQuery6m               INT,
    cardQuery3m               INT,
    selfQuery1m               INT,
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_guarantor_credit_info IS '担保人征信表（个人担保人）';
COMMENT ON COLUMN app_guarantor_credit_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_guarantor_credit_info.customerId IS '客户编号';
COMMENT ON COLUMN app_guarantor_credit_info.customerName IS '客户名称';
COMMENT ON COLUMN app_guarantor_credit_info.guarantorId IS '担保人客户编号';
COMMENT ON COLUMN app_guarantor_credit_info.guarantorName IS '担保人';
COMMENT ON COLUMN app_guarantor_credit_info.queryTime IS '征信查询时间';
COMMENT ON COLUMN app_guarantor_credit_info.zxReportNo IS '征信报告记录号';
COMMENT ON COLUMN app_guarantor_credit_info.totalLoanBal IS '贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.operateLoanBal IS '经营性贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.consumeLoanBal IS '消费类贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.houseLoanBal IS '住房类贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.otherLoanBal IS '其他贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.totalLoanCount IS '贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.operateLoanCount IS '经营性贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.consumeLoanCount IS '消费类贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.houseLoanCount IS '住房类贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.otherLoanCount IS '其他贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.bzcBal IS '被追偿余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.badBal IS '呆账余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.loanCurrentOverdue IS '贷款当前逾期总金额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.cardCurrentOverdue IS '贷记卡当前逾期总金额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.guaranteeOverdueAmt IS '对外担保（相关还款责任）当前逾期金额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.nonBankGuaranteeBal IS '在非银机构对外担保余额（万元，上游直给：qy_fyjg_dwdb_bal/gr_fyjg_dwdb_bal）';
COMMENT ON COLUMN app_guarantor_credit_info.nonBankHighRateLoan IS '非银机构较高利率借款推算利率最大值（%，上游直给：qy_fyjg_gjlv_loan_max/gr_fyjg_gjlv_loan_max；较高利率判断依据）';
COMMENT ON COLUMN app_guarantor_credit_info.guaranteeAbnormalBal IS '对外担保（相关还款责任）五级分类非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.extendBal IS '展期债务余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.delayBal IS '落实金融困等政策银行主动延期债务余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.creditAbnormalBal IS '未结清信贷五级分类非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.acctAbnormalBal IS '未结清账户状态非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.cardAbnormalBal IS '未销户贷记卡账户状态非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.guaranteeHkAbnormalBal IS '对外担保（相关还款责任）还款状态非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.creditUseRate IS '信用卡使用率（%）';
COMMENT ON COLUMN app_guarantor_credit_info.nonBankLiabTotal IS '在非银机构负债合计（万元，个人，上游直给：gr_fyjg_liab_tot）';
COMMENT ON COLUMN app_guarantor_credit_info.loanQuery12m IS '近一年贷款审批征信查询次数（2026-09-03 新增）';
COMMENT ON COLUMN app_guarantor_credit_info.loanQuery6m IS '近6个月贷款审批征信查询次数（2026-09-03 新增）';
COMMENT ON COLUMN app_guarantor_credit_info.loanQuery3m IS '近3个月贷款审批征信查询次数（2026-09-03 新增）';
COMMENT ON COLUMN app_guarantor_credit_info.cardQuery12m IS '近一年信用卡审批征信查询次数（2026-09-03 新增）';
COMMENT ON COLUMN app_guarantor_credit_info.cardQuery6m IS '近6个月信用卡审批征信查询次数（2026-09-03 新增）';
COMMENT ON COLUMN app_guarantor_credit_info.cardQuery3m IS '近3个月信用卡审批征信查询次数（2026-09-03 新增）';
COMMENT ON COLUMN app_guarantor_credit_info.selfQuery1m IS '近1个月本人查询征信查询次数（2026-09-03 新增）';
COMMENT ON COLUMN app_guarantor_credit_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_guarantor_credit_info_reportNo ON app_guarantor_credit_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_guarantor_credit_info_customerId ON app_guarantor_credit_info (customerId);
CREATE INDEX IF NOT EXISTS idx_guarantor_credit_info_guarantorName ON app_guarantor_credit_info (guarantorName);

CREATE TABLE IF NOT EXISTS app_credit_query_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    guarantorId            VARCHAR(64),
    guarantorName          VARCHAR(128),
    queryTime              VARCHAR(32),
    zxReportNo             VARCHAR(128),
    loanQuery12m           INT,
    loanQuery6m            INT,
    loanQuery3m            INT,
    cardQuery12m           INT,
    cardQuery6m            INT,
    cardQuery3m            INT,
    selfQuery1m            INT,
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_credit_query_info IS '征信查询次数表';
COMMENT ON COLUMN app_credit_query_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_credit_query_info.customerId IS '客户编号';
COMMENT ON COLUMN app_credit_query_info.customerName IS '客户名称';
COMMENT ON COLUMN app_credit_query_info.guarantorId IS '担保人客户编号';
COMMENT ON COLUMN app_credit_query_info.guarantorName IS '担保人名称';
COMMENT ON COLUMN app_credit_query_info.queryTime IS '征信查询时间';
COMMENT ON COLUMN app_credit_query_info.zxReportNo IS '征信报告记录号';
COMMENT ON COLUMN app_credit_query_info.loanQuery12m IS '近一年贷款审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.loanQuery6m IS '近6个月贷款审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.loanQuery3m IS '近3个月贷款审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.cardQuery12m IS '近一年信用卡审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.cardQuery6m IS '近6个月信用卡审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.cardQuery3m IS '近3个月信用卡审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.selfQuery1m IS '近1个月本人查询征信查询次数';
COMMENT ON COLUMN app_credit_query_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_credit_query_info_reportNo ON app_credit_query_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_credit_query_info_customerId ON app_credit_query_info (customerId);

CREATE TABLE IF NOT EXISTS app_capital_flow_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    loanSerialNo           VARCHAR(64),
    loanStatus             VARCHAR(64),
    serialNo               VARCHAR(128),
    capitalCheckTaskType   VARCHAR(64),
    approveStatus          VARCHAR(64),
    isPurposeAbnormal      VARCHAR(64),
    rectificationSituation VARCHAR(128),
    rectificationDeadline  VARCHAR(32),
    rectificationExplanation TEXT,
    identifyReason         TEXT,
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_capital_flow_info IS '资金回流/用途异常表';
COMMENT ON COLUMN app_capital_flow_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_capital_flow_info.customerId IS '客户编号';
COMMENT ON COLUMN app_capital_flow_info.customerName IS '客户名称';
COMMENT ON COLUMN app_capital_flow_info.loanSerialNo IS '借据号';
COMMENT ON COLUMN app_capital_flow_info.loanStatus IS '借据状态（码值：正常/关注/次级/可疑/损失/逾期/结清（码值待确认））';
COMMENT ON COLUMN app_capital_flow_info.serialNo IS '流水号';
COMMENT ON COLUMN app_capital_flow_info.capitalCheckTaskType IS '任务类型（码值：资金用途检查任务类型（码值待确认））';
COMMENT ON COLUMN app_capital_flow_info.approveStatus IS '审批状态（码值：审批通过/待审批/驳回（码值待确认））';
COMMENT ON COLUMN app_capital_flow_info.isPurposeAbnormal IS '是否回流异常（码值：是/否）';
COMMENT ON COLUMN app_capital_flow_info.rectificationSituation IS '整改情况';
COMMENT ON COLUMN app_capital_flow_info.rectificationDeadline IS '整改期限';
COMMENT ON COLUMN app_capital_flow_info.rectificationExplanation IS '整改情况说明';
COMMENT ON COLUMN app_capital_flow_info.identifyReason IS '认定理由';
COMMENT ON COLUMN app_capital_flow_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_capital_flow_info_reportNo ON app_capital_flow_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_capital_flow_info_customerId ON app_capital_flow_info (customerId);

CREATE TABLE IF NOT EXISTS app_entrust_pay_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    paymentMode            VARCHAR(64),
    payDate                VARCHAR(32),
    accountName            VARCHAR(128),
    payeeCancelDate        VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_entrust_pay_info IS '受托支付明细表';
COMMENT ON COLUMN app_entrust_pay_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_entrust_pay_info.customerId IS '客户编号';
COMMENT ON COLUMN app_entrust_pay_info.customerName IS '客户名称';
COMMENT ON COLUMN app_entrust_pay_info.paymentMode IS '支付方式（码值：受托支付/自主支付，码值待确认）';
COMMENT ON COLUMN app_entrust_pay_info.payDate IS '支付日期';
COMMENT ON COLUMN app_entrust_pay_info.accountName IS '收款人名称';
COMMENT ON COLUMN app_entrust_pay_info.payeeCancelDate IS '受托支付对象注销日期';
COMMENT ON COLUMN app_entrust_pay_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_entrust_pay_info_reportNo ON app_entrust_pay_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_entrust_pay_info_customerId ON app_entrust_pay_info (customerId);

CREATE TABLE IF NOT EXISTS app_settle_counterparty_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    counterpartyName       VARCHAR(128),
    direction              VARCHAR(16),
    amount                 DECIMAL(18,2),
    rankNo                 VARCHAR(16),
    upstreamFlag           VARCHAR(32),
    remark                 VARCHAR(512),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_settle_counterparty_info IS '结算交易对手表';
COMMENT ON COLUMN app_settle_counterparty_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_settle_counterparty_info.customerId IS '客户编号';
COMMENT ON COLUMN app_settle_counterparty_info.customerName IS '客户名称';
COMMENT ON COLUMN app_settle_counterparty_info.counterpartyName IS '交易对手名称';
COMMENT ON COLUMN app_settle_counterparty_info.direction IS '方向（借方/贷方）';
COMMENT ON COLUMN app_settle_counterparty_info.amount IS '发生额（万元）';
COMMENT ON COLUMN app_settle_counterparty_info.rankNo IS '排名（TOP1-10）';
COMMENT ON COLUMN app_settle_counterparty_info.upstreamFlag IS '是否前五大上游客户（码值：是/否）';
COMMENT ON COLUMN app_settle_counterparty_info.remark IS '交易备注（预留：备注含担保/借款/投资关键字贷方发生额筛选用，接口待补充）';
COMMENT ON COLUMN app_settle_counterparty_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_settle_counterparty_info_reportNo ON app_settle_counterparty_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_settle_counterparty_info_customerId ON app_settle_counterparty_info (customerId);
CREATE INDEX IF NOT EXISTS idx_settle_counterparty_info_direction ON app_settle_counterparty_info (direction);

CREATE TABLE IF NOT EXISTS app_top_five_updown_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    supplier               VARCHAR(128),
    supplierType           VARCHAR(64),
    supplierTypeName       VARCHAR(64),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_top_five_updown_info IS '前五大上下游表';
COMMENT ON COLUMN app_top_five_updown_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_top_five_updown_info.customerId IS '客户编号';
COMMENT ON COLUMN app_top_five_updown_info.customerName IS '客户名称';
COMMENT ON COLUMN app_top_five_updown_info.supplier IS '供应商名称';
COMMENT ON COLUMN app_top_five_updown_info.supplierType IS '供应商类型';
COMMENT ON COLUMN app_top_five_updown_info.supplierTypeName IS '供应商类型名称';
COMMENT ON COLUMN app_top_five_updown_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_top_five_updown_info_reportNo ON app_top_five_updown_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_top_five_updown_info_customerId ON app_top_five_updown_info (customerId);

CREATE TABLE IF NOT EXISTS app_payroll_stat_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    statMonth              VARCHAR(32),
    payrollCount           INT,
    payrollAmount          DECIMAL(18,2),
    countMom               DECIMAL(12,4),
    amountMom              DECIMAL(12,4),
    countYoy               DECIMAL(12,4),
    amountYoy              DECIMAL(12,4),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_payroll_stat_info IS '代发统计表（月粒度）';
COMMENT ON COLUMN app_payroll_stat_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_payroll_stat_info.customerId IS '客户编号';
COMMENT ON COLUMN app_payroll_stat_info.customerName IS '客户名称';
COMMENT ON COLUMN app_payroll_stat_info.statMonth IS '统计月份';
COMMENT ON COLUMN app_payroll_stat_info.payrollCount IS '代发人数';
COMMENT ON COLUMN app_payroll_stat_info.payrollAmount IS '代发金额（万元）';
COMMENT ON COLUMN app_payroll_stat_info.countMom IS '代发人数环比';
COMMENT ON COLUMN app_payroll_stat_info.amountMom IS '代发金额环比';
COMMENT ON COLUMN app_payroll_stat_info.countYoy IS '代发人数同比';
COMMENT ON COLUMN app_payroll_stat_info.amountYoy IS '代发金额同比';
COMMENT ON COLUMN app_payroll_stat_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_payroll_stat_info_reportNo ON app_payroll_stat_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_payroll_stat_info_customerId ON app_payroll_stat_info (customerId);

CREATE TABLE IF NOT EXISTS app_check_record_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    checkInTime            VARCHAR(32),
    checkInAddress         VARCHAR(256),
    visitObj               VARCHAR(128),
    checkInObj             VARCHAR(128),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_check_record_info IS '现场检查打卡记录表';
COMMENT ON COLUMN app_check_record_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_check_record_info.customerId IS '客户编号';
COMMENT ON COLUMN app_check_record_info.customerName IS '客户名称';
COMMENT ON COLUMN app_check_record_info.checkInTime IS '打卡日期';
COMMENT ON COLUMN app_check_record_info.checkInAddress IS '打卡地址';
COMMENT ON COLUMN app_check_record_info.visitObj IS '拜访对象';
COMMENT ON COLUMN app_check_record_info.checkInObj IS '打卡对象';
COMMENT ON COLUMN app_check_record_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_check_record_info_reportNo ON app_check_record_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_check_record_info_customerId ON app_check_record_info (customerId);

CREATE TABLE IF NOT EXISTS app_check_opinion_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    conditionDesc          TEXT,
    completeStatus         VARCHAR(64),
    conditionInstruction   TEXT,
    realCompleteTime       VARCHAR(32),
    itemCategory           VARCHAR(64),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_check_opinion_info IS '批复后续管理要求表';
COMMENT ON COLUMN app_check_opinion_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_check_opinion_info.customerId IS '客户编号';
COMMENT ON COLUMN app_check_opinion_info.customerName IS '客户名称';
COMMENT ON COLUMN app_check_opinion_info.conditionDesc IS '批复后续管理要求';
COMMENT ON COLUMN app_check_opinion_info.completeStatus IS '完成情况（码值：已完成/未完成/部分完成/持续关注，码值待确认）';
COMMENT ON COLUMN app_check_opinion_info.conditionInstruction IS '情况说明';
COMMENT ON COLUMN app_check_opinion_info.realCompleteTime IS '实际完成日期';
COMMENT ON COLUMN app_check_opinion_info.itemCategory IS '事项类别';
COMMENT ON COLUMN app_check_opinion_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_check_opinion_info_reportNo ON app_check_opinion_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_check_opinion_info_customerId ON app_check_opinion_info (customerId);

CREATE TABLE IF NOT EXISTS app_single_check_task_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    itemCategory           VARCHAR(64),
    serialNo               VARCHAR(64),
    creditNo               VARCHAR(64),
    approveTextNo          VARCHAR(64),
    startDate              VARCHAR(32),
    maturity               VARCHAR(32),
    groupName              VARCHAR(128),
    productName            VARCHAR(128),
    checkDate              VARCHAR(32),
    balance                DECIMAL(18,2),
    condition              TEXT,
    implementStatus        VARCHAR(64),
    extendDate             VARCHAR(32),
    opinion                TEXT,
    conditioninStruction   TEXT,
    creditApproveUserName  VARCHAR(64),
    approveAuthor          VARCHAR(64),
    operateBelongOrgName   VARCHAR(128),
    operateOrgName         VARCHAR(128),
    operateUserName        VARCHAR(64),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_single_check_task_info IS '单项检查任务表';
COMMENT ON COLUMN app_single_check_task_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_single_check_task_info.customerId IS '客户编号';
COMMENT ON COLUMN app_single_check_task_info.customerName IS '客户名称';
COMMENT ON COLUMN app_single_check_task_info.itemCategory IS '事项类别';
COMMENT ON COLUMN app_single_check_task_info.serialNo IS '单项检查任务流水号';
COMMENT ON COLUMN app_single_check_task_info.creditNo IS '授信编号';
COMMENT ON COLUMN app_single_check_task_info.approveTextNo IS '批复编号';
COMMENT ON COLUMN app_single_check_task_info.startDate IS '批复生效日期';
COMMENT ON COLUMN app_single_check_task_info.maturity IS '批复到期日';
COMMENT ON COLUMN app_single_check_task_info.groupName IS '集团名称';
COMMENT ON COLUMN app_single_check_task_info.productName IS '对象';
COMMENT ON COLUMN app_single_check_task_info.checkDate IS '检查时间';
COMMENT ON COLUMN app_single_check_task_info.balance IS '对象项下借据余额（万元）';
COMMENT ON COLUMN app_single_check_task_info.condition IS '批复后续管理要求';
COMMENT ON COLUMN app_single_check_task_info.implementStatus IS '落实情况';
COMMENT ON COLUMN app_single_check_task_info.extendDate IS '延期日期';
COMMENT ON COLUMN app_single_check_task_info.opinion IS '签署意见';
COMMENT ON COLUMN app_single_check_task_info.conditioninStruction IS '情况说明';
COMMENT ON COLUMN app_single_check_task_info.creditApproveUserName IS '授信审查人';
COMMENT ON COLUMN app_single_check_task_info.approveAuthor IS '审批权限';
COMMENT ON COLUMN app_single_check_task_info.operateBelongOrgName IS '分行';
COMMENT ON COLUMN app_single_check_task_info.operateOrgName IS '支行';
COMMENT ON COLUMN app_single_check_task_info.operateUserName IS '经办客户经理';
COMMENT ON COLUMN app_single_check_task_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_single_check_task_info_reportNo ON app_single_check_task_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_single_check_task_info_customerId ON app_single_check_task_info (customerId);

CREATE TABLE IF NOT EXISTS app_check_index_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    chineseId              VARCHAR(64),
    chineseName            VARCHAR(128),
    indexObject            VARCHAR(128),
    yesNo                  VARCHAR(32),
    isAbnormal             VARCHAR(32),
    remark                 TEXT,
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_check_index_info IS '日常检查综合指标表';
COMMENT ON COLUMN app_check_index_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_check_index_info.customerId IS '客户编号';
COMMENT ON COLUMN app_check_index_info.customerName IS '客户名称';
COMMENT ON COLUMN app_check_index_info.chineseId IS '指标编号';
COMMENT ON COLUMN app_check_index_info.chineseName IS '指标名称';
COMMENT ON COLUMN app_check_index_info.indexObject IS '指标对象';
COMMENT ON COLUMN app_check_index_info.yesNo IS '检查结论（是/否）';
COMMENT ON COLUMN app_check_index_info.isAbnormal IS '是否异常（码值：是/否）';
COMMENT ON COLUMN app_check_index_info.remark IS '说明';
COMMENT ON COLUMN app_check_index_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_check_index_info_reportNo ON app_check_index_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_check_index_info_customerId ON app_check_index_info (customerId);

CREATE TABLE IF NOT EXISTS app_check_object_info (
    id               BIGINT NOT NULL AUTO_INCREMENT,
    reportNo         VARCHAR(64) NOT NULL,
    customerId       VARCHAR(64),
    customerName     VARCHAR(128),
    objectName       VARCHAR(128),
    contractNo       VARCHAR(64),
    indexNo          VARCHAR(64),
    indexName        VARCHAR(128),
    indexType        VARCHAR(64),
    indexResult      VARCHAR(256),
    isAbnormal       VARCHAR(32),
    redTextRequire   TEXT,
    inputtime        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_check_object_info IS '对象指标检查明细表';
COMMENT ON COLUMN app_check_object_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_check_object_info.customerId IS '客户编号';
COMMENT ON COLUMN app_check_object_info.customerName IS '客户名称';
COMMENT ON COLUMN app_check_object_info.objectName IS '对象名称';
COMMENT ON COLUMN app_check_object_info.contractNo IS '业务合同编号';
COMMENT ON COLUMN app_check_object_info.indexNo IS '指标编号';
COMMENT ON COLUMN app_check_object_info.indexName IS '指标名称';
COMMENT ON COLUMN app_check_object_info.indexType IS '指标类型';
COMMENT ON COLUMN app_check_object_info.indexResult IS '指标结果';
COMMENT ON COLUMN app_check_object_info.isAbnormal IS '是否异常（码值：是/否/提示）';
COMMENT ON COLUMN app_check_object_info.redTextRequire IS '红字要求';
COMMENT ON COLUMN app_check_object_info.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_check_object_info_reportNo ON app_check_object_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_check_object_info_customerId ON app_check_object_info (customerId);

CREATE TABLE IF NOT EXISTS app_reputation_event_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    subjectType            VARCHAR(32),
    subjectName            VARCHAR(128),
    eventTime              VARCHAR(32),
    eventType              VARCHAR(64),
    eventDesc              TEXT,
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- ↓↓ 2026-09-16 结构变更（同事反馈）：新增两列
    eventTypeCode          VARCHAR(64),
    eventTypeOrder         INTEGER,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_reputation_event_info IS '舆情事件明细表';
COMMENT ON COLUMN app_reputation_event_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_reputation_event_info.customerId IS '客户编号';
COMMENT ON COLUMN app_reputation_event_info.customerName IS '客户名称';
COMMENT ON COLUMN app_reputation_event_info.subjectType IS '主体类型（码值：借款人/股东）';
COMMENT ON COLUMN app_reputation_event_info.subjectName IS '主体名称（借款人名称/股东名称）';
COMMENT ON COLUMN app_reputation_event_info.eventTime IS '舆情发生时间';
COMMENT ON COLUMN app_reputation_event_info.eventType IS '舆情类型（码值：证券市场违规/股票戴帽/退市风险/评级下调/高管无法履职/财务造假/其他，待确认）';
COMMENT ON COLUMN app_reputation_event_info.eventDesc IS '舆情事件描述';
COMMENT ON COLUMN app_reputation_event_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_reputation_event_info.eventTypeCode IS '舆情类型编码';
COMMENT ON COLUMN app_reputation_event_info.eventTypeOrder IS '舆情事件排序';
CREATE INDEX IF NOT EXISTS idx_reputation_event_info_reportNo ON app_reputation_event_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_reputation_event_info_customerId ON app_reputation_event_info (customerId);

-- =====================================================================
-- V1.25 新增表：app_graph_hit_info（企业图谱命中情况，14 字段）
-- =====================================================================
CREATE TABLE IF NOT EXISTS app_graph_hit_info (
    id                            BIGINT NOT NULL AUTO_INCREMENT,
    reportNo                      VARCHAR(64) NOT NULL,
    customerId                    VARCHAR(64),
    customerName                  VARCHAR(128),
    inputtime                     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    suspectedFundReturn           VARCHAR(8) DEFAULT NULL,
    suspectedLoanPurposeAbnormal  VARCHAR(8) DEFAULT NULL,
    suspectedBorrowedNameLoan     VARCHAR(8) DEFAULT NULL,
    suspectedShellCompany         VARCHAR(8) DEFAULT NULL,
    suspectedGuaranteeCircle      VARCHAR(8) DEFAULT NULL,
    intraBankRelation             VARCHAR(8) DEFAULT NULL,
    entrustedPayManyToOne         VARCHAR(8) DEFAULT NULL,
    collateralSameCommunity       VARCHAR(8) DEFAULT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_graph_hit_info IS '企业图谱命中情况';
COMMENT ON COLUMN app_graph_hit_info.id IS 'id';
COMMENT ON COLUMN app_graph_hit_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_graph_hit_info.customerId IS '客户编号';
COMMENT ON COLUMN app_graph_hit_info.customerName IS '客户名称';
COMMENT ON COLUMN app_graph_hit_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_graph_hit_info.suspectedFundReturn IS '疑似资金回流（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.suspectedLoanPurposeAbnormal IS '贷款用途疑似异常（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.suspectedBorrowedNameLoan IS '疑似借名贷款（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.suspectedShellCompany IS '疑似空壳公司（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.suspectedGuaranteeCircle IS '疑似担保圈链（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.intraBankRelation IS '行内关联关系（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.entrustedPayManyToOne IS '受托支付多对一（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.collateralSameCommunity IS '抵押物同小区关联（码值：是/否，码值待确认）';
CREATE INDEX IF NOT EXISTS idx_graph_hit_info_reportNo ON app_graph_hit_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_graph_hit_info_customerId ON app_graph_hit_info (customerId);

-- =====================================================================
-- V1.23 新增表1：app_gs_tax_sales_info（国税销售额表，9 字段）
-- =====================================================================
CREATE TABLE IF NOT EXISTS app_gs_tax_sales_info (
    id                BIGINT NOT NULL AUTO_INCREMENT,
    reportNo          VARCHAR(64) NOT NULL,
    customerId        VARCHAR(64),
    customerName      VARCHAR(128),
    inputtime         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    taxPeriod         VARCHAR(32),
    monthlyTaxSales   DECIMAL(18,2),
    totalSalesTax     DECIMAL(18,2),
    yoyChange         DECIMAL(18,2),
    yoyRate           DECIMAL(12,4),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_gs_tax_sales_info IS '国税销售额表';
COMMENT ON COLUMN app_gs_tax_sales_info.id IS 'id';
COMMENT ON COLUMN app_gs_tax_sales_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_gs_tax_sales_info.customerId IS '客户编号';
COMMENT ON COLUMN app_gs_tax_sales_info.customerName IS '客户名称';
COMMENT ON COLUMN app_gs_tax_sales_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_gs_tax_sales_info.taxPeriod IS '纳税期（按月，一月一行，如202603）';
COMMENT ON COLUMN app_gs_tax_sales_info.monthlyTaxSales IS '每月纳税销售额（万元）';
COMMENT ON COLUMN app_gs_tax_sales_info.totalSalesTax IS '当年纳税申请总销售额累计（万元）';
COMMENT ON COLUMN app_gs_tax_sales_info.yoyChange IS '当年销售额较上年同期变动额（万元）';
COMMENT ON COLUMN app_gs_tax_sales_info.yoyRate IS '当年销售额较上年同期同比（%）';
CREATE INDEX IF NOT EXISTS idx_gs_tax_sales_reportNo ON app_gs_tax_sales_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_gs_tax_sales_customerId ON app_gs_tax_sales_info (customerId);
CREATE UNIQUE INDEX IF NOT EXISTS uk_gs_tax_sales_biz ON app_gs_tax_sales_info (reportNo, customerId, taxPeriod);

-- =====================================================================
-- V1.23 新增表2：app_gs_finance_data_info（国税财务数据表，21 字段）
-- =====================================================================
CREATE TABLE IF NOT EXISTS app_gs_finance_data_info (
    id                    BIGINT NOT NULL AUTO_INCREMENT,
    reportNo              VARCHAR(64) NOT NULL,
    customerId            VARCHAR(64),
    customerName          VARCHAR(128),
    reportScope           VARCHAR(64),
    beforeYear            VARCHAR(32),
    lastYear              VARCHAR(32),
    thisYear              VARCHAR(32),
    gfRevenue             DECIMAL(18,2),
    lastYearRevenue       DECIMAL(18,2),
    beforeYearRevenue     DECIMAL(18,2),
    gfReceivable          DECIMAL(18,2),
    lastYearReceivable    DECIMAL(18,2),
    beforeYearReceivable  DECIMAL(18,2),
    gfPayable             DECIMAL(18,2),
    lastYearPayable       DECIMAL(18,2),
    beforeYearPayable     DECIMAL(18,2),
    gfInventory           DECIMAL(18,2),
    lastYearInventory     DECIMAL(18,2),
    beforeYearInventory   DECIMAL(18,2),
    inputtime             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_gs_finance_data_info IS '国税财务数据表';
COMMENT ON COLUMN app_gs_finance_data_info.id IS 'id';
COMMENT ON COLUMN app_gs_finance_data_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_gs_finance_data_info.customerId IS '客户编号';
COMMENT ON COLUMN app_gs_finance_data_info.customerName IS '客户名称';
COMMENT ON COLUMN app_gs_finance_data_info.reportScope IS '财报口径';
COMMENT ON COLUMN app_gs_finance_data_info.beforeYear IS '前年日期';
COMMENT ON COLUMN app_gs_finance_data_info.lastYear IS '去年日期';
COMMENT ON COLUMN app_gs_finance_data_info.thisYear IS '最新一期日期';
COMMENT ON COLUMN app_gs_finance_data_info.gfRevenue IS '最近一期营收（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.lastYearRevenue IS '去年营收（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.beforeYearRevenue IS '前年营收（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.gfReceivable IS '最近一期应收账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.lastYearReceivable IS '去年应收账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.beforeYearReceivable IS '前年应收账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.gfPayable IS '最近一期应付账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.lastYearPayable IS '去年应付账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.beforeYearPayable IS '前年应付账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.gfInventory IS '最近一期存货（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.lastYearInventory IS '去年存货（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.beforeYearInventory IS '前年存货（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_gs_finance_data_reportNo ON app_gs_finance_data_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_gs_finance_data_customerId ON app_gs_finance_data_info (customerId);
CREATE UNIQUE INDEX IF NOT EXISTS uk_gs_finance_data_biz ON app_gs_finance_data_info (reportNo, customerId, reportScope);

CREATE TABLE IF NOT EXISTS app_guofa_report_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    dataDate               VARCHAR(32),
    beforeYear             VARCHAR(32),
    lastYear               VARCHAR(32),
    thisYear               VARCHAR(32),
    gfRevenue              DECIMAL(18,2),
    lastYearRevenue        DECIMAL(18,2),
    beforeYearRevenue      DECIMAL(18,2),
    gfReceivable           DECIMAL(18,2),
    lastYearReceivable     DECIMAL(18,2),
    beforeYearReceivable   DECIMAL(18,2),
    gfPayable              DECIMAL(18,2),
    lastYearPayable        DECIMAL(18,2),
    beforeYearPayable      DECIMAL(18,2),
    gfInventory            DECIMAL(18,2),
    lastYearInventory      DECIMAL(18,2),
    beforeYearInventory    DECIMAL(18,2),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_guofa_report_info IS '国发征信信息表';
COMMENT ON COLUMN app_guofa_report_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_guofa_report_info.customerId IS '客户编号';
COMMENT ON COLUMN app_guofa_report_info.customerName IS '客户名称';
COMMENT ON COLUMN app_guofa_report_info.dataDate IS '数据日期';
COMMENT ON COLUMN app_guofa_report_info.beforeYear IS '前年日期';
COMMENT ON COLUMN app_guofa_report_info.lastYear IS '去年日期';
COMMENT ON COLUMN app_guofa_report_info.thisYear IS '最新一期日期';
COMMENT ON COLUMN app_guofa_report_info.gfRevenue IS '最近一期营收（万元）';
COMMENT ON COLUMN app_guofa_report_info.lastYearRevenue IS '去年营收（万元）';
COMMENT ON COLUMN app_guofa_report_info.beforeYearRevenue IS '前年营收（万元）';
COMMENT ON COLUMN app_guofa_report_info.gfReceivable IS '最近一期应收账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.lastYearReceivable IS '去年应收账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.beforeYearReceivable IS '前年应收账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.gfPayable IS '最近一期应付账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.lastYearPayable IS '去年应付账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.beforeYearPayable IS '前年应付账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.gfInventory IS '最近一期存货（万元）';
COMMENT ON COLUMN app_guofa_report_info.lastYearInventory IS '去年存货（万元）';
COMMENT ON COLUMN app_guofa_report_info.beforeYearInventory IS '前年存货（万元）';
COMMENT ON COLUMN app_guofa_report_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_guofa_report_info_reportNo ON app_guofa_report_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_guofa_report_info_customerId ON app_guofa_report_info (customerId);

CREATE TABLE IF NOT EXISTS app_loan_plan_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    productType            VARCHAR(32),
    nextPayDate            VARCHAR(32),
    payPrinciPalamt        DECIMAL(18,2),
    payInterestamt         DECIMAL(18,2),
    payFineAmt             DECIMAL(18,2),
    compoundInterest       DECIMAL(18,2),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_loan_plan_info IS '贷款产品还本付息计划表';
COMMENT ON COLUMN app_loan_plan_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_loan_plan_info.customerId IS '客户编号';
COMMENT ON COLUMN app_loan_plan_info.customerName IS '客户名称';
COMMENT ON COLUMN app_loan_plan_info.productType IS '产品类型（码值：固贷/房地产开发贷款）';
COMMENT ON COLUMN app_loan_plan_info.nextPayDate IS '下次还款日';
COMMENT ON COLUMN app_loan_plan_info.payPrinciPalamt IS '下次还款本金（万元）';
COMMENT ON COLUMN app_loan_plan_info.payInterestamt IS '下次还款利息（万元）';
COMMENT ON COLUMN app_loan_plan_info.payFineAmt IS '下次还款罚息（万元）';
COMMENT ON COLUMN app_loan_plan_info.compoundInterest IS '下次还款复利（万元）';
COMMENT ON COLUMN app_loan_plan_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_loan_plan_info_reportNo ON app_loan_plan_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_loan_plan_info_customerId ON app_loan_plan_info (customerId);
CREATE TABLE IF NOT EXISTS app_specific_loan_operate_check_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    objectName             VARCHAR(64),
    balance                DECIMAL(18,2),
    businessSum            DECIMAL(18,2),
    contractNo             VARCHAR(64),
    duebillTotalBusinessSum DECIMAL(18,2),
    expectation            VARCHAR(64),
    expectation2           VARCHAR(64),
    ifChange               VARCHAR(32),
    ifDown                 VARCHAR(32),
    ifDownExplain          TEXT,
    ifOpenAccount          VARCHAR(32),
    ifPledge               VARCHAR(32),
    ifPledgeExplain        TEXT,
    ifSign                 VARCHAR(32),
    ifSupervise            VARCHAR(32),
    income                 DECIMAL(18,2),
    incomeCompare          VARCHAR(64),
    indexYear              INT,
    indexYearCompare       INT,
    lastIncome             DECIMAL(18,2),
    lastIncomeCompare      VARCHAR(64),
    lastLesseeCount        INT,
    lastLesseeCountCompare VARCHAR(64),
    lastOperateCDIncomeCondition TEXT,
    lastOperateIncomeCondition   TEXT,
    lesseeCount            INT,
    lesseeCountCompare     VARCHAR(64),
    nominalBalanceSum      DECIMAL(18,2),
    operateCDIncomeCondition     TEXT,
    operateIncomeCondition  TEXT,
    productBelongName      VARCHAR(128),
    productName            VARCHAR(128),
    purpose                VARCHAR(128),
    repaySum               DECIMAL(18,2),
    signExplain            TEXT,
    superviseExplain       TEXT,
    vouchType              VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_specific_loan_operate_check_info IS '特定贷款检查表-经营收入类（经营性物业贷款/厂房通贷款，检查租金经营收入/租户/出租预期/抵押物/监管）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_specific_loan_operate_check_info.customerId IS '客户编号';
COMMENT ON COLUMN app_specific_loan_operate_check_info.customerName IS '客户名称';
COMMENT ON COLUMN app_specific_loan_operate_check_info.objectName IS '对象名称（码值：经营性物业贷款/厂房通贷款）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.balance IS '用信余额（万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.businessSum IS '授信金额（万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.contractNo IS '业务合同编号';
COMMENT ON COLUMN app_specific_loan_operate_check_info.duebillTotalBusinessSum IS '用信金额（万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.expectation IS '出租情况是否符合预期（码值：是/否，文本结论）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.expectation2 IS '物业收入是否符合预期（码值：是/否，接口字段名保留）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifChange IS '出租情况或物业使用情况是否较授信时发生变化（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifDown IS '抵押物价值是否有显著下降（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifDownExplain IS '抵押物价值显著下降说明';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifOpenAccount IS '是否开立监管账户（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifPledge IS '抵押物是否存在查封或其他抵押的情况（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifPledgeExplain IS '抵押物查封或其他抵押情况说明';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifSign IS '租金监管协议是否已签署（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifSupervise IS '物业经营收入是否需要监管（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.income IS '承贷物业的经营收入（本次检查，万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.incomeCompare IS '承贷物业的经营收入与业务申报方案相比（结论文本）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.indexYear IS '年份（本次检查年度，如2026）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.indexYearCompare IS '比较年份（如2025）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastIncome IS '经营收入（上年/前次，万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastIncomeCompare IS '经营收入与业务申报方案相比（上年/前次）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastLesseeCount IS '租户租数（前次/上年）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastLesseeCountCompare IS '租户租数与业务申报方案相比（前次/上年）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastOperateCDIncomeCondition IS '承贷物业的经营收入前次检查情况';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastOperateIncomeCondition IS '前次物业收入及还款来源分析';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lesseeCount IS '租户租数（本次）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lesseeCountCompare IS '租户租数与业务申报方案相比（本次）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.nominalBalanceSum IS '用信敞口余额（万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.operateCDIncomeCondition IS '承贷物业的经营收入本次检查情况';
COMMENT ON COLUMN app_specific_loan_operate_check_info.operateIncomeCondition IS '物业收入及还款来源分析（本次）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.productBelongName IS '产品归属';
COMMENT ON COLUMN app_specific_loan_operate_check_info.productName IS '基础产品';
COMMENT ON COLUMN app_specific_loan_operate_check_info.purpose IS '用途';
COMMENT ON COLUMN app_specific_loan_operate_check_info.repaySum IS '已还本金（万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.signExplain IS '租金监管协议签署说明';
COMMENT ON COLUMN app_specific_loan_operate_check_info.superviseExplain IS '开立监管账户说明';
COMMENT ON COLUMN app_specific_loan_operate_check_info.vouchType IS '担保方式';
COMMENT ON COLUMN app_specific_loan_operate_check_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_specific_loan_operate_check_info_reportNo ON app_specific_loan_operate_check_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_specific_loan_operate_check_info_customerId ON app_specific_loan_operate_check_info (customerId);

CREATE TABLE IF NOT EXISTS app_specific_loan_project_check_info (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    reportNo               VARCHAR(64) NOT NULL,
    customerId             VARCHAR(64),
    customerName           VARCHAR(128),
    objectName             VARCHAR(64),
    balance                DECIMAL(18,2),
    businessSum            DECIMAL(18,2),
    capitalCheckCondition  TEXT,
    capitalFundInvoiced    DECIMAL(18,2),
    capitalFundUnInvoiced  DECIMAL(18,2),
    capitalFundUsed        DECIMAL(18,2),
    contractNo             VARCHAR(64),
    duebillTotalBusinessSum DECIMAL(18,2),
    explain                TEXT,
    ifBuild                VARCHAR(32),
    ifConstructionExpect   VARCHAR(32),
    ifGetPermission        VARCHAR(32),
    ifMatch                VARCHAR(32),
    ifOpenAccount          VARCHAR(32),
    ifOperate              VARCHAR(32),
    ifOverInvest           VARCHAR(32),
    ifRunExpect            VARCHAR(32),
    ifSign                 VARCHAR(32),
    lastCapitalCheckCondition  TEXT,
    lastPurchaseCheckCondition TEXT,
    lastRunCheckCondition     TEXT,
    lastScheduleCheckCondition TEXT,
    lastSuperviseCheckCondition TEXT,
    loanFundInvoiced       DECIMAL(18,2),
    loanFundUnInvoiced     DECIMAL(18,2),
    loanFundUsed           DECIMAL(18,2),
    nominalBalanceSum      DECIMAL(18,2),
    otherFundInvoiced      DECIMAL(18,2),
    otherFundUnInvoiced    DECIMAL(18,2),
    otherFundUsed          DECIMAL(18,2),
    overInvest             TEXT,
    productBelongName      VARCHAR(128),
    productName            VARCHAR(128),
    projectBeginDate       VARCHAR(32),
    projectFinishDate      VARCHAR(32),
    purchaseCheckCondition TEXT,
    purpose                VARCHAR(128),
    repaySum               DECIMAL(18,2),
    runCheckCondition      TEXT,
    scheduleCheckCondition TEXT,
    superviseCheckCondition TEXT,
    totalInvestInvoiced    DECIMAL(18,2),
    totalInvestUnInvoiced  DECIMAL(18,2),
    totalInvestUsed        DECIMAL(18,2),
    vouchType              VARCHAR(32),
    inputtime              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_specific_loan_project_check_info IS '特定贷款检查表-项目类（固定资产贷款/房地产开发贷款，检查项目资本金/建设进度/资金开票使用/超投/预售）';
COMMENT ON COLUMN app_specific_loan_project_check_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_specific_loan_project_check_info.customerId IS '客户编号';
COMMENT ON COLUMN app_specific_loan_project_check_info.customerName IS '客户名称';
COMMENT ON COLUMN app_specific_loan_project_check_info.objectName IS '对象名称（码值：固定资产/房地产开发贷款）';
COMMENT ON COLUMN app_specific_loan_project_check_info.balance IS '用信余额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.businessSum IS '授信金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.capitalCheckCondition IS '项目资本金情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.capitalFundInvoiced IS '资本金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.capitalFundUnInvoiced IS '资本金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.capitalFundUsed IS '资本金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.contractNo IS '业务合同编号';
COMMENT ON COLUMN app_specific_loan_project_check_info.duebillTotalBusinessSum IS '用信金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.explain IS '说明（项目情况说明）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifBuild IS '是否建设期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifConstructionExpect IS '建设期进度是否符合预期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifGetPermission IS '是否取得预售证（码值：是/否/不涉及）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifMatch IS '资金使用是否与项目进度匹配（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifOpenAccount IS '是否开立监管账户（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifOperate IS '是否运营期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifOverInvest IS '是否存在超投情况（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifRunExpect IS '运营是否符合预期（码值：是/否/不涉及）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifSign IS '资金监管协议是否已签署（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.lastCapitalCheckCondition IS '项目资本金情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.lastPurchaseCheckCondition IS '建安工程或设备采购支出情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.lastRunCheckCondition IS '运营检查前次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.lastScheduleCheckCondition IS '项目建设进度前次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.lastSuperviseCheckCondition IS '资金监管情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.loanFundInvoiced IS '贷款资金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.loanFundUnInvoiced IS '贷款资金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.loanFundUsed IS '贷款资金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.nominalBalanceSum IS '用信敞口余额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.otherFundInvoiced IS '其他资金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.otherFundUnInvoiced IS '其他资金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.otherFundUsed IS '其他资金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.overInvest IS '超投情况说明';
COMMENT ON COLUMN app_specific_loan_project_check_info.productBelongName IS '产品归属';
COMMENT ON COLUMN app_specific_loan_project_check_info.productName IS '基础产品';
COMMENT ON COLUMN app_specific_loan_project_check_info.projectBeginDate IS '项目启动年月';
COMMENT ON COLUMN app_specific_loan_project_check_info.projectFinishDate IS '（预计）项目完工年月';
COMMENT ON COLUMN app_specific_loan_project_check_info.purchaseCheckCondition IS '建安工程或设备采购支出情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.purpose IS '用途';
COMMENT ON COLUMN app_specific_loan_project_check_info.repaySum IS '已还本金（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.runCheckCondition IS '运营检查本次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.scheduleCheckCondition IS '项目建设进度本次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.superviseCheckCondition IS '资金监管情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.totalInvestInvoiced IS '总投资已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.totalInvestUnInvoiced IS '总投资未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.totalInvestUsed IS '总投资已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.vouchType IS '担保方式';
COMMENT ON COLUMN app_specific_loan_project_check_info.inputtime IS '入库时间';
CREATE INDEX IF NOT EXISTS idx_specific_loan_project_check_info_reportNo ON app_specific_loan_project_check_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_specific_loan_project_check_info_customerId ON app_specific_loan_project_check_info (customerId);

-- ============================================================
-- 二、新增模块：财务指标预定义表（自动译 + 另起共存，按用户确认）
-- 设计依据：《新增财务指标表表结构.xlsx》
-- 行级属性已自带：同比/较年初变动/增幅由查询层加工或上游直给；本期值字段为落表主体
-- ============================================================

CREATE TABLE IF NOT EXISTS app_finance_indicator_info (
    id                              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo                        VARCHAR(64) NOT NULL,
    customerId                      VARCHAR(64),
    customerName                    VARCHAR(128),
    finReportNo                     VARCHAR(64),
    accountMonth                    VARCHAR(32),
    reportScope                     VARCHAR(64),
    reportPeriod                    VARCHAR(64),
    auditFlag                       VARCHAR(32),
    currency                        VARCHAR(32),
    monetaryUnit                    VARCHAR(32),
    reportStatusName                VARCHAR(64),
    reportStatus                    VARCHAR(64),
    inputtime                       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reportTypeNo                    VARCHAR(64),
    reportTypeName                  VARCHAR(128),
    sheetNo                         VARCHAR(64),
    revenue                         DECIMAL(18,2),
    revenueYoy                      DECIMAL(12,4),
    netProfit                       DECIMAL(18,2),
    netProfitYoy                    DECIMAL(12,4),
    paidInCapital                   DECIMAL(18,2),
    totalEquity                     DECIMAL(18,2),
    accountsReceivable              DECIMAL(18,2),
    arChangeFromYearStart           DECIMAL(18,2),
    arChangeFromYearStartRate       DECIMAL(12,4),
    otherReceivable                 DECIMAL(18,2),
    orChangeFromYearStart           DECIMAL(18,2),
    orChangeFromYearStartRate       DECIMAL(12,4),
    arOrTotalAssetRatio             DECIMAL(12,4),
    shortLoan                       DECIMAL(18,2),
    shortLoanChangeFromYearStart    DECIMAL(18,2),
    shortLoanChangeFromYearStartRate DECIMAL(12,4),
    longLoan                        DECIMAL(18,2),
    longLoanChangeFromYearStart     DECIMAL(18,2),
    longLoanChangeFromYearStartRate DECIMAL(12,4),
    longLoanDueWithin1Y             DECIMAL(18,2),
    salesLoanRatio                 DECIMAL(12,4),
    notesPayable                     DECIMAL(18,2),
    notesPayableChangeFromYearStart  DECIMAL(18,2),
    notesPayableChangeFromYearStartRate DECIMAL(12,4),
    otherPayable                    DECIMAL(18,2),
    otherPayableChangeFromYearStart DECIMAL(18,2),
    otherPayableChangeFromYearStartRate DECIMAL(12,4),
    slTotalLoanYoy                  DECIMAL(12,4),
    arYoy                           DECIMAL(12,4),
    arTurnoverDays                  INT,
    inventoryTurnoverDays           INT,
    inventoryYoy                    DECIMAL(12,4),
    accountsPayable                 DECIMAL(18,2),
    inventory                       DECIMAL(18,2),
    debtRatio                       DECIMAL(12,4),
    salesProfitRatio                DECIMAL(12,4),
    netProfitRatio                  DECIMAL(12,4),
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_finance_indicator_info IS '财务指标预定义表（宽表纵表，一期一行一指标口径，与 app_finance_index_info EAV 宽表并存；数据来源：附件《新增财务指标表表结构.xlsx》按"见名知意"自动译）';
COMMENT ON COLUMN app_finance_indicator_info.reportNo IS '报告编号';
COMMENT ON COLUMN app_finance_indicator_info.customerId IS '客户编号';
COMMENT ON COLUMN app_finance_indicator_info.customerName IS '客户名称';
COMMENT ON COLUMN app_finance_indicator_info.finReportNo IS '财报编号';
COMMENT ON COLUMN app_finance_indicator_info.accountMonth IS '会计月';
COMMENT ON COLUMN app_finance_indicator_info.reportScope IS '报表口径（码值：合并/本部）';
COMMENT ON COLUMN app_finance_indicator_info.reportPeriod IS '报表周期（码值：年报/半年报/季报/月报）';
COMMENT ON COLUMN app_finance_indicator_info.auditFlag IS '是否审计（码值：是/否）';
COMMENT ON COLUMN app_finance_indicator_info.currency IS '报表币种';
COMMENT ON COLUMN app_finance_indicator_info.monetaryUnit IS '货币单位（码值：元/千/万，样例为万）';
COMMENT ON COLUMN app_finance_indicator_info.reportStatusName IS '报表状态中文';
COMMENT ON COLUMN app_finance_indicator_info.reportStatus IS '报表状态码值';
COMMENT ON COLUMN app_finance_indicator_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_finance_indicator_info.reportTypeNo IS '报表类型';
COMMENT ON COLUMN app_finance_indicator_info.reportTypeName IS '报表类型名称';
COMMENT ON COLUMN app_finance_indicator_info.sheetNo IS '科目所在财报类型';
COMMENT ON COLUMN app_finance_indicator_info.revenue IS '营业收入（万元）';
COMMENT ON COLUMN app_finance_indicator_info.revenueYoy IS '营业收入同比（%）';
COMMENT ON COLUMN app_finance_indicator_info.netProfit IS '净利润（万元）';
COMMENT ON COLUMN app_finance_indicator_info.netProfitYoy IS '净利润同比（%）';
COMMENT ON COLUMN app_finance_indicator_info.paidInCapital IS '实收资本（万元）';
COMMENT ON COLUMN app_finance_indicator_info.totalEquity IS '所有者权益合计（万元）';
COMMENT ON COLUMN app_finance_indicator_info.accountsReceivable IS '应收账款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.arChangeFromYearStart IS '应收账款较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.arChangeFromYearStartRate IS '应收账款较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.otherReceivable IS '其他应收款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.orChangeFromYearStart IS '其他应收款较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.orChangeFromYearStartRate IS '其他应收款较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.arOrTotalAssetRatio IS '应收账款和其他应收款合计占总资产比例（%）';
COMMENT ON COLUMN app_finance_indicator_info.shortLoan IS '短期借款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.shortLoanChangeFromYearStart IS '短期借款较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.shortLoanChangeFromYearStartRate IS '短期借款较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.longLoan IS '长期借款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.longLoanChangeFromYearStart IS '长期借款较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.longLoanChangeFromYearStartRate IS '长期借款较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.longLoanDueWithin1Y IS '一年内到期的长期借款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.salesLoanRatio IS '销贷比';
COMMENT ON COLUMN app_finance_indicator_info.notesPayable IS '应付票据（万元）';
COMMENT ON COLUMN app_finance_indicator_info.notesPayableChangeFromYearStart IS '应付票据较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.notesPayableChangeFromYearStartRate IS '应付票据较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.otherPayable IS '其他应付款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.otherPayableChangeFromYearStart IS '其他应付款较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.otherPayableChangeFromYearStartRate IS '其他应付款较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.slTotalLoanYoy IS '短期借款和长期借款合计同比（%）';
COMMENT ON COLUMN app_finance_indicator_info.arYoy IS '应收账款同比（%）';
COMMENT ON COLUMN app_finance_indicator_info.arTurnoverDays IS '应收账款周转天数';
COMMENT ON COLUMN app_finance_indicator_info.inventoryTurnoverDays IS '存货周转天数';
COMMENT ON COLUMN app_finance_indicator_info.inventoryYoy IS '存货同比（%）';
COMMENT ON COLUMN app_finance_indicator_info.accountsPayable IS '应付账款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.inventory IS '存货（万元）';
COMMENT ON COLUMN app_finance_indicator_info.debtRatio IS '资产负债率（%）';
COMMENT ON COLUMN app_finance_indicator_info.salesProfitRatio IS '销售利率（%）';
COMMENT ON COLUMN app_finance_indicator_info.netProfitRatio IS '净利率（%）';
CREATE INDEX IF NOT EXISTS idx_finance_indicator_info_reportNo ON app_finance_indicator_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_finance_indicator_info_customerId ON app_finance_indicator_info (customerId);
CREATE UNIQUE INDEX IF NOT EXISTS uk_finance_indicator_info_biz ON app_finance_indicator_info (reportNo, customerId, finReportNo, accountMonth, reportScope, reportPeriod, reportTypeNo);

-- =====================================================================
-- V1.20 新增表：app_credit_approval_manage_req_info（授信批复管理要求表，9 字段）
-- =====================================================================
CREATE TABLE IF NOT EXISTS app_credit_approval_manage_req_info (
    id BIGINT NOT NULL AUTO_INCREMENT,
    reportno VARCHAR(64) NOT NULL,
    customerid VARCHAR(64) DEFAULT NULL,
    customername VARCHAR(255) DEFAULT NULL,
    inputtime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    swqNo VARCHAR(32) DEFAULT NULL,
    `CONDITION` TEXT DEFAULT NULL,
    PELATIVESERIALNO VARCHAR(64) DEFAULT NULL,
    checkDate DATE DEFAULT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_credit_approval_manage_req_info IS '授信批复管理要求表';
COMMENT ON COLUMN app_credit_approval_manage_req_info.id IS 'id';
COMMENT ON COLUMN app_credit_approval_manage_req_info.reportno IS '报告编号';
COMMENT ON COLUMN app_credit_approval_manage_req_info.customerid IS '客户编号';
COMMENT ON COLUMN app_credit_approval_manage_req_info.customername IS '客户名称';
COMMENT ON COLUMN app_credit_approval_manage_req_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_credit_approval_manage_req_info.swqNo IS '序号';
COMMENT ON COLUMN app_credit_approval_manage_req_info.CONDITION IS '后续管理要求';
COMMENT ON COLUMN app_credit_approval_manage_req_info.PELATIVESERIALNO IS '对象';
COMMENT ON COLUMN app_credit_approval_manage_req_info.checkDate IS '检查时间';
CREATE INDEX IF NOT EXISTS idx_credit_approval_manage_req_reportNo ON app_credit_approval_manage_req_info (reportno);
CREATE INDEX IF NOT EXISTS idx_credit_approval_manage_req_customerId ON app_credit_approval_manage_req_info (customerid);
