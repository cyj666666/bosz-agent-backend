-- =====================================================================
-- app_check_opinion_info（对公日检-批复后续管理要求）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_check_opinion.sql
-- 源表（父子表，mainId -> xd_corp_check_info.id=1，父表共享自 app_check_index_info）：
--   xd_corp_check_reply_requirement   批复后续管理要求 CheckFollowUpRequirement
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_check_opinion.sql，10 列）：
--   conditionDesc         <- condition                后续管理要求内容（源 VARCHAR(1000) -> app TEXT）
--   completeStatus        <- completeStatus           完成状态（原样透传）
--   conditionInstruction  <- conditionInstruction     要求说明（源 VARCHAR(1000) -> app TEXT）
--   realCompleteTime      <- realCompleteTime         实际完成时间（VARCHAR(64) -> app VARCHAR(32)）
--                          正则 ^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$ 命中去 -/；不命中原样透传
--   itemCategory          <- itemCategory             事项类别
--   去重键 (reportNo, customerId, condition) ROW_NUMBER(inputtime DESC, id DESC)；先 JOIN 当前主档
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202603-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：5
--   realCompleteTime 源 = '2026-08-31'（YYYY-MM-DD）-> 加工去 - -> '20260831'，
--   app 列若为 DATE 类型，存储回 '2026-08-31 00:00:00'（与目标 DML 一致）
--
-- 共享父表：xd_corp_check_info id=1（来自 app_check_index_info 文件，本文件条件 IF NOT EXISTS 跳过创建）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源子表（不动父表 id=1）
-- =====================================================================
DELETE FROM app_check_opinion_info            WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_corp_check_reply_requirement   WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';

-- =====================================================================
-- 1. xd_corp_check_info（共享父表，条件创建：仅当 id=1 不存在时插入）
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
SELECT 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 10:30:00'
WHERE NOT EXISTS (SELECT 1 FROM xd_corp_check_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001');

-- =====================================================================
-- 2. xd_corp_check_reply_requirement（批复后续管理要求，5 行）
--    mainId=1；condition/completeStatus/conditionInstruction/realCompleteTime/itemCategory 全部直映目标 DML
--    realCompleteTime 源用 '2026-08-31'（YYYY-MM-DD），加工去 - 后 '20260831'，app 列 DATE 回填 '2026-08-31 00:00:00'
-- =====================================================================
INSERT INTO xd_corp_check_reply_requirement (
    mainId, reportNo, customerId, customerName, condition, completeStatus,
    conditionInstruction, realCompleteTime, itemCategory, inputtime
) VALUES
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '关注原材料价格波动对生产成本的影响，关注主要客户合作稳定性及订单变化情况。',
 '持续关注',
 '本年主要原材料采购成本较上年同期上涨约8%，企业已通过调整采购策略部分对冲影响；前五大客户合作协议均已续签，订单量同比基本持平',
 '2026-08-31', '08', '2026-08-31 17:30:00'),
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '关注对外担保风险，定期核查被担保企业经营状况及偿债能力变化。',
 '持续关注',
 '目前对外担保余额合计1,200万元，被担保企业生产经营正常，未发现代偿风险信号',
 '2026-08-31', '08', '2026-08-31 17:30:00'),
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '结算回笼资金归行率不低于30%，按月监测销售回款及资金流向，确保贷款资金用途合规。',
 '持续关注',
 '本月销售回款1,850万元，归行率约35%，符合批复要求；贷款资金用途均与约定用途一致，未发现挪用情况',
 '2026-08-31', '08', '2026-08-31 17:30:00'),
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '关注环保政策及行业准入变化对企业生产经营的影响，定期核查安全生产合规情况。',
 '持续关注',
 '企业已取得最新排污许可证，本年度环保检查合格；行业准入方面未发生重大不利变化',
 '2026-08-31', '08', '2026-08-31 17:30:00'),
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '资产负债率不得高于50%，每季度监测资产负债结构变化，确保财务杠杆水平在可控范围内。',
 '持续关注',
 '本期资产负债率58.2%，已超出批复要求8.2个百分点，主要系短期借款增加所致，已督促企业制定降负债方案',
 '2026-08-31', '08', '2026-08-31 17:35:00');

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工/xd_check_opinion.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202603-001'）
--   2. 加工产出 5 行，业务字段与目标 DML 完全一致：
--      - conditionDesc/completeStatus/conditionInstruction/itemCategory 直映 ✓
--      - realCompleteTime 源 '2026-08-31' -> 去分隔符 -> '20260831' -> app DATE 回填 '2026-08-31 00:00:00' ✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..5）
--   4. app_check_opinion_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中 '2026-08-31 17:30:00.0' / '17:35:00.0' 无法精确复现
--
--   -- ISSUE: 目标 DML 中第 3 行 conditionDesc 为
--      '...按月监测销售回款及资金流向，确保贷款资金用途合规。'
--      而原始业务材料（节选）可能写作 '...资金归集情况...'，
--      此处以目标 DML 实际文本为准（conditionDesc 直映），源表 = 目标值。
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_check_opinion.sql
-- Params: customerId='CUST-001', reportNo='RPT-202603-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》批复后续管理要求 · 源头表 -> app_check_opinion_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info                对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_reply_requirement   批复后续管理要求 CheckFollowUpRequirement（mainId -> xd_corp_check_info.id）
-- 目标：app_check_opinion_info（业务主键 reportNo + customerId + conditionDesc）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_check_opinion_info 段）：
--   conditionDesc         <- condition                后续管理要求内容（源 VARCHAR(1000) -> app TEXT）
--   completeStatus        <- completeStatus           完成状态（码值：已完成/未完成/部分完成/持续关注，待确认，原样透传）
--   conditionInstruction  <- conditionInstruction     要求说明（源 VARCHAR(1000) -> app TEXT）
--   realCompleteTime      <- realCompleteTime         实际完成时间（源 VARCHAR(64) -> app VARCHAR(32)，LEFT 截断）
--   itemCategory          <- itemCategory             事项类别
--   （源表 replySerialNo/relativeSerialNo/expectedCompletionExactDate/checkDate 目标表无列，不加工）
--
-- 处理规则（对齐 xd_collateral.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_check_opinion_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按 conditionDesc ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 一次日检可有多条要求（不同内容），各出一行；全字段字符串直映（仅 realCompleteTime 截断）
-- =====================================================================

-- 1. 幂等
DELETE FROM app_check_opinion_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL);

-- 2. 批复后续管理要求：xd_corp_check_reply_requirement（JOIN 当前主档）-> app_check_opinion_info
INSERT INTO app_check_opinion_info (
    reportNo, customerId, customerName, conditionDesc, completeStatus, conditionInstruction, realCompleteTime, itemCategory
)
SELECT
    c.reportNo, c.customerId, c.customerName,
    c.condition AS conditionDesc,
    c.completeStatus,
    c.conditionInstruction,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.realCompleteTime, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.realCompleteTime, 1, 10), '-', ''), '/', '')
         ELSE c.realCompleteTime END AS realCompleteTime,
    -- 事项类别：码值->中文（01担保落实/02佐证材料收集/03额度压降/04资金到位/06监管账户/07资金归集/08管理要求），NULL/未收录原样保留
    CASE c.itemCategory
        WHEN '01' THEN '担保落实'
        WHEN '02' THEN '佐证材料收集'
        WHEN '03' THEN '额度压降'
        WHEN '04' THEN '资金到位'
        WHEN '06' THEN '监管账户'
        WHEN '07' THEN '资金归集'
        WHEN '08' THEN '管理要求'
        ELSE c.itemCategory
    END AS itemCategory
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.condition, c.completeStatus,
           c.conditionInstruction, c.realCompleteTime, c.itemCategory,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.condition, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_reply_requirement c
    JOIN (
        SELECT id FROM (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_info
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
        ) mc WHERE mc.rn = 1
    ) m ON c.mainId = m.id
) c
WHERE c.rn = 1;
