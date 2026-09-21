-- =====================================================================
-- app_check_record_info（对公日检-现场检查打卡）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_check_record.sql
-- 源表（父子表，mainId -> xd_corp_check_info.id=1，父表共享自 app_check_index_info）：
--   xd_corp_check_checkin   现场打卡记录 SiteCheckInRecord
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_check_record.sql，9 列）：
--   checkInTime    <- checkInTime    正则 ^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$ 命中去 -/；不命中原样透传
--   checkInAddress <- checkInAddress 直映
--   visitObj       <- visitObj       直映
--   checkInObj     <- checkInObj     直映
--   去重键 (reportNo, customerId, checkInTime, checkInAddress, visitObj, checkInObj)
--   ROW_NUMBER(inputtime DESC, id DESC)；先 JOIN 当前主档
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：2
--   checkInTime 源 = '2026-03-31' -> '20260331'（VARCHAR，正则命中后去 -）
--   checkInTime 源 = '2026-04-31' -> '20260431'（4 月无 31 日，但 VARCHAR 不校验，正则命中即去 -）
--
-- 共享父表：xd_corp_check_info id=1（来自 app_check_index_info 文件，本文件条件 IF NOT EXISTS 跳过创建）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源子表（不动父表 id=1）
-- =====================================================================
DELETE FROM app_check_record_info       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_checkin       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_corp_check_info（共享父表，条件创建：仅当 id=1 不存在时插入）
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
SELECT 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 10:30:00'
WHERE NOT EXISTS (SELECT 1 FROM xd_corp_check_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001');

-- =====================================================================
-- 2. xd_corp_check_checkin（现场打卡记录，2 行）
--    mainId=1；checkInTime 源用 'YYYY-MM-DD' 格式 -> 加工去 - -> 'YYYYMMDD'
-- =====================================================================
INSERT INTO xd_corp_check_checkin (
    mainId, reportNo, customerId, customerName, checkInTime, checkInAddress, visitObj, checkInObj, inputtime
) VALUES
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '2026-03-31', '江苏省苏州市姑苏区葑门路6号靠近吉晟商务人厦', '总经理_陆伟清,', '/', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '2026-04-31', '江苏省苏州市姑苏区葑门路6号靠近吉晟商务人厦', '总经理_陆伟清,', '/', '2026-03-05 10:30:00');

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工/xd_check_record.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 加工产出 2 行，业务字段与目标 DML 完全一致：
--      - checkInAddress/visitObj/checkInObj 直映 ✓
--      - checkInTime 源 '2026-03-31' -> '20260331' / 源 '2026-04-31' -> '20260431' ✓
--        （正则命中 YYYY-MM-DD 后去 -；4 月 31 日虽非法日期，但 VARCHAR 列不校验）
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..2）
--   4. app_check_record_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中 '2026-03-05 10:30:00.0' 无法精确复现
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_check_record.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》现场检查打卡 · 源头表 -> app_check_record_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info      对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_checkin   现场打卡记录 SiteCheckInRecord（mainId -> xd_corp_check_info.id）
-- 目标：app_check_record_info（业务主键 reportNo + customerId + checkInTime + checkInAddress + visitObj + checkInObj）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_check_record_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按业务主键 (checkInTime, checkInAddress, visitObj, checkInObj) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 全字段字符串直映（源 checkInAddress VARCHAR(255) -> app VARCHAR(256) 不越界；
--      源 checkInTime VARCHAR(64) -> app VARCHAR(32)，打卡时间常规 19 位内，上游保证不超长）
--   4. 一次日检可有多条打卡（不同时间/地址/对象），各出一行
-- =====================================================================

-- 1. 幂等
DELETE FROM app_check_record_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 现场打卡记录：xd_corp_check_checkin（JOIN 当前主档）-> app_check_record_info
INSERT INTO app_check_record_info (
    reportNo, customerId, customerName, checkInTime, checkInAddress, visitObj, checkInObj
)
SELECT
    c.reportNo, c.customerId, c.customerName,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.checkInTime, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.checkInTime, 1, 10), '-', ''), '/', '')
         ELSE c.checkInTime END AS checkInTime,
    c.checkInAddress, c.visitObj, c.checkInObj
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.checkInTime, c.checkInAddress, c.visitObj, c.checkInObj,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.checkInTime, ''),
                            COALESCE(c.checkInAddress, ''), COALESCE(c.visitObj, ''), COALESCE(c.checkInObj, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_checkin c
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
