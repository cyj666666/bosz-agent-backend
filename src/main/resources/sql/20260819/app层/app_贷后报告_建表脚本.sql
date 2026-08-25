-- =====================================================================
-- 苏州银行 对公客户日常定期检查（贷后）报告 数据表结构 V1.0
-- 数据库：高斯DB（GaussDB，兼容MySQL模式）
-- 设计依据：《数据映射细化V2.xlsx》
-- 共31张表（报告主表1 + 公共基础表11 + 模块明细表19）
-- 设计原则：公共+模块两层、一期一行、沿用J列字段名+驼峰；经验库规则所需源数据见正文模块表
-- 公共列：id / reportNo / customerId / customerName / inputtime
-- =====================================================================

-- ============================================================
-- 一、报告层（1张）
-- ============================================================

-- 报告主表：一次贷后报告一条记录，所有明细表的入口
CREATE TABLE IF NOT EXISTS app_report_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号（一次贷后报告的记录号）',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    reportTitle     VARCHAR(128) COMMENT '报告标题',
    checkTaskNo     VARCHAR(64) COMMENT '日检任务编号',
    reportDate      VARCHAR(32) COMMENT '报告日期（贷后检查日）',
    reportStatus    VARCHAR(32) COMMENT '报告状态（生成中/已生成/已审批）',
    generatorName   VARCHAR(64) COMMENT '生成人',
    generateTime    TIMESTAMP COMMENT '生成时间',
    approveStatus   VARCHAR(32) COMMENT '审批状态（码值：待审批/审批通过/审批驳回（码值待确认））',
    approveOpinion  TEXT COMMENT '审批意见',
    approveTime     TIMESTAMP COMMENT '审批时间',
    reportUrl       VARCHAR(256) COMMENT '报告链接',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_report_no (reportNo)
) COMMENT '贷后报告主表';

-- ============================================================
-- 二、公共基础表（10张）：跨模块复用的元属性与实体
-- ============================================================

-- 客户工商概况：二、客户基本情况-工商情况及股权结构 / 经验库规则复用
CREATE TABLE IF NOT EXISTS app_customer_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    legalPerson     VARCHAR(128) COMMENT '法定代表人',
    registerCapital DECIMAL(18,2) COMMENT '注册资本（万元）',
    paidInCapital   DECIMAL(18,2) COMMENT '实收资本（万元）',
    industryType    VARCHAR(64) COMMENT '行业分类（码值：GB/T 4754 行业代码，码值待确认）',
    holdType        VARCHAR(64) COMMENT '控股类型（码值：国有绝对控股/国有相对控股/集体绝对控股/集体相对控股（国营），其余为民营）',
    actualController VARCHAR(128) COMMENT '实际控制人',
    officeAddress   VARCHAR(256) COMMENT '办公地址',
    businessScope   TEXT COMMENT '经营范围',
    dangerLevel     VARCHAR(64) COMMENT '十级分类（码值：银行十级分类（1-4正常/5-6关注/7-8次级可疑/9-10损失，具体码值待确认））',
    warningLevel    VARCHAR(64) COMMENT '预警等级（码值：高/中/低，码值待确认）',
    isStateOwned    VARCHAR(64) COMMENT '是否国资/国有担保（码值：是/否（由控股类型holdType判断））',
    isFakeStateOwned VARCHAR(64) COMMENT '是否假冒国企（码值：是/否）',
    isListedCompany VARCHAR(32) COMMENT '借款人是否上市公司（码值：是/否，中台接口）',
    groupName       VARCHAR(128) COMMENT '所属集团名称',
    isTechCompany   VARCHAR(64) COMMENT '是否科创企业（码值：是/否）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '客户工商概况表';

-- 工商登记信息（客户级）：工商口径基础信息，一行一客户一快照；股东明细见 app_ic_shareholder_info
CREATE TABLE IF NOT EXISTS app_ic_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    snapshot_type   VARCHAR(32) COMMENT '快照类型（latest最新/atCredit授信时）',
    icLegalPerson   VARCHAR(128) COMMENT '工商法定代表人',
    icRegisterCapital DECIMAL(18,2) COMMENT '工商注册资本（万元）',
    icPaidInCapital DECIMAL(18,2) COMMENT '工商实缴资本（万元）',
    icBeneficiaryName VARCHAR(128) COMMENT '工商受益人名称',
    systemActualController VARCHAR(128) COMMENT '系统实际控制人（多时点快照，授信时/最新）',
    icBeneficiaryPercent DECIMAL(12,4) COMMENT '工商受益人持股比例（%）',
    isStateOwned    VARCHAR(64) COMMENT '是否国有企业（工商口径）（码值：是/否（工商口径））',
    isFakeStateOwned VARCHAR(64) COMMENT '是否假冒国企（工商口径）（码值：是/否（工商口径））',
    cancellationDate VARCHAR(32) COMMENT '注销日期',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '工商登记信息表（客户级）';

-- 工商股东明细（股东级）：一行一股东一快照，支撑股权变更/口径对比规则
CREATE TABLE IF NOT EXISTS app_ic_shareholder_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    snapshot_type   VARCHAR(32) COMMENT '快照类型（latest最新/atCredit授信时）',
    icShareholderName VARCHAR(128) COMMENT '工商股东名称',
    icStockNum      INT COMMENT '工商股东持股数',
    icStockPercent  DECIMAL(12,4) COMMENT '工商股东持股比例（%）',
    icAmount        DECIMAL(18,2) COMMENT '工商股东出资金额（万元）',
    changeTime      VARCHAR(32) COMMENT '股权变更时间（授信时点后的变更）',
    percentBefore   DECIMAL(12,4) COMMENT '变更前持股比例（%）',
    percentAfter    DECIMAL(12,4) COMMENT '变更后持股比例（%）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '工商股东明细表';

-- 股东股权：工商情况及股权结构-股东 / 经验库股权变更规则
CREATE TABLE IF NOT EXISTS app_shareholder_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    name            VARCHAR(128) COMMENT '股东名称',
    stock_num       INT COMMENT '持股数',
    amount          DECIMAL(18,2) COMMENT '应出资金额（万元）',
    stock_percent   DECIMAL(12,4) COMMENT '持股比例（%）',
    is_quoted      VARCHAR(32) COMMENT '是否已出资（码值：是/否）',
    is_state_owned  VARCHAR(64) COMMENT '是否国资股东（码值：是/否）',
    is_fake_state_owned VARCHAR(32) COMMENT '股东假冒国企标签（码值：是/否；苏企查/中台按股东主体查询，仅企业股东有值，自然人股东为空）',
    is_listed_company VARCHAR(32) COMMENT '股东是否上市公司（码值：是/否，中台按股东主体查询）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '股东股权信息表';

-- 授信用信概况：三、业务基本情况-用信情况
CREATE TABLE IF NOT EXISTS app_credit_use_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    creditSum       DECIMAL(18,2) COMMENT '授信金额（万元）',
    balance         DECIMAL(18,2) COMMENT '总余额（万元）',
    exposureAmount  DECIMAL(18,2) COMMENT '敞口金额（万元）',
    limitBalance    DECIMAL(18,2) COMMENT '敞口余额（万元）',
    groupAmount     DECIMAL(18,2) COMMENT '集团授信金额（万元）',
    groupBalance    DECIMAL(18,2) COMMENT '集团总余额（万元）',
    isGroup         VARCHAR(32) COMMENT '是否集团客户（码值：是/否）',
    groupName       VARCHAR(128) COMMENT '所属集团名称',
    creditDate      VARCHAR(32) COMMENT '授信日期（授信时点，用于反查报表期）',
    latestOverdueDate VARCHAR(32) COMMENT '企业当前最近一次逾期日期',
    gdOverdueCounts  INT COMMENT '固贷产品近一年历史逾期次数',
    ajOverdueCounts  INT COMMENT '按揭贷款产品近一年历史逾期次数（房开贷暂取此值，待确认）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '授信用信概况表';

-- 借据信息：三、业务基本情况-业务产品情况 / 逾期情况 / 经验库规则
CREATE TABLE IF NOT EXISTS app_loan_receipt_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    loanSerialNo    VARCHAR(64) COMMENT '借据号',
    loanStatus      VARCHAR(64) COMMENT '借据状态（码值：正常/逾期/欠息/结清/呆账（码值待确认））',
    productName     VARCHAR(128) COMMENT '基础产品名称',
    productType     VARCHAR(64) COMMENT '产品类型（基础/组合/固贷/房地产）',
    purposeName     VARCHAR(128) COMMENT '用途',
    balance         DECIMAL(18,2) COMMENT '借据余额（万元）',
    productBelongName VARCHAR(128) COMMENT '产品归属（组合产品）',
    overdueBalance  DECIMAL(18,2) COMMENT '期供欠本金额（万元）',
    overdueInterestAmt DECIMAL(18,2) COMMENT '期供欠息金额（万元）',
    isRestructed    VARCHAR(32) COMMENT '是否重组优化贷款（码值：是/否）',
    extendBalance   DECIMAL(18,2) COMMENT '展期贷款余额（万元）',
    restructedBalance DECIMAL(18,2) COMMENT '重组贷款余额（万元）',
    reorgTimes      INT COMMENT '借新还旧次数',
    reorgBalance    DECIMAL(18,2) COMMENT '借新还旧余额（万元）',
    loanChangeRptCounts INT COMMENT '还款方式变更笔数',
    loanChangeRptBalance DECIMAL(18,2) COMMENT '还款方式变更贷款余额（万元）',
    occurType       VARCHAR(32) COMMENT '发生类型',
    isExtend        VARCHAR(32) COMMENT '是否展期（码值：是/否）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '借据信息表';

-- 预警任务台账：一、总结概述-历史预警意见 / 十一、预警信息和潜在风险 / 经验库
CREATE TABLE IF NOT EXISTS app_early_warning_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    confirmTime     VARCHAR(32) COMMENT '预警本次认定时间',
    inputDate       VARCHAR(32) COMMENT '预警本次发起时间',
    approveStatusName VARCHAR(64) COMMENT '审批状态（码值：审批通过/待审批/驳回（码值待确认））',
    phaseOpinion    TEXT COMMENT '审批意见',
    endTime         VARCHAR(32) COMMENT '审批日期',
    riskTaskType    VARCHAR(64) COMMENT '任务类型（码值：预警任务类型（码值待确认））',
    warnLevel       VARCHAR(64) COMMENT '客户风险等级（码值：高/中/低，码值待确认）',
    riskReason      TEXT COMMENT '风险原因',
    riskReasonCount INT COMMENT '近一年每个风险原因数量',
    riskReasonTodoCount INT COMMENT '近一年每个风险原因待填写数量',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '预警任务台账表';

-- 押品主档：十二、担保情况和潜在风险-押品风险解读
CREATE TABLE IF NOT EXISTS app_collateral_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    owner           VARCHAR(128) COMMENT '权属人',
    clrType         VARCHAR(64) COMMENT '押品类型（码值：不动产/动产/权利类等，码值待确认）',
    clrName         VARCHAR(128) COMMENT '押品名称',
    clrStatus       VARCHAR(64) COMMENT '押品状态（码值：正常/查封/冻结/处置中，码值待确认）',
    valuationDate   VARCHAR(32) COMMENT '押品最新评估日期',
    choiceTypeName  VARCHAR(64) COMMENT '评估方式（评估价/协议作价）',
    evaluateValue   DECIMAL(18,2) COMMENT '评估价值（万元）',
    rightOrder      VARCHAR(64) COMMENT '顺位',
    rightSum        DECIMAL(18,2) COMMENT '权证金额（万元）',
    confirmDate     VARCHAR(32) COMMENT '认定日期',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '押品主档表';

-- 押品他项权利/限制权利：押品风险解读 / 经验库「抵押物多次抵押」规则
CREATE TABLE IF NOT EXISTS app_collateral_mortgage_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    clrName         VARCHAR(128) COMMENT '关联押品名称',
    pledgeSerialNo  VARCHAR(64) COMMENT '不动产登记编号',
    pledgeeName     VARCHAR(128) COMMENT '他项权姓名',
    guaranteeScope  VARCHAR(256) COMMENT '担保范围',
    pledgeTypeName  VARCHAR(64) COMMENT '抵押方式（码值：一般抵押/最高额抵押等，码值待确认）',
    maxCreditorAmt  DECIMAL(18,2) COMMENT '债权数额（万元）',
    startEnd        VARCHAR(64) COMMENT '债务履行期限',
    registerTimestamp VARCHAR(32) COMMENT '设定日期',
    attachmentOrg   VARCHAR(128) COMMENT '限制权人',
    attachmentTypeName VARCHAR(64) COMMENT '查封类型（码值：轮候查封/正式查封等，码值待确认）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '押品他项权利/限制权利表';

-- 结算账户与资产：九、结算情况和潜在风险-我行结算账户与资产情况
CREATE TABLE IF NOT EXISTS app_settle_account_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    accountNo       VARCHAR(64) COMMENT '账号',
    accountStatus   VARCHAR(64) COMMENT '账户状态（码值：正常/冻结/销户，码值待确认）',
    accountBalance  DECIMAL(18,2) COMMENT '账户余额（万元）',
    frozenAmount    DECIMAL(18,2) COMMENT '冻结金额（万元）',
    yearAvgDeposit  DECIMAL(18,2) COMMENT '年日均存款（万元）',
    superviseFlag   VARCHAR(64) COMMENT '监管标识（码值：是/否，码值待确认）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '结算账户与资产表';

-- 贷后意见：一、总结概述-上一次贷后意见（剔除同意、取最新）
CREATE TABLE IF NOT EXISTS app_opinion_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    phaseOpinion    TEXT COMMENT '审批意见',
    endTime         VARCHAR(32) COMMENT '审批日期',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '贷后意见表';

-- ============================================================
-- 三、模块明细表（18张）：与B列模块一一对应，字段=该模块H列要素
-- ============================================================

-- 财报主档：五、指标变化和潜在风险（报表四件套下沉，一期一行）
CREATE TABLE IF NOT EXISTS app_finance_report_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    accountMonth    VARCHAR(32) COMMENT '会计月',
    sheetNo         VARCHAR(64) COMMENT '报表类型（码值：资产负债表/利润表/现金流量表等，码值待确认）',
    reportScope     VARCHAR(64) COMMENT '报表口径（码值：合并/本部）',
    reportPeriod    VARCHAR(64) COMMENT '报表周期（码值：年报/半年报/季报/月报，码值待确认）',
    auditFlag       VARCHAR(32) COMMENT '是否审计（码值：是/否）',
    currency        VARCHAR(32) COMMENT '报表币种',
    reportStatus    VARCHAR(32) COMMENT '报表状态（锁定/未锁定，是否锁定状态判断依据）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId, accountMonth)
) COMMENT '财报主档表（一期一行）';

-- 财务指标值：重点财务指标分析×7模块 / 征信财务交叉解读（一期一行）
CREATE TABLE IF NOT EXISTS app_finance_index_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    accountMonth    VARCHAR(32) COMMENT '报表期（会计月，如202603，一期一行）',
    reportScope     VARCHAR(64) COMMENT '报表口径（码值：合并/本部）',
    indexType       VARCHAR(64) COMMENT '指标类型（金额科目：营收/净利润/实收资本/短期借款/长期借款/一年内到期长期借款/应收账款/其他应收款/应付票据/其他应付款/存货/总资产，单位万元；比率指标：资产负债率/销售利率/净利率，存百分数值，如65.43表示65.43%）',
    indexValue      DECIMAL(18,2) COMMENT '指标本期值（金额科目=万元；比率指标=百分数值，如65.43表示65.43%）',
    yoyValue        DECIMAL(12,4) COMMENT '同比（%）：该期值÷上年同期值−1；行级属性各期行自带，上游计算或加工层预填（默认已有）',
    changeValue     DECIMAL(18,2) COMMENT '较年初变动（万元）：该期值−上年末(12月)值；行级属性各期行自带（默认已有）',
    changeRate      DECIMAL(12,4) COMMENT '较年初增幅（%）：(该期值−上年末值)÷上年末值；行级属性各期行自带（默认已有）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId, indexType, accountMonth, reportScope)
) COMMENT '财务指标值表（一期一行一指标；同比/较年初等对比值由查询层计算，不落表）';
) COMMENT '财务指标值表（一期一行）';

-- 纳税数据：重点财务指标分析-营收（税务及财务交叉类）
CREATE TABLE IF NOT EXISTS app_tax_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    taxPeriod       VARCHAR(32) COMMENT '纳税期（按月，一期一行，如202603）',
    monthlyTaxSales DECIMAL(18,2) COMMENT '每月增值税申报销售额（万元，预留：当前取数以 totalSalesTax 该期累计为准，本字段暂不使用）',
    yoyChange       DECIMAL(18,2) COMMENT '较上年同期变动额（万元）：该期累计−上年同期累计；行级属性各期行自带（如202512行=上年全年vs上上年全年、202603行=本期vs上年同期），默认已有',
    yoyRate         DECIMAL(12,4) COMMENT '较上年同期同比（%）：变动额÷上年同期累计；行级属性各期行自带（同上），默认已有',
    totalSalesTax   DECIMAL(18,2) COMMENT '纳税申请总销售额累计（万元）：该纳税期累计数，如202603行=2026年1-3月累计、202512行=2025年全年累计、202503行=2025年1-3月累计；任何期间累计直接从对应 taxPeriod 行取',
    taxReceivable   DECIMAL(18,2) COMMENT '税务申报应收账款（万元，上游直给，供与财报应收对比；无则NULL）',
    taxPayable      DECIMAL(18,2) COMMENT '税务申报应付账款（万元，上游直给，供与财报应付对比；无则NULL）',
    taxInventory    DECIMAL(18,2) COMMENT '税务申报存货（万元，上游直给，供与财报存货对比；无则NULL）',
    diffWithReport  DECIMAL(18,2) COMMENT '与(本部)报表营收相差（万元）：该期累计纳税−该期本部营收；行级属性各期行自带，默认已有',
    diffRateWithReport DECIMAL(12,4) COMMENT '与(本部)报表营收相差幅度（%）：相差额÷该期本部营收；行级属性各期行自带，默认已有',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId, taxPeriod)
) COMMENT '纳税数据表（增值税申报销售额，按月一期一行；同期对比/同比由查询层计算，不落表）';
) COMMENT '纳税数据表';

-- 企业征信快照：六、征信情况和潜在风险-征信情况（一期一行，查询时间为主键维度）
CREATE TABLE IF NOT EXISTS app_credit_report_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    queryTime       VARCHAR(32) COMMENT '征信查询时间',
    expireDate      VARCHAR(32) COMMENT '征信报告有效期',
    overdueTotal    DECIMAL(18,2) COMMENT '未结清信贷的逾期总额（万元）',
    attentionCreditBal DECIMAL(18,2) COMMENT '未结清关注类信贷余额（万元）',
    badCreditBal    DECIMAL(18,2) COMMENT '未结清不良类借贷余额（万元）',
    attentionGuaranteeBal DECIMAL(18,2) COMMENT '未结清关注类担保交易余额（万元）',
    badGuaranteeBal DECIMAL(18,2) COMMENT '未结清不良类担保交易余额（万元）',
    guaranteeOverdueTotal DECIMAL(18,2) COMMENT '对外担保（相关还款责任）未结清逾期类负债总额（万元）',
    guaranteeAttentionBal DECIMAL(18,2) COMMENT '对外担保（相关还款责任）未结清关注类负债总额（万元）',
    guaranteeBadBal  DECIMAL(18,2) COMMENT '对外担保（相关还款责任）未结清不良类负债总额（万元）',
    extendDebtBal    DECIMAL(18,2) COMMENT '展期债务未结清余额（万元）',
    restructureDebtBal DECIMAL(18,2) COMMENT '重组债务未结清余额（万元）',
    renewDebtBal     DECIMAL(18,2) COMMENT '无还本续贷未结清余额（万元）',
    transferDebtBal  DECIMAL(18,2) COMMENT '其他机构转入未结清余额（万元）',
    newOldDebtBal    DECIMAL(18,2) COMMENT '借新还旧债务未结清余额（万元）',
    nonBankLiabTotal DECIMAL(18,2) COMMENT '在非银机构负债合计（万元，上游直给：qy_fyjg_liab_tot/gr_fyjg_liab_tot）',
    bankLeaseOrgCount INT COMMENT '合作银行及融资租赁机构数（上游直给：qy_hzyh_rzzl_cnt）',
    nonBankHighRateLoan DECIMAL(12,4) COMMENT '非银机构较高利率借款推算利率最大值（%，企业，上游直给：qy_fyjg_gjlv_loan_max；较高利率判断依据）',
    inputtime        TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '企业征信快照表（一期一行）';

-- 征信债务明细：征信解读分析-征信及财务交叉（按债务类型行式，一期一行）
CREATE TABLE IF NOT EXISTS app_credit_debt_detail (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    queryTime       VARCHAR(32) COMMENT '征信查询时间',
debtType VARCHAR(64) COMMENT '债务类型（中长期借款/短期借款/循环透支/贴现/银行承兑汇票/信用证/银行保函/其他担保交易）',
    orgCount        INT COMMENT '未结清机构数合计',
    balance         DECIMAL(18,2) COMMENT '未结清余额合计（万元）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId, debtType)
) COMMENT '征信债务明细表（按类型一期一行）';

-- 担保人：十二、担保情况和潜在风险-（系统填充）
CREATE TABLE IF NOT EXISTS app_guarantor_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    guarantorName   VARCHAR(128) COMMENT '担保人',
    guarantorType   VARCHAR(32) COMMENT '担保人类型（法人/自然人）',
    isStateOwned    VARCHAR(64) COMMENT '是否国资/国有担保',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '担保人信息表';

-- 担保人征信：担保人征信情况 / 担保人征信债务情况
CREATE TABLE IF NOT EXISTS app_guarantor_credit_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    guarantorName   VARCHAR(128) COMMENT '担保人',
    queryTime       VARCHAR(32) COMMENT '征信查询时间',
    totalLoanBal    DECIMAL(18,2) COMMENT '贷款余额合计（万元）',
    operateLoanBal  DECIMAL(18,2) COMMENT '经营性贷款余额合计（万元）',
    consumeLoanBal  DECIMAL(18,2) COMMENT '消费类贷款余额合计（万元）',
    houseLoanBal    DECIMAL(18,2) COMMENT '住房类贷款余额合计（万元）',
    otherLoanBal    DECIMAL(18,2) COMMENT '其他贷款余额合计（万元）',
    totalLoanCount  INT COMMENT '贷款机构数',
    operateLoanCount INT COMMENT '经营性贷款机构数',
    consumeLoanCount INT COMMENT '消费类贷款机构数',
    houseLoanCount  INT COMMENT '住房类贷款机构数',
    otherLoanCount  INT COMMENT '其他贷款机构数',
    bzcBal          DECIMAL(18,2) COMMENT '被追偿余额（万元）',
    badBal          DECIMAL(18,2) COMMENT '呆账余额（万元）',
    loanCurrentOverdue DECIMAL(18,2) COMMENT '贷款当前逾期总金额（万元）',
    cardCurrentOverdue DECIMAL(18,2) COMMENT '贷记卡当前逾期总金额（万元）',
    guaranteeOverdueAmt DECIMAL(18,2) COMMENT '对外担保（相关还款责任）当前逾期金额（万元）',
    nonBankGuaranteeBal DECIMAL(18,2) COMMENT '在非银机构对外担保余额（万元，上游直给：qy_fyjg_dwdb_bal/gr_fyjg_dwdb_bal）',
    nonBankHighRateLoan  DECIMAL(12,4) COMMENT '非银机构较高利率借款推算利率最大值（%，上游直给：qy_fyjg_gjlv_loan_max/gr_fyjg_gjlv_loan_max；较高利率判断依据）',
    guaranteeAbnormalBal DECIMAL(18,2) COMMENT '对外担保（相关还款责任）五级分类非正常余额（万元）',
    extendBal       DECIMAL(18,2) COMMENT '展期债务余额（万元）',
    delayBal        DECIMAL(18,2) COMMENT '落实金融困等政策银行主动延期债务余额（万元）',
    creditAbnormalBal DECIMAL(18,2) COMMENT '未结清信贷五级分类非正常余额（万元）',
    acctAbnormalBal DECIMAL(18,2) COMMENT '未结清账户状态非正常余额（万元）',
    cardAbnormalBal DECIMAL(18,2) COMMENT '未销户贷记卡账户状态非正常余额（万元）',
    guaranteeHkAbnormalBal DECIMAL(18,2) COMMENT '对外担保（相关还款责任）还款状态非正常余额（万元）',
    creditUseRate   DECIMAL(12,4) COMMENT '信用卡使用率（%）',
    guaranteeNetAsset DECIMAL(12,4) COMMENT '对外担保/净资产（%）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId, guarantorName)
) COMMENT '担保人征信表';

-- 征信查询次数：担保人征信查询次数
CREATE TABLE IF NOT EXISTS app_credit_query_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    queryTime       VARCHAR(32) COMMENT '征信查询时间',
    loanQuery12m    INT COMMENT '近一年贷款审批征信查询次数',
    loanQuery6m     INT COMMENT '近6个月贷款审批征信查询次数',
    loanQuery3m     INT COMMENT '近3个月贷款审批征信查询次数',
    cardQuery12m    INT COMMENT '近一年信用卡审批征信查询次数',
    cardQuery6m     INT COMMENT '近6个月信用卡审批征信查询次数',
    cardQuery3m     INT COMMENT '近3个月信用卡审批征信查询次数',
    selfQuery1m     INT COMMENT '近1个月本人查询征信查询次数',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '征信查询次数表';

-- 资金回流：七、资金疑似回流或用途异常-资金回流
CREATE TABLE IF NOT EXISTS app_capital_flow_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    loanSerialNo    VARCHAR(64) COMMENT '借据号',
    capitalCheckTaskType VARCHAR(64) COMMENT '任务类型（码值：资金用途检查任务类型（码值待确认））',
    approveStatus   VARCHAR(64) COMMENT '审批状态（码值：审批通过/待审批/驳回（码值待确认））',
    isPurposeAbnormal VARCHAR(64) COMMENT '是否回流异常（码值：是/否）',
    rectificationSituation VARCHAR(128) COMMENT '整改情况',
    rectificationDeadline VARCHAR(32) COMMENT '整改期限',
    rectificationExplanation TEXT COMMENT '整改情况说明',
    identifyReason  TEXT COMMENT '认定理由',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '资金回流/用途异常表';

-- 受托支付：九、结算情况和潜在风险-我行结算交易对手情况（受托支付明细）
CREATE TABLE IF NOT EXISTS app_entrust_pay_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    paymentMode     VARCHAR(64) COMMENT '支付方式（码值：受托支付/自主支付，码值待确认）',
    payDate         VARCHAR(32) COMMENT '支付日期',
    accountName     VARCHAR(128) COMMENT '收款人名称',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '受托支付明细表';

-- 结算交易对手：前十大借贷方 / 前五大上游客户（行式）
CREATE TABLE IF NOT EXISTS app_settle_counterparty_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    counterpartyName VARCHAR(128) COMMENT '交易对手名称',
    direction       VARCHAR(16) COMMENT '方向（借方/贷方）',
    amount          DECIMAL(18,2) COMMENT '发生额（万元）',
    rankNo          VARCHAR(16) COMMENT '排名（TOP1-10）',
    upstreamFlag    VARCHAR(32) COMMENT '是否前五大上游客户（码值：是/否）',
    remark          VARCHAR(512) COMMENT '交易备注（预留：备注含担保/借款/投资关键字贷方发生额筛选用，接口待补充）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId, direction)
) COMMENT '结算交易对手表';

-- 代发统计：九、结算情况和潜在风险-（系统填充）近12个月代发（一期一行）
CREATE TABLE IF NOT EXISTS app_payroll_stat_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    statMonth       VARCHAR(32) COMMENT '统计月份',
    payrollCount    INT COMMENT '代发人数',
    payrollAmount   DECIMAL(18,2) COMMENT '代发金额（万元）',
    countMom        DECIMAL(12,4) COMMENT '代发人数环比',
    amountMom       DECIMAL(12,4) COMMENT '代发金额环比',
    countYoy        DECIMAL(12,4) COMMENT '代发人数同比',
    amountYoy       DECIMAL(12,4) COMMENT '代发金额同比',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '代发统计表（月粒度）';

-- 现场检查打卡：四、本次日常定期检查开展情况-（系统填充）
CREATE TABLE IF NOT EXISTS app_check_record_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    checkInTime     VARCHAR(32) COMMENT '打卡日期',
    checkInAddress  VARCHAR(256) COMMENT '打卡地址',
    visitObj        VARCHAR(128) COMMENT '拜访对象',
    checkInObj      VARCHAR(128) COMMENT '打卡对象',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '现场检查打卡记录表';

-- 批复后续管理要求：四、本次日常定期检查开展情况-批复解读分析
CREATE TABLE IF NOT EXISTS app_check_opinion_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    conditionDesc   TEXT COMMENT '批复后续管理要求',
    completeStatus  VARCHAR(64) COMMENT '完成情况（码值：已完成/未完成/部分完成（码值待确认））',
    conditionInstruction TEXT COMMENT '情况说明',
    realCompleteTime VARCHAR(32) COMMENT '实际完成日期',
    itemCategory    VARCHAR(64) COMMENT '事项类别',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '批复后续管理要求表';

-- 日常检查综合指标：四、本次日常定期检查开展情况-综合选项分析
CREATE TABLE IF NOT EXISTS app_check_index_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    chineseId       VARCHAR(64) COMMENT '指标编号',
    chineseName     VARCHAR(128) COMMENT '指标名称',
    yesNo           VARCHAR(32) COMMENT '检查结论（是/否）',
    remark          TEXT COMMENT '说明',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '日常检查综合指标表';

-- 舆情事件明细：一行一舆情事件，支持借款人/股东双主体；[最近一次授信,最新]为时间区间（授信后发生）
CREATE TABLE IF NOT EXISTS app_reputation_event_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    subjectType     VARCHAR(32) COMMENT '主体类型（码值：借款人/股东）',
    subjectName     VARCHAR(128) COMMENT '主体名称（借款人名称/股东名称）',
    eventTime       VARCHAR(32) COMMENT '舆情发生时间',
    eventType       VARCHAR(64) COMMENT '舆情类型（码值：证券市场违规/股票戴帽/退市风险/评级下调/高管无法履职/财务造假/其他，待确认）',
    eventDesc       TEXT COMMENT '舆情事件描述',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '舆情事件明细表';

-- 国发征信信息（国发征信中心，独立数据源）：上游直给营收/应收/应付/存货科目，供与财报科目偏差对比；一行一客户一查询时点
CREATE TABLE IF NOT EXISTS app_guofa_report_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    queryTime       VARCHAR(32) COMMENT '国发征信查询时间',
    gfRevenue       DECIMAL(18,2) COMMENT '国发征信营收（万元，上游直给）',
    gfReceivable    DECIMAL(18,2) COMMENT '国发征信应收账款（万元，上游直给）',
    gfPayable       DECIMAL(18,2) COMMENT '国发征信应付账款（万元，上游直给）',
    gfInventory     DECIMAL(18,2) COMMENT '国发征信存货（万元，上游直给）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId, queryTime)
) COMMENT '国发征信信息表';

-- 贷款产品还本付息计划：固贷/房地产开发贷款产品对象（接口客户级独立对象，一行一客户一产品类型）
CREATE TABLE IF NOT EXISTS app_loan_plan_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    productType     VARCHAR(32) COMMENT '产品类型（码值：固贷/房地产开发贷款）',
    nextPayDate     VARCHAR(32) COMMENT '下次还款日',
    payPrinciPalamt DECIMAL(18,2) COMMENT '下次还款本金（万元）',
    payInterestamt  DECIMAL(18,2) COMMENT '下次还款利息（万元）',
    payFineAmt      DECIMAL(18,2) COMMENT '下次还款罚息（万元）',
    compoundInterest DECIMAL(18,2) COMMENT '下次还款复利（万元）',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '贷款产品还本付息计划表';

-- 特定贷款检查：固定资产/房地产开发贷款/经营性物业贷款/厂房通贷款（接口特定贷款检查数组，一行一客户一贷款对象）
CREATE TABLE IF NOT EXISTS app_specific_loan_check_info (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL COMMENT '报告编号',
    customerId      VARCHAR(64) COMMENT '客户编号',
    customerName    VARCHAR(128) COMMENT '客户名称',
    objectName      VARCHAR(64) COMMENT '对象名称（码值：固定资产/房地产开发贷款/经营性物业贷款/厂房通贷款）',
    productName     VARCHAR(128) COMMENT '基础产品',
    productBelongName VARCHAR(128) COMMENT '产品归属',
    contractNo      VARCHAR(64) COMMENT '业务合同编号',
    businessSum     DECIMAL(18,2) COMMENT '授信金额（万元）',
    balance         DECIMAL(18,2) COMMENT '用信余额（万元）',
    duebillTotalBusinessSum DECIMAL(18,2) COMMENT '用信金额（万元）',
    nominalBalanceSum DECIMAL(18,2) COMMENT '用信敞口余额（万元）',
    repaySum        DECIMAL(18,2) COMMENT '已还本金（万元）',
    purpose         VARCHAR(128) COMMENT '用途',
    vouchType       VARCHAR(32) COMMENT '担保方式',
    projectBeginDate VARCHAR(32) COMMENT '项目启动年月',
    projectFinishDate VARCHAR(32) COMMENT '（预计）项目完工年月',
    ifBulid         VARCHAR(32) COMMENT '是否建设期（码值：是/否）',
    ifConstructionExpect VARCHAR(32) COMMENT '建设期进度是否符合预期（码值：是/否）',
    ifGetPermission VARCHAR(32) COMMENT '是否取得预售证（码值：是/否）',
    ifMatch         VARCHAR(32) COMMENT '资金使用是否与项目进度匹配（码值：是/否）',
    ifOpenAccount   VARCHAR(32) COMMENT '是否开立监管账户（码值：是/否）',
    ifSign          VARCHAR(32) COMMENT '资金监管协议是否已签署（码值：是/否）',
    ifOverInvest    VARCHAR(32) COMMENT '是否存在超投情况（码值：是/否）',
    overInvest      TEXT COMMENT '超投情况说明',
    ifOperate       VARCHAR(32) COMMENT '是否运营期（码值：是/否）',
    ifRunExpect     VARCHAR(32) COMMENT '运营是否符合预期（码值：是/否）',
    scheduleCheckCondition TEXT COMMENT '项目建设进度本次检查情况',
    lastScheduleCheckCondition TEXT COMMENT '项目建设进度前次检查情况',
    capitalCheckCondition TEXT COMMENT '项目资本金情况本次检查情况',
    lastCapitalCheckCondition TEXT COMMENT '项目资本金情况前次检查情况',
    purchaseCheckCondition TEXT COMMENT '建安工程或设备采购支出情况本次检查情况',
    lastPurchaseCheckCondition TEXT COMMENT '建安工程或设备采购支出情况前次检查情况',
    runCheckCondition TEXT COMMENT '运营检查本次检查情况',
    lastRunCheckCondition TEXT COMMENT '运营检查前次检查情况',
    superviseCheckCondition TEXT COMMENT '资金监管情况本次检查情况',
    lastSuperviseCheckCondition TEXT COMMENT '资金监管情况前次检查情况',
    capitalFundInvoiced DECIMAL(18,2) COMMENT '资本金已开票金额（万元）',
    capitalFundUnInvoiced DECIMAL(18,2) COMMENT '资本金未开票金额（万元）',
    capitalFundUsed DECIMAL(18,2) COMMENT '资本金已使用金额（万元）',
    loanFundInvoiced DECIMAL(18,2) COMMENT '贷款资金已开票金额（万元）',
    loanFundUnInvoiced DECIMAL(18,2) COMMENT '贷款资金未开票金额（万元）',
    loanFundUsed DECIMAL(18,2) COMMENT '贷款资金已使用金额（万元）',
    otherFundInvoiced DECIMAL(18,2) COMMENT '其他资金已开票金额（万元）',
    otherFundUnInvoiced DECIMAL(18,2) COMMENT '其他资金未开票金额（万元）',
    otherFundUsed DECIMAL(18,2) COMMENT '其他资金已使用金额（万元）',
    totalInvestInvoiced DECIMAL(18,2) COMMENT '总投资已开票金额（万元）',
    totalInvestUnInvoiced DECIMAL(18,2) COMMENT '总投资未开票金额（万元）',
    totalInvestUsed DECIMAL(18,2) COMMENT '总投资已使用金额（万元）',
    explain         TEXT COMMENT '说明',
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    KEY idx_report (reportNo, customerId)
) COMMENT '特定贷款检查表';

-- ============================================================
-- 说明：风险经验库（C列=经验库）规则所需源数据
-- 规则判断所需数据均来自以上正文模块对应的 28 张表，
-- 具体取数 SQL 见《数据映射细化V4.xlsx》各经验库模块（按B列模块查看）。
-- 规则引擎的命中逻辑与结果存储由公司规则平台自行设计，本表结构不涉及。
-- ============================================================
