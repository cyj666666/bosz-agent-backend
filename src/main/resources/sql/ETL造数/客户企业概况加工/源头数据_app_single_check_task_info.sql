-- =====================================================================
-- app_single_check_task_info（单项检查任务）源头表反推造数
-- 加工脚本：客户企业概况加工/xd_single_task.sql
-- 源表：
--   xd_single_task_check  单项检查任务主表（无父表，aflSingleTaskCheckQry 落表）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（xd_single_task.sql，24 业务列）：
--   reportNo/customerId/customerName  直映
--   itemCategory  码值->中文 CASE：'01'->担保落实, '02'->佐证材料收集, '03'->额度压降,
--                                  '04'->资金到位, '06'->监管账户, '07'->资金归集, '08'->管理要求;
--                                  NULL/未收录原样保留
--   serialNo/creditNo/approveTextNo  直映
--   startDate/maturity/checkDate/extendDate  日期正则 -> YYYYMMDD；否则原样透传
--   groupName/productName  直映
--   balance  VARCHAR -> CAST AS DECIMAL(18,2)（REGEXP 数字守卫）
--   "condition"  直映（源 VARCHAR(1000) -> app TEXT）
--   implementStatus  码值->中文 CASE：'01'->已完成, '02'->部分完成, '03'->无法完成,
--                                       '06'->持续关注, '07'->结清不续贷, '08'->已有新批复, '09'->延期;
--                                       NULL/未收录原样保留
--   opinion  直映
--   conditioninStruction <- conditionInstruction（源列名不同，显式 AS）
--   creditApproveUserName/approveAuthor/operateBelongOrgName/operateOrgName/operateUserName  直映
--   approveStatusName  直映
--   去重：ROW_NUMBER(reportNo, customerId, serialNo) ORDER BY inputtime DESC, id DESC
--
-- 测试数据上下文：
--   reportNo    = 'RPT-202603-001'
--   customerId  = 'CUST-001'
--   customerName= '苏州XX精密机械制造有限公司'
--
-- 目标 DML 行数：2（serialNo: CHK-202603-001, CHK-202603-002）
--
-- ISSUE: DML 有 26 列，加工 SQL 只插入 24 列。inputtime 列 DML 非空
--   ('2026-03-05 00:00:00.0')，DEFAULT CURRENT_TIMESTAMP，不一致
-- =====================================================================

-- =====================================================================
-- 0. 清理（可重跑）：清 app 表 + 源表
-- =====================================================================
DELETE FROM app_single_check_task_info WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';
DELETE FROM xd_single_task_check       WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202603-001';

-- =====================================================================
-- 1. xd_single_task_check（单项检查任务；无 mainId，独立行）
--    列：id, reportNo, customerId, customerName, serialNo, creditNo, approveTextNo,
--        startDate, maturity, groupName, productName, checkDate, balance, condition,
--        itemCategory, implementStatus, extendDate, opinion, conditionInstruction,
--        creditApproveUserName, approveAuthor, operateBelongOrgName, operateOrgName,
--        operateUserName, approveStatusName, inputtime
--
--    startDate '2026-03-01' -> 匹配日期正则 -> '20260301'
--    maturity '2027-03-01' -> 匹配日期正则 -> '20270301'
--    checkDate '2026-03-10' -> 匹配日期正则 -> '20260310'
--    extendDate '2026-03-15' -> 匹配日期正则 -> '20260315'
--    balance '2000.00' -> REGEXP 数字 -> CAST AS DECIMAL = 2000.00
--    itemCategory 码值翻译：'01'->担保落实, '03'->额度压降（加工 CASE 翻译为中文）
--    implementStatus 码值翻译：'01'->已完成, '02'->部分完成（加工 CASE 翻译为中文）
--    conditionInstruction -> conditioninStruction（显式 AS 改名）
-- =====================================================================

-- ---------- Row 1: serialNo=CHK-202603-001, itemCategory=01(担保落实), implementStatus=01(已完成) ----------
INSERT INTO xd_single_task_check (
    id, reportNo, customerId, customerName, serialNo, creditNo, approveTextNo,
    startDate, maturity, groupName, productName, checkDate, balance, condition,
    itemCategory, implementStatus, extendDate, opinion, conditionInstruction,
    creditApproveUserName, approveAuthor, operateBelongOrgName, operateOrgName,
    operateUserName, approveStatusName, inputtime
) VALUES (
    1, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'CHK-202603-001', 'CR-2026-001', 'AP-2026-001',
    '2026-03-01', '2027-03-01', '苏州XX集团', '短期流动资金贷款', '2026-03-10', '2000.00', '根据批复要求，需定期监控借款人经营状况，确保资金用途合规，按季度提交财务报表，如发现异常需及时上报。同时要求借款人保持资产负债率不超过70%，并落实担保措施。',
    '01', '01', '2026-03-15', '同意', '经检查，借款人经营正常，资金用途符合批复要求，财务报表已按时提交。担保措施有效，未发现重大风险事项。后续将继续跟踪，确保贷款安全。',
    '张三', '分行审批', '苏州分行', '苏州工业园区支行', '李四', '审批通过', '2026-03-05 00:00:00'
);

-- ---------- Row 2: serialNo=CHK-202603-002, itemCategory=03(额度压降), implementStatus=02(部分完成) ----------
INSERT INTO xd_single_task_check (
    id, reportNo, customerId, customerName, serialNo, creditNo, approveTextNo,
    startDate, maturity, groupName, productName, checkDate, balance, condition,
    itemCategory, implementStatus, extendDate, opinion, conditionInstruction,
    creditApproveUserName, approveAuthor, operateBelongOrgName, operateOrgName,
    operateUserName, approveStatusName, inputtime
) VALUES (
    2, 'RPT-202603-001', 'CUST-001', '苏州XX精密机械制造有限公司', 'CHK-202603-002', 'CR-2026-002', 'AP-2026-002',
    '2026-03-05', '2027-03-05', '苏州XX集团', '银行承兑汇票', '2026-03-12', '3000.00', '要求借款人严格按照批复用途使用资金，不得挪用。每半年进行一次现场检查，关注上下游客户变化，确保贸易背景真实。如出现逾期，需在3个工作日内启动催收程序。',
    '03', '02', '2026-03-20', '有条件同意', '检查发现借款人部分贸易合同尚未归档，已要求其限期补充。目前资金使用基本合规，但需加强贷后管理，后续将重点监控票据到期兑付情况。',
    '王五', '支行审批', '苏州分行', '苏州高新区支行', '赵六', '取消', '2026-03-05 00:00:00'
);

-- =====================================================================
-- 验证说明：
--   1. 两行 xd_single_task_check serialNo 不同，去重各出 1 行，共 2 行
--   2. startDate/maturity/checkDate/extendDate '2026-03-01' 等 -> 匹配日期正则 -> '20260301' 等
--   3. balance '2000.00'/'3000.00' -> REGEXP 数字 -> CAST AS DECIMAL
--   4. itemCategory 码值翻译：'01'->担保落实, '03'->额度压降（加工 CASE 翻译为中文）
--   5. implementStatus 码值翻译：'01'->已完成, '02'->部分完成（加工 CASE 翻译为中文）
--   6. conditionInstruction -> conditioninStruction（显式 AS 改名直映）
--   7. approveStatusName 直映：'审批通过'/'取消'
--   8. ISSUE: inputtime 列加工 SQL 不设置，DML 有非空值，需手工补充
-- =====================================================================

-- =====================================================================
-- Processing logic (params filled, ready to run)
-- Source: 客户企业概况加工\xd_single_task.sql
-- Params: customerId='CUST-001', reportNo='RPT-202603-001'
-- Note: full xd_*.sql logic (idempotent DELETE + INSERT); params replaced
-- =====================================================================
-- =====================================================================
-- 单项检查任务 · 源头表 -> app_single_check_task_info 加工
-- 节点：单项检查任务查询接口（aflSingleTaskCheckQry，CrcsAfterLoanAiService.aflSingleTaskCheckQry）
-- 源表：xd_single_task_check（单项检查任务主表 SingleTaskCheck，aflSingleTaskCheckQry 落表，无父表）
-- 目标：app_single_check_task_info（业务主键（字典 J 列）reportNo + customerId + serialNo）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 字段映射（依据《SZ银行DH智能体》1-数据字典 app_single_check_task_info 段 ROW380-405）：
--   itemCategory           <- itemCategory           事项类别（码值->中文：01->担保落实, 02->佐证材料收集, 03->额度压降, 04->资金到位, 06->监管账户, 07->资金归集, 08->管理要求；NULL/未收录原样保留）
--   serialNo               <- serialNo               流水号（业务主键）
--   creditNo               <- creditNo               授信编号
--   approveTextNo          <- approveTextNo          批复文本编号
--   startDate              <- startDate              起始日期（源 VARCHAR(64) -> app VARCHAR(32)，LEFT 截断）
--   maturity               <- maturity               到期日期（LEFT 截断）
--   groupName              <- groupName              集团名称
--   productName            <- productName            对象
--   checkDate              <- checkDate              检查日期（LEFT 截断）
--   balance                <- balance                对象项下借据余额（源 VARCHAR -> DECIMAL(18,2)，NULLIF 防空串）
--   "condition"            <- condition              批复后续管理要求（源 VARCHAR(1000) -> app TEXT）
--   implementStatus        <- implementStatus        落实情况（码值->中文：01->已完成, 02->部分完成, 03->无法完成, 06->持续关注, 07->结清不续贷, 08->已有新批复, 09->延期；NULL/未收录原样保留）
--   extendDate             <- extendDate             展期日期（LEFT 截断）
--   opinion                <- opinion                意见（源 VARCHAR(1000) -> app TEXT）
--   conditioninStruction   <- conditionInstruction   情况说明（源列名 conditionInstruction，app 列名拼写不同需显式 AS）
--   creditApproveUserName  <- creditApproveUserName  授信审查人
--   approveAuthor          <- approveAuthor          审批权限
--   operateBelongOrgName   <- operateBelongOrgName   分行
--   operateOrgName         <- operateOrgName         支行
--   operateUserName        <- operateUserName        经办客户经理
--   approveStatusName      <- approveStatusName      审批状态名称（码值：Cancel取消/Reject否决/Review复核中/Ineffective失效/Approving审批中/Finished审批通过/CustomerRegister客户经理登记中/PreSubmit待提交/PreConfirmed待确认/EarlyTerminate提前结束/Register登记中/Registered登记完成/Adjournment续议/AutoConfirmed自动审批已确认/AutoToBeConfirm自动审批待确认/GoBack退回/Accepted通过）
--
-- 处理规则（对齐 xd_collateral.sql；本表为父表自身，无 mainId，不 JOIN 主档）：
--   1. 幂等：先按 (customerId, reportNo) 删除 app_single_check_task_info 本次范围旧行，再插入
--   2. 源头 append-only：按业务主键 (reportNo, customerId, serialNo) ROW_NUMBER 去重取最新（inputtime DESC, id DESC）
--   3. 一次查询可有多条任务（不同流水号），各出一行；balance 数值 CAST，日期列 LEFT 截断
-- =====================================================================

-- 1. 幂等
DELETE FROM app_single_check_task_info
WHERE (customerId = 'CUST-001' OR 'CUST-001' IS NULL)
  AND (reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL);

-- 2. 单项检查任务：xd_single_task_check -> app_single_check_task_info
INSERT INTO app_single_check_task_info (
    reportNo, customerId, customerName, itemCategory, serialNo, creditNo, approveTextNo,
    startDate, maturity, groupName, productName, checkDate, balance, "condition",
    implementStatus, extendDate, opinion, conditioninStruction,
    creditApproveUserName, approveAuthor, operateBelongOrgName, operateOrgName, operateUserName, approveStatusName
)
SELECT
    c.reportNo, c.customerId, c.customerName,
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
    END AS itemCategory,
    c.serialNo, c.creditNo, c.approveTextNo,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.startDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.startDate, 1, 10), '-', ''), '/', '')
         ELSE c.startDate END AS startDate,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.maturity, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.maturity, 1, 10), '-', ''), '/', '')
         ELSE c.maturity END AS maturity,
    c.groupName, c.productName,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.checkDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.checkDate, 1, 10), '-', ''), '/', '')
         ELSE c.checkDate END AS checkDate,
    c.balance AS balance,
    c.condition AS "condition",
    -- 落实情况：码值->中文（01已完成/02部分完成/03无法完成/06持续关注/07结清不续贷/08已有新批复/09延期），NULL/未收录原样保留
    CASE c.implementStatus
        WHEN '01' THEN '已完成'
        WHEN '02' THEN '部分完成'
        WHEN '03' THEN '无法完成'
        WHEN '06' THEN '持续关注'
        WHEN '07' THEN '结清不续贷'
        WHEN '08' THEN '已有新批复'
        WHEN '09' THEN '延期'
        ELSE c.implementStatus
    END AS implementStatus,
    CASE WHEN REGEXP_LIKE(SUBSTR(c.extendDate, 1, 10), '^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$')
         THEN REPLACE(REPLACE(SUBSTR(c.extendDate, 1, 10), '-', ''), '/', '')
         ELSE c.extendDate END AS extendDate,
    c.opinion,
    c.conditionInstruction AS conditioninStruction,
    c.creditApproveUserName, c.approveAuthor, c.operateBelongOrgName, c.operateOrgName, c.operateUserName,
    c.approveStatusName
FROM (
    SELECT c.reportNo, c.customerId, c.customerName, c.itemCategory, c.serialNo, c.creditNo, c.approveTextNo,
           c.startDate, c.maturity, c.groupName, c.productName, c.checkDate, c.balance, c.condition,
           c.implementStatus, c.extendDate, c.opinion, c.conditionInstruction, c.creditApproveUserName,
           c.approveAuthor, c.operateBelongOrgName, c.operateOrgName, c.operateUserName, c.approveStatusName,
           ROW_NUMBER() OVER (
               PARTITION BY c.reportNo, COALESCE(c.customerId, ''), COALESCE(c.serialNo, '')
               ORDER BY c.inputtime DESC, c.id DESC) AS rn
    FROM xd_single_task_check c
    WHERE c.reportNo IS NOT NULL
      AND (c.customerId = 'CUST-001' OR 'CUST-001' IS NULL)
      AND (c.reportNo   = 'RPT-202603-001'   OR 'RPT-202603-001'   IS NULL)
) c
WHERE c.rn = 1;
