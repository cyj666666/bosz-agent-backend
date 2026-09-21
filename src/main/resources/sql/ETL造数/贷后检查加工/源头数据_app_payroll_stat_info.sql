-- =====================================================================
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
DELETE FROM dfs_crdt_loan_cust_rel WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. dfs_crdt_loan_cust_rel（数据融合平台·信贷客户关联信息）
--    列：reportNo, customerId, customerName,
--        instd_sal_moly, instd_sal_person_moly, instd_sal_amt_moly,
--        instd_sal_person_moly_hb, instd_sal_amt_moly_hb,
--        instd_sal_person_moly_tb, instd_sal_amt_moly_tb, dt, inputtime
--    1 行（去重键 reportNo+customerId 按 dt DESC 取最新，单行即最新）
--    7 个代发列各 12 个月数据；环比列稀疏（202603 首月无 MoM）
-- =====================================================================
INSERT INTO dfs_crdt_loan_cust_rel (
    reportNo, customerId, customerName,
    instd_sal_moly, instd_sal_person_moly, instd_sal_amt_moly,
    instd_sal_person_moly_hb, instd_sal_amt_moly_hb,
    instd_sal_person_moly_tb, instd_sal_amt_moly_tb, dt, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
    -- instd_sal_moly: 12 个月份键
    '202603|202604|202605|202606|202607|202608|202609|202610|202611|202612|202701|202702',
    -- instd_sal_person_moly: 每月代发人数
    '202603:1280|202604:1315|202605:1298|202606:1342|202607:1376|202608:1358|202609:1405|202610:1428|202611:1396|202612:1462|202701:1490|202702:1516',
    -- instd_sal_amt_moly: 每月代发金额（万元）
    '202603:856.32|202604:889.75|202605:872.40|202606:910.18|202607:936.52|202608:921.06|202609:958.44|202610:973.20|202611:949.88|202612:1005.36|202701:1028.75|202702:1052.40',
    -- instd_sal_person_moly_hb: 每月人数环比（稀疏，202603 首月无 MoM）
    '202604:0.0273|202605:-0.0129|202606:0.0339|202607:0.0253|202608:-0.0131|202609:0.0346|202610:0.0164|202611:-0.0224|202612:0.0473|202701:0.0192|202702:0.0174',
    -- instd_sal_amt_moly_hb: 每月金额环比（稀疏，202603 首月无 MoM）
    '202604:0.0390|202605:-0.0195|202606:0.0433|202607:0.0289|202608:-0.0165|202609:0.0406|202610:0.0154|202611:-0.0240|202612:0.0584|202701:0.0233|202702:0.0230',
    -- instd_sal_person_moly_tb: 每月人数同比（12 月全有）
    '202603:0.0821|202604:0.0756|202605:0.0643|202606:0.0918|202607:0.0887|202608:0.0724|202609:0.1052|202610:0.0978|202611:0.0835|202612:0.1126|202701:0.1189|202702:0.1243',
    -- instd_sal_amt_moly_tb: 每月金额同比（12 月全有）
    '202603:0.0912|202604:0.0834|202605:0.0715|202606:0.1023|202607:0.0968|202608:0.0811|202609:0.1136|202610:0.1044|202611:0.0902|202612:0.1218|202701:0.1265|202702:0.1327',
    '202702', '2026-09-10 23:00:00'
);

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
-- Processing logic (params filled, ready to run)
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
