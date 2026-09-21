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
DELETE FROM app_ic_info                WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_gs_info                 WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM ws_beneficial_owner        WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM std_ecis_t_mining_tags_dd  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

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
-- Processing logic (params filled, ready to run)
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
