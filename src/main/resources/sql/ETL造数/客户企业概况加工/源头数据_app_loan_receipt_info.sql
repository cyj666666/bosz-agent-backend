-- =====================================================================
-- app_loan_receipt_info（借据信息台账）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_loan_receipt.sql
-- 源表：
--   xd_credit_info  授信用信主档（父表）
--   xd_credit_loan  借据信息（mainId -> xd_credit_info.id）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_loan_receipt.sql，26 业务列）：
--   reportNo/customerId/customerName/loanSerialNo/loanStatus  直映
--   productName/productBelongName/balance/businessSum  直映（DECIMAL 透传）
--   overdueBalance/overdueInterestAmt  直映
--   isRestructed/isExtend/fixedAssetLoan/realEstateDevLoan/occurType  直映
--   loanChangeRptBalance  直映
--   repaymentPeriod  码值->中文 CASE：'01'->按月, '02'->按季, '03'->一次, '04'->按半年, '05'->按年, '06'->指定周期, '07'->按季（固定）；NULL/未收录原样保留
--   purposeName <- c.purpose（源列名不同）
--   loanChangeRptCounts  VARCHAR -> CAST AS INTEGER（REGEXP 数字守卫）
--   nextPayDate   日期正则 -> YYYYMMDD；否则原样透传
--   payPrinciPalamt/payInterestamt/payFineAmt/compoundinterest  VARCHAR -> CAST AS DECIMAL(18,2)
--   businessRate  VARCHAR -> CAST AS DECIMAL(12,4)
--   去重：JOIN 当前主档 + ROW_NUMBER(reportNo, customerId, loanSerialNo) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202603-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：12（loanSerialNo: LOAN-202603-001 ~ 012）
--
-- ISSUE: DML 有 33 列，加工 SQL 只插入 26 列。未映射列：
--   producttype='基础'/'固贷'/'房地产'（源表无此列，无法产出，不一致）
--   extendbalance/restructedbalance/reorgtimes/reorgbalance（源表有列但加工 SQL 不映射 -> NULL，不一致）
--   inputtime（DEFAULT CURRENT_TIMESTAMP，不一致）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
DELETE FROM app_loan_receipt_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_credit_loan        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_credit_info        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';

-- =====================================================================
-- 1. xd_credit_info（授信用信主档；显式 id 供 credit_loan.mainId 指向）
-- =====================================================================
INSERT INTO xd_credit_info (id, reportNo, customerId, customerName, inputtime)
VALUES (1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 08:00:00');

-- =====================================================================
-- 2. xd_credit_loan（借据信息；mainId 指向 credit_info.id）
--    列：id, mainId, reportNo, customerId, customerName, loanSerialNo, loanStatus,
--        productName, productBelongName, businessSum, balance, overdueBalance,
--        overdueInterestAmt, purpose, loanChangeRptCounts, loanChangeRptBalance,
--        isExtend, isRestructed, occurType, fixedAssetLoan, realEstateDevLoan,
--        nextPayDate, payPrinciPalAmt, payInterestAmt, payFineAmt, compoundInterest,
--        businessRate, repaymentPeriod, inputtime
--
--    nextPayDate '2026-03-31' -> 匹配日期正则 -> '20260331'
--    loanChangeRptCounts '1' -> REGEXP 数字 -> CAST AS INTEGER = 1
--    payPrinciPalAmt '0.00' -> REGEXP 数字 -> CAST AS DECIMAL = 0.00
--    businessRate '4.3500' -> REGEXP 数字 -> CAST AS DECIMAL(12,4) = 4.3500
--    purpose '股东还款' -> purposeName 直映
-- =====================================================================

INSERT INTO xd_credit_loan (
    id, mainId, reportNo, customerId, customerName, loanSerialNo, loanStatus,
    productName, productBelongName, businessSum, balance, overdueBalance,
    overdueInterestAmt, purpose, loanChangeRptCounts, loanChangeRptBalance,
    isExtend, isRestructed, occurType, fixedAssetLoan, realEstateDevLoan,
    nextPayDate, payPrinciPalAmt, payInterestAmt, payFineAmt, compoundInterest,
    businessRate, repaymentPeriod, inputtime
) VALUES
(1, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-001', '正常结清',
 '短期流动资金贷款', '征信贷', 1000.00, 2000.00, 0.00, 0.00, '股东还款', '1', 10.00,
 '否', '否', '借新还旧', '否', '否', '2026-03-31', '0.00', '0.00', '0.00', '0.00', '4.3500', '01', '2026-03-05 10:30:00'),
(2, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-002', '提前结清',
 '银行承兑汇票', '信保贷', 1001.00, 3000.00, 0.00, 0.00, '采购支付', '2', 11.00,
 '是', '否', '借新还旧', '否', '否', '2026-03-30', '0.00', '0.00', '0.00', '0.00', '4.7500', '02', '2026-03-06 14:20:00'),
(3, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-003', '逾期结清',
 '短期流动资金贷款', '一般产品额度', 1002.00, 1000.00, 200.00, 15.50, '日常运营', '3', 12.00,
 '是', '否', '其他', '否', '否', '2026-03-29', '0.00', '0.00', '0.00', '0.00', '5.2000', '04', '2026-03-07 09:15:00'),
(4, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-004', '理赔结清',
 '基本建设项目贷款', '一般产品额度', 1003.00, 1000.00, 0.00, 0.00, '项目建设', '4', 13.00,
 '是', '否', '其他', '是', '否', '2026-03-28', '0.00', '0.00', '0.00', '0.00', '4.1500', '03', '2026-03-08 16:45:00'),
(5, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-005', '未结清',
 '技术改造项目贷款', '一般产品额度', 1004.00, 500.00, 100.00, 8.20, '归还股东借款', '5', 14.00,
 '是', '是', '其他', '是', '否', '2026-04-15', '20.00', '1.80', '0.50', '0.20', '4.5000', '05', '2026-03-09 11:00:00'),
(6, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-006', '未结清',
 '其他类项目贷款', '一般产品额度', 1005.00, 0.00, 0.00, 0.00, '资金周转', '6', 15.00,
 '是', '是', '其他', '否', '否', '2026-05-20', '0.00', '0.00', '0.00', '0.00', '0.0000', '06', '2026-03-10 08:30:00'),
(7, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-007', '未结清',
 '经营性物业贷款', '一般产品额度', 1006.00, 300.00, 30.00, 2.60, '物业经营', '7', 16.00,
 '否', '否', '其他', '否', '否', '2026-04-10', '10.00', '1.20', '0.30', '0.10', '4.6500', '01', '2026-03-11 13:20:00'),
(8, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-008', '未结清',
 '房地产开发贷款', '一般产品额度', 1007.00, 700.00, 80.00, 6.90, '项目开发', '8', 17.00,
 '否', '否', '其他', '否', '是', '2026-06-01', '25.00', '3.50', '1.20', '0.50', '5.8000', '02', '2026-03-12 10:00:00'),
(9, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-009', '未结清',
 '短期流动资金贷款', '信保贷', 1008.00, 450.00, 50.00, 4.10, '应急周转', '0', 0.00,
 '否', '否', '新增', '否', '否', '2026-04-25', '15.00', '2.00', '0.60', '0.20', '4.3500', '01', '2026-03-13 15:30:00'),
(10, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-010', '正常结清',
 '银行承兑汇票', '征信贷', 1008.00, 600.00, 0.00, 0.00, '贸易结算', '1', 5.00,
 '否', '否', '借新还旧', '否', '否', '2026-03-27', '0.00', '0.00', '0.00', '0.00', '4.5000', '04', '2026-03-14 09:45:00'),
(11, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-011', '逾期结清',
 '经营性物业贷款', '一般产品额度', 1009.00, 350.00, 120.00, 10.30, '物业改造', '2', 8.00,
 '是', '是', '其他', '否', '否', '2026-03-26', '0.00', '0.00', '0.00', '0.00', '5.0000', '05', '2026-03-15 11:20:00'),
(12, 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-012', '未结清',
 '房地产开发贷款', '一般产品额度', 1010.00, 1200.00, 200.00, 18.50, '住宅开发', '0', 0.00,
 '否', '否', '新增', '否', '是', '2026-07-01', '30.00', '5.00', '2.00', '1.00', '6.2000', '02', '2026-03-16 14:00:00');

-- =====================================================================
-- 验证说明：
--   1. credit_info id=1 为唯一当前主档，12 行 credit_loan mainId=1 指向
--   2. loanSerialNo 各不同，去重各出 1 行，共 12 行
--   3. purpose 直映 -> purposeName（'股东还款'/'采购支付' 等）
--   4. loanChangeRptCounts VARCHAR '1'~'8'/'0' -> CAST AS INTEGER
--   5. nextPayDate '2026-03-31' 等 -> 匹配日期正则 -> '20260331' 等
--   6. payPrinciPalAmt/payInterestAmt/payFineAmt/compoundInterest VARCHAR -> CAST AS DECIMAL
--   7. businessRate VARCHAR '4.3500' 等 -> CAST AS DECIMAL(12,4)
--   8. ISSUE: producttype/extendbalance/restructedbalance/reorgtimes/reorgbalance/inputtime
--      列加工 SQL 不映射或不设置，DML 有非空值，需手工补充
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_loan_receipt.sql
-- Params: customerId='CUST-001', reportNo='RPT-202603-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 我行授信用信情况》借据信息数组 · 源头表 -> app_loan_receipt_info 加工
-- 节点：我行授信用信情况》借据信息数组（aflCreditLoanQry 响应 loanInfoList，CrcsAfterLoanAiService.aflCreditLoanQry）
-- 源表：
--   xd_credit_info  授信用信主档（父表，aflCreditLoanQry 落表）
--   xd_credit_loan  借据信息（mainId -> xd_credit_info.id）
-- 目标：app_loan_receipt_info（业务主键 reportNo + customerId + loanSerialNo）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_loan_receipt_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_credit_info.id) 排除历史快照，
--      再按 loanSerialNo ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 金额源头已 DECIMAL(18,2) 直接透传（balance/businessSum 等）；计数/利率/下次还款明细源头 VARCHAR -> CAST
--      （NULLIF 防空串，businessRate -> DECIMAL(12,4)，还款明细 -> DECIMAL(18,2)）
--      businessSum（借款金额，2026-09-15 新增列）源 DECIMAL(18,2) 直映
--   4. 码值（借据状态/发生类型/是否展期/是否重组/固贷/房开）待确认的原样透传
-- =====================================================================

-- 1. 幂等
DELETE FROM app_loan_receipt_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL);

-- 2. 借据信息：xd_credit_loan（JOIN 当前主档）-> app_loan_receipt_info
INSERT INTO app_loan_receipt_info (
    reportNo, customerId, customerName, loanSerialNo, loanStatus, productName, purposeName,
    balance, businessSum, productBelongName, overdueBalance, overdueInterestAmt, isRestructed,
    loanChangeRptCounts, loanChangeRptBalance, occurType, isExtend,
    fixedAssetLoan, realEstateDevLoan, nextPayDate, payPrinciPalamt, payInterestamt,
    payFineAmt, compoundinterest, businessRate, RepaymentPeriod
)
SELECT
    c.reportNo, c.customerId, c.customerName, c.loanSerialNo, c.loanStatus, c.productName,
    c.purpose AS purposeName,
    c.balance, c.businessSum, c.productBelongName, c.overdueBalance, c.overdueInterestAmt, c.isRestructed,
    c.loanChangeRptCounts AS loanChangeRptCounts,
    c.loanChangeRptBalance, c.occurType, c.isExtend,
    c.fixedAssetLoan, c.realEstateDevLoan,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.nextPayDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.nextPayDate, 1, 10), '-', ''), '/', '')
         ELSE c.nextPayDate END AS nextPayDate,
    c.payPrinciPalAmt AS payPrinciPalamt,
    c.payInterestAmt AS payInterestamt,
    c.payFineAmt AS payFineAmt,
    c.compoundInterest AS compoundinterest,
    c.businessRate AS businessRate,
    -- 还款周期：码值->中文（01按月/02按季/03一次/04按半年/05按年/06指定周期/07按季（固定）），NULL/未收录原样保留
    CASE c.repaymentPeriod
        WHEN '01' THEN '按月'
        WHEN '02' THEN '按季'
        WHEN '03' THEN '一次'
        WHEN '04' THEN '按半年'
        WHEN '05' THEN '按年'
        WHEN '06' THEN '指定周期'
        WHEN '07' THEN '按季（固定）'
        ELSE c.repaymentPeriod
    END AS RepaymentPeriod
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.loanSerialNo, c.loanStatus, c.productName,
            c.purpose, c.balance, c.businessSum, c.productBelongName, c.overdueBalance, c.overdueInterestAmt,
           c.isRestructed, c.loanChangeRptCounts, c.loanChangeRptBalance, c.occurType, c.isExtend,
           c.fixedAssetLoan, c.realEstateDevLoan, c.nextPayDate, c.payPrinciPalAmt, c.payInterestAmt,
           c.payFineAmt, c.compoundInterest, c.businessRate, c.repaymentPeriod,
           ROW_NUMBER() OVER (PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.loanSerialNo, '')
                              ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_credit_loan c
    JOIN (
        SELECT id FROM (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_credit_info
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
        ) mc WHERE mc.rn = 1
    ) m ON c.mainId = m.id
) c
WHERE c.rn = 1;
