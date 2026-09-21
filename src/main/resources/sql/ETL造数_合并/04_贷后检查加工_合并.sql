-- =====================================================================
-- 【合并脚本】贷后检查加工 组（原 10 个脚本 → 本文件 1 个）
-- 生成：2026-09-22　由 33 个原脚本合并（清理段统一前置 + 造数段 + 加工段）
-- 合并规则：
--   1. 各原脚本自带的「源表 DELETE」已全部抽出并前置到 §0（同一张表只清一次）
--      ⇒ 组内多个脚本不再互相删数据（原「后跑的删掉先跑的」问题消失）
--   2. 同一张表被组内多个脚本造数时，只保留一处（其余位置见 [已合并] 标记）
--   3. 加工段原样保留（各自 app 表的幂等 DELETE + INSERT 不受影响）
--   4. reportNo 已统一为 RPT-202609-001
-- 【执行顺序（跨组 owner 约定）】
--   01 外数  ->  02 客户企业概况  ->  04 贷后检查
--   本组依赖：① 01 建的 ws_gs_info 借款人照面行（本组 UPDATE 补 entId）
--             ② 02 建的 xd_credit_info(全字段) / xd_credit_loan(12 行)
--   本组 §0 已交出 xd_credit_info / xd_credit_loan / ws_gs_info 的清理权（谁造谁清）
-- 原脚本清单：
--     源头数据_app_capital_flow_info.sql
--     源头数据_app_graph_hit_info.sql
--     源头数据_app_gs_finance_data_info.sql
--     源头数据_app_gs_tax_sales_info.sql
--     源头数据_app_guofa_report_info.sql
--     源头数据_app_payroll_stat_info.sql
--     源头数据_app_reputation_event_info.sql
--     源头数据_app_settle_account_info.sql
--     源头数据_app_settle_asset_info.sql
--     源头数据_app_settle_counterparty_info.sql
-- =====================================================================

-- =====================================================================
-- §0 统一清理（组内所有源表 + app 表，每张表只清一次）
-- =====================================================================
DELETE FROM app_capital_flow_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_fund_use_abnormal  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_graph_hit       WHERE eid = 'ENT-CUST-001';
DELETE FROM dfs_crdt_loan_cust_rel   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_gs_tax_sales_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_guofa_report_info    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM gfzx_finance_index_item  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM gfzx_balance_sheet_item  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM gfzx_profit_sheet_item   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM gfzx_national_dev        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_reputation_event_info     WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM dfs_final_crdt_loan_cust_rel  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_settle_account_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_settle_asset_info   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_settle_counterparty_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- §1 造数（按原脚本分段；源表 DELETE 已上移；同表重复造数已省略）
-- =====================================================================

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_capital_flow_info.sql
-- ---------------------------------------------------------------------
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
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：7（loanSerialNo 3 个：LOAN-202603-001/002/003）
--   loanStatus 映射（A 方案：以 02 组「借据主档」为准）
--     = LOAN-202603-001 正常结清 / LOAN-202603-002 提前结清 / LOAN-202603-003 逾期结清
--   ⚠️ 与原 DML 目标差 2 个值（原为 001=未结清 / 002=正常结清）：
--      同一借据号在两处诉求矛盾，已按裁决统一到借据主档，详见下方 §1-2 说明
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_capital_flow_info
-- [已上移至 §0] DELETE FROM xd_fund_use_abnormal
-- 【清理权已交出】DELETE FROM xd_credit_loan  -> owner = 02 组（本组不再造、不再清）
-- 【清理权已交出】DELETE FROM xd_credit_info  -> owner = 02 组（本组不再造、不再清）

-- =====================================================================
-- 1. xd_credit_info —— 【造数已删除，收归 02 组 owner】
--    本组不再造 credit 主档 / 借据（02 组已造全字段版，见 02_客户企业概况加工_合并.sql）：
--      · xd_credit_info <- app_credit_use_info（14 列全字段，id=1）
--      · xd_credit_loan <- app_loan_receipt_info（12 行 28 列，mainId=1）
--    本组只是「借用」：capital_flow 加工 LEFT JOIN xd_credit_loan 取 loanStatus
--    ⚠️ 执行顺序要求：02 必须先于 04，否则 loanStatus 全 NULL
-- =====================================================================

-- =====================================================================
-- 2. xd_credit_loan —— 【造数已删除，收归 02 组 owner】
--    原此处造 3 行（001=未结清 / 002=正常结清 / 003=逾期结清），与 02 组的
--    12 行版（001=正常结清 / 002=提前结清 / 003=逾期结清）冲突：
--      · 主键：两表只有 id 唯一约束，重复插报 duplicate key；
--      · 值：同一 loanSerialNo 的 loanStatus 两处要求不同。
--    ✅ 已按裁决「A：以借据主档（02 组 loan_receipt 12 行）为准」统一 ⇒ 本组删除造数。
--    ⇒ 预期差异：app_capital_flow_info 的 001/002 将由
--       「未结清 / 正常结清」 变为 「正常结清 / 提前结清」（其余不变，共 2 个值）
-- =====================================================================

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
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-001', 'LOAN-202603-001', '审批通过',
    '经核查，该笔资金流向为正常货款支付，收款方为长期供应商，合同、发票、物流单据齐全，不属于资金回流。', '否', '无需整改',
    NULL, NULL, '01', '2026-03-05 10:30:00'
);

-- 行2：SER-202603-002 / LOAN-202603-001 / 01(资金回流异常) / 审批通过 / 是 / 整改中 / deadline=20261231 / explain=归还说明 / identifyReason=NULL
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-002', 'LOAN-202603-001', '审批通过',
    NULL, '是', '整改中',
    '20261231', '已要求借款人于2026年12月31日前归还回流资金，并提供银行流水及还款凭证；目前借款人已归还50%，剩余部分正在筹措。', '01', '2026-03-05 10:30:00'
);

-- 行3：SER-202603-003 / LOAN-202603-001 / 01(资金回流异常) / 审批中 / NULL / NULL / NULL / NULL / NULL
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-003', 'LOAN-202603-001', '审批中',
    NULL, NULL, NULL,
    NULL, NULL, '01', '2026-03-06 09:15:00'
);

-- 行4：SER-202603-004 / LOAN-202603-002 / 01(资金回流异常) / 审批通过 / 是 / 已整改 / deadline=20260930 / explain=全额归还说明 / identifyReason=NULL
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-004', 'LOAN-202603-002', '审批通过',
    NULL, '是', '已整改',
    '20260930', '借款人已全额归还回流资金，并提供还款凭证及银行流水，整改完成。', '01', '2026-03-06 14:20:00'
);

-- 行5：SER-202603-005 / LOAN-202603-002 / 01(资金回流异常) / 审批通过 / 否 / 无需整改 / NULL / NULL / identifyReason=关联方往来款说明
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-005', 'LOAN-202603-002', '审批通过',
    '资金流向为关联方正常往来款，已提供董事会决议及往来合同，经经营机构认定不属于资金回流。', '否', '无需整改',
    NULL, NULL, '01', '2026-03-07 11:00:00'
);

-- 行6：SER-202603-006 / LOAN-202603-003 / 01(资金回流异常) / 审批中 / NULL / NULL / NULL / NULL / NULL
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-006', 'LOAN-202603-003', '审批中',
    NULL, NULL, NULL,
    NULL, NULL, '01', '2026-03-08 16:45:00'
);

-- 行7：SER-202603-007 / LOAN-202603-003 / 01(资金回流异常) / 审批通过 / 是 / 整改中 / deadline=20261015 / explain=分期归还说明 / identifyReason=NULL
INSERT INTO xd_fund_use_abnormal (
    reportNo, customerId, customerName, serialNo, loanSerialNo, approveStatus,
    purposeIdentifiyReason, isPurposeAbnormal, rectificationPurposeSituation,
    rectificationPurposeDeadline, rectificationPurposeExplanation, capitalCheckTaskType, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'SER-202603-007', 'LOAN-202603-003', '审批通过',
    NULL, '是', '整改中',
    '20261015', '已制定整改计划，要求借款人分期归还回流资金，目前第一期已到账。', '01', '2026-03-09 09:00:00'
);

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_capital_flow.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 13 个业务列将与 DML 目标行完全一致（7 行）
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..7，顺序与 serialNo 升序一致）
--   4. app_capital_flow_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），DML 中历史时间戳无法逐行复现；
--      该列由系统自动填充，非加工 SQL 写入，属预期行为
--   5. capitalCheckTaskType 码值翻译：'01'->资金回流异常（加工 CASE 翻译为中文）
--   6. rectificationDeadline 均 ≤8 字符，LEFT(...,32) 不触发截断
--   7. loanStatus 通过 LEFT JOIN xd_credit_loan（按 loanSerialNo 撞）填充，3 个借据均命中
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_graph_hit_info.sql
-- ---------------------------------------------------------------------
﻿-- =====================================================================
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
-- [已上移至 §0] DELETE FROM xd_graph_hit
-- 【清理权已交出】DELETE FROM ws_gs_info  -> owner = 01/02 组（本组改为 UPDATE 补 entId，不再造整行）

-- =====================================================================
-- 1. ws_gs_info（启信宝工商照面；借款人，entId 非空）
--    列：reportNo, customerId, customerName, entId, inputtime
--    1 行（去重键 reportNo+customerId 取最新，单行即最新）
-- =====================================================================
-- 【已改为 UPDATE，收归 01 组 owner】
--   01_外数加工_合并.sql 已建「借款人工商照面行」（customerId='CUST-001'、name IS NULL），
--   本组只补 entId 字段 —— 避免原 INSERT + 双向 DELETE 造成的互相清场：
--     01 先跑：本组删除照面列 -> app_ic_info 的 legalPerson/registerCapital 等 5 列全空
--     04 先跑：01 删掉 entId 行 -> app_graph_hit_info 的 INNER JOIN 撞不到 -> 0 行
UPDATE ws_gs_info SET entId = 'ENT-CUST-001'
 WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' AND name IS NULL;

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
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_gs_finance_data_info.sql
-- ---------------------------------------------------------------------
﻿-- =====================================================================
-- app_gs_finance_data_info（国税财务数据）源头表反推造数
-- 加工脚本：贷后检查加工/xd_gs_finance_data.sql
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（财税/财报/账户/代发等经营字段，append-only）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；取段用 SPLIT_PART）
--
-- 字段映射（xd_gs_finance_data.sql）：
--   reportScope          <- fin_rpt_clber（单值直取）
--   beforeYear           <- SPLIT_PART(SPLIT_PART(oprt_incm,'|',1),':',1)   前年日期
--   lastYear             <- SPLIT_PART(SPLIT_PART(oprt_incm,'|',2),':',1)   去年日期
--   thisYear             <- SPLIT_PART(SPLIT_PART(oprt_incm,'|',3),':',1)   最新一期日期
--   gfRevenue             <- CAST(SPLIT_PART(SPLIT_PART(oprt_incm,'|',3),':',2) AS DECIMAL)   最新营收
--   lastYearRevenue        <- CAST(SPLIT_PART(SPLIT_PART(oprt_incm,'|',2),':',2) AS DECIMAL)   去年营收
--   beforeYearRevenue      <- CAST(SPLIT_PART(SPLIT_PART(oprt_incm,'|',1),':',2) AS DECIMAL)   前年营收
--   gfReceivable/lastYearReceivable/beforeYearReceivable  <- rcvb_fnd_on_acct 段3/2/1 金额
--   gfPayable/lastYearPayable/beforeYearPayable           <- due_fnd_on_acct  段3/2/1 金额
--   gfInventory/lastYearInventory/beforeYearInventory       <- ivnt             段3/2/1 金额
--   id/inputtime         <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- 源头字段格式（4 个财报科目列各为「三期拼接值」，| 分隔，顺序 前年|去年|最新，每段 日期:金额）：
--   oprt_incm        = '20241231:19875.20|20251231:23640.80|20260330:12580.50'
--   rcvb_fnd_on_acct = '20241231:3560.80|20251231:3980.25|20260330:4320.60'
--   due_fnd_on_acct  = '20241231:2890.30|20251231:3120.70|20260330:2760.45'
--   ivnt             = '20241231:3015.60|20251231:3280.90|20260330:3540.20'
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：1（一客户一行，16 列业务数据）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
DELETE FROM app_gs_finance_data_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
-- [已上移至 §0] DELETE FROM dfs_crdt_loan_cust_rel

-- =====================================================================
-- 1. dfs_crdt_loan_cust_rel（数据融合平台·信贷客户关联信息）
--    列：reportNo, customerId, customerName, fin_rpt_clber,
--        oprt_incm, rcvb_fnd_on_acct, due_fnd_on_acct, ivnt, dt, inputtime
--    1 行（去重键 reportNo+customerId 按 dt DESC 取最新，单行即最新）
-- =====================================================================
INSERT INTO dfs_crdt_loan_cust_rel (
    reportNo, customerId, customerName, fin_rpt_clber,
    oprt_incm, rcvb_fnd_on_acct, due_fnd_on_acct, ivnt, dt, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '本部',
    '20241231:19875.20|20251231:23640.80|20260330:12580.50',
    '20241231:3560.80|20251231:3980.25|20260330:4320.60',
    '20241231:2890.30|20251231:3120.70|20260330:2760.45',
    '20241231:3015.60|20251231:3280.90|20260330:3540.20',
    '20260330', '2026-09-11 12:00:00'
);

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_gs_finance_data.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 16 个业务列（reportScope + 3 日期 + 12 金额）将与 DML 目标行完全一致（1 行）
--   3. id 为 AUTO_INCREMENT（空表起算 = 1）
--   4. app_gs_finance_data_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），DML 中 '2026-09-11 12:00:00.0' 无法复现；
--      该列由系统自动填充，非加工 SQL 写入，属预期行为
--   5. 4 个财报科目列均为「前年|去年|最新」三期拼接，段内 日期:金额；加工 SQL SPLIT_PART 拆段后 CAST 金额
--   6. fin_rpt_clber='本部' 单值直取 reportScope
--   7. dt='20260330' 用于 ROW_NUMBER 去重（单行即最新）
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_gs_tax_sales_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_gs_tax_sales_info（国税销售额）源头表反推造数
-- 加工脚本：贷后检查加工/xd_gs_tax_sales.sql
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（mon_sale_amt 月度纳税销售额，append-only）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；取段用 SPLIT_PART）
--
-- 字段映射（xd_gs_tax_sales.sql）：
--   taxPeriod         <- SPLIT_PART(mon_sale_amt 元素, ':', 1)   月份键 YYYYMM（前 6 位）
--   monthlyTaxSales   <- CAST(SPLIT_PART(mon_sale_amt 元素, ':', 2) AS DECIMAL)   当月销售额
--   totalSalesTax     <- SUM(amt) OVER (PARTITION 年 ORDER 月)    当年 YTD 累计
--   yoyChange         <- 当年YTD - 上年同期YTD（p.hasData=1 时；否则 NULL）
--   yoyRate           <- yoyChange ÷ 上年同期YTD × 100（上年YTD=0 或无数据时 NULL）
--   id/inputtime      <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- 源头字段格式（mon_sale_amt，| 分隔，每元素 YYYYMM:金额，跨年）：
--   2025 年 12 个月 + 2026 年 8 个月（共 20 元素）
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：20（202501-202512 共 12 行 yoyChange=NULL + 202601-202608 共 8 行 yoyChange 有值）
--
-- -- ISSUE: xd_gs_tax_sales.sql 含 `WHERE r.yr = r.curYr` 过滤，curYr = MAX(yr) over partition。
--   当 mon_sale_amt 同时含 2025+2026 月份数据时，curYr=2026，仅输出 2026 的 8 行；
--   2025 的 12 行（target id 1-12, yoyChange=NULL）会被 curYr 过滤滤掉，无法在单次加工中产出。
--   目标 DML 的 20 行很可能由更早版本（无 curYr 过滤）或多次加工累积落表生成。
--   本文件提供的源数据可正确产出 2026 的 8 行（id 13-20 的业务数据，含 yoyChange/yoyRate 完全一致）；
--   若需产出全部 20 行，需在加工 SQL 移除 `WHERE r.yr = r.curYr` 限制（本任务禁止改加工 SQL）。
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_gs_tax_sales_info
-- [已上移至 §0] DELETE FROM dfs_crdt_loan_cust_rel

-- =====================================================================
-- 1. dfs_crdt_loan_cust_rel（数据融合平台·信贷客户关联信息）
--    列：reportNo, customerId, customerName, mon_sale_amt, dt, inputtime
--    1 行（去重键 reportNo+customerId 按 dt DESC 取最新，单行即最新）
--    mon_sale_amt 含 2025(12月)+2026(8月) 共 20 个元素，顺序：202501..202512|202601..202608
-- =====================================================================
-- [合并改写] 原 INSERT #2（reportNo, customerId, customerName, mon_sale_amt, dt, inputtime）→ UPDATE，把该组列补到同一行
UPDATE dfs_crdt_loan_cust_rel
SET
    reportNo = 'RPT-202609-001',
    customerId = 'CUST-001',
    customerName = '苏州XX精密机械制造有限公司',
    mon_sale_amt = '202501:120|202502:95|202503:110|202504:105|202505:130|202506:125|202507:115|202508:140|202509:135|202510:150|202511:145|202512:160|202601:100|202602:85|202603:105|202604:95|202605:115|202606:110|202607:100|202608:120',
    dt = '202608',
    inputtime = '2026-09-11 17:00:00'
WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001';

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_gs_tax_sales.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 可正确产出 2026 年 8 行（202601-202608），业务数据与 DML 目标行 13-20 完全一致：
--      - monthlyTaxSales: 100/85/105/95/115/110/100/120 ✓
--      - totalSalesTax(YTD): 100/185/290/385/500/610/710/830 ✓
--      - yoyChange: -20/-30/-35/-45/-60/-75/-90/-110 ✓（当年YTD - 上年同期YTD，2025数据作上年参考）
--      - yoyRate: -16.6667/-13.9535/-10.7692/-10.4651/-10.7143/-10.9489/-11.2500/-11.7021 ✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..8）
--   4. app_gs_tax_sales_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），DML 中 '2026-09-11 17:45:19.347078' 无法复现
--
--   ISSUE 详述（见文件头 ISSUE 注释）：
--   - 加工 SQL `WHERE r.yr = r.curYr` 限制只输出当前年（max 年份=2026）的行
--   - DML 目标的 2025 年 12 行（id 1-12, yoyChange=NULL, yoyRate=NULL）无法在单次加工中产出
--   - 若加工 SQL 移除 curYr 限制，则 2025 的 12 行也可正确产出（yoyChange=NULL 因无 2024 数据）
--   - 本任务禁止修改加工 SQL，故仅能产出 8/20 行
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_guofa_report_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_guofa_report_info（国发征信财务数据）源头表反推造数
-- 加工脚本：贷后检查加工/xd_guofa.sql
-- 源表（主档 + 三子表，mainId -> gfzx_national_dev.id）：
--   gfzx_national_dev         主档（报表期次表头 c_*/n_*/o_*，各含 前年/去年/去年同期/今年同期 四期）
--   gfzx_profit_sheet_item    利润表明细（n_cn_name 科目 + 四期金额）
--   gfzx_balance_sheet_item   资产负债表明细（c_cn_name 科目 + 四期余额）
--   gfzx_finance_index_item   主要财务指标明细（本表不取，预留）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_guofa.sql）：
--   dataDate           <- 主档 inputtime（CAST AS CHAR(32)，取前 10 位日期去横线 -> yyyyMMdd）
--   beforeYear         <- 主档 c_beforeYear（LEFT 32）
--   lastYear           <- 主档 c_lastYear（LEFT 32）
--   thisYear           <- 主档 c_samePeriodThisYear（LEFT 32）
--   gfRevenue          <- 利润表 n_cn_name='营业收入' n_current_qmye（REGEXP 守卫 + CAST DECIMAL）
--   lastYearRevenue     <- 同上 n_last_qmye
--   beforeYearRevenue    <- 同上 n_before_last_qmye
--   gfReceivable        <- 资产负债表 c_cn_name='应收账款' c_current_qmye
--   lastYearReceivable     <- 同上 c_last_qmye
--   beforeYearReceivable    <- 同上 c_before_last_qmye
--   gfPayable/gfInventory   <- 同上模式（'应付账款'/'存货'）
--   id/inputtime       <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--   主档 id     = 1（子表 mainId 指向）
--
-- 目标 DML 行数：1（一报告一行，16 列业务数据）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_guofa_report_info
-- [已上移至 §0] DELETE FROM gfzx_finance_index_item
-- [已上移至 §0] DELETE FROM gfzx_balance_sheet_item
-- [已上移至 §0] DELETE FROM gfzx_profit_sheet_item
-- [已上移至 §0] DELETE FROM gfzx_national_dev

-- =====================================================================
-- 1. gfzx_national_dev（国发征信主档；报表期次表头）
--    列：id, reportNo, customerId, customerName, c_beforeYear, c_lastYear, c_samePeriodThisYear, inputtime
--    1 行（去重键 reportNo 取最新，单行即最新）
--    inputtime='2026-09-10 10:30:00' -> dataDate='20260910'（前 10 位日期去横线）
-- =====================================================================
INSERT INTO gfzx_national_dev (id, reportNo, customerId, customerName, c_beforeYear, c_lastYear, c_samePeriodThisYear, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '20241231', '20251231', '20260331', '2026-09-10 10:30:00');

-- =====================================================================
-- 2. gfzx_profit_sheet_item（利润表明细；营业收入）
--    列：mainId, reportNo, customerId, customerName, n_cn_name,
--        n_before_last_qmye, n_last_qmye, n_current_qmye, inputtime
--    1 行（n_cn_name='营业收入'，按 mainId 取最新，单行即最新）
-- =====================================================================
INSERT INTO gfzx_profit_sheet_item (mainId, reportNo, customerId, customerName, n_cn_name, n_before_last_qmye, n_last_qmye, n_current_qmye, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '营业收入', '19875.20', '23640.80', '12580.50', '2026-09-10 10:30:00');

-- =====================================================================
-- 3. gfzx_balance_sheet_item（资产负债表明细；应收账款/应付账款/存货 三科目各 1 行）
--    列：mainId, reportNo, customerId, customerName, c_cn_name,
--        c_before_last_qmye, c_last_qmye, c_current_qmye, inputtime
-- =====================================================================

-- 应收账款：c_current_qmye=4320.60 / c_last_qmye=3980.25 / c_before_last_qmye=3560.80
INSERT INTO gfzx_balance_sheet_item (mainId, reportNo, customerId, customerName, c_cn_name, c_before_last_qmye, c_last_qmye, c_current_qmye, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '应收账款', '3560.80', '3980.25', '4320.60', '2026-09-10 10:30:00');

-- 应付账款：c_current_qmye=2760.45 / c_last_qmye=3120.70 / c_before_last_qmye=2890.30
INSERT INTO gfzx_balance_sheet_item (mainId, reportNo, customerId, customerName, c_cn_name, c_before_last_qmye, c_last_qmye, c_current_qmye, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '应付账款', '2890.30', '3120.70', '2760.45', '2026-09-10 10:30:00');

-- 存货：c_current_qmye=3540.20 / c_last_qmye=3280.90 / c_before_last_qmye=3015.60
INSERT INTO gfzx_balance_sheet_item (mainId, reportNo, customerId, customerName, c_cn_name, c_before_last_qmye, c_last_qmye, c_current_qmye, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '存货', '3015.60', '3280.90', '3540.20', '2026-09-10 10:30:00');

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_guofa.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 16 个业务列（dataDate + 3 期次 + 12 金额）将与 DML 目标行完全一致（1 行）：
--      - dataDate='20260910'（主档 inputtime 前 10 位去横线）✓
--      - beforeYear/lastYear/thisYear = 20241231/20251231/20260331 ✓
--      - gfRevenue/lastYearRevenue/beforeYearRevenue = 12580.50/23640.80/19875.20 ✓
--      - gfReceivable/lastYearReceivable/beforeYearReceivable = 4320.60/3980.25/3560.80 ✓
--      - gfPayable/lastYearPayable/beforeYearPayable = 2760.45/3120.70/2890.30 ✓
--      - gfInventory/lastYearInventory/beforeYearInventory = 3540.20/3280.90/3015.60 ✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1）
--   4. app_guofa_report_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），DML 中 '2026-09-10 10:30:00.0' 无法复现
--   5. 主档 id=1（显式），子表 mainId=1 精确指向；四组 LEFT JOIN 均命中
--   6. 金额 VARCHAR 经 REGEXP 数字守卫 + CAST DECIMAL(18,2)，源值均为合法数字
--   7. 科目精确匹配：'营业收入'/'应收账款'/'应付账款'/'存货'
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_payroll_stat_info.sql
-- ---------------------------------------------------------------------
﻿-- =====================================================================
-- app_payroll_stat_info（代发统计·月粒度）源头表反推造数
-- 加工脚本：贷后检查加工/xd_payroll.sql
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（代发字段，append-only）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；strpos 定位 + SPLIT_PART 取段）
--
-- 字段映射（xd_payroll.sql）：
--   statMonth      <- SPLIT_PART(instd_sal_moly, '|', n)           月份键 YYYYMM（驱动列）
--   payrollCount   <- CAST(instd_sal_person_moly 按 月份键取值 AS INTEGER)   每月代发人数
--   payrollAmount  <- CAST(instd_sal_amt_moly    按 月份键取值 AS DECIMAL)  每月代发金额（万元）
--   countMom       <- CAST(instd_sal_person_moly_hb 按 月份键取值 AS DECIMAL(12,4)) × 100  每月人数环比（%）
--   amountMom      <- CAST(instd_sal_amt_moly_hb     按 月份键取值 AS DECIMAL(12,4)) × 100  每月金额环比（%）
--   countYoy       <- CAST(instd_sal_person_moly_tb 按 月份键取值 AS DECIMAL(12,4)) × 100  每月人数同比（%）
--   amountYoy      <- CAST(instd_sal_amt_moly_tb    按 月份键取值 AS DECIMAL(12,4)) × 100  每月金额同比（%）
--   id/inputtime   <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- -- ISSUE: xd_payroll.sql 对 countMom/amountMom/countYoy/amountYoy 4 列做 ×100 转换
--   （源为小数比率 0.01=1%，app 单位为 %，加工层 ×100）。但 DML 目标值（如 0.0273）
--   疑似未经 ×100 的原始比率值。若按当前 SQL 加工，这 4 列输出值为 DML 目标值 × 100
--   （如 0.0273 → 2.7300），与 DML 不一致。DML 可能由更早版本（无 ×100）生成。
--   本文件源数据按 DML 目标值直填（payrollCount/payrollAmount 2 列可完全匹配；
--   4 列环比/同比因 ×100 差异无法完全匹配）。
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：12（statMonth: 202603..202702）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
DELETE FROM app_payroll_stat_info  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
-- [已上移至 §0] DELETE FROM dfs_crdt_loan_cust_rel

-- =====================================================================
-- 1. dfs_crdt_loan_cust_rel（数据融合平台·信贷客户关联信息）
--    列：reportNo, customerId, customerName,
--        instd_sal_moly, instd_sal_person_moly, instd_sal_amt_moly,
--        instd_sal_person_moly_hb, instd_sal_amt_moly_hb,
--        instd_sal_person_moly_tb, instd_sal_amt_moly_tb, dt, inputtime
--    1 行（去重键 reportNo+customerId 按 dt DESC 取最新，单行即最新）
--    7 个代发列各 12 个月数据；环比列稀疏（202603 首月无 MoM）
-- =====================================================================
-- [合并改写] 原 INSERT #3（reportNo, customerId, customerName, instd_sal_moly, instd_sal_person_moly, instd_sal_amt_moly, instd_sal_person_moly_hb, instd_sal_amt_moly_hb, instd_sal_person_moly_tb, instd_sal_amt_moly_tb, dt, inputtime）→ UPDATE，把该组列补到同一行
UPDATE dfs_crdt_loan_cust_rel
SET
    reportNo = 'RPT-202609-001',
    customerId = 'CUST-001',
    customerName = '苏州XX精密机械制造有限公司',
    instd_sal_moly = -- instd_sal_moly: 12 个月份键
    '202603|202604|202605|202606|202607|202608|202609|202610|202611|202612|202701|202702',
    instd_sal_person_moly = -- instd_sal_person_moly: 每月代发人数
    '202603:1280|202604:1315|202605:1298|202606:1342|202607:1376|202608:1358|202609:1405|202610:1428|202611:1396|202612:1462|202701:1490|202702:1516',
    instd_sal_amt_moly = -- instd_sal_amt_moly: 每月代发金额（万元）
    '202603:856.32|202604:889.75|202605:872.40|202606:910.18|202607:936.52|202608:921.06|202609:958.44|202610:973.20|202611:949.88|202612:1005.36|202701:1028.75|202702:1052.40',
    instd_sal_person_moly_hb = -- instd_sal_person_moly_hb: 每月人数环比（稀疏，202603 首月无 MoM）
    '202604:0.0273|202605:-0.0129|202606:0.0339|202607:0.0253|202608:-0.0131|202609:0.0346|202610:0.0164|202611:-0.0224|202612:0.0473|202701:0.0192|202702:0.0174',
    instd_sal_amt_moly_hb = -- instd_sal_amt_moly_hb: 每月金额环比（稀疏，202603 首月无 MoM）
    '202604:0.0390|202605:-0.0195|202606:0.0433|202607:0.0289|202608:-0.0165|202609:0.0406|202610:0.0154|202611:-0.0240|202612:0.0584|202701:0.0233|202702:0.0230',
    instd_sal_person_moly_tb = -- instd_sal_person_moly_tb: 每月人数同比（12 月全有）
    '202603:0.0821|202604:0.0756|202605:0.0643|202606:0.0918|202607:0.0887|202608:0.0724|202609:0.1052|202610:0.0978|202611:0.0835|202612:0.1126|202701:0.1189|202702:0.1243',
    instd_sal_amt_moly_tb = -- instd_sal_amt_moly_tb: 每月金额同比（12 月全有）
    '202603:0.0912|202604:0.0834|202605:0.0715|202606:0.1023|202607:0.0968|202608:0.0811|202609:0.1136|202610:0.1044|202611:0.0902|202612:0.1218|202701:0.1265|202702:0.1327',
    dt = '202702',
    inputtime = '2026-09-10 23:00:00'
WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001';

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_payroll.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 可正确产出 12 行（statMonth: 202603..202702）
--   3. payrollCount/payrollAmount 2 列与 DML 完全一致（无 ×100 转换，直接 CAST）：
--      - payrollCount: 1280/1315/1298/1342/1376/1358/1405/1428/1396/1462/1490/1516 ✓
--      - payrollAmount: 856.32/889.75/872.40/910.18/936.52/921.06/958.44/973.20/949.88/1005.36/1028.75/1052.40 ✓
--   4. countMom=NULL (202603 首月，环比串稀疏无此月) ✓
--
--   ISSUE 详述（见文件头 ISSUE 注释）：
--   - countMom/amountMo countYoy/amountYoy 4 列，加工 SQL 做 ×100 转换
--   - DML 目标值（0.0273 等）疑似未 ×100 的原始比率，当前 SQL 输出 = DML × 100（如 0.0273 → 2.7300）
--   - DECIMAL(12,4) 精度限制：source=0.000273 会被 round 为 0.0003，×100=0.0300 ≠ 0.0273
--   - 故 4 列环比/同比无法精确匹配 DML（2 列人数/金额可完全匹配）
--   - id 为 AUTO_INCREMENT（空表起算 = 1..12）
--   - app_payroll_stat_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP，DML 时间戳无法复现
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_reputation_event_info.sql
-- ---------------------------------------------------------------------
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
-- [已上移至 §0] DELETE FROM app_reputation_event_info
-- [已上移至 §0] DELETE FROM dfs_final_crdt_loan_cust_rel

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
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_settle_account_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_settle_account_info（结算账户）源头表反推造数
-- 加工脚本：贷后检查加工/xd_settle_account.sql
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（acct_zhxx 账户信息列，append-only）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；SPLIT_PART 取段）
--
-- 字段映射（xd_settle_account.sql）：
--   accountNo       <- acct_zhxx 账户段1（; 分隔）  账号
--   accountStatus   <- acct_zhxx 账户段2           账户状态（原样透传）
--   accountBalance  <- CAST(acct_zhxx 账户段3 AS DECIMAL)  账户余额（万元）
--   superviseFlag   <- acct_zhxx 账户段5           监管标识（原样透传）
--   id/inputtime    <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- 源头字段格式（acct_zhxx，| 分隔账户，; 分隔账户内 10 段）：
--   账户1;状态;余额;开户机构;监管标识;seg6;seg7;seg8;seg9;seg10|账户2;...
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：5（5 个结算账户）
--
-- 注意：dfs_crdt_loan_cust_rel 为多张 app 表共用源表（gs_finance_data/gs_tax_sales/payroll/
--   settle_account/settle_asset/settle_counterparty）。本文件独立清理+造数，单独执行可验证
--   settle_account 加工；若与其他共用源表的文件同时执行，后执行者覆盖先者的 dfs 行。
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_settle_account_info
-- [已上移至 §0] DELETE FROM dfs_crdt_loan_cust_rel

-- =====================================================================
-- 1. dfs_crdt_loan_cust_rel（数据融合平台·信贷客户关联信息）
--    列：reportNo, customerId, customerName, acct_zhxx, dt, inputtime
--    1 行（去重键 reportNo+customerId 按 dt DESC 取最新，单行即最新）
--    acct_zhxx 含 5 个账户，每个 10 段（; 分隔），账户间 | 分隔
-- =====================================================================
-- [合并改写] 原 INSERT #4（reportNo, customerId, customerName, acct_zhxx, dt, inputtime）→ UPDATE，把该组列补到同一行
UPDATE dfs_crdt_loan_cust_rel
SET
    reportNo = 'RPT-202609-001',
    customerId = 'CUST-001',
    customerName = '苏州XX精密机械制造有限公司',
    acct_zhxx = -- 账户1: 320501-8888-0001 / 正常 / 125.60 / 开户机构1 / 否
    '320501-8888-0001;正常;125.60;开户机构1;否;seg6;seg7;seg8;seg9;seg10'
    -- 账户2: 320501-8888-0002 / 冻结 / 88.35 / 开户机构2 / 否
    || '|320501-8888-0002;冻结;88.35;开户机构2;否;seg6;seg7;seg8;seg9;seg10'
    -- 账户3: 320501-8888-0003 / 正常 / 210.75 / 开户机构3 / 否
    || '|320501-8888-0003;正常;210.75;开户机构3;否;seg6;seg7;seg8;seg9;seg10'
    -- 账户4: 320501-8888-0004 / 正常 / 56.20 / 开户机构4 / 否
    || '|320501-8888-0004;正常;56.20;开户机构4;否;seg6;seg7;seg8;seg9;seg10'
    -- 账户5: 320501-8888-0005 / 正常 / 342.10 / 开户机构5 / 否
    || '|320501-8888-0005;正常;342.10;开户机构5;否;seg6;seg7;seg8;seg9;seg10',
    dt = '20260911',
    inputtime = '2026-09-11 10:00:00'
WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001';

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_settle_account.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 5 个业务列（accountNo/accountStatus/accountBalance/superviseFlag）+ 3 公共列 与 DML 完全一致（5 行）：
--      - accountNo: 320501-8888-0001..0005 ✓
--      - accountStatus: 正常/冻结/正常/正常/正常 ✓
--      - accountBalance: 125.60/88.35/210.75/56.20/342.10 ✓
--      - superviseFlag: 否/否/否/否/否 ✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..5，按账户串内 | 顺序）
--   4. app_settle_account_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP，DML 时间戳无法复现
--   5. accountStatus/superviseFlag 为中文码值（原样透传，加工 SQL 无 CASE 转换）
--   6. 共用源表注意：见文件头注释（dfs_crdt_loan_cust_rel 为多 app 表共用）
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_settle_asset_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_settle_asset_info（结算资产）源头表反推造数
-- 加工脚本：贷后检查加工/xd_settle_asset.sql
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（结算/代发等经营字段，append-only）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；strpos 定位 + SPLIT_PART 取段）
--
-- 字段映射（xd_settle_asset.sql）：
--   frozenAmount                     <- fzn_amt（单值，直接 CAST DECIMAL）
--   debitSameNameTransferRatio       <- hnym_tfrd_amt_dbt_pcnt（单值，直接 CAST DECIMAL(5,2)）
--   creditSameNameTransferRatio      <- hnym_tfrd_amt_cr_pcnt（单值，直接 CAST DECIMAL(5,2)）
--   yearAvgDeposit                   <- dep_y_avg_bal「当年」段（标签取段，CAST DECIMAL）
--   lastYearAvgDeposit                <- dep_y_avg_bal「去年」段（标签取段，CAST DECIMAL）
--   propertyIncome                   <- yr_pty_income「当年/去年」段（1月规则 selIdx，CAST DECIMAL）
--   propertyIncomeYoy                 <- yr_pty_income_ch 同段（CAST DECIMAL(18,2) × 100 → %）
--   propertyIncomeSupervised           <- yr_pty_income_regy 同段（CAST DECIMAL）
--   electricFeeIncome                  <- elec_income 同段（CAST DECIMAL）
--   electricFeeYoy                     <- elec_income_ch 同段（CAST DECIMAL(18,2) × 100 → %）
--   electricFeeSupervised              <- elec_income_regy 同段（CAST DECIMAL）
--   keywordCounterpartyCreditAmount     <- cr_acr_amt_2 同段（CAST DECIMAL）
--   keywordRemarkCreditAmount           <- cr_acr_amt_1 同段（CAST DECIMAL）
--   id/inputtime    <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- -- ISSUE: propertyIncomeYoy / electricFeeYoy 2 列加工 SQL 做 ×100 转换
--   （源为小数比率，CAST(18,2) 后 ×100）。DML 目标值（23.60 / -5.30）疑似未 ×100 的原始值。
--   CAST('0.236' AS DECIMAL(18,2))=0.24 → ×100=24.00 ≠ 23.60；无法精确匹配。
--   本文件源值按 DML 目标值直填（11 列可完全匹配，2 列 ×100 有差异）。
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--   dt          = '20260911'（月份=09≠01 → selIdx=1 取「当年」段）
--
-- 目标 DML 行数：1（一客户一行，13 列业务数据）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_settle_asset_info
-- [已上移至 §0] DELETE FROM dfs_crdt_loan_cust_rel

-- =====================================================================
-- 1. dfs_crdt_loan_cust_rel（数据融合平台·信贷客户关联信息）
--    列：reportNo, customerId, customerName,
--        fzn_amt, hnym_tfrd_amt_dbt_pcnt, hnym_tfrd_amt_cr_pcnt,
--        dep_y_avg_bal, yr_pty_income, yr_pty_income_ch, yr_pty_income_regy,
--        elec_income, elec_income_ch, elec_income_regy,
--        cr_acr_amt_1, cr_acr_amt_2, dt, inputtime
--    1 行（去重键 reportNo+customerId 按 dt DESC 取最新，单行即最新）
--    标签列格式：当年:值|去年:值（selIdx=1 取当年段）
-- =====================================================================
-- [合并改写] 原 INSERT #5（reportNo, customerId, customerName, fzn_amt, hnym_tfrd_amt_dbt_pcnt, hnym_tfrd_amt_cr_pcnt, dep_y_avg_bal, yr_pty_income, yr_pty_income_ch, yr_pty_income_regy, elec_income, elec_income_ch, elec_income_regy, cr_acr_amt_1, cr_acr_amt_2, dt, inputtime）→ UPDATE，把该组列补到同一行
UPDATE dfs_crdt_loan_cust_rel
SET
    reportNo = 'RPT-202609-001',
    customerId = 'CUST-001',
    customerName = '苏州XX精密机械制造有限公司',
    fzn_amt = -- 3 单值列（直接 CAST）
    '88.35',
    hnym_tfrd_amt_dbt_pcnt = '12.50',
    hnym_tfrd_amt_cr_pcnt = '15.80',
    dep_y_avg_bal = -- dep 固定当年/去年段
    '当年:286.45|去年:245.30',
    yr_pty_income = -- 物业 3 列（selIdx=1 取当年段）
    '当年:156.80|去年:0',
    yr_pty_income_ch = '当年:23.60|去年:0',
    yr_pty_income_regy = '当年:45.20|去年:0',
    elec_income = -- 电费 3 列（selIdx=1 取当年段）
    '当年:78.50|去年:0',
    elec_income_ch = '当年:-5.30|去年:0',
    elec_income_regy = '当年:20.10|去年:0',
    cr_acr_amt_1 = -- 关键字 2 列（selIdx=1 取当年段）
    '当年:85.50|去年:0',
    cr_acr_amt_2 = '当年:120.00|去年:0',
    dt = '20260911',
    inputtime = '2026-09-11 11:00:00'
WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001';

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_settle_asset.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 11 列可完全匹配 DML 目标行（frozenAmount/debitSameNameTransferRatio/creditSameNameTransferRatio/
--      yearAvgDeposit/lastYearAvgDeposit/propertyIncome/propertyIncomeSupervised/electricFeeIncome/
--      electricFeeSupervised/keywordCounterpartyCreditAmount/keywordRemarkCreditAmount）：
--      - frozenAmount=88.35 ✓  debit=12.50 ✓  credit=15.80 ✓
--      - yearAvgDeposit=286.45 ✓  lastYearAvgDeposit=245.30 ✓
--      - propertyIncome=156.80 ✓  propertyIncomeSupervised=45.20 ✓
--      - electricFeeIncome=78.50 ✓  electricFeeSupervised=20.10 ✓
--      - keywordCounterpartyCreditAmount=120.00 ✓  keywordRemarkCreditAmount=85.50 ✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1）
--   4. app_settle_asset_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP，DML 时间戳无法复现
--   5. dt='20260911' 月份=09≠01 → selIdx=1（取当年段）
--
--   ISSUE（见文件头）：propertyIncomeYoy / electricFeeYoy 2 列 ×100 转换差异
--   - DML 目标：23.60 / -5.30（疑似未 ×100）
--   - 当前 SQL 输出：源 23.60 ×100 = 2360.00 / 源 -5.30 ×100 = -530.00
--   - DECIMAL(18,2) 精度限制使得 source/100 方案也不可行（0.236→0.24→24.00）
--   - 故此 2 列无法精确匹配 DML（11/13 列可匹配）
--   6. 共用源表注意：见 settle_account 文件头注释（dfs_crdt_loan_cust_rel 为多 app 表共用）
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_settle_counterparty_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_settle_counterparty_info（结算交易对手）源头表反推造数
-- 加工脚本：贷后检查加工/xd_settle_counterparty.sql
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（dbt_cntpr_and_acr_amt / cr_cntpr_and_acr_amt，append-only）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；SPLIT_PART 取段）
--
-- 字段映射（xd_settle_counterparty.sql）：
--   counterpartyName <- SPLIT_PART(元素, ':', 1)   交易对手名称
--   direction        <- 借方(dbt 串) / 贷方(cr 串)
--   amount           <- CAST(SPLIT_PART(元素, ':', 2) AS DECIMAL)  发生额（万元）
--   rankNo           <- DENSE_RANK() OVER (PARTITION direction ORDER BY amount DESC) → CAST AS CHAR(16)
--   upstreamFlag/remark <- 不加工（字典标「删除/未执行」，默认 NULL）
--   id/inputtime    <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- 源头字段格式（2 列各存「前十大」，| 分隔，每元素 name:amt）：
--   dbt_cntpr_and_acr_amt  借方：name:amt|name:amt|...
--   cr_cntpr_and_acr_amt   贷方：name:amt|name:amt|...
--
-- -- ISSUE 1: 加工 SQL CROSS JOIN 序号仅 1..10，每方向最多 10 行；DML 目标 40 行（借/贷各 20）
--   当前 SQL 仅能产出 20 行（借/贷各 10），DML 的 20-40 号行（TOP11-TOP20）无法产出。
-- -- ISSUE 2: rankNo 格式差异：加工 SQL 输出 CAST(dr AS CHAR(16)) = '1'/'2'/...；
--   DML 目标为 'TOP1'/'TOP2'/...（含 'TOP' 前缀），格式不一致。
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_settle_counterparty_info
-- [已上移至 §0] DELETE FROM dfs_crdt_loan_cust_rel

-- =====================================================================
-- 1. dfs_crdt_loan_cust_rel（数据融合平台·信贷客户关联信息）
--    列：reportNo, customerId, customerName,
--        dbt_cntpr_and_acr_amt, cr_cntpr_and_acr_amt, dt, inputtime
--    1 行（去重键 reportNo+customerId 按 dt DESC 取最新，单行即最新）
--    借方 20 元素 + 贷方 20 元素（均按发生额降序）
-- =====================================================================
-- [合并改写] 原 INSERT #6（reportNo, customerId, customerName, dbt_cntpr_and_acr_amt, cr_cntpr_and_acr_amt, dt, inputtime）→ UPDATE，把该组列补到同一行
UPDATE dfs_crdt_loan_cust_rel
SET
    reportNo = 'RPT-202609-001',
    customerId = 'CUST-001',
    customerName = '苏州XX精密机械制造有限公司',
    dbt_cntpr_and_acr_amt = -- 借方 19 个交易对手（TOP1-TOP19，按发生额降序）
    '江苏恒力特钢有限公司:1250.50|上海精工轴承有限公司:1180.30|无锡泰达电机有限公司:1050.80|常州瑞新机械配件有限公司:980.60|宁波海天精密工业有限公司:920.40|杭州智造装备有限公司:880.20|南京自动化科技有限公司:850.00|合肥中科智能装备有限公司:820.75|苏州华鑫金属材料有限公司:790.50|上海宝钢贸易有限公司:730.00|浙江联创机械有限公司:700.80|安徽合力叉车有限公司:680.40|山东临工机械有限公司:660.20|徐工集团工程机械有限公司:640.00|三一重工股份有限公司:620.50|中联重科股份有限公司:600.30|广西柳工机械股份有限公司:580.10|厦门厦工机械股份有限公司:560.00|山推工程机械股份有限公司:540.60',
    cr_cntpr_and_acr_amt = -- 贷方 20 个交易对手（TOP1-TOP20，按发生额降序）
    '苏州工业园区联合贸易有限公司:1500.00|上海东浩国际贸易有限公司:1420.50|南京金陵机械有限公司:1350.80|杭州万向传动轴有限公司:1280.30|宁波均胜电子股份有限公司:1200.00|合肥美菱股份有限公司:1150.60|无锡威孚高科技集团股份有限公司:1100.40|常州星宇车灯股份有限公司:1050.20|江苏沙钢集团有限公司:1000.00|浙江吉利控股集团有限公司:950.80|安徽江淮汽车集团股份有限公司:900.50|山东重工集团有限公司:860.30|徐州工程机械集团有限公司:820.10|三一集团有限公司:780.00|中联重科股份有限公司:740.60|广西玉柴机器集团有限公司:700.40|厦门金龙联合汽车工业有限公司:660.20|山推工程机械股份有限公司:620.00|苏州创元投资发展有限公司:580.80|上海电气集团股份有限公司:540.60',
    dt = '20260911',
    inputtime = '2026-09-11 11:43:00'
WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001';

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_settle_counterparty.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 借方/贷方前 10 名的 counterpartyName/direction/amount 3 列与 DML TOP1-TOP10 完全一致：
--      借方 TOP1: 江苏恒力特钢有限公司/借方/1250.50 ✓
--      借方 TOP2: 上海精工轴承有限公司/借方/1180.30 ✓ ...（依此类推至 TOP10）
--      贷方 TOP1: 苏州工业园区联合贸易有限公司/贷方/1500.00 ✓ ...（依此类推至 TOP10）
--   3. upstreamFlag/remark 2 列 DML 为 NULL，加工 SQL 不插入，默认 NULL ✓
--   4. id 为 AUTO_INCREMENT（空表起算，ORDER BY direction, amount DESC）
--   5. app_settle_counterparty_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP，DML 时间戳无法复现
--
--   ISSUE 1（见文件头）：CROSS JOIN 仅 1..10，每方向最多 10 行
--   - DML 目标 40 行（借/贷各 20），当前 SQL 仅产出 20 行（借/贷各 10）
--   - 借方 TOP11-TOP20 / 贷方 TOP11-TOP20 无法产出（源数据已提供 20 个，但 SQL 只取前 10）
--
--   ISSUE 2（见文件头）：rankNo 格式差异
--   - 加工 SQL: CAST(DENSE_RANK() AS CHAR(16)) = '1'/'2'/...'10'
--   - DML 目标: 'TOP1'/'TOP2'/...'TOP10'（含 'TOP' 前缀）
--   - 格式不一致，DML 疑似由更早版本（含 'TOP' 前缀格式化）生成
--
--   6. 共用源表注意：见 settle_account 文件头注释（dfs_crdt_loan_cust_rel 为多 app 表共用）
-- =====================================================================

-- =====================================================================
--

-- =====================================================================
-- §2 加工（各原脚本的加工段，原样保留）
-- =====================================================================

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_capital_flow_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_capital_flow.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
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
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

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
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
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
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) mc WHERE mc.rn = 1
    )
) cur ON cur.reportNo = f.reportNo AND cur.loanSerialNo = f.loanSerialNo AND cur.lrn = 1
WHERE f.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_graph_hit_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_gs_finance_data_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_gs_finance_data.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 国税》国税财务数据 · 源头表 -> app_gs_finance_data_info 加工
-- 节点：数据融合平台 dfsDataQry》信贷客户关联信息
--       （adm_stas_plma_crdt_loan_cust_rel_info，DfsDataQryService.queryCrdtLoanCustRelInfo 落表）
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（财税/结算/代发等经营字段，append-only）
-- 目标：app_gs_finance_data_info（国税财务数据表，业务主键 reportNo + customerId，一个客户一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；字符串拼接用 CONCAT 不用 ||，取段用 SPLIT_PART）
--
-- 源头字段格式（4 个财报科目列各为「三期拼接值」，| 分隔，顺序 前年|去年|最新，每段 日期:金额；依据中台样例）：
--   oprt_incm        2024-12-31:47473968.1|2025-12-31:3967996.09|2026-06-30:50167646.76
--   rcvb_fnd_on_acct 2024-12-31:1403477.5|2025-12-31:1468103.94|2026-06-30:2327827.98
--   due_fnd_on_acct  2024-12-31:37781.63|2025-12-31:165968.52|2026-06-30:173875.98
--   ivnt             2024-12-31:4019650.05|2025-12-31:2738977.1|2026-06-30:1293680.29
--   fin_rpt_clber    合并            （财报口径，单值）
--   三期 = 段1 前年 / 段2 去年 / 段3 最新；段内 SPLIT_PART(':',1)=日期、SPLIT_PART(':',2)=金额
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_gs_finance_data_info 段）：
--   reportScope          <- fin_rpt_clber            财报口径（单值直取）
--   beforeYear           <- oprt_incm 段1 日期        前年日期
--   lastYear             <- oprt_incm 段2 日期        去年日期
--   thisYear             <- oprt_incm 段3 日期        最新一期日期
--   gfRevenue            <- oprt_incm 段3 金额        最近一期营收（万元）
--   lastYearRevenue      <- oprt_incm 段2 金额        去年营收（万元）
--   beforeYearRevenue    <- oprt_incm 段1 金额        前年营收（万元）
--   gfReceivable         <- rcvb_fnd_on_acct 段3      最近一期应收账款（万元）
--   lastYearReceivable   <- rcvb_fnd_on_acct 段2      去年应收账款（万元）
--   beforeYearReceivable <- rcvb_fnd_on_acct 段1      前年应收账款（万元）
--   gfPayable            <- due_fnd_on_acct 段3       最近一期应付账款（万元）
--   lastYearPayable      <- due_fnd_on_acct 段2       去年应付账款（万元）
--   beforeYearPayable    <- due_fnd_on_acct 段1       前年应付账款（万元）
--   gfInventory          <- ivnt 段3                  最近一期存货（万元）
--   lastYearInventory    <- ivnt 段2                  去年存货（万元）
--   beforeYearInventory  <- ivnt 段1                  前年存货（万元）
--   （字典源列名 rovb_fnd_on_acct 为笔误，实际 DDL 列 rcvb_fnd_on_acct）
--
-- 处理规则（对齐 xd_payroll.sql / xd_settle_asset.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_gs_finance_data_info 本次范围旧行，再插入
--   2. 取最新一个 dt：append-only，按 (reportNo, customerId) 内 ROW_NUMBER() ORDER BY (dt 是否空) 升序、
--      dt DESC、inputtime DESC、id DESC 取 rn=1（最新 dt 一行）
--   3. 三期拼接列 SPLIT_PART('|',1/2/3) 取段，段内 SPLIT_PART(':',1)=日期、SPLIT_PART(':',2)=金额；
--      一客户一行（16 列），不拆行
--   4. CAST：金额 VARCHAR->DECIMAL(18,2)，空段置 NULL（防 CAST('') 报错）；日期/口径 VARCHAR 直取
-- =====================================================================

-- 1. 幂等
DELETE FROM app_gs_finance_data_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 国税财务数据：取最新 dt 一行 -> 4 科目三期拼接拆 16 列 + 口径 -> app_gs_finance_data_info
INSERT INTO app_gs_finance_data_info (
    reportNo, customerId, customerName, reportScope,
    beforeYear, lastYear, thisYear,
    gfRevenue, lastYearRevenue, beforeYearRevenue,
    gfReceivable, lastYearReceivable, beforeYearReceivable,
    gfPayable, lastYearPayable, beforeYearPayable,
    gfInventory, lastYearInventory, beforeYearInventory
)
SELECT
    t.reportNo,
    t.customerId,
    t.customerName,
    t.scope                AS reportScope,
    SPLIT_PART(t.o1, ':', 1) AS beforeYear,
    SPLIT_PART(t.o2, ':', 1) AS lastYear,
    SPLIT_PART(t.o3, ':', 1) AS thisYear,
    CAST(CASE WHEN t.rev3 IS NULL OR t.rev3 = '' THEN NULL ELSE t.rev3 END AS DECIMAL(18,2)) AS gfRevenue,
    CAST(CASE WHEN t.rev2 IS NULL OR t.rev2 = '' THEN NULL ELSE t.rev2 END AS DECIMAL(18,2)) AS lastYearRevenue,
    CAST(CASE WHEN t.rev1 IS NULL OR t.rev1 = '' THEN NULL ELSE t.rev1 END AS DECIMAL(18,2)) AS beforeYearRevenue,
    CAST(CASE WHEN t.rcv3 IS NULL OR t.rcv3 = '' THEN NULL ELSE t.rcv3 END AS DECIMAL(18,2)) AS gfReceivable,
    CAST(CASE WHEN t.rcv2 IS NULL OR t.rcv2 = '' THEN NULL ELSE t.rcv2 END AS DECIMAL(18,2)) AS lastYearReceivable,
    CAST(CASE WHEN t.rcv1 IS NULL OR t.rcv1 = '' THEN NULL ELSE t.rcv1 END AS DECIMAL(18,2)) AS beforeYearReceivable,
    CAST(CASE WHEN t.pay3 IS NULL OR t.pay3 = '' THEN NULL ELSE t.pay3 END AS DECIMAL(18,2)) AS gfPayable,
    CAST(CASE WHEN t.pay2 IS NULL OR t.pay2 = '' THEN NULL ELSE t.pay2 END AS DECIMAL(18,2)) AS lastYearPayable,
    CAST(CASE WHEN t.pay1 IS NULL OR t.pay1 = '' THEN NULL ELSE t.pay1 END AS DECIMAL(18,2)) AS beforeYearPayable,
    CAST(CASE WHEN t.inv3 IS NULL OR t.inv3 = '' THEN NULL ELSE t.inv3 END AS DECIMAL(18,2)) AS gfInventory,
    CAST(CASE WHEN t.inv2 IS NULL OR t.inv2 = '' THEN NULL ELSE t.inv2 END AS DECIMAL(18,2)) AS lastYearInventory,
    CAST(CASE WHEN t.inv1 IS NULL OR t.inv1 = '' THEN NULL ELSE t.inv1 END AS DECIMAL(18,2)) AS beforeYearInventory
FROM (
    SELECT m.*, ROW_NUMBER() OVER (
        PARTITION BY m.reportNo, COALESCE(m.customerId, '')
        ORDER BY CASE WHEN m.dt IS NULL THEN 1 ELSE 0 END ASC, m.dt DESC, m.inputtime DESC, m.id DESC
    ) AS rn
    FROM (
        -- m：三期拼接列 SPLIT_PART('|',n) 取段，再 SPLIT_PART(':',n) 拆日期/金额
        SELECT reportNo, customerId, customerName, dt, inputtime, id,
            fin_rpt_clber                       AS scope,
            SPLIT_PART(oprt_incm,        '|', 1) AS o1,
            SPLIT_PART(oprt_incm,        '|', 2) AS o2,
            SPLIT_PART(oprt_incm,        '|', 3) AS o3,
            SPLIT_PART(SPLIT_PART(oprt_incm,        '|', 1), ':', 2) AS rev1,
            SPLIT_PART(SPLIT_PART(oprt_incm,        '|', 2), ':', 2) AS rev2,
            SPLIT_PART(SPLIT_PART(oprt_incm,        '|', 3), ':', 2) AS rev3,
            SPLIT_PART(SPLIT_PART(rcvb_fnd_on_acct, '|', 1), ':', 2) AS rcv1,
            SPLIT_PART(SPLIT_PART(rcvb_fnd_on_acct, '|', 2), ':', 2) AS rcv2,
            SPLIT_PART(SPLIT_PART(rcvb_fnd_on_acct, '|', 3), ':', 2) AS rcv3,
            SPLIT_PART(SPLIT_PART(due_fnd_on_acct,  '|', 1), ':', 2) AS pay1,
            SPLIT_PART(SPLIT_PART(due_fnd_on_acct,  '|', 2), ':', 2) AS pay2,
            SPLIT_PART(SPLIT_PART(due_fnd_on_acct,  '|', 3), ':', 2) AS pay3,
            SPLIT_PART(SPLIT_PART(ivnt,             '|', 1), ':', 2) AS inv1,
            SPLIT_PART(SPLIT_PART(ivnt,             '|', 2), ':', 2) AS inv2,
            SPLIT_PART(SPLIT_PART(ivnt,             '|', 3), ':', 2) AS inv3
        FROM dfs_crdt_loan_cust_rel
        WHERE reportNo IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) m
) t
WHERE t.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_gs_tax_sales_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_gs_tax_sales.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 国税》国税销售额 · 源头表 -> app_gs_tax_sales_info 加工
-- 节点：数据融合平台 dfsDataQry》信贷客户关联信息
--       （adm_stas_plma_crdt_loan_cust_rel_info，DfsDataQryService.queryCrdtLoanCustRelInfo 落表）
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（财税/结算/代发等经营字段，append-only）
-- 目标：app_gs_tax_sales_info（国税销售额表，业务主键 reportNo + customerId + taxPeriod，一月份一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；字符串拼接用 CONCAT 不用 ||，取段用 SPLIT_PART）
--
-- 源头字段格式（mon_sale_amt，| 分隔，每个元素自带「年份」前缀，跨年）：
--   YYYYMM:金额|YYYYMM:金额|...   （如 202601:150|202602:200|...|202501:80|...；某月无值时该月不出现或金额为空）
--   与代发不同：月份键（YYYYMM）就嵌在每个元素里，无独立月份序列列。
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_gs_tax_sales_info 段）：
--   taxPeriod        <- 月份键 YYYYMM（源元素前 6 位）
--   monthlyTaxSales  <- 当月纳税销售额（万元，源元素 : 后金额，VARCHAR->DECIMAL(18,2)）
--   totalSalesTax    <- 当年 1 月→该月 累计（万元，缺失/空月按 0 计）
--   yoyChange        <- 当年YTD(该月) − 上年同期YTD（上年「1月→同月」窗口内已有月份之和，缺失月补 0；
--                       窗口内一条都没有时置 NULL）
--   yoyRate          <- yoyChange ÷ 上年同期YTD × 100（%）；上年同期YTD 为 0 或无数据时置 NULL（防除 0）
--
-- 取值口径（已与产品确认）：
--   · 输出范围：仅「当前年」（= 数组中最大年份）的月份；上年月份只作同比参考，不出行
--   · YTD 累计：当年 1 月→该月逐月累加，该年缺失或金额为空的月按 0 计
--   · 只输出「有值月」：该月金额非空才出行（但空月在 YTD 中按 0 参与累计）
--
-- 处理规则（对齐 xd_payroll.sql / xd_settle_asset.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_gs_tax_sales_info 本次范围旧行，再插入
--   2. 取最新一个 dt：append-only，按 (reportNo, customerId) 内 ROW_NUMBER() ORDER BY (dt 是否空) 升序、
--      dt DESC、inputtime DESC、id DESC 取 rn=1（最新 dt 一行）
--   3. 按 | 拆分：CROSS JOIN 序号 1..60（SPLIT_PART 超序返回空串，过滤；覆盖 800 字上限内的元素数），
--      每元素 SPLIT_PART(':',1)=月份键 YYYYMM、SPLIT_PART(':',2)=金额
--   4. 窗口算累计：SUM(amt) OVER (PARTITION reportNo,customerId,年 ORDER 月) 得当年 YTD（1 月起）；
--      左连接「上年」同窗口累计（p 年=当前年-1、同月，窗口=上年 1 月→同月）得上年同期 YTD；
--      MAX(hasData) 标记上年同期窗口是否有任何数据（窗口内全空 -> yoyChange/yoyRate 置 NULL）
--   5. CAST：金额/累计 VARCHAR->DECIMAL(18,2)；同比 DECIMAL(12,4)；空金额置 0 参与累计、置 NULL 不参与出行
-- =====================================================================

-- 1. 幂等
DELETE FROM app_gs_tax_sales_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 国税销售额：取最新 dt 一行 -> 按 | 拆 (月份,金额) -> 窗口算当年 YTD + 上年同期 YTD -> app_gs_tax_sales_info
INSERT INTO app_gs_tax_sales_info (
    reportNo, customerId, customerName, taxPeriod, monthlyTaxSales, totalSalesTax, yoyChange, yoyRate
)
SELECT
    x.reportNo,
    x.customerId,
    x.customerName,
    x.taxPeriod,
    x.monthlyTaxSales,
    x.totalSalesTax,
    x.yoyChange,
    x.yoyRate
FROM (
    SELECT
        r.reportNo,
        r.customerId,
        r.customerName,
        r.mkey                    AS taxPeriod,
        r.amt                     AS monthlyTaxSales,
        r.ytd                     AS totalSalesTax,
        CASE WHEN p.hasData = 1 THEN r.ytd - p.ytd END AS yoyChange,
        CAST(CASE WHEN COALESCE(p.ytd, 0) = 0 THEN NULL ELSE (r.ytd - p.ytd) / p.ytd * 100 END AS DECIMAL(12,4)) AS yoyRate,
        ROW_NUMBER() OVER (PARTITION BY r.reportNo, COALESCE(r.customerId, ''), r.yr, r.mon ORDER BY p.mon DESC) AS prn
    FROM (
    -- r：当月 + 当年 YTD + 当前年标记（窗口）
    SELECT
        e.reportNo, e.customerId, e.customerName, e.mkey, e.yr, e.mon, e.amt, e.hasVal,
        SUM(e.amt) OVER (PARTITION BY e.reportNo, e.customerId, e.yr ORDER BY e.mon) AS ytd,
        MAX(e.yr)  OVER (PARTITION BY e.reportNo, e.customerId)                     AS curYr
    FROM (
        -- e：拆元素（yr/mon 数值化、amt 空=0、hasval 标记有值月）
        SELECT
            reportNo, customerId, customerName,
            elkey                                          AS mkey,
            CAST(SUBSTRING(elkey, 1, 4) AS INTEGER)         AS yr,
            CAST(SUBSTRING(elkey, 5, 2) AS INTEGER)         AS mon,
            CAST(CASE WHEN elval IS NULL OR elval = '' THEN '0' ELSE elval END AS DECIMAL(18,2)) AS amt,
            CASE WHEN elval IS NULL OR elval = '' THEN 0 ELSE 1 END AS hasVal
        FROM (
            SELECT reportNo, customerId, customerName,
                   SPLIT_PART(SPLIT_PART(mon_sale_amt, '|', n.n), ':', 1) AS elkey,
                   SPLIT_PART(SPLIT_PART(mon_sale_amt, '|', n.n), ':', 2) AS elval
            FROM (
                SELECT reportNo, customerId, customerName, mon_sale_amt,
                       ROW_NUMBER() OVER (
                           PARTITION BY reportNo, COALESCE(customerId, '')
                           ORDER BY CASE WHEN dt IS NULL THEN 1 ELSE 0 END ASC,
                                    dt DESC, inputtime DESC, id DESC
                       ) AS rn
                FROM dfs_crdt_loan_cust_rel
                WHERE reportNo IS NOT NULL
                  AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
            ) b
            CROSS JOIN (
                SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
                UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
                UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
                UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
                UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25
                UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30
                UNION ALL SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35
                UNION ALL SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40
                UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44 UNION ALL SELECT 45
                UNION ALL SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49 UNION ALL SELECT 50
                UNION ALL SELECT 51 UNION ALL SELECT 52 UNION ALL SELECT 53 UNION ALL SELECT 54 UNION ALL SELECT 55
                UNION ALL SELECT 56 UNION ALL SELECT 57 UNION ALL SELECT 58 UNION ALL SELECT 59 UNION ALL SELECT 60
                UNION ALL SELECT 61 UNION ALL SELECT 62 UNION ALL SELECT 63 UNION ALL SELECT 64 UNION ALL SELECT 65
                UNION ALL SELECT 66 UNION ALL SELECT 67 UNION ALL SELECT 68 UNION ALL SELECT 69 UNION ALL SELECT 70
                UNION ALL SELECT 71 UNION ALL SELECT 72 UNION ALL SELECT 73 UNION ALL SELECT 74 UNION ALL SELECT 75
                UNION ALL SELECT 76 UNION ALL SELECT 77 UNION ALL SELECT 78 UNION ALL SELECT 79 UNION ALL SELECT 80
            ) n
            WHERE b.rn = 1
              AND SPLIT_PART(mon_sale_amt, '|', n.n) IS NOT NULL
              AND SPLIT_PART(mon_sale_amt, '|', n.n) <> ''
        ) z
        WHERE z.elkey IS NOT NULL AND z.elkey <> ''
    ) e
) r
LEFT JOIN (
    -- p：上年同期 YTD（年=当前年-1、月≤同月的上年行，窗口累计 1 月→该月；hasData=窗口内是否有数据；
    --    外层按 p.mon DESC 取 rn=1 行 = 上年窗口内最新月的累计行；JOIN 不上（上年无数据）则 ytd/hasData 全 NULL）
    SELECT
        e2.reportNo, e2.customerId, e2.yr, e2.mon,
        SUM(e2.amt) OVER (PARTITION BY e2.reportNo, e2.customerId, e2.yr ORDER BY e2.mon) AS ytd,
        MAX(e2.hasData) OVER (PARTITION BY e2.reportNo, e2.customerId, e2.yr ORDER BY e2.mon) AS hasData
    FROM (
        SELECT
            reportNo, customerId,
            CAST(SUBSTRING(elkey, 1, 4) AS INTEGER) AS yr,
            CAST(SUBSTRING(elkey, 5, 2) AS INTEGER) AS mon,
            CAST(CASE WHEN elval IS NULL OR elval = '' THEN '0' ELSE elval END AS DECIMAL(18,2)) AS amt,
            CASE WHEN elval IS NULL OR elval = '' THEN 0 ELSE 1 END AS hasData
        FROM (
            SELECT reportNo, customerId,
                   SPLIT_PART(SPLIT_PART(mon_sale_amt, '|', n.n), ':', 1) AS elkey,
                   SPLIT_PART(SPLIT_PART(mon_sale_amt, '|', n.n), ':', 2) AS elval
            FROM (
                SELECT reportNo, customerId, mon_sale_amt,
                       ROW_NUMBER() OVER (
                           PARTITION BY reportNo, COALESCE(customerId, '')
                           ORDER BY CASE WHEN dt IS NULL THEN 1 ELSE 0 END ASC,
                                    dt DESC, inputtime DESC, id DESC
                       ) AS rn
                FROM dfs_crdt_loan_cust_rel
                WHERE reportNo IS NOT NULL
                  AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
            ) b2
            CROSS JOIN (
                SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
                UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
                UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
                UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
                UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25
                UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30
                UNION ALL SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35
                UNION ALL SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40
                UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44 UNION ALL SELECT 45
                UNION ALL SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49 UNION ALL SELECT 50
                UNION ALL SELECT 51 UNION ALL SELECT 52 UNION ALL SELECT 53 UNION ALL SELECT 54 UNION ALL SELECT 55
                UNION ALL SELECT 56 UNION ALL SELECT 57 UNION ALL SELECT 58 UNION ALL SELECT 59 UNION ALL SELECT 60
                UNION ALL SELECT 61 UNION ALL SELECT 62 UNION ALL SELECT 63 UNION ALL SELECT 64 UNION ALL SELECT 65
                UNION ALL SELECT 66 UNION ALL SELECT 67 UNION ALL SELECT 68 UNION ALL SELECT 69 UNION ALL SELECT 70
                UNION ALL SELECT 71 UNION ALL SELECT 72 UNION ALL SELECT 73 UNION ALL SELECT 74 UNION ALL SELECT 75
                UNION ALL SELECT 76 UNION ALL SELECT 77 UNION ALL SELECT 78 UNION ALL SELECT 79 UNION ALL SELECT 80
            ) n
            WHERE b2.rn = 1
              AND SPLIT_PART(mon_sale_amt, '|', n.n) IS NOT NULL
              AND SPLIT_PART(mon_sale_amt, '|', n.n) <> ''
        ) z2
        WHERE z2.elkey IS NOT NULL AND z2.elkey <> ''
    ) e2
  ) p ON p.reportNo = r.reportNo
      AND p.customerId = r.customerId
      AND p.yr = r.yr - 1
      AND p.mon <= r.mon
    WHERE r.hasVal = 1
  ) x
WHERE x.prn = 1
ORDER BY x.taxPeriod;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_guofa_report_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_guofa.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 国发征信 · 源头表 -> app_guofa_report_info 加工
-- 节点：客户国家级发展信息查询接口（custNationalDevelopmentQry，CrcsCustNationalDevelopmentService.query）
-- 源表（主档 + 三子表，mainId -> gfzx_national_dev.id）：
--   gfzx_national_dev           主档（报表期次表头 c_*/n_*/o_*，各含 前年/去年/去年同期/今年同期 四期）
--   gfzx_profit_sheet_item      利润表明细（n_cn_name 科目 + 四期金额）
--   gfzx_balance_sheet_item     资产负债表明细（c_cn_name 科目 + 四期余额）
--   gfzx_finance_index_item     主要财务指标明细（本表不取，预留）
-- 目标：app_guofa_report_info（一报告一行，业务主键 reportNo + customerId）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_guofa_report_info 段）：
--   dataDate      <- 主档 inputtime（CAST(inputtime AS CHAR(32))；源未落 dataDate 列，暂用入库时间近似）
--   beforeYear    <- 主档 c_beforeYear          前年期次（LEFT 32）
--   lastYear      <- 主档 c_lastYear            去年期次（LEFT 32）
--   thisYear      <- 主档 c_samePeriodThisYear  最新一期期次（LEFT 32）
--   gfRevenue         <- 利润表 n_cn_name='营业收入'  n_current_qmye（最近一期）
--   lastYearRevenue   <- 同上 n_last_qmye
--   beforeYearRevenue <- 同上 n_before_last_qmye
--   gfReceivable/gfPayable/gfInventory <- 资产负债表 c_cn_name='应收账款'/'应付账款'/'存货' 的 c_*_qmye
--   （各 before/last 同理取该科目 c_before_last_qmye / c_last_qmye）
--   数值列源 VARCHAR -> app DECIMAL(18,2)：REGEXP 数字守卫 + CAST（非数字/空串 -> NULL，防 GaussDB 严格模式 CAST 报错）
--   科目中文名待信贷确认精确码值，暂按 '营业收入'/'应收账款'/'应付账款'/'存货' 精确匹配；撞不到该组为 NULL
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_guofa_report_info 本次范围旧行，再插入
--   2. 源头 append-only：主档按 reportNo ROW_NUMBER 取最新（inputtime DESC, id DESC）作为「当前主档」，
--      子表按 (mainId) ROW_NUMBER 取最新后 JOIN 当前主档 id，排除历史快照
--   3. 一报告一行：主档为基行，四组指标各 LEFT JOIN（撞不到为 NULL）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_guofa_report_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 国发征信：主档（期次表头）+ 利润表营业收入 + 资产负债表应收/应付/存货 -> app_guofa_report_info
INSERT INTO app_guofa_report_info (
    reportNo, customerId, customerName, dataDate, beforeYear, lastYear, thisYear,
    gfRevenue, lastYearRevenue, beforeYearRevenue,
    gfReceivable, lastYearReceivable, beforeYearReceivable,
    gfPayable, lastYearPayable, beforeYearPayable,
    gfInventory, lastYearInventory, beforeYearInventory
)
SELECT
    b.reportNo, b.customerId, b.customerName, b.dataDate, b.beforeYear, b.lastYear, b.thisYear,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(r.n_current_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(r.n_current_qmye) END AS DECIMAL(18,2)) AS gfRevenue,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(r.n_last_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(r.n_last_qmye) END AS DECIMAL(18,2)) AS lastYearRevenue,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(r.n_before_last_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(r.n_before_last_qmye) END AS DECIMAL(18,2)) AS beforeYearRevenue,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(ar.c_current_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(ar.c_current_qmye) END AS DECIMAL(18,2)) AS gfReceivable,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(ar.c_last_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(ar.c_last_qmye) END AS DECIMAL(18,2)) AS lastYearReceivable,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(ar.c_before_last_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(ar.c_before_last_qmye) END AS DECIMAL(18,2)) AS beforeYearReceivable,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(ap.c_current_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(ap.c_current_qmye) END AS DECIMAL(18,2)) AS gfPayable,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(ap.c_last_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(ap.c_last_qmye) END AS DECIMAL(18,2)) AS lastYearPayable,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(ap.c_before_last_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(ap.c_before_last_qmye) END AS DECIMAL(18,2)) AS beforeYearPayable,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(inv.c_current_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(inv.c_current_qmye) END AS DECIMAL(18,2)) AS gfInventory,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(inv.c_last_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(inv.c_last_qmye) END AS DECIMAL(18,2)) AS lastYearInventory,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(inv.c_before_last_qmye), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(inv.c_before_last_qmye) END AS DECIMAL(18,2)) AS beforeYearInventory
FROM (
    -- 当前主档（报表期次表头，取最新一期）
    SELECT id, reportNo, customerId, customerName,
            -- inputtime DATETIME -> yyyyMMdd（前 10 位日期段去横线；源无独立 dataDate 列，用主档落表时间近似）
            CASE WHEN REGEXP_LIKE(SUBSTR(CAST(inputtime AS CHAR(32)), 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
                 THEN REPLACE(REPLACE(SUBSTR(CAST(inputtime AS CHAR(32)), 1, 10), '-', ''), '/', '')
                 ELSE CAST(inputtime AS CHAR(32)) END AS dataDate,
           LEFT(c_beforeYear, 32)         AS beforeYear,
           LEFT(c_lastYear, 32)           AS lastYear,
           LEFT(c_samePeriodThisYear, 32) AS thisYear
    FROM (
        SELECT id, reportNo, customerId, customerName, inputtime,
               c_beforeYear, c_lastYear, c_samePeriodThisYear,
               ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
        FROM gfzx_national_dev
        WHERE reportNo IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) mc WHERE mc.rn = 1
) b
LEFT JOIN (
    -- 利润表：营业收入（当前主档下取最新一行）
    SELECT mainId, n_current_qmye, n_last_qmye, n_before_last_qmye,
           ROW_NUMBER() OVER (PARTITION BY mainId ORDER BY inputtime DESC, id DESC) AS rn
    FROM gfzx_profit_sheet_item
    WHERE n_cn_name = '营业收入'
) r ON r.mainId = b.id AND r.rn = 1
LEFT JOIN (
    -- 资产负债表：应收账款
    SELECT mainId, c_current_qmye, c_last_qmye, c_before_last_qmye,
           ROW_NUMBER() OVER (PARTITION BY mainId ORDER BY inputtime DESC, id DESC) AS rn
    FROM gfzx_balance_sheet_item
    WHERE c_cn_name = '应收账款'
) ar ON ar.mainId = b.id AND ar.rn = 1
LEFT JOIN (
    -- 资产负债表：应付账款
    SELECT mainId, c_current_qmye, c_last_qmye, c_before_last_qmye,
           ROW_NUMBER() OVER (PARTITION BY mainId ORDER BY inputtime DESC, id DESC) AS rn
    FROM gfzx_balance_sheet_item
    WHERE c_cn_name = '应付账款'
) ap ON ap.mainId = b.id AND ap.rn = 1
LEFT JOIN (
    -- 资产负债表：存货
    SELECT mainId, c_current_qmye, c_last_qmye, c_before_last_qmye,
           ROW_NUMBER() OVER (PARTITION BY mainId ORDER BY inputtime DESC, id DESC) AS rn
    FROM gfzx_balance_sheet_item
    WHERE c_cn_name = '存货'
) inv ON inv.mainId = b.id AND inv.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_payroll_stat_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_payroll.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 结算》代发业务情况 · 源头表 -> app_payroll_stat_info 加工
-- 节点：数据融合平台 dfsDataQry》信贷客户关联信息
--       （adm_stas_plma_crdt_loan_cust_rel_info，DfsDataQryService.queryCrdtLoanCustRelInfo 落表）
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（财税/财报/账户/代发等经营字段，append-only）
-- 目标：app_payroll_stat_info（代发统计表·月粒度，业务主键 reportNo + customerId + statMonth，一月份一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；字符串拼接用 CONCAT 不用 ||，定位用 strpos 不用 INSTR）
--
-- 源头字段格式（7 列各存 12 个月，| 分隔；依据中台样例）：
--   instd_sal_moly            代发统计月份   202509|202510|...|202608            （纯月份键，无值）
--   instd_sal_person_moly     每月代发人数   202509:127|202510:126|...|202608:105
--   instd_sal_amt_moly        每月代发金额   202509:519472.24|202510:514970.15|...
--   instd_sal_person_moly_hb  每月代发人数环比 202509:-0.0305|202510:-0.0079|...  （稀疏：缺失月份整段不出现）
--   instd_sal_amt_moly_hb     每月代发金额环比 202509:-0.0205|...
--   instd_sal_person_moly_tb  每月代发人数同比 202509:-0.1911|...                  （稀疏）
--   instd_sal_amt_moly_tb     每月代发金额同比 202509:-0.1457|...
-- 注意：环比/同比串是「稀疏」的（某月缺数据则整段不出现，元素数 < 月份数），故各指标值必须
--       「按月份键精确匹配」取值，不能按 | 位置对齐（否则缺失月份会导致后续值整体错位）。
--
-- 处理规则（对齐 xd_capital_flow.sql / xd_warning_signal.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_payroll_stat_info 本次范围旧行，再插入
--   2. 取最新一个 dt：dfs_crdt_loan_cust_rel 为 append-only，按 (reportNo, customerId) 内
--      ROW_NUMBER() ORDER BY (dt 是否空) 升序、dt DESC、inputtime DESC、id DESC 取 rn=1（最新 dt 一行）
--   3. 按月份拆分：以 instd_sal_moly（12 个月键，顺序即时间序）为驱动，CROSS JOIN 序号 1..12，
--      SPLIT_PART(instd_sal_moly,'|',n) 取第 n 个月份键；超过实际月份数的序号返回空串，过滤掉
--   4. 各指标值按「月份键」从对应串中抽取：SPLIT_PART(str, '月份键:', 2) 取键后剩余，
--      再 SPLIT_PART(..., '|', 1) 截到下一元素；该月在某串中不存在（strpos=0）则置 NULL。
--      ⚠ 不能用 strpos 动态起点 SUBSTRING：openGauss 把其返回类型推导为 character(0)，
--        运行时报 "value too long for type character(0)"（SPLIT_PART 返回 text，不受影响）。
--   5. CAST：代发人数 VARCHAR->SIGNED(INT)；代发金额 VARCHAR->DECIMAL(18,2)；
--      环比/同比 源值为小数比率(0.01=1%)，app 层单位为 %，加工层 ×100，VARCHAR->DECIMAL(12,4)。
--      缺失月份由 CASE 置 NULL（对齐「非数字/空 -> NULL」，
--      dense 列的当月值由上游保证为数字串，同 xd_financial.sql 硬 cast 口径）
--   6. statMonth 存月份键原值（YYYYMM，如 202509），展示层按需转格式
-- =====================================================================

-- 1. 幂等
DELETE FROM app_payroll_stat_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 代发统计：取最新 dt 一行 -> 按月份拆 12 行 -> 各指标按月份键取值 -> app_payroll_stat_info
INSERT INTO app_payroll_stat_info (
    reportNo, customerId, customerName, statMonth,
    payrollCount, payrollAmount, countMom, amountMom, countYoy, amountYoy
)
SELECT
    y.reportNo,
    y.customerId,
    y.customerName,
    y.month AS statMonth,
    -- 代发人数（instd_sal_person_moly，每月代发人数）
    CAST(
        CASE
            WHEN y.month IS NULL OR y.month = '' THEN NULL
            WHEN y.p_moly IS NULL OR y.p_moly = '|' THEN NULL
            WHEN strpos(y.p_moly, CONCAT(y.month, ':')) = 0 THEN NULL
            ELSE SPLIT_PART(SPLIT_PART(REPLACE(y.p_moly, CONCAT(y.month, ':'), 'M:'), 'M:', 2), '|', 1)
        END
    AS INTEGER) AS payrollCount,
    -- 代发金额（万元）（instd_sal_amt_moly，每月代发金额）
    CAST(
        CASE
            WHEN y.month IS NULL OR y.month = '' THEN NULL
            WHEN y.a_moly IS NULL OR y.a_moly = '|' THEN NULL
            WHEN strpos(y.a_moly, CONCAT(y.month, ':')) = 0 THEN NULL
            ELSE SPLIT_PART(SPLIT_PART(REPLACE(y.a_moly, CONCAT(y.month, ':'), 'M:'), 'M:', 2), '|', 1)
        END
    AS DECIMAL(18,2)) AS payrollAmount,
    -- 代发人数环比（instd_sal_person_moly_hb，稀疏；源为小数比率，×100 转 %）
    CAST(
        CASE
            WHEN y.month IS NULL OR y.month = '' THEN NULL
            WHEN y.p_hb IS NULL OR y.p_hb = '|' THEN NULL
            WHEN strpos(y.p_hb, CONCAT(y.month, ':')) = 0 THEN NULL
            ELSE CAST(SPLIT_PART(SPLIT_PART(REPLACE(y.p_hb, CONCAT(y.month, ':'), 'M:'), 'M:', 2), '|', 1) AS DECIMAL(12,4))*100
        END
    AS DECIMAL(12,4)) AS countMom,
    -- 代发金额环比（instd_sal_amt_moly_hb，稀疏；源为小数比率，×100 转 %）
    CAST(
        CASE
            WHEN y.month IS NULL OR y.month = '' THEN NULL
            WHEN y.a_hb IS NULL OR y.a_hb = '|' THEN NULL
            WHEN strpos(y.a_hb, CONCAT(y.month, ':')) = 0 THEN NULL
            ELSE CAST(SPLIT_PART(SPLIT_PART(REPLACE(y.a_hb, CONCAT(y.month, ':'), 'M:'), 'M:', 2), '|', 1) AS DECIMAL(12,4))*100
        END
    AS DECIMAL(12,4)) AS amountMom,
    -- 代发人数同比（instd_sal_person_moly_tb，稀疏；源为小数比率，×100 转 %）
    CAST(
        CASE
            WHEN y.month IS NULL OR y.month = '' THEN NULL
            WHEN y.p_tb IS NULL OR y.p_tb = '|' THEN NULL
            WHEN strpos(y.p_tb, CONCAT(y.month, ':')) = 0 THEN NULL
            ELSE CAST(SPLIT_PART(SPLIT_PART(REPLACE(y.p_tb, CONCAT(y.month, ':'), 'M:'), 'M:', 2), '|', 1) AS DECIMAL(12,4))*100
        END
    AS DECIMAL(12,4)) AS countYoy,
    -- 代发金额同比（instd_sal_amt_moly_tb，稀疏；源为小数比率，×100 转 %）
    CAST(
        CASE
            WHEN y.month IS NULL OR y.month = '' THEN NULL
            WHEN y.a_tb IS NULL OR y.a_tb = '|' THEN NULL
            WHEN strpos(y.a_tb, CONCAT(y.month, ':')) = 0 THEN NULL
            ELSE CAST(SPLIT_PART(SPLIT_PART(REPLACE(y.a_tb, CONCAT(y.month, ':'), 'M:'), 'M:', 2), '|', 1) AS DECIMAL(12,4))*100
        END
    AS DECIMAL(12,4)) AS amountYoy
FROM (
    -- y：最新 dt 一行 CROSS JOIN 序号 1..12，拆出每行对应「月份键 + 6 个串尾补 | 的指标串」
    SELECT
        b.reportNo,
        b.customerId,
        b.customerName,
        SPLIT_PART(b.instd_sal_moly, '|', n.n)      AS month,
        CONCAT(b.instd_sal_person_moly, '|')        AS p_moly,
        CONCAT(b.instd_sal_amt_moly, '|')           AS a_moly,
        CONCAT(b.instd_sal_person_moly_hb, '|')     AS p_hb,
        CONCAT(b.instd_sal_amt_moly_hb, '|')        AS a_hb,
        CONCAT(b.instd_sal_person_moly_tb, '|')     AS p_tb,
        CONCAT(b.instd_sal_amt_moly_tb, '|')        AS a_tb
    FROM (
        -- base：按 (reportNo, customerId) 取最新 dt 一行（append-only 去重）
        SELECT
            reportNo, customerId, customerName,
            instd_sal_moly, instd_sal_person_moly, instd_sal_amt_moly,
            instd_sal_person_moly_hb, instd_sal_amt_moly_hb,
            instd_sal_person_moly_tb, instd_sal_amt_moly_tb,
            ROW_NUMBER() OVER (
                PARTITION BY reportNo, COALESCE(customerId, '')
                ORDER BY CASE WHEN dt IS NULL THEN 1 ELSE 0 END ASC,
                         dt DESC, inputtime DESC, id DESC
            ) AS rn
        FROM dfs_crdt_loan_cust_rel
        WHERE reportNo IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) b
    CROSS JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
    ) n
    WHERE b.rn = 1
      AND SPLIT_PART(b.instd_sal_moly, '|', n.n) IS NOT NULL
      AND SPLIT_PART(b.instd_sal_moly, '|', n.n) <> ''
) y
ORDER BY y.month;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_reputation_event_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_settle_account_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_settle_account.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 结算》结算账户 · 源头表 -> app_settle_account_info 加工
-- 节点：数据融合平台 dfsDataQry》信贷客户关联信息
--       （adm_stas_plma_crdt_loan_cust_rel_info，DfsDataQryService.queryCrdtLoanCustRelInfo 落表）
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（结算/代发等经营字段，append-only）
-- 目标：app_settle_account_info（结算账户表，业务主键 reportNo + customerId + accountNo，一个账户一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；字符串拼接用 CONCAT 不用 ||，取段用 SPLIT_PART）
--
-- 源头字段格式（acct_zhxx，依据中台真实样例）：
--   账户之间用 | 分隔；每个账户内部用 ; 分隔固定 10 段：
--     段1  账号         -> accountNo
--     段2  账户状态      -> accountStatus（码值待确认，原样透传）
--     段3  账户余额      -> accountBalance（万元，VARCHAR->DECIMAL(18,2)）
--     段4  开户机构      （暂不入 app）
--     段5  监管标识      -> superviseFlag（码值待确认，原样透传）
--     段6~段10 长账号串/其他 （暂不入 app）
--   样例（2 账户 = 段1..10 | 段1..10）：
--     51473600001173;N;24414.77;706660112;O;7066601071210000095320;N;203129.12;706660107;0|51473600001174;...
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_settle_account_info 段，全部「原始」）：
--   accountNo       <- acct_zhxx 账户段1  账号
--   accountStatus   <- acct_zhxx 账户段2  账户状态（码值：N/Y 等，待确认，原样透传）
--   accountBalance  <- acct_zhxx 账户段3  账户余额（万元）
--   superviseFlag   <- acct_zhxx 账户段5  监管标识（码值：O/N 等，待确认，原样透传）
--
-- 处理规则（对齐 xd_payroll.sql / xd_settle_counterparty.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_settle_account_info 本次范围旧行，再插入
--   2. 取最新一个 dt：dfs_crdt_loan_cust_rel 为 append-only，按 (reportNo, customerId) 内
--      ROW_NUMBER() ORDER BY (dt 是否空) 升序、dt DESC、inputtime DESC、id DESC 取 rn=1（最新 dt 一行）
--   3. 按账户拆分：CROSS JOIN 账户序号 1..50，SPLIT_PART(acct_zhxx, '|', n) 取第 n 个账户串
--      （超序返回空串，过滤）；账户串内再 SPLIT_PART(acct, ';', k) 取段1/2/3/5；
--      以「段1 账号非空」判定该账户存在，空账户过滤掉（尾段截断账户保留为一条空值行）
--   4. CAST：账户余额 VARCHAR->DECIMAL(18,2)，空段置 NULL（防截断账户误 cast）；
--      账号/状态/监管 VARCHAR LEFT 截断 64 防越界
--   5. 账户数 > 50 的客户仅取前 50 个（结算账户表实际账户数远小于此，作兜底上限）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_settle_account_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 结算账户：取最新 dt 一行 -> 按 | 拆账户(1..50) -> 账户内按 ; 取段1/2/3/5 -> app_settle_account_info
INSERT INTO app_settle_account_info (
    reportNo, customerId, customerName, accountNo, accountStatus, accountBalance, superviseFlag
)
SELECT
    x.reportNo,
    x.customerId,
    x.customerName,
    LEFT(x.seg_no, 64)     AS accountNo,
    LEFT(x.seg_status, 64) AS accountStatus,
    CAST(CASE WHEN x.seg_bal IS NULL OR x.seg_bal = '' THEN NULL ELSE x.seg_bal END AS DECIMAL(18,2)) AS accountBalance,
    LEFT(x.seg_sup, 64)    AS superviseFlag
FROM (
    SELECT
        a.reportNo, a.customerId, a.customerName,
        SPLIT_PART(a.acct, ';', 1) AS seg_no,
        SPLIT_PART(a.acct, ';', 2) AS seg_status,
        SPLIT_PART(a.acct, ';', 3) AS seg_bal,
        SPLIT_PART(a.acct, ';', 5) AS seg_sup
    FROM (
        SELECT reportNo, customerId, customerName,
               SPLIT_PART(acct_zhxx, '|', n.n) AS acct
        FROM (
            SELECT reportNo, customerId, customerName, acct_zhxx,
                   ROW_NUMBER() OVER (
                       PARTITION BY reportNo, COALESCE(customerId, '')
                       ORDER BY CASE WHEN dt IS NULL THEN 1 ELSE 0 END ASC,
                                dt DESC, inputtime DESC, id DESC
                   ) AS rn
            FROM dfs_crdt_loan_cust_rel
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) b
        CROSS JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
            UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
            UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
            UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25
            UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30
            UNION ALL SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35
            UNION ALL SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40
            UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44 UNION ALL SELECT 45
            UNION ALL SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49 UNION ALL SELECT 50
            UNION ALL SELECT 51 UNION ALL SELECT 52 UNION ALL SELECT 53 UNION ALL SELECT 54 UNION ALL SELECT 55
            UNION ALL SELECT 56 UNION ALL SELECT 57 UNION ALL SELECT 58 UNION ALL SELECT 59 UNION ALL SELECT 60
            UNION ALL SELECT 61 UNION ALL SELECT 62 UNION ALL SELECT 63 UNION ALL SELECT 64 UNION ALL SELECT 65
            UNION ALL SELECT 66 UNION ALL SELECT 67 UNION ALL SELECT 68 UNION ALL SELECT 69 UNION ALL SELECT 70
            UNION ALL SELECT 71 UNION ALL SELECT 72 UNION ALL SELECT 73 UNION ALL SELECT 74 UNION ALL SELECT 75
            UNION ALL SELECT 76 UNION ALL SELECT 77 UNION ALL SELECT 78 UNION ALL SELECT 79 UNION ALL SELECT 80
            UNION ALL SELECT 81 UNION ALL SELECT 82 UNION ALL SELECT 83 UNION ALL SELECT 84 UNION ALL SELECT 85
            UNION ALL SELECT 86 UNION ALL SELECT 87 UNION ALL SELECT 88 UNION ALL SELECT 89 UNION ALL SELECT 90
            UNION ALL SELECT 91 UNION ALL SELECT 92 UNION ALL SELECT 93 UNION ALL SELECT 94 UNION ALL SELECT 95
            UNION ALL SELECT 96 UNION ALL SELECT 97 UNION ALL SELECT 98 UNION ALL SELECT 99 UNION ALL SELECT 100
        ) n
        WHERE b.rn = 1
          AND SPLIT_PART(b.acct_zhxx, '|', n.n) IS NOT NULL
          AND SPLIT_PART(b.acct_zhxx, '|', n.n) <> ''
    ) a
    WHERE SPLIT_PART(a.acct, ';', 1) IS NOT NULL
      AND SPLIT_PART(a.acct, ';', 1) <> ''
) x;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_settle_asset_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_settle_asset.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 结算》结算资产 · 源头表 -> app_settle_asset_info 加工
-- 节点：数据融合平台 dfsDataQry》信贷客户关联信息
--       （adm_stas_plma_crdt_loan_cust_rel_info，DfsDataQryService.queryCrdtLoanCustRelInfo 落表）
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（结算/代发等经营字段，append-only）
-- 目标：app_settle_asset_info（结算资产表，业务主键 reportNo + customerId，一个客户一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；字符串拼接用 CONCAT 不用 ||，定位用 strpos）
--
-- 源头字段格式（依据中台真实样例）：
--   9 个拼接列（dep/物业×3/电费×3/关键字×2）均为「标签式」| 分隔，段内 标签:值：
--     当年:值|去年:值
--     dep_y_avg_bal      当年:2002618.09|去年:2877299.25
--     yr_pty_income      当年:2595957.13|去年:4153259.37
--     cr_acr_amt_1       去年:4005000            （段序不固定、段可缺失）
--   值里的 \N 表示空（置 NULL）。
--   取值必须「按标签找段」，不能用固定位置 SPLIT_PART（段序/段数不定）。
--
-- 标签取值实现（按标签找段，SPLIT_PART 两段、分隔符均为字面量常量）：
--     val(col, 标签) = CASE WHEN strpos(col,'标签:')=0 THEN CAST(NULL AS CHAR(200))
--                           ELSE SPLIT_PART(SPLIT_PART(col,'标签:',2), '|', 1) END
--   段1 取「标签:」之后的剩余（标签在串首时即段值|后续段），段2 再按 | 截第一段。
--   ⚠ 不能用 strpos 动态起点 SUBSTRING / 动态分隔符 SPLIT_PART：openGauss 会把其返回类型
--     推导为 character(0)，运行时报 "value too long for type character(0)"。
--   ⚠ NULL 分支必须显式带类型 CAST(NULL AS CHAR(200))：裸 NULL 与 SPLIT_PART 字符串分支混排
--     且外层无 CAST 目标类型时，openGauss 把 CASE 结果推导为 character(0)，运行时报
--     "value too long for type character(0)"（引用列即 v_dep_cur 等输出列）。
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_settle_asset_info 段；源列名以中台 DDL 实际为准）：
--   frozenAmount                     <- fzn_amt                  冻结金额（万元，单值，直接 CAST）
--   debitSameNameTransferRatio       <- hnym_tfrd_amt_dbt_pcnt   借方同名划转金额占比（%，单值，直接 CAST）
--   creditSameNameTransferRatio      <- hnym_tfrd_amt_cr_pcnt    贷方同名划转金额占比（%，单值，直接 CAST）
--   yearAvgDeposit                   <- dep_y_avg_bal   「当年」段      年日均存款（万元）
--   lastYearAvgDeposit               <- dep_y_avg_bal   「去年」段      上年年日均存款（万元）
--   propertyIncome                   <- yr_pty_income      「当年」段·1月规则   当年物业收入（万元）
--   propertyIncomeYoy                <- yr_pty_income_ch   「当年」段·1月规则   当年物业收入累计较上年同期（%，源为小数比率，×100）
--   propertyIncomeSupervised         <- yr_pty_income_regy 「当年」段·1月规则   当年监管账户物业收入（万元）
--   electricFeeIncome                <- elec_income        「当年」段·1月规则   当年电费收入（万元）
--   electricFeeYoy                   <- elec_income_ch     「当年」段·1月规则   当年电费收入累计较上年同期（%，源为小数比率，×100）
--   electricFeeSupervised            <- elec_income_regy   「当年」段·1月规则   当年监管账户当年电费收入（万元）
--   keywordCounterpartyCreditAmount  <- cr_acr_amt_2       「当年」段·1月规则   交易对手关键字贷方发生额（万元）
--   keywordRemarkCreditAmount        <- cr_acr_amt_1       「当年」段·1月规则   备注关键字贷方发生额（万元）
--
-- 「1月规则」（字典：当前时间为1月时取上年值，否则取当年）：
--   适用 物业/电费/关键字 共 8 列（dep 两列固定取 当年/去年 段，不走此规则）。
--   实现：以「取最新 dt 那一行的 dt 月份」近似「当前时间」——dt(YYYYMMDD) 的 SUBSTRING(dt,5,2)='01' 则
--         取「去年」段，否则取「当年」段。dt 为空/非1月默认取当年。
--   ⚠ 该「当前时间」按数据分区键 dt 的月份近似；若口径应为「报告账期月」，把 selIdx 的判定换成报告月即可（一处改动）。
--
-- 处理规则（对齐 xd_payroll.sql / xd_settle_counterparty.sql / xd_settle_account.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_settle_asset_info 本次范围旧行，再插入
--   2. 取最新一个 dt：dfs_crdt_loan_cust_rel 为 append-only，按 (reportNo, customerId) 内
--      ROW_NUMBER() ORDER BY (dt 是否空) 升序、dt DESC、inputtime DESC、id DESC 取 rn=1（最新 dt 一行）
--   3. 标签列按标签取段；单值列直取。\N/空段/空串 置 NULL（防 CAST('') 报错中断脚本）
--   4. CAST：金额 VARCHAR->DECIMAL(18,2)；占比/同比 VARCHAR->DECIMAL(18,2)
--      （同比 propertyIncomeYoy/electricFeeYoy 源为小数比率(0.01=1%)，app 层单位 %，加工层 ×100）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_settle_asset_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 结算资产：取最新 dt 一行 -> 13 列（3 单值直取 + 2 dep 标签段 + 8 标签段·1月规则）-> app_settle_asset_info
INSERT INTO app_settle_asset_info (
    reportNo, customerId, customerName,
    frozenAmount, debitSameNameTransferRatio, creditSameNameTransferRatio,
    yearAvgDeposit, lastYearAvgDeposit,
    propertyIncome, propertyIncomeYoy, propertyIncomeSupervised,
    electricFeeIncome, electricFeeYoy, electricFeeSupervised,
    keywordCounterpartyCreditAmount, keywordRemarkCreditAmount
)
SELECT
    t.reportNo,
    t.customerId,
    t.customerName,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_fzn),      '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_fzn)      END AS DECIMAL(18,2)) AS frozenAmount,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_dbt),      '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_dbt)      END AS DECIMAL(5,2))  AS debitSameNameTransferRatio,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_cr),       '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_cr)       END AS DECIMAL(5,2))  AS creditSameNameTransferRatio,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_dep_cur),  '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_dep_cur)  END AS DECIMAL(18,2)) AS yearAvgDeposit,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_dep_last), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_dep_last) END AS DECIMAL(18,2)) AS lastYearAvgDeposit,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_pinc),     '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_pinc)     END AS DECIMAL(18,2)) AS propertyIncome,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_pinc_yoy), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_pinc_yoy) END AS DECIMAL(18,2)) AS propertyIncomeYoy,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_pinc_sup), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_pinc_sup) END AS DECIMAL(18,2)) AS propertyIncomeSupervised,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_einc),     '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_einc)     END AS DECIMAL(18,2)) AS electricFeeIncome,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_einc_yoy), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_einc_yoy) END AS DECIMAL(18,2)) AS electricFeeYoy,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_einc_sup), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_einc_sup) END AS DECIMAL(18,2)) AS electricFeeSupervised,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_kw_cp),    '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_kw_cp)    END AS DECIMAL(18,2)) AS keywordCounterpartyCreditAmount,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_kw_rk),    '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.v_kw_rk)    END AS DECIMAL(18,2)) AS keywordRemarkCreditAmount
FROM (
    SELECT m.*, ROW_NUMBER() OVER (
        PARTITION BY m.reportNo, COALESCE(m.customerId, '')
        ORDER BY CASE WHEN m.dt IS NULL THEN 1 ELSE 0 END ASC, m.dt DESC, m.inputtime DESC, m.id DESC
    ) AS rn
    FROM (
        -- m：标签列按标签取段（selIdx=1 取当年 / selIdx=2 取去年），单值列直取
        SELECT reportNo, customerId, customerName, dt, inputtime, id,
            fzn_amt                                    AS v_fzn,
            hnym_tfrd_amt_dbt_pcnt                     AS v_dbt,
            hnym_tfrd_amt_cr_pcnt                      AS v_cr,
            -- dep 固定：当年段 / 去年段（不走 1月规则）
            CASE WHEN strpos(dep_y_avg_bal, '当年:') = 0 THEN CAST(NULL AS CHAR(200))
                 ELSE SPLIT_PART(SPLIT_PART(dep_y_avg_bal, '当年:', 2), '|', 1) END AS v_dep_cur,
            CASE WHEN strpos(dep_y_avg_bal, '去年:') = 0 THEN CAST(NULL AS CHAR(200))
                 ELSE SPLIT_PART(SPLIT_PART(dep_y_avg_bal, '去年:', 2), '|', 1) END AS v_dep_last,
            -- 物业（1月规则）
            CASE WHEN selIdx = 2
                 THEN CASE WHEN strpos(yr_pty_income, '去年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(yr_pty_income, '去年:', 2), '|', 1) END
                 ELSE CASE WHEN strpos(yr_pty_income, '当年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(yr_pty_income, '当年:', 2), '|', 1) END END AS v_pinc,
            CASE WHEN selIdx = 2
                 THEN CASE WHEN strpos(yr_pty_income_ch, '去年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(yr_pty_income_ch, '去年:', 2), '|', 1) END
                 ELSE CASE WHEN strpos(yr_pty_income_ch, '当年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(yr_pty_income_ch, '当年:', 2), '|', 1) END END AS v_pinc_yoy,
            CASE WHEN selIdx = 2
                 THEN CASE WHEN strpos(yr_pty_income_regy, '去年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(yr_pty_income_regy, '去年:', 2), '|', 1) END
                 ELSE CASE WHEN strpos(yr_pty_income_regy, '当年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(yr_pty_income_regy, '当年:', 2), '|', 1) END END AS v_pinc_sup,
            -- 电费（1月规则）
            CASE WHEN selIdx = 2
                 THEN CASE WHEN strpos(elec_income, '去年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(elec_income, '去年:', 2), '|', 1) END
                 ELSE CASE WHEN strpos(elec_income, '当年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(elec_income, '当年:', 2), '|', 1) END END AS v_einc,
            CASE WHEN selIdx = 2
                 THEN CASE WHEN strpos(elec_income_ch, '去年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(elec_income_ch, '去年:', 2), '|', 1) END
                 ELSE CASE WHEN strpos(elec_income_ch, '当年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(elec_income_ch, '当年:', 2), '|', 1) END END AS v_einc_yoy,
            CASE WHEN selIdx = 2
                 THEN CASE WHEN strpos(elec_income_regy, '去年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(elec_income_regy, '去年:', 2), '|', 1) END
                 ELSE CASE WHEN strpos(elec_income_regy, '当年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(elec_income_regy, '当年:', 2), '|', 1) END END AS v_einc_sup,
            -- 关键字（1月规则）
            CASE WHEN selIdx = 2
                 THEN CASE WHEN strpos(cr_acr_amt_2, '去年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(cr_acr_amt_2, '去年:', 2), '|', 1) END
                 ELSE CASE WHEN strpos(cr_acr_amt_2, '当年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(cr_acr_amt_2, '当年:', 2), '|', 1) END END AS v_kw_cp,
            CASE WHEN selIdx = 2
                 THEN CASE WHEN strpos(cr_acr_amt_1, '去年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(cr_acr_amt_1, '去年:', 2), '|', 1) END
                 ELSE CASE WHEN strpos(cr_acr_amt_1, '当年:') = 0 THEN CAST(NULL AS CHAR(200))
                          ELSE SPLIT_PART(SPLIT_PART(cr_acr_amt_1, '当年:', 2), '|', 1) END END AS v_kw_rk
        FROM (
            -- s：算 selIdx（dt 月份='01' 取去年段，否则当年段；dt 空/非1月默认 当年）
            SELECT *, CASE WHEN SUBSTRING(dt, 5, 2) = '01' THEN 2 ELSE 1 END AS selIdx
            FROM dfs_crdt_loan_cust_rel
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) s
    ) m
) t
WHERE t.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_settle_counterparty_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_settle_counterparty.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 结算》结算交易对手 · 源头表 -> app_settle_counterparty_info 加工
-- 节点：数据融合平台 dfsDataQry》信贷客户关联信息
--       （adm_stas_plma_crdt_loan_cust_rel_info，DfsDataQryService.queryCrdtLoanCustRelInfo 落表）
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（结算/代发等经营字段，append-only）
-- 目标：app_settle_counterparty_info（结算交易对手表，业务主键 reportNo + customerId + direction + counterpartyName，
--       一个「方向 + 交易对手」一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；字符串拼接用 CONCAT 不用 ||，定位/取段用 SPLIT_PART）
--
-- 源头字段格式（2 列各存「前十大」交易对手，| 分隔；依据中台样例）：
--   dbt_cntpr_and_acr_amt   前十大借方：name:amt|name:amt|...   （如 昊中电缆:313500|待核预算:772472.6|昆山电缆:259071.5|...）
--   cr_cntpr_and_acr_amt    前十大贷方：name:amt|name:amt|...
-- 注意：源数组顺序并非按发生额排序（样例 313500 在前、772472.6 在后），rankNo 不能直接用数组位置，
--       必须「按方向分组、按发生额降序」计算（见下 DENSE_RANK）。
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_settle_counterparty_info 段）：
--   counterpartyName <- 交易对手名称（dbt 串 name 段 / cr 串 name 段）
--   direction        <- 方向（dbt 串=借方 / cr 串=贷方）
--   amount           <- 发生额（万元）（dbt 串 amt 段 / cr 串 amt 段，VARCHAR->DECIMAL(18,2)）
--   rankNo           <- 排名 TOP1-10（业务口径为「前十大」；按发生额降序、借方/贷方分开排；同额并列同号 DENSE_RANK，次位按名称保证确定性）
--   upstreamFlag / remark  字典标「删除/未执行」，不加工
--
-- 处理规则（对齐 xd_payroll.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_settle_counterparty_info 本次范围旧行，再插入
--   2. 取最新一个 dt：dfs_crdt_loan_cust_rel 为 append-only，按 (reportNo, customerId) 内
--      ROW_NUMBER() ORDER BY (dt 是否空) 升序、dt DESC、inputtime DESC、id DESC 取 rn=1（最新 dt 一行）
--   3. 按「方向 + 交易对手」拆分：UNION ALL 借方（dbt 串）/贷方（cr 串）两源，各 CROSS JOIN 序号 1..10，
--      SPLIT_PART 取第 n 个 name:amt 元素再按 ':' 拆 name / amt；超过实际个数的序号返回空串，过滤掉
--   4. 按发生额降序、借方/贷方分开算 rankNo：DENSE_RANK() OVER (PARTITION BY customerId, direction ORDER BY amount DESC, counterpartyName)
--      （customerId 入分组保证多客户同批加工时各客户排名互不串扰；正常按单客户调用时为空操作）
--      取 1..N；兜底上限 DENSE_RANK <= 20（源为「前十大」数组、每方向 <=10 个元素，20 为序号表上限，正常不触发）
--   5. CAST：发生额 VARCHAR->DECIMAL(18,2)。空/缺失元素由 SPLIT_PART 空串过滤（无数字 CAST 风险）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_settle_counterparty_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 结算交易对手：取最新 dt 一行 -> 借方/贷方各拆 1..10 -> 按发生额降序分方向算 rankNo -> app_settle_counterparty_info
INSERT INTO app_settle_counterparty_info (
    reportNo, customerId, customerName, counterpartyName, direction, amount, rankNo
)
SELECT
    r.reportNo,
    r.customerId,
    r.customerName,
    r.counterpartyName,
    r.direction,
    r.amount,
    CAST(r.dr AS CHAR(16)) AS rankNo
FROM (
    SELECT
        d.*,
        DENSE_RANK() OVER (PARTITION BY d.customerId, d.direction ORDER BY d.amount DESC, d.counterpartyName) AS dr
    FROM (
        -- d：按业务主键 (reportNo, customerId, counterpartyName, direction) 去重，保留发生额最大的一行
        SELECT
            s.reportNo, s.customerId, s.customerName, s.counterpartyName, s.direction, s.amount,
            ROW_NUMBER() OVER (
                PARTITION BY s.reportNo, COALESCE(s.customerId, ''), COALESCE(s.counterpartyName, ''), s.direction
                ORDER BY s.amount DESC
            ) AS dup_rn
        FROM (
            -- s：借方/贷方两源 UNION ALL，各按 1..10 拆出「方向 + 交易对手 + 发生额」
            SELECT
                b.reportNo, b.customerId, b.customerName,
                SPLIT_PART(b.e, ':', 1)                  AS counterpartyName,
                '借方'                                    AS direction,
                CAST(SPLIT_PART(b.e, ':', 2) AS DECIMAL(18,2)) AS amount
            FROM (
                SELECT reportNo, customerId, customerName,
                       SPLIT_PART(dbt_cntpr_and_acr_amt, '|', n.n) AS e
                FROM (
                    SELECT reportNo, customerId, customerName, dbt_cntpr_and_acr_amt,
                           ROW_NUMBER() OVER (
                               PARTITION BY reportNo, COALESCE(customerId, '')
                               ORDER BY CASE WHEN dt IS NULL THEN 1 ELSE 0 END ASC,
                                        dt DESC, inputtime DESC, id DESC
                           ) AS rn
                    FROM dfs_crdt_loan_cust_rel
                    WHERE reportNo IS NOT NULL
                      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
                ) x
                CROSS JOIN (
                    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
                    UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
                    UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
                ) n
                WHERE x.rn = 1
                  AND SPLIT_PART(x.dbt_cntpr_and_acr_amt, '|', n.n) IS NOT NULL
                  AND SPLIT_PART(x.dbt_cntpr_and_acr_amt, '|', n.n) <> ''
            ) b
            UNION ALL
            SELECT
                c.reportNo, c.customerId, c.customerName,
                SPLIT_PART(c.e, ':', 1)                  AS counterpartyName,
                '贷方'                                    AS direction,
                CAST(SPLIT_PART(c.e, ':', 2) AS DECIMAL(18,2)) AS amount
            FROM (
                SELECT reportNo, customerId, customerName,
                       SPLIT_PART(cr_cntpr_and_acr_amt, '|', n.n) AS e
                FROM (
                    SELECT reportNo, customerId, customerName, cr_cntpr_and_acr_amt,
                           ROW_NUMBER() OVER (
                               PARTITION BY reportNo, COALESCE(customerId, '')
                               ORDER BY CASE WHEN dt IS NULL THEN 1 ELSE 0 END ASC,
                                        dt DESC, inputtime DESC, id DESC
                           ) AS rn
                    FROM dfs_crdt_loan_cust_rel
                    WHERE reportNo IS NOT NULL
                      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
                ) y
                CROSS JOIN (
                    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
                    UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
                    UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
                ) n
                WHERE y.rn = 1
                  AND SPLIT_PART(y.cr_cntpr_and_acr_amt, '|', n.n) IS NOT NULL
                  AND SPLIT_PART(y.cr_cntpr_and_acr_amt, '|', n.n) <> ''
            ) c
        ) s
    ) d
    WHERE d.dup_rn = 1
) r
WHERE r.dr <= 20
ORDER BY r.direction, r.amount DESC;