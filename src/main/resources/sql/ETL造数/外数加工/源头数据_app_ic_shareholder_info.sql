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
DELETE FROM app_ic_shareholder_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_best_shareholding    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_equity_change        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. ws_best_shareholding（启信宝最优股比，顶层表，最新持股行）
--    用于 2b 变更行 LEFT JOIN 撞股东名补 icStockNum / icAmount
--    注意：此 4 行同时触发 2a 最新快照加工，会额外产出 4 行（见 ISSUE 2）
--    泰州公司 icStockNum=3000000 / 股东B/C icStockNum=2000000 / 股东D icStockNum=1000000
-- =====================================================================
INSERT INTO ws_best_shareholding (reportNo, customerId, customerName, name, stock_num, amount, percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '泰州公司', '3000000', '3000000.00', '30.00%', '2026-09-15 10:00:00');
INSERT INTO ws_best_shareholding (reportNo, customerId, customerName, name, stock_num, amount, percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '股东B', '2000000', '2000000.00', '30.00%', '2026-09-15 10:00:00');
INSERT INTO ws_best_shareholding (reportNo, customerId, customerName, name, stock_num, amount, percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '股东C', '2000000', '2000000.00', '0.00%', '2026-09-15 10:00:00');
INSERT INTO ws_best_shareholding (reportNo, customerId, customerName, name, stock_num, amount, percent, inputtime)
VALUES ('RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '股东D', '1000000', '1000000.00', '21.00%', '2026-09-15 10:00:00');

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
-- Processing logic (params filled, ready to run)
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
    zygb.stock_num AS icStockNum,
    zygb.amount AS icAmount,
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
