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
DELETE FROM app_check_object_info       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_fixed_loan    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_operate_loan  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_corp_check_info（共享父表，条件创建：仅当 id=1 不存在时插入）
--    排他父表来源：源头数据_app_check_index_info.sql（主创建者）
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
SELECT 1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 10:30:00'
WHERE NOT EXISTS (SELECT 1 FROM xd_corp_check_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001');

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
-- Processing logic (params filled, ready to run)
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
