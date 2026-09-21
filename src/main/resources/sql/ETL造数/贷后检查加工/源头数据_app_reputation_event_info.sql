-- =====================================================================
-- app_reputation_event_info（舆情事件明细）源头表反推造数
-- 加工脚本：贷后检查加工/xd_reputation.sql
-- 源表：dfs_final_crdt_loan_cust_rel  数据融合平台·最终信贷客户关联信息
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 源表字段（dfs_final_crdt_loan_cust_rel）：
--   reportNo        报告编号
--   customerId      客户编号
--   customerName    客户名称
--   subjectType     主体类型（借款人/股东）
--   subjectName     主体名称（股东行为股东名称；借款人行为空，加工回退 cust_nm）
--   cr_cust_num     信贷客户号
--   cust_nm         客户名称
--   rsk_ev          风险事件（小类）码值
--   ev_tp           事件类型（中文）
--   business_time   业务披露时间
--   prmpt_ltr       提示信息
--   inputtime       入库时间
--
-- 字段映射（xd_reputation.sql）：
--   subjectType    <- subjectType（直接透传）
--   subjectName    <- COALESCE(subjectName, cust_nm)（借款人行回退 cust_nm）
--   eventTime      <- business_time（原样透传）
--   eventType       <- ev_tp（空->'其他'）
--   eventTypeCode    <- rsk_ev
--   eventTypeOrder   <- CASE rsk_ev（0604006=100/0504006=99/0504007=98/0601027=97/0101003=96/0504005=70）
--   eventDesc      <- prmpt_ltr
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：4（借款人 2 行 + 股东 2 行）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）
-- =====================================================================
DELETE FROM app_reputation_event_info     WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM dfs_final_crdt_loan_cust_rel  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. dfs_final_crdt_loan_cust_rel（风险事件表）
--    借款人行：subjectType='借款人', subjectName=NULL(加工回退 cust_nm), cust_nm=客户名称
--    股东行：  subjectType='股东', subjectName=股东名称, cust_nm=NULL
-- =====================================================================

-- 行1：借款人 / 证券市场违规 / 2026-03-18
INSERT INTO dfs_final_crdt_loan_cust_rel (
    reportNo, customerId, customerName, subjectType, subjectName, cr_cust_num, cust_nm,
    rsk_ev, ev_tp, business_time, prmpt_ltr, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '借款人', NULL, 'CUST-001', '苏州XX精密机械制造有限公司',
    '0601027', '证券市场违规问题', '2026-03-18', '因信息披露违规被江苏证监局出具警示函。',
    '2026-09-11 11:30:00'
);

-- 行2：借款人 / 企业评级被下调 / 2026-05-09
INSERT INTO dfs_final_crdt_loan_cust_rel (
    reportNo, customerId, customerName, subjectType, subjectName, cr_cust_num, cust_nm,
    rsk_ev, ev_tp, business_time, prmpt_ltr, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '借款人', NULL, 'CUST-001', '苏州XX精密机械制造有限公司',
    '0504005', '企业评级被下调', '2026-05-09', '主体信用评级由AA-下调至A+，评级展望为负面。',
    '2026-09-11 11:31:00'
);

-- 行3：股东(泰州公司) / 财务造假 / 2026-04-22
INSERT INTO dfs_final_crdt_loan_cust_rel (
    reportNo, customerId, customerName, subjectType, subjectName, cr_cust_num, cust_nm,
    rsk_ev, ev_tp, business_time, prmpt_ltr, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '股东', '泰州公司', NULL, NULL,
    '0604006', '财务造假', '2026-04-22', '泰州公司因虚增营业收入被证监会立案调查。',
    '2026-09-11 11:32:00'
);

-- 行4：股东(泰州公司) / 企业高管无法履职 / 2026-06-15
INSERT INTO dfs_final_crdt_loan_cust_rel (
    reportNo, customerId, customerName, subjectType, subjectName, cr_cust_num, cust_nm,
    rsk_ev, ev_tp, business_time, prmpt_ltr, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '股东', '泰州公司', NULL, NULL,
    '0101003', '企业高管无法履职', '2026-06-15', '泰州公司法定代表人因涉嫌违法犯罪被限制人身自由。',
    '2026-09-11 11:33:00'
);

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_reputation.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 加工产出 4 行，排序 subjectType, subjectName, eventTime：
--      - 行1: 借款人/苏州XX精密机械制造有限公司/2026-03-18/证券市场违规问题/0601027/97
--      - 行2: 借款人/苏州XX精密机械制造有限公司/2026-05-09/企业评级被下调/0504005/70
--      - 行3: 股东/泰州公司/2026-04-22/财务造假/0604006/100
--      - 行4: 股东/泰州公司/2026-06-15/企业高管无法履职/0101003/96
--   3. subjectName 加工：借款人行 subjectName=NULL -> COALESCE(NULL, cust_nm) = '苏州XX精密机械制造有限公司'
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_reputation.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- =====================================================================

-- 1. 幂等
DELETE FROM app_reputation_event_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 舆情事件明细：源表主体维度风险事件（借款人 + 股东；append-only 去重取最新）-> app_reputation_event_info
INSERT INTO app_reputation_event_info (
    reportNo, customerId, customerName, subjectType, subjectName, eventTime, eventType, eventTypeCode, eventTypeOrder, eventDesc
)
SELECT
    t.reportNo,
    t.customerId,
    t.customerName,
    t.subjectType    AS subjectType,
    COALESCE(NULLIF(TRIM(t.subjectName), ''), t.cust_nm) AS subjectName,
    t.business_time   AS eventTime,
    COALESCE(NULLIF(TRIM(t.ev_tp), ''), '其他') AS eventType,
    t.rsk_ev          AS eventTypeCode,
    CASE t.rsk_ev
        WHEN '0604006' THEN 100
        WHEN '0504006' THEN 99
        WHEN '0504007' THEN 98
        WHEN '0601027' THEN 97
        WHEN '0101003' THEN 96
        WHEN '0504005' THEN 70
    END               AS eventTypeOrder,
    t.prmpt_ltr       AS eventDesc
FROM (
    SELECT
        reportNo, customerId, customerName, subjectType, subjectName, cust_nm,
        rsk_ev, ev_tp, business_time, prmpt_ltr,
        ROW_NUMBER() OVER (
            PARTITION BY reportNo, COALESCE(customerId, ''),
                         COALESCE(subjectType, ''), COALESCE(subjectName, ''),
                         COALESCE(rsk_ev, ''),
                         COALESCE(business_time, ''), COALESCE(CAST(prmpt_ltr AS CHAR(2000)), '')
            ORDER BY inputtime DESC
        ) AS rn
    FROM dfs_final_crdt_loan_cust_rel
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) t
WHERE t.rn = 1
  AND t.business_time IS NOT NULL AND t.business_time <> ''
ORDER BY subjectType, subjectName, eventTime;
