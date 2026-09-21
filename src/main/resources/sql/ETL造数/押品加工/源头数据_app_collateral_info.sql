-- =====================================================================
-- app_collateral_info（押品主档）源头表造数（反推 DML 目标数据）
-- 处理 SQL：sql/押品加工/xd_collateral.sql（一次产出 押品三张 app 表）
-- 源表：
--   xd_corp_check_collateral          押品主档（CollateralItem，父表 xd_corp_check_info）
--   DDL 见：sql/源头表/信贷/DDL/对公检查信息查询接口_建表DDL.sql
-- 目标表：app_collateral_info（3 行，clrId=001/002/003）
-- 字段映射（源 -> app）：
--   reportNo      -> reportNo          （直接透传）
--   customerId    -> customerId        （直接透传）
--   customerName  -> customerName      （直接透传）
--   clrId         -> clrId             （直接透传；去重键 PARTITION BY reportNo,clrId）
--   ownerName     -> owner             （重命名 ownerName->owner）
--   clrType       -> clrType           （直接透传，码值待确认）
--   clrName       -> clrName           （直接透传）
--   clrStatus     -> clrStatus         （直接透传，码值待确认）
--   valuationDate -> valuationDate     （CASE: YYYY-MM-DD -> YYYYMMDD 去横杠）
--   choiceTypeName  码值->中文 CASE：'AgrPri'->内部协议作价, 'Inner'->内部估值, 'Outer'->外部估值; NULL/未收录原样保留
--   evaluateValue -> evaluateValue     （VARCHAR -> TRIM -> CAST DECIMAL(18,2)，非数字->NULL）
--   rightOrder    -> rightOrder        （直接透传）
--   rightSum      -> rightSum          （VARCHAR -> TRIM -> CAST DECIMAL(18,2)，非数字->NULL）
--   confirmDate   -> confirmDate       （CASE: YYYY-MM-DD -> YYYYMMDD 去横杠）
--   dyqDj/yyDj/cfDj/ygDj -> 同名       （直接透传；DML 目标未列出= NULL，故源表置 NULL）
-- 去重：ROW_NUMBER() PARTITION BY (reportNo, COALESCE(clrId, 内容键)) ORDER BY inputtime DESC, id DESC
-- 测试数据：reportNo='RPT-202603-001', customerId='CUST-001', customerName='苏州XX精密机械制造有限公司'
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清源头三表 + app 三表（CUST-001）
-- =====================================================================
DELETE FROM app_collateral_info             WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM app_collateral_mortgage_info    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM app_collateral_restricted_right WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_corp_check_collateral           WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_corp_check_collateral_mortgage  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_corp_check_collateral_restrict  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';

-- =====================================================================
-- 1. 押品主档 xd_corp_check_collateral（mainId 哑值，加工 SQL 不读取）
--    3 行，clrId 唯一（001/002/003），去重不会合并
-- =====================================================================

-- C1：clrId='001' 出让出宅用地 / 中原路50号住宅 / 正常 / Inner(内部估值) 3400 万 / 顺位2 / 权证 1000 万
INSERT INTO xd_corp_check_collateral (id, mainId, reportNo, customerId, customerName, clrId, ownerId, ownerName, clrType, clrName, clrStatus, rightOrder, rightSum, valuationDate, choiceTypeName, evaluateValue, confirmDate, dyqDj, yyDj, cfDj, ygDj, inputtime)
VALUES (900001, 990100001, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', '001', NULL, '张三', '出让出宅用地', '中原路50号住宅', '正常', '2', '1000.00', '2026-06-30', 'Inner', '3400.00', '2026-06-30', '否', '否', '否', '否', '2026-07-15 10:30:00');

-- C2：clrId='002' 商业用房 / 中原路128号商铺 / 正常 / AgrPri(内部协议作价) 1800 万 / 顺位1 / 权证 1500 万
INSERT INTO xd_corp_check_collateral (id, mainId, reportNo, customerId, customerName, clrId, ownerId, ownerName, clrType, clrName, clrStatus, rightOrder, rightSum, valuationDate, choiceTypeName, evaluateValue, confirmDate, dyqDj, yyDj, cfDj, ygDj, inputtime)
VALUES (900002, 990100002, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', '002', NULL, '张三', '商业用房', '中原路128号商铺', '正常', '1', '1500.00', '2026-06-30', 'AgrPri', '1800.00', '2026-06-30', '否', '否', '否', '否', '2026-07-15 10:30:00');

-- C3：clrId='003' 权利类 / XX科技公司30%股权 / 查封 / Outer(外部估值) 500 万 / 顺位1 / 权证 0 万
INSERT INTO xd_corp_check_collateral (id, mainId, reportNo, customerId, customerName, clrId, ownerId, ownerName, clrType, clrName, clrStatus, rightOrder, rightSum, valuationDate, choiceTypeName, evaluateValue, confirmDate, dyqDj, yyDj, cfDj, ygDj, inputtime)
VALUES (900003, 990100003, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', '003', NULL, '李四', '权利类', 'XX科技公司30%股权', '查封', '1', '0.00', '2026-06-30', 'Outer', '500.00', '2026-06-30', '否', '否', '是', '否', '2026-07-15 10:30:00');

-- =====================================================================
-- 验证说明：
-- 1. 上述 3 行 xd_corp_check_collateral 经 xd_collateral.sql 第 2 段 INSERT 加工后应产出
--    app_collateral_info 3 行（id 由 AUTO_INCREMENT 分配，1/2/3 顺序按插入顺序）。
-- 2. ISSUE（日期格式）：处理 SQL 对 valuationDate / confirmDate 做
--    SUBSTR(1,10) REGEXP '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$' 校验后去横杠（YYYY-MM-DD -> YYYYMMDD）。
--    源值 '2026-06-30' 命中正则 -> 加工输出 '20260630'，而 DML 目标为 '2026-06-30'（带横杠）。
--    不存在任何源值能令该 CASE 走 ELSE 分支同时原样返回 '2026-06-30'（10 字符必命中正则）。
--    故 valuationDate/confirmDate 实际加工结果为 '20260630'，与 DML 目标 '2026-06-30' 不一致。
-- 3. ISSUE（dyqDj/yyDj/cfDj/ygDj）：处理 SQL INSERT 列表含此 4 列（源->app 原样透传），
--    但 DML 目标 INSERT 列表未列出（= NULL）。故源表此 4 列置 NULL，加工后 app 表此 4 列亦为 NULL，与 DML 一致。
-- 4. evaluateValue='3400.00'/'1800.00'/'500.00' 均为合法数字，TRIM+CAST 后为 3400.00/1800.00/500.00。
-- 5. rightSum='1000.00'/'1500.00'/'0.00' 均为合法数字，CAST 后为 1000.00/1500.00/0.00。
-- 6. inputtime（app 表）由 DB DEFAULT CURRENT_TIMESTAMP 设定，非源表透传，加工时取运行时时间戳，
--    与 DML 目标 '2026-07-15 10:30:00.0' 可能不一致（运行时相关，非源数据可控）。
-- 7. 3 行 clrId 唯一（001/002/003），去重后各保留 1 行，符合目标 3 行。
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 押品加工\xd_collateral.sql
-- Params: customerId='CUST-001', reportNo='RPT-202603-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 押品 · 源头表 -> 应用层表加工（参考 财务指标加工/xd_financial.sql 模式）
-- 源表（对公检查接口 aflCheckDetailQry 落表，见 源头表/信贷/DDL/对公检查信息查询接口_建表DDL.sql）：
--   xd_corp_check_collateral           押品主档（CollateralItem）
--   xd_corp_check_collateral_mortgage  他项权利/抵押（OtherRight，mainId -> xd_corp_check_collateral.id）
--   xd_corp_check_collateral_restrict  限制权利/查封（RestrictionRight，mainId -> xd_corp_check_collateral.id）
-- 目标：app_collateral_info / app_collateral_mortgage_info / app_collateral_restricted_right
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式，正则用 REGEXP）
--
-- 处理规则：
--   1. 幂等：先按 (customerId, reportNo) 删除三张 app 表本次范围旧行，再插入
--   2. 源头表"接口返回直接追加插入，不做去重约束"，同一 reportNo 重复调用接口会重复落表，
--      故按业务键去重取最新一条（inputtime DESC, id DESC）：
--        押品主档  : (reportNo, clrId)；clrId 为空时按内容键(clrName+clrType+rightOrder+rightSum)兜底
--        他项权利  : 挂在"当前"押品行(mainId=最新主档.id)下，按 (主档键, 他项内容键) 去重
--        限制权利  : 同上，按 (主档键, 限制权人+限制权类型) 去重
--   3. 金额字段源头为 VARCHAR，先按数字正则校验再 CAST DECIMAL(18,2)，非数字/空 -> null
--   4. 子表无 clrId/clrName 列，经 mainId 关联父表带出
--   5. guaranteeScope 源头 VARCHAR(1000) 宽于 app 表 VARCHAR(256)，截断防止超长报错
--   6. clrType/clrStatus/pledgeTypeName/attachmentTypeName 码值表待确认，暂原样透传
--   7. 四类登记标记 DYQDJ(地役权登记)/YYDJ(异议登记)/CFDJ(查封登记)/YGDJ(预告登记)：
--      源表列名小写驼峰 dyqDj/yyDj/cfDj/ygDj，app 表列名大写 DYQDJ/YYDJ/CFDJ/YGDJ，原样透传
-- =====================================================================

-- 1. 幂等：先删除本次加工范围内的目标行（与下方过滤条件一致，避免重复加工叠加）
DELETE FROM app_collateral_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL);

DELETE FROM app_collateral_mortgage_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL);

DELETE FROM app_collateral_restricted_right
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL);

-- 2. 押品主档：xd_corp_check_collateral -> app_collateral_info
INSERT INTO app_collateral_info (
    reportNo, customerId, customerName, clrId, owner,
    clrType, clrName, clrStatus, valuationDate, choiceTypeName,
    evaluateValue, rightOrder, rightSum, confirmDate,
    dyqDj, yyDj, cfDj, ygDj
)
SELECT
    c.reportNo AS reportNo,
    c.customerId AS customerId,
    c.customerName AS customerName,
    c.clrId AS clrId,
    c.ownerName AS owner,
    c.clrType AS clrType,
    c.clrName AS clrName,
    c.clrStatus AS clrStatus,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.valuationDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.valuationDate, 1, 10), '-', ''), '/', '')
         ELSE c.valuationDate END AS valuationDate,
    -- 估值方式：码值->中文（AgrPri内部协议作价/Inner内部估值/Outer外部估值），NULL/未收录原样保留
    CASE c.choiceTypeName
        WHEN 'AgrPri' THEN '内部协议作价'
        WHEN 'Inner'  THEN '内部估值'
        WHEN 'Outer'  THEN '外部估值'
        ELSE c.choiceTypeName
    END AS choiceTypeName,
    c.evaluateValue AS evaluateValue,
    c.rightOrder AS rightOrder,
    c.rightSum AS rightSum,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.confirmDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.confirmDate, 1, 10), '-', ''), '/', '')
         ELSE c.confirmDate END AS confirmDate,
    c.dyqDj ,
    c.yyDj  ,
    c.cfDj  ,
    c.ygDj
FROM (
    -- 押品主档去重：每个 (reportNo, 业务键) 仅保留最新一条
    SELECT reportNo, customerId, customerName, clrId, ownerName,
           clrType, clrName, clrStatus, valuationDate, choiceTypeName,
           evaluateValue, rightOrder, rightSum, confirmDate,
           dyqDj, yyDj, cfDj, ygDj,
           ROW_NUMBER() OVER (
               PARTITION BY reportNo,
                   COALESCE(clrId,
                       CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                              '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
               ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_check_collateral
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
) c
WHERE c.rn = 1;

-- 3. 他项权利/抵押：xd_corp_check_collateral_mortgage -> app_collateral_mortgage_info
--    仅取挂在"当前"(最新)押品行下的记录，避免历史重复快照的子记录混入
INSERT INTO app_collateral_mortgage_info (
    reportNo, customerId, customerName, clrId,
    pledgeSerialNo, pledgeeName, guaranteeScope, pledgeTypeName,
    maxCreditorAmt, startEnd, registerTimestamp
)
SELECT
    t.reportNo AS reportNo,
    t.customerId AS customerId,
    t.customerName AS customerName,
    t.clrId AS clrId,
    t.pledgeSerialNo AS pledgeSerialNo,
    t.pledgeeName AS pledgeeName,
    LEFT(t.guaranteeScope, 256) AS guaranteeScope,
    t.pledgeTypeName AS pledgeTypeName,
    t.maxCreditorAmt AS maxCreditorAmt,
    t.startEnd AS startEnd,
    CASE WHEN REGEXP_LIKE(SUBSTR(t.registerTimestamp, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(t.registerTimestamp, 1, 10), '-', ''), '/', '')
         ELSE t.registerTimestamp END AS registerTimestamp
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.clrId,
           m.pledgeSerialNo, m.pledgeeName, m.guaranteeScope, m.pledgeTypeName,
           m.maxCreditorAmt, m.startEnd, m.registerTimestamp,
           ROW_NUMBER() OVER (
               PARTITION BY c.rnKey,
                   COALESCE(m.pledgeSerialNo,
                       CONCAT('N|', COALESCE(m.pledgeeName, ''), '|', COALESCE(m.pledgeTypeName, '')))
               ORDER BY m.inputtime DESC, m.id DESC) AS mRN
    FROM (
        -- 当前押品主档（与主档表同一去重口径，带出去重键 rnKey）
        SELECT reportNo, customerId, customerName, clrId,  id,
               COALESCE(clrId,
                   CONCAT('N|', COALESCE(clrType, ''),
                          '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, ''))) AS rnKey
        FROM (
            SELECT reportNo, customerId, customerName, clrId,  clrType, rightOrder, rightSum, id,
                   ROW_NUMBER() OVER (
                       PARTITION BY reportNo,
                           COALESCE(clrId,
                               CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                                      '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
                       ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_collateral
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
        ) pc
        WHERE pc.rn = 1
    ) c
    JOIN xd_corp_check_collateral_mortgage m ON m.mainId = c.id
) t
WHERE t.mRN = 1;

-- 4. 限制权利/查封：xd_corp_check_collateral_restrict -> app_collateral_restricted_right
INSERT INTO app_collateral_restricted_right (
    reportNo, customerId, customerName, clrId, attachmentOrg, attachmentTypeName
)
SELECT
    t.reportNo AS reportNo,
    t.customerId AS customerId,
    t.customerName AS customerName,
    t.clrId AS clrId,
    t.attachmentOrg AS attachmentOrg,
    t.attachmentTypeName AS attachmentTypeName
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.clrId,
           s.attachmentOrg, s.attachmentTypeName,
           ROW_NUMBER() OVER (
               PARTITION BY c.rnKey,
                   COALESCE(CONCAT(COALESCE(s.attachmentOrg, ''), '|', COALESCE(s.attachmentTypeName, '')), 'N')
               ORDER BY s.inputtime DESC, s.id DESC) AS sRN
    FROM (
        -- 当前押品主档（同上口径）
        SELECT reportNo, customerId, customerName, clrId, id,
               COALESCE(clrId,
                   CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                          '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, ''))) AS rnKey
        FROM (
            SELECT reportNo, customerId, customerName, clrId, clrName, clrType, rightOrder, rightSum, id,
                   ROW_NUMBER() OVER (
                       PARTITION BY reportNo,
                           COALESCE(clrId,
                               CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                                      '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
                       ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_collateral
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
        ) pc
        WHERE pc.rn = 1
    ) c
    JOIN xd_corp_check_collateral_restrict s ON s.mainId = c.id
) t
WHERE t.sRN = 1;
