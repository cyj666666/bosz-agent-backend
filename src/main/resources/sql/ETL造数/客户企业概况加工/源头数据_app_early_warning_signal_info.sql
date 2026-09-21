-- =====================================================================
-- app_early_warning_signal_info（近一年预警信号台账）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_warning_signal.sql
-- 源表：
--   xd_warning_ledger  近一年预警台账主表（无父表/无 mainId，aflSignalAccountQry 落表）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_warning_signal.sql，8 业务列）：
--   reportNo/customerId/customerName/serialNo  直映
--   riskMessage   VARCHAR(1000) -> VARCHAR(500)  LEFT(...,500) 截断
--   status        码值->中文 CASE：'00'->无预警, '01'->待认定, '02'->已认定,
--                                   '03'->已调整, '04'->已解除; NULL/未收录原样保留
--   warningLevel  码值->中文 CASE：'4'->黄色预警, '6'->红色预警; NULL/未收录原样保留
--   inputDate     日期正则 -> YYYYMMDD；否则原样透传
--   去重：ROW_NUMBER(reportNo, customerId, serialNo) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202603-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：6（DML 中 serialNo 为 'LOAN-202603-001' ~ 'LOAN-202603-006'，各不相同）
--
-- ISSUE: DML 有 12 列，加工 SQL 只插入 8 列。未映射列：
--   count=0, readycount=0（DML 非空，加工 SQL 不设置 -> NULL，不一致）
--   inputtime='2026-09-10 19:12:54.879211'（DML 非空，DEFAULT CURRENT_TIMESTAMP，不一致）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
DELETE FROM app_early_warning_signal_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_warning_ledger              WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';

-- =====================================================================
-- 1. xd_warning_ledger（近一年预警台账；无 mainId，独立行）
--    列：id, reportNo, customerId, customerName, serialNo, riskMessage,
--        status, warningLevel, inputDate, inputtime
--
--    status 码值翻译：'01'->待认定, '02'->已认定（加工 CASE 翻译为中文）
--    warningLevel 码值翻译：'6'->红色, '4'->黄色（加工 CASE 翻译）
--    inputDate '2026-10-15' -> 匹配日期正则 -> '20261015'
--    riskMessage 均 < 500 字符 -> LEFT 截断无影响
-- =====================================================================

-- ---------- Row 1: status=02(已认定), warningLevel=6(红色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-001', '企业已逾期10天以上',
    '02', '6', '2026-10-15', '2026-09-10 19:12:54'
);

-- ---------- Row 2: status=01(待认定), warningLevel=4(黄色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    2, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-002', '企业已逾期10天以上',
    '01', '4', '2026-10-15', '2026-09-10 19:12:55'
);

-- ---------- Row 3: status=01(待认定), warningLevel=6(红色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    3, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-003', '企业已逾期10天以上',
    '01', '6', '2026-10-15', '2026-09-10 19:12:56'
);

-- ---------- Row 4: status=02(已认定), warningLevel=4(黄色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    4, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-004', '企业已逾期10天以上',
    '02', '4', '2026-10-15', '2026-09-10 19:12:57'
);

-- ---------- Row 5: status=01(待认定), warningLevel=6(红色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    5, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-005', '他行未结清关注类贷款余额两期对比上升',
    '01', '6', '2026-10-15', '2026-09-10 19:12:58'
);

-- ---------- Row 6: status=02(已认定), warningLevel=4(黄色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    6, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-006', '国有股东出资比例降低',
    '02', '4', '2026-10-15', '2026-09-10 19:12:59'
);

-- =====================================================================
-- 验证说明：
--   1. 6 行 xd_warning_ledger serialNo 各不相同（'LOAN-202603-001' ~ 'LOAN-202603-006'）
--   2. warningLevel 码值：'6'->红色, '4'->黄色（加工 CASE 翻译）
--   3. status 码值：'02'->已认定, '01'->待认定（加工 CASE 翻译）
--   4. inputDate '2026-10-15' 匹配日期正则 -> '20261015'
--   5. riskMessage 均 < 500 字符，LEFT 截断无影响
--   6. 去重键 (reportNo, customerId, serialNo) 各不相同，加工 SQL 产出 6 行 ✓
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_warning_signal.sql
-- Params: customerId='CUST-001', reportNo='RPT-202603-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 近一年预警台账 · 源头表 -> app_early_warning_signal_info 加工
-- 节点：近一年预警台账接口（aflSignalAccountQry，CrcsAfterLoanAiService.aflSignalAccountQry）
-- 源表：xd_warning_ledger（近一年预警台账主表 SignalAccount，aflSignalAccountQry 落表，无父表/无 mainId）
-- 目标：app_early_warning_signal_info（业务主键 reportNo + customerId + serialNo，一预警一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_single_task.sql；本表为父表自身，无 mainId，不 JOIN 主档）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_early_warning_signal_info 本次范围旧行，再插入
--   2. 源头 append-only：按业务主键 (reportNo, customerId, serialNo) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 7 列直映（源列名 == app 列名），仅 1 处源宽 > app 宽需 LEFT 截断防越界：
--        riskMessage  源 VARCHAR(1000) -> app VARCHAR(500)  LEFT(...,500)
--      其余 serialNo/status/warningLevel/inputDate 均源宽<=app 宽，直映
--   4. 码值处理（依据《苏州银行综合信贷系统_贷后智能体相关接口_V1.0》「码表」sheet）：
--        status（信号状态 00无预警/01待认定/02已认定/03已调整/04已解除）
--        码值->中文 内联 CASE，NULL/未收录原样保留；
--        warningLevel（预警等级 1无风险/2风险排查/4黄色预警/5橙色预警/6红色预警，码表无 3）
--        码值->中文 内联 CASE，NULL/未收录原样保留
-- =====================================================================

-- 1. 幂等
DELETE FROM app_early_warning_signal_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL);

-- 2. 近一年预警台账：xd_warning_ledger -> app_early_warning_signal_info
INSERT INTO app_early_warning_signal_info (
    reportNo, customerId, customerName, serialNo, riskMessage, status, warningLevel, inputDate
)
SELECT
    c.reportNo, c.customerId, c.customerName, c.serialNo,
    LEFT(c.riskMessage, 500) AS riskMessage,
    -- 信号状态：码值->中文（00无预警/01待认定/02已认定/03已调整/04已解除），NULL/未收录原样保留
    CASE c.status
        WHEN '00' THEN '无预警'
        WHEN '01' THEN '待认定'
        WHEN '02' THEN '已认定'
        WHEN '03' THEN '已调整'
        WHEN '04' THEN '已解除'
        ELSE c.status
    END AS status,
    -- 预警等级：码值->中文（1/2/4/5/6 码，码表无 3），NULL/未收录原样保留
    CASE WHEN c.warningLevel IS NULL THEN NULL
         WHEN c.warningLevel = '1' THEN '无风险'
         WHEN c.warningLevel = '2' THEN '风险排查'
         WHEN c.warningLevel = '4' THEN '黄色预警'
         WHEN c.warningLevel = '5' THEN '橙色预警'
         WHEN c.warningLevel = '6' THEN '红色预警'
          ELSE c.warningLevel END AS warningLevel,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.inputDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.inputDate, 1, 10), '-', ''), '/', '')
         ELSE c.inputDate END AS inputDate
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.serialNo, c.riskMessage,
           c.status, c.warningLevel, c.inputDate,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.serialNo, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_warning_ledger c
    WHERE c.reportNo IS NOT NULL
      AND (c.customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (c.reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
) c
WHERE c.rn = 1;
