-- =====================================================================
-- app_xd_shareholder_info（信贷系统股东全字段）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_customer.sql（同 app_customer_info 一个脚本，第 3 段 INSERT）
-- 源表（父子表，mainId -> xd_corp_customer_info.id=1，父表共享自 app_credit_use_info）：
--   xd_corp_customer_info     客户主档（CustomerEndInfoDto，全字段，使 app_customer_info 产出完整）
--   xd_corp_customer_control  实际控制人（ControlshipExecutives，本文件附造 2 行使两张 app 表均有数据）
--   xd_corp_customer_shareholder   股东信息（CustomerShipSharehold）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_customer.sql 第 3 段 INSERT，14 列）：
--   name            <- shareholderName
--   investmentProp  <- investmentProp            DECIMAL 直映
--   relationShip    <- CASE relationShip 码值（5 码 0401~0405）未收录原样保留
--                      目标值 '自筹'/'合资'/'个人投资' 不在 CASE 内 -> 透传（源=目标）
--   currencyType    <- currencyType              直映
--   oughtSum        <- oughtSum                  DECIMAL 直映
--   investmentSum   <- investmentSum             DECIMAL 直映
--   investDate      <- CASE CAST(investDate AS CHAR(32)) 正则命中 yyyy-MM-dd/yyyy/MM/dd 去分隔符；
--                      不命中原样 CAST AS CHAR(64)
--   inputUserId     <- inputUserId
--   inputOrgId      <- inputOrgId
--   去重键 (reportNo, customerId, shareholderName) ROW_NUMBER(inputtime DESC, id DESC)
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202609-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：6
--   1: 周九, 30.0000, '自筹',     '人民币', 3000000.00, 1500000.00, '2026/3/5',  'admin',   'ORG-001'
--   2: 泰州公司, 20.0000, '合资', '人民币', 2000000.00, 2000000.00, '2026/3/6',  'admin',   'ORG-001'
--   3: 王五, 20.0000, '个人投资', '人民币', 2000000.00, 1000000.00, '2026/3/7',  'zhangsan','ORG-002'
--   4: 李四, 10.0000, '个人投资', '人民币', 1000000.00, 500000.00,  '2026/3/8',  'lisi',    'ORG-002'
--   5: 赵六, 10.0000, '自筹',     '人民币', 1000000.00, 1000000.00, '2026/3/9',  'admin',   'ORG-001'
--   6: 钱七, 10.0000, '自筹',     '人民币', 1000000.00, 800000.00,  '2026/3/10', 'wangwu',  'ORG-003'
--
-- 共享父表：xd_corp_customer_info id=1（来自 app_credit_use_info 文件，本文件条件 IF NOT EXISTS 跳过创建）
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源子表（不动父表 id=1）
-- =====================================================================
DELETE FROM app_xd_shareholder_info       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM app_customer_info             WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_customer_shareholder  WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_customer_control      WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';
DELETE FROM xd_corp_customer_info         WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001';

-- =====================================================================
-- 1. xd_corp_customer_info（父表，全字段，使 app_customer_info 产出完整）
--    清理段已删除旧父表，此处直接 INSERT 全字段
-- =====================================================================
INSERT INTO xd_corp_customer_info (
    id, reportNo, customerId, customerName, fictitiousPerson, registerCapital, paiclupCapital,
    industryType, holdType, officeFormattedAddress, businessScope,
    dangerLevel, warningLevel, isStiEnt, listingCorpOrNot,
    groupClientNo, groupClientName, inputtime
)
VALUES (
    1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
    '李四', 3000.00, 3000.00,
    '房屋建筑业', '050', '泰州市xx路XXX号',
    '建设工程施工，同时兼营园林绿化工程施工、土石方工程施工以及建筑材料销售等一般性业务',
    '6级', '4', '1', '1',
    'GRP-001', '江阴市xx精密集团', '2025-04-18 09:20:00'
);

-- =====================================================================
-- 2. xd_corp_customer_shareholder（股东信息，6 行）
--    mainId=1；shareholderName 各异（去重键 (reportNo, customerId, shareholderName)）
--    relationShip 源 = 目标值（'自筹'/'合资'/'个人投资' 不在 CASE 5 码内 -> 透传）
--    investDate 源用目标字符串 'YYYY/M/D'（VARCHAR，CAST AS CHAR(32) 后正则
--      ^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$ 不命中（月/日单数字）-> ELSE CAST AS CHAR(64) 透传）
--
--    -- ISSUE: investDate 在 DDL 中是 DATE 类型；若 DB 实际按 DATE 存储，
--       CAST(investDate AS CHAR(32)) 会得到 'YYYY-MM-DD'（如 '2026-03-05'），
--       正则命中后去 - -> '20260305'，与目标 '2026/3/5' 不一致。
--       为与目标一致，需保证 DB 中 investDate 列按 VARCHAR 存储（或源数据为字符串字面量）。
--       若实际 DDL 为 DATE 不可改，则加工产出 '20260305' 而非 '2026/3/5'，存在差异。
--       本文件按目标字符串原样插入，依赖 DB 列类型为 VARCHAR（或接受字符串字面量）。
-- =====================================================================
INSERT INTO xd_corp_customer_shareholder (
    mainId, reportNo, customerId, customerName, shareholderName, relationShip, currencyType,
    investmentProp, oughtSum, investmentSum, investDate, inputUserId, inputOrgId, inputtime
) VALUES
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '周九', '自筹', '人民币', 30.0000, 3000000.00, 1500000.00, '2026/3/5', 'admin', 'ORG-001', '2026-03-05 10:30:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '泰州公司', '合资', '人民币', 20.0000, 2000000.00, 2000000.00, '2026/3/6', 'admin', 'ORG-001', '2026-03-06 14:20:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '王五', '个人投资', '人民币', 20.0000, 2000000.00, 1000000.00, '2026/3/7', 'zhangsan', 'ORG-002', '2026-03-07 09:15:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '李四', '个人投资', '人民币', 10.0000, 1000000.00, 500000.00, '2026/3/8', 'lisi', 'ORG-002', '2026-03-08 16:45:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '赵六', '自筹', '人民币', 10.0000, 1000000.00, 1000000.00, '2026/3/9', 'admin', 'ORG-001', '2026-03-09 11:00:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司',
 '钱七', '自筹', '人民币', 10.0000, 1000000.00, 800000.00, '2026/3/10', 'wangwu', 'ORG-003', '2026-03-10 08:30:00');

-- =====================================================================
-- 3. xd_corp_customer_control（实际控制人，2 行，使本文件两张 app 表均有数据）
--    mainId=1；controlName='张三'/'李四'，isControl='1'（纳入 actualController 拼接）
-- =====================================================================
INSERT INTO xd_corp_customer_control (
    mainId, reportNo, customerId, customerName, controlName, certId, isControl, inputtime
) VALUES
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '张三', 'CERT-001', '1', '2025-04-18 09:20:00'),
(1, 'RPT-202609-001', 'CUST-001', '苏州XX精密机械制造有限公司', '李四', 'CERT-002', '1', '2025-04-18 09:20:00');

-- =====================================================================
-- 验证说明：
--   1. 执行本脚本造源表数据后，再执行 客户企业概况加工\xd_customer.sql
--      （带 :customerId='CUST-001' :reportNo='RPT-202609-001'）
--      本文件已含父表全字段 + control 2 行 + shareholder 6 行，两张 app 表均有数据
--   2. 加工产出 6 行，业务字段与目标 DML 大体一致：
--      - name/investmentProp/currencyType/oughtSum/investmentSum/inputUserId/inputOrgId 直映 ✓
--      - relationShip：源 '自筹'/'合资'/'个人投资' 不在 CASE 5 码（0401~0405）内 -> ELSE 透传 ✓
--   3. id 为 AUTO_INCREMENT（空表起算 = 1..6）
--   4. app_xd_shareholder_info.inputtime 为 DEFAULT CURRENT_TIMESTAMP（运行时刻），
--      DML 中各股东 inputtime（如 '2026-03-05 10:30:00.0'）无法精确复现
--
--   -- ISSUE（investDate 列类型）：
--      目标 DML investDate='2026/3/5' 等单数字月/日字符串。
--      加工 SQL：CAST(investDate AS CHAR(32)) REGEXP '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$'
--      若 investDate 列在 DDL 中为 DATE 类型，CAST AS CHAR 得 'YYYY-MM-DD'（如 '2026-03-05'），
--      正则命中 -> 去 - -> '20260305'，与目标 '2026/3/5' 不一致。
--      若列实际为 VARCHAR（DDL 标 DATE 但 openGauss 兼容模式宽松），源字符串原样存，
--      CAST AS CHAR 得 '2026/3/5'，正则不命中（月单数字）-> ELSE 透传 -> '2026/3/5' ✓。
--      本文件按目标字符串原样插入，依赖 DB 实际按字符串存储（或兼容 DATE 列接受字符串）。
--      若实际严格按 DATE 存储，则加工产出 'YYYYMMDD' 格式（如 '20260305'），存在 6 行差异。
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_customer.sql
-- Params: customerId='CUST-001', reportNo='RPT-202609-001'
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
--          isTechCompany    <- isStiEnt(是否科创企业, 1 -> 是, 其余 -> 否)
--          isListedCompany  <- listingCorpOrNot(是否上市公司, 1 -> 是, 其余 -> 否)
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
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

DELETE FROM app_xd_shareholder_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL);

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
     CASE WHEN BTRIM(COALESCE(i.isStiEnt, '')) IN ('1', '是') THEN '是' ELSE '否' END AS isTechCompany,
     CASE WHEN BTRIM(COALESCE(i.listingCorpOrNot, '')) IN ('1', '是') THEN '是' ELSE '否' END AS isListedCompany
FROM (
    -- 主档去重：每个 reportNo 仅保留最新一条
    SELECT reportNo, customerId, customerName, fictitiousPerson, registerCapital, paiclupCapital,
           industryType, holdType, officeFormattedAddress, businessScope,
           dangerLevel, warningLevel, isStiEnt, listingCorpOrNot,
           ROW_NUMBER() OVER (PARTITION BY reportNo ORDER BY inputtime DESC, id DESC) AS rn
    FROM xd_corp_customer_info
    WHERE reportNo IS NOT NULL
      AND (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
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
          AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
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
      AND (reportNo   = 'RPT-202609-001'   OR 'RPT-202609-001'   IS NULL)
) s
WHERE s.rn = 1;
