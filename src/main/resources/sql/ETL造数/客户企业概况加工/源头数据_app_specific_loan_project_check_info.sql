-- =====================================================================
-- app_specific_loan_project_check_info（特定贷款项目检查）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_specific_loan_project.sql
-- 源表：
--   xd_corp_check_info          对公检查主档（父表）
--   xd_corp_check_fixed_loan     特定贷款检查（固定资产、房地产开发贷款，mainId -> xd_corp_check_info.id）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_specific_loan_project.sql，32 业务列）：
--   reportNo/customerId/customerName  直映
--   objectName/balance/businessSum  直映（DECIMAL 透传）
--   capitalCheckCondition/capitalFundInvoiced/capitalFundUnInvoiced/capitalFundUsed  直映
--   contractNo/duebillTotalBusinessSum  直映
--   loanFundInvoiced/loanFundUnInvoiced/loanFundUsed  直映
--   nominalBalanceSum/otherFundInvoiced/otherFundUnInvoiced/otherFundUsed  直映
--   productBelongName/productName  直映
--   projectBeginDate/projectFinishDate  日期正则 -> YYYYMMDD；否则原样透传
--   purpose  VARCHAR(255) -> VARCHAR(128)  LEFT(...,128) 截断
--   repaySum/runCheckCondition/scheduleCheckCondition/superviseCheckCondition  直映
--   totalInvestInvoiced/totalInvestUnInvoiced/totalInvestUsed  直映
--   vouchType  VARCHAR(64) -> VARCHAR(32)  LEFT(...,32) 截断
--   去重：JOIN 当前主档 + ROW_NUMBER(reportNo, customerId, contractNo) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：4（contractNo: GDZC-2026-001/002, FDK-2026-003/004）
--
-- ISSUE 1: DML 有 51 列，加工 SQL 只插入 32 列。19 列未映射：
--   explain/ifbuild/ifconstructionexpect/ifgetpermission/ifmatch/ifopenaccount/
--   ifoperate/ifoverinvest/ifrunexpect/ifsign/lastcapitalcheckcondition/
--   lastpurchasecheckcondition/lastruncheckcondition/lastschedulecheckcondition/
--   lastsupervisecheckcondition/overinvest/purchasecheckcondition（源表有列但加工 SQL 不映射 -> NULL）
--   id（auto）/inputtime（DEFAULT CURRENT_TIMESTAMP）
--   -> 上述列 DML 有非空值，加工 SQL 不设置，不一致
--
-- ISSUE 2: projectBeginDate/projectFinishDate DML 为 '2026-01-01 00:00:00' 格式，
--   但加工 SQL 日期正则匹配后输出 YYYYMMDD（如 '20260101'），不一致。
--   源数据使用 '2026-01-01 00:00:00'，加工 SQL 会转为 '20260101'。
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
DELETE FROM app_specific_loan_project_check_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_fixed_loan             WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_info                   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档；显式 id 供 fixed_loan.mainId 指向）
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-09-02 21:00:00');

-- =====================================================================
-- 2. xd_corp_check_fixed_loan（特定贷款检查；mainId 指向主档 id）
--    列：id, mainId, reportNo, customerId, customerName, objectName, balance,
--        businessSum, capitalCheckCondition, capitalFundInvoiced, capitalFundUnInvoiced,
--        capitalFundUsed, contractNo, duebillTotalBusinessSum, loanFundInvoiced,
--        loanFundUnInvoiced, loanFundUsed, nominalBalanceSum, otherFundInvoiced,
--        otherFundUnInvoiced, otherFundUsed, productBelongName, productName,
--        projectBeginDate, projectFinishDate, purpose, repaySum, runCheckCondition,
--        scheduleCheckCondition, superviseCheckCondition, totalInvestInvoiced,
--        totalInvestUnInvoiced, totalInvestUsed, vouchType, inputtime
--
--    purpose LEFT(...,128) 截断（均 < 128 字符，无影响）
--    vouchType LEFT(...,32) 截断（均 < 32 字符，无影响）
--    projectBeginDate '2026-01-01 00:00:00' -> SUBSTR(1,10)='2026-01-01' 匹配 -> '20260101'
--      ISSUE: DML 显示 '2026-01-01 00:00:00'，加工 SQL 输出 '20260101'，不一致
-- =====================================================================

INSERT INTO xd_corp_check_fixed_loan (
    id, mainId, reportNo, customerId, customerName, objectName, balance,
    businessSum, capitalCheckCondition, capitalFundInvoiced, capitalFundUnInvoiced,
    capitalFundUsed, contractNo, duebillTotalBusinessSum, loanFundInvoiced,
    loanFundUnInvoiced, loanFundUsed, nominalBalanceSum, otherFundInvoiced,
    otherFundUnInvoiced, otherFundUsed, productBelongName, productName,
    projectBeginDate, projectFinishDate, purpose, repaySum, runCheckCondition,
    scheduleCheckCondition, superviseCheckCondition, totalInvestInvoiced,
    totalInvestUnInvoiced, totalInvestUsed, vouchType, inputtime
) VALUES
(1, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '固定资产', 5000.00,
 5000.00, '已落实，资本金足额到位', 1200.00, 0.00, 1000.00, 'GDZC-2026-001', 5000.00, 3800.00,
 1200.00, 3000.00, 4000.00, 0.00, 0.00, 0.00, '公司业务部', '固定资产贷款',
 '2026-01-01 00:00:00', '2027-06-01 00:00:00', '购置生产设备', 0.00, '不涉及',
 '建设进度正常，按计划推进', '监管账户流水正常', 5000.00, 0.00, 4000.00, '抵押+保证', '2026-09-02 21:35:56'),
(2, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '固定资产', 12000.00,
 12000.00, '已落实，分期到位', 600.00, 0.00, 500.00, 'GDZC-2026-002', 12000.00, 9200.00,
 2800.00, 8500.00, 11500.00, 0.00, 0.00, 0.00, '公司业务部', '固定资产贷款',
 '2026-03-01 00:00:00', '2027-12-01 00:00:00', '技术改造升级', 0.00, '不涉及',
 '建设进度正常，按计划推进', '监管账户流水正常', 12000.00, 0.00, 9000.00, '抵押', '2026-09-02 21:35:56'),
(3, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '房地产开发贷款', 30000.00,
 30000.00, '已落实，资本金按进度到位', 1800.00, 0.00, 1500.00, 'FDK-2026-003', 30000.00, 22000.00,
 8000.00, 20000.00, 28500.00, 1500.00, 0.00, 1500.00, '房地产金融部', '房地产开发贷款',
 '2026-02-01 00:00:00', '2028-12-01 00:00:00', '住宅开发建设', 0.00, '不涉及',
 '建设进度正常，按计划推进', '监管账户流水正常', 30000.00, 0.00, 23000.00, '抵押+质押', '2026-09-02 21:35:56'),
(4, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '房地产开发贷款', 25000.00,
 25000.00, '已落实，股东借款转增资本金', 1200.00, 0.00, 1000.00, 'FDK-2026-004', 25000.00, 19500.00,
 5500.00, 18000.00, 24000.00, 1000.00, 0.00, 1000.00, '房地产金融部', '房地产开发贷款',
 '2026-04-01 00:00:00', '2028-06-01 00:00:00', '商业地产开发', 0.00, '不涉及',
 '建设进度正常，按计划推进', '监管账户流水正常', 26000.00, 0.00, 20000.00, '抵押', '2026-09-02 21:35:56');

-- =====================================================================
-- 验证说明：
--   1. xd_corp_check_info id=1 为唯一当前主档，4 行 fixed_loan mainId=1 指向
--   2. contractNo 各不同（GDZC-2026-001/002, FDK-2026-003/004），去重各出 1 行
--   3. purpose/vouchType 均 < 截断长度，LEFT 无影响
--   4. 金额列 DECIMAL(18,2) 直映
--   5. ISSUE 1: 19 列（explain/ifbuild 等）加工 SQL 不映射，DML 有非空值，需手工补充
--   6. ISSUE 2: projectBeginDate/projectFinishDate 加工 SQL 输出 YYYYMMDD，
--      DML 显示 '2026-01-01 00:00:00' 格式，不一致
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_specific_loan_project.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》特定贷款检查（项目类）· 源头表 -> app_specific_loan_project_check_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info          对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_fixed_loan    特定贷款检查数组（固定资产、房地产开发贷款，mainId -> xd_corp_check_info.id）
-- 目标：app_specific_loan_project_check_info（业务主键 reportNo + customerId + contractNo，一笔贷款一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_check_record.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_specific_loan_project_check_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按业务主键 (contractNo) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 32 列直映（源列名 == app 列名），仅 4 处源宽 > app 宽需 LEFT 截断防越界：
--        projectBeginDate  源 VARCHAR(64)  -> app VARCHAR(32)  LEFT(...,32)
--        projectFinishDate 源 VARCHAR(64)  -> app VARCHAR(32)  LEFT(...,32)
--        purpose           源 VARCHAR(255) -> app VARCHAR(128) LEFT(...,128)
--        vouchType         源 VARCHAR(64)  -> app VARCHAR(32)  LEFT(...,32)
--      金额列均为 DECIMAL(18,2) 直映；说明列源 VARCHAR(1000) -> app TEXT 不越界不截断
--   4. objectName 码值（固定资产/房地产开发贷款）原样透传
-- =====================================================================

-- 1. 幂等
DELETE FROM app_specific_loan_project_check_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 特定贷款检查（项目类）：xd_corp_check_fixed_loan（JOIN 当前主档）-> app_specific_loan_project_check_info
INSERT INTO app_specific_loan_project_check_info (
    reportNo, customerId, customerName, objectName, balance, businessSum,
    capitalCheckCondition, capitalFundInvoiced, capitalFundUnInvoiced, capitalFundUsed,
    contractNo, duebillTotalBusinessSum, loanFundInvoiced, loanFundUnInvoiced, loanFundUsed,
    nominalBalanceSum, otherFundInvoiced, otherFundUnInvoiced, otherFundUsed,
    productBelongName, productName, projectBeginDate, projectFinishDate, purpose,
    repaySum, runCheckCondition, scheduleCheckCondition, superviseCheckCondition,
    totalInvestInvoiced, totalInvestUnInvoiced, totalInvestUsed, vouchType
)
SELECT
    c.reportNo, c.customerId, c.customerName, c.objectName, c.balance, c.businessSum,
    c.capitalCheckCondition, c.capitalFundInvoiced, c.capitalFundUnInvoiced, c.capitalFundUsed,
    c.contractNo, c.duebillTotalBusinessSum, c.loanFundInvoiced, c.loanFundUnInvoiced, c.loanFundUsed,
    c.nominalBalanceSum, c.otherFundInvoiced, c.otherFundUnInvoiced, c.otherFundUsed,
    c.productBelongName, c.productName,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.projectBeginDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.projectBeginDate, 1, 10), '-', ''), '/', '')
         ELSE c.projectBeginDate END AS projectBeginDate,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.projectFinishDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.projectFinishDate, 1, 10), '-', ''), '/', '')
         ELSE c.projectFinishDate END AS projectFinishDate,
    LEFT(c.purpose, 128)          AS purpose,
    c.repaySum, c.runCheckCondition, c.scheduleCheckCondition, c.superviseCheckCondition,
    c.totalInvestInvoiced, c.totalInvestUnInvoiced, c.totalInvestUsed,
    LEFT(c.vouchType, 32)         AS vouchType
FROM (
    SELECT c.*, ROW_NUMBER() OVER (
        PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.contractNo, '')
        ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_fixed_loan c
    JOIN (
        SELECT id FROM (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_info
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) mc WHERE mc.rn = 1
    ) m ON c.mainId = m.id
) c
WHERE c.rn = 1;
