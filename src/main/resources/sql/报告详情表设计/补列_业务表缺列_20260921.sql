-- =====================================================================
-- 补列脚本：按「表结构缺列自检」结果一次补齐（2026-09-21）
-- 数据库：高斯DB（GaussDB / openGauss）
--
-- 来源：在**本地库**跑 `校验_表结构缺列_20260921.sql` 实测得到 —— 11 张表共缺 39 列。
--   ⚠️ 2026-09-21 复核更正：这 39 列里有 **2 列并非真的缺失，而是库内列名拼写错**
--      （`app_finance_indicator_info` 的 notespayablechangefromyearstart / ...rate，
--       库里建成了 note**payable**changefromyearstart，少一个 s）⇒ 已从本脚本移出。
--      🔴 **请先执行 `改名_财务指标_应付票据两列_20260921.sql`**（RENAME，保留 18 行数据），
--         再跑本脚本。⇒ 本脚本实际为 **37 条 ADD COLUMN**。
--   根因：这些表的 DDL 文本持续演进，但库里是**早期建的**、且一直没有配套补列脚本 ⇒ 缺列。
--   后果：报告生成的「指标取数」链路会报 `column xxx does not exist`（PG 只报第一个，
--         所以逐列补是打地鼠 —— 本脚本一次补全）。
--
-- 类型/注释均**照仓库 DDL 原样**摘取（未加引号的小写列名，与库内物理列名一致）。
--
-- ⚠️ 幂等性：**不幂等**。列已存在时重复执行会报
--   "column xxx of relation yyy already exists"，属正常现象，跳过即可。
-- ⚠️ 若某条报「已存在」，说明该列其实有 —— 请回到自检脚本复核（可能 schema 不一致）。
-- =====================================================================

-- 执行前置：SET search_path = <你的 schema>, public;

BEGIN;

-- ---------------------------------------------------------------------
-- app_specific_loan_project_check_info（缺 17 列）
-- ---------------------------------------------------------------------
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN explain TEXT;
COMMENT ON COLUMN app_specific_loan_project_check_info.explain IS '说明（项目情况说明）';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN ifbuild VARCHAR(32);
COMMENT ON COLUMN app_specific_loan_project_check_info.ifbuild IS '是否建设期（码值：是/否）';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN ifconstructionexpect VARCHAR(32);
COMMENT ON COLUMN app_specific_loan_project_check_info.ifconstructionexpect IS '建设期进度是否符合预期（码值：是/否）';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN ifgetpermission VARCHAR(32);
COMMENT ON COLUMN app_specific_loan_project_check_info.ifgetpermission IS '是否取得预售证（码值：是/否/不涉及）';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN ifmatch VARCHAR(32);
COMMENT ON COLUMN app_specific_loan_project_check_info.ifmatch IS '资金使用是否与项目进度匹配（码值：是/否）';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN ifopenaccount VARCHAR(32);
COMMENT ON COLUMN app_specific_loan_project_check_info.ifopenaccount IS '是否开立监管账户（码值：是/否）';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN ifoperate VARCHAR(32);
COMMENT ON COLUMN app_specific_loan_project_check_info.ifoperate IS '是否运营期（码值：是/否）';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN ifoverinvest VARCHAR(32);
COMMENT ON COLUMN app_specific_loan_project_check_info.ifoverinvest IS '是否存在超投情况（码值：是/否）';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN ifrunexpect VARCHAR(32);
COMMENT ON COLUMN app_specific_loan_project_check_info.ifrunexpect IS '运营是否符合预期（码值：是/否/不涉及）';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN ifsign VARCHAR(32);
COMMENT ON COLUMN app_specific_loan_project_check_info.ifsign IS '资金监管协议是否已签署（码值：是/否）';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN lastcapitalcheckcondition TEXT;
COMMENT ON COLUMN app_specific_loan_project_check_info.lastcapitalcheckcondition IS '项目资本金情况前次检查情况';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN lastpurchasecheckcondition TEXT;
COMMENT ON COLUMN app_specific_loan_project_check_info.lastpurchasecheckcondition IS '建安工程或设备采购支出情况前次检查情况';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN lastruncheckcondition TEXT;
COMMENT ON COLUMN app_specific_loan_project_check_info.lastruncheckcondition IS '运营检查前次检查情况';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN lastschedulecheckcondition TEXT;
COMMENT ON COLUMN app_specific_loan_project_check_info.lastschedulecheckcondition IS '项目建设进度前次检查情况';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN lastsupervisecheckcondition TEXT;
COMMENT ON COLUMN app_specific_loan_project_check_info.lastsupervisecheckcondition IS '资金监管情况前次检查情况';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN overinvest TEXT;
COMMENT ON COLUMN app_specific_loan_project_check_info.overinvest IS '超投情况说明';
ALTER TABLE app_specific_loan_project_check_info ADD COLUMN purchasecheckcondition TEXT;
COMMENT ON COLUMN app_specific_loan_project_check_info.purchasecheckcondition IS '建安工程或设备采购支出情况本次检查情况';

-- ---------------------------------------------------------------------
-- app_loan_receipt_info（缺 5 列）
-- ---------------------------------------------------------------------
ALTER TABLE app_loan_receipt_info ADD COLUMN extendbalance DECIMAL(18,2);
COMMENT ON COLUMN app_loan_receipt_info.extendbalance IS '展期贷款余额（万元）';
ALTER TABLE app_loan_receipt_info ADD COLUMN producttype VARCHAR(64);
COMMENT ON COLUMN app_loan_receipt_info.producttype IS '产品类型（基础/组合/固贷/房地产）';
ALTER TABLE app_loan_receipt_info ADD COLUMN reorgbalance DECIMAL(18,2);
COMMENT ON COLUMN app_loan_receipt_info.reorgbalance IS '借新还旧余额（万元）';
ALTER TABLE app_loan_receipt_info ADD COLUMN reorgtimes INT;
COMMENT ON COLUMN app_loan_receipt_info.reorgtimes IS '借新还旧次数';
ALTER TABLE app_loan_receipt_info ADD COLUMN restructedbalance DECIMAL(18,2);
COMMENT ON COLUMN app_loan_receipt_info.restructedbalance IS '重组贷款余额（万元）';

-- ---------------------------------------------------------------------
-- app_early_warning_info（缺 3 列）
-- ---------------------------------------------------------------------
ALTER TABLE app_early_warning_info ADD COLUMN endtime VARCHAR(32);
COMMENT ON COLUMN app_early_warning_info.endtime IS '审批日期';
ALTER TABLE app_early_warning_info ADD COLUMN phaseopinion TEXT;
COMMENT ON COLUMN app_early_warning_info.phaseopinion IS '审批意见';
ALTER TABLE app_early_warning_info ADD COLUMN riskreason TEXT;
COMMENT ON COLUMN app_early_warning_info.riskreason IS '风险原因';

-- ---------------------------------------------------------------------
-- app_finance_indicator_info（缺 1 列）
--   ⚠️ 原自检报「缺 3 列」，其中 notespayablechangefromyearstart / ...rate
--      是**列名拼写错**（库里少了 s），不是缺列 ⇒ 已移到
--      `改名_财务指标_应付票据两列_20260921.sql`（RENAME 保数据）。
--      本脚本只补真正缺失的 sheetno。
-- ---------------------------------------------------------------------
ALTER TABLE app_finance_indicator_info ADD COLUMN sheetno VARCHAR(64);
COMMENT ON COLUMN app_finance_indicator_info.sheetno IS '科目所在财报类型';

-- ---------------------------------------------------------------------
-- app_customer_info（缺 2 列）
-- ---------------------------------------------------------------------
ALTER TABLE app_customer_info ADD COLUMN groupname VARCHAR(128);
COMMENT ON COLUMN app_customer_info.groupname IS '所属集团名称';
ALTER TABLE app_customer_info ADD COLUMN isstateowned VARCHAR(64);
COMMENT ON COLUMN app_customer_info.isstateowned IS '是否国资/国有担保（码值：是/否（由控股类型holdType判断））';

-- ---------------------------------------------------------------------
-- app_early_warning_signal_info（缺 2 列）
-- ---------------------------------------------------------------------
ALTER TABLE app_early_warning_signal_info ADD COLUMN count INT;
COMMENT ON COLUMN app_early_warning_signal_info.count IS '数量';
ALTER TABLE app_early_warning_signal_info ADD COLUMN readycount INT;
COMMENT ON COLUMN app_early_warning_signal_info.readycount IS '待填写数量';

-- ---------------------------------------------------------------------
-- app_ic_shareholder_info（缺 2 列）
-- ---------------------------------------------------------------------
ALTER TABLE app_ic_shareholder_info ADD COLUMN icstockpercent DECIMAL(12,4);
COMMENT ON COLUMN app_ic_shareholder_info.icstockpercent IS '工商股东持股比例（%）';
ALTER TABLE app_ic_shareholder_info ADD COLUMN snapshot_type VARCHAR(32);
COMMENT ON COLUMN app_ic_shareholder_info.snapshot_type IS '快照类型（latest最新/atCredit授信时）';

-- ---------------------------------------------------------------------
-- app_settle_counterparty_info（缺 2 列）
-- ---------------------------------------------------------------------
ALTER TABLE app_settle_counterparty_info ADD COLUMN remark VARCHAR(512);
COMMENT ON COLUMN app_settle_counterparty_info.remark IS '交易备注（预留：备注含担保/借款/投资关键字贷方发生额筛选用，接口待补充）';
ALTER TABLE app_settle_counterparty_info ADD COLUMN upstreamflag VARCHAR(32);
COMMENT ON COLUMN app_settle_counterparty_info.upstreamflag IS '是否前五大上游客户（码值：是/否）';

-- ---------------------------------------------------------------------
-- app_collateral_mortgage_info（缺 1 列）
-- ---------------------------------------------------------------------
ALTER TABLE app_collateral_mortgage_info ADD COLUMN clrname VARCHAR(128);
COMMENT ON COLUMN app_collateral_mortgage_info.clrname IS '关联押品名称';

-- ---------------------------------------------------------------------
-- app_ic_info（缺 1 列）
-- ---------------------------------------------------------------------
ALTER TABLE app_ic_info ADD COLUMN icbeneficiarypercent DECIMAL(12,4);
COMMENT ON COLUMN app_ic_info.icbeneficiarypercent IS '工商受益人持股比例（%）';

-- ---------------------------------------------------------------------
-- app_shareholder_info（缺 1 列）
-- ---------------------------------------------------------------------
ALTER TABLE app_shareholder_info ADD COLUMN is_listed_company VARCHAR(32);
COMMENT ON COLUMN app_shareholder_info.is_listed_company IS '股东是否上市公司（码值：是/否，中台按股东主体查询）';

COMMIT;

-- =====================================================================
-- 复核：重跑 `校验_表结构缺列_20260921.sql`，结果集②应为 0 行
-- =====================================================================

