-- =====================================================================
-- app_settle_counterparty_info（结算交易对手）源头表反推造数
-- 加工脚本：贷后检查加工/xd_settle_counterparty.sql
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（dbt_cntpr_and_acr_amt / cr_cntpr_and_acr_amt，append-only）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；SPLIT_PART 取段）
--
-- 字段映射（xd_settle_counterparty.sql）：
--   counterpartyName <- SPLIT_PART(元素, ':', 1)   交易对手名称
--   direction        <- 借方(dbt 串) / 贷方(cr 串)
--   amount           <- CAST(SPLIT_PART(元素, ':', 2) AS DECIMAL)  发生额（万元）
--   rankNo           <- DENSE_RANK() OVER (PARTITION direction ORDER BY amount DESC) → CAST AS CHAR(16)
--   upstreamFlag/remark <- 不加工（字典标「删除/未执行」，默认 NULL）
--   id/inputtime    <- app 表 AUTO_INCREMENT / DEFAULT CURRENT_TIMESTAMP（自动）
--
-- 源头字段格式（2 列各存「前十大」，| 分隔，每元素 name:amt）：
--   dbt_cntpr_and_acr_amt  借方：name:amt|name:amt|...
--   cr_cntpr_and_acr_amt   贷方：name:amt|name:amt|...
--
-- -- ISSUE 1: 加工 SQL CROSS JOIN 序号仅 1..10，每方向最多 10 行；DML 目标 40 行（借/贷各 20）
--   当前 SQL 仅能产出 20 行（借/贷各 10），DML 的 20-40 号行（TOP11-TOP20）无法产出。
-- -- ISSUE 2: rankNo 格式差异：加工 SQL 输出 CAST(dr AS CHAR(16)) = '1'/'2'/...；
--   DML 目标为 'TOP1'/'TOP2'/...（含 'TOP' 前缀），格式不一致。
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表，customerId='CUST-001'
-- =====================================================================
DELETE FROM app_settle_counterparty_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM dfs_crdt_loan_cust_rel       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. dfs_crdt_loan_cust_rel（数据融合平台·信贷客户关联信息）
--    列：reportNo, customerId, customerName,
--        dbt_cntpr_and_acr_amt, cr_cntpr_and_acr_amt, dt, inputtime
--    1 行（去重键 reportNo+customerId 按 dt DESC 取最新，单行即最新）
--    借方 20 元素 + 贷方 20 元素（均按发生额降序）
-- =====================================================================
INSERT INTO dfs_crdt_loan_cust_rel (
    reportNo, customerId, customerName,
    dbt_cntpr_and_acr_amt, cr_cntpr_and_acr_amt, dt, inputtime
) VALUES (
    'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
    -- 借方 19 个交易对手（TOP1-TOP19，按发生额降序）
    '江苏恒力特钢有限公司:1250.50|上海精工轴承有限公司:1180.30|无锡泰达电机有限公司:1050.80|常州瑞新机械配件有限公司:980.60|宁波海天精密工业有限公司:920.40|杭州智造装备有限公司:880.20|南京自动化科技有限公司:850.00|合肥中科智能装备有限公司:820.75|苏州华鑫金属材料有限公司:790.50|上海宝钢贸易有限公司:730.00|浙江联创机械有限公司:700.80|安徽合力叉车有限公司:680.40|山东临工机械有限公司:660.20|徐工集团工程机械有限公司:640.00|三一重工股份有限公司:620.50|中联重科股份有限公司:600.30|广西柳工机械股份有限公司:580.10|厦门厦工机械股份有限公司:560.00|山推工程机械股份有限公司:540.60',
    -- 贷方 20 个交易对手（TOP1-TOP20，按发生额降序）
    '苏州工业园区联合贸易有限公司:1500.00|上海东浩国际贸易有限公司:1420.50|南京金陵机械有限公司:1350.80|杭州万向传动轴有限公司:1280.30|宁波均胜电子股份有限公司:1200.00|合肥美菱股份有限公司:1150.60|无锡威孚高科技集团股份有限公司:1100.40|常州星宇车灯股份有限公司:1050.20|江苏沙钢集团有限公司:1000.00|浙江吉利控股集团有限公司:950.80|安徽江淮汽车集团股份有限公司:900.50|山东重工集团有限公司:860.30|徐州工程机械集团有限公司:820.10|三一集团有限公司:780.00|中联重科股份有限公司:740.60|广西玉柴机器集团有限公司:700.40|厦门金龙联合汽车工业有限公司:660.20|山推工程机械股份有限公司:620.00|苏州创元投资发展有限公司:580.80|上海电气集团股份有限公司:540.60',
    '20260911', '2026-09-11 11:43:00'
);

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 贷后检查加工/xd_settle_counterparty.sql（带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 借方/贷方前 10 名的 counterpartyName/direction/amount 3 列与 DML TOP1-TOP10 完全一致：
--      借方 TOP1: 江苏恒力特钢有限公司/借方/1250.50 ✓
--      借方 TOP2: 上海精工轴承有限公司/借方/1180.30 ✓ ...（依此类推至 TOP10）
--      贷方 TOP1: 苏州工业园区联合贸易有限公司/贷方/1500.00 ✓ ...（依此类推至 TOP10）
--   3. upstreamFlag/remark 2 列 DML 为 NULL，加工 SQL 不插入，默认 NULL ✓
--   4. id 为 AUTO_INCREMENT（空表起算，ORDER BY direction, amount DESC）
--   5. app_settle_counterparty_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP，DML 时间戳无法复现
--
--   ISSUE 1（见文件头）：CROSS JOIN 仅 1..10，每方向最多 10 行
--   - DML 目标 40 行（借/贷各 20），当前 SQL 仅产出 20 行（借/贷各 10）
--   - 借方 TOP11-TOP20 / 贷方 TOP11-TOP20 无法产出（源数据已提供 20 个，但 SQL 只取前 10）
--
--   ISSUE 2（见文件头）：rankNo 格式差异
--   - 加工 SQL: CAST(DENSE_RANK() AS CHAR(16)) = '1'/'2'/...'10'
--   - DML 目标: 'TOP1'/'TOP2'/...'TOP10'（含 'TOP' 前缀）
--   - 格式不一致，DML 疑似由更早版本（含 'TOP' 前缀格式化）生成
--
--   6. 共用源表注意：见 settle_account 文件头注释（dfs_crdt_loan_cust_rel 为多 app 表共用）
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 贷后检查加工\xd_settle_counterparty.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 结算》结算交易对手 · 源头表 -> app_settle_counterparty_info 加工
-- 节点：数据融合平台 dfsDataQry》信贷客户关联信息
--       （adm_stas_plma_crdt_loan_cust_rel_info，DfsDataQryService.queryCrdtLoanCustRelInfo 落表）
-- 源表：
--   dfs_crdt_loan_cust_rel  数据融合平台·信贷客户关联信息（结算/代发等经营字段，append-only）
-- 目标：app_settle_counterparty_info（结算交易对手表，业务主键 reportNo + customerId + direction + counterpartyName，
--       一个「方向 + 交易对手」一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式；字符串拼接用 CONCAT 不用 ||，定位/取段用 SPLIT_PART）
--
-- 源头字段格式（2 列各存「前十大」交易对手，| 分隔；依据中台样例）：
--   dbt_cntpr_and_acr_amt   前十大借方：name:amt|name:amt|...   （如 昊中电缆:313500|待核预算:772472.6|昆山电缆:259071.5|...）
--   cr_cntpr_and_acr_amt    前十大贷方：name:amt|name:amt|...
-- 注意：源数组顺序并非按发生额排序（样例 313500 在前、772472.6 在后），rankNo 不能直接用数组位置，
--       必须「按方向分组、按发生额降序」计算（见下 DENSE_RANK）。
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_settle_counterparty_info 段）：
--   counterpartyName <- 交易对手名称（dbt 串 name 段 / cr 串 name 段）
--   direction        <- 方向（dbt 串=借方 / cr 串=贷方）
--   amount           <- 发生额（万元）（dbt 串 amt 段 / cr 串 amt 段，VARCHAR->DECIMAL(18,2)）
--   rankNo           <- 排名 TOP1-10（按发生额降序、借方/贷方分开排；同额并列同号 DENSE_RANK，次位按名称保证确定性）
--   upstreamFlag / remark  字典标「删除/未执行」，不加工
--
-- 处理规则（对齐 xd_payroll.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_settle_counterparty_info 本次范围旧行，再插入
--   2. 取最新一个 dt：dfs_crdt_loan_cust_rel 为 append-only，按 (reportNo, customerId) 内
--      ROW_NUMBER() ORDER BY (dt 是否空) 升序、dt DESC、inputtime DESC、id DESC 取 rn=1（最新 dt 一行）
--   3. 按「方向 + 交易对手」拆分：UNION ALL 借方（dbt 串）/贷方（cr 串）两源，各 CROSS JOIN 序号 1..10，
--      SPLIT_PART 取第 n 个 name:amt 元素再按 ':' 拆 name / amt；超过实际个数的序号返回空串，过滤掉
--   4. 按发生额降序、借方/贷方分开算 rankNo：DENSE_RANK() OVER (PARTITION BY customerId, direction ORDER BY amount DESC, counterpartyName)
--      （customerId 入分组保证多客户同批加工时各客户排名互不串扰；正常按单客户调用时为空操作）
--      取 1..N；TOP10 上限（DENSE_RANK <= 10，前十大数组本身 <=10 个元素，正常不触发，作兜底）
--   5. CAST：发生额 VARCHAR->DECIMAL(18,2)。空/缺失元素由 SPLIT_PART 空串过滤（无数字 CAST 风险）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_settle_counterparty_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 结算交易对手：取最新 dt 一行 -> 借方/贷方各拆 1..10 -> 按发生额降序分方向算 rankNo -> app_settle_counterparty_info
INSERT INTO app_settle_counterparty_info (
    reportNo, customerId, customerName, counterpartyName, direction, amount, rankNo
)
SELECT
    r.reportNo,
    r.customerId,
    r.customerName,
    r.counterpartyName,
    r.direction,
    r.amount,
    CAST(r.dr AS CHAR(16)) AS rankNo
FROM (
    SELECT
        d.*,
        DENSE_RANK() OVER (PARTITION BY d.customerId, d.direction ORDER BY d.amount DESC, d.counterpartyName) AS dr
    FROM (
        -- d：按业务主键 (reportNo, customerId, counterpartyName, direction) 去重，保留发生额最大的一行
        SELECT
            s.reportNo, s.customerId, s.customerName, s.counterpartyName, s.direction, s.amount,
            ROW_NUMBER() OVER (
                PARTITION BY s.reportNo, COALESCE(s.customerId, ''), COALESCE(s.counterpartyName, ''), s.direction
                ORDER BY s.amount DESC
            ) AS dup_rn
        FROM (
            -- s：借方/贷方两源 UNION ALL，各按 1..10 拆出「方向 + 交易对手 + 发生额」
            SELECT
                b.reportNo, b.customerId, b.customerName,
                SPLIT_PART(b.e, ':', 1)                  AS counterpartyName,
                '借方'                                    AS direction,
                CAST(SPLIT_PART(b.e, ':', 2) AS DECIMAL(18,2)) AS amount
            FROM (
                SELECT reportNo, customerId, customerName,
                       SPLIT_PART(dbt_cntpr_and_acr_amt, '|', n.n) AS e
                FROM (
                    SELECT reportNo, customerId, customerName, dbt_cntpr_and_acr_amt,
                           ROW_NUMBER() OVER (
                               PARTITION BY reportNo, COALESCE(customerId, '')
                               ORDER BY CASE WHEN dt IS NULL THEN 1 ELSE 0 END ASC,
                                        dt DESC, inputtime DESC, id DESC
                           ) AS rn
                    FROM dfs_crdt_loan_cust_rel
                    WHERE reportNo IS NOT NULL
                      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
                ) x
                CROSS JOIN (
                    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
                    UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
                    UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
                ) n
                WHERE x.rn = 1
                  AND SPLIT_PART(x.dbt_cntpr_and_acr_amt, '|', n.n) IS NOT NULL
                  AND SPLIT_PART(x.dbt_cntpr_and_acr_amt, '|', n.n) <> ''
            ) b
            UNION ALL
            SELECT
                c.reportNo, c.customerId, c.customerName,
                SPLIT_PART(c.e, ':', 1)                  AS counterpartyName,
                '贷方'                                    AS direction,
                CAST(SPLIT_PART(c.e, ':', 2) AS DECIMAL(18,2)) AS amount
            FROM (
                SELECT reportNo, customerId, customerName,
                       SPLIT_PART(cr_cntpr_and_acr_amt, '|', n.n) AS e
                FROM (
                    SELECT reportNo, customerId, customerName, cr_cntpr_and_acr_amt,
                           ROW_NUMBER() OVER (
                               PARTITION BY reportNo, COALESCE(customerId, '')
                               ORDER BY CASE WHEN dt IS NULL THEN 1 ELSE 0 END ASC,
                                        dt DESC, inputtime DESC, id DESC
                           ) AS rn
                    FROM dfs_crdt_loan_cust_rel
                    WHERE reportNo IS NOT NULL
                      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
                      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
                ) y
                CROSS JOIN (
                    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
                    UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
                    UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
                ) n
                WHERE y.rn = 1
                  AND SPLIT_PART(y.cr_cntpr_and_acr_amt, '|', n.n) IS NOT NULL
                  AND SPLIT_PART(y.cr_cntpr_and_acr_amt, '|', n.n) <> ''
            ) c
        ) s
    ) d
    WHERE d.dup_rn = 1
) r
WHERE r.dr <= 20
ORDER BY r.direction, r.amount DESC;
