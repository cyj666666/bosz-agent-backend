-- =====================================================================
-- 对公检查信息查询接口 · 数据落表 DDL（v3.1）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 语法适配（按实测验证）：
--   1. 建表语句内 不写 列注释/表注释/索引子句
--      （openGauss 兼容模式不支持 MySQL 内联 COMMENT 与表内 INDEX）
--   2. 注释用 PG 风格单独写：COMMENT ON TABLE / COMMENT ON COLUMN
--   3. 索引用 CREATE INDEX IF NOT EXISTS 单独建
--   4. 自增主键：id BIGINT not null AUTO_INCREMENT + 表级 primary key (id)（实测要求）
--
-- 设计约定：
--   - 1 张主表 + 12 张子表，英文字段名 100% 照抄接口材料（驼峰/全大写保持）
--   - 每张表公共字段：reportNo / serialNo / customerId / customerName / inputtime
--   - 子表 mainId 逐层指向直接上级表主键（不建物理外键）
--   - 材料 String -> VARCHAR；Number -> DECIMAL(18,2)；inputtime -> TIMESTAMP（openGauss 无 DATETIME 类型）
--   - reportNo / serialNo / customerId / customerName 四列均建索引
--   - 接口返回直接追加插入，不做去重约束
-- =====================================================================

-- #####################################################################
-- 1. 对公检查信息主表（入参 + 贷后检查详情-基础字段）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_info (
    id            BIGINT not null AUTO_INCREMENT,
    reportNo      VARCHAR(64) NOT NULL,
    serialNo      VARCHAR(64),
    customerId    VARCHAR(64),
    customerName  VARCHAR(128),
    bapSerialNo   VARCHAR(64),
    bapStartDate  VARCHAR(64),
    bapMaturity   VARCHAR(64),
    bapReportNo   VARCHAR(64),
    baReportNo    VARCHAR(64),
    checkDate     VARCHAR(64),
    inputtime     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_info IS '对公检查信息主表（贷后检查详情-基础信息）';
COMMENT ON COLUMN xd_corp_check_info.id IS '主键';
COMMENT ON COLUMN xd_corp_check_info.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_info.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_info.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_info.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_info.bapSerialNo IS '批复编号';
COMMENT ON COLUMN xd_corp_check_info.bapStartDate IS '批复生效日';
COMMENT ON COLUMN xd_corp_check_info.bapMaturity IS '批复到期日';
COMMENT ON COLUMN xd_corp_check_info.bapReportNo IS '贷后检查关联征信报告编号';
COMMENT ON COLUMN xd_corp_check_info.baReportNo IS '授信时点的征信报告编号';
COMMENT ON COLUMN xd_corp_check_info.checkDate IS '检查日期';
COMMENT ON COLUMN xd_corp_check_info.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_info (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_info (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_info (customerName);

-- #####################################################################
-- 2. 批复关联押品表（押品数组 + 最新不动产登记簿记录）
--    mainId -> xd_corp_check_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_collateral (
    id              BIGINT not null AUTO_INCREMENT,
    mainId          BIGINT NOT NULL,
    reportNo        VARCHAR(64) NOT NULL,
    serialNo        VARCHAR(64),
    customerId      VARCHAR(64),
    customerName    VARCHAR(128),
    ClrId           VARCHAR(64),
    ownerId         VARCHAR(64),
    ownerName       VARCHAR(128),
    ClrType         VARCHAR(64),
    ClrName         VARCHAR(128),
    ClrStatus       VARCHAR(64),
    rightOrder      VARCHAR(64),
    rightSum        DECIMAL(18,2),
    valuationDate   VARCHAR(64),
    choiceTypeName  VARCHAR(64),
    evaluateValue   DECIMAL(18,2),
    confirmDate     VARCHAR(64),
    DYQDJ           VARCHAR(64),
    YYDJ            VARCHAR(64),
    CFDJ            VARCHAR(64),
    YGDJ            VARCHAR(64),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_collateral IS '对公检查-批复关联押品表（押品数组+不动产登记簿记录）';
COMMENT ON COLUMN xd_corp_check_collateral.id IS '主键';
COMMENT ON COLUMN xd_corp_check_collateral.mainId IS '关联主表主键id（xd_corp_check_info.id）';
COMMENT ON COLUMN xd_corp_check_collateral.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_collateral.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_collateral.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_collateral.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_collateral.ClrId IS '押品编号';
COMMENT ON COLUMN xd_corp_check_collateral.ownerId IS '权属人客户编号';
COMMENT ON COLUMN xd_corp_check_collateral.ownerName IS '权属人姓名';
COMMENT ON COLUMN xd_corp_check_collateral.ClrType IS '押品类型';
COMMENT ON COLUMN xd_corp_check_collateral.ClrName IS '押品名称';
COMMENT ON COLUMN xd_corp_check_collateral.ClrStatus IS '押品状态';
COMMENT ON COLUMN xd_corp_check_collateral.rightOrder IS '顺位';
COMMENT ON COLUMN xd_corp_check_collateral.rightSum IS '权证金额';
COMMENT ON COLUMN xd_corp_check_collateral.valuationDate IS '押品最新评估日期';
COMMENT ON COLUMN xd_corp_check_collateral.choiceTypeName IS '评估方式';
COMMENT ON COLUMN xd_corp_check_collateral.evaluateValue IS '评估价值';
COMMENT ON COLUMN xd_corp_check_collateral.confirmDate IS '认定日期';
COMMENT ON COLUMN xd_corp_check_collateral.DYQDJ IS '地役权登记';
COMMENT ON COLUMN xd_corp_check_collateral.YYDJ IS '异议登记';
COMMENT ON COLUMN xd_corp_check_collateral.CFDJ IS '查封登记';
COMMENT ON COLUMN xd_corp_check_collateral.YGDJ IS '预告登记';
COMMENT ON COLUMN xd_corp_check_collateral.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_collateral (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_collateral (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_collateral (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_collateral (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_collateral (customerName);

-- #####################################################################
-- 3. 押品限制权利表（押品下的限制权利数组）
--    mainId -> xd_corp_check_collateral.id（押品表）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_collateral_restrict (
    id                  BIGINT not null AUTO_INCREMENT,
    mainId              BIGINT NOT NULL,
    reportNo            VARCHAR(64) NOT NULL,
    serialNo            VARCHAR(64),
    customerId          VARCHAR(64),
    customerName        VARCHAR(128),
    attachmentOrg       VARCHAR(128),
    attachmentTypeName  VARCHAR(64),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_collateral_restrict IS '对公检查-押品限制权利表';
COMMENT ON COLUMN xd_corp_check_collateral_restrict.id IS '主键';
COMMENT ON COLUMN xd_corp_check_collateral_restrict.mainId IS '关联押品表主键id（xd_corp_check_collateral.id）';
COMMENT ON COLUMN xd_corp_check_collateral_restrict.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_collateral_restrict.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_collateral_restrict.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_collateral_restrict.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_collateral_restrict.attachmentOrg IS '限制权人';
COMMENT ON COLUMN xd_corp_check_collateral_restrict.attachmentTypeName IS '查封类型';
COMMENT ON COLUMN xd_corp_check_collateral_restrict.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_collateral_restrict (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_collateral_restrict (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_collateral_restrict (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_collateral_restrict (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_collateral_restrict (customerName);

-- #####################################################################
-- 4. 押品他项权利表（押品下的他项权利数组）
--    mainId -> xd_corp_check_collateral.id（押品表）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_collateral_mortgage (
    id                  BIGINT not null AUTO_INCREMENT,
    mainId              BIGINT NOT NULL,
    reportNo            VARCHAR(64) NOT NULL,
    serialNo            VARCHAR(64),
    customerId          VARCHAR(64),
    customerName        VARCHAR(128),
    pledgeSerialNo      VARCHAR(64),
    pledgeeName         VARCHAR(128),
    guaranteeScope      VARCHAR(1000),
    pledgeTypeName      VARCHAR(64),
    maxCreditorAmt      DECIMAL(18,2),
    startEnd            VARCHAR(64),
    registerTimestamp   VARCHAR(64),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_collateral_mortgage IS '对公检查-押品他项权利表';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.id IS '主键';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.mainId IS '关联押品表主键id（xd_corp_check_collateral.id）';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.pledgeSerialNo IS '不动产登记编号';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.pledgeeName IS '他项权人姓名';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.guaranteeScope IS '担保范围';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.pledgeTypeName IS '抵押方式';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.maxCreditorAmt IS '债权数额（万元）';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.startEnd IS '债务履行期限';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.registerTimestamp IS '登记日期';
COMMENT ON COLUMN xd_corp_check_collateral_mortgage.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_collateral_mortgage (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_collateral_mortgage (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_collateral_mortgage (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_collateral_mortgage (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_collateral_mortgage (customerName);

-- #####################################################################
-- 5. 批复后续管理要求表（检查详情-批复后续管理要求数组）
--    mainId -> xd_corp_check_info.id
--    说明：材料 SERIALNO（批复落实流水号）与公共字段 serialNo 同名冲突 -> 改名 replySerialNo
--          CONDITION 为关键字，加反引号（MySQL兼容模式支持）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_reply_requirement (
    id                          BIGINT not null AUTO_INCREMENT,
    mainId                      BIGINT NOT NULL,
    reportNo                    VARCHAR(64) NOT NULL,
    serialNo                    VARCHAR(64),
    customerId                  VARCHAR(64),
    customerName                VARCHAR(128),
    replySerialNo               VARCHAR(64),
    `CONDITION`                 VARCHAR(1000),
    RELATIVESERIALNO            VARCHAR(128),
    ITEMCATEGORY                VARCHAR(64),
    EXPECTEDCOMPLETIONEXACTDATE VARCHAR(64),
    COMPELETESTATUS             VARCHAR(64),
    CONDITIONINSTRUCTION        VARCHAR(1000),
    REALCOMPELETETIME           VARCHAR(64),
    checkTime                   VARCHAR(64),
    inputtime                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_reply_requirement IS '对公检查-批复后续管理要求表（贷后检查详情）';
COMMENT ON COLUMN xd_corp_check_reply_requirement.id IS '主键';
COMMENT ON COLUMN xd_corp_check_reply_requirement.mainId IS '关联主表主键id（xd_corp_check_info.id）';
COMMENT ON COLUMN xd_corp_check_reply_requirement.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_reply_requirement.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_reply_requirement.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_reply_requirement.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_reply_requirement.replySerialNo IS '批复落实流水号';
COMMENT ON COLUMN xd_corp_check_reply_requirement.`CONDITION` IS '批复后续管理要求';
COMMENT ON COLUMN xd_corp_check_reply_requirement.RELATIVESERIALNO IS '对象';
COMMENT ON COLUMN xd_corp_check_reply_requirement.ITEMCATEGORY IS '事项类别';
COMMENT ON COLUMN xd_corp_check_reply_requirement.EXPECTEDCOMPLETIONEXACTDATE IS '要求完成日期';
COMMENT ON COLUMN xd_corp_check_reply_requirement.COMPELETESTATUS IS '完成情况';
COMMENT ON COLUMN xd_corp_check_reply_requirement.CONDITIONINSTRUCTION IS '情况说明';
COMMENT ON COLUMN xd_corp_check_reply_requirement.REALCOMPELETETIME IS '实际完成日期';
COMMENT ON COLUMN xd_corp_check_reply_requirement.checkTime IS '检查时间';
COMMENT ON COLUMN xd_corp_check_reply_requirement.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_reply_requirement (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_reply_requirement (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_reply_requirement (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_reply_requirement (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_reply_requirement (customerName);

-- #####################################################################
-- 6. 授信批复后续管理要求表（授信批复后续管理要求数组）
--    mainId -> xd_corp_check_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_credit_requirement (
    id                  BIGINT not null AUTO_INCREMENT,
    mainId              BIGINT NOT NULL,
    reportNo            VARCHAR(64) NOT NULL,
    serialNo            VARCHAR(64),
    customerId          VARCHAR(64),
    customerName        VARCHAR(128),
    seqNo               VARCHAR(64),
    `CONDITION`         VARCHAR(1000),
    RELATIVESERIALNO    VARCHAR(128),
    checkTime           VARCHAR(64),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_credit_requirement IS '对公检查-授信批复后续管理要求表（贷后检查详情-授信批复信息）';
COMMENT ON COLUMN xd_corp_check_credit_requirement.id IS '主键';
COMMENT ON COLUMN xd_corp_check_credit_requirement.mainId IS '关联主表主键id（xd_corp_check_info.id）';
COMMENT ON COLUMN xd_corp_check_credit_requirement.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_credit_requirement.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_credit_requirement.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_credit_requirement.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_credit_requirement.seqNo IS '序号';
COMMENT ON COLUMN xd_corp_check_credit_requirement.`CONDITION` IS '后续管理要求';
COMMENT ON COLUMN xd_corp_check_credit_requirement.RELATIVESERIALNO IS '对象';
COMMENT ON COLUMN xd_corp_check_credit_requirement.checkTime IS '检查时间';
COMMENT ON COLUMN xd_corp_check_credit_requirement.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_credit_requirement (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_credit_requirement (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_credit_requirement (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_credit_requirement (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_credit_requirement (customerName);

-- #####################################################################
-- 7. 预警任务表（预警任务对象）
--    mainId -> xd_corp_check_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_warning_task (
    id                          BIGINT not null AUTO_INCREMENT,
    mainId                      BIGINT NOT NULL,
    reportNo                    VARCHAR(64) NOT NULL,
    serialNo                    VARCHAR(64),
    customerId                  VARCHAR(64),
    customerName                VARCHAR(128),
    confirmTime                 VARCHAR(64),
    approveStatusName           VARCHAR(64),
    riskTaskType                VARCHAR(64),
    inputDate                   VARCHAR(64),
    identifyCustomWaringLevel   VARCHAR(64),
    inputtime                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_warning_task IS '对公检查-预警任务表（审批通过的最近一次预警任务）';
COMMENT ON COLUMN xd_corp_check_warning_task.id IS '主键';
COMMENT ON COLUMN xd_corp_check_warning_task.mainId IS '关联主表主键id（xd_corp_check_info.id）';
COMMENT ON COLUMN xd_corp_check_warning_task.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_warning_task.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_warning_task.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_warning_task.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_warning_task.confirmTime IS '预警本次认定时间';
COMMENT ON COLUMN xd_corp_check_warning_task.approveStatusName IS '审批状态';
COMMENT ON COLUMN xd_corp_check_warning_task.riskTaskType IS '任务类型';
COMMENT ON COLUMN xd_corp_check_warning_task.inputDate IS '预警本次发起时间';
COMMENT ON COLUMN xd_corp_check_warning_task.identifyCustomWaringLevel IS '客户风险等级';
COMMENT ON COLUMN xd_corp_check_warning_task.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_warning_task (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_warning_task (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_warning_task (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_warning_task (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_warning_task (customerName);

-- #####################################################################
-- 8. 预警任务审批意见表（预警任务下的审批意见，取最后一岗、剔除同意）
--    mainId -> xd_corp_check_warning_task.id（预警任务表）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_warning_opinion (
    id                  BIGINT not null AUTO_INCREMENT,
    mainId              BIGINT NOT NULL,
    reportNo            VARCHAR(64) NOT NULL,
    serialNo            VARCHAR(64),
    customerId          VARCHAR(64),
    customerName        VARCHAR(128),
    seqNo               VARCHAR(64),
    activeName          VARCHAR(64),
    approveUserName     VARCHAR(64),
    approveOrgName      VARCHAR(128),
    warningLevelName    VARCHAR(64),
    phaseOpinion        VARCHAR(1000),
    endTime             VARCHAR(64),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_warning_opinion IS '对公检查-预警任务审批意见表（最后一岗，剔除同意）';
COMMENT ON COLUMN xd_corp_check_warning_opinion.id IS '主键';
COMMENT ON COLUMN xd_corp_check_warning_opinion.mainId IS '关联预警任务表主键id（xd_corp_check_warning_task.id）';
COMMENT ON COLUMN xd_corp_check_warning_opinion.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_warning_opinion.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_warning_opinion.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_warning_opinion.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_warning_opinion.seqNo IS '序号';
COMMENT ON COLUMN xd_corp_check_warning_opinion.activeName IS '审批阶段';
COMMENT ON COLUMN xd_corp_check_warning_opinion.approveUserName IS '审批人';
COMMENT ON COLUMN xd_corp_check_warning_opinion.approveOrgName IS '所属机构';
COMMENT ON COLUMN xd_corp_check_warning_opinion.warningLevelName IS '认定等级';
COMMENT ON COLUMN xd_corp_check_warning_opinion.phaseOpinion IS '审批意见';
COMMENT ON COLUMN xd_corp_check_warning_opinion.endTime IS '审批日期';
COMMENT ON COLUMN xd_corp_check_warning_opinion.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_warning_opinion (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_warning_opinion (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_warning_opinion (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_warning_opinion (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_warning_opinion (customerName);

-- #####################################################################
-- 9. 上次贷后意见表（上次贷后意见对象，取最后一岗、剔除同意）
--    mainId -> xd_corp_check_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_last_opinion (
    id                  BIGINT not null AUTO_INCREMENT,
    mainId              BIGINT NOT NULL,
    reportNo            VARCHAR(64) NOT NULL,
    serialNo            VARCHAR(64),
    customerId          VARCHAR(64),
    customerName        VARCHAR(128),
    taskGenerationDate  VARCHAR(64),
    activeName          VARCHAR(64),
    approveUserName     VARCHAR(64),
    approveOrgName      VARCHAR(128),
    phaseOpinion        VARCHAR(1000),
    endTime             VARCHAR(64),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_last_opinion IS '对公检查-上次贷后意见表（上一次贷后检查，最后一岗）';
COMMENT ON COLUMN xd_corp_check_last_opinion.id IS '主键';
COMMENT ON COLUMN xd_corp_check_last_opinion.mainId IS '关联主表主键id（xd_corp_check_info.id）';
COMMENT ON COLUMN xd_corp_check_last_opinion.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_last_opinion.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_last_opinion.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_last_opinion.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_last_opinion.taskGenerationDate IS '任务生成日期';
COMMENT ON COLUMN xd_corp_check_last_opinion.activeName IS '审批阶段';
COMMENT ON COLUMN xd_corp_check_last_opinion.approveUserName IS '审批人';
COMMENT ON COLUMN xd_corp_check_last_opinion.approveOrgName IS '所属机构';
COMMENT ON COLUMN xd_corp_check_last_opinion.phaseOpinion IS '审批意见';
COMMENT ON COLUMN xd_corp_check_last_opinion.endTime IS '审批日期';
COMMENT ON COLUMN xd_corp_check_last_opinion.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_last_opinion (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_last_opinion (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_last_opinion (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_last_opinion (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_last_opinion (customerName);

-- #####################################################################
-- 10. 本次贷后检查意见表（本次贷后检查意见数组，各级意见）
--     mainId -> xd_corp_check_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_current_opinion (
    id                  BIGINT not null AUTO_INCREMENT,
    mainId              BIGINT NOT NULL,
    reportNo            VARCHAR(64) NOT NULL,
    serialNo            VARCHAR(64),
    customerId          VARCHAR(64),
    customerName        VARCHAR(128),
    taskGenerationDate  VARCHAR(64),
    activeName          VARCHAR(64),
    approveUserName     VARCHAR(64),
    approveOrgName      VARCHAR(128),
    phaseOpinion        VARCHAR(1000),
    endTime             VARCHAR(64),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_current_opinion IS '对公检查-本次贷后检查意见表（本次贷后检查，各级意见）';
COMMENT ON COLUMN xd_corp_check_current_opinion.id IS '主键';
COMMENT ON COLUMN xd_corp_check_current_opinion.mainId IS '关联主表主键id（xd_corp_check_info.id）';
COMMENT ON COLUMN xd_corp_check_current_opinion.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_current_opinion.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_current_opinion.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_current_opinion.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_current_opinion.taskGenerationDate IS '任务生成日期';
COMMENT ON COLUMN xd_corp_check_current_opinion.activeName IS '审批阶段';
COMMENT ON COLUMN xd_corp_check_current_opinion.approveUserName IS '审批人';
COMMENT ON COLUMN xd_corp_check_current_opinion.approveOrgName IS '所属机构';
COMMENT ON COLUMN xd_corp_check_current_opinion.phaseOpinion IS '审批意见';
COMMENT ON COLUMN xd_corp_check_current_opinion.endTime IS '审批日期';
COMMENT ON COLUMN xd_corp_check_current_opinion.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_current_opinion (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_current_opinion (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_current_opinion (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_current_opinion (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_current_opinion (customerName);

-- #####################################################################
-- 11. 现场打卡记录表（现场打开记录数组）
--     mainId -> xd_corp_check_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_checkin (
    id                  BIGINT not null AUTO_INCREMENT,
    mainId              BIGINT NOT NULL,
    reportNo            VARCHAR(64) NOT NULL,
    serialNo            VARCHAR(64),
    customerId          VARCHAR(64),
    customerName        VARCHAR(128),
    checkInTime         VARCHAR(64),
    checkInAddress      VARCHAR(255),
    visitObj            VARCHAR(128),
    checkInObj          VARCHAR(128),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_checkin IS '对公检查-现场打卡记录表（贷后检查详情-打卡）';
COMMENT ON COLUMN xd_corp_check_checkin.id IS '主键';
COMMENT ON COLUMN xd_corp_check_checkin.mainId IS '关联主表主键id（xd_corp_check_info.id）';
COMMENT ON COLUMN xd_corp_check_checkin.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_checkin.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_checkin.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_checkin.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_checkin.checkInTime IS '打卡日期';
COMMENT ON COLUMN xd_corp_check_checkin.checkInAddress IS '打卡地址';
COMMENT ON COLUMN xd_corp_check_checkin.visitObj IS '拜访对象';
COMMENT ON COLUMN xd_corp_check_checkin.checkInObj IS '打卡对象';
COMMENT ON COLUMN xd_corp_check_checkin.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_checkin (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_checkin (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_checkin (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_checkin (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_checkin (customerName);

-- #####################################################################
-- 12. 日常检查综合指标表（日常检查综合指标对象）
--     mainId -> xd_corp_check_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_daily_index (
    id              BIGINT not null AUTO_INCREMENT,
    mainId          BIGINT NOT NULL,
    reportNo        VARCHAR(64) NOT NULL,
    serialNo        VARCHAR(64),
    customerId      VARCHAR(64),
    customerName    VARCHAR(128),
    chineseId       VARCHAR(64),
    chineseName     VARCHAR(255),
    YesNo           VARCHAR(64),
    remark          VARCHAR(1000),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_daily_index IS '对公检查-日常检查综合指标表';
COMMENT ON COLUMN xd_corp_check_daily_index.id IS '主键';
COMMENT ON COLUMN xd_corp_check_daily_index.mainId IS '关联主表主键id（xd_corp_check_info.id）';
COMMENT ON COLUMN xd_corp_check_daily_index.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_daily_index.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_daily_index.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_daily_index.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_daily_index.chineseId IS '指标编号';
COMMENT ON COLUMN xd_corp_check_daily_index.chineseName IS '指标名称';
COMMENT ON COLUMN xd_corp_check_daily_index.YesNo IS '检查结论';
COMMENT ON COLUMN xd_corp_check_daily_index.remark IS '说明';
COMMENT ON COLUMN xd_corp_check_daily_index.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_daily_index (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_daily_index (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_daily_index (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_daily_index (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_daily_index (customerName);

-- #####################################################################
-- 13. 特定贷款检查表（特定贷款检查数组，46 个字段）
--     mainId -> xd_corp_check_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_check_special_loan (
    id                          BIGINT not null AUTO_INCREMENT,
    mainId                      BIGINT NOT NULL,
    reportNo                    VARCHAR(64) NOT NULL,
    serialNo                    VARCHAR(64),
    customerId                  VARCHAR(64),
    customerName                VARCHAR(128),
    objectName                  VARCHAR(64),
    balance                     DECIMAL(18,2),
    businessSum                 DECIMAL(18,2),
    capitalCheckCondition       VARCHAR(1000),
    capitalFundInvoiced         DECIMAL(18,2),
    capitalFundUnInvoiced       DECIMAL(18,2),
    capitalFundUsed             DECIMAL(18,2),
    contractNo                  VARCHAR(64),
    duebillTotalBusinessSum     DECIMAL(18,2),
    explain                     VARCHAR(1000),
    ifBulid                     VARCHAR(64),
    ifConstructionExpect        VARCHAR(64),
    ifGetPermission             VARCHAR(64),
    ifMatch                     VARCHAR(64),
    ifOpenAccount               VARCHAR(64),
    ifOperate                   VARCHAR(64),
    ifOverInvest                VARCHAR(64),
    ifRunExpect                 VARCHAR(64),
    ifSign                      VARCHAR(64),
    lastCapitalCheckCondition   VARCHAR(1000),
    lastPurchaseCheckCondition  VARCHAR(1000),
    lastRunCheckCondition       VARCHAR(1000),
    lastScheduleCheckCondition  VARCHAR(1000),
    lastSuperviseCheckCondition VARCHAR(1000),
    loanFundInvoiced            DECIMAL(18,2),
    loanFundUnInvoiced          DECIMAL(18,2),
    loanFundUsed                DECIMAL(18,2),
    nominalBalanceSum           DECIMAL(18,2),
    otherFundInvoiced           DECIMAL(18,2),
    otherFundUnInvoiced         DECIMAL(18,2),
    otherFundUsed               DECIMAL(18,2),
    overInvest                  VARCHAR(1000),
    productBelongName           VARCHAR(64),
    productName                 VARCHAR(64),
    projectBeginDate            VARCHAR(64),
    projectFinishDate           VARCHAR(64),
    purchaseCheckCondition      VARCHAR(1000),
    purpose                     VARCHAR(255),
    repaySum                    DECIMAL(18,2),
    runCheckCondition           VARCHAR(1000),
    scheduleCheckCondition      VARCHAR(1000),
    superviseCheckCondition     VARCHAR(1000),
    totalInvestInvoiced         DECIMAL(18,2),
    totalInvestUnInvoiced       DECIMAL(18,2),
    totalInvestUsed             DECIMAL(18,2),
    vouchType                   VARCHAR(64),
    inputtime                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_check_special_loan IS '对公检查-特定贷款检查表';
COMMENT ON COLUMN xd_corp_check_special_loan.id IS '主键';
COMMENT ON COLUMN xd_corp_check_special_loan.mainId IS '关联主表主键id（xd_corp_check_info.id）';
COMMENT ON COLUMN xd_corp_check_special_loan.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_check_special_loan.serialNo IS '日检申请流水号';
COMMENT ON COLUMN xd_corp_check_special_loan.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_corp_check_special_loan.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_check_special_loan.objectName IS '对象名称';
COMMENT ON COLUMN xd_corp_check_special_loan.balance IS '用信余额';
COMMENT ON COLUMN xd_corp_check_special_loan.businessSum IS '授信金额';
COMMENT ON COLUMN xd_corp_check_special_loan.capitalCheckCondition IS '项目资本金情况本次检查情况';
COMMENT ON COLUMN xd_corp_check_special_loan.capitalFundInvoiced IS '资本金已开票金额';
COMMENT ON COLUMN xd_corp_check_special_loan.capitalFundUnInvoiced IS '资本金未开票金额';
COMMENT ON COLUMN xd_corp_check_special_loan.capitalFundUsed IS '资本金已使用金额';
COMMENT ON COLUMN xd_corp_check_special_loan.contractNo IS '业务合同编号';
COMMENT ON COLUMN xd_corp_check_special_loan.duebillTotalBusinessSum IS '用信金额';
COMMENT ON COLUMN xd_corp_check_special_loan.explain IS '说明';
COMMENT ON COLUMN xd_corp_check_special_loan.ifBulid IS '是否建设期';
COMMENT ON COLUMN xd_corp_check_special_loan.ifConstructionExpect IS '建设期进度是否符合预期';
COMMENT ON COLUMN xd_corp_check_special_loan.ifGetPermission IS '是否取得预售证';
COMMENT ON COLUMN xd_corp_check_special_loan.ifMatch IS '资金使用是否与项目进入匹配';
COMMENT ON COLUMN xd_corp_check_special_loan.ifOpenAccount IS '是否开立监管账户';
COMMENT ON COLUMN xd_corp_check_special_loan.ifOperate IS '运营期';
COMMENT ON COLUMN xd_corp_check_special_loan.ifOverInvest IS '是否存在超投情况';
COMMENT ON COLUMN xd_corp_check_special_loan.ifRunExpect IS '运营是否符合预期';
COMMENT ON COLUMN xd_corp_check_special_loan.ifSign IS '资金监管协议是否已签署';
COMMENT ON COLUMN xd_corp_check_special_loan.lastCapitalCheckCondition IS '项目资本金情况前次检查情况';
COMMENT ON COLUMN xd_corp_check_special_loan.lastPurchaseCheckCondition IS '建安工程或设备采购支出情况前次检查情况';
COMMENT ON COLUMN xd_corp_check_special_loan.lastRunCheckCondition IS '运营检查前次检查情况';
COMMENT ON COLUMN xd_corp_check_special_loan.lastScheduleCheckCondition IS '项目建设进度前次检查情况';
COMMENT ON COLUMN xd_corp_check_special_loan.lastSuperviseCheckCondition IS '资金监管情况前次检查情况';
COMMENT ON COLUMN xd_corp_check_special_loan.loanFundInvoiced IS '贷款资金已开票金额';
COMMENT ON COLUMN xd_corp_check_special_loan.loanFundUnInvoiced IS '贷款资金未开票金额';
COMMENT ON COLUMN xd_corp_check_special_loan.loanFundUsed IS '贷款资金已使用金额';
COMMENT ON COLUMN xd_corp_check_special_loan.nominalBalanceSum IS '用信敞口余额';
COMMENT ON COLUMN xd_corp_check_special_loan.otherFundInvoiced IS '其他资金已开票金额';
COMMENT ON COLUMN xd_corp_check_special_loan.otherFundUnInvoiced IS '其他资金未开票金额';
COMMENT ON COLUMN xd_corp_check_special_loan.otherFundUsed IS '其他资金已使用金额';
COMMENT ON COLUMN xd_corp_check_special_loan.overInvest IS '超投情况说明';
COMMENT ON COLUMN xd_corp_check_special_loan.productBelongName IS '产品归属';
COMMENT ON COLUMN xd_corp_check_special_loan.productName IS '基础产品';
COMMENT ON COLUMN xd_corp_check_special_loan.projectBeginDate IS '项目启动年月';
COMMENT ON COLUMN xd_corp_check_special_loan.projectFinishDate IS '（预计）项目完工年月';
COMMENT ON COLUMN xd_corp_check_special_loan.purchaseCheckCondition IS '建安工程或设备采购支出情况本次检查情况';
COMMENT ON COLUMN xd_corp_check_special_loan.purpose IS '用途';
COMMENT ON COLUMN xd_corp_check_special_loan.repaySum IS '已还本金';
COMMENT ON COLUMN xd_corp_check_special_loan.runCheckCondition IS '运营检查本次检查情况';
COMMENT ON COLUMN xd_corp_check_special_loan.scheduleCheckCondition IS '项目建设进度本次检查情况';
COMMENT ON COLUMN xd_corp_check_special_loan.superviseCheckCondition IS '资金监管情况本次检查情况';
COMMENT ON COLUMN xd_corp_check_special_loan.totalInvestInvoiced IS '总投资已开票金额';
COMMENT ON COLUMN xd_corp_check_special_loan.totalInvestUnInvoiced IS '总投资未开票金额';
COMMENT ON COLUMN xd_corp_check_special_loan.totalInvestUsed IS '总投资已使用金额';
COMMENT ON COLUMN xd_corp_check_special_loan.vouchType IS '担保方式';
COMMENT ON COLUMN xd_corp_check_special_loan.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_check_special_loan (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_check_special_loan (reportNo);
CREATE INDEX IF NOT EXISTS idx_serialNo ON xd_corp_check_special_loan (serialNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_check_special_loan (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_check_special_loan (customerName);
