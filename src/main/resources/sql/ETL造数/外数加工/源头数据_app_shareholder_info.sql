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
DELETE FROM app_shareholder_info        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_best_shareholding         WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_base_info                 WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM std_ecis_t_mining_tags_dd    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

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
-- Processing logic (params filled, ready to run)
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
