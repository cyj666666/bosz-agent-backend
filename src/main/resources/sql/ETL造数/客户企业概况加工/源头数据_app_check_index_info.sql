-- =====================================================================
-- app_check_index_info（对公日检-日常检查综合指标）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_check_index.sql
-- 源表（父子表）：
--   xd_corp_check_info          对公检查主档（父表；按 reportNo 取最新 id 作为「当前主档」）
--   xd_corp_check_daily_index   日常检查综合指标（子表，mainId -> 主档.id，一指标一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_check_index.sql，9 列）：
--   chineseId/chineseName/yesNo/remark 透传（chineseName 源 VARCHAR(255) -> app VARCHAR(128) LEFT 截断）
--   indexObject 按附录2 硬编码 CASE：D22/D23=担保人指标 / D24~D30=抵质押物指标 /
--               D05~D19+D31=被检查人指标 / 其余=NULL
--   isAbnormal  按附录2 异常选项硬编码 CASE：
--       异常选项=否 组（D05/D06/D07/D09/D31）：yesNo='否' -> '是'，否则 '否'
--       异常选项=是 组（D08/D10~D19/D22~D30）：yesNo='是' -> '是'，否则 '否'
--       附录2 外：NULL
--   去重键 (reportNo, customerId, chineseId) ROW_NUMBER(inputtime DESC, id DESC)；先 JOIN 当前主档
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：25（D05/D31/D06/D07/D08/D09/D10/D11/D12/D13/D14/D15/D16/D17/D18/D19
--                   D22/D23/D24/D25/D26/D27/D28/D29/D30）
--
-- 共享父表：xd_corp_check_info id=1 由本文件创建，并被
--   源头数据_app_check_object_info.sql / app_check_opinion_info.sql / app_check_record_info.sql 复用
--   （后续文件用条件 INSERT IF NOT EXISTS 跳过创建）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表（含父表 id=1）
-- =====================================================================
DELETE FROM app_check_index_info       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_daily_index  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_check_info         WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_corp_check_info（对公检查主档，父表；显式 id=1 供 mainId 指向）
--    按报告编号取最新一条（inputtime DESC, id DESC）-> 单行即当前主档
-- =====================================================================
INSERT INTO xd_corp_check_info (id, reportNo, customerId, customerName, inputtime)
VALUES (1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '2026-03-05 10:30:00');

-- =====================================================================
-- 2. xd_corp_check_daily_index（日常检查综合指标，子表）
--    mainId=1（指向 xd_corp_check_info.id=1）；25 行（D05~D31 附录2 指标，一指标一行）
--    chineseId/chineseName/yesNo/remark 全部直映目标 DML（加工层透传）
--    isAbnormal/indexObject 由加工层 CASE 派生，源表无对应列
-- =====================================================================
INSERT INTO xd_corp_check_daily_index (mainId, reportNo, customerId, customerName, chineseId, chineseName, yesNo, remark, inputtime) VALUES
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D05', '经营信息是否真实有效', '否', '经核查，企业工商登记信息与实际情况不符，存在虚报注册资本、伪造经营场所等情形，经营信息不真实。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D31', '贷款资金用途是否合规且符合合同约定', '否', '贷款资金未按合同约定用途使用，部分资金被挪用于购买理财产品及偿还民间借贷，违反合同约定。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D06', '总体生产经营是否正常', '否', '企业已处于半停产状态，主要生产线停工，订单大幅减少，生产经营不正常。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D07', '现金流是否充裕', '否', '企业现金流紧张，经营性现金流入不足以覆盖到期债务，存在资金链断裂风险。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D08', '所属行业、国家产业政策是否发生不利于企业的、重大变化', '是', '所属行业被列入国家限制类产业目录，产业政策发生重大不利变化，对企业经营产生严重影响。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D09', '环保手续是否齐全（如有）', '否', '企业未取得排污许可证，环保验收手续缺失，存在被环保部门处罚的风险。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D10', '纳税是否异常波动', '是', '企业近半年纳税额同比大幅下降，且存在欠税记录，纳税异常波动。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D11', '员工人员及工资发放是否异常波动', '是', '企业员工人数锐减，且存在拖欠员工工资情况，工资发放异常。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D12', '是否涉及民间融资或民间借贷担保', '是', '经查，企业涉及多笔民间借贷，并为关联方民间融资提供担保，金额较大。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D13', '是否涉及重大刑事案件', '是', '企业实际控制人因涉嫌非法吸收公众存款被立案侦查，涉及重大刑事案件。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D14', '是否向非主业盲目扩张', '是', '企业近年大举投资房地产、金融等非主业领域，导致主业经营受影响，存在盲目扩张。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D15', '实控人健康、家庭状况是否发生重大不利变化', '是', '实际控制人因重病住院，且家庭发生重大变故，对企业经营决策产生不利影响。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D16', '股权结构/管理层是否发生重大不利变化', '是', '企业股权结构发生重大变更，核心管理层集体离职，管理层动荡。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D17', '是否遭受重大自然灾害等不可抗力的负面影响', '是', '企业厂房遭受火灾，生产设备损毁严重，恢复生产需较长时间。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D18', '是否达到相关办法中规定的业务中止或退出规定', '是', '企业已触发相关办法中规定的业务中止条件，如连续逾期超过90天。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D19', '还款意愿是否下降', '是', '借款人多次拖延还款，沟通中表现出消极还款意愿，还款意愿明显下降。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D22', '担保能力是否下降', '是', '担保人对外担保金额过大，代偿能力不足，担保能力显著下降。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D23', '还款意愿是否下降', '是', '担保人拒绝配合贷后检查，且明确表示不愿承担担保责任，还款意愿下降。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D24', '抵/质押物是否被查封、被冻或冻结', '是', '抵/质押物已被法院查封，存在被处置的风险。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D25', '抵/质押物权属是否变更或发生争议', '是', '抵/质押物权属发生变更，且存在第三方主张权利，权属争议较大。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D26', '抵/质押物是否被毁损', '是', '抵/质押物因保管不善发生严重毁损，价值大幅贬损。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D27', '抵/质押物市场价值是否大幅下降', '是', '抵/质押物市场价格大幅下跌，当前市值已不足以覆盖贷款本息。', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D28', '抵/质押物状态（使用情况、租赁关系等）是否发生、变化', '是', '/', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D29', '第三方保管的，抵/质押物保管状态是否异常（如、有）', '否', '/', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'D30', '第三方保管的，保管人的保管能力及资质是否发、生变化（如有）', '否', '/', '2026-03-05 10:30:00');

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工/xd_check_index.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--   2. 加工产出 25 行，业务字段与目标 DML 完全一致：
--      - chineseId/chineseName/yesNo/remark 直映 ✓
--      - indexObject 按 chineseId 派生（被检查人/担保人/抵质押物指标）✓
--      - isAbnormal 按 chineseId + yesNo 派生（异常选项否组：yesNo=否->是；异常选项是组：yesNo=是->是）✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..25）
--   4. app_check_index_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中 '2026-03-05 10:30:00.0' 无法精确复现（系统自动生成）
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_check_index.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 对公日检》日常检查综合指标 · 源头表 -> app_check_index_info 加工
-- 节点：对公检查信息查询接口（aflCheckDetailQry，CrcsAfterLoanAiService.aflCheckDetailQry）
-- 源表：
--   xd_corp_check_info          对公检查主档（父表，aflCheckDetailQry 落表）
--   xd_corp_check_daily_index   日常检查综合指标 DailyCheckIndicator（mainId -> xd_corp_check_info.id）
-- 目标：app_check_index_info（业务主键 reportNo + customerId + chineseId，一指标一行）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 处理规则（对齐 xd_check_record.sql）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_check_index_info 本次范围旧行，再插入
--   2. 源头 append-only：先 JOIN「当前主档」(mainId=最新 xd_corp_check_info.id) 排除历史快照，
--      再按业务主键 (chineseId) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 透传字段：chineseId / chineseName / yesNo / remark 直映；
--      源 chineseName VARCHAR(255) -> app VARCHAR(128)，LEFT(...,128) 截断防越界
--   4. 加工字段（依据《SZ银行DH智能体》附录2-日常检查指标，按 chineseId 硬编码 CASE）：
--        indexObject 指标对象：D22/D23=担保人指标，D24~D30=抵质押物指标，其余=被检查人指标；附录2 外的指标置 NULL
--        isAbnormal  是否异常：附录2「异常选项」给出该指标 yesNo 触发异常的值——
--                     异常选项=否 的指标（D05/D31/D06/D07/D09）：yesNo='否' -> '是' 否则 '否'
--                     异常选项=是 的指标（D08~D30 其余）：yesNo='是' -> '是' 否则 '否'
--                     附录2 外的指标置 NULL
--   5. 注：D31（贷款资金用途是否合规且符合合同约定）附录2 标注"等信贷确认下"，先按 被检查人指标/异常选项=否 加工
-- =====================================================================

-- 1. 幂等
DELETE FROM app_check_index_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

-- 2. 日常检查综合指标：xd_corp_check_daily_index（JOIN 当前主档）-> app_check_index_info
INSERT INTO app_check_index_info (
    reportNo, customerId, customerName, chineseId, chineseName, indexObject, yesNo, isAbnormal, remark
)
SELECT
    c.reportNo, c.customerId, c.customerName,
    c.chineseId,
    LEFT(c.chineseName, 128)                                        AS chineseName,
    CASE
        WHEN c.chineseId IN ('D22', 'D23')                          THEN '担保人指标'
        WHEN c.chineseId IN ('D24', 'D25', 'D26', 'D27', 'D28', 'D29', 'D30') THEN '抵质押物指标'
        WHEN c.chineseId IN ('D05', 'D06', 'D07', 'D08', 'D09', 'D10', 'D11', 'D12',
                             'D13', 'D14', 'D15', 'D16', 'D17', 'D18', 'D19', 'D31') THEN '被检查人指标'
        ELSE NULL
    END                                                             AS indexObject,
    c.yesNo,
    CASE
        WHEN c.chineseId IN ('D05', 'D31', 'D06', 'D07', 'D09')
            THEN CASE WHEN c.yesNo = '否' THEN '是' ELSE '否' END
        WHEN c.chineseId IN ('D08', 'D10', 'D11', 'D12', 'D13', 'D14', 'D15', 'D16',
                             'D17', 'D18', 'D19', 'D22', 'D23', 'D24', 'D25', 'D26',
                             'D27', 'D28', 'D29', 'D30')
            THEN CASE WHEN c.yesNo = '是' THEN '是' ELSE '否' END
        ELSE NULL
    END                                                             AS isAbnormal,
    c.remark
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.chineseId, c.chineseName, c.yesNo, c.remark,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.chineseId, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_corp_check_daily_index c
    JOIN (
        SELECT id FROM (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
            FROM xd_corp_check_info
            WHERE reportNo IS NOT NULL
              AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
              AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
        ) mc WHERE mc.rn = 1
    ) m ON c.mainId = m.id
) c
WHERE c.rn = 1;
