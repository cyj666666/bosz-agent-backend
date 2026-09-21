-- =====================================================================
-- app_entrust_pay_info（受托支付）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_entrust_pay.sql
-- 源表：
--   xd_credit_info     授信用信主档（父表）
--   xd_credit_loan     借据信息（mainId -> xd_credit_info.id）
--   xd_credit_payment  受托支付（mainId -> xd_credit_loan.id）
--   ws_gs_info         启信宝工商照面（外数，按收款人 name 撞 endDate）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_entrust_pay.sql，7 业务列）：
--   reportNo/customerId/customerName  直映
--   paymentMode   码值映射: 10->自主支付, 20->受托支付, 30->部分受托支付
--   payDate       日期正则 -> YYYYMMDD；否则原样透传
--   accountName   直映
--   payeeCancelDate <- ws_gs_info.endDate（LEFT JOIN by reportNo+name，日期正则变换）
--   去重：ROW_NUMBER(reportNo, customerId, customerName) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：2
--
-- CRITICAL ISSUE: 去重键为 (reportNo, customerId, customerName)，两行全相同，
--   加工 SQL 只保留最新 1 行（inputtime DESC），无法产出 DML 2 行。
--   需修改加工 SQL 去重键（如增加 accountName）方能产出 2 行。
--
-- ISSUE: DML 有 9 列，加工 SQL 只插入 7 列。inputtime 列 DML 非空
--   ('2026-09-01 10:15:00.0' 等)，DEFAULT CURRENT_TIMESTAMP，不一致
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
DELETE FROM app_entrust_pay_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_credit_payment     WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_credit_loan        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_credit_info        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_gs_info            WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_credit_info（授信用信主档；显式 id 供 credit_loan.mainId 指向）
-- =====================================================================
INSERT INTO xd_credit_info (id, reportNo, customerId, customerName, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 08:00:00');

-- =====================================================================
-- 2. xd_credit_loan（借据信息；mainId 指向 credit_info.id）
--    加工 SQL JOIN credit_loan 取 loanId 供 payment.mainId 指向
-- =====================================================================
INSERT INTO xd_credit_loan (id, mainId, reportNo, customerId, customerName, loanSerialNo, inputtime)
VALUES (1, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-001', '2026-03-05 09:00:00');

-- =====================================================================
-- 3. xd_credit_payment（受托支付；mainId 指向 credit_loan.id）
--    列：id, mainId, reportNo, customerId, customerName, paymentMode, payDate,
--        accountName, inputtime
--
--    payDate '2026-08-01' -> 匹配日期正则 -> '20260801'
--    payDate '2026-06-20' -> 匹配日期正则 -> '20260620'
-- =====================================================================

-- ---------- Row 1: paymentMode=20(受托支付) ----------
INSERT INTO xd_credit_payment (
    id, mainId, reportNo, customerId, customerName, paymentMode, payDate, accountName, inputtime
) VALUES (
    1, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '20', '2026-08-01', '苏州XX精密机械制造有限公司基本户', '2026-09-01 10:15:00'
);

-- ---------- Row 2: paymentMode=10(自主支付) ----------
INSERT INTO xd_credit_payment (
    id, mainId, reportNo, customerId, customerName, paymentMode, payDate, accountName, inputtime
) VALUES (
    2, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '10', '2026-06-20', '苏州XX精密机械制造有限公司结算户', '2026-08-05 09:20:00'
);

-- =====================================================================
-- 4. ws_gs_info（启信宝工商照面；按 name 撞 accountName 取 endDate）
--    列：id, reportNo, customerId, customerName, name, endDate, inputtime
--    LEFT JOIN: g.reportNo = c.reportNo AND g.name = c.accountName AND g.rn = 1
--
--    endDate '2026-08-25' -> 匹配日期正则 -> '20260825' (payeeCancelDate for Row 1)
--    endDate '2026-07-15' -> 匹配日期正则 -> '20260715' (payeeCancelDate for Row 2)
-- =====================================================================

-- ---------- ws_gs_info for Row 1 accountName ----------
INSERT INTO ws_gs_info (id, reportNo, customerId, customerName, name, endDate, inputtime)
VALUES (1, 'RPT-202609-001', NULL, NULL, '苏州XX精密机械制造有限公司基本户', '2026-08-25', '2026-09-01 10:00:00');

-- ---------- ws_gs_info for Row 2 accountName ----------
INSERT INTO ws_gs_info (id, reportNo, customerId, customerName, name, endDate, inputtime)
VALUES (2, 'RPT-202609-001', NULL, NULL, '苏州XX精密机械制造有限公司结算户', '2026-07-15', '2026-08-05 09:00:00');

-- =====================================================================
-- 验证说明：
--   1. credit_info id=1 为唯一当前主档，credit_loan id=1 mainId=1 指向
--   2. 两行 payment mainId=1 指向当前借据
--   3. payDate '2026-08-01'/'2026-06-20' 匹配日期正则 -> '20260801'/'20260620'
--   4. ws_gs_info LEFT JOIN by (reportNo, name=accountName) 取 endDate
--      '2026-08-25'/'2026-07-15' -> '20260825'/'20260715'
--   5. CRITICAL ISSUE: 去重键 (reportNo, customerId, customerName) 两行全相同，
--      加工 SQL 只保留最新 1 行，无法产出 DML 2 行
--   6. ISSUE: inputtime 列加工 SQL 不设置，DML 有非空值，需手工补充
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_entrust_pay.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 我行授信用信情况》受托支付数组 · 源头表 -> app_entrust_pay_info 加工
-- 节点：我行授信用信情况》借据信息数组》受托支付（aflCreditLoanQry 响应 loanInfoList[].entrustedPaymentList，CrcsAfterLoanAiService.aflCreditLoanQry）
-- 源表：
--   xd_credit_info     授信用信主档（父表，aflCreditLoanQry 落表）
--   xd_credit_loan     借据信息（mainId -> xd_credit_info.id）
--   xd_credit_payment  受托支付（mainId -> xd_credit_loan.id）
--   ws_gs_info         启信宝工商照面 QXB_GSZM01（外数，按收款人企业落表；取注销日期 endDate）
-- 目标：app_entrust_pay_info（一客户一报告一行；《SZ银行DH智能体》1-数据字典 J列业务主键=reportNo+customerId+customerName，
--       同客户同报告多笔支付去重折叠为最新一笔）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_collateral.sql / xd_shareholder_info.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_entrust_pay_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」->「当前借据」排除历史快照，
--      再按业务主键 (reportNo, customerId, customerName) ROW_NUMBER 取最新（inputtime DESC, id DESC）。
--      去重键 = 字典 J 列业务主键三列；同客户同报告多笔支付折叠为最新一笔。
--   3. 码值（支付方式）待确认的原样透传
--   4. 源宽 > app 宽 2 处 LEFT 截断防越界：payDate 源 VARCHAR(64)->app VARCHAR(32)；
--      payeeCancelDate 源 ws_gs_info.endDate VARCHAR(64)->app VARCHAR(32)
--   5. payeeCancelDate（受托支付对象注销日期）：用收款人名称 accountName 撞 ws_gs_info.name（启信宝工商照面 QXB_GSZM01）
--      取 endDate（营业有效期截止=注销日期）；ws_gs_info 按 (reportNo, name) 去重取最新后 LEFT JOIN，
--      不按 customerId 过滤（收款人企业落表 customerId 可能是收款人自身）；撞不到为 NULL
--      （前提：外数侧需按收款人企业逐个调 QXB_GSZM01 落表 ws_gs_info，否则该列为 NULL）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_entrust_pay_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 受托支付明细：xd_credit_payment（JOIN 当前主档 -> 当前借据）+ ws_gs_info（收款人注销日期）-> app_entrust_pay_info
INSERT INTO app_entrust_pay_info (reportNo, customerId, customerName, paymentMode, payDate, accountName, payeeCancelDate)
SELECT
    c.reportNo, c.customerId, c.customerName,
    CASE c.paymentMode
        WHEN '10' THEN '自主支付'
        WHEN '20' THEN '受托支付'
        WHEN '30' THEN '部分受托支付'
        ELSE c.paymentMode
    END AS paymentMode,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.payDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.payDate, 1, 10), '-', ''), '/', '')
         ELSE c.payDate END AS payDate,
    c.accountName,
    CASE WHEN REGEXP_LIKE(SUBSTR(g.endDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(g.endDate, 1, 10), '-', ''), '/', '')
         ELSE g.endDate END AS payeeCancelDate
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.paymentMode, c.payDate, c.accountName,
            ROW_NUMBER() OVER (
                PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.customerName, ''),
                    COALESCE(c.accountName, '')
                ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_credit_payment c
    JOIN (
        SELECT l.id AS loanId
        FROM xd_credit_loan l
        JOIN (
            SELECT id FROM (
                SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
                FROM xd_credit_info
                WHERE reportNo IS NOT NULL
                  AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
            ) mc WHERE mc.rn = 1
        ) m ON l.mainId = m.id
    ) cur ON c.mainId = cur.loanId
) c
LEFT JOIN (
    SELECT reportNo, name, endDate,
           ROW_NUMBER() OVER (PARTITION BY reportNo, COALESCE(name, '') ORDER BY inputtime DESC, id DESC) AS rn
    FROM ws_gs_info
    WHERE reportNo IS NOT NULL
      AND name IS NOT NULL
      AND (reportNo = 'RPT-202609-001' OR 'RPT-202609-001' IS NULL)
) g ON g.reportNo = c.reportNo AND g.name = c.accountName AND g.rn = 1
WHERE c.rn = 1;
