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
DELETE FROM app_settle_asset_info   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM dfs_crdt_loan_cust_rel  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

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
INSERT INTO dfs_crdt_loan_cust_rel (
    reportNo, customerId, customerName,
    fzn_amt, hnym_tfrd_amt_dbt_pcnt, hnym_tfrd_amt_cr_pcnt,
    dep_y_avg_bal, yr_pty_income, yr_pty_income_ch, yr_pty_income_regy,
    elec_income, elec_income_ch, elec_income_regy,
    cr_acr_amt_1, cr_acr_amt_2, dt, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
    -- 3 单值列（直接 CAST）
    '88.35',   '12.50',  '15.80',
    -- dep 固定当年/去年段
    '当年:286.45|去年:245.30',
    -- 物业 3 列（selIdx=1 取当年段）
    '当年:156.80|去年:0',
    '当年:23.60|去年:0',
    '当年:45.20|去年:0',
    -- 电费 3 列（selIdx=1 取当年段）
    '当年:78.50|去年:0',
    '当年:-5.30|去年:0',
    '当年:20.10|去年:0',
    -- 关键字 2 列（selIdx=1 取当年段）
    '当年:85.50|去年:0',
    '当年:120.00|去年:0',
    '20260911', '2026-09-11 11:00:00'
);

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
-- Processing logic (params filled, ready to run)
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
