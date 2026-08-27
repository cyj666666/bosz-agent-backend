-- =====================================================================
-- 苏州银行 贷后报告 征信造数配套：5 张征信表结构调整（对已建库执行）
-- 依据：《征信数据造数20260827V1.xlsx》造数要求（新增/删除字段标注）
-- 说明：
--   1. 若目标表已按最新建表脚本重建，无需执行本脚本；
--   2. 接口字段按规范命名（驼峰业务名），原 qy_/gr_ 接口字段名在注释"上游直给"中注明；
--   3. 若此前已执行过旧版脚本（含 qy_fyjg_dwdb_bal 等 qy_ 字段名），请改用文件末尾的 RENAME 补救段。
-- =====================================================================

-- ---------- 1. app_guarantor_info：+guarantorId、-isListedCompany ----------
ALTER TABLE app_guarantor_info ADD COLUMN guarantorId VARCHAR(64);
COMMENT ON COLUMN app_guarantor_info.guarantorId IS '担保人客户编号（行内接口字段）';
ALTER TABLE app_guarantor_info DROP COLUMN isListedCompany;

-- ---------- 2. app_credit_report_info：+subjectType/guarantorId/guarantorName/接口与加工字段，-bankLeaseOrgCount ----------
ALTER TABLE app_credit_report_info ADD COLUMN subjectType VARCHAR(64);
COMMENT ON COLUMN app_credit_report_info.subjectType IS '主体类型（码值：借款人/担保人）';
ALTER TABLE app_credit_report_info ADD COLUMN guarantorId VARCHAR(64);
COMMENT ON COLUMN app_credit_report_info.guarantorId IS '担保人客户编号（subjectType=担保人时填写）';
ALTER TABLE app_credit_report_info ADD COLUMN guarantorName VARCHAR(128);
COMMENT ON COLUMN app_credit_report_info.guarantorName IS '担保人名称（subjectType=担保人时填写）';
ALTER TABLE app_credit_report_info ADD COLUMN nonBankGuaranteeBal DECIMAL(18,2);
COMMENT ON COLUMN app_credit_report_info.nonBankGuaranteeBal IS '在非银机构对外担保余额（万元，上游直给：qy_fyjg_dwdb_bal）';
ALTER TABLE app_credit_report_info ADD COLUMN workingCapitalLoanBal DECIMAL(18,2);
COMMENT ON COLUMN app_credit_report_info.workingCapitalLoanBal IS '流动资金贷款余额（万元，上游直给：qy_zhint_wjq_xyldk_bal）';
ALTER TABLE app_credit_report_info ADD COLUMN workingCapitalLoan1yBal DECIMAL(18,2);
COMMENT ON COLUMN app_credit_report_info.workingCapitalLoan1yBal IS '一年期以下的流动资金贷款余额（万元，上游直给：qy_zhint_wjq_xyldk_1year_bal）';
ALTER TABLE app_credit_report_info ADD COLUMN loanBankOrgCount INT;
COMMENT ON COLUMN app_credit_report_info.loanBankOrgCount IS '企业借贷交易合作银行及融资租赁机构数（上游直给：qy_jiedai_hzyh_org_cnt）';
ALTER TABLE app_credit_report_info ADD COLUMN guaranteeBankOrgCount INT;
COMMENT ON COLUMN app_credit_report_info.guaranteeBankOrgCount IS '企业担保交易合作银行及融资租赁机构数（上游直给：qy_danbao_hzyh_org_cnt）';
ALTER TABLE app_credit_report_info ADD COLUMN creditShortTermDiff DECIMAL(18,2);
COMMENT ON COLUMN app_credit_report_info.creditShortTermDiff IS '征信短期借款未结清余额与财报短期借款相差（万元，加工结果默认已有）';
ALTER TABLE app_credit_report_info ADD COLUMN creditLongTermDiff DECIMAL(18,2);
COMMENT ON COLUMN app_credit_report_info.creditLongTermDiff IS '征信中长期借款未结清余额与财报长期借款（含一年内到期的长期借款）相差（万元，加工结果默认已有）';
ALTER TABLE app_credit_report_info ADD COLUMN creditDebtDeviation DECIMAL(12,4);
COMMENT ON COLUMN app_credit_report_info.creditDebtDeviation IS '征信债务与财报债务偏离度（%，加工结果默认已有）';
ALTER TABLE app_credit_report_info ADD COLUMN guaranteeNetAsset DECIMAL(12,4);
COMMENT ON COLUMN app_credit_report_info.guaranteeNetAsset IS '对外担保/净资产（%）';
ALTER TABLE app_credit_report_info ADD COLUMN guaranteeBalanceExBank DECIMAL(18,2);
COMMENT ON COLUMN app_credit_report_info.guaranteeBalanceExBank IS '对外担保（相关还款责任）余额（剔除我行）（万元，上游直给：qy_dwdb_bal_exc_wx）';
ALTER TABLE app_credit_report_info DROP COLUMN bankLeaseOrgCount;

-- ---------- 3. app_credit_debt_detail：+subjectType/guarantorId/guarantorName ----------
ALTER TABLE app_credit_debt_detail ADD COLUMN subjectType VARCHAR(64);
COMMENT ON COLUMN app_credit_debt_detail.subjectType IS '主体类型（码值：借款人/担保人）';
ALTER TABLE app_credit_debt_detail ADD COLUMN guarantorId VARCHAR(64);
COMMENT ON COLUMN app_credit_debt_detail.guarantorId IS '担保人客户编号（subjectType=担保人时填写）';
ALTER TABLE app_credit_debt_detail ADD COLUMN guarantorName VARCHAR(128);
COMMENT ON COLUMN app_credit_debt_detail.guarantorName IS '担保人名称（subjectType=担保人时填写）';

-- ---------- 4. app_guarantor_credit_info：+guarantorId、+nonBankLiabTotal、-guaranteeNetAsset、-guaranteeBalanceExBank（两字段为企业维度，挪至 app_credit_report_info） ----------
ALTER TABLE app_guarantor_credit_info ADD COLUMN guarantorId VARCHAR(64);
COMMENT ON COLUMN app_guarantor_credit_info.guarantorId IS '担保人客户编号';
ALTER TABLE app_guarantor_credit_info ADD COLUMN nonBankLiabTotal DECIMAL(18,2);
COMMENT ON COLUMN app_guarantor_credit_info.nonBankLiabTotal IS '在非银机构负债合计（万元，个人，上游直给：gr_fyjg_liab_tot）';
ALTER TABLE app_guarantor_credit_info DROP COLUMN guaranteeNetAsset;
ALTER TABLE app_guarantor_credit_info DROP COLUMN guaranteeBalanceExBank;

-- ---------- 5. app_credit_query_info：+guarantorId/guarantorName ----------
ALTER TABLE app_credit_query_info ADD COLUMN guarantorId VARCHAR(64);
COMMENT ON COLUMN app_credit_query_info.guarantorId IS '担保人客户编号';
ALTER TABLE app_credit_query_info ADD COLUMN guarantorName VARCHAR(128);
COMMENT ON COLUMN app_credit_query_info.guarantorName IS '担保人名称';

-- =====================================================================
-- 【补救段】若此前已按旧版脚本执行过（字段名为 qy_fyjg_dwdb_bal 等），
-- 用以下 RENAME 将字段改为规范名；注释同步更新。
-- =====================================================================
ALTER TABLE app_credit_report_info RENAME COLUMN qy_fyjg_dwdb_bal TO nonBankGuaranteeBal;
COMMENT ON COLUMN app_credit_report_info.nonBankGuaranteeBal IS '在非银机构对外担保余额（万元，上游直给：qy_fyjg_dwdb_bal）';
ALTER TABLE app_credit_report_info RENAME COLUMN qy_zhint_wjq_xyldk_bal TO workingCapitalLoanBal;
COMMENT ON COLUMN app_credit_report_info.workingCapitalLoanBal IS '流动资金贷款余额（万元，上游直给：qy_zhint_wjq_xyldk_bal）';
ALTER TABLE app_credit_report_info RENAME COLUMN qy_zhint_wjq_xyldk_1year_bal TO workingCapitalLoan1yBal;
COMMENT ON COLUMN app_credit_report_info.workingCapitalLoan1yBal IS '一年期以下的流动资金贷款余额（万元，上游直给：qy_zhint_wjq_xyldk_1year_bal）';
ALTER TABLE app_credit_report_info RENAME COLUMN qy_jiedai_hzyh_org_cnt TO loanBankOrgCount;
COMMENT ON COLUMN app_credit_report_info.loanBankOrgCount IS '企业借贷交易合作银行及融资租赁机构数（上游直给：qy_jiedai_hzyh_org_cnt）';
ALTER TABLE app_credit_report_info RENAME COLUMN qy_danbao_hzyh_org_cnt TO guaranteeBankOrgCount;
COMMENT ON COLUMN app_credit_report_info.guaranteeBankOrgCount IS '企业担保交易合作银行及融资租赁机构数（上游直给：qy_danbao_hzyh_org_cnt）';
