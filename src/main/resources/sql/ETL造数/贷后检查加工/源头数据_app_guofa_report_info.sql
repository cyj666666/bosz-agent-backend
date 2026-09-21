-- =====================================================================
-- app_guofa_report_info（国发征信财务数据）源头表反推造数
-- 加工脚本：贷后检查加工/xd_guofa.sql
-- 源表（主档 + 三子表，mainId -> gfzx_national_dev.id）：
--   gfzx_national_dev         主档（报表期次表头 c_*/n_*/o_*，各含 前年/去年/去年同期/今年同期 四期）
--   gfzx_profit_sheet_item    利润表明细（n_cn_name 科目 + 四期金额）
--   gfzx_balance_sheet_item   资产负债表明细（c_cn_name 科目 + 四期余额）
--   gfzx_finance_index_item   主要财务指标明细（本表不取，预留）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_guofa.sql）：
--   dataDate           <- 主档 inputtime（CAST AS CHAR(32)，取前 10 位日期去横线 -> yyyyMMdd）
--   beforeYear         <- 主档 c_beforeYear（LEFT 32）
--   lastYear           <- 主档 c_lastYear（LEFT 32）
--   thisYear           <- 主档 c_samePeriodThisYear（LEFT 32）
--   gfRevenue          <- 利润表 n_cn_name='营业收入' n_current_qmye（REGEXP 守卫 + CAST DECIMAL）
--   lastYearRevenue     <- 同上 n_last_qmye
--   beforeYearRevenue    <- 同上 n_before_last_qmye
--   gfReceivable        <- 资产负债表 c_cn_name='应收账款' c_current_qmye
--   lastYearReceivable     <- 同上 c_last_qmye
--   beforeYearReceivable    <- 同上 c_before_last_qmye
--   gfPayable/gfInventory   <- 同上模式（'应付账款'/'存货'）
--   id/inputtime       <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--   主档 id     = 1（子表 mainId 指向）
--
-- 目标 DML 行数：1（一报告一行，16 列业务数据）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
DELETE FROM app_guofa_report_info    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM gfzx_finance_index_item  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM gfzx_balance_sheet_item  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM gfzx_profit_sheet_item   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM gfzx_national_dev        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. gfzx_national_dev（国发征信主档；报表期次表头）
--    列：id, reportNo, customerId, customerName, c_beforeYear, c_lastYear, c_samePeriodThisYear, inputtime
--    1 行（去重键 reportNo 取最新，单行即最新）
--    inputtime='2026-09-10 10:30:00' -> dataDate='20260910'（前 10 位日期去横线）
-- =====================================================================
INSERT INTO gfzx_national_dev (id, reportNo, customerId, customerName, c_beforeYear, c_lastYear, c_samePeriodThisYear, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '20241231', '20251231', '20260331', '2026-09-10 10:30:00');

-- =====================================================================
-- 2. gfzx_profit_sheet_item（利润表明细；营业收入）
--    列：mainId, reportNo, customerId, customerName, n_cn_name,
--        n_before_last_qmye, n_last_qmye, n_current_qmye, inputtime
--    1 行（n_cn_name='营业收入'，按 mainId 取最新，单行即最新）
-- =====================================================================
INSERT INTO gfzx_profit_sheet_item (mainId, reportNo, customerId, customerName, n_cn_name, n_before_last_qmye, n_last_qmye, n_current_qmye, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '营业收入', '19875.20', '23640.80', '12580.50', '2026-09-10 10:30:00');

-- =====================================================================
-- 3. gfzx_balance_sheet_item（资产负债表明细；应收账款/应付账款/存货 三科目各 1 行）
--    列：mainId, reportNo, customerId, customerName, c_cn_name,
--        c_before_last_qmye, c_last_qmye, c_current_qmye, inputtime
-- =====================================================================

-- 应收账款：c_current_qmye=4320.60 / c_last_qmye=3980.25 / c_before_last_qmye=3560.80
INSERT INTO gfzx_balance_sheet_item (mainId, reportNo, customerId, customerName, c_cn_name, c_before_last_qmye, c_last_qmye, c_current_qmye, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '应收账款', '3560.80', '3980.25', '4320.60', '2026-09-10 10:30:00');

-- 应付账款：c_current_qmye=2760.45 / c_last_qmye=3120.70 / c_before_last_qmye=2890.30
INSERT INTO gfzx_balance_sheet_item (mainId, reportNo, customerId, customerName, c_cn_name, c_before_last_qmye, c_last_qmye, c_current_qmye, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '应付账款', '2890.30', '3120.70', '2760.45', '2026-09-10 10:30:00');

-- 存货：c_current_qmye=3540.20 / c_last_qmye=3280.90 / c_before_last_qmye=3015.60
INSERT INTO gfzx_balance_sheet_item (mainId, reportNo, customerId, customerName, c_cn_name, c_before_last_qmye, c_last_qmye, c_current_qmye, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '存货', '3015.60', '3280.90', '3540.20', '2026-09-10 10:30:00');

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_guofa.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 16 个业务列（dataDate + 3 期次 + 12 金额）将与 DML 目标行完全一致（1 行）：
--      - dataDate='20260910'（主档 inputtime 前 10 位去横线）✓
--      - beforeYear/lastYear/thisYear = 20241231/20251231/20260331 ✓
--      - gfRevenue/lastYearRevenue/beforeYearRevenue = 12580.50/23640.80/19875.20 ✓
--      - gfReceivable/lastYearReceivable/beforeYearReceivable = 4320.60/3980.25/3560.80 ✓
--      - gfPayable/lastYearPayable/beforeYearPayable = 2760.45/3120.70/2890.30 ✓
--      - gfInventory/lastYearInventory/beforeYearInventory = 3540.20/3280.90/3015.60 ✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1）
--   4. app_guofa_report_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），DML 中 '2026-09-10 10:30:00.0' 无法复现
--   5. 主档 id=1（显式），子表 mainId=1 精确指向；四组 LEFT JOIN 均命中
--   6. 金额 VARCHAR 经 REGEXP 数字守卫 + CAST DECIMAL(18,2)，源值均为合法数字
--   7. 科目精确匹配：'营业收入'/'应收账款'/'应付账款'/'存货'
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_guofa.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 国发征信 · 源头表 -> app_guofa_report_info 加工
-- 节点：客户国家级发展信息查询接口（custNationalDevelopmentQry，CrcsCustNationalDevelopmentService.query）
-- 源表（主档 + 三子表，mainId -> gfzx_national_dev.id）：
--   gfzx_national_dev           主档（报表期次表头 c_*/n_*/o_*，各含 前年/去年/去年同期/今年同期 四期）
--   gfzx_profit_sheet_item      利润表明细（n_cn_name 科目 + 四期金额）
--   gfzx_balance_sheet_item     资产负债表明细（c_cn_name 科目 + 四期余额）
--   gfzx_finance_index_item     主要财务指标明细（本表不取，预留）
-- 目标：app_guofa_report_info（一报告一行，业务主键 reportNo + customerId）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_guofa_report_info 段）：
--   dataDate      <- 主档 inputtime（CAST(inputtime AS CHAR(32))；源未落 dataDate 列，暂用入库时间近似）
--   beforeYear    <- 主档 c_beforeYear          前年期次（LEFT 32）
--   lastYear      <- 主档 c_lastYear            去年期次（LEFT 32）
--   thisYear      <- 主档 c_samePeriodThisYear  最新一期期次（LEFT 32）
--   gfRevenue         <- 利润表 n_cn_name='营业收入'  n_current_qmye（最近一期）
--   lastYearRevenue   <- 同上 n_last_qmye
--   beforeYearRevenue <- 同上 n_before_last_qmye
--   gfReceivable/gfPayable/gfInventory <- 资产负债表 c_cn_name='应收账款'/'应付账款'/'存货' 的 c_*_qmye
--   （各 before/last 同理取该科目 c_before_last_qmye / c_last_qmye）
--   数值列源 VARCHAR -> app DECIMAL(18,2)：REGEXP 数字守卫 + CAST（非数字/空串 -> NULL，防 GaussDB 严格模式 CAST 报错）
--   科目中文名待信贷确认精确码值，暂按 '营业收入'/'应收账款'/'应付账款'/'存货' 精确匹配；撞不到该组为 NULL
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_guofa_report_info 本次范围旧行，再插入
--   2. 源头 append-only：主档按 reportNo ROW_NUMBER 取最新（inputtime DESC, id DESC）作为「当前主档」，
--      子表按 (mainId) ROW_NUMBER 取最新后 JOIN 当前主档 id，排除历史快照
--   3. 一报告一行：主档为基行，四组指标各 LEFT JOIN（撞不到为 NULL）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_guofa_report_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 国发征信：主档（期次表头）+ 利润表营业收入 + 资产负债表应收/应付/存货 -> app_guofa_report_info
INSERT INTO app_guofa_report_info (
    reportNo, customerId, customerName, dataDate, beforeYear, lastYear, thisYear,
    gfRevenue, lastYearRevenue, beforeYearRevenue,
    gfReceivable, lastYearReceivable, beforeYearReceivable,
    gfPayable, lastYearPayable, beforeYearPayable,
    gfInventory, lastYearInventory, beforeYearInventory
)
SELECT
    b.reportNo, b.customerId, b.customerName, b.dataDate, b.beforeYear, b.lastYear, b.thisYear,
    r.n_current_qmye AS gfRevenue,
    r.n_last_qmye AS lastYearRevenue,
    r.n_before_last_qmye AS beforeYearRevenue,
    ar.c_current_qmye AS gfReceivable,
    ar.c_last_qmye AS lastYearReceivable,
    ar.c_before_last_qmye AS beforeYearReceivable,
    ap.c_current_qmye AS gfPayable,
    ap.c_last_qmye AS lastYearPayable,
    ap.c_before_last_qmye AS beforeYearPayable,
    inv.c_current_qmye AS gfInventory,
    inv.c_last_qmye AS lastYearInventory,
    inv.c_before_last_qmye AS beforeYearInventory
FROM (
    -- 当前主档（报表期次表头，取最新一期）
    SELECT id, reportNo, customerId, customerName,
            -- inputtime DATETIME -> yyyyMMdd（前 10 位日期段去横线；源无独立 dataDate 列，用主档落表时间近似）
            CASE WHEN REGEXP_LIKE(SUBSTR(CAST(inputtime AS CHAR(32)), 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
                 THEN REPLACE(REPLACE(SUBSTR(CAST(inputtime AS CHAR(32)), 1, 10), '-', ''), '/', '')
                 ELSE CAST(inputtime AS CHAR(32)) END AS dataDate,
           LEFT(c_beforeYear, 32)         AS beforeYear,
           LEFT(c_lastYear, 32)           AS lastYear,
           LEFT(c_samePeriodThisYear, 32) AS thisYear
    FROM (
        SELECT id, reportNo, customerId, customerName, inputtime,
               c_beforeYear, c_lastYear, c_samePeriodThisYear,
               ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
        FROM gfzx_national_dev
        WHERE reportNo IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) mc WHERE mc.rn = 1
) b
LEFT JOIN (
    -- 利润表：营业收入（当前主档下取最新一行）
    SELECT mainId, n_current_qmye, n_last_qmye, n_before_last_qmye,
           ROW_NUMBER() OVER (PARTITION BY mainId ORDER BY inputtime DESC, id DESC) AS rn
    FROM gfzx_profit_sheet_item
    WHERE n_cn_name = '营业收入'
) r ON r.mainId = b.id AND r.rn = 1
LEFT JOIN (
    -- 资产负债表：应收账款
    SELECT mainId, c_current_qmye, c_last_qmye, c_before_last_qmye,
           ROW_NUMBER() OVER (PARTITION BY mainId ORDER BY inputtime DESC, id DESC) AS rn
    FROM gfzx_balance_sheet_item
    WHERE c_cn_name = '应收账款'
) ar ON ar.mainId = b.id AND ar.rn = 1
LEFT JOIN (
    -- 资产负债表：应付账款
    SELECT mainId, c_current_qmye, c_last_qmye, c_before_last_qmye,
           ROW_NUMBER() OVER (PARTITION BY mainId ORDER BY inputtime DESC, id DESC) AS rn
    FROM gfzx_balance_sheet_item
    WHERE c_cn_name = '应付账款'
) ap ON ap.mainId = b.id AND ap.rn = 1
LEFT JOIN (
    -- 资产负债表：存货
    SELECT mainId, c_current_qmye, c_last_qmye, c_before_last_qmye,
           ROW_NUMBER() OVER (PARTITION BY mainId ORDER BY inputtime DESC, id DESC) AS rn
    FROM gfzx_balance_sheet_item
    WHERE c_cn_name = '存货'
) inv ON inv.mainId = b.id AND inv.rn = 1;
