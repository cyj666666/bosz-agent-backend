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
DELETE FROM app_gs_tax_sales_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM dfs_crdt_loan_cust_rel WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. dfs_crdt_loan_cust_rel（数据融合平台·信贷客户关联信息）
--    列：reportNo, customerId, customerName, mon_sale_amt, dt, inputtime
--    1 行（去重键 reportNo+customerId 按 dt DESC 取最新，单行即最新）
--    mon_sale_amt 含 2025(12月)+2026(8月) 共 20 个元素，顺序：202501..202512|202601..202608
-- =====================================================================
INSERT INTO dfs_crdt_loan_cust_rel (
    reportNo, customerId, customerName, mon_sale_amt, dt, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
    '202501:120|202502:95|202503:110|202504:105|202505:130|202506:125|202507:115|202508:140|202509:135|202510:150|202511:145|202512:160|202601:100|202602:85|202603:105|202604:95|202605:115|202606:110|202607:100|202608:120',
    '202608', '2026-09-11 17:00:00'
);

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
-- Processing logic (params filled, ready to run)
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
        e.reportNo, e.customerId, e.customerName, e.mkey, e.yr, e.mon, e.amt,
        SUM(e.amt) OVER (PARTITION BY e.reportNo, e.customerId, e.yr ORDER BY e.mon) AS ytd,
        MAX(e.yr)  OVER (PARTITION BY e.reportNo, e.customerId)                     AS curYr
    FROM (
        -- e：拆元素（yr/mon 数值化、amt 空=0、hasval 标记有值月）
        SELECT
            reportNo, customerId, customerName,
            elkey                                          AS mkey,
            CAST(SUBSTRING(elkey, 1, 4) AS INTEGER)         AS yr,
            CAST(SUBSTRING(elkey, 5, 2) AS INTEGER)         AS mon,
            CAST(CASE WHEN elval IS NULL OR elval = '' THEN '0' ELSE elval END AS DECIMAL(18,2)) AS amt
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
    WHERE r.amt > 0
  ) x
WHERE x.prn = 1
ORDER BY x.taxPeriod;
