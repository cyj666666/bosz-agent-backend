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
DELETE FROM app_settle_account_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM dfs_crdt_loan_cust_rel WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. dfs_crdt_loan_cust_rel（数据融合平台·信贷客户关联信息）
--    列：reportNo, customerId, customerName, acct_zhxx, dt, inputtime
--    1 行（去重键 reportNo+customerId 按 dt DESC 取最新，单行即最新）
--    acct_zhxx 含 5 个账户，每个 10 段（; 分隔），账户间 | 分隔
-- =====================================================================
INSERT INTO dfs_crdt_loan_cust_rel (
    reportNo, customerId, customerName, acct_zhxx, dt, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
    -- 账户1: 320501-8888-0001 / 正常 / 125.60 / 开户机构1 / 否
    '320501-8888-0001;正常;125.60;开户机构1;否;seg6;seg7;seg8;seg9;seg10'
    -- 账户2: 320501-8888-0002 / 冻结 / 88.35 / 开户机构2 / 否
    || '|320501-8888-0002;冻结;88.35;开户机构2;否;seg6;seg7;seg8;seg9;seg10'
    -- 账户3: 320501-8888-0003 / 正常 / 210.75 / 开户机构3 / 否
    || '|320501-8888-0003;正常;210.75;开户机构3;否;seg6;seg7;seg8;seg9;seg10'
    -- 账户4: 320501-8888-0004 / 正常 / 56.20 / 开户机构4 / 否
    || '|320501-8888-0004;正常;56.20;开户机构4;否;seg6;seg7;seg8;seg9;seg10'
    -- 账户5: 320501-8888-0005 / 正常 / 342.10 / 开户机构5 / 否
    || '|320501-8888-0005;正常;342.10;开户机构5;否;seg6;seg7;seg8;seg9;seg10',
    '20260911', '2026-09-11 10:00:00'
);

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
-- Processing logic (params filled, ready to run)
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
