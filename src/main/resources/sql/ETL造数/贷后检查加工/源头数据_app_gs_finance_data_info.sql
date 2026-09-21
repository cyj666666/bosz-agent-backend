-- =====================================================================
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
DELETE FROM dfs_crdt_loan_cust_rel   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

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
-- Processing logic (params filled, ready to run)
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
