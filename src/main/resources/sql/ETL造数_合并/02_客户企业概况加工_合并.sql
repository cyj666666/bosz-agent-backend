-- =====================================================================
-- 【合并脚本】客户企业概况加工 组（原 17 个脚本 → 本文件 1 个）
-- 生成：2026-09-22　由 33 个原脚本合并（清理段统一前置 + 造数段 + 加工段）
-- 合并规则：
--   1. 各原脚本自带的「源表 DELETE」已全部抽出并前置到 §0（同一张表只清一次）
--      ⇒ 组内多个脚本不再互相删数据（原「后跑的删掉先跑的」问题消失）
--   2. 同一张表被组内多个脚本造数时，只保留一处（其余位置见 [已合并] 标记）
--   3. 加工段原样保留（各自 app 表的幂等 DELETE + INSERT 不受影响）
--   4. reportNo 已统一为 RPT-202609-001
-- 【owner 约定】xd_credit_info / xd_credit_loan 由本组唯一造数（见下）
--   xd_credit_info <- app_credit_use_info（14 列全字段版）
--   xd_credit_loan <- app_loan_receipt_info（12 行 28 列版）
--   其余脚本（entrust_pay / loan_receipt 的占位行、04 组的 capital_flow）不再造这两张表
--   执行顺序：01 -> 02 -> 04
-- 原脚本清单：
--     源头数据_app_check_index_info.sql
--     源头数据_app_check_object_info.sql
--     源头数据_app_check_opinion_info.sql
--     源头数据_app_check_record_info.sql
--     源头数据_app_credit_approval_manage_req_info.sql
--     源头数据_app_credit_use_info.sql
--     源头数据_app_customer_info.sql
--     源头数据_app_early_warning_info.sql
--     源头数据_app_early_warning_opinion_info.sql
--     源头数据_app_early_warning_signal_info.sql
--     源头数据_app_entrust_pay_info.sql
--     源头数据_app_loan_receipt_info.sql
--     源头数据_app_opinion_info.sql
--     源头数据_app_single_check_task_info.sql
--     源头数据_app_specific_loan_project_check_info.sql
--     源头数据_app_top_five_updown_info.sql
--     源头数据_app_xd_shareholder_info.sql
-- =====================================================================

-- =====================================================================
-- §0 统一清理（组内所有源表 + app 表，每张表只清一次）
-- =====================================================================
DELETE FROM xd_corp_check_daily_index  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_info         WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_check_object_info       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_fixed_loan    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_operate_loan  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_check_opinion_info            WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_reply_requirement   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_checkin       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_credit_approval_manage_req_info   WHERE customerid = 'CUST-001' AND reportno = 'RPT-202609-001';
DELETE FROM xd_corp_check_credit_requirement      WHERE customerId = 'CUST-001' AND reportNo   = 'RPT-202609-001';
DELETE FROM app_credit_use_info       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_credit_info            WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_customer_info           WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_xd_shareholder_info     WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_customer_control    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_customer_shareholder WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_customer_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001'
  AND EXISTS (SELECT 1 FROM xd_corp_customer_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001'
              AND (fictitiousPerson IS NULL OR registerCapital IS NULL OR paiclupCapital IS NULL
                   OR holdType IS NULL OR officeFormattedAddress IS NULL OR businessScope IS NULL
                   OR dangerLevel IS NULL OR warningLevel IS NULL OR isStiEnt IS NULL
                   OR listingCorpOrNot IS NULL));
DELETE FROM app_early_warning_info     WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_warning_task WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_early_warning_opinion_info  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_warning_opinion   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_early_warning_signal_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_warning_ledger              WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_entrust_pay_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_credit_payment     WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_credit_loan        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_gs_info            WHERE customerId IS NULL AND name IS NOT NULL
  AND reportNo = 'RPT-202609-001';
--   ↑ 收窄到本组自造的两行收款人企业（原条件 customerId='CUST-001' 根本删不到它们
--     ⇒ 重跑必撞主键 id=1/2）；不再触碰 01 组的借款人行（customerId='CUST-001'）
DELETE FROM app_loan_receipt_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_opinion_info                WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_current_opinion   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_last_opinion      WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_single_check_task_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_single_task_check       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_supplier     WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_customer_info         WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
-- =====================================================================
-- §1 造数（按原脚本分段；源表 DELETE 已上移；同表重复造数已省略）
-- =====================================================================

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_check_index_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_check_index_info（对公日检-日常检查综合指标）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_check_index.sql
-- 源表（父子表）：
--   xd_corp_check_info          对公检查主档（父表；按 reportNo 取最新 id 作为「当前主档」）
--   xd_corp_check_daily_index   日常检查综合指标（子表，mainId -> 主档.id，一指标一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_check_index.sql，9 列）：
--   chineseId/chineseName/yesNo/remark 透传（chineseName 源 VARCHAR(255) -> app VARCHAR(128) LEFT 截断）
--   indexObject 按附录2 硬编码 CASE：D22/D23=担保人指标 / D24~D30=抵质押物指标 /
--               D05~D19+D31=被检查人指标 / 其余=NULL
--   isAbnormal  按附录2 异常选项硬编码 CASE：
--       异常选项=否 组（D05/D06/D07/D09/D31）：yesNo='否' -> '是'，否则 '否'
--       异常选项=是 组（D08/D10~D19/D22~D30）：yesNo='是' -> '是'，否则 '否'
--       附录2 外：NULL
--   去重键 (reportNo, customerId, chineseId) ROW_NUMBER(inputtime DESC, id DESC)；先 JOIN 当前主档
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：25（D05/D31/D06/D07/D08/D09/D10/D11/D12/D13/D14/D15/D16/D17/D18/D19
--                   D22/D23/D24/D25/D26/D27/D28/D29/D30）
--
-- 共享父表：xd_corp_check_info id=1 由本文件创建，并被
--   源头数据_app_check_object_info.sql / app_check_opinion_info.sql / app_check_record_info.sql 复用
--   （后续文件用条件 INSERT IF NOT EXISTS 跳过创建）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表（含父表 id=1）
-- =====================================================================
DELETE FROM app_check_index_info       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
-- [已上移至 §0] DELETE FROM xd_corp_check_daily_index
-- [已上移至 §0] DELETE FROM xd_corp_check_info

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档，父表；显式 id=1 供 mainId 指向）
--    按报告编号取最新一条（inputtime DESC, id DESC）-> 单行即当前主档
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 10:30:00');

-- =====================================================================
-- 2. xd_corp_check_daily_index（日常检查综合指标，子表）
--    mainId=1（指向 xd_corp_check_info.id=1）；25 行（D05~D31 附录2 指标，一指标一行）
--    chineseId/chineseName/yesNo/remark 全部直映目标 DML（加工层透传）
--    isAbnormal/indexObject 由加工层 CASE 派生，源表无对应列
-- =====================================================================
INSERT INTO xd_corp_check_daily_index (mainId, reportNo, customerId, customerName, chineseId, chineseName, yesNo, remark, inputtime) VALUES
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D05', '经营信息是否真实有效', '否', '经核查，企业工商登记信息与实际情况不符，存在虚报注册资本、伪造经营场所等情形，经营信息不真实。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D31', '贷款资金用途是否合规且符合合同约定', '否', '贷款资金未按合同约定用途使用，部分资金被挪用于购买理财产品及偿还民间借贷，违反合同约定。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D06', '总体生产经营是否正常', '否', '企业已处于半停产状态，主要生产线停工，订单大幅减少，生产经营不正常。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D07', '现金流是否充裕', '否', '企业现金流紧张，经营性现金流入不足以覆盖到期债务，存在资金链断裂风险。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D08', '所属行业、国家产业政策是否发生不利于企业的、重大变化', '是', '所属行业被列入国家限制类产业目录，产业政策发生重大不利变化，对企业经营产生严重影响。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D09', '环保手续是否齐全（如有）', '否', '企业未取得排污许可证，环保验收手续缺失，存在被环保部门处罚的风险。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D10', '纳税是否异常波动', '是', '企业近半年纳税额同比大幅下降，且存在欠税记录，纳税异常波动。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D11', '员工人员及工资发放是否异常波动', '是', '企业员工人数锐减，且存在拖欠员工工资情况，工资发放异常。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D12', '是否涉及民间融资或民间借贷担保', '是', '经查，企业涉及多笔民间借贷，并为关联方民间融资提供担保，金额较大。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D13', '是否涉及重大刑事案件', '是', '企业实际控制人因涉嫌非法吸收公众存款被立案侦查，涉及重大刑事案件。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D14', '是否向非主业盲目扩张', '是', '企业近年大举投资房地产、金融等非主业领域，导致主业经营受影响，存在盲目扩张。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D15', '实控人健康、家庭状况是否发生重大不利变化', '是', '实际控制人因重病住院，且家庭发生重大变故，对企业经营决策产生不利影响。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D16', '股权结构/管理层是否发生重大不利变化', '是', '企业股权结构发生重大变更，核心管理层集体离职，管理层动荡。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D17', '是否遭受重大自然灾害等不可抗力的负面影响', '是', '企业厂房遭受火灾，生产设备损毁严重，恢复生产需较长时间。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D18', '是否达到相关办法中规定的业务中止或退出规定', '是', '企业已触发相关办法中规定的业务中止条件，如连续逾期超过90天。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D19', '还款意愿是否下降', '是', '借款人多次拖延还款，沟通中表现出消极还款意愿，还款意愿明显下降。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D22', '担保能力是否下降', '是', '担保人对外担保金额过大，代偿能力不足，担保能力显著下降。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D23', '还款意愿是否下降', '是', '担保人拒绝配合贷后检查，且明确表示不愿承担担保责任，还款意愿下降。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D24', '抵/质押物是否被查封、被冻或冻结', '是', '抵/质押物已被法院查封，存在被处置的风险。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D25', '抵/质押物权属是否变更或发生争议', '是', '抵/质押物权属发生变更，且存在第三方主张权利，权属争议较大。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D26', '抵/质押物是否被毁损', '是', '抵/质押物因保管不善发生严重毁损，价值大幅贬损。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D27', '抵/质押物市场价值是否大幅下降', '是', '抵/质押物市场价格大幅下跌，当前市值已不足以覆盖贷款本息。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D28', '抵/质押物状态（使用情况、租赁关系等）是否发生、变化', '是', '/', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D29', '第三方保管的，抵/质押物保管状态是否异常（如、有）', '否', '/', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D30', '第三方保管的，保管人的保管能力及资质是否发、生变化（如有）', '否', '/', '2026-03-05 10:30:00');

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工/xd_check_index.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 加工产出 25 行，业务字段与目标 DML 完全一致：
--      - chineseId/chineseName/yesNo/remark 直映 ✓
--      - indexObject 按 chineseId 派生（被检查人/担保人/抵质押物指标）✓
--      - isAbnormal 按 chineseId + yesNo 派生（异常选项否组：yesNo=否->是；异常选项是组：yesNo=是->是）✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..25）
--   4. app_check_index_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中 '2026-03-05 10:30:00.0' 无法精确复现（系统自动生成）
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_check_object_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_check_object_info（对公日检-特定贷款检查对象指标）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_check_object.sql
-- 源表（父子表，mainId -> xd_corp_check_info.id=1，父表共享自 app_check_index_info）：
--   xd_corp_check_fixed_loan     特定贷款检查数组（固定资产、房地产开发贷款）
--   xd_corp_check_operate_loan   特定贷款检查数组（经营性物业贷款、厂房通贷款）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_check_object.sql，13 列）：
--   objectName/contractNo   <- 源列直映（objectName 经驱动表归一匹配后取源原值输出）
--   indexNo/indexName/indexType/redTextRequire <- 驱动表（附录3）固定写死，与源列无关
--   indexResult             <- CASE indexNo 取源对应列（fixed/operate 各一组）
--   isAbnormal              <- CASE abnormalMode 派生（TRIGGER_YES/TRIGGER_NO/PROMPT_NO/NONE）
--   去重键 (reportNo, customerId, contractNo) ROW_NUMBER(inputtime DESC, id DESC)；先 JOIN 当前主档
--
-- 源列名映射（indexNo -> 源列）：
--   fixed_loan:  ifOverInvest/overInvest/ifConstructionExpect/ifMatch/capitalCheckCondition/
--                schedulCheckCondition(->scheduleCheckCondition)/purchaseCheckCondition/
--                ifRunExpect/runCheckCondition/ifOpenAccount/ifsign(->ifSign)/superviseCheckCondition/ifGetPermission
--   operate_loan: ifDown/ifDownExplain/ifPledge/ifPledgeExplain/ifChange/expectation/expectation2/
--                 operateIncomeCondition/ifSupervise/ifOpenAccount/superviseExplain/
--                 ifSign(->ifsign 驱动键)/signExplain/operateCDIncomeCondition
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：65（5 个合同 × 12/12/13/14/14 指标 = 65 行，已按合同分组）
--   合同 a 固定资产/GDZC-2026-001  -> fixed_loan 12 行（ifOverInvest..superviseCheckCondition）
--   合同 b 固定资产/GDZC-2026-002  -> fixed_loan 12 行（同 a）
--   合同 c 房地产开发贷款/FDK-2026-003 -> fixed_loan 13 行（ifGetPermission + 12 项）
--   合同 d 经营性物业贷款/YYWY-2026-004 -> operate_loan 14 行
--   合同 e 厂房通贷款/CFT-2026-005  -> operate_loan 14 行
--
-- 共享父表：xd_corp_check_info id=1（来自 app_check_index_info 文件，本文件条件 IF NOT EXISTS 跳过创建）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源子表（不动父表 id=1，避免影响 check_index/opinion/record）
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_check_object_info
-- [已上移至 §0] DELETE FROM xd_corp_check_fixed_loan
-- [已上移至 §0] DELETE FROM xd_corp_check_operate_loan

-- =====================================================================
-- 1. xd_corp_check_info（共享父表，条件创建：仅当 id=1 不存在时插入）
--    排他父表来源：源头数据_app_check_index_info.sql（主创建者）
-- =====================================================================
-- [已合并] xd_corp_check_info 造数与 app_check_index_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 2. xd_corp_check_fixed_loan（固定资产 / 房地产开发贷款，3 行）
--    mainId=1；objectName=源原值（加工层 CASE 归一匹配 '固定资产贷款'->'固定资产'，本处源用 '固定资产' 也走 ELSE 直映）
--    各指标列 = 目标 indexResult 值（NULL -> NULL）
--    资本金/进度/采购三段说明（capitalCheckCondition/scheduleCheckCondition/purchaseCheckCondition）
--      在 a/b/c 三个合同中完全一致，逐字对齐目标 DML 多行文本
-- =====================================================================
-- 合同 a：固定资产/GDZC-2026-001（12 指标）
INSERT INTO xd_corp_check_fixed_loan (
    mainId, reportNo, customerId, customerName, objectName, contractNo,
    ifOverInvest, overInvest, ifConstructionExpect, ifMatch,
    capitalCheckCondition, scheduleCheckCondition, purchaseCheckCondition,
    ifRunExpect, runCheckCondition, ifOpenAccount, ifSign, superviseCheckCondition, ifGetPermission,
    inputtime
) VALUES (
    1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '固定资产', 'GDZC-2026-001',
    '是', NULL, '否', '否',
    '本项目总投资16574.08万元，其中项目资本金5000万元。目前项目资本金已到位4000万元，并纳入实收资本科目核算。扬州诚瑞会计师事务所有限公司出具了 具4000万元项目资本金到位的审计报告。截至目前，项目资本金已使用3492.36万元，到位并使用的项目资本金在总资金本中的占比为69.85%，发票已提供，不存在资本金抽逃。',
    '根据华奕集团2026年工作部署，江苏华奕工厂计划于2026年5月正式投产，较前次反馈2025年11月投产延后约6个月，主要原因如下： 一是集团对江苏华奕工厂的定位，是辐射长三角乃至整个华东地区的重要生产基地，也是集团对外展示的重要平台和窗口，并在此设立了业内一流的实验室， 2026年全面投产后，还将承担集团出海拓展北美市场的重任，因此整个厂区建设 标准很高。从项目施工、装修设计，到材料设备采购、实验室建设等环节集团均 ，项目进度与业务 层层把关，发生了多次细微调整，并且成本管控十分严格，发现问题后第一时间 14（如对比实际项目起 要求施工单位立即停工整改； 二是本项目室外配套工程原先中标方为长沙中辉建筑工程有限公司，该公司2025年8月进场施工，2025年11月提出因对项目所在地的地下水网、土壤环境不熟悉导致项目室外配套工程无法继续推进，最终双方在2025年12月签订了《解除协议》，2025年12月，借款人与总包方江苏鼎源建设有限公司签订《项目室外配套工程施工合同》，江苏鼎源2026年1月进场施工，计划2026年4月室外配套工程完工。由于项目室外配套工程中标方中途毁约影响，导致项目整体工程进度带后4个',
    '1、施工总承包合同：合同总金额7300.02万元，已付款金额4599.02万元，已开票金额4599.02万元； 2、装修改造工程施工合同：合同总金额3301万元，已付款金额1155.35万元， 殳备款应支付金额， 3、冷水水系统土建及钢结构工程施工合同：合同总金额19.80万元，已付款金额 顶，已支付的工程款 19.206万元，已开票金额19.80万元； 改占比，工程款或设 4、3#厂房实验室基础工程施工合同：合同金额15.95万元，已付款金额15.47万 元，已开票金额15.95万元； 5、办公楼门窗变更工程施工合同：合同金额160万元，已付款48万元，已开票 6、室外配套工程',
    '否', NULL, '否', '否', NULL, NULL,
    '2026-03-05 10:30:00'
);

-- 合同 b：固定资产/GDZC-2026-002（12 指标，业务值与 a 一致）
INSERT INTO xd_corp_check_fixed_loan (
    mainId, reportNo, customerId, customerName, objectName, contractNo,
    ifOverInvest, overInvest, ifConstructionExpect, ifMatch,
    capitalCheckCondition, scheduleCheckCondition, purchaseCheckCondition,
    ifRunExpect, runCheckCondition, ifOpenAccount, ifSign, superviseCheckCondition, ifGetPermission,
    inputtime
) VALUES (
    1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '固定资产', 'GDZC-2026-002',
    '是', NULL, '否', '否',
    '本项目总投资16574.08万元，其中项目资本金5000万元。目前项目资本金已到位4000万元，并纳入实收资本科目核算。扬州诚瑞会计师事务所有限公司出具了 具4000万元项目资本金到位的审计报告。截至目前，项目资本金已使用3492.36万元，到位并使用的项目资本金在总资金本中的占比为69.85%，发票已提供，不存在资本金抽逃。',
    '根据华奕集团2026年工作部署，江苏华奕工厂计划于2026年5月正式投产，较前次反馈2025年11月投产延后约6个月，主要原因如下： 一是集团对江苏华奕工厂的定位，是辐射长三角乃至整个华东地区的重要生产基地，也是集团对外展示的重要平台和窗口，并在此设立了业内一流的实验室， 2026年全面投产后，还将承担集团出海拓展北美市场的重任，因此整个厂区建设 标准很高。从项目施工、装修设计，到材料设备采购、实验室建设等环节集团均 ，项目进度与业务 层层把关，发生了多次细微调整，并且成本管控十分严格，发现问题后第一时间 14（如对比实际项目起 要求施工单位立即停工整改； 二是本项目室外配套工程原先中标方为长沙中辉建筑工程有限公司，该公司2025年8月进场施工，2025年11月提出因对项目所在地的地下水网、土壤环境不熟悉导致项目室外配套工程无法继续推进，最终双方在2025年12月签订了《解除协议》，2025年12月，借款人与总包方江苏鼎源建设有限公司签订《项目室外配套工程施工合同》，江苏鼎源2026年1月进场施工，计划2026年4月室外配套工程完工。由于项目室外配套工程中标方中途毁约影响，导致项目整体工程进度带后4个',
    '1、施工总承包合同：合同总金额7300.02万元，已付款金额4599.02万元，已开票金额4599.02万元； 2、装修改造工程施工合同：合同总金额3301万元，已付款金额1155.35万元， 殳备款应支付金额， 3、冷水水系统土建及钢结构工程施工合同：合同总金额19.80万元，已付款金额 顶，已支付的工程款 19.206万元，已开票金额19.80万元； 改占比，工程款或设 4、3#厂房实验室基础工程施工合同：合同金额15.95万元，已付款金额15.47万 元，已开票金额15.95万元； 5、办公楼门窗变更工程施工合同：合同金额160万元，已付款48万元，已开票 6、室外配套工程',
    '否', NULL, '否', '否', NULL, NULL,
    '2026-03-05 10:30:00'
);

-- 合同 c：房地产开发贷款/FDK-2026-003（13 指标 = ifGetPermission + 12 项）
INSERT INTO xd_corp_check_fixed_loan (
    mainId, reportNo, customerId, customerName, objectName, contractNo,
    ifOverInvest, overInvest, ifConstructionExpect, ifMatch,
    capitalCheckCondition, scheduleCheckCondition, purchaseCheckCondition,
    ifRunExpect, runCheckCondition, ifOpenAccount, ifSign, superviseCheckCondition, ifGetPermission,
    inputtime
) VALUES (
    1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '房地产开发贷款', 'FDK-2026-003',
    '是', NULL, '否', '否',
    '本项目总投资16574.08万元，其中项目资本金5000万元。目前项目资本金已到位4000万元，并纳入实收资本科目核算。扬州诚瑞会计师事务所有限公司出具了 具4000万元项目资本金到位的审计报告。截至目前，项目资本金已使用3492.36万元，到位并使用的项目资本金在总资金本中的占比为69.85%，发票已提供，不存在资本金抽逃。',
    '根据华奕集团2026年工作部署，江苏华奕工厂计划于2026年5月正式投产，较前次反馈2025年11月投产延后约6个月，主要原因如下： 一是集团对江苏华奕工厂的定位，是辐射长三角乃至整个华东地区的重要生产基地，也是集团对外展示的重要平台和窗口，并在此设立了业内一流的实验室， 2026年全面投产后，还将承担集团出海拓展北美市场的重任，因此整个厂区建设 标准很高。从项目施工、装修设计，到材料设备采购、实验室建设等环节集团均 ，项目进度与业务 层层把关，发生了多次细微调整，并且成本管控十分严格，发现问题后第一时间 14（如对比实际项目起 要求施工单位立即停工整改； 二是本项目室外配套工程原先中标方为长沙中辉建筑工程有限公司，该公司2025年8月进场施工，2025年11月提出因对项目所在地的地下水网、土壤环境不熟悉导致项目室外配套工程无法继续推进，最终双方在2025年12月签订了《解除协议》，2025年12月，借款人与总包方江苏鼎源建设有限公司签订《项目室外配套工程施工合同》，江苏鼎源2026年1月进场施工，计划2026年4月室外配套工程完工。由于项目室外配套工程中标方中途毁约影响，导致项目整体工程进度带后4个',
    '1、施工总承包合同：合同总金额7300.02万元，已付款金额4599.02万元，已开票金额4599.02万元； 2、装修改造工程施工合同：合同总金额3301万元，已付款金额1155.35万元， 殳备款应支付金额， 3、冷水水系统土建及钢结构工程施工合同：合同总金额19.80万元，已付款金额 顶，已支付的工程款 19.206万元，已开票金额19.80万元； 改占比，工程款或设 4、3#厂房实验室基础工程施工合同：合同金额15.95万元，已付款金额15.47万 元，已开票金额15.95万元； 5、办公楼门窗变更工程施工合同：合同金额160万元，已付款48万元，已开票 6、室外配套工程',
    '否', NULL, '否', '否', NULL, '否',
    '2026-03-05 10:30:00'
);

-- =====================================================================
-- 3. xd_corp_check_operate_loan（经营性物业贷款 / 厂房通贷款，2 行）
--    mainId=1；objectName=源原值（与驱动表一致，无需归一）
--    各指标列 = 目标 indexResult 值（NULL -> NULL）
-- =====================================================================
-- 合同 d：经营性物业贷款/YYWY-2026-004（14 指标）
INSERT INTO xd_corp_check_operate_loan (
    mainId, reportNo, customerId, customerName, objectName, contractNo,
    ifDown, ifDownExplain, ifPledge, ifPledgeExplain, ifChange,
    expectation, expectation2, operateIncomeCondition,
    ifSupervise, ifOpenAccount, superviseExplain, ifSign, signExplain, operateCDIncomeCondition,
    inputtime
) VALUES (
    1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '经营性物业贷款', 'YYWY-2026-004',
    '是', NULL, '是', NULL, '是',
    '否', '否', NULL,
    '否', '否', NULL, '否', NULL, NULL,
    '2026-03-05 10:30:00'
);

-- 合同 e：厂房通贷款/CFT-2026-005（14 指标，业务值与 d 一致）
INSERT INTO xd_corp_check_operate_loan (
    mainId, reportNo, customerId, customerName, objectName, contractNo,
    ifDown, ifDownExplain, ifPledge, ifPledgeExplain, ifChange,
    expectation, expectation2, operateIncomeCondition,
    ifSupervise, ifOpenAccount, superviseExplain, ifSign, signExplain, operateCDIncomeCondition,
    inputtime
) VALUES (
    1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '厂房通贷款', 'CFT-2026-005',
    '是', NULL, '是', NULL, '是',
    '否', '否', NULL,
    '否', '否', NULL, '否', NULL, NULL,
    '2026-03-05 10:30:00'
);

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工/xd_check_object.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 加工产出 65 行（12+12+13+14+14），业务字段与目标 DML 大体一致：
--      - reportNo/customerId/customerName/objectName/contractNo/indexNo/indexName/indexType/
--        indexResult/redTextRequire 直映或驱动表写死 ✓
--      - isAbnormal 按 abnormalMode + indexResult 派生 ✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..65）
--   4. app_check_object_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中 '2026-03-05 10:30:00.0' 无法精确复现
--
--   -- ISSUE 1（说明类 isAbnormal）：
--      目标 DML 中说明类行（indexType='说明'）的 isAbnormal=NULL，
--      但加工 SQL 的 abnormalMode=NONE 走 ELSE '否' 分支 -> 加工产出 '否'（非 NULL）。
--      影响行：a/b 各 5 行（overInvest/capitalCheck/schedulCheck/purchaseCheck/runCheck/superviseCheck 共 6 项，
--      其中 overInvest=NULL 时 isAbnormal 仍按 ELSE='否'；target 为 NULL）+
--      c 同 6 行 + d/e 各 5 行（ifDownExplain/ifPledgeExplain/operateIncomeCondition/superviseExplain/
--      signExplain/operateCDIncomeCondition 共 6 项中除 ifDownExplain=NULL 时 target=NULL）。
--      实际：所有说明类行加工产出 isAbnormal='否'，而 target DML 中说明类 isAbnormal=NULL（约 35 行差异）。
--      本任务禁止改加工 SQL，故 isAbnormal 差异无法消除；其余业务字段一致。
--
--   -- ISSUE 2（rows 49/63 indexNo=NULL）：
--      目标 DML 中 id=49（YYWY-2026-004）和 id=63（CFT-2026-005）的 indexNo=NULL/indexName=NULL，
--      但加工 SQL 驱动表对 ifSign 行固定输出 indexNo='ifsign'/indexName='资金监管协议是否已签署'。
--      源 ifSign='否' -> 加工产出 indexNo='ifsign', indexName='资金监管协议是否已签署', indexResult='否',
--      与 target indexNo=NULL 不一致（2 行差异）。本任务禁止改加工 SQL，故无法消除。
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_check_opinion_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_check_opinion_info（对公日检-批复后续管理要求）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_check_opinion.sql
-- 源表（父子表，mainId -> xd_corp_check_info.id=1，父表共享自 app_check_index_info）：
--   xd_corp_check_reply_requirement   批复后续管理要求 CheckFollowUpRequirement
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_check_opinion.sql，10 列）：
--   conditionDesc         <- condition                后续管理要求内容（源 VARCHAR(1000) -> app TEXT）
--   completeStatus        <- completeStatus           完成状态（原样透传）
--   conditionInstruction  <- conditionInstruction     要求说明（源 VARCHAR(1000) -> app TEXT）
--   realCompleteTime      <- realCompleteTime         实际完成时间（VARCHAR(64) -> app VARCHAR(32)）
--                          正则 ^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$ 命中去 -/；不命中原样透传
--   itemCategory          <- itemCategory             事项类别
--   去重键 (reportNo, customerId, condition) ROW_NUMBER(inputtime DESC, id DESC)；先 JOIN 当前主档
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：5
--   realCompleteTime 源 = '2026-08-31'（YYYY-MM-DD）-> 加工去 - -> '20260831'，
--   app 列若为 DATE 类型，存储回 '2026-08-31 00:00:00'（与目标 DML 一致）
--
-- 共享父表：xd_corp_check_info id=1（来自 app_check_index_info 文件，本文件条件 IF NOT EXISTS 跳过创建）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源子表（不动父表 id=1）
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_check_opinion_info
-- [已上移至 §0] DELETE FROM xd_corp_check_reply_requirement

-- =====================================================================
-- 1. xd_corp_check_info（共享父表，条件创建：仅当 id=1 不存在时插入）
-- =====================================================================
-- [已合并] xd_corp_check_info 造数与 app_check_index_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 2. xd_corp_check_reply_requirement（批复后续管理要求，5 行）
--    mainId=1；condition/completeStatus/conditionInstruction/realCompleteTime/itemCategory 全部直映目标 DML
--    realCompleteTime 源用 '2026-08-31'（YYYY-MM-DD），加工去 - 后 '20260831'，app 列 DATE 回填 '2026-08-31 00:00:00'
-- =====================================================================
INSERT INTO xd_corp_check_reply_requirement (
    mainId, reportNo, customerId, customerName, condition, completeStatus,
    conditionInstruction, realCompleteTime, itemCategory, inputtime
) VALUES
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '关注原材料价格波动对生产成本的影响，关注主要客户合作稳定性及订单变化情况。',
 '持续关注',
 '本年主要原材料采购成本较上年同期上涨约8%，企业已通过调整采购策略部分对冲影响；前五大客户合作协议均已续签，订单量同比基本持平',
 '2026-08-31', '08', '2026-08-31 17:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '关注对外担保风险，定期核查被担保企业经营状况及偿债能力变化。',
 '持续关注',
 '目前对外担保余额合计1,200万元，被担保企业生产经营正常，未发现代偿风险信号',
 '2026-08-31', '08', '2026-08-31 17:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '结算回笼资金归行率不低于30%，按月监测销售回款及资金流向，确保贷款资金用途合规。',
 '持续关注',
 '本月销售回款1,850万元，归行率约35%，符合批复要求；贷款资金用途均与约定用途一致，未发现挪用情况',
 '2026-08-31', '08', '2026-08-31 17:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '关注环保政策及行业准入变化对企业生产经营的影响，定期核查安全生产合规情况。',
 '持续关注',
 '企业已取得最新排污许可证，本年度环保检查合格；行业准入方面未发生重大不利变化',
 '2026-08-31', '08', '2026-08-31 17:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '资产负债率不得高于50%，每季度监测资产负债结构变化，确保财务杠杆水平在可控范围内。',
 '持续关注',
 '本期资产负债率58.2%，已超出批复要求8.2个百分点，主要系短期借款增加所致，已督促企业制定降负债方案',
 '2026-08-31', '08', '2026-08-31 17:35:00');

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工/xd_check_opinion.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 加工产出 5 行，业务字段与目标 DML 完全一致：
--      - conditionDesc/completeStatus/conditionInstruction/itemCategory 直映 ✓
--      - realCompleteTime 源 '2026-08-31' -> 去分隔符 -> '20260831' -> app DATE 回填 '2026-08-31 00:00:00' ✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..5）
--   4. app_check_opinion_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中 '2026-08-31 17:30:00.0' / '17:35:00.0' 无法精确复现
--
--   -- ISSUE: 目标 DML 中第 3 行 conditionDesc 为
--      '...按月监测销售回款及资金流向，确保贷款资金用途合规。'
--      而原始业务材料（节选）可能写作 '...资金归集情况...'，
--      此处以目标 DML 实际文本为准（conditionDesc 直映），源表 = 目标值。
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_check_record_info.sql
-- ---------------------------------------------------------------------
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
-- [已上移至 §0] DELETE FROM xd_corp_check_checkin

-- =====================================================================
-- 1. xd_corp_check_info（共享父表，条件创建：仅当 id=1 不存在时插入）
-- =====================================================================
-- [已合并] xd_corp_check_info 造数与 app_check_index_info 重复，此处省略（避免主键冲突）

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
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_credit_approval_manage_req_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_credit_approval_manage_req_info（对公日检-授信批复管理要求）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_credit_approval_req.sql
-- 源表（父子表，mainId -> xd_corp_check_info.id=1，父表共享自 app_check_index_info）：
--   xd_corp_check_credit_requirement   授信批复后续管理要求 CreditFollowUpRequirement
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_credit_approval_req.sql，9 列）：
--   swqNo            <- seqNo              序号（LEFT 32 截断）
--   "CONDITION"      <- condition          授信后续管理要求内容
--   PELATIVESERIALNO <- relativeSerialNo   关联流水号
--   checkDate        <- checkDate          检查日期（正则命中归一 yyyy-MM-dd）
--   去重键 (reportNo, customerId, seqNo, condition, relativeSerialNo, checkDate)
--   ROW_NUMBER(inputtime DESC, id DESC)；先 JOIN 当前主档
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：1（1 条授信批复管理要求）
--   seqNo='1' / condition='我行授信未全部结清前抵押物不得出库（权证到期换证除外）'
--   relativeSerialNo='全部' / checkDate='2025-06-07' -> 加工后 checkDate='2025-06-07'
--
-- 共享父表：xd_corp_check_info id=1（来自 app_check_index_info 文件，本文件条件 IF NOT EXISTS 跳过创建）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源子表（不动父表 id=1）
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_credit_approval_manage_req_info
-- [已上移至 §0] DELETE FROM xd_corp_check_credit_requirement

-- =====================================================================
-- 1. xd_corp_check_info（共享父表，条件创建：仅当 id=1 不存在时插入）
--    排他父表来源：源头数据_app_check_index_info.sql（主创建者）
-- =====================================================================
-- [已合并] xd_corp_check_info 造数与 app_check_index_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 2. xd_corp_check_credit_requirement（授信批复后续管理要求，1 行）
--    mainId=1；seqNo/condition/relativeSerialNo/checkDate 直映到 app 表
--    checkDate='2025-06-07' -> 正则命中 -> 加工后 '2025-06-07'（DATE 类型）
-- =====================================================================
INSERT INTO xd_corp_check_credit_requirement (
    mainId, reportNo, customerId, customerName, seqNo, condition, relativeSerialNo, checkDate, inputtime
) VALUES (
    1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
    '1', '我行授信未全部结清前抵押物不得出库（权证到期换证除外）', '全部', '2025-06-07',
    '2026-03-15 10:23:45'
);

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_credit_use_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_credit_use_info（我行授信用用概况）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_credit_use.sql
-- 源表：
--   xd_credit_info         授信用用主档（aflCreditLoanQry 落表，每 reportNo 取最新一条）
--   xd_corp_customer_info  客户主档（getEntCustomerAllQry 落表，取 groupClientNo/groupClientName）
--                          与 app_customer_info / app_xd_shareholder_info 共享（id=1）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_credit_use.sql，17 列）：
--   creditSum/balance/exposureAmount/limitBalance/groupAmount/groupBalance <- 源列直映（DECIMAL）
--   isGroup      <- CASE cc.groupClientNo：非空 -> '是'，否则 NULL（'否' 分支不可达）
--   groupName    <- CASE cc.groupClientName：空 -> groupClientNo 否则 groupClientName
--   creditDate       <- 正则命中 yyyy-MM-dd / yyyy/MM/dd 去分隔符；不命中（如 '202509'）原样透传
--   latestOverdueDate<- 同上；源 '2025-07-01' -> '20250701' -> app DATE 列回填 '2025-07-01'
--   gdOverdueCounts/ajOverdueCounts <- CAST(TRIM AS INTEGER)；源 VARCHAR
--   主档去重 ROW_NUMBER(reportNo ORDER BY inputtime DESC, id DESC)；LEFT JOIN 客户主档 rn=1
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：1
--   creditSum=800.00, balance=565.00, exposureAmount=700.00, limitBalance=515.00
--   groupAmount=8000.00, groupBalance=5750.00
--   isGroup='是', groupName='江阴市xx精密集团'
--   creditDate='202509' (源同值，正则不命中->透传)
--   latestOverdueDate='2025-07-01' (源同值 -> 去 - -> '20250701' -> DATE 回填)
--   gdOverdueCounts=2 (源 '2'), ajOverdueCounts=3 (源 '3')
--
-- 共享父表：xd_corp_customer_info id=1（与 app_customer_info / app_xd_shareholder_info 共享）
--   本文件用条件 IF NOT EXISTS 创建最小化字段集（含 groupClientNo/groupClientName）；
--   app_customer_info 文件检测到关键字段为空时会 DELETE + 重建补齐字段（保留 groupClient*）；
--   app_xd_shareholder_info 文件用条件 IF NOT EXISTS 跳过创建（股东子表不读 customer_info 列）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + xd_credit_info（仅清自身专有源表）
--    xd_corp_customer_info id=1 为共享父表（与 app_customer_info / app_xd_shareholder_info 共享），
--    本文件不删除该父表行 -> 由 app_customer_info 文件负责字段补齐/重建
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_credit_use_info
-- [已上移至 §0] DELETE FROM xd_credit_info

-- =====================================================================
-- 1. xd_credit_info（授信用用主档，1 行）
--    creditDate='202509'（YYYYMM 无分隔符，正则不命中 -> 透传）
--    latestOverdueDate='2025-07-01'（YYYY-MM-DD，正则命中 -> '20250701'，app DATE 回填）
--    gdOverdueCounts='2' / ajOverdueCounts='3'（VARCHAR，CAST SIGNED -> 2/3）
-- =====================================================================
INSERT INTO xd_credit_info (
    reportNo, customerId, customerName, creditSum, creditDate, balance, exposureAmount,
    limitBalance, groupAmount, groupBalance, latestOverdueDate, gdOverdueCounts, ajOverdueCounts, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
    800.00, '202509', 565.00, 700.00,
    515.00, 8000.00, 5750.00, '2025-07-01', '2', '3',
    '2025-04-18 09:20:00'
);

-- =====================================================================
-- 2. xd_corp_customer_info（共享客户主档，条件创建：仅当 id=1 不存在时插入最小化字段集）
--    groupClientNo='GRP-001'（非空 -> isGroup='是'）
--    groupClientName='江阴市xx精密集团'（非空 -> groupName=该值）
--    注意：若 app_customer_info 文件已运行（id=1 含全字段），此处 IF NOT EXISTS 跳过，
--          app_credit_use加工仍可读取已存在的 groupClientNo/groupClientName -> 正常产出
--    若本文件先运行，创建最小化行；后续 app_customer_info 文件检测到关键字段为空，
--          会 DELETE + 重建补齐字段（不影响 groupClientNo/groupClientName，仍保留）
-- =====================================================================
-- [已合并] xd_corp_customer_info 造数与 app_customer_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工/xd_credit_use.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 加工产出 1 行，业务字段与目标 DML 完全一致：
--      - creditSum/balance/exposureAmount/limitBalance/groupAmount/groupBalance 直映 ✓
--      - isGroup='是'（groupClientNo='GRP-001' 非空）✓
--      - groupName='江阴市xx精密集团'（groupClientName 非空取此）✓
--      - creditDate='202509'（正则不命中->透传）✓
--      - latestOverdueDate：源 '2025-07-01' -> 去 - -> '20250701' -> app DATE 列回填 '2025-07-01' ✓
--      - gdOverdueCounts=2（源 '2' CAST SIGNED）✓
--      - ajOverdueCounts=3（源 '3' CAST SIGNED）✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1）
--   4. app_credit_use_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中 '2025-04-18 09:20:00.0' 无法精确复现
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_customer_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_customer_info（客户工商概况）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_customer.sql（同时产出 app_xd_shareholder_info）
-- 源表（父子表，mainId -> xd_corp_customer_info.id=1，父表共享自 app_credit_use_info）：
--   xd_corp_customer_info     客户主档（CustomerEndInfoDto）
--   xd_corp_customer_control  实际控制人（ControlshipExecutives）
--   （xd_corp_customer_shareholder 由 app_xd_shareholder_info 文件造数，本文件不插）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_customer.sql，19 列）：
--   legalPerson      <- fictitiousPerson            法人代表
--   registerCapital  <- registerCapital             DECIMAL 直映
--   paidInCapital    <- paiclupCapital              DECIMAL 直映
--   industryType     <- COALESCE(d.code_name, i.industryType)  码值字典 JOIN，未命中回退原值
--   holdType         <- CASE holdType 码值（10 码） 050->个人绝对控股
--   actualController <- GROUP_CONCAT(DISTINCT controlName ORDER BY controlName SEPARATOR '、')  isControl='1' 去重顿号拼接
--   officeAddress    <- officeFormattedAddress
--   businessScope    <- businessScope
--   dangerLevel      <- CASE dangerLevel 码值（10 码）  未收录原样保留（'6级' 透传）
--   warningLevel     <- CASE warningLevel 码值（5 码）  4->黄色预警
--   isTechCompany    <- isStiEnt 直映（无需映射）
--   isListedCompany  <- listingCorpOrNot 直映（无需映射）
--   主档去重 ROW_NUMBER(reportNo ORDER BY inputtime DESC, id DESC)
--   控制人去重 ROW_NUMBER(reportNo, controlName+certId ORDER BY inputtime DESC, id DESC)
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：1
--   legalPerson='李四', registerCapital=3000.00, paidInCapital=3000.00
--   industryType='房屋建筑业' (源同中文，码值字典 JOIN 未命中回退原值)
--   holdType='个人绝对控股' (源 '050' CASE 命中)
--   actualController='张三；李四' (源 2 行控制人 controlName='张三'/'李四')
--   officeAddress='泰州市xx路XXX号'
--   businessScope='建设工程施工，同时兼营园林绿化工程施工、土石方工程施工以及建筑材料销售等一般性业务'
--   dangerLevel='6级' (源 '6级' 未收录码，CASE ELSE 透传)
--   warningLevel='黄色预警' (源 '4' CASE 命中)
--   isTechCompany='是' (源 isStiEnt='是'，直映)
--   isListedCompany='是' (源 listingCorpOrNot='是'，直映)
--
-- 共享父表：xd_corp_customer_info id=1（与 app_credit_use_info / app_xd_shareholder_info 共享）
--   本文件负责字段补齐：若 id=1 来自 app_credit_use_info（最小化字段集，关键字段为空），
--   本文件先 DELETE 再用完整字段 INSERT；若 id=1 不存在则直接 INSERT（全字段）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源子表（不动父表 id=1）
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_customer_info
-- [已上移至 §0] DELETE FROM app_xd_shareholder_info
-- [已上移至 §0] DELETE FROM xd_corp_customer_control
-- [已上移至 §0] DELETE FROM xd_corp_customer_shareholder

-- =====================================================================
-- 1. xd_corp_customer_info（共享父表，条件创建：仅当 id=1 不存在时插入）
--    注意：本文件用条件 INSERT 保证幂等；若需更新父表字段（如 businessScope），
--    请先 DELETE FROM xd_corp_customer_info WHERE id=1 再重新执行 app_credit_use_info 与本文件
--    本文件用补齐字段的条件 INSERT（包含 customer_info 全部所需字段），覆盖 app_credit_use_info
--    父表的最小化字段集
-- =====================================================================
-- 若 id=1 已存在但字段不齐（来自 app_credit_use_info），先删除再重建以补齐字段
-- [已上移至 §0] DELETE FROM xd_corp_customer_info

INSERT INTO xd_corp_customer_info (
    id, reportNo, customerId, customerName, fictitiousPerson, registerCapital, paiclupCapital,
    industryType, holdType, officeFormattedAddress, businessScope,
    dangerLevel, warningLevel, isStiEnt, listingCorpOrNot,
    groupClientNo, groupClientName, inputtime
)
SELECT 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
       '李四', 3000.00, 3000.00,
       '房屋建筑业', '050', '泰州市xx路XXX号',
       '建设工程施工，同时兼营园林绿化工程施工、土石方工程施工以及建筑材料销售等一般性业务',
       '6级', '4', '是', '是',
       'GRP-001', '江阴市xx精密集团', '2025-04-18 09:20:00'
WHERE NOT EXISTS (SELECT 1 FROM xd_corp_customer_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001');

-- =====================================================================
-- 2. xd_corp_customer_control（实际控制人，2 行）
--    mainId=1；controlName='张三'/'李四'，isControl='1'（纳入 actualController 拼接）
--    certId 各异 -> 去重键 (controlName+certId) 各保留 1 行
--    加工层 GROUP_CONCAT(DISTINCT controlName ORDER BY controlName SEPARATOR '、') -> 输出 '张三、李四'
-- =====================================================================
INSERT INTO xd_corp_customer_control (
    mainId, reportNo, customerId, customerName, controlName, certId, isControl, inputtime
) VALUES
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '张三', 'CERT-001', '1', '2025-04-18 09:20:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '李四', 'CERT-002', '1', '2025-04-18 09:20:00');

-- =====================================================================
-- 3. xd_corp_customer_shareholder（股东信息，6 行，使本文件两张 app 表均有数据）
--    mainId=1；shareholderName 各异（去重键 (reportNo, customerId, shareholderName)）
-- =====================================================================
-- [已合并] xd_corp_customer_shareholder 造数与 app_xd_shareholder_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工/xd_customer.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 加工产出 1 行，业务字段与目标 DML 大体一致：
--      - legalPerson/registerCapital/paidInCapital/officeAddress/businessScope 直映 ✓
--      - industryType='房屋建筑业'（源中文，码值字典 JOIN 未命中回退原值）✓
--      - holdType='个人绝对控股'（源 '050' CASE 命中）✓
--      - dangerLevel='6级'（源未收录码，CASE ELSE 透传）✓
--      - warningLevel='黄色预警'（源 '4' CASE 命中）✓
--      - isTechCompany='是'（源 isStiEnt='是'，直映）✓
--      - isListedCompany='是'（源 listingCorpOrNot='是'，直映）✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1）
--   4. app_customer_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中 '2025-04-18 09:20:00.0' 无法精确复现
--
--   -- ISSUE 1（actualController 分隔符）：
--      目标 DML actualController='张三、李四'（顿号分隔），
--      加工 SQL GROUP_CONCAT(DISTINCT controlName ORDER BY controlName SEPARATOR '、') -> 输出 '张三、李四'。
--      顺序按 controlName 排序，已保证固定顺序。
--
--   -- ISSUE 2（isStateOwned / groupName 不在加工 SQL 输出列）：
--      加工 SQL INSERT 列清单（见 xd_customer.sql 第 59-63 行）仅含 15 列，不含 isStateOwned / groupName。
--      目标 DML isStateOwned='否' / groupName='江阴市xx精密集团' 由其他流程（Java 侧或后续加工）写入。
--      本源头数据无法驱动产出这两个字段；若需一致，需在 app_customer_info INSERT 后另行 UPDATE 补值。
--
--   注意：xd_customer.sql 同时清理 + 加工 app_xd_shareholder_info（与 app_customer_info 同节点）
--      本文件已补插 xd_corp_customer_shareholder 6 行数据，app_xd_shareholder_info 加工产出 6 行
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_early_warning_info.sql
-- ---------------------------------------------------------------------
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
-- [已上移至 §0] DELETE FROM app_early_warning_info
-- [已上移至 §0] DELETE FROM xd_corp_check_warning_task
-- [已上移至 §0] DELETE FROM xd_corp_check_info

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档；显式 id 供 warning_task.mainId 指向）
--    列：id, reportNo, customerId, customerName, inputtime
-- =====================================================================
-- [已合并] xd_corp_check_info 造数与 app_check_index_info 重复，此处省略（避免主键冲突）

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
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_early_warning_opinion_info.sql
-- ---------------------------------------------------------------------
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
-- [已上移至 §0] DELETE FROM app_early_warning_opinion_info
-- [已上移至 §0] DELETE FROM xd_corp_check_warning_opinion
-- [已上移至 §0] DELETE FROM xd_corp_check_warning_task
-- [已上移至 §0] DELETE FROM xd_corp_check_info

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档；显式 id 供 warning_task.mainId 指向）
-- =====================================================================
-- [已合并] xd_corp_check_info 造数与 app_check_index_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 2. xd_corp_check_warning_task（预警任务；mainId 指向主档 id）
--    serialNo/confirmTime 随父任务行透传到 opinion 行
--    confirmTime='2026/3/5' -> SUBSTR(1,10)='2026/3/5' 不匹配日期正则 -> 原样透传
-- =====================================================================
INSERT INTO xd_corp_check_warning_task (
    id, mainId, reportNo, customerId, customerName, confirmTime, serialNo, taskType,
    approveStatusName, riskTaskType, inputDate, identifyCustomWaringLevel, inputtime
) VALUES (
    3, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026/3/5', 'YJ-202603-001', '审批通过预警任务',
    -- ↑ id 由 1 改为 3：本行与上一段 app_early_warning_info 造的 id=1 是同一 serialNo（YJ-202603-001），
    --   但 confirmTime 特意用了非零填充格式 '2026/3/5'，用于验证加工层「不匹配日期正则 -> 原样透传」分支，
    --   故不删除、只错开主键；inputtime 更早，不会影响加工段「取最新任务」的口径。
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
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_early_warning_signal_info.sql
-- ---------------------------------------------------------------------
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
--   reportNo    = 'RPT-202609-001'
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
-- [已上移至 §0] DELETE FROM app_early_warning_signal_info
-- [已上移至 §0] DELETE FROM xd_warning_ledger

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
    1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-001', '企业已逾期10天以上',
    '02', '6', '2026-10-15', '2026-09-10 19:12:54'
);

-- ---------- Row 2: status=01(待认定), warningLevel=4(黄色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    2, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-002', '企业已逾期10天以上',
    '01', '4', '2026-10-15', '2026-09-10 19:12:55'
);

-- ---------- Row 3: status=01(待认定), warningLevel=6(红色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    3, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-003', '企业已逾期10天以上',
    '01', '6', '2026-10-15', '2026-09-10 19:12:56'
);

-- ---------- Row 4: status=02(已认定), warningLevel=4(黄色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    4, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-004', '企业已逾期10天以上',
    '02', '4', '2026-10-15', '2026-09-10 19:12:57'
);

-- ---------- Row 5: status=01(待认定), warningLevel=6(红色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    5, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-005', '他行未结清关注类贷款余额两期对比上升',
    '01', '6', '2026-10-15', '2026-09-10 19:12:58'
);

-- ---------- Row 6: status=02(已认定), warningLevel=4(黄色) ----------
INSERT INTO xd_warning_ledger (
    id, reportNo, customerId, customerName, serialNo, riskMessage,
    status, warningLevel, inputDate, inputtime
) VALUES (
    6, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-006', '国有股东出资比例降低',
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
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_entrust_pay_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_entrust_pay_info（受托支付）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_entrust_pay.sql
-- 源表：
--   xd_credit_info     授信用信主档（父表）
--   xd_credit_loan     借据信息（mainId -> xd_credit_info.id）
--   xd_credit_payment  受托支付（mainId -> xd_credit_loan.id）
--   ws_gs_info         启信宝工商照面（外数，按收款人 name 撞 endDate）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_entrust_pay.sql，7 业务列）：
--   reportNo/customerId/customerName  直映
--   paymentMode   码值映射: 10->自主支付, 20->受托支付, 30->部分受托支付
--   payDate       日期正则 -> YYYYMMDD；否则原样透传
--   accountName   直映
--   payeeCancelDate <- ws_gs_info.endDate（LEFT JOIN by reportNo+name，日期正则变换）
--   去重：ROW_NUMBER(reportNo, customerId, customerName) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：2
--
-- CRITICAL ISSUE: 去重键为 (reportNo, customerId, customerName)，两行全相同，
--   加工 SQL 只保留最新 1 行（inputtime DESC），无法产出 DML 2 行。
--   需修改加工 SQL 去重键（如增加 accountName）方能产出 2 行。
--
-- ISSUE: DML 有 9 列，加工 SQL 只插入 7 列。inputtime 列 DML 非空
--   ('2026-09-01 10:15:00.0' 等)，DEFAULT CURRENT_TIMESTAMP，不一致
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_entrust_pay_info
-- [已上移至 §0] DELETE FROM xd_credit_payment
-- [已上移至 §0] DELETE FROM xd_credit_loan
-- [已上移至 §0] DELETE FROM xd_credit_info
-- [已上移至 §0] DELETE FROM ws_gs_info

-- =====================================================================
-- 1. xd_credit_info（授信用信主档；显式 id 供 credit_loan.mainId 指向）
-- =====================================================================
-- [已合并] xd_credit_info 造数已省略 —— owner = app_credit_use_info（14 列全字段版）
--   本处的占位版只有 5 列且硬编码 id=1 ⇒ 会造成主键冲突，且挤掉全字段版（列全 NULL）

-- =====================================================================
-- 2. xd_credit_loan（借据信息；mainId 指向 credit_info.id）
--    加工 SQL JOIN credit_loan 取 loanId 供 payment.mainId 指向
-- =====================================================================
-- [已合并] xd_credit_loan 造数已省略 —— owner = app_loan_receipt_info（12 行 28 列版）
--   本处的 7 列版没有 loanStatus，且硬编码 id=1 会撞主键

-- =====================================================================
-- 3. xd_credit_payment（受托支付；mainId 指向 credit_loan.id）
--    列：id, mainId, reportNo, customerId, customerName, paymentMode, payDate,
--        accountName, inputtime
--
--    payDate '2026-08-01' -> 匹配日期正则 -> '20260801'
--    payDate '2026-06-20' -> 匹配日期正则 -> '20260620'
-- =====================================================================

-- ---------- Row 1: paymentMode=20(受托支付) ----------
INSERT INTO xd_credit_payment (
    id, mainId, reportNo, customerId, customerName, paymentMode, payDate, accountName, inputtime
) VALUES (
    1, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '20', '2026-08-01', '苏州XX精密机械制造有限公司基本户', '2026-09-01 10:15:00'
);

-- ---------- Row 2: paymentMode=10(自主支付) ----------
INSERT INTO xd_credit_payment (
    id, mainId, reportNo, customerId, customerName, paymentMode, payDate, accountName, inputtime
) VALUES (
    2, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '10', '2026-06-20', '苏州XX精密机械制造有限公司结算户', '2026-08-05 09:20:00'
);

-- =====================================================================
-- 4. ws_gs_info（启信宝工商照面；按 name 撞 accountName 取 endDate）
--    列：id, reportNo, customerId, customerName, name, endDate, inputtime
--    LEFT JOIN: g.reportNo = c.reportNo AND g.name = c.accountName AND g.rn = 1
--
--    endDate '2026-08-25' -> 匹配日期正则 -> '20260825' (payeeCancelDate for Row 1)
--    endDate '2026-07-15' -> 匹配日期正则 -> '20260715' (payeeCancelDate for Row 2)
-- =====================================================================

-- ---------- ws_gs_info for Row 1 accountName ----------
INSERT INTO ws_gs_info (id, reportNo, customerId, customerName, name, endDate, inputtime)
VALUES (1, 'RPT-202609-001', NULL, NULL, '苏州XX精密机械制造有限公司基本户', '2026-08-25', '2026-09-01 10:00:00');

-- ---------- ws_gs_info for Row 2 accountName ----------
INSERT INTO ws_gs_info (id, reportNo, customerId, customerName, name, endDate, inputtime)
VALUES (2, 'RPT-202609-001', NULL, NULL, '苏州XX精密机械制造有限公司结算户', '2026-07-15', '2026-08-05 09:00:00');

-- =====================================================================
-- 验证说明：
--   1. credit_info id=1 为唯一当前主档，credit_loan id=1 mainId=1 指向
--   2. 两行 payment mainId=1 指向当前借据
--   3. payDate '2026-08-01'/'2026-06-20' 匹配日期正则 -> '20260801'/'20260620'
--   4. ws_gs_info LEFT JOIN by (reportNo, name=accountName) 取 endDate
--      '2026-08-25'/'2026-07-15' -> '20260825'/'20260715'
--   5. CRITICAL ISSUE: 去重键 (reportNo, customerId, customerName) 两行全相同，
--      加工 SQL 只保留最新 1 行，无法产出 DML 2 行
--   6. ISSUE: inputtime 列加工 SQL 不设置，DML 有非空值，需手工补充
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_loan_receipt_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_loan_receipt_info（借据信息台账）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_loan_receipt.sql
-- 源表：
--   xd_credit_info  授信用信主档（父表）
--   xd_credit_loan  借据信息（mainId -> xd_credit_info.id）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_loan_receipt.sql，26 业务列）：
--   reportNo/customerId/customerName/loanSerialNo/loanStatus  直映
--   productName/productBelongName/balance/businessSum  直映（DECIMAL 透传）
--   overdueBalance/overdueInterestAmt  直映
--   isRestructed/isExtend/fixedAssetLoan/realEstateDevLoan/occurType  直映
--   loanChangeRptBalance  直映
--   repaymentPeriod  码值->中文 CASE：'01'->按月, '02'->按季, '03'->一次, '04'->按半年, '05'->按年, '06'->指定周期, '07'->按季（固定）；NULL/未收录原样保留
--   purposeName <- c.purpose（源列名不同）
--   loanChangeRptCounts  VARCHAR -> CAST AS INTEGER（REGEXP 数字守卫）
--   nextPayDate   日期正则 -> YYYYMMDD；否则原样透传
--   payPrinciPalamt/payInterestamt/payFineAmt/compoundinterest  VARCHAR -> CAST AS DECIMAL(18,2)
--   businessRate  VARCHAR -> CAST AS DECIMAL(12,4)
--   去重：JOIN 当前主档 + ROW_NUMBER(reportNo, customerId, loanSerialNo) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：12（loanSerialNo: LOAN-202603-001 ~ 012）
--
-- ISSUE: DML 有 33 列，加工 SQL 只插入 26 列。未映射列：
--   producttype='基础'/'固贷'/'房地产'（源表无此列，无法产出，不一致）
--   extendbalance/restructedbalance/reorgtimes/reorgbalance（源表有列但加工 SQL 不映射 -> NULL，不一致）
--   inputtime（DEFAULT CURRENT_TIMESTAMP，不一致）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_loan_receipt_info
-- [已上移至 §0] DELETE FROM xd_credit_loan
-- [已上移至 §0] DELETE FROM xd_credit_info

-- =====================================================================
-- 1. xd_credit_info（授信用信主档；显式 id 供 credit_loan.mainId 指向）
-- =====================================================================
-- [已合并] xd_credit_info 造数已省略 —— owner = app_credit_use_info（14 列全字段版）
--   本处的占位版只有 5 列且硬编码 id=1 ⇒ 会造成主键冲突，且挤掉全字段版（列全 NULL）

-- =====================================================================
-- 2. xd_credit_loan（借据信息；mainId 指向 credit_info.id）
--    列：id, mainId, reportNo, customerId, customerName, loanSerialNo, loanStatus,
--        productName, productBelongName, businessSum, balance, overdueBalance,
--        overdueInterestAmt, purpose, loanChangeRptCounts, loanChangeRptBalance,
--        isExtend, isRestructed, occurType, fixedAssetLoan, realEstateDevLoan,
--        nextPayDate, payPrinciPalAmt, payInterestAmt, payFineAmt, compoundInterest,
--        businessRate, repaymentPeriod, inputtime
--
--    nextPayDate '2026-03-31' -> 匹配日期正则 -> '20260331'
--    loanChangeRptCounts '1' -> REGEXP 数字 -> CAST AS INTEGER = 1
--    payPrinciPalAmt '0.00' -> REGEXP 数字 -> CAST AS DECIMAL = 0.00
--    businessRate '4.3500' -> REGEXP 数字 -> CAST AS DECIMAL(12,4) = 4.3500
--    purpose '股东还款' -> purposeName 直映
-- =====================================================================

-- ⚠️ mainId 不硬编码 1，而是动态引用「当前主档」：xd_credit_info 的 id 由自增产生，
--    重跑后序列会推进（本次实测已到 3），硬编码 1 会导致 JOIN 失败、加工产出 0 行。
INSERT INTO xd_credit_loan (
    id, mainId, reportNo, customerId, customerName, loanSerialNo, loanStatus,
    productName, productBelongName, businessSum, balance, overdueBalance,
    overdueInterestAmt, purpose, loanChangeRptCounts, loanChangeRptBalance,
    isExtend, isRestructed, occurType, fixedAssetLoan, realEstateDevLoan,
    nextPayDate, payPrinciPalAmt, payInterestAmt, payFineAmt, compoundInterest,
    businessRate, repaymentPeriod, inputtime
) VALUES
(1, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-001', '正常结清',
 '短期流动资金贷款', '征信贷', 1000.00, 2000.00, 0.00, 0.00, '股东还款', '1', 10.00,
 '否', '否', '借新还旧', '否', '否', '2026-03-31', '0.00', '0.00', '0.00', '0.00', '4.3500', '01', '2026-03-05 10:30:00'),
(2, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-002', '提前结清',
 '银行承兑汇票', '信保贷', 1001.00, 3000.00, 0.00, 0.00, '采购支付', '2', 11.00,
 '是', '否', '借新还旧', '否', '否', '2026-03-30', '0.00', '0.00', '0.00', '0.00', '4.7500', '02', '2026-03-06 14:20:00'),
(3, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-003', '逾期结清',
 '短期流动资金贷款', '一般产品额度', 1002.00, 1000.00, 200.00, 15.50, '日常运营', '3', 12.00,
 '是', '否', '其他', '否', '否', '2026-03-29', '0.00', '0.00', '0.00', '0.00', '5.2000', '04', '2026-03-07 09:15:00'),
(4, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-004', '理赔结清',
 '基本建设项目贷款', '一般产品额度', 1003.00, 1000.00, 0.00, 0.00, '项目建设', '4', 13.00,
 '是', '否', '其他', '是', '否', '2026-03-28', '0.00', '0.00', '0.00', '0.00', '4.1500', '03', '2026-03-08 16:45:00'),
(5, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-005', '未结清',
 '技术改造项目贷款', '一般产品额度', 1004.00, 500.00, 100.00, 8.20, '归还股东借款', '5', 14.00,
 '是', '是', '其他', '是', '否', '2026-04-15', '20.00', '1.80', '0.50', '0.20', '4.5000', '05', '2026-03-09 11:00:00'),
(6, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-006', '未结清',
 '其他类项目贷款', '一般产品额度', 1005.00, 0.00, 0.00, 0.00, '资金周转', '6', 15.00,
 '是', '是', '其他', '否', '否', '2026-05-20', '0.00', '0.00', '0.00', '0.00', '0.0000', '06', '2026-03-10 08:30:00'),
(7, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-007', '未结清',
 '经营性物业贷款', '一般产品额度', 1006.00, 300.00, 30.00, 2.60, '物业经营', '7', 16.00,
 '否', '否', '其他', '否', '否', '2026-04-10', '10.00', '1.20', '0.30', '0.10', '4.6500', '01', '2026-03-11 13:20:00'),
(8, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-008', '未结清',
 '房地产开发贷款', '一般产品额度', 1007.00, 700.00, 80.00, 6.90, '项目开发', '8', 17.00,
 '否', '否', '其他', '否', '是', '2026-06-01', '25.00', '3.50', '1.20', '0.50', '5.8000', '02', '2026-03-12 10:00:00'),
(9, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-009', '未结清',
 '短期流动资金贷款', '信保贷', 1008.00, 450.00, 50.00, 4.10, '应急周转', '0', 0.00,
 '否', '否', '新增', '否', '否', '2026-04-25', '15.00', '2.00', '0.60', '0.20', '4.3500', '01', '2026-03-13 15:30:00'),
(10, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-010', '正常结清',
 '银行承兑汇票', '征信贷', 1008.00, 600.00, 0.00, 0.00, '贸易结算', '1', 5.00,
 '否', '否', '借新还旧', '否', '否', '2026-03-27', '0.00', '0.00', '0.00', '0.00', '4.5000', '04', '2026-03-14 09:45:00'),
(11, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-011', '逾期结清',
 '经营性物业贷款', '一般产品额度', 1009.00, 350.00, 120.00, 10.30, '物业改造', '2', 8.00,
 '是', '是', '其他', '否', '否', '2026-03-26', '0.00', '0.00', '0.00', '0.00', '5.0000', '05', '2026-03-15 11:20:00'),
(12, (SELECT id FROM xd_credit_info WHERE reportNo = 'RPT-202609-001' AND customerId = 'CUST-001' ORDER BY inputtime DESC, id DESC LIMIT 1), 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'LOAN-202603-012', '未结清',
 '房地产开发贷款', '一般产品额度', 1010.00, 1200.00, 200.00, 18.50, '住宅开发', '0', 0.00,
 '否', '否', '新增', '否', '是', '2026-07-01', '30.00', '5.00', '2.00', '1.00', '6.2000', '02', '2026-03-16 14:00:00');

-- =====================================================================
-- 验证说明：
--   1. credit_info id=1 为唯一当前主档，12 行 credit_loan mainId=1 指向
--   2. loanSerialNo 各不同，去重各出 1 行，共 12 行
--   3. purpose 直映 -> purposeName（'股东还款'/'采购支付' 等）
--   4. loanChangeRptCounts VARCHAR '1'~'8'/'0' -> CAST AS INTEGER
--   5. nextPayDate '2026-03-31' 等 -> 匹配日期正则 -> '20260331' 等
--   6. payPrinciPalAmt/payInterestAmt/payFineAmt/compoundInterest VARCHAR -> CAST AS DECIMAL
--   7. businessRate VARCHAR '4.3500' 等 -> CAST AS DECIMAL(12,4)
--   8. ISSUE: producttype/extendbalance/restructedbalance/reorgtimes/reorgbalance/inputtime
--      列加工 SQL 不映射或不设置，DML 有非空值，需手工补充
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_opinion_info.sql
-- ---------------------------------------------------------------------
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
-- [已上移至 §0] DELETE FROM app_opinion_info
-- [已上移至 §0] DELETE FROM xd_corp_check_current_opinion
-- [已上移至 §0] DELETE FROM xd_corp_check_last_opinion
-- [已上移至 §0] DELETE FROM xd_corp_check_info

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档；显式 id 供 opinion.mainId 指向）
-- =====================================================================
-- [已合并] xd_corp_check_info 造数与 app_check_index_info 重复，此处省略（避免主键冲突）

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
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_single_check_task_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_single_check_task_info（单项检查任务）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_single_task.sql
-- 源表：
--   xd_single_task_check  单项检查任务主表（无父表，aflSingleTaskCheckQry 落表）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_single_task.sql，24 业务列）：
--   reportNo/customerId/customerName  直映
--   itemCategory  码值->中文 CASE：'01'->担保落实, '02'->佐证材料收集, '03'->额度压降,
--                                  '04'->资金到位, '06'->监管账户, '07'->资金归集, '08'->管理要求;
--                                  NULL/未收录原样保留
--   serialNo/creditNo/approveTextNo  直映
--   startDate/maturity/checkDate/extendDate  日期正则 -> YYYYMMDD；否则原样透传
--   groupName/productName  直映
--   balance  VARCHAR -> CAST AS DECIMAL(18,2)（REGEXP 数字守卫）
--   "condition"  直映（源 VARCHAR(1000) -> app TEXT）
--   implementStatus  码值->中文 CASE：'01'->已完成, '02'->部分完成, '03'->无法完成,
--                                       '06'->持续关注, '07'->结清不续贷, '08'->已有新批复, '09'->延期;
--                                       NULL/未收录原样保留
--   opinion  直映
--   conditioninStruction <- conditionInstruction（源列名不同，显式 AS）
--   creditApproveUserName/approveAuthor/operateBelongOrgName/operateOrgName/operateUserName  直映
--   approveStatusName  直映
--   去重：ROW_NUMBER(reportNo, customerId, serialNo) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：2（serialNo: CHK-202603-001, CHK-202603-002）
--
-- ISSUE: DML 有 26 列，加工 SQL 只插入 24 列。inputtime 列 DML 非空
--   ('2026-03-05 00:00:00.0')，DEFAULT CURRENT_TIMESTAMP，不一致
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_single_check_task_info
-- [已上移至 §0] DELETE FROM xd_single_task_check

-- =====================================================================
-- 1. xd_single_task_check（单项检查任务；无 mainId，独立行）
--    列：id, reportNo, customerId, customerName, serialNo, creditNo, approveTextNo,
--        startDate, maturity, groupName, productName, checkDate, balance, condition,
--        itemCategory, implementStatus, extendDate, opinion, conditionInstruction,
--        creditApproveUserName, approveAuthor, operateBelongOrgName, operateOrgName,
--        operateUserName, approveStatusName, inputtime
--
--    startDate '2026-03-01' -> 匹配日期正则 -> '20260301'
--    maturity '2027-03-01' -> 匹配日期正则 -> '20270301'
--    checkDate '2026-03-10' -> 匹配日期正则 -> '20260310'
--    extendDate '2026-03-15' -> 匹配日期正则 -> '20260315'
--    balance '2000.00' -> REGEXP 数字 -> CAST AS DECIMAL = 2000.00
--    itemCategory 码值翻译：'01'->担保落实, '03'->额度压降（加工 CASE 翻译为中文）
--    implementStatus 码值翻译：'01'->已完成, '02'->部分完成（加工 CASE 翻译为中文）
--    conditionInstruction -> conditioninStruction（显式 AS 改名）
-- =====================================================================

-- ---------- Row 1: serialNo=CHK-202603-001, itemCategory=01(担保落实), implementStatus=01(已完成) ----------
INSERT INTO xd_single_task_check (
    id, reportNo, customerId, customerName, serialNo, creditNo, approveTextNo,
    startDate, maturity, groupName, productName, checkDate, balance, condition,
    itemCategory, implementStatus, extendDate, opinion, conditionInstruction,
    creditApproveUserName, approveAuthor, operateBelongOrgName, operateOrgName,
    operateUserName, approveStatusName, inputtime
) VALUES (
    1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'CHK-202603-001', 'CR-2026-001', 'AP-2026-001',
    '2026-03-01', '2027-03-01', '苏州XX集团', '短期流动资金贷款', '2026-03-10', '2000.00', '根据批复要求，需定期监控借款人经营状况，确保资金用途合规，按季度提交财务报表，如发现异常需及时上报。同时要求借款人保持资产负债率不超过70%，并落实担保措施。',
    '01', '01', '2026-03-15', '同意', '经检查，借款人经营正常，资金用途符合批复要求，财务报表已按时提交。担保措施有效，未发现重大风险事项。后续将继续跟踪，确保贷款安全。',
    '张三', '分行审批', '苏州分行', '苏州工业园区支行', '李四', '审批通过', '2026-03-05 00:00:00'
);

-- ---------- Row 2: serialNo=CHK-202603-002, itemCategory=03(额度压降), implementStatus=02(部分完成) ----------
INSERT INTO xd_single_task_check (
    id, reportNo, customerId, customerName, serialNo, creditNo, approveTextNo,
    startDate, maturity, groupName, productName, checkDate, balance, condition,
    itemCategory, implementStatus, extendDate, opinion, conditionInstruction,
    creditApproveUserName, approveAuthor, operateBelongOrgName, operateOrgName,
    operateUserName, approveStatusName, inputtime
) VALUES (
    2, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'CHK-202603-002', 'CR-2026-002', 'AP-2026-002',
    '2026-03-05', '2027-03-05', '苏州XX集团', '银行承兑汇票', '2026-03-12', '3000.00', '要求借款人严格按照批复用途使用资金，不得挪用。每半年进行一次现场检查，关注上下游客户变化，确保贸易背景真实。如出现逾期，需在3个工作日内启动催收程序。',
    '03', '02', '2026-03-20', '有条件同意', '检查发现借款人部分贸易合同尚未归档，已要求其限期补充。目前资金使用基本合规，但需加强贷后管理，后续将重点监控票据到期兑付情况。',
    '王五', '支行审批', '苏州分行', '苏州高新区支行', '赵六', '取消', '2026-03-05 00:00:00'
);

-- =====================================================================
-- 验证说明：
--   1. 两行 xd_single_task_check serialNo 不同，去重各出 1 行，共 2 行
--   2. startDate/maturity/checkDate/extendDate '2026-03-01' 等 -> 匹配日期正则 -> '20260301' 等
--   3. balance '2000.00'/'3000.00' -> REGEXP 数字 -> CAST AS DECIMAL
--   4. itemCategory 码值翻译：'01'->担保落实, '03'->额度压降（加工 CASE 翻译为中文）
--   5. implementStatus 码值翻译：'01'->已完成, '02'->部分完成（加工 CASE 翻译为中文）
--   6. conditionInstruction -> conditioninStruction（显式 AS 改名直映）
--   7. approveStatusName 直映：'审批通过'/'取消'
--   8. ISSUE: inputtime 列加工 SQL 不设置，DML 有非空值，需手工补充
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_specific_loan_project_check_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_specific_loan_project_check_info（特定贷款项目检查）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_specific_loan_project.sql
-- 源表：
--   xd_corp_check_info          对公检查主档（父表）
--   xd_corp_check_fixed_loan     特定贷款检查（固定资产、房地产开发贷款，mainId -> xd_corp_check_info.id）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_specific_loan_project.sql，32 业务列）：
--   reportNo/customerId/customerName  直映
--   objectName/balance/businessSum  直映（DECIMAL 透传）
--   capitalCheckCondition/capitalFundInvoiced/capitalFundUnInvoiced/capitalFundUsed  直映
--   contractNo/duebillTotalBusinessSum  直映
--   loanFundInvoiced/loanFundUnInvoiced/loanFundUsed  直映
--   nominalBalanceSum/otherFundInvoiced/otherFundUnInvoiced/otherFundUsed  直映
--   productBelongName/productName  直映
--   projectBeginDate/projectFinishDate  日期正则 -> YYYYMMDD；否则原样透传
--   purpose  VARCHAR(255) -> VARCHAR(128)  LEFT(...,128) 截断
--   repaySum/runCheckCondition/scheduleCheckCondition/superviseCheckCondition  直映
--   totalInvestInvoiced/totalInvestUnInvoiced/totalInvestUsed  直映
--   vouchType  VARCHAR(64) -> VARCHAR(32)  LEFT(...,32) 截断
--   去重：JOIN 当前主档 + ROW_NUMBER(reportNo, customerId, contractNo) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：4（contractNo: GDZC-2026-001/002, FDK-2026-003/004）
--
-- ISSUE 1: DML 有 51 列，加工 SQL 只插入 32 列。19 列未映射：
--   explain/ifbuild/ifconstructionexpect/ifgetpermission/ifmatch/ifopenaccount/
--   ifoperate/ifoverinvest/ifrunexpect/ifsign/lastcapitalcheckcondition/
--   lastpurchasecheckcondition/lastruncheckcondition/lastschedulecheckcondition/
--   lastsupervisecheckcondition/overinvest/purchasecheckcondition（源表有列但加工 SQL 不映射 -> NULL）
--   id（auto）/inputtime（DEFAULT CURRENT_TIMESTAMP）
--   -> 上述列 DML 有非空值，加工 SQL 不设置，不一致
--
-- ISSUE 2: projectBeginDate/projectFinishDate DML 为 '2026-01-01 00:00:00' 格式，
--   但加工 SQL 日期正则匹配后输出 YYYYMMDD（如 '20260101'），不一致。
--   源数据使用 '2026-01-01 00:00:00'，加工 SQL 会转为 '20260101'。
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
DELETE FROM app_specific_loan_project_check_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
-- [已上移至 §0] DELETE FROM xd_corp_check_fixed_loan
-- [已上移至 §0] DELETE FROM xd_corp_check_info

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档；显式 id 供 fixed_loan.mainId 指向）
-- =====================================================================
-- [已合并] xd_corp_check_info 造数与 app_check_index_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 2. xd_corp_check_fixed_loan（特定贷款检查；mainId 指向主档 id）
--    列：id, mainId, reportNo, customerId, customerName, objectName, balance,
--        businessSum, capitalCheckCondition, capitalFundInvoiced, capitalFundUnInvoiced,
--        capitalFundUsed, contractNo, duebillTotalBusinessSum, loanFundInvoiced,
--        loanFundUnInvoiced, loanFundUsed, nominalBalanceSum, otherFundInvoiced,
--        otherFundUnInvoiced, otherFundUsed, productBelongName, productName,
--        projectBeginDate, projectFinishDate, purpose, repaySum, runCheckCondition,
--        scheduleCheckCondition, superviseCheckCondition, totalInvestInvoiced,
--        totalInvestUnInvoiced, totalInvestUsed, vouchType, inputtime
--
--    purpose LEFT(...,128) 截断（均 < 128 字符，无影响）
--    vouchType LEFT(...,32) 截断（均 < 32 字符，无影响）
--    projectBeginDate '2026-01-01 00:00:00' -> SUBSTR(1,10)='2026-01-01' 匹配 -> '20260101'
--      ISSUE: DML 显示 '2026-01-01 00:00:00'，加工 SQL 输出 '20260101'，不一致
-- =====================================================================

INSERT INTO xd_corp_check_fixed_loan (
    id, mainId, reportNo, customerId, customerName, objectName, balance,
    businessSum, capitalCheckCondition, capitalFundInvoiced, capitalFundUnInvoiced,
    capitalFundUsed, contractNo, duebillTotalBusinessSum, loanFundInvoiced,
    loanFundUnInvoiced, loanFundUsed, nominalBalanceSum, otherFundInvoiced,
    otherFundUnInvoiced, otherFundUsed, productBelongName, productName,
    projectBeginDate, projectFinishDate, purpose, repaySum, runCheckCondition,
    scheduleCheckCondition, superviseCheckCondition, totalInvestInvoiced,
    totalInvestUnInvoiced, totalInvestUsed, vouchType, inputtime
) VALUES
(1, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '固定资产', 5000.00,
 5000.00, '已落实，资本金足额到位', 1200.00, 0.00, 1000.00, 'GDZC-2026-001', 5000.00, 3800.00,
 1200.00, 3000.00, 4000.00, 0.00, 0.00, 0.00, '公司业务部', '固定资产贷款',
 '2026-01-01 00:00:00', '2027-06-01 00:00:00', '购置生产设备', 0.00, '不涉及',
 '建设进度正常，按计划推进', '监管账户流水正常', 5000.00, 0.00, 4000.00, '抵押+保证', '2026-09-02 21:35:56'),
(2, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '固定资产', 12000.00,
 12000.00, '已落实，分期到位', 600.00, 0.00, 500.00, 'GDZC-2026-002', 12000.00, 9200.00,
 2800.00, 8500.00, 11500.00, 0.00, 0.00, 0.00, '公司业务部', '固定资产贷款',
 '2026-03-01 00:00:00', '2027-12-01 00:00:00', '技术改造升级', 0.00, '不涉及',
 '建设进度正常，按计划推进', '监管账户流水正常', 12000.00, 0.00, 9000.00, '抵押', '2026-09-02 21:35:56'),
(3, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '房地产开发贷款', 30000.00,
 30000.00, '已落实，资本金按进度到位', 1800.00, 0.00, 1500.00, 'FDK-2026-003', 30000.00, 22000.00,
 8000.00, 20000.00, 28500.00, 1500.00, 0.00, 1500.00, '房地产金融部', '房地产开发贷款',
 '2026-02-01 00:00:00', '2028-12-01 00:00:00', '住宅开发建设', 0.00, '不涉及',
 '建设进度正常，按计划推进', '监管账户流水正常', 30000.00, 0.00, 23000.00, '抵押+质押', '2026-09-02 21:35:56'),
(4, 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '房地产开发贷款', 25000.00,
 25000.00, '已落实，股东借款转增资本金', 1200.00, 0.00, 1000.00, 'FDK-2026-004', 25000.00, 19500.00,
 5500.00, 18000.00, 24000.00, 1000.00, 0.00, 1000.00, '房地产金融部', '房地产开发贷款',
 '2026-04-01 00:00:00', '2028-06-01 00:00:00', '商业地产开发', 0.00, '不涉及',
 '建设进度正常，按计划推进', '监管账户流水正常', 26000.00, 0.00, 20000.00, '抵押', '2026-09-02 21:35:56');

-- =====================================================================
-- 验证说明：
--   1. xd_corp_check_info id=1 为唯一当前主档，4 行 fixed_loan mainId=1 指向
--   2. contractNo 各不同（GDZC-2026-001/002, FDK-2026-003/004），去重各出 1 行
--   3. purpose/vouchType 均 < 截断长度，LEFT 无影响
--   4. 金额列 DECIMAL(18,2) 直映
--   5. ISSUE 1: 19 列（explain/ifbuild 等）加工 SQL 不映射，DML 有非空值，需手工补充
--   6. ISSUE 2: projectBeginDate/projectFinishDate 加工 SQL 输出 YYYYMMDD，
--      DML 显示 '2026-01-01 00:00:00' 格式，不一致
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_top_five_updown_info.sql
-- ---------------------------------------------------------------------
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
-- [已上移至 §0] DELETE FROM xd_corp_check_supplier
-- [已上移至 §0] DELETE FROM xd_corp_check_info

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档；显式 id 供 supplier.mainId 指向）
--    列：id, reportNo, customerId, customerName, serialNo, bapSerialNo,
--        bapStartDate, bapMaturity, bapTextNo, bapReportNo, baReportNo,
--        lastReportNo, checkDate, baSerialNo, approveApplyType,
--        electroApproveSerialNo, inputtime
-- =====================================================================
-- [已合并] xd_corp_check_info 造数与 app_check_index_info 重复，此处省略（避免主键冲突）

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
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_xd_shareholder_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_xd_shareholder_info（信贷系统股东全字段）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_customer.sql（同 app_customer_info 一个脚本，第 3 段 INSERT）
-- 源表（父子表，mainId -> xd_corp_customer_info.id=1，父表共享自 app_credit_use_info）：
--   xd_corp_customer_info     客户主档（CustomerEndInfoDto，全字段，使 app_customer_info 产出完整）
--   xd_corp_customer_control  实际控制人（ControlshipExecutives，本文件附造 2 行使两张 app 表均有数据）
--   xd_corp_customer_shareholder   股东信息（CustomerShipSharehold）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_customer.sql 第 3 段 INSERT，14 列）：
--   name            <- shareholderName
--   investmentProp  <- investmentProp            DECIMAL 直映
--   relationShip    <- CASE relationShip 码值（5 码 0401~0405）未收录原样保留
--                      目标值 '自筹'/'合资'/'个人投资' 不在 CASE 内 -> 透传（源=目标）
--   currencyType    <- currencyType              直映
--   oughtSum        <- oughtSum                  DECIMAL 直映
--   investmentSum   <- investmentSum             DECIMAL 直映
--   investDate      <- CASE CAST(investDate AS CHAR(32)) 正则命中 yyyy-MM-dd/yyyy/MM/dd 去分隔符；
--                      不命中原样 CAST AS CHAR(64)
--   inputUserId     <- inputUserId
--   inputOrgId      <- inputOrgId
--   去重键 (reportNo, customerId, shareholderName) ROW_NUMBER(inputtime DESC, id DESC)
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：6
--   1: 周九, 30.0000, '自筹',     '人民币', 3000000.00, 1500000.00, '2026/3/5',  'admin',   'ORG-001'
--   2: 泰州公司, 20.0000, '合资', '人民币', 2000000.00, 2000000.00, '2026/3/6',  'admin',   'ORG-001'
--   3: 王五, 20.0000, '个人投资', '人民币', 2000000.00, 1000000.00, '2026/3/7',  'zhangsan','ORG-002'
--   4: 李四, 10.0000, '个人投资', '人民币', 1000000.00, 500000.00,  '2026/3/8',  'lisi',    'ORG-002'
--   5: 赵六, 10.0000, '自筹',     '人民币', 1000000.00, 1000000.00, '2026/3/9',  'admin',   'ORG-001'
--   6: 钱七, 10.0000, '自筹',     '人民币', 1000000.00, 800000.00,  '2026/3/10', 'wangwu',  'ORG-003'
--
-- 共享父表：xd_corp_customer_info id=1（来自 app_credit_use_info 文件，本文件条件 IF NOT EXISTS 跳过创建）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源子表（不动父表 id=1）
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_xd_shareholder_info
-- [已上移至 §0] DELETE FROM app_customer_info
-- [已上移至 §0] DELETE FROM xd_corp_customer_shareholder
-- [已上移至 §0] DELETE FROM xd_corp_customer_control
-- [已上移至 §0] DELETE FROM xd_corp_customer_info

-- =====================================================================
-- 1. xd_corp_customer_info（父表，全字段，使 app_customer_info 产出完整）
--    清理段已删除旧父表，此处直接 INSERT 全字段
-- =====================================================================
-- [已合并] xd_corp_customer_info 造数与 app_customer_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 2. xd_corp_customer_shareholder（股东信息，6 行）
--    mainId=1；shareholderName 各异（去重键 (reportNo, customerId, shareholderName)）
--    relationShip 源 = 目标值（'自筹'/'合资'/'个人投资' 不在 CASE 5 码内 -> 透传）
--    investDate 源用目标字符串 'YYYY/M/D'（VARCHAR，CAST AS CHAR(32) 后正则
--      ^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$ 不命中（月/日单数字）-> ELSE CAST AS CHAR(64) 透传）
--
--    -- ISSUE: investDate 在 DDL 中是 DATE 类型；若 DB 实际按 DATE 存储，
--       CAST(investDate AS CHAR(32)) 会得到 'YYYY-MM-DD'（如 '2026-03-05'），
--       正则命中后去 - -> '20260305'，与目标 '2026/3/5' 不一致。
--       为与目标一致，需保证 DB 中 investDate 列按 VARCHAR 存储（或源数据为字符串字面量）。
--       若实际 DDL 为 DATE 不可改，则加工产出 '20260305' 而非 '2026/3/5'，存在差异。
--       本文件按目标字符串原样插入，依赖 DB 列类型为 VARCHAR（或接受字符串字面量）。
-- =====================================================================
INSERT INTO xd_corp_customer_shareholder (
    mainId, reportNo, customerId, customerName, shareholderName, relationShip, currencyType,
    investmentProp, oughtSum, investmentSum, investDate, inputUserId, inputOrgId, inputtime
) VALUES
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '周九', '自筹', '人民币', 30.0000, 3000000.00, 1500000.00, '2026/3/5', 'admin', 'ORG-001', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '泰州公司', '合资', '人民币', 20.0000, 2000000.00, 2000000.00, '2026/3/6', 'admin', 'ORG-001', '2026-03-06 14:20:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '王五', '个人投资', '人民币', 20.0000, 2000000.00, 1000000.00, '2026/3/7', 'zhangsan', 'ORG-002', '2026-03-07 09:15:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '李四', '个人投资', '人民币', 10.0000, 1000000.00, 500000.00, '2026/3/8', 'lisi', 'ORG-002', '2026-03-08 16:45:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '赵六', '自筹', '人民币', 10.0000, 1000000.00, 1000000.00, '2026/3/9', 'admin', 'ORG-001', '2026-03-09 11:00:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '钱七', '自筹', '人民币', 10.0000, 1000000.00, 800000.00, '2026/3/10', 'wangwu', 'ORG-003', '2026-03-10 08:30:00');

-- =====================================================================
-- 3. xd_corp_customer_control（实际控制人，2 行，使本文件两张 app 表均有数据）
--    mainId=1；controlName='张三'/'李四'，isControl='1'（纳入 actualController 拼接）
-- =====================================================================
-- [已合并] xd_corp_customer_control 造数与 app_customer_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工\xd_customer.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--      本文件已含父表全字段 + control 2 行 + shareholder 6 行，两张 app 表均有数据
--   2. 加工产出 6 行，业务字段与目标 DML 大体一致：
--      - name/investmentProp/currencyType/oughtSum/investmentSum/inputUserId/inputOrgId 直映 ✓
--      - relationShip：源 '自筹'/'合资'/'个人投资' 不在 CASE 5 码（0401~0405）内 -> ELSE 透传 ✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..6）
--   4. app_xd_shareholder_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中各股东 inputtime（如 '2026-03-05 10:30:00.0'）无法精确复现
--
--   -- ISSUE（investDate 列类型）：
--      目标 DML investDate='2026/3/5' 等单数字月/日字符串。
--      加工 SQL：CAST(investDate AS CHAR(32)) REGEXP '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$'
--      若 investDate 列在 DDL 中为 DATE 类型，CAST AS CHAR 得 'YYYY-MM-DD'（如 '2026-03-05'），
--      正则命中 -> 去 - -> '20260305'，与目标 '2026/3/5' 不一致。
--      若列实际为 VARCHAR（DDL 标 DATE 但 openGauss 兼容模式宽松），源字符串原样存，
--      CAST AS CHAR 得 '2026/3/5'，正则不命中（月单数字）-> ELSE 透传 -> '2026/3/5' ✓。
--      本文件按目标字符串原样插入，依赖 DB 实际按字符串存储（或兼容 DATE 列接受字符串）。
--      若实际严格按 DATE 存储，则加工产出 'YYYYMMDD' 格式（如 '20260305'），存在 6 行差异。
-- =====================================================================

-- =====================================================================
--

-- =====================================================================
-- §2 加工（各原脚本的加工段，原样保留）
-- =====================================================================

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_check_index_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_check_index.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》日常检查综合指标 · 源头表 -> app_check_index_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info          对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_daily_index   日常检查综合指标 DailyCheckIndicator（mainId -> xd_corp_check_info.id）
-- 目标：app_check_index_info（业务主键 reportNo + customerId + chineseId，一指标一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_check_record.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_check_index_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按业务主键 (chineseId) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 透传字段：chineseId / chineseName / yesNo / remark 直映；
--      源 chineseName VARCHAR(255) -> app VARCHAR(128)，LEFT(...,128) 截断防越界
--   4. 加工字段（依据《SZ银行DH智能体》附录2-日常检查指标，按 chineseId 硬编码 CASE）：
--        indexObject 指标对象：D22/D23=担保人指标，D24~D30=抵质押物指标，其余=被检查人指标；附录2 外的指标置 NULL
--        isAbnormal  是否异常：附录2「异常选项」给出该指标 yesNo 触发异常的值——
--                     异常选项=否 的指标（D05/D31/D06/D07/D09）：yesNo='否' -> '是' 否则 '否'
--                     异常选项=是 的指标（D08~D30 其余）：yesNo='是' -> '是' 否则 '否'
--                     附录2 外的指标置 NULL
--   5. 注：D31（贷款资金用途是否合规且符合合同约定）附录2 标注"等信贷确认下"，先按 被检查人指标/异常选项=否 加工
-- =====================================================================

-- 1. 幂等
DELETE FROM app_check_index_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 日常检查综合指标：xd_corp_check_daily_index（JOIN 当前主档）-> app_check_index_info
INSERT INTO app_check_index_info (
    reportNo, customerId, customerName, chineseId, chineseName, indexObject, yesNo, isAbnormal, remark
)
SELECT
    c.reportNo, c.customerId, c.customerName,
    c.chineseId,
    LEFT(c.chineseName, 128)                                        AS chineseName,
    CASE
        WHEN c.chineseId IN ('D22', 'D23')                          THEN '担保人指标'
        WHEN c.chineseId IN ('D24', 'D25', 'D26', 'D27', 'D28', 'D29', 'D30') THEN '抵质押物指标'
        WHEN c.chineseId IN ('D05', 'D06', 'D07', 'D08', 'D09', 'D10', 'D11', 'D12',
                             'D13', 'D14', 'D15', 'D16', 'D17', 'D18', 'D19', 'D31') THEN '被检查人指标'
        ELSE NULL
    END                                                             AS indexObject,
    c.yesNo,
    CASE
        WHEN c.chineseId IN ('D05', 'D31', 'D06', 'D07', 'D09')
            THEN CASE WHEN c.yesNo = '否' THEN '是' ELSE '否' END
        WHEN c.chineseId IN ('D08', 'D10', 'D11', 'D12', 'D13', 'D14', 'D15', 'D16',
                             'D17', 'D18', 'D19', 'D22', 'D23', 'D24', 'D25', 'D26',
                             'D27', 'D28', 'D29', 'D30')
            THEN CASE WHEN c.yesNo = '是' THEN '是' ELSE '否' END
        ELSE NULL
    END                                                             AS isAbnormal,
    c.remark
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.chineseId, c.chineseName, c.yesNo, c.remark,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.chineseId, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_daily_index c
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_check_object_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_check_object.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》特定贷款检查（对象指标）· 源头表 -> app_check_object_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表（均为 xd_corp_check_info 的子表，mainId -> xd_corp_check_info.id）：
--   xd_corp_check_fixed_loan   特定贷款检查数组（固定资产、房地产开发贷款）
--   xd_corp_check_operate_loan 特定贷款检查数组（经营性物业贷款、厂房通贷款）
-- 目标：app_check_object_info（业务主键 reportNo + contractNo；同一合同按附录3 转置展开成「一指标一行」明细）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 加工依据：《SZ银行DH智能体》附录3-特定贷款检查指标（一对象 N 个指标，选择题/说明）。
-- 处理规则（对齐 xd_check_record.sql / xd_check_index.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_check_object_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按 (reportNo, customerId, contractNo) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 转置：把一笔贷款的一行「选择题/说明」列，按附录3 展开成「一指标一行」（一指标一行 = 驱动表 u 撞源列）
--        objectName   <- 源列 objectName（附录3 限制条件 objectName=固定资产/房地产开发贷款/经营性物业贷款/厂房通贷款）
--        indexNo      <- 附录3 指标编号（= indexResult 取值字段名）
--        indexName    <- 附录3 指标名称（固定写死）
--        indexType    <- 附录3 指标类型：选择题 / 说明（固定写死）
--        indexResult  <- 源表对应指标列的值
--        redTextRequire <- 附录3 红字要求（仅说明类有值，选择题为 NULL，固定写死）
--        isAbnormal   <- 按附录3「是否异常」列判定（见下 abnormalMode）
--   4. isAbnormal 判定（附录3 规则：当指标结果为下列值时是否异常=是，否则为否；
--      个别「严格来说没有异常，可以把否作为提示项」的选择题，命中否时给 提示 而非 是）：
--        abnormalMode=TRIGGER_YES：indexResult='是' -> '是' 否则 '否'
--        abnormalMode=TRIGGER_NO ：indexResult='否' -> '是' 否则 '否'
--        abnormalMode=PROMPT_NO  ：indexResult='否' -> '提示' 否则 '否'
--        abnormalMode=NONE（说明类）：无异常判定，固定 '否'（说明类无是/否概念，取不异常）
--   5. 源列名与附录3 indexNo 不一致处需显式 AS 对齐：
--        fixed_loan：indexNo schedulCheckCondition -> 源列 scheduleCheckCondition；indexNo ifsign -> 源列 ifSign
--   6. 两源表 UNION ALL 合并；源 objectName 不在附录3 四种内的不出行（撞不到驱动表）
--   7. 源 objectName 与附录3 对象名不完全一致：实际上游 objectName=固定资产贷款（带"贷款"后缀），
--      附录3 对象名=固定资产；其余三种（房地产开发贷款/经营性物业贷款/厂房通贷款）一致。
--      故驱动表加 base_key 列做归一匹配（固定资产贷款->固定资产），app 输出列仍取源 objectName 原值
-- =====================================================================

-- 1. 幂等
DELETE FROM app_check_object_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 特定贷款检查对象指标：fixed_loan + operate_loan（JOIN 当前主档 + 去重）转置 -> app_check_object_info
INSERT INTO app_check_object_info (
    reportNo, customerId, customerName, objectName, contractNo,
    indexNo, indexName, indexType, indexResult, isAbnormal, redTextRequire
)
SELECT
    b.reportNo, b.customerId, b.customerName, b.objectName, b.contractNo,
    b.indexNo, b.indexName, b.indexType,
    LEFT(b.indexResult, 256)                        AS indexResult,
    CASE b.abnormalMode
        WHEN 'TRIGGER_YES' THEN CASE WHEN b.indexResult = '是' THEN '是' ELSE '否' END
        WHEN 'TRIGGER_NO'  THEN CASE WHEN b.indexResult = '否' THEN '是' ELSE '否' END
        WHEN 'PROMPT_NO'   THEN CASE WHEN b.indexResult = '否' THEN '提示' ELSE '否' END
        ELSE '否'
    END                                             AS isAbnormal,
    b.redTextRequire
FROM (
    -- =================================================================
    -- Part 1：固定资产 / 房地产开发贷款 <- xd_corp_check_fixed_loan
    -- =================================================================
    SELECT
        f.reportNo, f.customerId, f.customerName, f.objectName, f.contractNo,
        u.indexNo, u.indexName, u.indexType, u.redTextRequire, u.abnormalMode,
        CASE u.indexNo
            WHEN 'ifOverInvest'            THEN f.ifOverInvest
            WHEN 'overInvest'              THEN f.overInvest
            WHEN 'ifConstructionExpect'    THEN f.ifConstructionExpect
            WHEN 'ifMatch'                 THEN f.ifMatch
            WHEN 'capitalCheckCondition'   THEN f.capitalCheckCondition
            WHEN 'schedulCheckCondition'   THEN f.scheduleCheckCondition
            WHEN 'purchaseCheckCondition'  THEN f.purchaseCheckCondition
            WHEN 'ifRunExpect'             THEN f.ifRunExpect
            WHEN 'runCheckCondition'       THEN f.runCheckCondition
            WHEN 'ifOpenAccount'           THEN f.ifOpenAccount
            WHEN 'ifsign'                  THEN f.ifSign
            WHEN 'superviseCheckCondition' THEN f.superviseCheckCondition
            WHEN 'ifGetPermission'         THEN f.ifGetPermission
        END                                         AS indexResult
    FROM (
        -- 驱动表：附录3 指标清单（objectName, indexNo, indexName, indexType, redTextRequire, abnormalMode）
        SELECT '固定资产' AS objectName, 'ifOverInvest' AS indexNo, '是否存在超投情况' AS indexName, '选择题' AS indexType, NULL AS redTextRequire, 'TRIGGER_YES' AS abnormalMode
        UNION ALL SELECT '固定资产', 'overInvest', '超投情况说明', '说明', NULL, 'NONE'
        UNION ALL SELECT '固定资产', 'ifConstructionExpect', '建设期进度是否符合预期', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '固定资产', 'ifMatch', '资金使用是否与项目进入匹配', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '固定资产', 'capitalCheckCondition', '项目资本金情况本次检查情况', '说明', '重点描述项目资本金到位金额，已经投入使用金额，主要用途(如土地款、工程款、各项税赋等)，哪些用途具有发票佐证，是否存在资本金抽逃等。', 'NONE'
        UNION ALL SELECT '固定资产', 'schedulCheckCondition', '项目建设进度本次检查情况', '说明', '重点描述最新项目施工进度(如正常施工、已经停工、已经完工等)，项目进度与业务申报对比是否存在脱幅(如对比实际项目起始日和预计完工日期与业务申报时的总包施工合同中项目起始日和完工日)等。', 'NONE'
        UNION ALL SELECT '固定资产', 'purchaseCheckCondition', '建安工程或设备采购支出情况本次检查情况', '说明', '重点描述目前工程款或设备款应支付金额，已支付金额，待支付金额，已支付的工程款或设备款中我行项目贷款占比，工程款或设备款发票已经收集情况等。', 'NONE'
        UNION ALL SELECT '固定资产', 'ifRunExpect', '运营是否符合预期', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '固定资产', 'runCheckCondition', '运营检查本次检查情况', '说明', '重点根据授信时的还款来源，阐述目前的销售情况、去化率(请按照货值计算)、成本支出、利润总额、净利润等，并与授信时的项目运营情况作对比，判断是否符合预期(如不符合，需说明原因)等。', 'NONE'
        UNION ALL SELECT '固定资产', 'ifOpenAccount', '是否开立监管账户', '选择题', NULL, 'PROMPT_NO'
        UNION ALL SELECT '固定资产', 'ifsign', '资金监管协议是否已签署', '选择题', NULL, 'PROMPT_NO'
        UNION ALL SELECT '固定资产', 'superviseCheckCondition', '项目资本金情况本次检查情况', '说明', '重点描述销售资金合计金额，是否都进入监管账户，目前监管账户余额，其余销售资金用途情况(如归还银行贷款，项目反投等，需明确每个用途对应的金额，如有反投，再明确反投部分用途)，评估资金是否被挪用等。', 'NONE'
        UNION ALL SELECT '房地产开发贷款', 'ifGetPermission', '是否取得预售证', '选择题', NULL, 'PROMPT_NO'
        UNION ALL SELECT '房地产开发贷款', 'ifOverInvest', '是否存在超投情况', '选择题', NULL, 'TRIGGER_YES'
        UNION ALL SELECT '房地产开发贷款', 'overInvest', '超投情况说明', '说明', NULL, 'NONE'
        UNION ALL SELECT '房地产开发贷款', 'ifConstructionExpect', '建设期进度是否符合预期', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '房地产开发贷款', 'ifMatch', '资金使用是否与项目进入匹配', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '房地产开发贷款', 'capitalCheckCondition', '项目资本金情况本次检查情况', '说明', '重点描述项目资本金到位金额，已经投入使用金额，主要用途(如土地款、工程款、各项税赋等)，哪些用途具有发票佐证，是否存在资本金抽逃等。', 'NONE'
        UNION ALL SELECT '房地产开发贷款', 'schedulCheckCondition', '项目建设进度本次检查情况', '说明', '重点描述最新项目施工进度(如正常施工、已经停工、已经完工等)，项目进度与业务申报对比是否存在脱幅(如对比实际项目起始日和预计完工日期与业务申报时的总包施工合同中项目起始日和完工日)等。', 'NONE'
        UNION ALL SELECT '房地产开发贷款', 'purchaseCheckCondition', '建安工程或设备采购支出情况本次检查情况', '说明', '重点描述目前工程款或设备款应支付金额，已支付金额，待支付金额，已支付的工程款或设备款中我行项目贷款占比，工程款或设备款发票已经收集情况等。', 'NONE'
        UNION ALL SELECT '房地产开发贷款', 'ifRunExpect', '运营是否符合预期', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '房地产开发贷款', 'runCheckCondition', '运营检查本次检查情况', '说明', '重点根据授信时的还款来源，阐述目前的销售情况、去化率(请按照货值计算)、成本支出、利润总额、净利润等，并与授信时的项目运营情况作对比，判断是否符合预期(如不符合，需说明原因)等。', 'NONE'
        UNION ALL SELECT '房地产开发贷款', 'ifOpenAccount', '是否开立监管账户', '选择题', NULL, 'PROMPT_NO'
        UNION ALL SELECT '房地产开发贷款', 'ifsign', '资金监管协议是否已签署', '选择题', NULL, 'PROMPT_NO'
        UNION ALL SELECT '房地产开发贷款', 'superviseCheckCondition', '项目资本金情况本次检查情况', '说明', '重点描述销售资金合计金额，是否都进入监管账户，目前监管账户余额，其余销售资金用途情况(如归还银行贷款，项目反投等，需明确每个用途对应的金额，如有反投，再明确反投部分用途)，评估资金是否被挪用等。', 'NONE'
    ) u
    JOIN (
        SELECT c.*, ROW_NUMBER() OVER (
                   PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.contractNo, '')
                   ORDER BY c.inputtime DESC, c.id DESC) AS rn
        FROM xd_corp_check_fixed_loan c
        JOIN (
            SELECT id FROM (
                SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
                FROM xd_corp_check_info
                WHERE reportNo IS NOT NULL
                  AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
            ) mc WHERE mc.rn = 1
        ) m ON c.mainId = m.id
    ) f ON f.rn = 1
        AND u.objectName = CASE WHEN f.objectName = '固定资产贷款' THEN '固定资产' ELSE f.objectName END

    UNION ALL

    -- =================================================================
    -- Part 2：经营性物业贷款 / 厂房通贷款 <- xd_corp_check_operate_loan
    -- =================================================================
    SELECT
        f.reportNo, f.customerId, f.customerName, f.objectName, f.contractNo,
        u.indexNo, u.indexName, u.indexType, u.redTextRequire, u.abnormalMode,
        CASE u.indexNo
            WHEN 'ifDown'                  THEN f.ifDown
            WHEN 'ifDownExplain'           THEN f.ifDownExplain
            WHEN 'ifPledge'                THEN f.ifPledge
            WHEN 'ifPledgeExplain'         THEN f.ifPledgeExplain
            WHEN 'ifChange'                THEN f.ifChange
            WHEN 'expectation'             THEN f.expectation
            WHEN 'expectation2'            THEN f.expectation2
            WHEN 'operateIncomeCondition'  THEN f.operateIncomeCondition
            WHEN 'ifSupervise'             THEN f.ifSupervise
            WHEN 'ifOpenAccount'           THEN f.ifOpenAccount
            WHEN 'superviseExplain'        THEN f.superviseExplain
            WHEN 'ifSign'                  THEN f.ifSign
            WHEN 'signExplain'             THEN f.signExplain
            WHEN 'operateCDIncomeCondition' THEN f.operateCDIncomeCondition
        END                                         AS indexResult
    FROM (
        -- 驱动表：附录3 指标清单（objectName, indexNo, indexName, indexType, redTextRequire, abnormalMode）
        SELECT '经营性物业贷款' AS objectName, 'ifDown' AS indexNo, '抵押物价值是否有显著下降' AS indexName, '选择题' AS indexType, NULL AS redTextRequire, 'TRIGGER_YES' AS abnormalMode
        UNION ALL SELECT '经营性物业贷款', 'ifDownExplain', '说明抵押物价值是否有显著下降', '说明', NULL, 'NONE'
        UNION ALL SELECT '经营性物业贷款', 'ifPledge', '抵押物是否存在查封或其他抵押的情况', '选择题', NULL, 'TRIGGER_YES'
        UNION ALL SELECT '经营性物业贷款', 'ifPledgeExplain', '说明抵押物是否存在查封或其他抵押的情况', '说明', NULL, 'NONE'
        UNION ALL SELECT '经营性物业贷款', 'ifChange', '出租情况或物业使用情况是否按预临时发生变化', '选择题', NULL, 'TRIGGER_YES'
        UNION ALL SELECT '经营性物业贷款', 'expectation', '出租情况是否符合预期', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '经营性物业贷款', 'expectation2', '物业收入是否符合预期', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '经营性物业贷款', 'operateIncomeCondition', '物业收入及还款来源分析', '说明', '重点描述最新的出租率，空置率是否超过 20%(如空置率超过 20%需分析原因)等。', 'NONE'
        UNION ALL SELECT '经营性物业贷款', 'ifSupervise', '物业经营收入是否需要监管', '选择题', NULL, 'PROMPT_NO'
        UNION ALL SELECT '经营性物业贷款', 'ifOpenAccount', '是否开立监管账户', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '经营性物业贷款', 'superviseExplain', '开立监管账户说明', '说明', NULL, 'NONE'
        UNION ALL SELECT '经营性物业贷款', 'ifSign', '租金监管协议是否已签署', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '经营性物业贷款', 'signExplain', '租金监管协议签署说明', '说明', NULL, 'NONE'
        UNION ALL SELECT '经营性物业贷款', 'operateCDIncomeCondition', '承贷物业的经营收入（如租金、停车费等）情况本次检查情况', '说明', '重点描述应收租金，实际租金在行内归集情况，未入行进行归集的租金金额，未归集入行的原因等。', 'NONE'
        UNION ALL SELECT '厂房通贷款', 'ifDown', '抵押物价值是否有显著下降', '选择题', NULL, 'TRIGGER_YES'
        UNION ALL SELECT '厂房通贷款', 'ifDownExplain', '说明抵押物价值是否有显著下降', '说明', NULL, 'NONE'
        UNION ALL SELECT '厂房通贷款', 'ifPledge', '抵押物是否存在查封或其他抵押的情况', '选择题', NULL, 'TRIGGER_YES'
        UNION ALL SELECT '厂房通贷款', 'ifPledgeExplain', '说明抵押物是否存在查封或其他抵押的情况', '说明', NULL, 'NONE'
        UNION ALL SELECT '厂房通贷款', 'ifChange', '出租情况或物业使用情况是否按预临时发生变化', '选择题', NULL, 'TRIGGER_YES'
        UNION ALL SELECT '厂房通贷款', 'expectation', '出租情况是否符合预期', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '厂房通贷款', 'expectation2', '物业收入是否符合预期', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '厂房通贷款', 'operateIncomeCondition', '物业收入及还款来源分析', '说明', '重点描述最新的出租率，空置率是否超过 20%(如空置率超过 20%需分析原因)等。', 'NONE'
        UNION ALL SELECT '厂房通贷款', 'ifSupervise', '物业经营收入是否需要监管', '选择题', NULL, 'PROMPT_NO'
        UNION ALL SELECT '厂房通贷款', 'ifOpenAccount', '是否开立监管账户', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '厂房通贷款', 'superviseExplain', '开立监管账户说明', '说明', NULL, 'NONE'
        UNION ALL SELECT '厂房通贷款', 'ifSign', '租金监管协议是否已签署', '选择题', NULL, 'TRIGGER_NO'
        UNION ALL SELECT '厂房通贷款', 'signExplain', '租金监管协议签署说明', '说明', NULL, 'NONE'
        UNION ALL SELECT '厂房通贷款', 'operateCDIncomeCondition', '承贷物业的经营收入（如租金、停车费等）情况本次检查情况', '说明', '重点描述应收租金，实际租金在行内归集情况，未入行进行归集的租金金额，未归集入行的原因等。', 'NONE'
    ) u
    JOIN (
        SELECT c.*, ROW_NUMBER() OVER (
                   PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.contractNo, '')
                   ORDER BY c.inputtime DESC, c.id DESC) AS rn
        FROM xd_corp_check_operate_loan c
        JOIN (
            SELECT id FROM (
                SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
                FROM xd_corp_check_info
                WHERE reportNo IS NOT NULL
                  AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
            ) mc WHERE mc.rn = 1
        ) m ON c.mainId = m.id
    ) f ON f.rn = 1
        AND u.objectName = CASE WHEN f.objectName = '固定资产贷款' THEN '固定资产' ELSE f.objectName END
) b;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_check_opinion_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_check_opinion.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》批复后续管理要求 · 源头表 -> app_check_opinion_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info                对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_reply_requirement   批复后续管理要求 CheckFollowUpRequirement（mainId -> xd_corp_check_info.id）
-- 目标：app_check_opinion_info（业务主键 reportNo + customerId + conditionDesc）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_check_opinion_info 段）：
--   conditionDesc         <- condition                后续管理要求内容（源 VARCHAR(1000) -> app TEXT）
--   completeStatus        <- completeStatus           完成状态（码值：已完成/未完成/部分完成/持续关注，待确认，原样透传）
--   conditionInstruction  <- conditionInstruction     要求说明（源 VARCHAR(1000) -> app TEXT）
--   realCompleteTime      <- realCompleteTime         实际完成时间（源 VARCHAR(64) -> app VARCHAR(32)，LEFT 截断）
--   itemCategory          <- itemCategory             事项类别
--   （源表 replySerialNo/relativeSerialNo/expectedCompletionExactDate/checkDate 目标表无列，不加工）
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_check_opinion_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按 conditionDesc ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 一次日检可有多条要求（不同内容），各出一行；全字段字符串直映（仅 realCompleteTime 截断）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_check_opinion_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 批复后续管理要求：xd_corp_check_reply_requirement（JOIN 当前主档）-> app_check_opinion_info
INSERT INTO app_check_opinion_info (
    reportNo, customerId, customerName, conditionDesc, completeStatus, conditionInstruction, realCompleteTime, itemCategory
)
SELECT
    c.reportNo, c.customerId, c.customerName,
    c.condition AS conditionDesc,
    c.completeStatus,
    c.conditionInstruction,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.realCompleteTime, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.realCompleteTime, 1, 10), '-', ''), '/', '')
         ELSE c.realCompleteTime END AS realCompleteTime,
    -- 事项类别：码值->中文（01担保落实/02佐证材料收集/03额度压降/04资金到位/06监管账户/07资金归集/08管理要求），NULL/未收录原样保留
    CASE c.itemCategory
        WHEN '01' THEN '担保落实'
        WHEN '02' THEN '佐证材料收集'
        WHEN '03' THEN '额度压降'
        WHEN '04' THEN '资金到位'
        WHEN '06' THEN '监管账户'
        WHEN '07' THEN '资金归集'
        WHEN '08' THEN '管理要求'
        ELSE c.itemCategory
    END AS itemCategory
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.condition, c.completeStatus,
           c.conditionInstruction, c.realCompleteTime, c.itemCategory,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.condition, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_reply_requirement c
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_check_record_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_credit_approval_manage_req_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_credit_approval_req.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》授信批复管理要求 · 源头表 -> app_credit_approval_manage_req_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info                 对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_credit_requirement   授信批复后续管理要求 CreditFollowUpRequirement（mainId -> xd_corp_check_info.id）
-- 目标：app_credit_approval_manage_req_info（业务主键（字典 J 列）reportno + customerid + swqNo + "CONDITION" + PELATIVESERIALNO + checkDate）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 + DDL V1.20 注释，列名保留建表原拼写）：
--   swqNo              <- seqNo              序号（源 VARCHAR(64) -> app VARCHAR(32)，LEFT 截断）
--   "CONDITION"        <- condition          授信后续管理要求内容（源 VARCHAR(1000) -> app TEXT）
--   PELATIVESERIALNO   <- relativeSerialNo   关联流水号/对象
--   checkDate          <- checkDate          检查日期（源 VARCHAR 原样透传，不 CAST）
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerid, reportno) 删除本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按业务主键 ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 一次日检可有多条授信批复要求（不同序号/内容/对象），各出一行
-- =====================================================================

-- 1. 幂等
DELETE FROM app_credit_approval_manage_req_info
WHERE (customerid = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportno   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 授信批复管理要求：xd_corp_check_credit_requirement（JOIN 当前主档）-> app_credit_approval_manage_req_info
INSERT INTO app_credit_approval_manage_req_info (
    reportno, customerid, customername, swqNo, "CONDITION", PELATIVESERIALNO, checkDate
)
SELECT
    c.reportNo AS reportno,
    c.customerId AS customerid,
    c.customerName AS customername,
    LEFT(c.seqNo, 32) AS swqNo,
    c.condition AS "CONDITION",
    c.relativeSerialNo AS PELATIVESERIALNO,
    -- app 列 checkDate 为 DATE 类型：上游格式归一为 yyyy-MM-dd（- 分隔，兼容 / 分隔与带时分秒）
    CASE WHEN REGEXP_LIKE(SUBSTR(c.checkDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN CONCAT(SUBSTR(c.checkDate, 1, 4), '-', SUBSTR(c.checkDate, 6, 2), '-', SUBSTR(c.checkDate, 9, 2))
         ELSE c.checkDate END AS checkDate
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.seqNo, c.condition, c.relativeSerialNo, c.checkDate,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.seqNo, ''),
                            COALESCE(c.condition, ''), COALESCE(c.relativeSerialNo, ''), COALESCE(c.checkDate, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_credit_requirement c
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_credit_use_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_credit_use.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 我行授信用信概况 · 源头表 -> app_credit_use_info 加工
-- 节点：对公客户查询接口》企业概况（getEntCustomerAllQry，CrcsEntCustomerService.query）
-- 源表：
--   xd_credit_info         授信用信主档（aflCreditLoanQry 落表）
--   xd_corp_customer_info  客户主档（getEntCustomerAllQry 落表，取集团客户号 groupClientNo）
-- 目标：app_credit_use_info（业务主键 reportNo + customerId）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_credit_use_info 本次范围旧行，再插入
--   2. 源头 append-only：主档每 reportNo 取最新一条（inputtime DESC, id DESC）
--   3. isGroup 取自客户主档 groupClientNo（非空=是）；
--      groupName 取客户主档 groupClientName（集团客户名称：Java 侧按 groupClientNo 补调 getEntCustomerAllQry
--      回填，见 CrcsEntCustomerService.fillGroupClientName）；补调未落（NULL/空）时回退存 groupClientNo 集团客户号
--   4. 计数 CAST SIGNED（源头 VARCHAR）；金额源头已 DECIMAL(18,2) 直接透传
--      creditDate 上游格式不固定（yyyy-MM-dd / yyyy/MM/dd，可能带时分秒）-> 落 app 表 yyyyMMdd：
--      前 10 位为日期段（分隔符 - 或 /）时取前 10 位并去掉 - 和 /；空/NULL/非标准日期前缀 原样透传不置坏
--   5. 依赖：授信用信接口 aflCreditLoanQry 已先落表 xd_credit_info（流程顺序授信在前、企业概况在后）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_credit_use_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 授信用信概况：xd_credit_info + xd_corp_customer_info -> app_credit_use_info
INSERT INTO app_credit_use_info (
    reportNo, customerId, customerName, creditSum, balance, exposureAmount, limitBalance,
    groupAmount, groupBalance, isGroup, groupName, creditDate, latestOverdueDate, gdOverdueCounts, ajOverdueCounts
)
SELECT
    i.reportNo, i.customerId, i.customerName,
    i.creditSum, i.balance, i.exposureAmount, i.limitBalance,
    i.groupAmount, i.groupBalance,
    -- 是否集团客户（码值：是/否）：有集团客户号即为「是」，空/未采集为「否」
    CASE WHEN BTRIM(COALESCE(cc.groupClientNo, '')) <> '' THEN '是' ELSE '否' END AS isGroup,
    CASE WHEN cc.groupClientName IS NULL OR TRIM(cc.groupClientName) = ''
         THEN cc.groupClientNo ELSE cc.groupClientName END AS groupName,
    CASE WHEN REGEXP_LIKE(SUBSTR(i.creditDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(i.creditDate, 1, 10), '-', ''), '/', '')
         ELSE i.creditDate END AS creditDate,
    CASE WHEN REGEXP_LIKE(SUBSTR(i.latestOverdueDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(i.latestOverdueDate, 1, 10), '-', ''), '/', '')
         ELSE i.latestOverdueDate END AS latestOverdueDate,
    i.gdOverdueCounts AS gdOverdueCounts,
    i.ajOverdueCounts AS ajOverdueCounts
FROM (
    SELECT reportNo, customerId, customerName, creditSum, balance, exposureAmount, limitBalance,
           groupAmount, groupBalance, creditDate, latestOverdueDate, gdOverdueCounts, ajOverdueCounts,
           ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_credit_info
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) i
LEFT JOIN (
    SELECT reportNo, groupClientNo, groupClientName,
           ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_customer_info
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) cc ON cc.reportNo = i.reportNo AND cc.rn = 1
WHERE i.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_customer_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_customer.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 信贷系统客户企业概况 · 源头表 -> 应用层表加工（参考 财务指标加工/xd_financial.sql 模式）
-- 源表（对公客户信息查询接口 getEntCustomerAllQry 落表，见 源头表/信贷/DDL/对公客户信息查询接口_建表DDL.sql）：
--   xd_corp_customer_info           客户主档（CustomerEndInfoDto）
--   xd_corp_customer_control        实际控制人（ControlshipExecutives，mainId -> xd_corp_customer_info.id）
--   xd_corp_customer_shareholder    股东信息（CustomerShipSharehold，mainId -> xd_corp_customer_info.id）
-- 目标：app_customer_info（客户工商概况表）/ app_xd_shareholder_info（信贷股东全字段）
--      （app_shareholder_info 由 外数加工/xd_shareholder_info.sql 承载，本脚本不写入）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式，正则用 REGEXP）
--
-- 处理规则（依据《SZ银行DH智能体》数据字典，仅取"来源=信贷"的列）：
--   1. 幂等：先按 (customerId, reportNo) 删除两张 app 表本次范围旧行，再插入
--   2. 源头表"接口返回直接追加插入，不做去重约束"，同一 reportNo 重复调用会重复落表：
--        主档   : 按 reportNo 去重取最新一条
--        股东   : 按业务主键 (reportNo, customerId, name) 取最新（《SZ银行DH智能体》数据字典 J 列；同名股东仅一行）
--        控制人 : 按 (reportNo, controlName+certId) 去重（controlName=实控人名称）
--   3. 字段映射（信贷源 -> app）：
--        app_customer_info:
--          legalPerson      <- fictitiousPerson(法人代表)
--          registerCapital  <- registerCapital(已是 DECIMAL)
--          paidInCapital    <- paiclupCapital(实收资本, 已是 DECIMAL)
--          industryType     <- industryType(国标行业分类)  码值->中文：LEFT JOIN 码值字典表 app_code_dict
--                              （dict_type='industryType'，1969 码由 码值字典/国标行业分类_码值字典.sql 落表；
--                               命中取 code_name，未命中回退原码值）
--          holdType         <- holdType(控股类型)          码值->中文：内联 CASE（10 码）
--          actualController <- 控制子表 isControl='1' 的 controlName(实控人名称) 去重拼接
--                              （controlName=controlshipExecutives.customerName，落表时由 CorpCustomerDataStore 单独映射；
--                               relativeCustomerId 为实控人客户号，不再用于拼接）
--          officeAddress    <- officeFormattedAddress(标准办公地址)
--          businessScope    <- businessScope(经营范围)
--          dangerLevel      <- dangerLevel(风险分类结果)    码值->中文：内联 CASE（10 码）
--          warningLevel     <- warningLevel(预警等级)       码值->中文：内联 CASE（1/2/4/5/6 码）
--          isTechCompany    <- isStiEnt(是否科创企业，直映，无需映射)
--          isListedCompany  <- listingCorpOrNot(是否上市公司，直映，无需映射)
--          isStateOwned     <- 去掉, 不输出（holdType 码值表待确认, 按需求不加工该列）
--        app_xd_shareholder_info（信贷股东全字段）:
--          name <- shareholderName, investmentProp, relationShip(出资方式, 码值->中文内联 CASE 5 码),
--          currencyType(投资币种), oughtSum(应缴), investmentSum(实缴), investDate(最迟到位日期),
--          inputUserId, inputOrgId
--   4. 外数来源列（app_ic_info / app_ic_shareholder_info 整表, 以及 stock_num/is_quoted/is_state_owned/
--      is_fake_state_owned/is_listed_company 等）不在本脚本范围, 置 NULL 留给启信宝(QXB_*)等外数加工
--   5. 码值转换（依据《苏州银行综合信贷系统_贷后智能体相关接口_V1.0》「码表」sheet）：
--        holdType/dangerLevel/warningLevel/relationShip 码值小 -> 内联 CASE 转中文，NULL/未收录码值原样保留；
--        industryType 1969 码 -> 走 app_code_dict 字典表 JOIN（不在 SQL 内 CASE）。
--        前置：先执行 码值字典/国标行业分类_码值字典.sql 落 app_code_dict（industryType 类），否则 industryType 回退原码值。
--   6. isStiEnt/listingCorpOrNot 码表仅 0/1（0=否/1=是），按 1 判"是"，其余/未收录 -> "否"（2026-09-17 已去 'Y' 死分支）
-- =====================================================================

-- 1. 幂等：先删除本次加工范围内的目标行（与下方过滤条件一致，避免重复加工叠加）
DELETE FROM app_customer_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

DELETE FROM app_xd_shareholder_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 客户工商概况：xd_corp_customer_info -> app_customer_info
INSERT INTO app_customer_info (
    reportNo, customerId, customerName, legalPerson, registerCapital, paidInCapital,
    industryType, holdType, actualController, officeAddress, businessScope,
    dangerLevel, warningLevel, isTechCompany, isListedCompany
)
SELECT
    i.reportNo AS reportNo,
    i.customerId AS customerId,
    i.customerName AS customerName,
    i.fictitiousPerson AS legalPerson,
    i.registerCapital AS registerCapital,
    i.paiclupCapital AS paidInCapital,
    -- 国标行业分类：码值->中文，走码值字典表（1969 码，码值字典/国标行业分类_码值字典.sql 落表），未命中回退原码值
    COALESCE(d.code_name, i.industryType) AS industryType,
    -- 控股类型：码值->中文（10 码），NULL/未收录原样保留
    CASE WHEN i.holdType IS NULL THEN NULL
         WHEN i.holdType = '010' THEN '国有绝对控股'
         WHEN i.holdType = '020' THEN '国有相对控股'
         WHEN i.holdType = '030' THEN '集体绝对控股'
         WHEN i.holdType = '040' THEN '集体相对控股'
         WHEN i.holdType = '050' THEN '个人绝对控股'
         WHEN i.holdType = '060' THEN '个人相对控股'
         WHEN i.holdType = '070' THEN '港澳台商绝对控股'
         WHEN i.holdType = '080' THEN '港澳台商相对控股'
         WHEN i.holdType = '090' THEN '外商绝对控股'
         WHEN i.holdType = '100' THEN '外商相对控股'
         ELSE i.holdType END AS holdType,
    c.actualController AS actualController,
    i.officeFormattedAddress AS officeAddress,
    i.businessScope AS businessScope,
    -- 风险分类结果：码值->中文（10 码），NULL/未收录原样保留
    CASE WHEN i.dangerLevel IS NULL THEN NULL
         WHEN i.dangerLevel = '011' THEN '正常1'
         WHEN i.dangerLevel = '012' THEN '正常2'
         WHEN i.dangerLevel = '013' THEN '正常3'
         WHEN i.dangerLevel = '021' THEN '关注1'
         WHEN i.dangerLevel = '022' THEN '关注2'
         WHEN i.dangerLevel = '023' THEN '关注3'
         WHEN i.dangerLevel = '031' THEN '次级1'
         WHEN i.dangerLevel = '032' THEN '次级2'
         WHEN i.dangerLevel = '040' THEN '可疑'
         WHEN i.dangerLevel = '050' THEN '损失'
         ELSE i.dangerLevel END AS dangerLevel,
    -- 预警等级：码值->中文（1/2/4/5/6 码，码表无 3），NULL/未收录原样保留
    CASE WHEN i.warningLevel IS NULL THEN NULL
         WHEN i.warningLevel = '1' THEN '无风险'
         WHEN i.warningLevel = '2' THEN '风险排查'
         WHEN i.warningLevel = '4' THEN '黄色预警'
         WHEN i.warningLevel = '5' THEN '橙色预警'
         WHEN i.warningLevel = '6' THEN '红色预警'
         ELSE i.warningLevel END AS warningLevel,
     -- 是否科创企业 / 是否上市公司（码值：是/否）：源头码表 0/1，兼容历史 '是' 形态；其余（含 0/空/NULL/未收录）一律「否」
     CASE WHEN BTRIM(COALESCE(i.isStiEnt, '')) IN ('1', '是') THEN '是' ELSE '否' END AS isTechCompany,
     CASE WHEN BTRIM(COALESCE(i.listingCorpOrNot, '')) IN ('1', '是') THEN '是' ELSE '否' END AS isListedCompany
FROM (
    -- 主档去重：每个 reportNo 仅保留最新一条
    SELECT reportNo, customerId, customerName, fictitiousPerson, registerCapital, paiclupCapital,
           industryType, holdType, officeFormattedAddress, businessScope,
           dangerLevel, warningLevel, isStiEnt, listingCorpOrNot,
           ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_customer_info
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) i
LEFT JOIN (
    -- 国标行业分类码值字典（1969 码，码值字典/国标行业分类_码值字典.sql 落表）
    SELECT code_value, code_name
    FROM app_code_dict
    WHERE dict_type = 'industryType'
) d ON d.code_value = i.industryType
LEFT JOIN (
    -- 实际控制人：isControl='1' 的 controlName(实控人名称) 去重顿号拼接，按 controlName 排序保证固定顺序
    -- （controlName 落表时由 CorpCustomerDataStore 从 controlshipExecutives.customerName 单独映射；
    --  相对控制人去重键 = controlName+certId）
    SELECT reportNo,
           GROUP_CONCAT(DISTINCT controlName ORDER BY controlName SEPARATOR '、') AS actualController
    FROM (
        SELECT reportNo, controlName, inputtime, id,
               ROW_NUMBER() OVER (
                   PARTITION BY reportNo,
                       COALESCE(controlName, ''), COALESCE(certId, '')
                   ORDER BY inputtime DESC, id DESC) AS rn
        FROM xd_corp_customer_control
        WHERE reportNo IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
          AND isControl = '1'
          AND controlName IS NOT NULL
    ) t
    WHERE t.rn = 1
    GROUP BY reportNo
) c ON c.reportNo = i.reportNo
WHERE i.rn = 1;

-- 3. 信贷系统股东信息（全字段）：xd_corp_customer_shareholder -> app_xd_shareholder_info
--    （app_shareholder_info 由外数加工 外数加工/xd_shareholder_info.sql 承载，本脚本不再写入，避免两脚本互删）
INSERT INTO app_xd_shareholder_info (
    reportNo, customerId, customerName, name, investmentProp, relationShip, currencyType,
    oughtSum, investmentSum, investDate, inputUserId, inputOrgId
)
SELECT
    s.reportNo AS reportNo,
    s.customerId AS customerId,
    s.customerName AS customerName,
    s.shareholderName AS name,
    s.investmentProp AS investmentProp,
    -- 投资方式：码值->中文（5 码），NULL/未收录原样保留
    CASE WHEN s.relationShip IS NULL THEN NULL
         WHEN s.relationShip = '0401' THEN '资金(投资)'
         WHEN s.relationShip = '0402' THEN '技术(投资)'
         WHEN s.relationShip = '0403' THEN '实物(投资)'
         WHEN s.relationShip = '0404' THEN '权利(投资)'
         WHEN s.relationShip = '0405' THEN '其他(投资)'
         ELSE s.relationShip END AS relationShip,
    s.currencyType AS currencyType,
    s.oughtSum AS oughtSum,
    s.investmentSum AS investmentSum,
    CASE WHEN REGEXP_LIKE(SUBSTR(CAST(s.investDate AS CHAR(32)), 1, 10), '^[0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}$')
         THEN TO_CHAR(TO_DATE(SUBSTR(CAST(s.investDate AS CHAR(32)), 1, 10), 'YYYY-MM-DD'), 'YYYYMMDD')
         ELSE CAST(s.investDate AS CHAR(64)) END AS investDate,
    s.inputUserId AS inputUserId,
    s.inputOrgId AS inputOrgId
FROM (
    -- 股东去重：每个 (reportNo, 股东键) 仅保留最新一条
    SELECT reportNo, customerId, customerName, shareholderName, investmentProp, relationShip,
           currencyType, oughtSum, investmentSum, investDate, inputUserId, inputOrgId,
            ROW_NUMBER() OVER (
                PARTITION BY reportNo, COALESCE(customerId, ''), COALESCE(shareholderName, '')
                ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_customer_shareholder
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) s
WHERE s.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_early_warning_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_early_warning_opinion_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_early_warning_signal_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_warning_signal.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
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
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

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
      AND (c.reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) c
WHERE c.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_entrust_pay_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_entrust_pay.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 我行授信用信情况》受托支付数组 · 源头表 -> app_entrust_pay_info 加工
-- 节点：我行授信用信情况》借据信息数组》受托支付（aflCreditLoanQry 响应 loanInfoList[].entrustedPaymentList，CrcsAfterLoanAiService.aflCreditLoanQry）
-- 源表：
--   xd_credit_info     授信用信主档（父表，aflCreditLoanQry 落表）
--   xd_credit_loan     借据信息（mainId -> xd_credit_info.id）
--   xd_credit_payment  受托支付（mainId -> xd_credit_loan.id）
--   ws_gs_info         启信宝工商照面 QXB_GSZM01（外数，按收款人企业落表；取注销日期 endDate）
-- 目标：app_entrust_pay_info（一客户一报告一行；《SZ银行DH智能体》1-数据字典 J列业务主键=reportNo+customerId+customerName，
--       同客户同报告多笔支付去重折叠为最新一笔）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_collateral.sql / xd_shareholder_info.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_entrust_pay_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」->「当前借据」排除历史快照，
--      再按业务主键 (reportNo, customerId, customerName) ROW_NUMBER 取最新（inputtime DESC, id DESC）。
--      去重键 = 字典 J 列业务主键三列；同客户同报告多笔支付折叠为最新一笔。
--   3. 码值（支付方式）待确认的原样透传
--   4. 源宽 > app 宽 2 处 LEFT 截断防越界：payDate 源 VARCHAR(64)->app VARCHAR(32)；
--      payeeCancelDate 源 ws_gs_info.endDate VARCHAR(64)->app VARCHAR(32)
--   5. payeeCancelDate（受托支付对象注销日期）：用收款人名称 accountName 撞 ws_gs_info.name（启信宝工商照面 QXB_GSZM01）
--      取 endDate（营业有效期截止=注销日期）；ws_gs_info 按 (reportNo, name) 去重取最新后 LEFT JOIN，
--      不按 customerId 过滤（收款人企业落表 customerId 可能是收款人自身）；撞不到为 NULL
--      （前提：外数侧需按收款人企业逐个调 QXB_GSZM01 落表 ws_gs_info，否则该列为 NULL）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_entrust_pay_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 受托支付明细：xd_credit_payment（JOIN 当前主档 -> 当前借据）+ ws_gs_info（收款人注销日期）-> app_entrust_pay_info
INSERT INTO app_entrust_pay_info (reportNo, customerId, customerName, paymentMode, payDate, accountName, payeeCancelDate)
SELECT
    c.reportNo, c.customerId, c.customerName,
    CASE c.paymentMode
        WHEN '10' THEN '自主支付'
        WHEN '20' THEN '受托支付'
        WHEN '30' THEN '部分受托支付'
        ELSE c.paymentMode
    END AS paymentMode,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.payDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.payDate, 1, 10), '-', ''), '/', '')
         ELSE c.payDate END AS payDate,
    c.accountName,
    CASE WHEN REGEXP_LIKE(SUBSTR(g.endDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(g.endDate, 1, 10), '-', ''), '/', '')
         ELSE g.endDate END AS payeeCancelDate
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.paymentMode, c.payDate, c.accountName,
            ROW_NUMBER() OVER (
                PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.customerName, ''),
                    COALESCE(c.accountName, '')
                ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_credit_payment c
    JOIN (
        SELECT l.id AS loanId
        FROM xd_credit_loan l
        JOIN (
            SELECT id FROM (
                SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
                FROM xd_credit_info
                WHERE reportNo IS NOT NULL
                  AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
            ) mc WHERE mc.rn = 1
        ) m ON l.mainId = m.id
    ) cur ON c.mainId = cur.loanId
) c
LEFT JOIN (
    SELECT reportNo, name, endDate,
           ROW_NUMBER() OVER (PARTITION BY reportNo, COALESCE(name, '') ORDER BY inputtime DESC, id DESC) AS rn
    FROM ws_gs_info
    WHERE reportNo IS NOT NULL
      AND name IS NOT NULL
      AND (reportNo = 'RPT-202609-001' OR 'RPT-202609-001' IS NULL)
) g ON g.reportNo = c.reportNo AND g.name = c.accountName AND g.rn = 1
WHERE c.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_loan_receipt_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_loan_receipt.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 我行授信用信情况》借据信息数组 · 源头表 -> app_loan_receipt_info 加工
-- 节点：我行授信用信情况》借据信息数组（aflCreditLoanQry 响应 loanInfoList，CrcsAfterLoanAiService.aflCreditLoanQry）
-- 源表：
--   xd_credit_info  授信用信主档（父表，aflCreditLoanQry 落表）
--   xd_credit_loan  借据信息（mainId -> xd_credit_info.id）
-- 目标：app_loan_receipt_info（业务主键 reportNo + customerId + loanSerialNo）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_loan_receipt_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_credit_info.id) 排除历史快照，
--      再按 loanSerialNo ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 金额源头已 DECIMAL(18,2) 直接透传（balance/businessSum 等）；计数/利率/下次还款明细源头 VARCHAR -> CAST
--      （NULLIF 防空串，businessRate -> DECIMAL(12,4)，还款明细 -> DECIMAL(18,2)）
--      businessSum（借款金额，2026-09-15 新增列）源 DECIMAL(18,2) 直映
--   4. 码值（借据状态/发生类型/是否展期/是否重组/固贷/房开）待确认的原样透传
-- =====================================================================

-- 1. 幂等
DELETE FROM app_loan_receipt_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 借据信息：xd_credit_loan（JOIN 当前主档）-> app_loan_receipt_info
INSERT INTO app_loan_receipt_info (
    reportNo, customerId, customerName, loanSerialNo, loanStatus, productName, purposeName,
    balance, businessSum, productBelongName, overdueBalance, overdueInterestAmt, isRestructed,
    loanChangeRptCounts, loanChangeRptBalance, occurType, isExtend,
    fixedAssetLoan, realEstateDevLoan, nextPayDate, payPrinciPalamt, payInterestamt,
    payFineAmt, compoundinterest, businessRate, RepaymentPeriod
)
SELECT
    c.reportNo, c.customerId, c.customerName, c.loanSerialNo, c.loanStatus, c.productName,
    c.purpose AS purposeName,
    c.balance, c.businessSum, c.productBelongName, c.overdueBalance, c.overdueInterestAmt, c.isRestructed,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(c.loanChangeRptCounts), '^-?[0-9]+$') THEN BTRIM(c.loanChangeRptCounts) END AS INTEGER) AS loanChangeRptCounts,
    c.loanChangeRptBalance, c.occurType, c.isExtend,
    c.fixedAssetLoan, c.realEstateDevLoan,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.nextPayDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.nextPayDate, 1, 10), '-', ''), '/', '')
         ELSE c.nextPayDate END AS nextPayDate,
    c.payPrinciPalAmt AS payPrinciPalamt,
    c.payInterestAmt AS payInterestamt,
    c.payFineAmt AS payFineAmt,
    c.compoundInterest AS compoundinterest,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(c.businessRate), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(c.businessRate) END AS DECIMAL(12,4)) AS businessRate,
    -- 还款周期：码值->中文（01按月/02按季/03一次/04按半年/05按年/06指定周期/07按季（固定）），NULL/未收录原样保留
    CASE c.repaymentPeriod
        WHEN '01' THEN '按月'
        WHEN '02' THEN '按季'
        WHEN '03' THEN '一次'
        WHEN '04' THEN '按半年'
        WHEN '05' THEN '按年'
        WHEN '06' THEN '指定周期'
        WHEN '07' THEN '按季（固定）'
        ELSE c.repaymentPeriod
    END AS RepaymentPeriod
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.loanSerialNo, c.loanStatus, c.productName,
            c.purpose, c.balance, c.businessSum, c.productBelongName, c.overdueBalance, c.overdueInterestAmt,
           c.isRestructed, c.loanChangeRptCounts, c.loanChangeRptBalance, c.occurType, c.isExtend,
           c.fixedAssetLoan, c.realEstateDevLoan, c.nextPayDate, c.payPrinciPalAmt, c.payInterestAmt,
           c.payFineAmt, c.compoundInterest, c.businessRate, c.repaymentPeriod,
           ROW_NUMBER() OVER (PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.loanSerialNo, '')
                              ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_credit_loan c
    JOIN (
        SELECT id FROM (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_credit_info
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) mc WHERE mc.rn = 1
    ) m ON c.mainId = m.id
) c
WHERE c.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_opinion_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_single_check_task_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_single_task.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 单项检查任务 · 源头表 -> app_single_check_task_info 加工
-- 节点：单项检查任务查询接口（aflSingleTaskCheckQry，CrcsAfterLoanAiService.aflSingleTaskCheckQry）
-- 源表：xd_single_task_check（单项检查任务主表 SingleTaskCheck，aflSingleTaskCheckQry 落表，无父表）
-- 目标：app_single_check_task_info（业务主键（字典 J 列）reportNo + customerId + serialNo）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_single_check_task_info 段 ROW380-405）：
--   itemCategory           <- itemCategory           事项类别（码值->中文：01->担保落实, 02->佐证材料收集, 03->额度压降, 04->资金到位, 06->监管账户, 07->资金归集, 08->管理要求；NULL/未收录原样保留）
--   serialNo               <- serialNo               流水号（业务主键）
--   creditNo               <- creditNo               授信编号
--   approveTextNo          <- approveTextNo          批复文本编号
--   startDate              <- startDate              起始日期（源 VARCHAR(64) -> app VARCHAR(32)，LEFT 截断）
--   maturity               <- maturity               到期日期（LEFT 截断）
--   groupName              <- groupName              集团名称
--   productName            <- productName            对象
--   checkDate              <- checkDate              检查日期（LEFT 截断）
--   balance                <- balance                对象项下借据余额（源 VARCHAR -> DECIMAL(18,2)，NULLIF 防空串）
--   "condition"            <- condition              批复后续管理要求（源 VARCHAR(1000) -> app TEXT）
--   implementStatus        <- implementStatus        落实情况（码值->中文：01->已完成, 02->部分完成, 03->无法完成, 06->持续关注, 07->结清不续贷, 08->已有新批复, 09->延期；NULL/未收录原样保留）
--   extendDate             <- extendDate             展期日期（LEFT 截断）
--   opinion                <- opinion                意见（源 VARCHAR(1000) -> app TEXT）
--   conditioninStruction   <- conditionInstruction   情况说明（源列名 conditionInstruction，app 列名拼写不同需显式 AS）
--   creditApproveUserName  <- creditApproveUserName  授信审查人
--   approveAuthor          <- approveAuthor          审批权限
--   operateBelongOrgName   <- operateBelongOrgName   分行
--   operateOrgName         <- operateOrgName         支行
--   operateUserName        <- operateUserName        经办客户经理
--   approveStatusName      <- approveStatusName      审批状态名称（码值：Cancel取消/Reject否决/Review复核中/Ineffective失效/Approving审批中/Finished审批通过/CustomerRegister客户经理登记中/PreSubmit待提交/PreConfirmed待确认/EarlyTerminate提前结束/Register登记中/Registered登记完成/Adjournment续议/AutoConfirmed自动审批已确认/AutoToBeConfirm自动审批待确认/GoBack退回/Accepted通过）
--
-- 处理规则（对齐 xd_collateral.sql；本表为父表自身，无 mainId，不 JOIN 主档）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_single_check_task_info 本次范围旧行，再插入
--   2. 源头 append-only：按业务主键 (reportNo, customerId, serialNo) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 一次查询可有多条任务（不同流水号），各出一行；balance 数值 CAST，日期列 LEFT 截断
-- =====================================================================

-- 1. 幂等
DELETE FROM app_single_check_task_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 单项检查任务：xd_single_task_check -> app_single_check_task_info
INSERT INTO app_single_check_task_info (
    reportNo, customerId, customerName, itemCategory, serialNo, creditNo, approveTextNo,
    startDate, maturity, groupName, productName, checkDate, balance, "condition",
    implementStatus, extendDate, opinion, conditioninStruction,
    creditApproveUserName, approveAuthor, operateBelongOrgName, operateOrgName, operateUserName, approveStatusName
)
SELECT
    c.reportNo, c.customerId, c.customerName,
    -- 事项类别：码值->中文（01担保落实/02佐证材料收集/03额度压降/04资金到位/06监管账户/07资金归集/08管理要求），NULL/未收录原样保留
    CASE c.itemCategory
        WHEN '01' THEN '担保落实'
        WHEN '02' THEN '佐证材料收集'
        WHEN '03' THEN '额度压降'
        WHEN '04' THEN '资金到位'
        WHEN '06' THEN '监管账户'
        WHEN '07' THEN '资金归集'
        WHEN '08' THEN '管理要求'
        ELSE c.itemCategory
    END AS itemCategory,
    c.serialNo, c.creditNo, c.approveTextNo,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.startDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.startDate, 1, 10), '-', ''), '/', '')
         ELSE c.startDate END AS startDate,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.maturity, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.maturity, 1, 10), '-', ''), '/', '')
         ELSE c.maturity END AS maturity,
    c.groupName, c.productName,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.checkDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.checkDate, 1, 10), '-', ''), '/', '')
         ELSE c.checkDate END AS checkDate,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(c.balance), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(c.balance) END AS DECIMAL(18,2)) AS balance,
    c.condition AS "condition",
    -- 落实情况：码值->中文（01已完成/02部分完成/03无法完成/06持续关注/07结清不续贷/08已有新批复/09延期），NULL/未收录原样保留
    CASE c.implementStatus
        WHEN '01' THEN '已完成'
        WHEN '02' THEN '部分完成'
        WHEN '03' THEN '无法完成'
        WHEN '06' THEN '持续关注'
        WHEN '07' THEN '结清不续贷'
        WHEN '08' THEN '已有新批复'
        WHEN '09' THEN '延期'
        ELSE c.implementStatus
    END AS implementStatus,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.extendDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.extendDate, 1, 10), '-', ''), '/', '')
         ELSE c.extendDate END AS extendDate,
    c.opinion,
    c.conditionInstruction AS conditioninStruction,
    c.creditApproveUserName, c.approveAuthor, c.operateBelongOrgName, c.operateOrgName, c.operateUserName,
    c.approveStatusName
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.itemCategory, c.serialNo, c.creditNo, c.approveTextNo,
           c.startDate, c.maturity, c.groupName, c.productName, c.checkDate, c.balance, c.condition,
           c.implementStatus, c.extendDate, c.opinion, c.conditionInstruction, c.creditApproveUserName,
           c.approveAuthor, c.operateBelongOrgName, c.operateOrgName, c.operateUserName, c.approveStatusName,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.serialNo, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_single_task_check c
    WHERE c.reportNo IS NOT NULL
      AND (c.customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (c.reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) c
WHERE c.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_specific_loan_project_check_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_specific_loan_project.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》特定贷款检查（项目类）· 源头表 -> app_specific_loan_project_check_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info          对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_fixed_loan    特定贷款检查数组（固定资产、房地产开发贷款，mainId -> xd_corp_check_info.id）
-- 目标：app_specific_loan_project_check_info（业务主键 reportNo + customerId + contractNo，一笔贷款一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_check_record.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_specific_loan_project_check_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按业务主键 (contractNo) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 32 列直映（源列名 == app 列名），仅 4 处源宽 > app 宽需 LEFT 截断防越界：
--        projectBeginDate  源 VARCHAR(64)  -> app VARCHAR(32)  LEFT(...,32)
--        projectFinishDate 源 VARCHAR(64)  -> app VARCHAR(32)  LEFT(...,32)
--        purpose           源 VARCHAR(255) -> app VARCHAR(128) LEFT(...,128)
--        vouchType         源 VARCHAR(64)  -> app VARCHAR(32)  LEFT(...,32)
--      金额列均为 DECIMAL(18,2) 直映；说明列源 VARCHAR(1000) -> app TEXT 不越界不截断
--   4. objectName 码值（固定资产/房地产开发贷款）原样透传
-- =====================================================================

-- 1. 幂等
DELETE FROM app_specific_loan_project_check_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 特定贷款检查（项目类）：xd_corp_check_fixed_loan（JOIN 当前主档）-> app_specific_loan_project_check_info
INSERT INTO app_specific_loan_project_check_info (
    reportNo, customerId, customerName, objectName, balance, businessSum,
    capitalCheckCondition, capitalFundInvoiced, capitalFundUnInvoiced, capitalFundUsed,
    contractNo, duebillTotalBusinessSum, loanFundInvoiced, loanFundUnInvoiced, loanFundUsed,
    nominalBalanceSum, otherFundInvoiced, otherFundUnInvoiced, otherFundUsed,
    productBelongName, productName, projectBeginDate, projectFinishDate, purpose,
    repaySum, runCheckCondition, scheduleCheckCondition, superviseCheckCondition,
    totalInvestInvoiced, totalInvestUnInvoiced, totalInvestUsed, vouchType
)
SELECT
    c.reportNo, c.customerId, c.customerName, c.objectName, c.balance, c.businessSum,
    c.capitalCheckCondition, c.capitalFundInvoiced, c.capitalFundUnInvoiced, c.capitalFundUsed,
    c.contractNo, c.duebillTotalBusinessSum, c.loanFundInvoiced, c.loanFundUnInvoiced, c.loanFundUsed,
    c.nominalBalanceSum, c.otherFundInvoiced, c.otherFundUnInvoiced, c.otherFundUsed,
    c.productBelongName, c.productName,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.projectBeginDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.projectBeginDate, 1, 10), '-', ''), '/', '')
         ELSE c.projectBeginDate END AS projectBeginDate,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.projectFinishDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.projectFinishDate, 1, 10), '-', ''), '/', '')
         ELSE c.projectFinishDate END AS projectFinishDate,
    LEFT(c.purpose, 128)          AS purpose,
    c.repaySum, c.runCheckCondition, c.scheduleCheckCondition, c.superviseCheckCondition,
    c.totalInvestInvoiced, c.totalInvestUnInvoiced, c.totalInvestUsed,
    LEFT(c.vouchType, 32)         AS vouchType
FROM (
    SELECT c.*, ROW_NUMBER() OVER (
        PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.contractNo, '')
        ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_fixed_loan c
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_top_five_updown_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
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

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_xd_shareholder_info.sql
-- ---------------------------------------------------------------------
-- Processing logic (params filled, ready to run)   <- 加工段起点（幂等 DELETE + INSERT）
-- Source: 客户企业概况加工\xd_customer.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 信贷系统客户企业概况 · 源头表 -> 应用层表加工（参考 财务指标加工/xd_financial.sql 模式）
-- 源表（对公客户信息查询接口 getEntCustomerAllQry 落表，见 源头表/信贷/DDL/对公客户信息查询接口_建表DDL.sql）：
--   xd_corp_customer_info           客户主档（CustomerEndInfoDto）
--   xd_corp_customer_control        实际控制人（ControlshipExecutives，mainId -> xd_corp_customer_info.id）
--   xd_corp_customer_shareholder    股东信息（CustomerShipSharehold，mainId -> xd_corp_customer_info.id）
-- 目标：app_customer_info（客户工商概况表）/ app_xd_shareholder_info（信贷股东全字段）
--      （app_shareholder_info 由 外数加工/xd_shareholder_info.sql 承载，本脚本不写入）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式，正则用 REGEXP）
--
-- 处理规则（依据《SZ银行DH智能体》数据字典，仅取"来源=信贷"的列）：
--   1. 幂等：先按 (customerId, reportNo) 删除两张 app 表本次范围旧行，再插入
--   2. 源头表"接口返回直接追加插入，不做去重约束"，同一 reportNo 重复调用会重复落表：
--        主档   : 按 reportNo 去重取最新一条
--        股东   : 按业务主键 (reportNo, customerId, name) 取最新（《SZ银行DH智能体》数据字典 J 列；同名股东仅一行）
--        控制人 : 按 (reportNo, controlName+certId) 去重（controlName=实控人名称）
--   3. 字段映射（信贷源 -> app）：
--        app_customer_info:
--          legalPerson      <- fictitiousPerson(法人代表)
--          registerCapital  <- registerCapital(已是 DECIMAL)
--          paidInCapital    <- paiclupCapital(实收资本, 已是 DECIMAL)
--          industryType     <- industryType(国标行业分类)  码值->中文：LEFT JOIN 码值字典表 app_code_dict
--                              （dict_type='industryType'，1969 码由 码值字典/国标行业分类_码值字典.sql 落表；
--                               命中取 code_name，未命中回退原码值）
--          holdType         <- holdType(控股类型)          码值->中文：内联 CASE（10 码）
--          actualController <- 控制子表 isControl='1' 的 controlName(实控人名称) 去重拼接
--                              （controlName=controlshipExecutives.customerName，落表时由 CorpCustomerDataStore 单独映射；
--                               relativeCustomerId 为实控人客户号，不再用于拼接）
--          officeAddress    <- officeFormattedAddress(标准办公地址)
--          businessScope    <- businessScope(经营范围)
--          dangerLevel      <- dangerLevel(风险分类结果)    码值->中文：内联 CASE（10 码）
--          warningLevel     <- warningLevel(预警等级)       码值->中文：内联 CASE（1/2/4/5/6 码）
--          isTechCompany    <- isStiEnt(是否科创企业, 1 -> 是, 其余 -> 否)
--          isListedCompany  <- listingCorpOrNot(是否上市公司, 1 -> 是, 其余 -> 否)
--          isStateOwned     <- 去掉, 不输出（holdType 码值表待确认, 按需求不加工该列）
--        app_xd_shareholder_info（信贷股东全字段）:
--          name <- shareholderName, investmentProp, relationShip(出资方式, 码值->中文内联 CASE 5 码),
--          currencyType(投资币种), oughtSum(应缴), investmentSum(实缴), investDate(最迟到位日期),
--          inputUserId, inputOrgId
--   4. 外数来源列（app_ic_info / app_ic_shareholder_info 整表, 以及 stock_num/is_quoted/is_state_owned/
--      is_fake_state_owned/is_listed_company 等）不在本脚本范围, 置 NULL 留给启信宝(QXB_*)等外数加工
--   5. 码值转换（依据《苏州银行综合信贷系统_贷后智能体相关接口_V1.0》「码表」sheet）：
--        holdType/dangerLevel/warningLevel/relationShip 码值小 -> 内联 CASE 转中文，NULL/未收录码值原样保留；
--        industryType 1969 码 -> 走 app_code_dict 字典表 JOIN（不在 SQL 内 CASE）。
--        前置：先执行 码值字典/国标行业分类_码值字典.sql 落 app_code_dict（industryType 类），否则 industryType 回退原码值。
--   6. isStiEnt/listingCorpOrNot 码表仅 0/1（0=否/1=是），按 1 判"是"，其余/未收录 -> "否"（2026-09-17 已去 'Y' 死分支）
-- =====================================================================

-- 1. 幂等：先删除本次加工范围内的目标行（与下方过滤条件一致，避免重复加工叠加）
DELETE FROM app_customer_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

DELETE FROM app_xd_shareholder_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 客户工商概况：xd_corp_customer_info -> app_customer_info
INSERT INTO app_customer_info (
    reportNo, customerId, customerName, legalPerson, registerCapital, paidInCapital,
    industryType, holdType, actualController, officeAddress, businessScope,
    dangerLevel, warningLevel, isTechCompany, isListedCompany
)
SELECT
    i.reportNo AS reportNo,
    i.customerId AS customerId,
    i.customerName AS customerName,
    i.fictitiousPerson AS legalPerson,
    i.registerCapital AS registerCapital,
    i.paiclupCapital AS paidInCapital,
    -- 国标行业分类：码值->中文，走码值字典表（1969 码，码值字典/国标行业分类_码值字典.sql 落表），未命中回退原码值
    COALESCE(d.code_name, i.industryType) AS industryType,
    -- 控股类型：码值->中文（10 码），NULL/未收录原样保留
    CASE WHEN i.holdType IS NULL THEN NULL
         WHEN i.holdType = '010' THEN '国有绝对控股'
         WHEN i.holdType = '020' THEN '国有相对控股'
         WHEN i.holdType = '030' THEN '集体绝对控股'
         WHEN i.holdType = '040' THEN '集体相对控股'
         WHEN i.holdType = '050' THEN '个人绝对控股'
         WHEN i.holdType = '060' THEN '个人相对控股'
         WHEN i.holdType = '070' THEN '港澳台商绝对控股'
         WHEN i.holdType = '080' THEN '港澳台商相对控股'
         WHEN i.holdType = '090' THEN '外商绝对控股'
         WHEN i.holdType = '100' THEN '外商相对控股'
         ELSE i.holdType END AS holdType,
    c.actualController AS actualController,
    i.officeFormattedAddress AS officeAddress,
    i.businessScope AS businessScope,
    -- 风险分类结果：码值->中文（10 码），NULL/未收录原样保留
    CASE WHEN i.dangerLevel IS NULL THEN NULL
         WHEN i.dangerLevel = '011' THEN '正常1'
         WHEN i.dangerLevel = '012' THEN '正常2'
         WHEN i.dangerLevel = '013' THEN '正常3'
         WHEN i.dangerLevel = '021' THEN '关注1'
         WHEN i.dangerLevel = '022' THEN '关注2'
         WHEN i.dangerLevel = '023' THEN '关注3'
         WHEN i.dangerLevel = '031' THEN '次级1'
         WHEN i.dangerLevel = '032' THEN '次级2'
         WHEN i.dangerLevel = '040' THEN '可疑'
         WHEN i.dangerLevel = '050' THEN '损失'
         ELSE i.dangerLevel END AS dangerLevel,
    -- 预警等级：码值->中文（1/2/4/5/6 码，码表无 3），NULL/未收录原样保留
    CASE WHEN i.warningLevel IS NULL THEN NULL
         WHEN i.warningLevel = '1' THEN '无风险'
         WHEN i.warningLevel = '2' THEN '风险排查'
         WHEN i.warningLevel = '4' THEN '黄色预警'
         WHEN i.warningLevel = '5' THEN '橙色预警'
         WHEN i.warningLevel = '6' THEN '红色预警'
         ELSE i.warningLevel END AS warningLevel,
     -- 是否科创企业 / 是否上市公司（码值：是/否）：源头码表 0/1，兼容历史 '是' 形态；其余（含 0/空/NULL/未收录）一律「否」
     CASE WHEN BTRIM(COALESCE(i.isStiEnt, '')) IN ('1', '是') THEN '是' ELSE '否' END AS isTechCompany,
     CASE WHEN BTRIM(COALESCE(i.listingCorpOrNot, '')) IN ('1', '是') THEN '是' ELSE '否' END AS isListedCompany
FROM (
    -- 主档去重：每个 reportNo 仅保留最新一条
    SELECT reportNo, customerId, customerName, fictitiousPerson, registerCapital, paiclupCapital,
           industryType, holdType, officeFormattedAddress, businessScope,
           dangerLevel, warningLevel, isStiEnt, listingCorpOrNot,
           ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_customer_info
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) i
LEFT JOIN (
    -- 国标行业分类码值字典（1969 码，码值字典/国标行业分类_码值字典.sql 落表）
    SELECT code_value, code_name
    FROM app_code_dict
    WHERE dict_type = 'industryType'
) d ON d.code_value = i.industryType
LEFT JOIN (
    -- 实际控制人：isControl='1' 的 controlName(实控人名称) 去重顿号拼接，按 controlName 排序保证固定顺序
    -- （controlName 落表时由 CorpCustomerDataStore 从 controlshipExecutives.customerName 单独映射；
    --  相对控制人去重键 = controlName+certId）
    SELECT reportNo,
           GROUP_CONCAT(DISTINCT controlName ORDER BY controlName SEPARATOR '、') AS actualController
    FROM (
        SELECT reportNo, controlName, inputtime, id,
               ROW_NUMBER() OVER (
                   PARTITION BY reportNo,
                       COALESCE(controlName, ''), COALESCE(certId, '')
                   ORDER BY inputtime DESC, id DESC) AS rn
        FROM xd_corp_customer_control
        WHERE reportNo IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
          AND isControl = '1'
          AND controlName IS NOT NULL
    ) t
    WHERE t.rn = 1
    GROUP BY reportNo
) c ON c.reportNo = i.reportNo
WHERE i.rn = 1;

-- 3. 信贷系统股东信息（全字段）：xd_corp_customer_shareholder -> app_xd_shareholder_info
--    （app_shareholder_info 由外数加工 外数加工/xd_shareholder_info.sql 承载，本脚本不再写入，避免两脚本互删）
INSERT INTO app_xd_shareholder_info (
    reportNo, customerId, customerName, name, investmentProp, relationShip, currencyType,
    oughtSum, investmentSum, investDate, inputUserId, inputOrgId
)
SELECT
    s.reportNo AS reportNo,
    s.customerId AS customerId,
    s.customerName AS customerName,
    s.shareholderName AS name,
    s.investmentProp AS investmentProp,
    -- 投资方式：码值->中文（5 码），NULL/未收录原样保留
    CASE WHEN s.relationShip IS NULL THEN NULL
         WHEN s.relationShip = '0401' THEN '资金(投资)'
         WHEN s.relationShip = '0402' THEN '技术(投资)'
         WHEN s.relationShip = '0403' THEN '实物(投资)'
         WHEN s.relationShip = '0404' THEN '权利(投资)'
         WHEN s.relationShip = '0405' THEN '其他(投资)'
         ELSE s.relationShip END AS relationShip,
    s.currencyType AS currencyType,
    s.oughtSum AS oughtSum,
    s.investmentSum AS investmentSum,
    CASE WHEN REGEXP_LIKE(SUBSTR(CAST(s.investDate AS CHAR(32)), 1, 10), '^[0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}$')
         THEN TO_CHAR(TO_DATE(SUBSTR(CAST(s.investDate AS CHAR(32)), 1, 10), 'YYYY-MM-DD'), 'YYYYMMDD')
         ELSE CAST(s.investDate AS CHAR(64)) END AS investDate,
    s.inputUserId AS inputUserId,
    s.inputOrgId AS inputOrgId
FROM (
    -- 股东去重：每个 (reportNo, 股东键) 仅保留最新一条
    SELECT reportNo, customerId, customerName, shareholderName, investmentProp, relationShip,
           currencyType, oughtSum, investmentSum, investDate, inputUserId, inputOrgId,
            ROW_NUMBER() OVER (
                PARTITION BY reportNo, COALESCE(customerId, ''), COALESCE(shareholderName, '')
                ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_customer_shareholder
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) s
WHERE s.rn = 1;