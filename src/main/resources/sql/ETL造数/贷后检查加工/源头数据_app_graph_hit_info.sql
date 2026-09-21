-- =====================================================================
-- app_graph_hit_info（企业图谱命中情况）源头表反推造数
-- 加工脚本：贷后检查加工/xd_graph_hit.sql
-- 源表：
--   xd_graph_hit   企业图谱命中情况·源（eid 维度，8 个 是/否 标志，待定源）
--   ws_gs_info     启信宝工商照面（借款人，按 reportNo+customerId 取最新一行，entId 关联图谱 eid）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_graph_hit.sql）：
--   reportNo/customerId/customerName <- ws_gs_info（借款人最新工商照面）
--   suspectedFundReturn             <- xd_graph_hit.suspectedFundReturn（原样透传）
--   suspectedLoanPurposeAbnormal    <- xd_graph_hit.suspectedLoanPurposeAbnormal（原样透传）
--   suspectedBorrowedNameLoan       <- xd_graph_hit.suspectedBorrowedNameLoan（原样透传）
--   suspectedShellCompany            <- xd_graph_hit.suspectedShellCompany（原样透传）
--   suspectedGuaranteeCircle         <- xd_graph_hit.suspectedGuaranteeCircle（原样透传）
--   intraBankRelation                <- xd_graph_hit.intraBankRelation（原样透传）
--   entrustedPayManyToOne            <- xd_graph_hit.entrustedPayManyToOne（原样透传）
--   collateralSameCommunity          <- xd_graph_hit.collateralSameCommunity（原样透传）
--   id/inputtime                     <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- JOIN 口径：ws_gs_info.entId = xd_graph_hit.eid（INNER JOIN，撞不到则 0 行）
-- 去重：ws_gs_info 按 (reportNo, customerId) 取最新；xd_graph_hit 按 eid 取最新（dt DESC, inputtime DESC, id DESC）
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--   entId/eid   = 'ENT-CUST-001'（借款人企业 id，两端对齐）
--
-- 目标 DML 行数：1
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
DELETE FROM app_graph_hit_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_graph_hit       WHERE eid = 'ENT-CUST-001';
DELETE FROM ws_gs_info         WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. ws_gs_info（启信宝工商照面；借款人，entId 非空）
--    列：reportNo, customerId, customerName, entId, inputtime
--    1 行（去重键 reportNo+customerId 取最新，单行即最新）
-- =====================================================================
INSERT INTO ws_gs_info (reportNo, customerId, customerName, entId, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'ENT-CUST-001', '2026-09-11 12:00:00');

-- =====================================================================
-- 2. xd_graph_hit（企业图谱命中情况·源；eid 维度）
--    列：eid, suspectedFundReturn, suspectedLoanPurposeAbnormal, suspectedBorrowedNameLoan,
--        suspectedShellCompany, suspectedGuaranteeCircle, intraBankRelation,
--        entrustedPayManyToOne, collateralSameCommunity, dt, inputtime
--    1 行（去重键 eid 取最新，单行即最新）
--    8 标志对齐目标 DML：是/否/否/否/是/否/是/否
-- =====================================================================
INSERT INTO xd_graph_hit (
    eid, suspectedFundReturn, suspectedLoanPurposeAbnormal, suspectedBorrowedNameLoan,
    suspectedShellCompany, suspectedGuaranteeCircle, intraBankRelation,
    entrustedPayManyToOne, collateralSameCommunity, dt, inputtime
) VALUES (
    'ENT-CUST-001', '是', '否', '否',
    '否', '是', '否',
    '是', '否', '20260911', '2026-09-11 12:00:00'
);

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_graph_hit.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 11 个业务列（reportNo/customerId/customerName + 8 标志）将与 DML 目标行完全一致（1 行）
--   3. id 为 AUTO_INCREMENT（空表起算 = 1）
--   4. app_graph_hit_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），DML 中 '2026-09-11 12:30:00.0' 无法复现；
--      该列由系统自动填充，非加工 SQL 写入，属预期行为
--   5. 8 标志码值 是/否 原样透传（加工 SQL 无 CASE 转换）
--   6. INNER JOIN：ws_gs_info.entId='ENT-CUST-001' = xd_graph_hit.eid='ENT-CUST-001' 命中
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_graph_hit.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 图谱》企业图谱命中情况 · 源头表 -> app_graph_hit_info 加工
-- 节点：待定（图谱上游接口未落地，先占位；源表 xd_graph_hit 空则结果为空、不报错）
-- 源表：
--   xd_graph_hit            企业图谱命中情况·源（eid 维度，8 个 是/否 标志，待定源，上游落表）
--   ws_gs_info              启信宝工商照面（借款人，按 reportNo+customerId 取最新一行，entId 关联图谱 eid）
-- 目标：app_graph_hit_info（企业图谱命中情况，业务主键 reportNo + customerId，一个客户一行，8 标志列）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；字符串拼接用 CONCAT 不用 ||）
--
-- 关联口径（已与产品确认 eid = 企业id entId）：
--   借款人图谱：xd_graph_hit.eid = ws_gs_info.entId（取该 reportNo+customerId 最新工商照面一行）
--   图谱源按 eid 可能多行（append-only / 多 dt），按 eid 取最新一行（dt DESC, inputtime DESC, id DESC）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_graph_hit_info 段；8 标志均 是/否，码值待确认，原样透传）：
--   suspectedFundReturn             <- xd_graph_hit.suspectedFundReturn             疑似资金回流
--   suspectedLoanPurposeAbnormal    <- xd_graph_hit.suspectedLoanPurposeAbnormal     贷款用途疑似异常
--   suspectedBorrowedNameLoan       <- xd_graph_hit.suspectedBorrowedNameLoan        疑似借名贷款
--   suspectedShellCompany           <- xd_graph_hit.suspectedShellCompany            疑似空壳公司
--   suspectedGuaranteeCircle        <- xd_graph_hit.suspectedGuaranteeCircle         疑似担保圈链
--   intraBankRelation               <- xd_graph_hit.intraBankRelation                行内关联关系
--   entrustedPayManyToOne           <- xd_graph_hit.entrustedPayManyToOne            受托支付多对一
--   collateralSameCommunity         <- xd_graph_hit.collateralSameCommunity          抵押物同小区关联
--
-- 处理规则（对齐 xd_reputation.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_graph_hit_info 本次范围旧行，再插入
--   2. 借款人 entId：ws_gs_info 按 (reportNo, customerId) ROW_NUMBER(inputtime DESC, id DESC) 取最新一行（entId 非空）
--   3. 图谱取最新：xd_graph_hit 按 eid ROW_NUMBER(dt DESC, inputtime DESC, id DESC) 取 rn=1
--   4. 8 标志列 VARCHAR 原样透传（是/否 码值待确认）；JOIN 不到（无图谱数据）-> 0 行不报错
-- =====================================================================

-- 1. 幂等
DELETE FROM app_graph_hit_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 企业图谱命中情况：借款人 entId 撞图谱 eid（取最新）-> app_graph_hit_info
INSERT INTO app_graph_hit_info (
    reportNo, customerId, customerName,
    suspectedFundReturn, suspectedLoanPurposeAbnormal, suspectedBorrowedNameLoan,
    suspectedShellCompany, suspectedGuaranteeCircle, intraBankRelation,
    entrustedPayManyToOne, collateralSameCommunity
)
SELECT
    g.reportNo,
    g.customerId,
    g.customerName,
    gh.suspectedFundReturn,
    gh.suspectedLoanPurposeAbnormal,
    gh.suspectedBorrowedNameLoan,
    gh.suspectedShellCompany,
    gh.suspectedGuaranteeCircle,
    gh.intraBankRelation,
    gh.entrustedPayManyToOne,
    gh.collateralSameCommunity
FROM (
    -- 借款人最新工商照面（reportNo+customerId，entId 非空）
    SELECT reportNo, customerId, customerName, entId,
           ROW_NUMBER() OVER (
               PARTITION BY reportNo, COALESCE(customerId, '')
               ORDER BY inputtime DESC, id DESC
           ) AS rn
    FROM ws_gs_info
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
      AND entId IS NOT NULL AND entId <> ''
) g
JOIN (
    -- 图谱按 eid 取最新一行（append-only / 多 dt 去重）
    SELECT eid, suspectedFundReturn, suspectedLoanPurposeAbnormal, suspectedBorrowedNameLoan,
           suspectedShellCompany, suspectedGuaranteeCircle, intraBankRelation,
           entrustedPayManyToOne, collateralSameCommunity,
           ROW_NUMBER() OVER (
               PARTITION BY eid
               ORDER BY CASE WHEN dt IS NULL THEN 1 ELSE 0 END ASC, dt DESC, inputtime DESC, id DESC
           ) AS grn
    FROM xd_graph_hit
    WHERE eid IS NOT NULL AND eid <> ''
) gh ON gh.eid = g.entId
WHERE g.rn = 1 AND gh.grn = 1;
