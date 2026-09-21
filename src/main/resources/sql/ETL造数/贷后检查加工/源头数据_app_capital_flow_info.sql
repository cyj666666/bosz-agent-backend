-- =====================================================================
-- app_capital_flow_info（资金用途及回流异常）源头表反推造数
-- 加工脚本：贷后检查加工/xd_capital_flow.sql
-- 源表：
--   xd_fund_use_abnormal  资金用途及回流异常主表（父表，无 mainId，按 serialNo 去重取最新）
--   xd_credit_info        授信用信主档（取"当前借据"用，按 reportNo 取最新 id）
--   xd_credit_loan        借据信息（mainId -> xd_credit_info.id；撞 loanStatus 用，按 loanSerialNo 去重取最新）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_capital_flow.sql）：
--   loanSerialNo             <- xd_fund_use_abnormal.loanSerialNo
--   loanStatus               <- xd_credit_loan.loanStatus（LEFT JOIN 当前借据，撞不到 NULL）
--   serialNo                 <- xd_fund_use_abnormal.serialNo
--   capitalCheckTaskType     <- 码值->中文 CASE：'01'->资金回流异常, '02'->资金用途异常; NULL/未收录原样保留
--   approveStatus            <- xd_fund_use_abnormal.approveStatus（原样透传）
--   isPurposeAbnormal        <- xd_fund_use_abnormal.isPurposeAbnormal（原样透传）
--   rectificationSituation   <- xd_fund_use_abnormal.rectificationPurposeSituation（直映）
--   rectificationDeadline    <- LEFT(xd_fund_use_abnormal.rectificationPurposeDeadline, 32)（截断 32）
--   rectificationExplanation <- xd_fund_use_abnormal.rectificationPurposeExplanation（不截断）
--   identifyReason           <- xd_fund_use_abnormal.purposeIdentifiyReason（不截断）
--   id/inputtime             <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202603-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：7（loanSerialNo 3 个：LOAN-202603-001/002/003）
--   loanStatus 映射：LOAN-202603-001=未结清 / LOAN-202603-002=正常结清 / LOAN-202603-003=逾期结清
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
DELETE FROM app_capital_flow_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_fund_use_abnormal  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_credit_loan        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_credit_info        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';

-- =====================================================================
-- 1. xd_credit_info（授信用信主档；显式 id 供 credit_loan.mainId 指向）
--    列：id, reportNo, customerId, customerName, inputtime
-- =====================================================================
INSERT INTO xd_credit_info (id, reportNo, customerId, customerName, inputtime)
VALUES (1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 10:00:00');

-- =====================================================================
-- 2. xd_credit_loan（借据信息；mainId 指向 credit_info.id；撞 loanStatus 用）
--    每个 loanSerialNo 1 行，loanStatus 对齐目标 DML
--    列：mainId, reportNo, customerId, customerName, loanSerialNo, loanStatus, inputtime
-- =====================================================================
INSERT INTO xd_credit_loan (mainId, reportNo, customerId, customerName, loanSerialNo, loanStatus, inputtime)
VALUES (1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-001', '未结清', '2026-03-05 10:00:00');
INSERT INTO xd_credit_loan (mainId, reportNo, customerId, customerName, loanSerialNo, loanStatus, inputtime)
VALUES (1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-002', '正常结清', '2026-03-05 10:00:00');
INSERT INTO xd_credit_loan (mainId, reportNo, customerId, customerName, loanSerialNo, loanStatus, inputtime)
VALUES (1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-003', '逾期结清', '2026-03-05 10:00:00');

-- =====================================================================
-- 3. xd_fund_use_abnormal（资金用途及回流异常主表；父表无 mainId）
--    每个 serialNo 1 行（去重键 reportNo+customerId+serialNo 取最新，单行即最新）
--    列：reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
--        purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
--        rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
--
--    capitalCheckTaskType 码值翻译：'01'->资金回流异常（加工 CASE 翻译为中文）
-- =====================================================================

-- 行1：SER-202603-001 / LOAN-202603-001 / 01(资金回流异常) / 审批通过 / 否 / 无需整改 / deadline=NULL / explain=NULL / identifyReason=正常货款说明
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-001', 'LOAN-202603-001', '审批通过',
    '经核查，该笔资金流向为正常货款支付，收款方为长期供应商，合同、发票、物流单据齐全，不属于资金回流。', '否', '无需整改',
    NULL, NULL, '01', '2026-03-05 10:30:00'
);

-- 行2：SER-202603-002 / LOAN-202603-001 / 01(资金回流异常) / 审批通过 / 是 / 整改中 / deadline=20261231 / explain=归还说明 / identifyReason=NULL
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-002', 'LOAN-202603-001', '审批通过',
    NULL, '是', '整改中',
    '20261231', '已要求借款人于2026年12月31日前归还回流资金，并提供银行流水及还款凭证；目前借款人已归还50%，剩余部分正在筹措。', '01', '2026-03-05 10:30:00'
);

-- 行3：SER-202603-003 / LOAN-202603-001 / 01(资金回流异常) / 审批中 / NULL / NULL / NULL / NULL / NULL
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-003', 'LOAN-202603-001', '审批中',
    NULL, NULL, NULL,
    NULL, NULL, '01', '2026-03-06 09:15:00'
);

-- 行4：SER-202603-004 / LOAN-202603-002 / 01(资金回流异常) / 审批通过 / 是 / 已整改 / deadline=20260930 / explain=全额归还说明 / identifyReason=NULL
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-004', 'LOAN-202603-002', '审批通过',
    NULL, '是', '已整改',
    '20260930', '借款人已全额归还回流资金，并提供还款凭证及银行流水，整改完成。', '01', '2026-03-06 14:20:00'
);

-- 行5：SER-202603-005 / LOAN-202603-002 / 01(资金回流异常) / 审批通过 / 否 / 无需整改 / NULL / NULL / identifyReason=关联方往来款说明
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-005', 'LOAN-202603-002', '审批通过',
    '资金流向为关联方正常往来款，已提供董事会决议及往来合同，经经营机构认定不属于资金回流。', '否', '无需整改',
    NULL, NULL, '01', '2026-03-07 11:00:00'
);

-- 行6：SER-202603-006 / LOAN-202603-003 / 01(资金回流异常) / 审批中 / NULL / NULL / NULL / NULL / NULL
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-006', 'LOAN-202603-003', '审批中',
    NULL, NULL, NULL,
    NULL, NULL, '01', '2026-03-08 16:45:00'
);

-- 行7：SER-202603-007 / LOAN-202603-003 / 01(资金回流异常) / 审批通过 / 是 / 整改中 / deadline=20261015 / explain=分期归还说明 / identifyReason=NULL
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-007', 'LOAN-202603-003', '审批通过',
    NULL, '是', '整改中',
    '20261015', '已制定整改计划，要求借款人分期归还回流资金，目前第一期已到账。', '01', '2026-03-09 09:00:00'
);

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_capital_flow.sql（带 :customerId='CUST-001' :reportNo='RPT-202603-001'）
--   2. 13 个业务列将与 DML 目标行完全一致（7 行）
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..7，顺序与 serialNo 升序一致）
--   4. app_capital_flow_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），DML 中历史时间戳无法逐行复现；
--      该列由系统自动填充，非加工 SQL 写入，属预期行为
--   5. capitalCheckTaskType 码值翻译：'01'->资金回流异常（加工 CASE 翻译为中文）
--   6. rectificationDeadline 均 ≤8 字符，LEFT(...,32) 不触发截断
--   7. loanStatus 通过 LEFT JOIN xd_credit_loan（按 loanSerialNo 撞）填充，3 个借据均命中
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_capital_flow.sql
-- Params: customerId='CUST-001', reportNo='RPT-202603-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 资金用途及回流异常 · 源头表 -> app_capital_flow_info 加工
-- 节点：资金用途及回流异常查询接口（aflCapitalCheckQry，CrcsAfterLoanAiService.aflCapitalCheckQry）
-- 源表：
--   xd_fund_use_abnormal  资金用途及回流异常主表（CapitalCheck，父表，自身无 mainId，aflCapitalCheckQry 落表）
--   xd_credit_info        授信用信主档（父表，aflCreditLoanQry 落表，取"当前借据"用）
--   xd_credit_loan        借据信息（mainId -> xd_credit_info.id，撞借据状态 loanStatus 用）
-- 目标：app_capital_flow_info（业务主键 reportNo + customerId + serialNo，一回流/用途异常任务一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_capital_flow_info 段）：
--   loanSerialNo           <- loanSerialNo                 借据号
--   loanStatus             <- loanSerialNo 撞「当前借据」(最新 xd_credit_info 下 xd_credit_loan) 取 loanStatus，撞不到 NULL
--   serialNo               <- serialNo                     申请流水号
--   capitalCheckTaskType   <- capitalCheckTaskType         任务类型（码值->中文：01->资金回流异常, 02->资金用途异常；NULL/未收录原样保留）
--   approveStatus          <- approveStatus                审批状态（码值待确认，原样透传）
--   isPurposeAbnormal      <- isPurposeAbnormal            是否用途异常
--   rectificationSituation <- rectificationPurposeSituation  整改情况（源 VARCHAR(64) -> app VARCHAR(128) 直映）
--   rectificationDeadline  <- rectificationPurposeDeadline   整改期限（源 VARCHAR(64) -> app VARCHAR(32) LEFT 截断）
--   rectificationExplanation <- rectificationPurposeExplanation 整改情况说明（源 VARCHAR(1000) -> app TEXT 不截断）
--   identifyReason         <- purposeIdentifiyReason        认定理由（源 VARCHAR(1000) -> app TEXT 不截断）
--
-- 处理规则（对齐 xd_warning_signal.sql / xd_loan_receipt.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_capital_flow_info 本次范围旧行，再插入
--   2. 源头 append-only：xd_fund_use_abnormal 为父表（无 mainId，不 JOIN 主档），
--      按业务主键 (serialNo) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. loanStatus：用 loanSerialNo 撞「当前借据」（最新 xd_credit_info 下的 xd_credit_loan，按 loanSerialNo 去重取最新）
--      LEFT JOIN，撞不到为 NULL（若该报告未先调 aflCreditLoanQry 落借据表，则 loanStatus 全 NULL）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_capital_flow_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL);

-- 2. 资金用途及回流异常：xd_fund_use_abnormal（父表）+ 撞当前借据 loanStatus -> app_capital_flow_info
INSERT INTO app_capital_flow_info (
    reportNo, customerId, customerName, loanSerialNo, loanStatus, serialNo,
    capitalCheckTaskType, approveStatus, isPurposeAbnormal,
    rectificationSituation, rectificationDeadline, rectificationExplanation, identifyReason
)
SELECT
    f.reportNo, f.customerId, f.customerName, f.loanSerialNo,
    cur.loanStatus AS loanStatus,
    f.serialNo,
    -- 任务类型：码值->中文（01->资金回流异常, 02->资金用途异常），NULL/未收录原样保留
    CASE f.capitalCheckTaskType
        WHEN '01' THEN '资金回流异常'
        WHEN '02' THEN '资金用途异常'
        ELSE f.capitalCheckTaskType
    END AS capitalCheckTaskType,
    f.approveStatus, f.isPurposeAbnormal,
    f.rectificationPurposeSituation AS rectificationSituation,
    LEFT(f.rectificationPurposeDeadline, 32) AS rectificationDeadline,
    f.rectificationPurposeExplanation AS rectificationExplanation,
    f.purposeIdentifiyReason AS identifyReason
FROM (
    SELECT reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
           purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
           rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType,
           ROW_NUMBER() OVER (
               PARTITION BY reportNo, COALESCE(customerId, ''), COALESCE(serialNo, '')
               ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_fund_use_abnormal
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
) f
LEFT JOIN (
    -- 当前借据：最新 xd_credit_info 下的 xd_credit_loan，按 (reportNo, loanSerialNo) 去重取最新（取 loanStatus）
    SELECT reportNo, loanSerialNo, loanStatus,
           ROW_NUMBER() OVER (
               PARTITION BY reportNo, COALESCE(loanSerialNo, '')
               ORDER BY inputtime DESC, id DESC) AS lrn
    FROM xd_credit_loan
    WHERE mainId IN (
        SELECT id FROM (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_credit_info
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
        ) mc WHERE mc.rn = 1
    )
) cur ON cur.reportNo = f.reportNo AND cur.loanSerialNo = f.loanSerialNo AND cur.lrn = 1
WHERE f.rn = 1;
