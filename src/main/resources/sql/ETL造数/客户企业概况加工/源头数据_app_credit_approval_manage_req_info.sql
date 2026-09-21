-- =====================================================================
-- app_credit_approval_manage_req_info（对公日检-授信批复管理要求）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_credit_approval_req.sql
-- 源表（父子表，mainId -> xd_corp_check_info.id=1，父表共享自 app_check_index_info）：
--   xd_corp_check_credit_requirement   授信批复后续管理要求 CreditFollowUpRequirement
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_credit_approval_req.sql，9 列）：
--   swqNo            <- seqNo              序号（LEFT 32 截断）
--   "CONDITION"      <- condition          授信后续管理要求内容
--   PELATIVESERIALNO <- relativeSerialNo   关联流水号
--   checkDate        <- checkDate          检查日期（正则命中归一 yyyy-MM-dd）
--   去重键 (reportNo, customerId, seqNo, condition, relativeSerialNo, checkDate)
--   ROW_NUMBER(inputtime DESC, id DESC)；先 JOIN 当前主档
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：1（1 条授信批复管理要求）
--   seqNo='1' / condition='我行授信未全部结清前抵押物不得出库（权证到期换证除外）'
--   relativeSerialNo='全部' / checkDate='2025-06-07' -> 加工后 checkDate='2025-06-07'
--
-- 共享父表：xd_corp_check_info id=1（来自 app_check_index_info 文件，本文件条件 IF NOT EXISTS 跳过创建）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源子表（不动父表 id=1）
-- =====================================================================
DELETE FROM app_credit_approval_manage_req_info   WHERE customerid = 'CUST-001' AND reportno = 'RPT-202609-001';
DELETE FROM xd_corp_check_credit_requirement      WHERE customerId = 'CUST-001' AND reportNo   = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_corp_check_info（共享父表，条件创建：仅当 id=1 不存在时插入）
--    排他父表来源：源头数据_app_check_index_info.sql（主创建者）
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
SELECT 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 10:30:00'
WHERE NOT EXISTS (SELECT 1 FROM xd_corp_check_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001');

-- =====================================================================
-- 2. xd_corp_check_credit_requirement（授信批复后续管理要求，1 行）
--    mainId=1；seqNo/condition/relativeSerialNo/checkDate 直映到 app 表
--    checkDate='2025-06-07' -> 正则命中 -> 加工后 '2025-06-07'（DATE 类型）
-- =====================================================================
INSERT INTO xd_corp_check_credit_requirement (
    mainId, reportNo, customerId, customerName, seqNo, condition, relativeSerialNo, checkDate, inputtime
) VALUES (
    1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
    '1', '我行授信未全部结清前抵押物不得出库（权证到期换证除外）', '全部', '2025-06-07',
    '2026-03-15 10:23:45'
);

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_credit_approval_req.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》授信批复管理要求 · 源头表 -> app_credit_approval_manage_req_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info                 对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_credit_requirement   授信批复后续管理要求 CreditFollowUpRequirement（mainId -> xd_corp_check_info.id）
-- 目标：app_credit_approval_manage_req_info（业务主键（字典 J 列）reportno + customerid + swqNo + "CONDITION" + PELATIVESERIALNO + checkDate）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 + DDL V1.20 注释，列名保留建表原拼写）：
--   swqNo              <- seqNo              序号（源 VARCHAR(64) -> app VARCHAR(32)，LEFT 截断）
--   "CONDITION"        <- condition          授信后续管理要求内容（源 VARCHAR(1000) -> app TEXT）
--   PELATIVESERIALNO   <- relativeSerialNo   关联流水号/对象
--   checkDate          <- checkDate          检查日期（源 VARCHAR 原样透传，不 CAST）
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerid, reportno) 删除本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按业务主键 ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 一次日检可有多条授信批复要求（不同序号/内容/对象），各出一行
-- =====================================================================

-- 1. 幂等
DELETE FROM app_credit_approval_manage_req_info
WHERE (customerid = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportno   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 授信批复管理要求：xd_corp_check_credit_requirement（JOIN 当前主档）-> app_credit_approval_manage_req_info
INSERT INTO app_credit_approval_manage_req_info (
    reportno, customerid, customername, swqNo, "CONDITION", PELATIVESERIALNO, checkDate
)
SELECT
    c.reportNo AS reportno,
    c.customerId AS customerid,
    c.customerName AS customername,
    LEFT(c.seqNo, 32) AS swqNo,
    c.condition AS "CONDITION",
    c.relativeSerialNo AS PELATIVESERIALNO,
    -- app 列 checkDate 为 DATE 类型：上游格式归一为 yyyy-MM-dd（- 分隔，兼容 / 分隔与带时分秒）
    CASE WHEN REGEXP_LIKE(SUBSTR(c.checkDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN CONCAT(SUBSTR(c.checkDate, 1, 4), '-', SUBSTR(c.checkDate, 6, 2), '-', SUBSTR(c.checkDate, 9, 2))
         ELSE c.checkDate END AS checkDate
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.seqNo, c.condition, c.relativeSerialNo, c.checkDate,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.seqNo, ''),
                            COALESCE(c.condition, ''), COALESCE(c.relativeSerialNo, ''), COALESCE(c.checkDate, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_credit_requirement c
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
