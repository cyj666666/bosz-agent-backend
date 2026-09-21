-- =====================================================================
-- app_early_warning_info（预警任务台账）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_early_warning.sql
-- 源表：
--   xd_corp_check_info          对公检查主档（父表；加工按 reportNo 取最新主档）
--   xd_corp_check_warning_task  预警任务表 WarningTask（mainId -> xd_corp_check_info.id）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_early_warning.sql，10 业务列）：
--   reportNo/customerId/customerName/serialNo  直映
--   confirmTime   SUBSTR(1,10) REGEXP 日期 -> YYYYMMDD；否则原样透传
--   inputDate     同 confirmTime 变换
--   approveStatusName/riskTaskType/taskType  直映透传
--   warnLevel     <- identifyCustomWaringLevel（源列名不同，显式 AS）
--   去重：JOIN 当前主档 + ROW_NUMBER(reportNo, customerId, serialNo) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：2（serialNo: YJ-202603-001, YJ-202603-002）
--
-- ISSUE: DML 有 15 列，加工 SQL 只插入 10 列。未映射列：
--   phaseopinion=NULL（DML NULL，一致）
--   endtime=NULL（DML NULL，一致）
--   riskreason='借款人资金回流模型命中3次...'（DML 非空，加工 SQL 不设置 -> NULL，不一致）
--   inputtime='2026-03-05 10:30:00.0'（DML 非空，app DDL DEFAULT CURRENT_TIMESTAMP，不一致）
--   -> riskreason/inputtime 需由其他加工或手工 UPDATE 补充
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
DELETE FROM app_early_warning_info     WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_warning_task WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_info         WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档；显式 id 供 warning_task.mainId 指向）
--    列：id, reportNo, customerId, customerName, inputtime
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 08:00:00');

-- =====================================================================
-- 2. xd_corp_check_warning_task（预警任务；mainId 指向主档 id）
--    列：id, mainId, reportNo, customerId, customerName, confirmTime, serialNo,
--        taskType, approveStatusName, riskTaskType, inputDate, identifyCustomWaringLevel, inputtime
--
--    confirmTime/inputDate 格式：'2026/03/05 10:30:00' -> SUBSTR(1,10)='2026/03/05'
--       匹配 ^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$ -> 归一为 '20260305'
--    warnLevel <- identifyCustomWaringLevel 直映
-- =====================================================================

-- ---------- Row 1: serialNo=YJ-202603-001 ----------
INSERT INTO xd_corp_check_warning_task (
    id, mainId, reportNo, customerId, customerName, confirmTime, serialNo, taskType,
    approveStatusName, riskTaskType, inputDate, identifyCustomWaringLevel, inputtime
) VALUES (
    1, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026/03/05 10:30:00', 'YJ-202603-001', '审批通过预警任务',
    '审批通过', '预警认定', '2026/03/05 09:00:00', '红色', '2026-03-05 10:30:00'
);

-- ---------- Row 2: serialNo=YJ-202603-002 ----------
INSERT INTO xd_corp_check_warning_task (
    id, mainId, reportNo, customerId, customerName, confirmTime, serialNo, taskType,
    approveStatusName, riskTaskType, inputDate, identifyCustomWaringLevel, inputtime
) VALUES (
    2, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026/03/05 11:00:00', 'YJ-202603-002', '最近一条预警任务',
    '审批中', '预警解除', '2026/03/05 10:00:00', '红色', '2026-03-05 11:00:00'
);

-- =====================================================================
-- 验证说明：
--   1. xd_corp_check_info id=1 为唯一主档（reportNo=RPT-202609-001），加工取最新主档即此行
--   2. 两行 warning_task mainId=1 指向当前主档，serialNo 不同各自出 1 行
--   3. confirmTime='2026/03/05 10:30:00' SUBSTR(1,10)='2026/03/05' 匹配日期正则 -> '20260305'
--   4. inputDate='2026/03/05 09:00:00' 同理匹配 -> '20260305'
--   5. identifyCustomWaringLevel='红色' -> warnLevel='红色'
--   6. ISSUE: riskreason/inputtime 列加工 SQL 不设置，DML 有非空值，需手工补充
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_early_warning.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》预警任务台账 · 源头表 -> app_early_warning_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info          对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_warning_task  预警任务表 WarningTask（mainId -> xd_corp_check_info.id）
-- 目标：app_early_warning_info（业务主键 reportNo + customerId + serialNo，一预警任务一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_check_record.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_early_warning_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按业务主键 (serialNo) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 10 列映射（源列名多数 == app 列名），2 处源宽 > app 宽需 LEFT 截断防越界：
--        confirmTime  源 VARCHAR(64) -> app VARCHAR(32)  LEFT(...,32)
--        inputDate    源 VARCHAR(64) -> app VARCHAR(32)  LEFT(...,32)
--      其余 serialNo/approveStatusName/riskTaskType/taskType 源宽<=app 宽，直映
--   4. warnLevel 预警等级 ← 源列 identifyCustomWaringLevel（源列名拼写不同需显式 AS）
--   5. approveStatusName/riskTaskType/warnLevel 码值待确认，原样透传不翻译
-- =====================================================================

-- 1. 幂等
DELETE FROM app_early_warning_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 预警任务台账：xd_corp_check_warning_task（JOIN 当前主档）-> app_early_warning_info
INSERT INTO app_early_warning_info (
    reportNo, customerId, customerName, serialNo, confirmTime, inputDate,
    approveStatusName, riskTaskType, taskType, warnLevel
)
SELECT
    c.reportNo, c.customerId, c.customerName, c.serialNo,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.confirmTime, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.confirmTime, 1, 10), '-', ''), '/', '')
         ELSE c.confirmTime END AS confirmTime,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.inputDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.inputDate, 1, 10), '-', ''), '/', '')
         ELSE c.inputDate END AS inputDate,
    c.approveStatusName, c.riskTaskType, c.taskType,
    c.identifyCustomWaringLevel AS warnLevel
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.serialNo, c.confirmTime, c.inputDate,
           c.approveStatusName, c.riskTaskType, c.taskType, c.identifyCustomWaringLevel,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.serialNo, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_warning_task c
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
