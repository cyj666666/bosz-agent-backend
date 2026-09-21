-- =====================================================================
-- app_early_warning_opinion_info（预警意见台账）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_early_warning_opinion.sql
-- 源表：
--   xd_corp_check_info              对公检查主档（父表）
--   xd_corp_check_warning_task      预警任务表（mainId -> xd_corp_check_info.id）
--   xd_corp_check_warning_opinion    预警意见表（mainId -> xd_corp_check_warning_task.id）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_early_warning_opinion.sql，12 业务列）：
--   reportNo/customerId/customerName  直映（来自 opinion 表）
--   serialNo/confirmTime  来自父级 warning_task（cur.serialNo, cur.confirmTime）
--   seqNo      VARCHAR -> INT  REGEXP 数字守卫 + CAST（'1'->1, '2'->2）
--   endTime    VARCHAR(64) -> VARCHAR(32)  日期正则 -> YYYYMMDD；否则原样透传
--   activeName/approveUserName/approveOrgName/warningLevelName/phaseOpinion  直映
--   去重：JOIN 当前主档 -> 当前预警任务，ROW_NUMBER(reportNo, customerId, serialNo, seqNo)
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：2（serialNo=YJ-202603-001, seqNo=1/2）
--
-- ISSUE 1: DML 有 14 列，加工 SQL 只插入 12 列。inputtime 列 DML 非空
--         ('2026-09-10 20:05:32.724717')，app DDL DEFAULT CURRENT_TIMESTAMP，不一致
-- ISSUE 2: confirmTime 跨表不一致——app_early_warning_info DML 为 '2026/3/5 10:30'，
--         本表 DML 为 '2026/3/5'。两者来自同一 warning_task.confirmTime，
--         无法用单一源值同时满足。本文件取 confirmTime='2026/3/5' 以匹配本表 DML。
--         若同时运行 app_early_warning_info 加工，confirmTime 会与此不一致。
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
DELETE FROM app_early_warning_opinion_info  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_warning_opinion   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_warning_task      WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_info              WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档；显式 id 供 warning_task.mainId 指向）
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 08:00:00');

-- =====================================================================
-- 2. xd_corp_check_warning_task（预警任务；mainId 指向主档 id）
--    serialNo/confirmTime 随父任务行透传到 opinion 行
--    confirmTime='2026/3/5' -> SUBSTR(1,10)='2026/3/5' 不匹配日期正则 -> 原样透传
-- =====================================================================
INSERT INTO xd_corp_check_warning_task (
    id, mainId, reportNo, customerId, customerName, confirmTime, serialNo, taskType,
    approveStatusName, riskTaskType, inputDate, identifyCustomWaringLevel, inputtime
) VALUES (
    1, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026/3/5', 'YJ-202603-001', '审批通过预警任务',
    '审批通过', '预警认定', '2026/3/5 9:00', '红色', '2026-03-05 10:00:00'
);

-- =====================================================================
-- 3. xd_corp_check_warning_opinion（预警意见；mainId 指向 warning_task.id）
--    列：id, mainId, reportNo, customerId, customerName, seqNo, activeName,
--        approveUserName, approveOrgName, warningLevelName, phaseOpinion, endTime, inputtime
--
--    seqNo '1' -> REGEXP '^-?[0-9]+$' 匹配 -> CAST AS INTEGER = 1
--    endTime '2026-03-05' -> SUBSTR(1,10)='2026-03-05' 匹配日期正则 -> '20260305'
--    endTime '2026-03-06' -> 同理 -> '20260306'
-- =====================================================================

-- ---------- Row 1: seqNo=1 客户经理初审 ----------
INSERT INTO xd_corp_check_warning_opinion (
    id, mainId, reportNo, customerId, customerName, seqNo, activeName,
    approveUserName, approveOrgName, warningLevelName, phaseOpinion, endTime, inputtime
) VALUES (
    1, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '1', '客户经理初审',
    '李四', '苏州工业园区支行', '高', '经核实，借款人资金回流模型命中3次，资金流向异常，建议认定为高风险预警，提交分行审批。',
    '2026-03-05', '2026-03-05 10:30:00'
);

-- ---------- Row 2: seqNo=2 分行审批 ----------
INSERT INTO xd_corp_check_warning_opinion (
    id, mainId, reportNo, customerId, customerName, seqNo, activeName,
    approveUserName, approveOrgName, warningLevelName, phaseOpinion, endTime, inputtime
) VALUES (
    2, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2', '分行审批',
    '王五', '苏州分行', '高', '同意客户经理初审意见，认定为高风险预警。要求经营机构在2026年12月31日前完成整改，并定期上报整改进展。',
    '2026-03-06', '2026-03-05 11:00:00'
);

-- =====================================================================
-- 验证说明：
--   1. warning_task id=1 为唯一当前任务（serialNo=YJ-202603-001, confirmTime='2026/3/5'）
--   2. 两行 opinion mainId=1 指向该任务，seqNo='1'/'2' 不同各出 1 行
--   3. confirmTime 从父任务透传='2026/3/5'（不匹配日期正则原样透传）
--   4. seqNo '1'/'2' REGEXP 数字 -> CAST 为 INT 1/2
--   5. endTime '2026-03-05'/'2026-03-06' 匹配日期正则 -> '20260305'/'20260306'
--   6. ISSUE: inputtime 列加工 SQL 不设置，DML 有非空值，需手工补充
--   7. ISSUE: confirmTime 与 app_early_warning_info DML 不一致（见头部 ISSUE 2）
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_early_warning_opinion.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》预警意见 · 源头表 -> app_early_warning_opinion_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info              对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_warning_task      预警任务表 WarningTask（mainId -> xd_corp_check_info.id）
--   xd_corp_check_warning_opinion   预警意见表 RiskTaskOpinion（mainId -> xd_corp_check_warning_task.id）
-- 目标：app_early_warning_opinion_info（业务主键 reportNo + customerId + serialNo + seqNo，一预警意见一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_early_warning.sql / xd_entrust_pay.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_early_warning_opinion_info 本次范围旧行，再插入
--   2. 源头 append-only：先两级 JOIN「当前主档」->「当前预警任务」
--      （mainId=最新 xd_corp_check_info.id；warning_opinion.mainId=当前任务.id）排除历史快照，
--      再按业务主键 (serialNo, seqNo) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 13 列映射（源列名多数 == app 列名），2 处转换：
--        seqNo      源 VARCHAR(64) -> app INT  REGEXP 数字守卫 + CAST（非数字/空串 -> NULL，防 GaussDB 严格模式 CAST 报错）
--        endTime    源 VARCHAR(64) -> app VARCHAR(32)  LEFT(...,32) 截断
--      serialNo/confirmTime 随父任务行透传；activeName/approveUserName/approveOrgName/
--      warningLevelName/phaseOpinion 直映（码值待确认原样透传）
--   4. 一个预警任务下多条审批意见（不同 seqNo）各出一行；任务无意见则不出行
-- =====================================================================

-- 1. 幂等
DELETE FROM app_early_warning_opinion_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 预警意见：xd_corp_check_warning_opinion（JOIN 当前主档 -> 当前预警任务）-> app_early_warning_opinion_info
INSERT INTO app_early_warning_opinion_info (
    reportNo, customerId, customerName, serialNo, confirmTime,
    seqNo, activeName, approveUserName, approveOrgName,
    warningLevelName, phaseOpinion, endTime
)
SELECT
    c.reportNo, c.customerId, c.customerName, c.serialNo,
    CASE WHEN REGEXP_LIKE(c.confirmTime, '^[0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}')
         THEN TO_CHAR(TO_DATE(REPLACE(REGEXP_SUBSTR(c.confirmTime, '^[0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}'), '/', '-'), 'YYYY-MM-DD'), 'YYYYMMDD')
         ELSE c.confirmTime END AS confirmTime,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(c.seqNo), '^-?[0-9]+$') THEN BTRIM(c.seqNo) END AS INTEGER) AS seqNo,
    c.activeName, c.approveUserName, c.approveOrgName,
    c.warningLevelName, c.phaseOpinion,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.endTime, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.endTime, 1, 10), '-', ''), '/', '')
         ELSE c.endTime END AS endTime
FROM (
    SELECT o.reportNo, o.customerId, o.customerName,
           cur.serialNo, cur.confirmTime,
           o.seqNo, o.activeName, o.approveUserName, o.approveOrgName,
           o.warningLevelName, o.phaseOpinion, o.endTime,
           ROW_NUMBER() OVER (
               PARTITION BY o.reportNo, COALESCE(o.customerId, ''),
                            COALESCE(cur.serialNo, ''), COALESCE(o.seqNo, '')
               ORDER BY o.inputtime DESC, o.id DESC) AS rn
    FROM xd_corp_check_warning_opinion o
    JOIN (
        SELECT t.id AS taskId, t.reportNo, t.customerId, t.customerName,
               t.serialNo, t.confirmTime
        FROM xd_corp_check_warning_task t
        JOIN (
            SELECT id FROM (
                SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
                FROM xd_corp_check_info
                WHERE reportNo IS NOT NULL
                  AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
            ) mc WHERE mc.rn = 1
        ) m ON t.mainId = m.id
    ) cur ON o.mainId = cur.taskId
) c
WHERE c.rn = 1;
