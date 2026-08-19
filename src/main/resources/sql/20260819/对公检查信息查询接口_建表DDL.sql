-- =====================================================================
-- 对公检查信息查询接口 · 数据落表 DDL（v2.0）
-- 数据库：GaussDB（MySQL 兼容模式）
--
-- 设计约定：
--   1. 按接口嵌套层级拆分：1 张主表 + 12 张子表
--   2. 英文字段名 100% 照抄接口材料（驼峰保持驼峰、全大写保持全大写），不做格式转换
--   3. 每张表公共字段：reportNo(报告编号)、serialNo(日检申请流水号)、
--      customerId(信贷客户编号)、customerName(客户名称)、inputtime(入库时间)
--   4. 嵌套层级通过 mainId 逻辑关联（不建物理外键）：
--      - 直接子表：mainId -> 主表 corp_check_info.id
--      - 二级子表：mainId -> 直接上级表 id（押品限制/他项权利 -> 押品表；预警审批意见 -> 预警任务表）
--      追溯链路：二级子表 -> 一级子表 -> 主表，逐层 join 即可
--   5. 类型映射：材料 String -> VARCHAR；材料 Number -> DECIMAL(18,2)；inputtime -> DATETIME
--   6. reportNo / serialNo / customerId / customerName 四列均建索引
--   7. 接口返回直接追加插入，不做去重约束
-- =====================================================================

-- =====================================================================
-- 1. 对公检查信息主表（入参 + 贷后检查详情-基础字段）
--    对应出参：贷后检查详情（bapSerialNo ~ checkDate）
-- =====================================================================
CREATE TABLE corp_check_info (
    id              BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    reportNo        VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo        VARCHAR(64)     COMMENT '日检申请流水号',
    customerId      VARCHAR(64)     COMMENT '信贷客户编号',
    customerName    VARCHAR(128)    COMMENT '客户名称',
    bapSerialNo     VARCHAR(64)     COMMENT '批复编号',
    bapStartDate    VARCHAR(64)     COMMENT '批复生效日',
    bapMaturity     VARCHAR(64)     COMMENT '批复到期日',
    bapReportNo     VARCHAR(64)     COMMENT '贷后检查关联征信报告编号',
    baReportNo      VARCHAR(64)     COMMENT '授信时点的征信报告编号',
    checkDate       VARCHAR(64)     COMMENT '检查日期',
    inputtime       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查信息主表（贷后检查详情-基础信息）';

-- =====================================================================
-- 2. 批复关联押品表（押品数组 + 最新不动产登记簿记录）
--    对应出参：批复关联押品数组（ClrId ~ YGDJ）
--    mainId -> corp_check_info.id
-- =====================================================================
CREATE TABLE corp_check_collateral (
    id              BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId          BIGINT          NOT NULL COMMENT '关联主表主键id（corp_check_info.id）',
    reportNo        VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo        VARCHAR(64)     COMMENT '日检申请流水号',
    customerId      VARCHAR(64)     COMMENT '信贷客户编号',
    customerName    VARCHAR(128)    COMMENT '客户名称',
    ClrId           VARCHAR(64)     COMMENT '押品编号',
    ownerId         VARCHAR(64)     COMMENT '权属人客户编号',
    ownerName       VARCHAR(128)    COMMENT '权属人姓名',
    ClrType         VARCHAR(64)     COMMENT '押品类型',
    ClrName         VARCHAR(128)    COMMENT '押品名称',
    ClrStatus       VARCHAR(64)     COMMENT '押品状态',
    rightOrder      VARCHAR(64)     COMMENT '顺位',
    rightSum        DECIMAL(18,2)   COMMENT '权证金额',
    valuationDate   VARCHAR(64)     COMMENT '押品最新评估日期',
    choiceTypeName  VARCHAR(64)     COMMENT '评估方式',
    evaluateValue   DECIMAL(18,2)   COMMENT '评估价值',
    confirmDate     VARCHAR(64)     COMMENT '认定日期',
    DYQDJ           VARCHAR(64)     COMMENT '地役权登记',
    YYDJ            VARCHAR(64)     COMMENT '异议登记',
    CFDJ            VARCHAR(64)     COMMENT '查封登记',
    YGDJ            VARCHAR(64)     COMMENT '预告登记',
    inputtime       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-批复关联押品表（押品数组+不动产登记簿记录）';

-- =====================================================================
-- 3. 押品限制权利表（押品下的限制权利数组）
--    对应出参：限制权利数组（attachmentOrg ~ attachmentTypeName）
--    mainId -> corp_check_collateral.id（押品表）
-- =====================================================================
CREATE TABLE corp_check_collateral_restrict (
    id                  BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId              BIGINT          NOT NULL COMMENT '关联押品表主键id（corp_check_collateral.id）',
    reportNo            VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo            VARCHAR(64)     COMMENT '日检申请流水号',
    customerId          VARCHAR(64)     COMMENT '信贷客户编号',
    customerName        VARCHAR(128)    COMMENT '客户名称',
    attachmentOrg       VARCHAR(128)    COMMENT '限制权人',
    attachmentTypeName  VARCHAR(64)     COMMENT '查封类型',
    inputtime           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-押品限制权利表';

-- =====================================================================
-- 4. 押品他项权利表（押品下的他项权利数组）
--    对应出参：他项权利数组（pledgeSerialNo ~ registerTimestamp）
--    mainId -> corp_check_collateral.id（押品表）
-- =====================================================================
CREATE TABLE corp_check_collateral_mortgage (
    id                  BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId              BIGINT          NOT NULL COMMENT '关联押品表主键id（corp_check_collateral.id）',
    reportNo            VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo            VARCHAR(64)     COMMENT '日检申请流水号',
    customerId          VARCHAR(64)     COMMENT '信贷客户编号',
    customerName        VARCHAR(128)    COMMENT '客户名称',
    pledgeSerialNo      VARCHAR(64)     COMMENT '不动产登记编号',
    pledgeeName         VARCHAR(128)    COMMENT '他项权人姓名',
    guaranteeScope      VARCHAR(1000)   COMMENT '担保范围',
    pledgeTypeName      VARCHAR(64)     COMMENT '抵押方式',
    maxCreditorAmt      DECIMAL(18,2)   COMMENT '债权数额（万元）',
    startEnd            VARCHAR(64)     COMMENT '债务履行期限',
    registerTimestamp   VARCHAR(64)     COMMENT '登记日期',
    inputtime           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-押品他项权利表';

-- =====================================================================
-- 5. 批复后续管理要求表（检查详情-批复后续管理要求数组）
--    对应出参：检查详情-批复后续管理要求数组（SERIALNO ~ 检查时间）
--    mainId -> corp_check_info.id
--    说明：材料字段 SERIALNO（批复落实流水号）与公共字段 serialNo 同名冲突（库列名不区分大小写），
--          落表改名 replySerialNo，其余全大写字段按材料原样保留
-- =====================================================================
CREATE TABLE corp_check_reply_requirement (
    id                          BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId                      BIGINT          NOT NULL COMMENT '关联主表主键id（corp_check_info.id）',
    reportNo                    VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo                    VARCHAR(64)     COMMENT '日检申请流水号',
    customerId                  VARCHAR(64)     COMMENT '信贷客户编号',
    customerName                VARCHAR(128)    COMMENT '客户名称',
    replySerialNo               VARCHAR(64)     COMMENT '批复落实流水号',
    `CONDITION`                 VARCHAR(1000)   COMMENT '批复后续管理要求',
    RELATIVESERIALNO            VARCHAR(128)    COMMENT '对象',
    ITEMCATEGORY                VARCHAR(64)     COMMENT '事项类别',
    EXPECTEDCOMPLETIONEXACTDATE VARCHAR(64)     COMMENT '要求完成日期',
    COMPELETESTATUS             VARCHAR(64)     COMMENT '完成情况',
    CONDITIONINSTRUCTION        VARCHAR(1000)   COMMENT '情况说明',
    REALCOMPELETETIME           VARCHAR(64)     COMMENT '实际完成日期',
    checkTime                   VARCHAR(64)     COMMENT '检查时间',
    inputtime                   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-批复后续管理要求表（贷后检查详情）';

-- =====================================================================
-- 6. 授信批复后续管理要求表（授信批复后续管理要求数组）
--    对应出参：授信批复后续管理要求数组（seqNo ~ 检查时间）
--    mainId -> corp_check_info.id
-- =====================================================================
CREATE TABLE corp_check_credit_requirement (
    id                  BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId              BIGINT          NOT NULL COMMENT '关联主表主键id（corp_check_info.id）',
    reportNo            VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo            VARCHAR(64)     COMMENT '日检申请流水号',
    customerId          VARCHAR(64)     COMMENT '信贷客户编号',
    customerName        VARCHAR(128)    COMMENT '客户名称',
    seqNo               VARCHAR(64)     COMMENT '序号',
    `CONDITION`         VARCHAR(1000)   COMMENT '后续管理要求',
    RELATIVESERIALNO    VARCHAR(128)    COMMENT '对象',
    checkTime           VARCHAR(64)     COMMENT '检查时间',
    inputtime           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-授信批复后续管理要求表（贷后检查详情-授信批复信息）';

-- =====================================================================
-- 7. 预警任务表（预警任务对象）
--    对应出参：预警任务对象（confirmTime ~ identifyCustomWaringLevel）
--    mainId -> corp_check_info.id
-- =====================================================================
CREATE TABLE corp_check_warning_task (
    id                          BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId                      BIGINT          NOT NULL COMMENT '关联主表主键id（corp_check_info.id）',
    reportNo                    VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo                    VARCHAR(64)     COMMENT '日检申请流水号',
    customerId                  VARCHAR(64)     COMMENT '信贷客户编号',
    customerName                VARCHAR(128)    COMMENT '客户名称',
    confirmTime                 VARCHAR(64)     COMMENT '预警本次认定时间',
    approveStatusName           VARCHAR(64)     COMMENT '审批状态',
    riskTaskType                VARCHAR(64)     COMMENT '任务类型',
    inputDate                   VARCHAR(64)     COMMENT '预警本次发起时间',
    identifyCustomWaringLevel   VARCHAR(64)     COMMENT '客户风险等级',
    inputtime                   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-预警任务表（审批通过的最近一次预警任务）';

-- =====================================================================
-- 8. 预警任务审批意见表（预警任务下的审批意见，取最后一岗、剔除同意）
--    对应出参：预警任务对象内 seqNo ~ endTime
--    mainId -> corp_check_warning_task.id（预警任务表）
-- =====================================================================
CREATE TABLE corp_check_warning_opinion (
    id                  BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId              BIGINT          NOT NULL COMMENT '关联预警任务表主键id（corp_check_warning_task.id）',
    reportNo            VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo            VARCHAR(64)     COMMENT '日检申请流水号',
    customerId          VARCHAR(64)     COMMENT '信贷客户编号',
    customerName        VARCHAR(128)    COMMENT '客户名称',
    seqNo               VARCHAR(64)     COMMENT '序号',
    activeName          VARCHAR(64)     COMMENT '审批阶段',
    approveUserName     VARCHAR(64)     COMMENT '审批人',
    approveOrgName      VARCHAR(128)    COMMENT '所属机构',
    warningLevelName    VARCHAR(64)     COMMENT '认定等级',
    phaseOpinion        VARCHAR(1000)   COMMENT '审批意见',
    endTime             VARCHAR(64)     COMMENT '审批日期',
    inputtime           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-预警任务审批意见表（最后一岗，剔除同意）';

-- =====================================================================
-- 9. 上次贷后意见表（上次贷后意见对象，取最后一岗、剔除同意）
--    对应出参：上次贷后意见对象（taskGenerationDate ~ endTime）
--    mainId -> corp_check_info.id
-- =====================================================================
CREATE TABLE corp_check_last_opinion (
    id                  BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId              BIGINT          NOT NULL COMMENT '关联主表主键id（corp_check_info.id）',
    reportNo            VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo            VARCHAR(64)     COMMENT '日检申请流水号',
    customerId          VARCHAR(64)     COMMENT '信贷客户编号',
    customerName        VARCHAR(128)    COMMENT '客户名称',
    taskGenerationDate  VARCHAR(64)     COMMENT '任务生成日期',
    activeName          VARCHAR(64)     COMMENT '审批阶段',
    approveUserName     VARCHAR(64)     COMMENT '审批人',
    approveOrgName      VARCHAR(128)    COMMENT '所属机构',
    phaseOpinion        VARCHAR(1000)   COMMENT '审批意见',
    endTime             VARCHAR(64)     COMMENT '审批日期',
    inputtime           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-上次贷后意见表（上一次贷后检查，最后一岗）';

-- =====================================================================
-- 10. 本次贷后检查意见表（本次贷后检查意见数组，各级意见）
--     对应出参：本次贷后检查意见数组（taskGenerationDate ~ endTime）
--     mainId -> corp_check_info.id
-- =====================================================================
CREATE TABLE corp_check_current_opinion (
    id                  BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId              BIGINT          NOT NULL COMMENT '关联主表主键id（corp_check_info.id）',
    reportNo            VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo            VARCHAR(64)     COMMENT '日检申请流水号',
    customerId          VARCHAR(64)     COMMENT '信贷客户编号',
    customerName        VARCHAR(128)    COMMENT '客户名称',
    taskGenerationDate  VARCHAR(64)     COMMENT '任务生成日期',
    activeName          VARCHAR(64)     COMMENT '审批阶段',
    approveUserName     VARCHAR(64)     COMMENT '审批人',
    approveOrgName      VARCHAR(128)    COMMENT '所属机构',
    phaseOpinion        VARCHAR(1000)   COMMENT '审批意见',
    endTime             VARCHAR(64)     COMMENT '审批日期',
    inputtime           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-本次贷后检查意见表（本次贷后检查，各级意见）';

-- =====================================================================
-- 11. 现场打卡记录表（现场打开记录数组）
--     对应出参：现场打开记录数组（checkInTime ~ checkInObj）
--     mainId -> corp_check_info.id
--     注：材料标题为"现场打开记录"，应为"现场打卡"，字段按材料原样保留
-- =====================================================================
CREATE TABLE corp_check_checkin (
    id                  BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId              BIGINT          NOT NULL COMMENT '关联主表主键id（corp_check_info.id）',
    reportNo            VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo            VARCHAR(64)     COMMENT '日检申请流水号',
    customerId          VARCHAR(64)     COMMENT '信贷客户编号',
    customerName        VARCHAR(128)    COMMENT '客户名称',
    checkInTime         VARCHAR(64)     COMMENT '打卡日期',
    checkInAddress      VARCHAR(255)    COMMENT '打卡地址',
    visitObj            VARCHAR(128)    COMMENT '拜访对象',
    checkInObj          VARCHAR(128)    COMMENT '打卡对象',
    inputtime           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-现场打卡记录表（贷后检查详情-打卡）';

-- =====================================================================
-- 12. 日常检查综合指标表（日常检查综合指标对象）
--     对应出参：日常检查综合指标对象（chineseId ~ remark）
--     mainId -> corp_check_info.id
-- =====================================================================
CREATE TABLE corp_check_daily_index (
    id              BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId          BIGINT          NOT NULL COMMENT '关联主表主键id（corp_check_info.id）',
    reportNo        VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo        VARCHAR(64)     COMMENT '日检申请流水号',
    customerId      VARCHAR(64)     COMMENT '信贷客户编号',
    customerName    VARCHAR(128)    COMMENT '客户名称',
    chineseId       VARCHAR(64)     COMMENT '指标编号',
    chineseName     VARCHAR(255)    COMMENT '指标名称',
    YesNo           VARCHAR(64)     COMMENT '检查结论',
    remark          VARCHAR(1000)   COMMENT '说明',
    inputtime       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-日常检查综合指标表';

-- =====================================================================
-- 13. 特定贷款检查表（特定贷款检查数组，46 个字段）
--     对应出参：特定贷款检查数组（objectName ~ vouchType）
--     mainId -> corp_check_info.id
-- =====================================================================
CREATE TABLE corp_check_special_loan (
    id                          BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    mainId                      BIGINT          NOT NULL COMMENT '关联主表主键id（corp_check_info.id）',
    reportNo                    VARCHAR(64)     NOT NULL COMMENT '报告编号',
    serialNo                    VARCHAR(64)     COMMENT '日检申请流水号',
    customerId                  VARCHAR(64)     COMMENT '信贷客户编号',
    customerName                VARCHAR(128)    COMMENT '客户名称',
    objectName                  VARCHAR(64)     COMMENT '对象名称',
    balance                     DECIMAL(18,2)   COMMENT '用信余额',
    businessSum                 DECIMAL(18,2)   COMMENT '授信金额',
    capitalCheckCondition       VARCHAR(1000)   COMMENT '项目资本金情况本次检查情况',
    capitalFundInvoiced         DECIMAL(18,2)   COMMENT '资本金已开票金额',
    capitalFundUnInvoiced       DECIMAL(18,2)   COMMENT '资本金未开票金额',
    capitalFundUsed             DECIMAL(18,2)   COMMENT '资本金已使用金额',
    contractNo                  VARCHAR(64)     COMMENT '业务合同编号',
    duebillTotalBusinessSum     DECIMAL(18,2)   COMMENT '用信金额',
    explain                     VARCHAR(1000)   COMMENT '说明',
    ifBulid                     VARCHAR(64)     COMMENT '是否建设期',
    ifConstructionExpect        VARCHAR(64)     COMMENT '建设期进度是否符合预期',
    ifGetPermission             VARCHAR(64)     COMMENT '是否取得预售证',
    ifMatch                     VARCHAR(64)     COMMENT '资金使用是否与项目进入匹配',
    ifOpenAccount               VARCHAR(64)     COMMENT '是否开立监管账户',
    ifOperate                   VARCHAR(64)     COMMENT '运营期',
    ifOverInvest                VARCHAR(64)     COMMENT '是否存在超投情况',
    ifRunExpect                 VARCHAR(64)     COMMENT '运营是否符合预期',
    ifSign                      VARCHAR(64)     COMMENT '资金监管协议是否已签署',
    lastCapitalCheckCondition   VARCHAR(1000)   COMMENT '项目资本金情况前次检查情况',
    lastPurchaseCheckCondition  VARCHAR(1000)   COMMENT '建安工程或设备采购支出情况前次检查情况',
    lastRunCheckCondition       VARCHAR(1000)   COMMENT '运营检查前次检查情况',
    lastScheduleCheckCondition  VARCHAR(1000)   COMMENT '项目建设进度前次检查情况',
    lastSuperviseCheckCondition VARCHAR(1000)   COMMENT '资金监管情况前次检查情况',
    loanFundInvoiced            DECIMAL(18,2)   COMMENT '贷款资金已开票金额',
    loanFundUnInvoiced          DECIMAL(18,2)   COMMENT '贷款资金未开票金额',
    loanFundUsed                DECIMAL(18,2)   COMMENT '贷款资金已使用金额',
    nominalBalanceSum           DECIMAL(18,2)   COMMENT '用信敞口余额',
    otherFundInvoiced           DECIMAL(18,2)   COMMENT '其他资金已开票金额',
    otherFundUnInvoiced         DECIMAL(18,2)   COMMENT '其他资金未开票金额',
    otherFundUsed               DECIMAL(18,2)   COMMENT '其他资金已使用金额',
    overInvest                  VARCHAR(1000)   COMMENT '超投情况说明',
    productBelongName           VARCHAR(64)     COMMENT '产品归属',
    productName                 VARCHAR(64)     COMMENT '基础产品',
    projectBeginDate            VARCHAR(64)     COMMENT '项目启动年月',
    projectFinishDate           VARCHAR(64)     COMMENT '（预计）项目完工年月',
    purchaseCheckCondition      VARCHAR(1000)   COMMENT '建安工程或设备采购支出情况本次检查情况',
    purpose                     VARCHAR(255)    COMMENT '用途',
    repaySum                    DECIMAL(18,2)   COMMENT '已还本金',
    runCheckCondition           VARCHAR(1000)   COMMENT '运营检查本次检查情况',
    scheduleCheckCondition      VARCHAR(1000)   COMMENT '项目建设进度本次检查情况',
    superviseCheckCondition     VARCHAR(1000)   COMMENT '资金监管情况本次检查情况',
    totalInvestInvoiced         DECIMAL(18,2)   COMMENT '总投资已开票金额',
    totalInvestUnInvoiced       DECIMAL(18,2)   COMMENT '总投资未开票金额',
    totalInvestUsed             DECIMAL(18,2)   COMMENT '总投资已使用金额',
    vouchType                   VARCHAR(64)     COMMENT '担保方式',
    inputtime                   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入库时间',
    PRIMARY KEY (id),
    INDEX idx_mainId (mainId),
    INDEX idx_reportNo (reportNo),
    INDEX idx_serialNo (serialNo),
    INDEX idx_customerId (customerId),
    INDEX idx_customerName (customerName)
) COMMENT='对公检查-特定贷款检查表';
