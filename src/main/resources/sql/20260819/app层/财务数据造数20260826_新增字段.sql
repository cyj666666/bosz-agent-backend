-- =====================================================================
-- 苏州银行 贷后报告 财务数据造数配套：新增字段 currencyUnit（货币单位）
-- 目标表：app_finance_report_info / app_finance_index_info
-- 说明：造数要求字段"xinzeng"（货币单位），正式命名 currencyUnit（与已有 currency 报表币种对应）
-- 码值：元/千/万；造数样例统一为'万'。若目标表已按最新建表脚本重建，无需执行本脚本。
-- =====================================================================

ALTER TABLE app_finance_report_info ADD COLUMN currencyUnit VARCHAR(32);
COMMENT ON COLUMN app_finance_report_info.currencyUnit IS '货币单位（码值：元/千/万，样例为万）';

ALTER TABLE app_finance_index_info ADD COLUMN currencyUnit VARCHAR(32);
COMMENT ON COLUMN app_finance_index_info.currencyUnit IS '货币单位（码值：元/千/万，样例为万）';
