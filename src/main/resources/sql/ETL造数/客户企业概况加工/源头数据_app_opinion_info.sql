-- =====================================================================
-- app_opinion_info（贷后意见）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_opinion.sql
-- 源表：
--   xd_corp_check_info             对公检查主档（父表）
--   xd_corp_check_current_opinion   本次贷后检查意见（mainId -> xd_corp_check_info.id）
--   xd_corp_check_last_opinion      上次贷后意见（mainId -> xd_corp_check_info.id）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_opinion.sql，8 业务列）：
--   reportNo/customerId/customerName  直映
--   phaseOpinion   直映（源 VARCHAR(1000) -> app TEXT）
--   endTime        日期正则 -> YYYYMMDD；否则原样透传
--   approveUserName/approveOrgName  直映
--   "group"        <- 源表身份：current -> '本次贷后检查意见'；last -> '上次贷后检查意见'
--   去重：两源 UNION ALL + ROW_NUMBER(reportNo, customerId, phaseOpinion, group)
--         ORDER BY srcPriority ASC, inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：2（group: 上次贷后检查意见/本次贷后检查意见）
--
-- ISSUE: DML 有 10 列，加工 SQL 只插入 8 列。inputtime 列 DML 非空
--   ('2026-09-10 21:12:01.689546')，DEFAULT CURRENT_TIMESTAMP，不一致
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
DELETE FROM app_opinion_info                WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_current_opinion   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_last_opinion      WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_info              WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档；显式 id 供 opinion.mainId 指向）
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 08:00:00');

-- =====================================================================
-- 2. xd_corp_check_last_opinion（上次贷后意见；mainId 指向主档 id）
--    列：id, mainId, reportNo, customerId, customerName, taskGenerationDate,
--        activeName, approveUserName, approveOrgName, phaseOpinion, endTime, inputtime
--
--    加工 SQL 中 last 源 srcPriority=2，group='上次贷后检查意见'
--    endTime '2026-03-05' -> 匹配日期正则 -> '20260305'
--    phaseOpinion 直映
-- =====================================================================
INSERT INTO xd_corp_check_last_opinion (
    id, mainId, reportNo, customerId, customerName, taskGenerationDate,
    activeName, approveUserName, approveOrgName, phaseOpinion, endTime, inputtime
) VALUES (
    1, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '20260305',
    '贷后检查', 'XXX', 'XXX支行风险合规部',
    '报表显示企业25年销售收入XXX万元，净利润XXX万元，近三年销售呈下降趋势，受酒类价格和外部经济环境影响，纳税销售收人XXX万元，授信敞口XXX万元，比年初下降XXX万元，销贷比处于一个正常范围内，同意为"维持额度"，25年在我行不同名划转XXX笔，金额XXX万，与我行授信占比不匹配，后期请加强结算管理。另，客户近期有作为原告的诉讼案件XXX起,请跟进相关进展.',
    '2026-03-05', '2026-09-10 21:12:01'
);

-- =====================================================================
-- 3. xd_corp_check_current_opinion（本次贷后检查意见；mainId 指向主档 id）
--    列：id, mainId, reportNo, customerId, customerName, taskGenerationDate,
--        activeName, approveUserName, approveOrgName, phaseOpinion, endTime, inputtime
--
--    加工 SQL 中 current 源 srcPriority=1，group='本次贷后检查意见'
--    endTime NULL -> 原样 NULL
--    phaseOpinion 直映
-- =====================================================================
INSERT INTO xd_corp_check_current_opinion (
    id, mainId, reportNo, customerId, customerName, taskGenerationDate,
    activeName, approveUserName, approveOrgName, phaseOpinion, endTime, inputtime
) VALUES (
    1, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '20260305',
    '贷后检查', 'XXX', 'XXX支行风险合规部',
    '敞口XXX万元，比年初下降XXX万元。报表显示销售收入XXX万元，净利润XXX万元:纳税销售收入XXX万元，相对而言，销',
    NULL, '2026-09-10 21:12:01'
);

-- =====================================================================
-- 验证说明：
--   1. xd_corp_check_info id=1 为唯一当前主档
--   2. last_opinion 1 行 mainId=1 -> group='上次贷后检查意见'
--   3. current_opinion 1 行 mainId=1 -> group='本次贷后检查意见'
--   4. 两行 group 不同，去重各出 1 行，共 2 行
--   5. endTime '2026-03-05' -> 匹配日期正则 -> '20260305'（last 行）
--   6. endTime NULL -> NULL（current 行）
--   7. ISSUE: inputtime 列加工 SQL 不设置，DML 有非空值，需手工补充
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_opinion.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》贷后意见 · 源头表 -> app_opinion_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表（两源 UNION，结构对称）：
--   xd_corp_check_current_opinion   本次贷后检查意见 CurrentCheckOpinion（mainId -> xd_corp_check_info.id）
--   xd_corp_check_last_opinion      上次贷后意见 LastCheckOpinion（mainId -> xd_corp_check_info.id）
-- 目标：app_opinion_info（业务主键 reportNo + customerId + phaseOpinion + "group"）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_opinion_info 段 ROW545-554）：
--   phaseOpinion      <- phaseOpinion            审批意见（源 VARCHAR(1000) -> app TEXT）
--   endTime           <- endTime                 审批日期（源 VARCHAR(64) -> app VARCHAR(32)，LEFT 截断）
--   approveUserName   <- approveUserName         审批人
--   approveOrgName    <- approveOrgName          所属机构
--   "group"           <- 源表身份（源表无 group 列，字典取值字段"group"为文档笔误）：
--                       current 源 -> '本次贷后检查意见'；last 源 -> '上次贷后检查意见'
--   （源表 taskGenerationDate/activeName 目标表无列，不加工）
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_opinion_info 本次范围旧行，再插入
--   2. 源头 append-only：两源各自 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      UNION ALL 后按 (phaseOpinion, "group") ROW_NUMBER 去重取最新（源优先级 current > last，inputtime DESC, id DESC）
--   3. 一次日检可有多条意见（不同内容），各出一行；两源各出一行（group 区分本次/上次）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_opinion_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 贷后意见：current（本次）+ last（上次）UNION -> app_opinion_info
INSERT INTO app_opinion_info (
    reportNo, customerId, customerName, phaseOpinion, endTime, approveUserName, approveOrgName, "group"
)
SELECT
    c.reportNo, c.customerId, c.customerName,
    c.phaseOpinion,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.endTime, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.endTime, 1, 10), '-', ''), '/', '')
         ELSE c.endTime END AS endTime,
    c.approveUserName, c.approveOrgName,
    c.grp AS "group"
FROM (
    SELECT t.*,
           ROW_NUMBER() OVER (
               PARTITION BY t.reportNo, COALESCE(t.customerId, ''), COALESCE(t.phaseOpinion, ''), t.grp
               ORDER BY t.srcPriority ASC, t.inputtime DESC, t.id DESC) AS rn
    FROM (
        -- 本次贷后检查意见（current 源，srcPriority=1 优先保留）
        SELECT c.id, c.reportNo, c.customerId, c.customerName, c.phaseOpinion, c.endTime,
               c.approveUserName, c.approveOrgName, c.inputtime, 1 AS srcPriority,
               '本次贷后检查意见' AS grp
        FROM xd_corp_check_current_opinion c
        JOIN (
            SELECT id FROM (
                SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
                FROM xd_corp_check_info
                WHERE reportNo IS NOT NULL
                  AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
            ) mc WHERE mc.rn = 1
        ) m ON c.mainId = m.id
        UNION ALL
        -- 上次贷后意见（last 源，srcPriority=2）
        SELECT c.id, c.reportNo, c.customerId, c.customerName, c.phaseOpinion, c.endTime,
               c.approveUserName, c.approveOrgName, c.inputtime, 2 AS srcPriority,
               '上次贷后检查意见' AS grp
        FROM xd_corp_check_last_opinion c
        JOIN (
            SELECT id FROM (
                SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
                FROM xd_corp_check_info
                WHERE reportNo IS NOT NULL
                  AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
            ) mc WHERE mc.rn = 1
        ) m ON c.mainId = m.id
    ) t
) c
WHERE c.rn = 1;
