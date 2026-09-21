-- =====================================================================
-- 【合并脚本】押品加工 组（原 3 个脚本 → 本文件 1 个）
-- 生成：2026-09-22　由 33 个原脚本合并（清理段统一前置 + 造数段 + 加工段）
-- 合并规则：
--   1. 各原脚本自带的「源表 DELETE」已全部抽出并前置到 §0（同一张表只清一次）
--      ⇒ 组内多个脚本不再互相删数据（原「后跑的删掉先跑的」问题消失）
--   2. 同一张表被组内多个脚本造数时，只保留一处（其余位置见 [已合并] 标记）
--   3. 加工段原样保留（各自 app 表的幂等 DELETE + INSERT 不受影响）
--   4. reportNo 已统一为 RPT-202609-001
-- 原脚本清单：
--     源头数据_app_collateral_info.sql
--     源头数据_app_collateral_mortgage_info.sql
--     源头数据_app_collateral_restricted_right.sql
-- =====================================================================

-- =====================================================================
-- §0 统一清理（组内所有源表 + app 表，每张表只清一次）
-- =====================================================================
DELETE FROM app_collateral_info             WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_collateral_mortgage_info    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_collateral_restricted_right WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_collateral           WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_collateral_mortgage  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_collateral_restrict  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
-- =====================================================================
-- §1 造数（按原脚本分段；源表 DELETE 已上移；同表重复造数已省略）
-- =====================================================================

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_collateral_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_collateral_info（押品主档）源头表造数（反推 DML 目标数据）
-- 处理 SQL：sql/押品加工/xd_collateral.sql（一次产出 押品三张 app 表）
-- 源表：
--   xd_corp_check_collateral          押品主档（CollateralItem，父表 xd_corp_check_info）
--   DDL 见：sql/源头表/信贷/DDL/对公检查信息查询接口_建表DDL.sql
-- 目标表：app_collateral_info（3 行，clrId=001/002/003）
-- 字段映射（源 -> app）：
--   reportNo      -> reportNo          （直接透传）
--   customerId    -> customerId        （直接透传）
--   customerName  -> customerName      （直接透传）
--   clrId         -> clrId             （直接透传；去重键 PARTITION BY reportNo,clrId）
--   ownerName     -> owner             （重命名 ownerName->owner）
--   clrType       -> clrType           （直接透传，码值待确认）
--   clrName       -> clrName           （直接透传）
--   clrStatus     -> clrStatus         （直接透传，码值待确认）
--   valuationDate -> valuationDate     （CASE: YYYY-MM-DD -> YYYYMMDD 去横杠）
--   choiceTypeName  码值->中文 CASE：'AgrPri'->内部协议作价, 'Inner'->内部估值, 'Outer'->外部估值; NULL/未收录原样保留
--   evaluateValue -> evaluateValue     （VARCHAR -> TRIM -> CAST DECIMAL(18,2)，非数字->NULL）
--   rightOrder    -> rightOrder        （直接透传）
--   rightSum      -> rightSum          （VARCHAR -> TRIM -> CAST DECIMAL(18,2)，非数字->NULL）
--   confirmDate   -> confirmDate       （CASE: YYYY-MM-DD -> YYYYMMDD 去横杠）
--   dyqDj/yyDj/cfDj/ygDj -> 同名       （直接透传；DML 目标未列出= NULL，故源表置 NULL）
-- 去重：ROW_NUMBER() PARTITION BY (reportNo, COALESCE(clrId, 内容键)) ORDER BY inputtime DESC, id DESC
-- 测试数据：reportNo='RPT-202609-001', customerId='CUST-001', customerName='苏州XX精密机械制造有限公司'
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清源头三表 + app 三表（CUST-001）
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_collateral_info
-- [已上移至 §0] DELETE FROM app_collateral_mortgage_info
-- [已上移至 §0] DELETE FROM app_collateral_restricted_right
-- [已上移至 §0] DELETE FROM xd_corp_check_collateral
-- [已上移至 §0] DELETE FROM xd_corp_check_collateral_mortgage
-- [已上移至 §0] DELETE FROM xd_corp_check_collateral_restrict

-- =====================================================================
-- 1. 押品主档 xd_corp_check_collateral（mainId 哑值，加工 SQL 不读取）
--    3 行，clrId 唯一（001/002/003），去重不会合并
-- =====================================================================

-- C1：clrId='001' 出让出宅用地 / 中原路50号住宅 / 正常 / Inner(内部估值) 3400 万 / 顺位2 / 权证 1000 万
INSERT INTO xd_corp_check_collateral (id, mainId, reportNo, customerId, customerName, clrId, ownerId, ownerName, clrType, clrName, clrStatus, rightOrder, rightSum, valuationDate, choiceTypeName, evaluateValue, confirmDate, dyqDj, yyDj, cfDj, ygDj, inputtime)
VALUES (900001, 990100001, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '001', NULL, '张三', '出让出宅用地', '中原路50号住宅', '正常', '2', '1000.00', '2026-06-30', 'Inner', '3400.00', '2026-06-30', '否', '否', '否', '否', '2026-07-15 10:30:00');

-- C2：clrId='002' 商业用房 / 中原路128号商铺 / 正常 / AgrPri(内部协议作价) 1800 万 / 顺位1 / 权证 1500 万
INSERT INTO xd_corp_check_collateral (id, mainId, reportNo, customerId, customerName, clrId, ownerId, ownerName, clrType, clrName, clrStatus, rightOrder, rightSum, valuationDate, choiceTypeName, evaluateValue, confirmDate, dyqDj, yyDj, cfDj, ygDj, inputtime)
VALUES (900002, 990100002, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '002', NULL, '张三', '商业用房', '中原路128号商铺', '正常', '1', '1500.00', '2026-06-30', 'AgrPri', '1800.00', '2026-06-30', '否', '否', '否', '否', '2026-07-15 10:30:00');

-- C3：clrId='003' 权利类 / XX科技公司30%股权 / 查封 / Outer(外部估值) 500 万 / 顺位1 / 权证 0 万
INSERT INTO xd_corp_check_collateral (id, mainId, reportNo, customerId, customerName, clrId, ownerId, ownerName, clrType, clrName, clrStatus, rightOrder, rightSum, valuationDate, choiceTypeName, evaluateValue, confirmDate, dyqDj, yyDj, cfDj, ygDj, inputtime)
VALUES (900003, 990100003, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '003', NULL, '李四', '权利类', 'XX科技公司30%股权', '查封', '1', '0.00', '2026-06-30', 'Outer', '500.00', '2026-06-30', '否', '否', '是', '否', '2026-07-15 10:30:00');

-- =====================================================================
-- 验证说明：
-- 1. 上述 3 行 xd_corp_check_collateral 经 xd_collateral.sql 第 2 段 INSERT 加工后应产出
--    app_collateral_info 3 行（id 由 AUTO_INCREMENT 分配，1/2/3 顺序按插入顺序）。
-- 2. ISSUE（日期格式）：处理 SQL 对 valuationDate / confirmDate 做
--    SUBSTR(1,10) REGEXP '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$' 校验后去横杠（YYYY-MM-DD -> YYYYMMDD）。
--    源值 '2026-06-30' 命中正则 -> 加工输出 '20260630'，而 DML 目标为 '2026-06-30'（带横杠）。
--    不存在任何源值能令该 CASE 走 ELSE 分支同时原样返回 '2026-06-30'（10 字符必命中正则）。
--    故 valuationDate/confirmDate 实际加工结果为 '20260630'，与 DML 目标 '2026-06-30' 不一致。
-- 3. ISSUE（dyqDj/yyDj/cfDj/ygDj）：处理 SQL INSERT 列表含此 4 列（源->app 原样透传），
--    但 DML 目标 INSERT 列表未列出（= NULL）。故源表此 4 列置 NULL，加工后 app 表此 4 列亦为 NULL，与 DML 一致。
-- 4. evaluateValue='3400.00'/'1800.00'/'500.00' 均为合法数字，TRIM+CAST 后为 3400.00/1800.00/500.00。
-- 5. rightSum='1000.00'/'1500.00'/'0.00' 均为合法数字，CAST 后为 1000.00/1500.00/0.00。
-- 6. inputtime（app 表）由 DB DEFAULT CURRENT_TIMESTAMP 设定，非源表透传，加工时取运行时时间戳，
--    与 DML 目标 '2026-07-15 10:30:00.0' 可能不一致（运行时相关，非源数据可控）。
-- 7. 3 行 clrId 唯一（001/002/003），去重后各保留 1 行，符合目标 3 行。
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_collateral_mortgage_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_collateral_mortgage_info（押品他项权利/抵押）源头表造数（反推 DML 目标数据）
-- 处理 SQL：sql/押品加工/xd_collateral.sql（一次产出 押品三张 app 表）
-- 源表：
--   xd_corp_check_collateral          押品主档（CollateralItem，父表 xd_corp_check_info）
--   xd_corp_check_collateral_mortgage 他项权利/抵押（OtherRight，mainId -> collateral.id）
--   xd_corp_check_collateral_restrict 限制权利/查封（RestrictionRight，mainId -> collateral.id，本文件附造 1 行使三张 app 表均有数据）
--   DDL 见：sql/源头表/信贷/DDL/对公检查信息查询接口_建表DDL.sql
-- 目标表：app_collateral_mortgage_info（1 行，clrId=001）
-- 字段映射（源 -> app）：
--   c.reportNo     -> reportNo         （c=主档，直接透传）
--   c.customerId   -> customerId       （主档透传）
--   c.customerName -> customerName     （主档透传）
--   c.clrId        -> clrId            （主档透传，子表无 clrId 列）
--   m.pledgeSerialNo  -> pledgeSerialNo（m=他项，直接透传）
--   m.pledgeeName     -> pledgeeName    （直接透传）
--   m.guaranteeScope  -> guaranteeScope（LEFT(,256) 截断，VARCHAR(1000)->VARCHAR(256)）
--   m.pledgeTypeName  -> pledgeTypeName （直接透传，码值待确认）
--   m.maxCreditorAmt  -> maxCreditorAmt （VARCHAR -> TRIM -> CAST DECIMAL(18,2)，非数字->NULL）
--   m.startEnd        -> startEnd       （直接透传）
--   m.registerTimestamp -> registerTimestamp（CASE: YYYY-MM-DD -> YYYYMMDD 去横杠）
-- 去重：先取主档最新行（rn=1），再 JOIN 子表，子表按 (主档rnKey, pledgeSerialNo/内容键) 去重取最新
-- 测试数据：reportNo='RPT-202609-001', customerId='CUST-001', customerName='苏州XX精密机械制造有限公司'
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清源头三表 + app 三表（CUST-001）
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_collateral_info
-- [已上移至 §0] DELETE FROM app_collateral_mortgage_info
-- [已上移至 §0] DELETE FROM app_collateral_restricted_right
-- [已上移至 §0] DELETE FROM xd_corp_check_collateral
-- [已上移至 §0] DELETE FROM xd_corp_check_collateral_mortgage
-- [已上移至 §0] DELETE FROM xd_corp_check_collateral_restrict

-- =====================================================================
-- 1. 押品主档 xd_corp_check_collateral（3 行，clrId 唯一；本表为他项/限制子表的父表）
--    与 源头数据_app_collateral_info.sql 中主档数据保持一致
-- =====================================================================

-- C1：clrId='001'（他项权利挂此行下）
-- [已合并] xd_corp_check_collateral 造数与 app_collateral_info 重复，此处省略（避免主键冲突）

-- C2：clrId='002'
-- [已合并] xd_corp_check_collateral 造数与 app_collateral_info 重复，此处省略（避免主键冲突）

-- C3：clrId='003'
-- [已合并] xd_corp_check_collateral 造数与 app_collateral_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 2. 他项权利 xd_corp_check_collateral_mortgage（mainId 子查询取主档 id）
--    1 行，挂在 clrId='001' 当前主档下
-- =====================================================================

-- M1：挂 clrId='001' 主档；pledgeSerialNo=NULL / pledgeeName='XX银行' / guaranteeScope=NULL
--     / pledgeTypeName=NULL / maxCreditorAmt=2100.00 / startEnd / registerTimestamp
INSERT INTO xd_corp_check_collateral_mortgage (mainId, reportNo, customerId, customerName, pledgeSerialNo, pledgeeName, guaranteeScope, pledgeTypeName, maxCreditorAmt, startEnd, registerTimestamp, inputtime)
SELECT (SELECT id FROM (SELECT id, ROW_NUMBER() OVER (ORDER BY inputtime DESC, id DESC) rn FROM xd_corp_check_collateral WHERE reportNo='RPT-202609-001' AND customerId='CUST-001' AND clrId='001') t WHERE t.rn=1),
       'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
       NULL, 'XX银行', NULL, NULL, '2100.00', '2023-10-26起2032-10-26止', '2023-10-26 00:00:00',
       '2026-07-15 10:30:00';

-- =====================================================================
-- 3. 限制权利 xd_corp_check_collateral_restrict（mainId 子查询取主档 id）
--    1 行，挂在 clrId='002' 当前主档下（使本文件三张 app 表均有数据）
-- =====================================================================

-- R1：挂 clrId='002' 主档；attachmentOrg='张三' / attachmentTypeName='轮候查封'
INSERT INTO xd_corp_check_collateral_restrict (mainId, reportNo, customerId, customerName, attachmentOrg, attachmentTypeName, inputtime)
SELECT (SELECT id FROM (SELECT id, ROW_NUMBER() OVER (ORDER BY inputtime DESC, id DESC) rn FROM xd_corp_check_collateral WHERE reportNo='RPT-202609-001' AND customerId='CUST-001' AND clrId='002') t WHERE t.rn=1),
       'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
       '张三', '轮候查封',
       '2026-07-15 10:30:00';

-- =====================================================================
-- 验证说明：
-- 1. 上述 3 行主档 + 1 行他项 + 1 行限制经 xd_collateral.sql 加工后应产出
--    app_collateral_mortgage_info 1 行（clrId='001'，由主档 C1 带出）。
-- 2. ISSUE（DML 列名 clrname）：DML 目标 INSERT 列表含 clrname 列
--    (id,reportno,customerid,customername,clrname,...,clrid)，但 app 表 DDL
--    （app_贷后报告_建表脚本.sql）中 app_collateral_mortgage_info 仅有 clrId 列，无 clrname。
--    处理 SQL 也只 INSERT clrId（不含 clrname）。DML 中 clrname='中原路50号住宅' 实为主档
--    C1 的 clrName 透传展示，但处理 SQL 不会将其写入 app 表。此为 DML 与表结构/加工逻辑的不一致。
-- 3. ISSUE（registerTimestamp 日期格式）：处理 SQL 对 registerTimestamp 做
--    SUBSTR(1,10) REGEXP '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$' 校验后去横杠（YYYY-MM-DD -> YYYYMMDD）。
--    源值 '2023-10-26 00:00:00' 前 10 字符 '2023-10-26' 命中正则 -> 加工输出 '20231026'，
--    而 DML 目标为 '2023-10-26 00:00:00'（带横杠和时间）。不存在源值能令该 CASE 走 ELSE 分支
--    同时原样返回 '2023-10-26 00:00:00'（前 10 字符必命中正则）。故实际加工结果为 '20231026'。
-- 4. pledgeSerialNo=NULL / guaranteeScope=NULL / pledgeTypeName=NULL：源表置 NULL，加工后 app 表亦 NULL，
--    与 DML 目标 NULL 一致。
-- 5. maxCreditorAmt='2100.00' 合法数字，TRIM+CAST 后为 2100.00，与 DML 目标 2100.00 一致。
-- 6. startEnd='2023-10-26起2032-10-26止' 直接透传，与 DML 目标一致。
-- 7. inputtime（app 表）由 DB DEFAULT CURRENT_TIMESTAMP 设定，非源表透传，加工时取运行时时间戳，
--    与 DML 目标 '2026-07-15 10:30:00.0' 可能不一致（运行时相关，非源数据可控）。
-- 8. 他项仅 1 行，去重后保留 1 行，符合目标 1 行；mainId 子查询取 clrId='001' 主档最新行 id。
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_collateral_restricted_right.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_collateral_restricted_right（押品限制权利/查封）源头表造数（反推 DML 目标数据）
-- 处理 SQL：sql/押品加工/xd_collateral.sql（一次产出 押品三张 app 表）
-- 源表：
--   xd_corp_check_collateral          押品主档（CollateralItem，父表 xd_corp_check_info）
--   xd_corp_check_collateral_restrict 限制权利/查封（RestrictionRight，mainId -> collateral.id）
--   xd_corp_check_collateral_mortgage 他项权利/抵押（OtherRight，mainId -> collateral.id，本文件附造 1 行使三张 app 表均有数据）
--   DDL 见：sql/源头表/信贷/DDL/对公检查信息查询接口_建表DDL.sql
-- 目标表：app_collateral_restricted_right（1 行，clrId=002）
-- 字段映射（源 -> app）：
--   c.reportNo        -> reportNo          （c=主档，直接透传）
--   c.customerId      -> customerId        （主档透传）
--   c.customerName    -> customerName      （主档透传）
--   c.clrId           -> clrId             （主档透传，子表无 clrId 列）
--   s.attachmentOrg    -> attachmentOrg    （s=限制，直接透传）
--   s.attachmentTypeName -> attachmentTypeName（直接透传，码值待确认）
-- 去重：先取主档最新行（rn=1），再 JOIN 子表，子表按 (主档rnKey, attachmentOrg|attachmentTypeName) 去重取最新
-- 测试数据：reportNo='RPT-202609-001', customerId='CUST-001', customerName='苏州XX精密机械制造有限公司'
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清源头三表 + app 三表（CUST-001）
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_collateral_info
-- [已上移至 §0] DELETE FROM app_collateral_mortgage_info
-- [已上移至 §0] DELETE FROM app_collateral_restricted_right
-- [已上移至 §0] DELETE FROM xd_corp_check_collateral
-- [已上移至 §0] DELETE FROM xd_corp_check_collateral_mortgage
-- [已上移至 §0] DELETE FROM xd_corp_check_collateral_restrict

-- =====================================================================
-- 1. 押品主档 xd_corp_check_collateral（3 行，clrId 唯一；本表为限制子表的父表）
--    与 源头数据_app_collateral_info.sql 中主档数据保持一致
-- =====================================================================

-- C1：clrId='001'
-- [已合并] xd_corp_check_collateral 造数与 app_collateral_info 重复，此处省略（避免主键冲突）

-- C2：clrId='002'（限制权利挂此行下）
-- [已合并] xd_corp_check_collateral 造数与 app_collateral_info 重复，此处省略（避免主键冲突）

-- C3：clrId='003'
-- [已合并] xd_corp_check_collateral 造数与 app_collateral_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 2. 限制权利 xd_corp_check_collateral_restrict（mainId 子查询取主档 id）
--    1 行，挂在 clrId='002' 当前主档下
-- =====================================================================

-- R1：挂 clrId='002' 主档；attachmentOrg='张三' / attachmentTypeName='轮候查封'
-- [已合并] xd_corp_check_collateral_restrict 造数与 app_collateral_mortgage_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 3. 他项权利 xd_corp_check_collateral_mortgage（mainId 子查询取主档 id）
--    1 行，挂在 clrId='001' 当前主档下（使本文件三张 app 表均有数据）
-- =====================================================================

-- M1：挂 clrId='001' 主档；pledgeeName='XX银行' / maxCreditorAmt=2100.00
-- [已合并] xd_corp_check_collateral_mortgage 造数与 app_collateral_mortgage_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 验证说明：
-- 1. 上述 3 行主档 + 1 行限制 + 1 行他项经 xd_collateral.sql 加工后应产出
--    app_collateral_restricted_right 1 行（clrId='002'，由主档 C2 带出）。
-- 2. attachmentOrg='张三' 直接透传，与 DML 目标 '张三' 一致。
-- 3. attachmentTypeName='轮候查封' 直接透传，与 DML 目标 '轮候查封' 一致。
-- 4. clrId='002' 由主档 C2 透传（子表无 clrId 列，经 mainId JOIN 父表带出），与 DML 目标 '002' 一致。
-- 5. 本表无日期/金额字段经 CASE 或 CAST 变换，无日期格式或金额转换 ISSUE。
-- 6. inputtime（app 表）由 DB DEFAULT CURRENT_TIMESTAMP 设定，非源表透传，加工时取运行时时间戳，
--    与 DML 目标 '2026-07-15 10:30:00.0' 可能不一致（运行时相关，非源数据可控）。
-- 7. 限制仅 1 行，去重后保留 1 行，符合目标 1 行；mainId 子查询取 clrId='002' 主档最新行 id。
-- 8. 此表为三表中唯一无 ISSUE（除 inputtime 运行时戳外）的表。
-- =====================================================================

-- =====================================================================
--

-- =====================================================================
-- §2 加工（各原脚本的加工段，原样保留）
-- =====================================================================

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_collateral_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 押品加工\xd_collateral.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 押品 · 源头表 -> 应用层表加工（参考 财务指标加工/xd_financial.sql 模式）
-- 源表（对公检查接口 aflCheckDetailQry 落表，见 源头表/信贷/DDL/对公检查信息查询接口_建表DDL.sql）：
--   xd_corp_check_collateral           押品主档（CollateralItem）
--   xd_corp_check_collateral_mortgage  他项权利/抵押（OtherRight，mainId -> xd_corp_check_collateral.id）
--   xd_corp_check_collateral_restrict  限制权利/查封（RestrictionRight，mainId -> xd_corp_check_collateral.id）
-- 目标：app_collateral_info / app_collateral_mortgage_info / app_collateral_restricted_right
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式，正则用 REGEXP）
--
-- 处理规则：
--   1. 幂等：先按 (customerId, reportNo) 删除三张 app 表本次范围旧行，再插入
--   2. 源头表"接口返回直接追加插入，不做去重约束"，同一 reportNo 重复调用接口会重复落表，
--      故按业务键去重取最新一条（inputtime DESC, id DESC）：
--        押品主档  : (reportNo, clrId)；clrId 为空时按内容键(clrName+clrType+rightOrder+rightSum)兜底
--        他项权利  : 挂在"当前"押品行(mainId=最新主档.id)下，按 (主档键, 他项内容键) 去重
--        限制权利  : 同上，按 (主档键, 限制权人+限制权类型) 去重
--   3. 金额字段源头为 VARCHAR，先按数字正则校验再 CAST DECIMAL(18,2)，非数字/空 -> null
--   4. 子表无 clrId/clrName 列，经 mainId 关联父表带出
--   5. guaranteeScope 源头 VARCHAR(1000) 宽于 app 表 VARCHAR(256)，截断防止超长报错
--   6. clrType/clrStatus/pledgeTypeName/attachmentTypeName 码值表待确认，暂原样透传
--   7. 四类登记标记 DYQDJ(地役权登记)/YYDJ(异议登记)/CFDJ(查封登记)/YGDJ(预告登记)：
--      源表列名小写驼峰 dyqDj/yyDj/cfDj/ygDj，app 表列名大写 DYQDJ/YYDJ/CFDJ/YGDJ，原样透传
-- =====================================================================

-- 1. 幂等：先删除本次加工范围内的目标行（与下方过滤条件一致，避免重复加工叠加）
DELETE FROM app_collateral_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

DELETE FROM app_collateral_mortgage_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

DELETE FROM app_collateral_restricted_right
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 押品主档：xd_corp_check_collateral -> app_collateral_info
INSERT INTO app_collateral_info (
    reportNo, customerId, customerName, clrId, owner,
    clrType, clrName, clrStatus, valuationDate, choiceTypeName,
    evaluateValue, rightOrder, rightSum, confirmDate,
    dyqDj, yyDj, cfDj, ygDj
)
SELECT
    c.reportNo AS reportNo,
    c.customerId AS customerId,
    c.customerName AS customerName,
    c.clrId AS clrId,
    c.ownerName AS owner,
    c.clrType AS clrType,
    c.clrName AS clrName,
    c.clrStatus AS clrStatus,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.valuationDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.valuationDate, 1, 10), '-', ''), '/', '')
         ELSE c.valuationDate END AS valuationDate,
    -- 估值方式：码值->中文（AgrPri内部协议作价/Inner内部估值/Outer外部估值），NULL/未收录原样保留
    CASE c.choiceTypeName
        WHEN 'AgrPri' THEN '内部协议作价'
        WHEN 'Inner'  THEN '内部估值'
        WHEN 'Outer'  THEN '外部估值'
        ELSE c.choiceTypeName
    END AS choiceTypeName,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(c.evaluateValue), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(c.evaluateValue) END AS DECIMAL(18,2)) AS evaluateValue,
    c.rightOrder AS rightOrder,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(c.rightSum), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(c.rightSum) END AS DECIMAL(18,2)) AS rightSum,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.confirmDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.confirmDate, 1, 10), '-', ''), '/', '')
         ELSE c.confirmDate END AS confirmDate,
    c.dyqDj ,
    c.yyDj  ,
    c.cfDj  ,
    c.ygDj
FROM (
    -- 押品主档去重：每个 (reportNo, 业务键) 仅保留最新一条
    SELECT reportNo, customerId, customerName, clrId, ownerName,
           clrType, clrName, clrStatus, valuationDate, choiceTypeName,
           evaluateValue, rightOrder, rightSum, confirmDate,
           dyqDj, yyDj, cfDj, ygDj,
           ROW_NUMBER() OVER (
               PARTITION BY reportNo,
                   COALESCE(clrId,
                       CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                              '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
               ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_check_collateral
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) c
WHERE c.rn = 1;

-- 3. 他项权利/抵押：xd_corp_check_collateral_mortgage -> app_collateral_mortgage_info
--    仅取挂在"当前"(最新)押品行下的记录，避免历史重复快照的子记录混入
INSERT INTO app_collateral_mortgage_info (
    reportNo, customerId, customerName, clrId,
    pledgeSerialNo, pledgeeName, guaranteeScope, pledgeTypeName,
    maxCreditorAmt, startEnd, registerTimestamp
)
SELECT
    t.reportNo AS reportNo,
    t.customerId AS customerId,
    t.customerName AS customerName,
    t.clrId AS clrId,
    t.pledgeSerialNo AS pledgeSerialNo,
    t.pledgeeName AS pledgeeName,
    LEFT(t.guaranteeScope, 256) AS guaranteeScope,
    t.pledgeTypeName AS pledgeTypeName,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.maxCreditorAmt), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.maxCreditorAmt) END AS DECIMAL(18,2)) AS maxCreditorAmt,
    t.startEnd AS startEnd,
    CASE WHEN REGEXP_LIKE(SUBSTR(t.registerTimestamp, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(t.registerTimestamp, 1, 10), '-', ''), '/', '')
         ELSE t.registerTimestamp END AS registerTimestamp
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.clrId,
           m.pledgeSerialNo, m.pledgeeName, m.guaranteeScope, m.pledgeTypeName,
           m.maxCreditorAmt, m.startEnd, m.registerTimestamp,
           ROW_NUMBER() OVER (
               PARTITION BY c.rnKey,
                   COALESCE(m.pledgeSerialNo,
                       CONCAT('N|', COALESCE(m.pledgeeName, ''), '|', COALESCE(m.pledgeTypeName, '')))
               ORDER BY m.inputtime DESC, m.id DESC) AS mRN
    FROM (
        -- 当前押品主档（与主档表同一去重口径，带出去重键 rnKey）
        SELECT reportNo, customerId, customerName, clrId,  id,
               COALESCE(clrId,
                   CONCAT('N|', COALESCE(clrType, ''),
                          '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, ''))) AS rnKey
        FROM (
            SELECT reportNo, customerId, customerName, clrId,  clrType, rightOrder, rightSum, id,
                   ROW_NUMBER() OVER (
                       PARTITION BY reportNo,
                           COALESCE(clrId,
                               CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                                      '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
                       ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_collateral
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) pc
        WHERE pc.rn = 1
    ) c
    JOIN xd_corp_check_collateral_mortgage m ON m.mainId = c.id
) t
WHERE t.mRN = 1;

-- 4. 限制权利/查封：xd_corp_check_collateral_restrict -> app_collateral_restricted_right
INSERT INTO app_collateral_restricted_right (
    reportNo, customerId, customerName, clrId, attachmentOrg, attachmentTypeName
)
SELECT
    t.reportNo AS reportNo,
    t.customerId AS customerId,
    t.customerName AS customerName,
    t.clrId AS clrId,
    t.attachmentOrg AS attachmentOrg,
    t.attachmentTypeName AS attachmentTypeName
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.clrId,
           s.attachmentOrg, s.attachmentTypeName,
           ROW_NUMBER() OVER (
               PARTITION BY c.rnKey,
                   COALESCE(CONCAT(COALESCE(s.attachmentOrg, ''), '|', COALESCE(s.attachmentTypeName, '')), 'N')
               ORDER BY s.inputtime DESC, s.id DESC) AS sRN
    FROM (
        -- 当前押品主档（同上口径）
        SELECT reportNo, customerId, customerName, clrId, id,
               COALESCE(clrId,
                   CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                          '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, ''))) AS rnKey
        FROM (
            SELECT reportNo, customerId, customerName, clrId, clrName, clrType, rightOrder, rightSum, id,
                   ROW_NUMBER() OVER (
                       PARTITION BY reportNo,
                           COALESCE(clrId,
                               CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                                      '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
                       ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_collateral
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) pc
        WHERE pc.rn = 1
    ) c
    JOIN xd_corp_check_collateral_restrict s ON s.mainId = c.id
) t
WHERE t.sRN = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_collateral_mortgage_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 押品加工\xd_collateral.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 押品 · 源头表 -> 应用层表加工（参考 财务指标加工/xd_financial.sql 模式）
-- 源表（对公检查接口 aflCheckDetailQry 落表，见 源头表/信贷/DDL/对公检查信息查询接口_建表DDL.sql）：
--   xd_corp_check_collateral           押品主档（CollateralItem）
--   xd_corp_check_collateral_mortgage  他项权利/抵押（OtherRight，mainId -> xd_corp_check_collateral.id）
--   xd_corp_check_collateral_restrict  限制权利/查封（RestrictionRight，mainId -> xd_corp_check_collateral.id）
-- 目标：app_collateral_info / app_collateral_mortgage_info / app_collateral_restricted_right
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式，正则用 REGEXP）
--
-- 处理规则：
--   1. 幂等：先按 (customerId, reportNo) 删除三张 app 表本次范围旧行，再插入
--   2. 源头表"接口返回直接追加插入，不做去重约束"，同一 reportNo 重复调用接口会重复落表，
--      故按业务键去重取最新一条（inputtime DESC, id DESC）：
--        押品主档  : (reportNo, clrId)；clrId 为空时按内容键(clrName+clrType+rightOrder+rightSum)兜底
--        他项权利  : 挂在"当前"押品行(mainId=最新主档.id)下，按 (主档键, 他项内容键) 去重
--        限制权利  : 同上，按 (主档键, 限制权人+限制权类型) 去重
--   3. 金额字段源头为 VARCHAR，先按数字正则校验再 CAST DECIMAL(18,2)，非数字/空 -> null
--   4. 子表无 clrId/clrName 列，经 mainId 关联父表带出
--   5. guaranteeScope 源头 VARCHAR(1000) 宽于 app 表 VARCHAR(256)，截断防止超长报错
--   6. clrType/clrStatus/pledgeTypeName/attachmentTypeName 码值表待确认，暂原样透传
--   7. 四类登记标记 DYQDJ(地役权登记)/YYDJ(异议登记)/CFDJ(查封登记)/YGDJ(预告登记)：
--      源表列名小写驼峰 dyqDj/yyDj/cfDj/ygDj，app 表列名大写 DYQDJ/YYDJ/CFDJ/YGDJ，原样透传
-- =====================================================================

-- 1. 幂等：先删除本次加工范围内的目标行（与下方过滤条件一致，避免重复加工叠加）
DELETE FROM app_collateral_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

DELETE FROM app_collateral_mortgage_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

DELETE FROM app_collateral_restricted_right
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 押品主档：xd_corp_check_collateral -> app_collateral_info
INSERT INTO app_collateral_info (
    reportNo, customerId, customerName, clrId, owner,
    clrType, clrName, clrStatus, valuationDate, choiceTypeName,
    evaluateValue, rightOrder, rightSum, confirmDate,
    dyqDj, yyDj, cfDj, ygDj
)
SELECT
    c.reportNo AS reportNo,
    c.customerId AS customerId,
    c.customerName AS customerName,
    c.clrId AS clrId,
    c.ownerName AS owner,
    c.clrType AS clrType,
    c.clrName AS clrName,
    c.clrStatus AS clrStatus,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.valuationDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.valuationDate, 1, 10), '-', ''), '/', '')
         ELSE c.valuationDate END AS valuationDate,
    c.choiceTypeName AS choiceTypeName,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(c.evaluateValue), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(c.evaluateValue) END AS DECIMAL(18,2)) AS evaluateValue,
    c.rightOrder AS rightOrder,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(c.rightSum), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(c.rightSum) END AS DECIMAL(18,2)) AS rightSum,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.confirmDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.confirmDate, 1, 10), '-', ''), '/', '')
         ELSE c.confirmDate END AS confirmDate,
    c.dyqDj ,
    c.yyDj  ,
    c.cfDj  ,
    c.ygDj
FROM (
    -- 押品主档去重：每个 (reportNo, 业务键) 仅保留最新一条
    SELECT reportNo, customerId, customerName, clrId, ownerName,
           clrType, clrName, clrStatus, valuationDate, choiceTypeName,
           evaluateValue, rightOrder, rightSum, confirmDate,
           dyqDj, yyDj, cfDj, ygDj,
           ROW_NUMBER() OVER (
               PARTITION BY reportNo,
                   COALESCE(clrId,
                       CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                              '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
               ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_check_collateral
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) c
WHERE c.rn = 1;

-- 3. 他项权利/抵押：xd_corp_check_collateral_mortgage -> app_collateral_mortgage_info
--    仅取挂在"当前"(最新)押品行下的记录，避免历史重复快照的子记录混入
INSERT INTO app_collateral_mortgage_info (
    reportNo, customerId, customerName, clrId,
    pledgeSerialNo, pledgeeName, guaranteeScope, pledgeTypeName,
    maxCreditorAmt, startEnd, registerTimestamp
)
SELECT
    t.reportNo AS reportNo,
    t.customerId AS customerId,
    t.customerName AS customerName,
    t.clrId AS clrId,
    t.pledgeSerialNo AS pledgeSerialNo,
    t.pledgeeName AS pledgeeName,
    LEFT(t.guaranteeScope, 256) AS guaranteeScope,
    t.pledgeTypeName AS pledgeTypeName,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.maxCreditorAmt), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.maxCreditorAmt) END AS DECIMAL(18,2)) AS maxCreditorAmt,
    t.startEnd AS startEnd,
    CASE WHEN REGEXP_LIKE(SUBSTR(t.registerTimestamp, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(t.registerTimestamp, 1, 10), '-', ''), '/', '')
         ELSE t.registerTimestamp END AS registerTimestamp
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.clrId,
           m.pledgeSerialNo, m.pledgeeName, m.guaranteeScope, m.pledgeTypeName,
           m.maxCreditorAmt, m.startEnd, m.registerTimestamp,
           ROW_NUMBER() OVER (
               PARTITION BY c.rnKey,
                   COALESCE(m.pledgeSerialNo,
                       CONCAT('N|', COALESCE(m.pledgeeName, ''), '|', COALESCE(m.pledgeTypeName, '')))
               ORDER BY m.inputtime DESC, m.id DESC) AS mRN
    FROM (
        -- 当前押品主档（与主档表同一去重口径，带出去重键 rnKey）
        SELECT reportNo, customerId, customerName, clrId,  id,
               COALESCE(clrId,
                   CONCAT('N|', COALESCE(clrType, ''),
                          '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, ''))) AS rnKey
        FROM (
            SELECT reportNo, customerId, customerName, clrId,  clrType, rightOrder, rightSum, id,
                   ROW_NUMBER() OVER (
                       PARTITION BY reportNo,
                           COALESCE(clrId,
                               CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                                      '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
                       ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_collateral
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) pc
        WHERE pc.rn = 1
    ) c
    JOIN xd_corp_check_collateral_mortgage m ON m.mainId = c.id
) t
WHERE t.mRN = 1;

-- 4. 限制权利/查封：xd_corp_check_collateral_restrict -> app_collateral_restricted_right
INSERT INTO app_collateral_restricted_right (
    reportNo, customerId, customerName, clrId, attachmentOrg, attachmentTypeName
)
SELECT
    t.reportNo AS reportNo,
    t.customerId AS customerId,
    t.customerName AS customerName,
    t.clrId AS clrId,
    t.attachmentOrg AS attachmentOrg,
    t.attachmentTypeName AS attachmentTypeName
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.clrId,
           s.attachmentOrg, s.attachmentTypeName,
           ROW_NUMBER() OVER (
               PARTITION BY c.rnKey,
                   COALESCE(CONCAT(COALESCE(s.attachmentOrg, ''), '|', COALESCE(s.attachmentTypeName, '')), 'N')
               ORDER BY s.inputtime DESC, s.id DESC) AS sRN
    FROM (
        -- 当前押品主档（同上口径）
        SELECT reportNo, customerId, customerName, clrId, id,
               COALESCE(clrId,
                   CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                          '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, ''))) AS rnKey
        FROM (
            SELECT reportNo, customerId, customerName, clrId, clrName, clrType, rightOrder, rightSum, id,
                   ROW_NUMBER() OVER (
                       PARTITION BY reportNo,
                           COALESCE(clrId,
                               CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                                      '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
                       ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_collateral
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) pc
        WHERE pc.rn = 1
    ) c
    JOIN xd_corp_check_collateral_restrict s ON s.mainId = c.id
) t
WHERE t.sRN = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_collateral_restricted_right.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 押品加工\xd_collateral.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 押品 · 源头表 -> 应用层表加工（参考 财务指标加工/xd_financial.sql 模式）
-- 源表（对公检查接口 aflCheckDetailQry 落表，见 源头表/信贷/DDL/对公检查信息查询接口_建表DDL.sql）：
--   xd_corp_check_collateral           押品主档（CollateralItem）
--   xd_corp_check_collateral_mortgage  他项权利/抵押（OtherRight，mainId -> xd_corp_check_collateral.id）
--   xd_corp_check_collateral_restrict  限制权利/查封（RestrictionRight，mainId -> xd_corp_check_collateral.id）
-- 目标：app_collateral_info / app_collateral_mortgage_info / app_collateral_restricted_right
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式，正则用 REGEXP）
--
-- 处理规则：
--   1. 幂等：先按 (customerId, reportNo) 删除三张 app 表本次范围旧行，再插入
--   2. 源头表"接口返回直接追加插入，不做去重约束"，同一 reportNo 重复调用接口会重复落表，
--      故按业务键去重取最新一条（inputtime DESC, id DESC）：
--        押品主档  : (reportNo, clrId)；clrId 为空时按内容键(clrName+clrType+rightOrder+rightSum)兜底
--        他项权利  : 挂在"当前"押品行(mainId=最新主档.id)下，按 (主档键, 他项内容键) 去重
--        限制权利  : 同上，按 (主档键, 限制权人+限制权类型) 去重
--   3. 金额字段源头为 VARCHAR，先按数字正则校验再 CAST DECIMAL(18,2)，非数字/空 -> null
--   4. 子表无 clrId/clrName 列，经 mainId 关联父表带出
--   5. guaranteeScope 源头 VARCHAR(1000) 宽于 app 表 VARCHAR(256)，截断防止超长报错
--   6. clrType/clrStatus/pledgeTypeName/attachmentTypeName 码值表待确认，暂原样透传
--   7. 四类登记标记 DYQDJ(地役权登记)/YYDJ(异议登记)/CFDJ(查封登记)/YGDJ(预告登记)：
--      源表列名小写驼峰 dyqDj/yyDj/cfDj/ygDj，app 表列名大写 DYQDJ/YYDJ/CFDJ/YGDJ，原样透传
-- =====================================================================

-- 1. 幂等：先删除本次加工范围内的目标行（与下方过滤条件一致，避免重复加工叠加）
DELETE FROM app_collateral_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

DELETE FROM app_collateral_mortgage_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

DELETE FROM app_collateral_restricted_right
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 押品主档：xd_corp_check_collateral -> app_collateral_info
INSERT INTO app_collateral_info (
    reportNo, customerId, customerName, clrId, owner,
    clrType, clrName, clrStatus, valuationDate, choiceTypeName,
    evaluateValue, rightOrder, rightSum, confirmDate,
    dyqDj, yyDj, cfDj, ygDj
)
SELECT
    c.reportNo AS reportNo,
    c.customerId AS customerId,
    c.customerName AS customerName,
    c.clrId AS clrId,
    c.ownerName AS owner,
    c.clrType AS clrType,
    c.clrName AS clrName,
    c.clrStatus AS clrStatus,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.valuationDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.valuationDate, 1, 10), '-', ''), '/', '')
         ELSE c.valuationDate END AS valuationDate,
    c.choiceTypeName AS choiceTypeName,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(c.evaluateValue), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(c.evaluateValue) END AS DECIMAL(18,2)) AS evaluateValue,
    c.rightOrder AS rightOrder,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(c.rightSum), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(c.rightSum) END AS DECIMAL(18,2)) AS rightSum,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.confirmDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.confirmDate, 1, 10), '-', ''), '/', '')
         ELSE c.confirmDate END AS confirmDate,
    c.dyqDj ,
    c.yyDj  ,
    c.cfDj  ,
    c.ygDj
FROM (
    -- 押品主档去重：每个 (reportNo, 业务键) 仅保留最新一条
    SELECT reportNo, customerId, customerName, clrId, ownerName,
           clrType, clrName, clrStatus, valuationDate, choiceTypeName,
           evaluateValue, rightOrder, rightSum, confirmDate,
           dyqDj, yyDj, cfDj, ygDj,
           ROW_NUMBER() OVER (
               PARTITION BY reportNo,
                   COALESCE(clrId,
                       CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                              '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
               ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_check_collateral
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) c
WHERE c.rn = 1;

-- 3. 他项权利/抵押：xd_corp_check_collateral_mortgage -> app_collateral_mortgage_info
--    仅取挂在"当前"(最新)押品行下的记录，避免历史重复快照的子记录混入
INSERT INTO app_collateral_mortgage_info (
    reportNo, customerId, customerName, clrId,
    pledgeSerialNo, pledgeeName, guaranteeScope, pledgeTypeName,
    maxCreditorAmt, startEnd, registerTimestamp
)
SELECT
    t.reportNo AS reportNo,
    t.customerId AS customerId,
    t.customerName AS customerName,
    t.clrId AS clrId,
    t.pledgeSerialNo AS pledgeSerialNo,
    t.pledgeeName AS pledgeeName,
    LEFT(t.guaranteeScope, 256) AS guaranteeScope,
    t.pledgeTypeName AS pledgeTypeName,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.maxCreditorAmt), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(t.maxCreditorAmt) END AS DECIMAL(18,2)) AS maxCreditorAmt,
    t.startEnd AS startEnd,
    CASE WHEN REGEXP_LIKE(SUBSTR(t.registerTimestamp, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(t.registerTimestamp, 1, 10), '-', ''), '/', '')
         ELSE t.registerTimestamp END AS registerTimestamp
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.clrId,
           m.pledgeSerialNo, m.pledgeeName, m.guaranteeScope, m.pledgeTypeName,
           m.maxCreditorAmt, m.startEnd, m.registerTimestamp,
           ROW_NUMBER() OVER (
               PARTITION BY c.rnKey,
                   COALESCE(m.pledgeSerialNo,
                       CONCAT('N|', COALESCE(m.pledgeeName, ''), '|', COALESCE(m.pledgeTypeName, '')))
               ORDER BY m.inputtime DESC, m.id DESC) AS mRN
    FROM (
        -- 当前押品主档（与主档表同一去重口径，带出去重键 rnKey）
        SELECT reportNo, customerId, customerName, clrId,  id,
               COALESCE(clrId,
                   CONCAT('N|', COALESCE(clrType, ''),
                          '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, ''))) AS rnKey
        FROM (
            SELECT reportNo, customerId, customerName, clrId,  clrType, rightOrder, rightSum, id,
                   ROW_NUMBER() OVER (
                       PARTITION BY reportNo,
                           COALESCE(clrId,
                               CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                                      '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
                       ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_collateral
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) pc
        WHERE pc.rn = 1
    ) c
    JOIN xd_corp_check_collateral_mortgage m ON m.mainId = c.id
) t
WHERE t.mRN = 1;

-- 4. 限制权利/查封：xd_corp_check_collateral_restrict -> app_collateral_restricted_right
INSERT INTO app_collateral_restricted_right (
    reportNo, customerId, customerName, clrId, attachmentOrg, attachmentTypeName
)
SELECT
    t.reportNo AS reportNo,
    t.customerId AS customerId,
    t.customerName AS customerName,
    t.clrId AS clrId,
    t.attachmentOrg AS attachmentOrg,
    t.attachmentTypeName AS attachmentTypeName
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.clrId,
           s.attachmentOrg, s.attachmentTypeName,
           ROW_NUMBER() OVER (
               PARTITION BY c.rnKey,
                   COALESCE(CONCAT(COALESCE(s.attachmentOrg, ''), '|', COALESCE(s.attachmentTypeName, '')), 'N')
               ORDER BY s.inputtime DESC, s.id DESC) AS sRN
    FROM (
        -- 当前押品主档（同上口径）
        SELECT reportNo, customerId, customerName, clrId, id,
               COALESCE(clrId,
                   CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                          '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, ''))) AS rnKey
        FROM (
            SELECT reportNo, customerId, customerName, clrId, clrName, clrType, rightOrder, rightSum, id,
                   ROW_NUMBER() OVER (
                       PARTITION BY reportNo,
                           COALESCE(clrId,
                               CONCAT('N|', COALESCE(clrName, ''), '|', COALESCE(clrType, ''),
                                      '|', COALESCE(rightOrder, ''), '|', COALESCE(rightSum, '')))
                       ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_collateral
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) pc
        WHERE pc.rn = 1
    ) c
    JOIN xd_corp_check_collateral_restrict s ON s.mainId = c.id
) t
WHERE t.sRN = 1;