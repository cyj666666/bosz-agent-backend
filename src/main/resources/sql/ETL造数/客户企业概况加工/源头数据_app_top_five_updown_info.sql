-- =====================================================================
-- app_top_five_updown_info（前五大上下游）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_top_five_updown.sql
-- 源表：
--   xd_corp_check_info          对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_supplier      前五大上下游供应商名称子表（mainId -> xd_corp_check_info.id）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_top_five_updown.sql，6 业务列）：
--   reportNo/customerId/customerName  直映（取自 xd_corp_check_supplier 自身列）
--   supplier   <- supplier            VARCHAR(255) -> VARCHAR(128)，LEFT(...,128) 截断
--   supplierType/supplierTypeName     原样透传
--   去重：JOIN 当前主档（xd_corp_check_info 取最新 id）+ ROW_NUMBER(reportNo, customerId, supplier, supplierType) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：10（前五大上游 01 ×5 + 前五大下游 02 ×5，供应商名各不相同）
--
-- ISSUE 1: DML 有 8 列，加工 SQL 只插入 6 列。未映射列：
--   id（auto）/inputtime（DEFAULT CURRENT_TIMESTAMP）
--   -> DML inputtime 有非空值（'2026-09-11 09:00:00.0' ~ '09:45:00.0'），加工 SQL 不设置，
--      实际入库为执行时刻 CURRENT_TIMESTAMP，与 DML 不一致。
--
-- 验证说明：
--   1. 去重键 (reportNo, customerId, supplier, supplierType) — 10 行 supplier 各不相同，全部存活
--   2. supplier 名称均 < 128 字符，LEFT(...,128) 不截断，原样输出
--   3. reportNo/customerId/customerName 取自 xd_corp_check_supplier 自身列（加工 SQL 外层 c 即 supplier 表）
--   4. xd_corp_check_info 仅用于 JOIN 过滤（取最新主档 id），其业务列不进入 app 表
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
DELETE FROM app_top_five_updown_info   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_supplier     WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_info         WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档；显式 id 供 supplier.mainId 指向）
--    列：id, reportNo, customerId, customerName, serialNo, bapSerialNo,
--        bapStartDate, bapMaturity, bapTextNo, bapReportNo, baReportNo,
--        lastReportNo, checkDate, baSerialNo, approveApplyType,
--        electroApproveSerialNo, inputtime
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-09-02 21:00:00');

-- =====================================================================
-- 2. xd_corp_check_supplier（前五大上下游供应商；mainId 指向主档 id=1）
--    列：id, mainId, reportNo, customerId, customerName, supplier,
--        supplierType, supplierTypeName, inputtime
--    10 行：前五大上游(01) ×5 + 前五大下游(02) ×5
--    注：reportNo/customerId/customerName 在 supplier 表自身列设置（加工 SQL 直映）
-- =====================================================================
INSERT INTO xd_corp_check_supplier (id, mainId, reportNo, customerId, customerName, supplier, supplierType, supplierTypeName, inputtime)
VALUES
    (1,  1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '江苏恒力特钢有限公司',     '01', '前五大上游', '2026-09-11 09:00:00'),
    (2,  1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '上海精工轴承有限公司',     '01', '前五大上游', '2026-09-11 09:05:00'),
    (3,  1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '苏州华鑫金属材料有限公司', '01', '前五大上游', '2026-09-11 09:10:00'),
    (4,  1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '无锡泰达电机有限公司',     '01', '前五大上游', '2026-09-11 09:15:00'),
    (5,  1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '常州瑞新机械配件有限公司', '01', '前五大上游', '2026-09-11 09:20:00'),
    (6,  1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '杭州智造装备有限公司',     '02', '前五大下游', '2026-09-11 09:25:00'),
    (7,  1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '南京自动化科技有限公司',   '02', '前五大下游', '2026-09-11 09:30:00'),
    (8,  1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '宁波海天精密工业有限公司', '02', '前五大下游', '2026-09-11 09:35:00'),
    (9,  1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '合肥中科智能装备有限公司', '02', '前五大下游', '2026-09-11 09:40:00'),
    (10, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '常州新锐机械有限公司',     '02', '前五大下游', '2026-09-11 09:45:00');

-- =====================================================================
-- 3. 验证（加工 SQL 运行后预期）
--    app_top_five_updown_info 应产生 10 行：
--      reportNo='RPT-202609-001', customerId='CUST-001', customerName='苏州XX精密机械制造有限公司'
--      supplier / supplierType / supplierTypeName 与上方 10 行一致（supplier 均 < 128 字符，无截断）
--      inputtime = CURRENT_TIMESTAMP（非 DML 中的 '2026-09-11 09:xx:xx.0'，见 ISSUE 1）
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_top_five_updown.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》前五大上下游 · 源头表 -> app_top_five_updown_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info          对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_supplier      前五大上下游供应商名称子表（mainId -> xd_corp_check_info.id）
-- 目标：app_top_five_updown_info（业务主键 reportNo + customerId + supplier + supplierType，一个供应商一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_top_five_updown_info 段，全部「原始」直映）：
--   supplier         <- supplier          供应商名称（源 VARCHAR(255) -> app VARCHAR(128)，LEFT 截断防越界）
--   supplierType     <- supplierType      供应商类型（码值 01 前五大上游 / 02 前五大下游 / 03 前三大上游 / 04 前三大下游，原样透传）
--   supplierTypeName <- supplierTypeName  供应商类型名称（原样透传）
--
-- 处理规则（对齐 xd_specific_loan_project.sql / xd_check_record.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_top_five_updown_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按业务主键 (reportNo, customerId, supplier, supplierType) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 上游「前五大供应商名称数组」一个元素落一行；同一主档下可含前五大上游+前五大下游多条
-- =====================================================================

-- 1. 幂等
DELETE FROM app_top_five_updown_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 前五大上下游：xd_corp_check_supplier（JOIN 当前主档）-> app_top_five_updown_info
INSERT INTO app_top_five_updown_info (
    reportNo, customerId, customerName, supplier, supplierType, supplierTypeName
)
SELECT
    c.reportNo, c.customerId, c.customerName,
    LEFT(c.supplier, 128) AS supplier,
    c.supplierType,
    c.supplierTypeName
FROM (
    SELECT c.*, ROW_NUMBER() OVER (
        PARTITION BY c.reportNo, COALESCE(c.customerId, ''),
                     COALESCE(c.supplier, ''), COALESCE(c.supplierType, '')
        ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_supplier c
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
