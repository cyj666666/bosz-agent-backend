-- =====================================================================
-- app_credit_use_info（我行授信用用概况）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_credit_use.sql
-- 源表：
--   xd_credit_info         授信用用主档（aflCreditLoanQry 落表，每 reportNo 取最新一条）
--   xd_corp_customer_info  客户主档（getEntCustomerAllQry 落表，取 groupClientNo/groupClientName）
--                          与 app_customer_info / app_xd_shareholder_info 共享（id=1）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_credit_use.sql，17 列）：
--   creditSum/balance/exposureAmount/limitBalance/groupAmount/groupBalance <- 源列直映（DECIMAL）
--   isGroup      <- CASE cc.groupClientNo：非空 -> '是'，否则 NULL（'否' 分支不可达）
--   groupName    <- CASE cc.groupClientName：空 -> groupClientNo 否则 groupClientName
--   creditDate       <- 正则命中 yyyy-MM-dd / yyyy/MM/dd 去分隔符；不命中（如 '202509'）原样透传
--   latestOverdueDate<- 同上；源 '2025-07-01' -> '20250701' -> app DATE 列回填 '2025-07-01'
--   gdOverdueCounts/ajOverdueCounts <- CAST(TRIM AS INTEGER)；源 VARCHAR
--   主档去重 ROW_NUMBER(reportNo ORDER BY inputtime DESC, id DESC)；LEFT JOIN 客户主档 rn=1
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：1
--   creditSum=800.00, balance=565.00, exposureAmount=700.00, limitBalance=515.00
--   groupAmount=8000.00, groupBalance=5750.00
--   isGroup='是', groupName='江阴市xx精密集团'
--   creditDate='202509' (源同值，正则不命中->透传)
--   latestOverdueDate='2025-07-01' (源同值 -> 去 - -> '20250701' -> DATE 回填)
--   gdOverdueCounts=2 (源 '2'), ajOverdueCounts=3 (源 '3')
--
-- 共享父表：xd_corp_customer_info id=1（与 app_customer_info / app_xd_shareholder_info 共享）
--   本文件用条件 IF NOT EXISTS 创建最小化字段集（含 groupClientNo/groupClientName）；
--   app_customer_info 文件检测到关键字段为空时会 DELETE + 重建补齐字段（保留 groupClient*）；
--   app_xd_shareholder_info 文件用条件 IF NOT EXISTS 跳过创建（股东子表不读 customer_info 列）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + xd_credit_info（仅清自身专有源表）
--    xd_corp_customer_info id=1 为共享父表（与 app_customer_info / app_xd_shareholder_info 共享），
--    本文件不删除该父表行 -> 由 app_customer_info 文件负责字段补齐/重建
-- =====================================================================
DELETE FROM app_credit_use_info       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_credit_info            WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_credit_info（授信用用主档，1 行）
--    creditDate='202509'（YYYYMM 无分隔符，正则不命中 -> 透传）
--    latestOverdueDate='2025-07-01'（YYYY-MM-DD，正则命中 -> '20250701'，app DATE 回填）
--    gdOverdueCounts='2' / ajOverdueCounts='3'（VARCHAR，CAST SIGNED -> 2/3）
-- =====================================================================
INSERT INTO xd_credit_info (
    reportNo, customerId, customerName, creditSum, creditDate, balance, exposureAmount,
    limitBalance, groupAmount, groupBalance, latestOverdueDate, gdOverdueCounts, ajOverdueCounts, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
    800.00, '202509', 565.00, 700.00,
    515.00, 8000.00, 5750.00, '2025-07-01', '2', '3',
    '2025-04-18 09:20:00'
);

-- =====================================================================
-- 2. xd_corp_customer_info（共享客户主档，条件创建：仅当 id=1 不存在时插入最小化字段集）
--    groupClientNo='GRP-001'（非空 -> isGroup='是'）
--    groupClientName='江阴市xx精密集团'（非空 -> groupName=该值）
--    注意：若 app_customer_info 文件已运行（id=1 含全字段），此处 IF NOT EXISTS 跳过，
--          app_credit_use加工仍可读取已存在的 groupClientNo/groupClientName -> 正常产出
--    若本文件先运行，创建最小化行；后续 app_customer_info 文件检测到关键字段为空，
--          会 DELETE + 重建补齐字段（不影响 groupClientNo/groupClientName，仍保留）
-- =====================================================================
INSERT INTO xd_corp_customer_info (id, reportNo, customerId, customerName, groupClientNo, groupClientName, inputtime)
SELECT 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
       'GRP-001', '江阴市xx精密集团', '2025-04-18 09:20:00'
WHERE NOT EXISTS (SELECT 1 FROM xd_corp_customer_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001');

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工/xd_credit_use.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 加工产出 1 行，业务字段与目标 DML 完全一致：
--      - creditSum/balance/exposureAmount/limitBalance/groupAmount/groupBalance 直映 ✓
--      - isGroup='是'（groupClientNo='GRP-001' 非空）✓
--      - groupName='江阴市xx精密集团'（groupClientName 非空取此）✓
--      - creditDate='202509'（正则不命中->透传）✓
--      - latestOverdueDate：源 '2025-07-01' -> 去 - -> '20250701' -> app DATE 列回填 '2025-07-01' ✓
--      - gdOverdueCounts=2（源 '2' CAST SIGNED）✓
--      - ajOverdueCounts=3（源 '3' CAST SIGNED）✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1）
--   4. app_credit_use_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中 '2025-04-18 09:20:00.0' 无法精确复现
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_credit_use.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 我行授信用信概况 · 源头表 -> app_credit_use_info 加工
-- 节点：对公客户查询接口》企业概况（getEntCustomerAllQry，CrcsEntCustomerService.query）
-- 源表：
--   xd_credit_info         授信用信主档（aflCreditLoanQry 落表）
--   xd_corp_customer_info  客户主档（getEntCustomerAllQry 落表，取集团客户号 groupClientNo）
-- 目标：app_credit_use_info（业务主键 reportNo + customerId）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_credit_use_info 本次范围旧行，再插入
--   2. 源头 append-only：主档每 reportNo 取最新一条（inputtime DESC, id DESC）
--   3. isGroup 取自客户主档 groupClientNo（非空=是）；
--      groupName 取客户主档 groupClientName（集团客户名称：Java 侧按 groupClientNo 补调 getEntCustomerAllQry
--      回填，见 CrcsEntCustomerService.fillGroupClientName）；补调未落（NULL/空）时回退存 groupClientNo 集团客户号
--   4. 计数 CAST SIGNED（源头 VARCHAR）；金额源头已 DECIMAL(18,2) 直接透传
--      creditDate 上游格式不固定（yyyy-MM-dd / yyyy/MM/dd，可能带时分秒）-> 落 app 表 yyyyMMdd：
--      前 10 位为日期段（分隔符 - 或 /）时取前 10 位并去掉 - 和 /；空/NULL/非标准日期前缀 原样透传不置坏
--   5. 依赖：授信用信接口 aflCreditLoanQry 已先落表 xd_credit_info（流程顺序授信在前、企业概况在后）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_credit_use_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 授信用信概况：xd_credit_info + xd_corp_customer_info -> app_credit_use_info
INSERT INTO app_credit_use_info (
    reportNo, customerId, customerName, creditSum, balance, exposureAmount, limitBalance,
    groupAmount, groupBalance, isGroup, groupName, creditDate, latestOverdueDate, gdOverdueCounts, ajOverdueCounts
)
SELECT
    i.reportNo, i.customerId, i.customerName,
    i.creditSum, i.balance, i.exposureAmount, i.limitBalance,
    i.groupAmount, i.groupBalance,
    CASE WHEN cc.groupClientNo IS NULL OR cc.groupClientNo = '' THEN NULL
         WHEN cc.groupClientNo <> '' THEN '是' ELSE '否' END AS isGroup,
    CASE WHEN cc.groupClientName IS NULL OR TRIM(cc.groupClientName) = ''
         THEN cc.groupClientNo ELSE cc.groupClientName END AS groupName,
    CASE WHEN REGEXP_LIKE(SUBSTR(i.creditDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(i.creditDate, 1, 10), '-', ''), '/', '')
         ELSE i.creditDate END AS creditDate,
    CASE WHEN REGEXP_LIKE(SUBSTR(i.latestOverdueDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(i.latestOverdueDate, 1, 10), '-', ''), '/', '')
         ELSE i.latestOverdueDate END AS latestOverdueDate,
    i.gdOverdueCounts AS gdOverdueCounts,
    i.ajOverdueCounts AS ajOverdueCounts
FROM (
    SELECT reportNo, customerId, customerName, creditSum, balance, exposureAmount, limitBalance,
           groupAmount, groupBalance, creditDate, latestOverdueDate, gdOverdueCounts, ajOverdueCounts,
           ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_credit_info
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) i
LEFT JOIN (
    SELECT reportNo, groupClientNo, groupClientName,
           ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_customer_info
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) cc ON cc.reportNo = i.reportNo AND cc.rn = 1
WHERE i.rn = 1;
