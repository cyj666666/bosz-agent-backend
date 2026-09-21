-- =====================================================================
-- app_customer_info（客户工商概况）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_customer.sql（同时产出 app_xd_shareholder_info）
-- 源表（父子表，mainId -> xd_corp_customer_info.id=1，父表共享自 app_credit_use_info）：
--   xd_corp_customer_info     客户主档（CustomerEndInfoDto）
--   xd_corp_customer_control  实际控制人（ControlshipExecutives）
--   （xd_corp_customer_shareholder 由 app_xd_shareholder_info 文件造数，本文件不插）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_customer.sql，19 列）：
--   legalPerson      <- fictitiousPerson            法人代表
--   registerCapital  <- registerCapital             DECIMAL 直映
--   paidInCapital    <- paiclupCapital              DECIMAL 直映
--   industryType     <- COALESCE(d.code_name, i.industryType)  码值字典 JOIN，未命中回退原值
--   holdType         <- CASE holdType 码值（10 码） 050->个人绝对控股
--   actualController <- GROUP_CONCAT(DISTINCT controlName ORDER BY controlName SEPARATOR '、')  isControl='1' 去重顿号拼接
--   officeAddress    <- officeFormattedAddress
--   businessScope    <- businessScope
--   dangerLevel      <- CASE dangerLevel 码值（10 码）  未收录原样保留（'6级' 透传）
--   warningLevel     <- CASE warningLevel 码值（5 码）  4->黄色预警
--   isTechCompany    <- isStiEnt 直映（无需映射）
--   isListedCompany  <- listingCorpOrNot 直映（无需映射）
--   主档去重 ROW_NUMBER(reportNo ORDER BY inputtime DESC, id DESC)
--   控制人去重 ROW_NUMBER(reportNo, controlName+certId ORDER BY inputtime DESC, id DESC)
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202603-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：1
--   legalPerson='李四', registerCapital=3000.00, paidInCapital=3000.00
--   industryType='房屋建筑业' (源同中文，码值字典 JOIN 未命中回退原值)
--   holdType='个人绝对控股' (源 '050' CASE 命中)
--   actualController='张三；李四' (源 2 行控制人 controlName='张三'/'李四')
--   officeAddress='泰州市xx路XXX号'
--   businessScope='建设工程施工，同时兼营园林绿化工程施工、土石方工程施工以及建筑材料销售等一般性业务'
--   dangerLevel='6级' (源 '6级' 未收录码，CASE ELSE 透传)
--   warningLevel='黄色预警' (源 '4' CASE 命中)
--   isTechCompany='是' (源 isStiEnt='是'，直映)
--   isListedCompany='是' (源 listingCorpOrNot='是'，直映)
--
-- 共享父表：xd_corp_customer_info id=1（与 app_credit_use_info / app_xd_shareholder_info 共享）
--   本文件负责字段补齐：若 id=1 来自 app_credit_use_info（最小化字段集，关键字段为空），
--   本文件先 DELETE 再用完整字段 INSERT；若 id=1 不存在则直接 INSERT（全字段）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源子表（不动父表 id=1）
-- =====================================================================
DELETE FROM app_customer_info           WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM app_xd_shareholder_info     WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_corp_customer_control    WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_corp_customer_shareholder WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';

-- =====================================================================
-- 1. xd_corp_customer_info（共享父表，条件创建：仅当 id=1 不存在时插入）
--    注意：本文件用条件 INSERT 保证幂等；若需更新父表字段（如 businessScope），
--    请先 DELETE FROM xd_corp_customer_info WHERE id=1 再重新执行 app_credit_use_info 与本文件
--    本文件用补齐字段的条件 INSERT（包含 customer_info 全部所需字段），覆盖 app_credit_use_info
--    父表的最小化字段集
-- =====================================================================
-- 若 id=1 已存在但字段不齐（来自 app_credit_use_info），先删除再重建以补齐字段
DELETE FROM xd_corp_customer_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001'
  AND EXISTS (SELECT 1 FROM xd_corp_customer_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001'
              AND (fictitiousPerson IS NULL OR registerCapital IS NULL OR paiclupCapital IS NULL
                   OR holdType IS NULL OR officeFormattedAddress IS NULL OR businessScope IS NULL
                   OR dangerLevel IS NULL OR warningLevel IS NULL OR isStiEnt IS NULL
                   OR listingCorpOrNot IS NULL));

INSERT INTO xd_corp_customer_info (
    id, reportNo, customerId, customerName, fictitiousPerson, registerCapital, paiclupCapital,
    industryType, holdType, officeFormattedAddress, businessScope,
    dangerLevel, warningLevel, isStiEnt, listingCorpOrNot,
    groupClientNo, groupClientName, inputtime
)
SELECT 1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
       '李四', 3000.00, 3000.00,
       '房屋建筑业', '050', '泰州市xx路XXX号',
       '建设工程施工，同时兼营园林绿化工程施工、土石方工程施工以及建筑材料销售等一般性业务',
       '6级', '4', '是', '是',
       'GRP-001', '江阴市xx精密集团', '2025-04-18 09:20:00'
WHERE NOT EXISTS (SELECT 1 FROM xd_corp_customer_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001');

-- =====================================================================
-- 2. xd_corp_customer_control（实际控制人，2 行）
--    mainId=1；controlName='张三'/'李四'，isControl='1'（纳入 actualController 拼接）
--    certId 各异 -> 去重键 (controlName+certId) 各保留 1 行
--    加工层 GROUP_CONCAT(DISTINCT controlName ORDER BY controlName SEPARATOR '、') -> 输出 '张三、李四'
-- =====================================================================
INSERT INTO xd_corp_customer_control (
    mainId, reportNo, customerId, customerName, controlName, certId, isControl, inputtime
) VALUES
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', '张三', 'CERT-001', '1', '2025-04-18 09:20:00'),
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', '李四', 'CERT-002', '1', '2025-04-18 09:20:00');

-- =====================================================================
-- 3. xd_corp_customer_shareholder（股东信息，6 行，使本文件两张 app 表均有数据）
--    mainId=1；shareholderName 各异（去重键 (reportNo, customerId, shareholderName)）
-- =====================================================================
INSERT INTO xd_corp_customer_shareholder (
    mainId, reportNo, customerId, customerName, shareholderName, relationShip, currencyType,
    investmentProp, oughtSum, investmentSum, investDate, inputUserId, inputOrgId, inputtime
) VALUES
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '周九', '自筹', '人民币', 30.0000, 3000000.00, 1500000.00, '2026/3/5', 'admin', 'ORG-001', '2026-03-05 10:30:00'),
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '泰州公司', '合资', '人民币', 20.0000, 2000000.00, 2000000.00, '2026/3/6', 'admin', 'ORG-001', '2026-03-06 14:20:00'),
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '王五', '个人投资', '人民币', 20.0000, 2000000.00, 1000000.00, '2026/3/7', 'zhangsan', 'ORG-002', '2026-03-07 09:15:00'),
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '李四', '个人投资', '人民币', 10.0000, 1000000.00, 500000.00, '2026/3/8', 'lisi', 'ORG-002', '2026-03-08 16:45:00'),
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '赵六', '自筹', '人民币', 10.0000, 1000000.00, 1000000.00, '2026/3/9', 'admin', 'ORG-001', '2026-03-09 11:00:00'),
(1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '钱七', '自筹', '人民币', 10.0000, 1000000.00, 800000.00, '2026/3/10', 'wangwu', 'ORG-003', '2026-03-10 08:30:00');

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工/xd_customer.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202603-001'）
--   2. 加工产出 1 行，业务字段与目标 DML 大体一致：
--      - legalPerson/registerCapital/paidInCapital/officeAddress/businessScope 直映 ✓
--      - industryType='房屋建筑业'（源中文，码值字典 JOIN 未命中回退原值）✓
--      - holdType='个人绝对控股'（源 '050' CASE 命中）✓
--      - dangerLevel='6级'（源未收录码，CASE ELSE 透传）✓
--      - warningLevel='黄色预警'（源 '4' CASE 命中）✓
--      - isTechCompany='是'（源 isStiEnt='是'，直映）✓
--      - isListedCompany='是'（源 listingCorpOrNot='是'，直映）✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1）
--   4. app_customer_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中 '2025-04-18 09:20:00.0' 无法精确复现
--
--   -- ISSUE 1（actualController 分隔符）：
--      目标 DML actualController='张三、李四'（顿号分隔），
--      加工 SQL GROUP_CONCAT(DISTINCT controlName ORDER BY controlName SEPARATOR '、') -> 输出 '张三、李四'。
--      顺序按 controlName 排序，已保证固定顺序。
--
--   -- ISSUE 2（isStateOwned / groupName 不在加工 SQL 输出列）：
--      加工 SQL INSERT 列清单（见 xd_customer.sql 第 59-63 行）仅含 15 列，不含 isStateOwned / groupName。
--      目标 DML isStateOwned='否' / groupName='江阴市xx精密集团' 由其他流程（Java 侧或后续加工）写入。
--      本源头数据无法驱动产出这两个字段；若需一致，需在 app_customer_info INSERT 后另行 UPDATE 补值。
--
--   注意：xd_customer.sql 同时清理 + 加工 app_xd_shareholder_info（与 app_customer_info 同节点）
--      本文件已补插 xd_corp_customer_shareholder 6 行数据，app_xd_shareholder_info 加工产出 6 行
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_customer.sql
-- Params: customerId='CUST-001', reportNo='RPT-202603-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 信贷系统客户企业概况 · 源头表 -> 应用层表加工（参考 财务指标加工/xd_financial.sql 模式）
-- 源表（对公客户信息查询接口 getEntCustomerAllQry 落表，见 源头表/信贷/DDL/对公客户信息查询接口_建表DDL.sql）：
--   xd_corp_customer_info           客户主档（CustomerEndInfoDto）
--   xd_corp_customer_control        实际控制人（ControlshipExecutives，mainId -> xd_corp_customer_info.id）
--   xd_corp_customer_shareholder    股东信息（CustomerShipSharehold，mainId -> xd_corp_customer_info.id）
-- 目标：app_customer_info（客户工商概况表）/ app_xd_shareholder_info（信贷股东全字段）
--      （app_shareholder_info 由 外数加工/xd_shareholder_info.sql 承载，本脚本不写入）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式，正则用 REGEXP）
--
-- 处理规则（依据《SZ银行DH智能体》数据字典，仅取"来源=信贷"的列）：
--   1. 幂等：先按 (customerId, reportNo) 删除两张 app 表本次范围旧行，再插入
--   2. 源头表"接口返回直接追加插入，不做去重约束"，同一 reportNo 重复调用会重复落表：
--        主档   : 按 reportNo 去重取最新一条
--        股东   : 按业务主键 (reportNo, customerId, name) 取最新（《SZ银行DH智能体》数据字典 J 列；同名股东仅一行）
--        控制人 : 按 (reportNo, controlName+certId) 去重（controlName=实控人名称）
--   3. 字段映射（信贷源 -> app）：
--        app_customer_info:
--          legalPerson      <- fictitiousPerson(法人代表)
--          registerCapital  <- registerCapital(已是 DECIMAL)
--          paidInCapital    <- paiclupCapital(实收资本, 已是 DECIMAL)
--          industryType     <- industryType(国标行业分类)  码值->中文：LEFT JOIN 码值字典表 app_code_dict
--                              （dict_type='industryType'，1969 码由 码值字典/国标行业分类_码值字典.sql 落表；
--                               命中取 code_name，未命中回退原码值）
--          holdType         <- holdType(控股类型)          码值->中文：内联 CASE（10 码）
--          actualController <- 控制子表 isControl='1' 的 controlName(实控人名称) 去重拼接
--                              （controlName=controlshipExecutives.customerName，落表时由 CorpCustomerDataStore 单独映射；
--                               relativeCustomerId 为实控人客户号，不再用于拼接）
--          officeAddress    <- officeFormattedAddress(标准办公地址)
--          businessScope    <- businessScope(经营范围)
--          dangerLevel      <- dangerLevel(风险分类结果)    码值->中文：内联 CASE（10 码）
--          warningLevel     <- warningLevel(预警等级)       码值->中文：内联 CASE（1/2/4/5/6 码）
--          isTechCompany    <- isStiEnt(是否科创企业，直映，无需映射)
--          isListedCompany  <- listingCorpOrNot(是否上市公司，直映，无需映射)
--          isStateOwned     <- 去掉, 不输出（holdType 码值表待确认, 按需求不加工该列）
--        app_xd_shareholder_info（信贷股东全字段）:
--          name <- shareholderName, investmentProp, relationShip(出资方式, 码值->中文内联 CASE 5 码),
--          currencyType(投资币种), oughtSum(应缴), investmentSum(实缴), investDate(最迟到位日期),
--          inputUserId, inputOrgId
--   4. 外数来源列（app_ic_info / app_ic_shareholder_info 整表, 以及 stock_num/is_quoted/is_state_owned/
--      is_fake_state_owned/is_listed_company 等）不在本脚本范围, 置 NULL 留给启信宝(QXB_*)等外数加工
--   5. 码值转换（依据《苏州银行综合信贷系统_贷后智能体相关接口_V1.0》「码表」sheet）：
--        holdType/dangerLevel/warningLevel/relationShip 码值小 -> 内联 CASE 转中文，NULL/未收录码值原样保留；
--        industryType 1969 码 -> 走 app_code_dict 字典表 JOIN（不在 SQL 内 CASE）。
--        前置：先执行 码值字典/国标行业分类_码值字典.sql 落 app_code_dict（industryType 类），否则 industryType 回退原码值。
--   6. isStiEnt/listingCorpOrNot 码表仅 0/1（0=否/1=是），按 1 判"是"，其余/未收录 -> "否"（2026-09-17 已去 'Y' 死分支）
-- =====================================================================

-- 1. 幂等：先删除本次加工范围内的目标行（与下方过滤条件一致，避免重复加工叠加）
DELETE FROM app_customer_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL);

DELETE FROM app_xd_shareholder_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL);

-- 2. 客户工商概况：xd_corp_customer_info -> app_customer_info
INSERT INTO app_customer_info (
    reportNo, customerId, customerName, legalPerson, registerCapital, paidInCapital,
    industryType, holdType, actualController, officeAddress, businessScope,
    dangerLevel, warningLevel, isTechCompany, isListedCompany
)
SELECT
    i.reportNo AS reportNo,
    i.customerId AS customerId,
    i.customerName AS customerName,
    i.fictitiousPerson AS legalPerson,
    i.registerCapital AS registerCapital,
    i.paiclupCapital AS paidInCapital,
    -- 国标行业分类：码值->中文，走码值字典表（1969 码，码值字典/国标行业分类_码值字典.sql 落表），未命中回退原码值
    COALESCE(d.code_name, i.industryType) AS industryType,
    -- 控股类型：码值->中文（10 码），NULL/未收录原样保留
    CASE WHEN i.holdType IS NULL THEN NULL
         WHEN i.holdType = '010' THEN '国有绝对控股'
         WHEN i.holdType = '020' THEN '国有相对控股'
         WHEN i.holdType = '030' THEN '集体绝对控股'
         WHEN i.holdType = '040' THEN '集体相对控股'
         WHEN i.holdType = '050' THEN '个人绝对控股'
         WHEN i.holdType = '060' THEN '个人相对控股'
         WHEN i.holdType = '070' THEN '港澳台商绝对控股'
         WHEN i.holdType = '080' THEN '港澳台商相对控股'
         WHEN i.holdType = '090' THEN '外商绝对控股'
         WHEN i.holdType = '100' THEN '外商相对控股'
         ELSE i.holdType END AS holdType,
    c.actualController AS actualController,
    i.officeFormattedAddress AS officeAddress,
    i.businessScope AS businessScope,
    -- 风险分类结果：码值->中文（10 码），NULL/未收录原样保留
    CASE WHEN i.dangerLevel IS NULL THEN NULL
         WHEN i.dangerLevel = '011' THEN '正常1'
         WHEN i.dangerLevel = '012' THEN '正常2'
         WHEN i.dangerLevel = '013' THEN '正常3'
         WHEN i.dangerLevel = '021' THEN '关注1'
         WHEN i.dangerLevel = '022' THEN '关注2'
         WHEN i.dangerLevel = '023' THEN '关注3'
         WHEN i.dangerLevel = '031' THEN '次级1'
         WHEN i.dangerLevel = '032' THEN '次级2'
         WHEN i.dangerLevel = '040' THEN '可疑'
         WHEN i.dangerLevel = '050' THEN '损失'
         ELSE i.dangerLevel END AS dangerLevel,
    -- 预警等级：码值->中文（1/2/4/5/6 码，码表无 3），NULL/未收录原样保留
    CASE WHEN i.warningLevel IS NULL THEN NULL
         WHEN i.warningLevel = '1' THEN '无风险'
         WHEN i.warningLevel = '2' THEN '风险排查'
         WHEN i.warningLevel = '4' THEN '黄色预警'
         WHEN i.warningLevel = '5' THEN '橙色预警'
         WHEN i.warningLevel = '6' THEN '红色预警'
         ELSE i.warningLevel END AS warningLevel,
     -- 是否科创企业 / 是否上市公司（码值：是/否）：源头码表 0/1，兼容历史 '是' 形态；其余（含 0/空/NULL/未收录）一律「否」
     CASE WHEN BTRIM(COALESCE(c.isStiEnt, '')) IN ('1', '是') THEN '是' ELSE '否' END AS isTechCompany,
     CASE WHEN BTRIM(COALESCE(c.listingCorpOrNot, '')) IN ('1', '是') THEN '是' ELSE '否' END AS isListedCompany
FROM (
    -- 主档去重：每个 reportNo 仅保留最新一条
    SELECT reportNo, customerId, customerName, fictitiousPerson, registerCapital, paiclupCapital,
           industryType, holdType, officeFormattedAddress, businessScope,
           dangerLevel, warningLevel, isStiEnt, listingCorpOrNot,
           ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_customer_info
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
) i
LEFT JOIN (
    -- 国标行业分类码值字典（1969 码，码值字典/国标行业分类_码值字典.sql 落表）
    SELECT code_value, code_name
    FROM app_code_dict
    WHERE dict_type = 'industryType'
) d ON d.code_value = i.industryType
LEFT JOIN (
    -- 实际控制人：isControl='1' 的 controlName(实控人名称) 去重顿号拼接，按 controlName 排序保证固定顺序
    -- （controlName 落表时由 CorpCustomerDataStore 从 controlshipExecutives.customerName 单独映射；
    --  相对控制人去重键 = controlName+certId）
    SELECT reportNo,
           GROUP_CONCAT(DISTINCT controlName ORDER BY controlName SEPARATOR '、') AS actualController
    FROM (
        SELECT reportNo, controlName, inputtime, id,
               ROW_NUMBER() OVER (
                   PARTITION BY reportNo,
                       COALESCE(controlName, ''), COALESCE(certId, '')
                   ORDER BY inputtime DESC, id DESC) AS rn
        FROM xd_corp_customer_control
        WHERE reportNo IS NOT NULL
          AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
          AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
          AND isControl = '1'
          AND controlName IS NOT NULL
    ) t
    WHERE t.rn = 1
    GROUP BY reportNo
) c ON c.reportNo = i.reportNo
WHERE i.rn = 1;

-- 3. 信贷系统股东信息（全字段）：xd_corp_customer_shareholder -> app_xd_shareholder_info
--    （app_shareholder_info 由外数加工 外数加工/xd_shareholder_info.sql 承载，本脚本不再写入，避免两脚本互删）
INSERT INTO app_xd_shareholder_info (
    reportNo, customerId, customerName, name, investmentProp, relationShip, currencyType,
    oughtSum, investmentSum, investDate, inputUserId, inputOrgId
)
SELECT
    s.reportNo AS reportNo,
    s.customerId AS customerId,
    s.customerName AS customerName,
    s.shareholderName AS name,
    s.investmentProp AS investmentProp,
    -- 投资方式：码值->中文（5 码），NULL/未收录原样保留
    CASE WHEN s.relationShip IS NULL THEN NULL
         WHEN s.relationShip = '0401' THEN '资金(投资)'
         WHEN s.relationShip = '0402' THEN '技术(投资)'
         WHEN s.relationShip = '0403' THEN '实物(投资)'
         WHEN s.relationShip = '0404' THEN '权利(投资)'
         WHEN s.relationShip = '0405' THEN '其他(投资)'
         ELSE s.relationShip END AS relationShip,
    s.currencyType AS currencyType,
    s.oughtSum AS oughtSum,
    s.investmentSum AS investmentSum,
    CASE WHEN REGEXP_LIKE(SUBSTR(CAST(s.investDate AS CHAR(32)), 1, 10), '^[0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}$')
         THEN TO_CHAR(TO_DATE(SUBSTR(CAST(s.investDate AS CHAR(32)), 1, 10), 'YYYY-MM-DD'), 'YYYYMMDD')
         ELSE CAST(s.investDate AS CHAR(64)) END AS investDate,
    s.inputUserId AS inputUserId,
    s.inputOrgId AS inputOrgId
FROM (
    -- 股东去重：每个 (reportNo, 股东键) 仅保留最新一条
    SELECT reportNo, customerId, customerName, shareholderName, investmentProp, relationShip,
           currencyType, oughtSum, investmentSum, investDate, inputUserId, inputOrgId,
            ROW_NUMBER() OVER (
                PARTITION BY reportNo, COALESCE(customerId, ''), COALESCE(shareholderName, '')
                ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_customer_shareholder
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
) s
WHERE s.rn = 1;
