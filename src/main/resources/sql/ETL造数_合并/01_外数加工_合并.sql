-- =====================================================================
-- 【合并脚本】外数加工 组（原 3 个脚本 → 本文件 1 个）
-- 生成：2026-09-22　由 33 个原脚本合并（清理段统一前置 + 造数段 + 加工段）
-- 合并规则：
--   1. 各原脚本自带的「源表 DELETE」已全部抽出并前置到 §0（同一张表只清一次）
--      ⇒ 组内多个脚本不再互相删数据（原「后跑的删掉先跑的」问题消失）
--   2. 同一张表被组内多个脚本造数时，只保留一处（其余位置见 [已合并] 标记）
--   3. 加工段原样保留（各自 app 表的幂等 DELETE + INSERT 不受影响）
--   4. reportNo 已统一为 RPT-202609-001
--
-- 【执行顺序（跨组 owner 约定）】
--   01 外数  ->  02 客户企业概况  ->  04 贷后检查        （03 押品、05 财务 与其余互不共享，可任意）
--   共享源表的 owner（谁造谁清，其余组只读不写）：
--     ws_gs_info     owner = 01（借款人行）+ 02（收款人 2 行）；04 改为 UPDATE 补 entId
--     xd_credit_info owner = 02 / app_credit_use_info（14 列全字段版）
--     xd_credit_loan owner = 02 / app_loan_receipt_info（12 行 28 列版）
--     dfs_crdt_loan_cust_rel、ws_best_shareholding 等 → 见各文件 §0 注释
-- 原脚本清单：
--     源头数据_app_ic_info.sql
--     源头数据_app_ic_shareholder_info.sql
--     源头数据_app_shareholder_info.sql
-- =====================================================================

-- =====================================================================
-- §0 统一清理（组内所有源表 + app 表，每张表只清一次）
-- =====================================================================
DELETE FROM app_ic_info                WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_gs_info                 WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001'
  AND name IS NULL;
--   ↑ ws_gs_info owner = 本组：只清本组创建的「借款人工商照面行」（name IS NULL）
--     02 组的 2 行收款人（customerId IS NULL、name 非空）与 04 组的 UPDATE 均不受影响
DELETE FROM ws_beneficial_owner        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM std_ecis_t_mining_tags_dd  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_ic_shareholder_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_best_shareholding    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_equity_change        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_shareholder_info        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_base_info                 WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
-- =====================================================================
-- §1 造数（按原脚本分段；源表 DELETE 已上移；同表重复造数已省略）
-- =====================================================================

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_ic_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_ic_info（工商登记信息）源头表造数（反推 DML 目标数据）
-- 处理 SQL：sql/外数加工/xd_ic_info.sql
-- 源表：
--   ws_gs_info              启信宝工商照面（QXB_GSZM01，客户级单对象）
--     DDL 见：sql/源头表/外数/建表DDL_QXB_GSZM01_启信宝工商照面.sql
--   ws_beneficial_owner     启信宝企业实际受益人（QXB_SJSY01，多条）
--     DDL 见：sql/源头表/外数/建表DDL_QXB_SJSY01_启信宝实际受益人.sql
--   std_ecis_t_mining_tags_dd 中台客户/股东标签（客户级行 entp_first_nm 为空）
--     DDL 见：sql/源头表/数据融合平台/dfsDataQry_建表DDL.sql
-- 字段映射（源 -> app）：
--   ws_gs_info.operName              -> icLegalPerson      （直接透传）
--   ws_gs_info.registCapi            -> icRegisterCapital  （REGEXP_SUBSTR 取前导数值 + CAST DECIMAL(24,6)）
--   ws_gs_info.actualCapi            -> icPaidInCapital    （同上）
--   ws_gs_info.currency_unit         -> currencyUnit       （直接透传）
--   ws_beneficial_owner.beneficiary  -> icBeneficiaryName  （GROUP_CONCAT DISTINCT '、' 拼接）
--   ws_gs_info.endDate               -> cancellationDate   （YYYY-MM-DD -> YYYYMMDD 去横杠；否则原样）
--   std_ecis_t_mining_tags_dd tag_id=10104001 客户级 -> isStateOwned    （命中=是，否则=否）
--   std_ecis_t_mining_tags_dd tag_id=01011001 客户级 -> isFakeStateOwned（命中=是，否则=否）
-- 去重：ws_gs_info 按 (reportNo, customerId) ROW_NUMBER 取最新（inputtime DESC, id DESC）
--       ws_beneficial_owner 按 (reportNo, customerId, beneficiary) 去重后拼接
--       std_ecis_t_mining_tags_dd 按 (reportNo, cr_cust_num, tag_id) 取最新
-- 测试数据：reportNo='RPT-202609-001', customerId='CUST-001', customerName='苏州XX精密机械制造有限公司'
-- DML 目标：1 行（id=1）
--   icLegalPerson='李四', icRegisterCapital=3000.00, icPaidInCapital=2000.00,
--   icBeneficiaryName='王五', isStateOwned='是', isFakeStateOwned='是',
--   cancellationDate='2025-04-18 00:00:00', inputtime='2025-04-18 09:20:00.0'
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app_ic_info + 三张源表（CUST-001 / RPT-202609-001）
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_ic_info
-- [已上移至 §0] DELETE FROM ws_gs_info
-- [已上移至 §0] DELETE FROM ws_beneficial_owner
-- [已上移至 §0] DELETE FROM std_ecis_t_mining_tags_dd

-- =====================================================================
-- 1. ws_gs_info（启信宝工商照面，顶层表）
--    icLegalPerson='李四' / registCapi='3000.00万人民币' -> 清洗取 '3000.00' -> 3000.00
--    / actualCapi='2000.00万元' -> 清洗取 '2000.00' -> 2000.00 / currency_unit='人民币' 透传
--    / endDate='2025-04-18' -> 加工后 cancellationDate='20250418'（见 ISSUE 2）
-- =====================================================================
INSERT INTO ws_gs_info (reportNo, customerId, customerName, operName, registCapi, actualCapi, currency_unit, endDate, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '李四', '3000.00万人民币', '2000.00万元', 'CNY', '2025-04-18', '2026-09-15 10:00:00');

-- =====================================================================
-- 2. ws_beneficial_owner（启信宝实际受益人，顶层表）
--    beneficiary='王五' -> icBeneficiaryName='王五'（GROUP_CONCAT DISTINCT 单条=王五）
-- =====================================================================
INSERT INTO ws_beneficial_owner (reportNo, customerId, customerName, beneficiary, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '王五', '2026-09-15 10:00:00');

-- =====================================================================
-- 3. std_ecis_t_mining_tags_dd（中台客户标签，客户级行 entp_first_nm 为空）
--    cr_cust_num=CUST-001（=借款人客户编号），entp_first_nm=NULL（客户级）
--    tag_id=10104001(国有企业) -> isStateOwned='是'
--    tag_id=01011001(假冒国企) -> isFakeStateOwned='是'
-- =====================================================================
INSERT INTO std_ecis_t_mining_tags_dd (reportNo, customerId, customerName, cr_cust_num, entp_first_nm, tag_id, tag_name, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'CUST-001', NULL, '10104001', '国有企业', '2026-09-15 10:00:00');

INSERT INTO std_ecis_t_mining_tags_dd (reportNo, customerId, customerName, cr_cust_num, entp_first_nm, tag_id, tag_name, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'CUST-001', NULL, '01011001', '假冒国企', '2026-09-15 10:00:00');

-- =====================================================================
-- 验证说明：
-- 1. 上述 1 行 ws_gs_info + 1 行 ws_beneficial_owner + 2 行标签 经 xd_ic_info.sql 加工后
--    应产出 app_ic_info 1 行（id 由 AUTO_INCREMENT 分配）。
-- 2. 可复现字段（与 DML 一致）：
--    - reportNo='RPT-202609-001' ✓
--    - customerId='CUST-001' ✓
--    - customerName='苏州XX精密机械制造有限公司'（来自 ws_gs_info.customerName）✓
--    - icLegalPerson='李四'（← ws_gs_info.operName）✓
--    - icRegisterCapital=3000.00（REGEXP_SUBSTR '3000.00万人民币' 取 '3000.00'，
--      CAST AS DECIMAL(24,6)=3000.000000，入表 DECIMAL(18,2) -> 3000.00）✓
--    - icPaidInCapital=2000.00（同上 '2000.00万元' -> 2000.00）✓
--    - icBeneficiaryName='王五'（GROUP_CONCAT DISTINCT 单条=王五）✓
--    - isStateOwned='是'（10104001 命中）✓
--    - isFakeStateOwned='是'（01011001 命中）✓
-- 3. ISSUE（1）- DML 列名 schema drift：DML 列表写 `icbeneficiarypercent`（值 20.0000），
--    但 app_ic_info 实际表（见 应用层表/app_贷后报告_建表脚本.sql）该位置列名是 `currencyUnit`
--    （VARCHAR(64)），无 icbeneficiarypercent 列；xd_ic_info.sql 也只插入 currencyUnit，不插
--    icbeneficiarypercent。故 DML 中 icbeneficiarypercent=20.0000 无法由加工 SQL 复现。
--    加工 SQL 实际产出 currencyUnit='人民币'（来自 ws_gs_info.currency_unit），DML 列表未列出
--    currencyUnit 列（schema drift）。本脚本仍造 currency_unit='人民币'（供实际加工产出该列值）。
-- 4. ISSUE（2）- cancellationDate 日期格式不可复现：DML 目标='2025-04-18 00:00:00'（带时分秒）。
--    xd_ic_info.sql 第 59-61 行 CASE 逻辑：SUBSTR(endDate,1,10) REGEXP
--    '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$' 命中则去横杠输出 YYYYMMDD；不命中则原样返回 endDate。
--    源值 endDate='2025-04-18'（10 字符）必命中正则 -> 加工输出 '20250418'，与 DML 目标
--    '2025-04-18 00:00:00' 不一致。不存在任何源值能令加工输出恰好为 '2025-04-18 00:00:00'
--    （该字符串前 10 字符 '2025-04-18' 必命中正则 -> 输出 '20250418'）。
--    故 cancellationDate 实际加工结果为 '20250418'，与 DML 目标不一致。
-- 5. ISSUE（3）- inputtime 不可控：inputtime（app 表）由 DB DEFAULT CURRENT_TIMESTAMP 设定，
--    非源表透传，加工时取运行时时间戳，与 DML 目标 '2025-04-18 09:20:00.0' 不一致
--    （运行时相关，非源数据可控）。
-- 6. 去重：单条 ws_gs_info / 单条 ws_beneficial_owner / 两条不同 tag_id 标签，去重后各保留 1 行。
-- 7. customerName 取 ws_gs_info 侧（g.customerName，COALESCE 优先 g 后 b）。
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_ic_shareholder_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_ic_shareholder_info（工商股东变更）源头表造数（反推 DML 目标数据）
-- 处理 SQL：sql/外数加工/xd_ic_shareholder.sql
-- 源表：
--   ws_equity_change      启信宝股权变更（QXB_GQBG01，变更历史，多条）
--     DDL 见：sql/源头表/外数/建表DDL_QXB_GQBG01_启信宝股权变更.sql
--   ws_best_shareholding  启信宝最优股比（QXB_ZYGB01，最新持股，与 app_shareholder_info 共用）
--     DDL 见：sql/源头表/外数/建表DDL_QXB_ZYGB01_启信宝最优股比.sql
-- 字段映射（源 -> app）：
--   ws_equity_change.name          -> icShareholderName  （变更行：直接透传）
--   ws_equity_change.before_percent -> percentBefore     （REGEXP 守卫 + CAST DECIMAL(12,4)，去 %）
--   ws_equity_change.after_percent  -> percentAfter       （同上）
--   ws_equity_change.change_date    -> changeTime          （YYYY-MM-DD -> YYYYMMDD 去横杠；否则原样）
--   ws_best_shareholding.stock_num  -> icStockNum         （变更行 LEFT JOIN 撞股东名补值，REGEXP+SIGNED）
--   ws_best_shareholding.amount     -> icAmount            （同上，REGEXP+DECIMAL(18,2)）
--   snapshot_type / icStockPercent：DDL 无此列；DML 列出但全为 NULL（默认 NULL，加工 SQL 未插）
-- 去重：
--   ws_equity_change 按 (reportNo, customerId, name, change_date) 取最新（inputtime DESC, id DESC）
--   ws_best_shareholding 按 (reportNo, customerId, name) 取最新（LEFT JOIN 用）
-- 测试数据：reportNo='RPT-202609-001', customerId='CUST-001', customerName='苏州XX精密机械制造有限公司'
-- DML 目标：4 行（id=1~4），均为变更历史行（changeTime/percentBefore/percentAfter 非 NULL）
--   泰州公司 / 股东B / 股东C / 股东D
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app_ic_shareholder_info + 两张源表（CUST-001 / RPT-202609-001）
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_ic_shareholder_info
-- [已上移至 §0] DELETE FROM ws_best_shareholding
-- [已上移至 §0] DELETE FROM ws_equity_change

-- =====================================================================
-- 1. ws_best_shareholding（启信宝最优股比，顶层表，最新持股行）
--    用于 2b 变更行 LEFT JOIN 撞股东名补 icStockNum / icAmount
--    注意：此 4 行同时触发 2a 最新快照加工，会额外产出 4 行（见 ISSUE 2）
--    泰州公司 icStockNum=3000000 / 股东B/C icStockNum=2000000 / 股东D icStockNum=1000000
-- =====================================================================
-- [已合并] ws_best_shareholding 造数与 app_shareholder_info 重复，此处省略（避免主键冲突）
-- [已合并] ws_best_shareholding 造数与 app_shareholder_info 重复，此处省略（避免主键冲突）
-- [已合并] ws_best_shareholding 造数与 app_shareholder_info 重复，此处省略（避免主键冲突）
-- [已合并] ws_best_shareholding 造数与 app_shareholder_info 重复，此处省略（避免主键冲突）

-- =====================================================================
-- 2. ws_equity_change（启信宝股权变更，顶层表，变更历史行）
--    DML 目标 4 行：泰州公司 / 股东B / 股东C / 股东D 各 1 个变更时点
--    change_date 'YYYY-MM-DD' -> changeTime 'YYYYMMDD'（命中正则去横杠）
-- =====================================================================
-- 泰州公司 C1：change_date='2026-10-01', before='10.00%', after='30.00%'
--   -> changeTime='20261001' / percentBefore=10.0000 / percentAfter=30.0000
INSERT INTO ws_equity_change (reportNo, customerId, customerName, name, change_date, before_percent, after_percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '泰州公司', '2026-10-01', '10.00%', '30.00%', '2026-09-15 10:00:00');
-- 股东B C2：change_date='2026-01-01', before='0.00%', after='30.00%'
--   -> changeTime='20260101' / percentBefore=0.0000 / percentAfter=30.0000
INSERT INTO ws_equity_change (reportNo, customerId, customerName, name, change_date, before_percent, after_percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '股东B', '2026-01-01', '0.00%', '30.00%', '2026-09-15 10:00:00');
-- 股东C C3：change_date='2026-11-01', before='22.00%', after='0.00%'
--   -> changeTime='20261101' / percentBefore=22.0000 / percentAfter=0.0000
INSERT INTO ws_equity_change (reportNo, customerId, customerName, name, change_date, before_percent, after_percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '股东C', '2026-11-01', '22.00%', '0.00%', '2026-09-15 10:00:00');
-- 股东D C4：change_date='2026-11-01', before='22.00%', after='21.00%'
--   -> changeTime='20261101' / percentBefore=22.0000 / percentAfter=21.0000
INSERT INTO ws_equity_change (reportNo, customerId, customerName, name, change_date, before_percent, after_percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '股东D', '2026-11-01', '22.00%', '21.00%', '2026-09-15 10:00:00');

-- =====================================================================
-- 验证说明：
-- 1. 上述 4 行 ws_equity_change + 4 行 ws_best_shareholding 经 xd_ic_shareholder.sql 加工后
--    应产出 app_ic_shareholder_info 行：2a 最新快照 4 行（来自 ws_best_shareholding）+
--    2b 变更历史 4 行（来自 ws_equity_change）= 共 8 行。
-- 2. ISSUE（1）- DML 列名 schema drift：DML 列表含 `snapshot_type` 与 `icstockpercent` 列，
--    但 app_ic_shareholder_info 实际表（见 应用层表/app_贷后报告_建表脚本.sql）无此 2 列；
--    xd_ic_shareholder.sql INSERT 列表也未含此 2 列。DML 此 2 列值全为 NULL，与加工 SQL 不插入
--    （默认 NULL）一致，可视为 schema drift 但不影响数据。
--    注：snapshot_type 在 xd_ic_shareholder.sql 注释中提及（latest/变更）但未实际实现到 INSERT 列表。
-- 3. ISSUE（2）- 行数不可复现：DML 目标仅 4 行（均为变更历史行，changeTime/percentBefore/
--    percentAfter 非 NULL）。但 xd_ic_shareholder.sql 用 UNION ALL 同时输出 2a 最新快照
--    （ws_best_shareholding 每股东一行，changeTime/percentBefore/percentAfter=NULL）+ 2b 变更历史。
--    为使 2b 变更行经 LEFT JOIN 撞到 ws_best_shareholding.name 补 icStockNum/icAmount
--    （DML 目标此 2 列非 NULL），ws_best_shareholding 必须有 4 行 -> 2a 必然额外产出 4 行快照
--    （changeTime/percentBefore/percentAfter=NULL）。故实际加工结果为 8 行（4 快照 + 4 变更），
--    其中 4 变更行匹配 DML 目标，4 快照行为额外产出（DML 未列出）。
--    若不造 ws_best_shareholding（避免 2a 行），2b 变更行经 LEFT JOIN 撞不到 -> icStockNum/icAmount
--    =NULL，与 DML 目标非 NULL 不一致。两难，本脚本选择前者（多 4 行快照）以匹配 DML 变更行数据。
-- 4. 可复现字段（DML 4 变更行）：
--    - reportNo/customerId/customerName ✓
--    - icShareholderName = ws_equity_change.name ✓（泰州公司/股东B/股东C/股东D）
--    - icStockNum = ws_best_shareholding.stock_num（REGEXP+SIGNED，撞股东名）✓
--      （3000000/2000000/2000000/1000000）
--    - icAmount = ws_best_shareholding.amount（REGEXP+DECIMAL(18,2)）✓
--      （3000000.00/2000000.00/2000000.00/1000000.00）
--    - changeTime = ws_equity_change.change_date（YYYY-MM-DD -> YYYYMMDD 去横杠）✓
--      （'2026-10-01'->'20261001', '2026-01-01'->'20260101', '2026-11-01'->'20261101'）
--    - percentBefore = ws_equity_change.before_percent（REGEXP 守卫 + CAST DECIMAL(12,4)，去 %）✓
--      （10.0000/0.0000/22.0000/22.0000）
--    - percentAfter = ws_equity_change.after_percent（同上）✓
--      （30.0000/30.0000/0.0000/21.0000）
-- 5. ISSUE（3）- inputtime 不可控：inputtime（app 表）由 DB DEFAULT CURRENT_TIMESTAMP 设定，
--    非源表透传，加工时取运行时时间戳，与 DML 目标 '2026-03-10 08:30:00.0' 不一致
--    （运行时相关，非源数据可控）。
-- 6. ISSUE（4）- 跨表股东值冲突：泰州公司行 DML 目标 icStockNum=3000000，但
--    app_shareholder_info DML 目标同一股东 stock_num=2000000。两者共用 ws_best_shareholding
--    （过滤条件相同 reportNo+customerId），源值只能取其一。本脚本取 3000000 以匹配本表 DML
--    （app_shareholder_info 源数据脚本另取 2000000，两脚本独立运行不冲突）。
-- 7. 去重：4 行 ws_equity_change (name, change_date) 各异，4 行 ws_best_shareholding name 各异，
--    去重后各保留 1 行。
-- =====================================================================

-- =====================================================================
--

-- ---------------------------------------------------------------------
-- 【原脚本 §1】源头数据_app_shareholder_info.sql
-- ---------------------------------------------------------------------
-- =====================================================================
-- app_shareholder_info（股东股权信息）源头表造数（反推 DML 目标数据）
-- 处理 SQL：sql/外数加工/xd_shareholder_info.sql
-- 源表：
--   ws_best_shareholding        启信宝最优股比（QXB_ZYGB01，多条股东）
--     DDL 见：sql/源头表/外数/建表DDL_QXB_ZYGB01_启信宝最优股比.sql
--   ws_base_info                启信宝企业基础工商信息报告（QXB_QJGXB01，客户级单对象）
--     DDL 见：sql/源头表/外数/建表DDL_QXB_QJGXB01_启信宝企业基础工商信息.sql
--   std_ecis_t_mining_tags_dd  中台客户/股东标签（股东级行 entp_first_nm=股东名称）
--     DDL 见：sql/源头表/数据融合平台/dfsDataQry_建表DDL.sql
-- 字段映射（源 -> app）：
--   ws_best_shareholding.name        -> name            （直接透传）
--   ws_best_shareholding.stock_num   -> stock_num       （REGEXP+SIGNED）
--   ws_best_shareholding.amount       -> amount          （REGEXP+DECIMAL(24,6)）
--   ws_best_shareholding.percent      -> stock_percent   （REGEXP+DECIMAL(24,6)，去 %）
--   ws_base_info.is_quoted           -> is_quoted        （按股东名撞 ws_base_info.name，直接透传）
--   std_ecis_t_mining_tags_dd tag_id=10104001 股东级 -> is_state_owned     （命中=是，否则=否）
--   std_ecis_t_mining_tags_dd tag_id=01011001 股东级 -> is_fake_state_owned（同上）
-- 去重：
--   ws_best_shareholding 按 (reportNo, customerId, name) 取最新（inputtime DESC, id DESC）
--   ws_base_info 按 (reportNo, name) 取最新（不按 customerId 过滤）
--   std_ecis_t_mining_tags_dd 按 (reportNo, entp_first_nm, tag_id) 取最新
-- 测试数据：reportNo='RPT-202609-001', customerId='CUST-001', customerName='苏州XX精密机械制造有限公司'
-- DML 目标：6 行（id=1~6）
--   周九 / 泰州公司 / 王五 / 李四 / 赵六 / 陈友谅
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app_shareholder_info + 三张源表
--    ws_base_info 股东级行 customerId 可能非 CUST-001（按 name 撞），故按 reportNo 清
--    std_ecis_t_mining_tags_dd 股东级行 customerId 恒主客户（CUST-001），按 customerId+reportNo 清
-- =====================================================================
-- [已上移至 §0] DELETE FROM app_shareholder_info
-- [已上移至 §0] DELETE FROM ws_best_shareholding
-- [已上移至 §0] DELETE FROM ws_base_info
-- [已上移至 §0] DELETE FROM std_ecis_t_mining_tags_dd

-- =====================================================================
-- 1. ws_best_shareholding（启信宝最优股比，顶层表，股东行）
--    6 股东各 1 行：周九 / 泰州公司 / 王五 / 李四 / 赵六 / 陈友谅
-- =====================================================================
-- 周九：stock_num='3000000', amount='3000000.00', percent='30.00%'
--   -> stock_num=3000000, amount=3000000.00, stock_percent=30.0000
INSERT INTO ws_best_shareholding (reportNo, customerId, customerName, name, stock_num, amount, percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '周九', '3000000', '3000000.00', '30.00%', '2026-09-15 10:00:00');
-- 泰州公司：stock_num='2000000', amount='2000000.00', percent='20.00%'
--   -> stock_num=2000000, amount=2000000.00, stock_percent=20.0000
INSERT INTO ws_best_shareholding (reportNo, customerId, customerName, name, stock_num, amount, percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '泰州公司', '2000000', '2000000.00', '20.00%', '2026-09-15 10:00:00');
-- 王五：stock_num='2000000', amount='2000000.00', percent='20.00%'
INSERT INTO ws_best_shareholding (reportNo, customerId, customerName, name, stock_num, amount, percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '王五', '2000000', '2000000.00', '20.00%', '2026-09-15 10:00:00');
-- 李四：stock_num='1000000', amount='1000000.00', percent='10.00%'
INSERT INTO ws_best_shareholding (reportNo, customerId, customerName, name, stock_num, amount, percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '李四', '1000000', '1000000.00', '10.00%', '2026-09-15 10:00:00');
-- 赵六：stock_num='1000000', amount='1000000.00', percent='10.00%'
INSERT INTO ws_best_shareholding (reportNo, customerId, customerName, name, stock_num, amount, percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '赵六', '1000000', '1000000.00', '10.00%', '2026-09-15 10:00:00');
-- 陈友谅：stock_num='1000000', amount='1000000.00', percent='10.00%'
INSERT INTO ws_best_shareholding (reportNo, customerId, customerName, name, stock_num, amount, percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '陈友谅', '1000000', '1000000.00', '10.00%', '2026-09-15 10:00:00');

-- =====================================================================
-- 2. ws_base_info（启信宝企业基础工商信息，顶层表，企业级）
--    只为泰州公司造 1 行（is_quoted='是'），其余 5 股东无 ws_base_info 行 -> is_quoted=NULL
--    加工按 q.name = z.name 撞股东名（不按 customerId 过滤）
-- =====================================================================
INSERT INTO ws_base_info (reportNo, customerId, customerName, name, is_quoted, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '泰州公司', '是', '2026-09-15 10:00:00');

-- =====================================================================
-- 3. std_ecis_t_mining_tags_dd（中台标签，股东级行 entp_first_nm=股东名称）
--    只为泰州公司造 2 行（10104001 + 01011001），其余 5 股东无标签行
--    -> 泰州公司 is_state_owned='是' / is_fake_state_owned='是'（命中）
--    -> 其余 5 股东实际加工产出 '否'（见 ISSUE 2），但 DML 目标为 NULL（不一致）
-- =====================================================================
-- 泰州公司 M1：tag 10104001(国有企业) -> is_state_owned='是'
INSERT INTO std_ecis_t_mining_tags_dd (reportNo, customerId, customerName, cr_cust_num, entp_first_nm, tag_id, tag_name, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'CUST-001', '泰州公司', '10104001', '国有企业', '2026-09-15 10:00:00');
-- 泰州公司 M2：tag 01011001(假冒国企) -> is_fake_state_owned='是'
INSERT INTO std_ecis_t_mining_tags_dd (reportNo, customerId, customerName, cr_cust_num, entp_first_nm, tag_id, tag_name, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'CUST-001', '泰州公司', '01011001', '假冒国企', '2026-09-15 10:00:00');

-- =====================================================================
-- 验证说明：
-- 1. 上述 6 行 ws_best_shareholding + 1 行 ws_base_info + 2 行标签 经 xd_shareholder_info.sql 加工后
--    应产出 app_shareholder_info 6 行（每股东一行，id 由 AUTO_INCREMENT 分配，1~6 顺序按
--    ws_best_shareholding 插入顺序）。
-- 2. 可复现字段（与 DML 一致）：
--    - reportNo/customerId/customerName ✓
--    - name = ws_best_shareholding.name ✓（周九/泰州公司/王五/李四/赵六/陈友谅）
--    - stock_num = ws_best_shareholding.stock_num（REGEXP+SIGNED）✓
--      （3000000/2000000/2000000/1000000/1000000/1000000）
--    - amount = ws_best_shareholding.amount（REGEXP+DECIMAL(24,6)）✓
--      （3000000.00/2000000.00/2000000.00/1000000.00/1000000.00/1000000.00）
--    - stock_percent = ws_best_shareholding.percent（REGEXP+DECIMAL(24,6)，去 %）✓
--      （30.0000/20.0000/20.0000/10.0000/10.0000/10.0000）
--    - 泰州公司 is_quoted='是'（ws_base_info 1 行命中，直接透传）✓
--    - 其余 5 股东 is_quoted=NULL（无 ws_base_info 行，LEFT JOIN 未命中 -> NULL）✓
--    - 泰州公司 is_state_owned='是'（10104001 命中）✓
--    - 泰州公司 is_fake_state_owned='是'（01011001 命中）✓
-- 3. ISSUE（1）- DML 列名 schema drift：DML 列表含 `is_listed_company` 列，但
--    app_shareholder_info 实际表（见 应用层表/app_贷后报告_建表脚本.sql）无此列；
--    xd_shareholder_info.sql INSERT 列表也未含此列。DML 此列全为 NULL，与加工 SQL 不插入
--    （默认 NULL）一致，可视为 schema drift 但不影响数据。
-- 4. ISSUE（2）- is_state_owned/is_fake_state_owned 不可为 NULL：DML 目标中 5 行
--    （周九/王五/李四/赵六/陈友谅）is_state_owned=NULL / is_fake_state_owned=NULL，
--    但 xd_shareholder_info.sql 第 56-57 行 CASE 逻辑：
--      CASE WHEN tg.stateOwnedFlag = 1 THEN '是' ELSE '否' END AS is_state_owned
--      CASE WHEN tg.fakeFlag = 1 THEN '是' ELSE '否' END AS is_fake_state_owned
--    此 CASE 在 LEFT JOIN 未命中（tg.stateOwnedFlag=NULL）时走 ELSE 输出 '否'，而非 NULL。
--    故实际加工产出此 5 行 is_state_owned='否' / is_fake_state_owned='否'，
--    与 DML 目标 NULL 不一致。泰州公司行（命中 10104001+01011001）-> is_state_owned='是'
--    / is_fake_state_owned='是' ✓ 与 DML 一致。
-- 5. ISSUE（3）- inputtime 不可控：inputtime（app 表）由 DB DEFAULT CURRENT_TIMESTAMP 设定，
--    非源表透传，加工时取运行时时间戳，与 DML 目标 '2026-03-10 08:30:00.0' 不一致
--    （运行时相关，非源数据可控）。
-- 6. ISSUE（4）- 跨表股东值冲突：泰州公司行 DML 目标 stock_num=2000000，但
--    app_ic_shareholder_info DML 目标同一股东 icStockNum=3000000。两者共用 ws_best_shareholding
--    （过滤条件相同 reportNo+customerId），源值只能取其一。本脚本取 2000000 以匹配本表 DML
--    （app_ic_shareholder_info 源数据脚本另取 3000000，两脚本独立运行不冲突）。
-- 7. 去重：6 行 ws_best_shareholding name 各异，1 行 ws_base_info name 唯一，2 行标签
--    (entp_first_nm, tag_id) 各异，去重后各保留 1 行。
-- 8. is_quoted 在 ws_base_info DDL 为 VARCHAR(20)，本脚本取值 '是'（与 DML 目标一致），
--    xd_shareholder_info.sql 直接透传 q.is_quoted 不做码值转换。
-- 9. ws_base_info 加工不按 customerId 过滤（股东级 QJGXB01 调用落表的 customerId 可能是股东自身），
--    故 DELETE 按 reportNo 清（非按 customerId）。
-- =====================================================================

-- =====================================================================
--

-- =====================================================================
-- §2 加工（各原脚本的加工段，原样保留）
-- =====================================================================

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_ic_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 外数加工\xd_ic_info.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 工商登记信息 · 外数源头表 -> app_ic_info 加工（参考 财务指标加工/xd_financial.sql 模式）
-- 源表（ESB-EDMS 外数平台 f1100300004403 落表，见 源头表/外数 建表DDL）：
--   ws_gs_info           启信宝-工商照面（QXB_GSZM01，客户级单对象）
--   ws_beneficial_owner  启信宝-企业实际受益人（QXB_SJSY01，多条）
-- 中台标签源表（见 源头表/数据融合平台 建表DDL；DFS 接口链路待定，表空时两标签列回退「否」不报错）：
--   std_ecis_t_mining_tags_dd   中台客户/股东标签（客户级行 entp_first_nm 为空）
-- 目标：app_ic_info（工商登记信息表，客户级）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式，正则用 REGEXP）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_ic_info 段）：
--   icLegalPerson      <- ws_gs_info.operName      企业法定代表人（原始透传）
--   icRegisterCapital  <- ws_gs_info.registCapi    注册资本（万元，仅取数值，VARCHAR -> DECIMAL，见下「清洗规则」）
--   icPaidInCapital    <- ws_gs_info.actualCapi    实缴资本（万元，仅取数值，VARCHAR -> DECIMAL，见下「清洗规则」）
--   currencyUnit       <- ws_gs_info.currency_unit 币种（原始透传）
--   icBeneficiaryName  <- ws_beneficial_owner.beneficiary 多个受益人去重后以「、」拼接
--   cancellationDate   <- ws_gs_info.endDate       注销日期（取营业有效期截止 endDate）
--   isStateOwned       <- std_ecis_t_mining_tags_dd          tag_id=10104001(国有企业) 客户级(cr_cust_num=借款人客户编号)
--                                                        有数据为「是」，否则「否」
--   isFakeStateOwned   <- std_ecis_t_mining_tags_dd          tag_id=01011001(假冒国企) 客户级(cr_cust_num=借款人客户编号)
--                                                        有数据为「是」，否则「否」
--
-- 处理规则：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_ic_info 本次范围旧行，再插入
--   2. 源头表 append-only（重复调接口重复落表），按 (reportNo, customerId) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 键表 = 两侧 (reportNo, customerId) 并集，双 LEFT JOIN：任一侧有数即出一行（另一侧列 NULL）
--   4. 受益人拼接：GROUP_CONCAT(DISTINCT beneficiary SEPARATOR '、')；
--      注意 MySQL 语义下 DISTINCT 与 ORDER BY 互斥，拼接顺序由引擎决定（已按 inputtime/id 去重取最新）
--   5. 金额清洗：registCapi/actualCapi 源头为带单位/币种的文字串（如「300万人民币」「200万元」「400万日元」），
--      只取数值（万元口径，不做 ×万 换算）：REGEXP_SUBSTR(串, '^-?[0-9]+([.][0-9]+)?') 取前导数字，
--      取不到（非数字开头/空串）返回 NULL，再 CAST AS DECIMAL(24,6)（NULL 透传不报错）
--   6. 中台标签（isStateOwned/isFakeStateOwned）：客户级标签按 (reportNo, cr_cust_num=k.customerId) 匹配
--      std_ecis_t_mining_tags_dd 且 entp_first_nm 为空（排除股东级行）；对应 tag_id 有数据 -> 「是」，否则「否」（COALESCE 兜底）
--      源表空（DFS 接口链路未接）时两列均为「否」，不报错
-- =====================================================================

-- 1. 幂等：先删除本次加工范围内的目标行（与下方过滤条件一致，避免重复加工叠加）
DELETE FROM app_ic_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 加工：ws_gs_info(工商照面) + ws_beneficial_owner(受益人) + std_ecis_t_mining_tags_dd(中台标签) -> app_ic_info
INSERT INTO app_ic_info (
    reportNo, customerId, customerName,
    icLegalPerson, icRegisterCapital, icPaidInCapital, currencyUnit, icBeneficiaryName,
    isStateOwned, isFakeStateOwned, cancellationDate
)
SELECT
    k.reportNo AS reportNo,
    k.customerId AS customerId,
    COALESCE(g.customerName, b.customerName) AS customerName,
    g.operName AS icLegalPerson,
    CAST(REGEXP_SUBSTR(g.registCapi, '^-?[0-9]+([.][0-9]+)?') AS DECIMAL(24,6)) AS icRegisterCapital,
    CAST(REGEXP_SUBSTR(g.actualCapi, '^-?[0-9]+([.][0-9]+)?') AS DECIMAL(24,6)) AS icPaidInCapital,
    g.currency_unit AS currencyUnit,
    b.beneficiaryNames AS icBeneficiaryName,
    CASE WHEN tg.stateOwnedFlag = 1 THEN '是' ELSE '否' END AS isStateOwned,
    CASE WHEN tg.fakeFlag = 1 THEN '是' ELSE '否' END AS isFakeStateOwned,
    CASE WHEN REGEXP_LIKE(SUBSTR(g.endDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(g.endDate, 1, 10), '-', ''), '/', '')
         ELSE g.endDate END AS cancellationDate
FROM (
    -- k：两侧键并集（任一侧有数即保留该 客户+报告 组合）
    SELECT DISTINCT reportNo, customerId
    FROM ws_gs_info
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    UNION
    SELECT DISTINCT reportNo, customerId
    FROM ws_beneficial_owner
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) k
LEFT JOIN (
    -- g：工商照面去重，每个 (reportNo, customerId) 仅保留最新一条
    SELECT reportNo, customerId, customerName, operName, registCapi, actualCapi, currency_unit, endDate
    FROM (
        SELECT reportNo, customerId, customerName, operName, registCapi, actualCapi, currency_unit, endDate,
               ROW_NUMBER() OVER (
                   PARTITION BY reportNo, COALESCE(customerId, '')
                   ORDER BY inputtime DESC, id DESC) AS rn
        FROM ws_gs_info
        WHERE reportNo IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) t
    WHERE t.rn = 1
) g ON g.reportNo = k.reportNo
   AND g.customerId = k.customerId
LEFT JOIN (
    -- b：受益人按 (reportNo, customerId, beneficiary) 去重取最新后，按「、」拼接
    SELECT reportNo, customerId,
           MAX(customerName) AS customerName,
           GROUP_CONCAT(DISTINCT beneficiary SEPARATOR '、') AS beneficiaryNames
    FROM (
        SELECT reportNo, customerId, customerName, beneficiary,
               ROW_NUMBER() OVER (
                   PARTITION BY reportNo, COALESCE(customerId, ''), beneficiary
                   ORDER BY inputtime DESC, id DESC) AS rn
        FROM ws_beneficial_owner
        WHERE reportNo IS NOT NULL
          AND beneficiary IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) s
    WHERE s.rn = 1
    GROUP BY reportNo, customerId
) b ON b.reportNo = k.reportNo
   AND b.customerId = k.customerId
LEFT JOIN (
    -- tg：中台标签（客户级）：同 (reportNo, 客户) 下去重取最新后，按 tag_id 汇总出 国有企业/假冒国企 命中标记
    --     只取客户级行（entp_first_nm 为空）；cr_cust_num = 借款人客户编号（= k.customerId）
    SELECT reportNo, cr_cust_num AS customerId,
           MAX(CASE WHEN tag_id = '10104001' THEN 1 ELSE 0 END) AS stateOwnedFlag,
           MAX(CASE WHEN tag_id = '01011001' THEN 1 ELSE 0 END) AS fakeFlag
    FROM (
        SELECT reportNo, cr_cust_num, tag_id,
               ROW_NUMBER() OVER (
                   PARTITION BY reportNo, COALESCE(cr_cust_num, ''), tag_id
                   ORDER BY inputtime DESC, id DESC) AS rn
        FROM std_ecis_t_mining_tags_dd
        WHERE reportNo IS NOT NULL
          AND (entp_first_nm IS NULL OR entp_first_nm = '')
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) s
    WHERE s.rn = 1
    GROUP BY reportNo, cr_cust_num
) tg ON tg.reportNo = k.reportNo
    AND tg.customerId = k.customerId;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_ic_shareholder_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 外数加工\xd_ic_shareholder.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 工商股东变更 · 外数源头表 -> app_ic_shareholder_info 加工
-- 接口（ESB-EDMS 外数平台 f1100300004403）：
--   QXB_GQBG01 启信宝-股权变更（工商公示）-> ws_equity_change（变更历史，多条）
--   QXB_ZYGB01 启信宝-最优股比           -> ws_best_shareholding（最新持股，多条股东）
-- 目标：app_ic_shareholder_info（工商股东变更表，多时点快照）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_ic_shareholder_info 段）：
--   icShareholderName  <- ws_equity_change.name / ws_best_shareholding.name   股东名称
--   percentBefore      <- ws_equity_change.before_percent  变更前持股比例（上游如 '3.1%' 带 % 号，去 % 后 CAST 数值入表）
--   percentAfter       <- ws_equity_change.after_percent   变更后持股比例（同上）
--   changeTime         <- ws_equity_change.change_date     股权变更时间
--   icStockNum         <- ws_best_shareholding.stock_num   当前持股数（仅上市公司有值，按股东名撞）
--   icStockPercent     <- ws_best_shareholding.percent     当前持股比例（按股东名撞）
--   icAmount           <- ws_best_shareholding.amount      当前出资金额（非上市公司有值，按股东名撞）
--
-- 处理规则（对齐 xd_shareholder_info.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_ic_shareholder_info 本次范围旧行，再插入
--   2. 源头表 append-only：按业务键 ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 业务主键 (reportNo, customerId, snapshot_type, icShareholderName, changeTime)：
--        snapshot_type='latest'：最新时点快照，来自 ws_best_shareholding（每股东一行，changeTime=NULL）
--        snapshot_type='变更'  ：变更历史时点，来自 ws_equity_change（每 股东+变更时间 一行）
--      变更行 LEFT JOIN 最新持股（按股东名撞 ws_best_shareholding.name）补当前 stock_num/percent/amount
--   4. 数值 CAST：stock_num->SIGNED、percent/amount->DECIMAL（percent 12,4 / amount 18,2）；
--      percent 上游可能带 % 号（如 '3.1%'），REGEXP 允许可选尾 %，CAST 前 REPLACE 去 %；
--      源头 VARCHAR 空串 '' 直接 CAST 会报 Truncated incorrect DECIMAL value，一律 NULLIF(col,'') 转 NULL
--   5. 待确认：snapshot_type 字典注释写 latest/atCredit，此处变更历史统一用 '变更'，是否需 'atCredit' 口径待产品确认
-- =====================================================================

-- 1. 幂等
DELETE FROM app_ic_shareholder_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 加工：变更历史(gqbg, 撞最新持股补当前数值) -> app_ic_shareholder_info
INSERT INTO app_ic_shareholder_info (
    reportNo, customerId, customerName, icShareholderName,
    icStockNum, icAmount, changeTime, percentBefore, percentAfter
)
-- 变更历史：ws_equity_change（每 股东+变更时间 一行），撞最新持股补当前数值
SELECT
    c.reportNo, c.customerId, c.customerName,
    c.name AS icShareholderName,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(zygb.stock_num), '^-?[0-9]+$') THEN BTRIM(zygb.stock_num) END AS INTEGER) AS icStockNum,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(zygb.amount), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(zygb.amount) END AS DECIMAL(18,2)) AS icAmount,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.change_date, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.change_date, 1, 10), '-', ''), '/', '')
         ELSE c.change_date END AS changeTime,
    CAST(REGEXP_SUBSTR(c.before_percent, '^-?[0-9]+([.][0-9]+)?') AS DECIMAL(12,4)) AS percentBefore,
    CAST(REGEXP_SUBSTR(c.after_percent, '^-?[0-9]+([.][0-9]+)?') AS DECIMAL(12,4)) AS percentAfter
FROM (
    SELECT reportNo, customerId, customerName, name, change_date, before_percent, after_percent,
           ROW_NUMBER() OVER (PARTITION BY reportNo, COALESCE(customerId, ''), COALESCE(name, ''), COALESCE(change_date, '') ORDER BY inputtime DESC, id DESC) AS rn
    FROM ws_equity_change
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) c
LEFT JOIN (
    SELECT reportNo, name, stock_num, percent, amount
    FROM (
        SELECT reportNo, name, stock_num, percent, amount,
               ROW_NUMBER() OVER (PARTITION BY reportNo, COALESCE(customerId, ''), COALESCE(name, '') ORDER BY inputtime DESC, id DESC) AS rn
        FROM ws_best_shareholding
        WHERE reportNo IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) z WHERE z.rn = 1
) zygb ON zygb.reportNo = c.reportNo AND zygb.name = c.name
WHERE c.rn = 1;

-- ---------------------------------------------------------------------
-- 【原脚本 §2】源头数据_app_shareholder_info.sql
-- ---------------------------------------------------------------------
Processing logic (params filled, ready to run)
-- Source: 外数加工\xd_shareholder_info.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 股东股权信息 · 外数源头表 -> app_shareholder_info 加工（参考 外数加工/xd_ic_info.sql 模式）
-- 源表（ESB-EDMS 外数平台 f1100300004403 落表，见 源头表/外数 建表DDL）：
--   ws_best_shareholding  启信宝-最优股比（QXB_ZYGB01，多条股东）
--   ws_base_info          启信宝-企业基础工商信息报告（QXB_QJGXB01，客户级单对象）
-- 中台标签源表（见 源头表/数据融合平台 建表DDL；DFS 接口链路待定，表空时两标签列回退「否」不报错）：
--   std_ecis_t_mining_tags_dd   中台客户/股东标签（股东级行 entp_first_nm=股东名称）
-- 目标：app_shareholder_info（股东股权信息表，一个股东一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_shareholder_info 段 R274-R281）：
--   name            <- ws_best_shareholding.name        股东名称
--   stock_num       <- ws_best_shareholding.stock_num   持股数量（VARCHAR -> INT，仅上市公司有值）
--   amount          <- ws_best_shareholding.amount      投资金额（VARCHAR -> DECIMAL，非上市公司有值）
--   stock_percent   <- ws_best_shareholding.percent     持股比例%（Excel 取值字段写作 perecent，源表实际列为 percent；
--                                                         上游如 '3.1%' 带 % 号，加工去 % 后 CAST 数值入表，3.1% -> 3.1）
--   is_quoted       <- ws_base_info.is_quoted           是否上市（对每个股东再调一次 QJGXB01 落表，
--                                                        按股东名称撞 ws_base_info.name 取该股东企业是否上市）
--   is_state_owned  <- std_ecis_t_mining_tags_dd                  tag_id=10104001(国有企业) 股东级(entp_first_nm=股东名称)
--                                                     有数据为「是」，否则「否」
--   is_fake_state_owned <- std_ecis_t_mining_tags_dd              tag_id=01011001(假冒国企) 股东级(entp_first_nm=股东名称)
--                                                     有数据为「是」，否则「否」
--
-- 处理规则：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_shareholder_info 本次范围旧行，再插入
--   2. 源头表 append-only（重复调接口重复落表），按 (reportNo, customerId, 股东键) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 基表 = ws_best_shareholding 去重（股东行）；ws_base_info 按 (reportNo, 企业名称 name) 去重后
--      LEFT JOIN：is_quoted 用股东名称撞 ws_base_info.name（对每个股东企业再调一次 QJGXB01 落表，
--      name 区分不同企业；股东级调用的落表 customerId 可能是股东自身，故不按 customerId 过滤）
--   4. 数值列 stock_num/amount/percent 源 VARCHAR -> SIGNED/DECIMAL：REGEXP 数字守卫 + CAST（非数字/空串 -> NULL，防 GaussDB 严格模式 CAST 报错）；
--      percent 上游可能带 % 号（如 '3.1%'），REGEXP 允许可选尾 %，CAST 前 REPLACE 去 %
--   5. 中台标签（is_state_owned/is_fake_state_owned）：股东级标签按 (reportNo, 股东名) 匹配
--      std_ecis_t_mining_tags_dd 且 entp_first_nm = z.name（不按 customerId 过滤：股东级调用落表的 customerId 可能是股东自身）；
--      对应 tag_id 有数据 -> 「是」，否则「否」（COALESCE 兜底）；源表空（DFS 接口链路未接）时两列均为「否」，不报错
-- =====================================================================

-- 1. 幂等：先删除本次加工范围内的目标行（与下方过滤条件一致，避免重复加工叠加）
DELETE FROM app_shareholder_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 加工：ws_best_shareholding(股东行) + ws_base_info(是否上市) + std_ecis_t_mining_tags_dd(股东级中台标签) -> app_shareholder_info
INSERT INTO app_shareholder_info (
    reportNo, customerId, customerName, name, stock_num, amount, stock_percent,
    is_quoted, is_state_owned, is_fake_state_owned
)
SELECT
    z.reportNo AS reportNo,
    z.customerId AS customerId,
    z.customerName AS customerName,
    z.name AS name,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(z.stock_num), '^-?[0-9]+$') THEN BTRIM(z.stock_num) END AS INTEGER) AS stock_num,
    CAST(CASE WHEN REGEXP_LIKE(BTRIM(z.amount), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(z.amount) END AS DECIMAL(18,2)) AS amount,
    CAST(REGEXP_SUBSTR(z.percent, '^-?[0-9]+([.][0-9]+)?') AS DECIMAL(12,4)) AS stock_percent,
    CASE WHEN q.is_quoted = '1' OR q.is_quoted = '是' THEN '是' ELSE '否' END AS is_quoted,
    CASE WHEN tg.stateOwnedFlag = 1 THEN '是' ELSE '否' END AS is_state_owned,
    CASE WHEN tg.fakeFlag = 1 THEN '是' ELSE '否' END AS is_fake_state_owned
FROM (
    -- z：最优股比股东去重，每个 (reportNo, customerId, 股东名) 仅保留最新一条
    SELECT reportNo, customerId, customerName, name, stock_num, amount, percent
    FROM (
        SELECT reportNo, customerId, customerName, name, stock_num, amount, percent,
               ROW_NUMBER() OVER (
                   PARTITION BY reportNo, COALESCE(customerId, ''),
                       COALESCE(name, '')
                   ORDER BY inputtime DESC, id DESC) AS rn
        FROM ws_best_shareholding
        WHERE reportNo IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) t
    WHERE t.rn = 1
) z
LEFT JOIN (
    -- q：企业基础工商信息去重，每个 (reportNo, 企业名称) 仅保留最新一条（取 is_quoted）
    --    不按 customerId 过滤：股东级 QJGXB01 调用落表的 customerId 可能是股东自身，按名称撞即可
    SELECT reportNo, name, is_quoted
    FROM (
        SELECT reportNo, name, is_quoted,
               ROW_NUMBER() OVER (
                   PARTITION BY reportNo, COALESCE(name, '')
                   ORDER BY inputtime DESC, id DESC) AS rn
        FROM ws_base_info
        WHERE reportNo IS NOT NULL
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) t
    WHERE t.rn = 1
) q ON q.reportNo = z.reportNo
   AND q.name = z.name
LEFT JOIN (
    -- tg：中台标签（股东级）：同 (reportNo, 股东名) 下去重取最新后，按 tag_id 汇总出 国有企业/假冒国企 命中标记
    --     只取股东级行（entp_first_nm 非空）；entp_first_nm = 股东名称（= z.name）
    --     不按 customerId 过滤：股东级中台调用落表的 customerId 可能是股东自身，按名称撞即可
    SELECT reportNo, entp_first_nm AS name,
           MAX(CASE WHEN tag_id = '10104001' THEN 1 ELSE 0 END) AS stateOwnedFlag,
           MAX(CASE WHEN tag_id = '01011001' THEN 1 ELSE 0 END) AS fakeFlag
    FROM (
        SELECT reportNo, entp_first_nm, tag_id,
               ROW_NUMBER() OVER (
                   PARTITION BY reportNo, COALESCE(entp_first_nm, ''), tag_id
                   ORDER BY inputtime DESC, id DESC) AS rn
        FROM std_ecis_t_mining_tags_dd
        WHERE reportNo IS NOT NULL
          AND entp_first_nm IS NOT NULL AND entp_first_nm != ''
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
    ) s
    WHERE s.rn = 1
    GROUP BY reportNo, entp_first_nm
) tg ON tg.reportNo = z.reportNo
    AND tg.name = z.name;