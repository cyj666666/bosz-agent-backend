-- =====================================================================
-- 【核验脚本】ETL造数_合并 · 源表行数核验
-- 用途：跑完 01~05 后，逐张确认「源头表是否已为 reportNo='RPT-202609-001' 造出数据」
-- 期望：38 张有数据；gfzx_finance_index_item 是「本表不取，预留」⇒ 0 行属正常
-- 用法：可整文件执行（每条独立 SELECT）；或在任意 SQL 客户端逐条跑
-- =====================================================================

-- ---------- 外数加工（01）----------
SELECT 'ws_gs_info'                        AS tbl, count(*) AS n FROM ws_gs_info                        WHERE reportNo = 'RPT-202609-001';
SELECT 'ws_beneficial_owner'               AS tbl, count(*) AS n FROM ws_beneficial_owner               WHERE reportNo = 'RPT-202609-001';
SELECT 'std_ecis_t_mining_tags_dd'         AS tbl, count(*) AS n FROM std_ecis_t_mining_tags_dd         WHERE reportNo = 'RPT-202609-001';
SELECT 'ws_best_shareholding'              AS tbl, count(*) AS n FROM ws_best_shareholding              WHERE reportNo = 'RPT-202609-001';
SELECT 'ws_equity_change'                  AS tbl, count(*) AS n FROM ws_equity_change                  WHERE reportNo = 'RPT-202609-001';
SELECT 'ws_base_info'                      AS tbl, count(*) AS n FROM ws_base_info                      WHERE reportNo = 'RPT-202609-001';

-- ---------- 客户企业概况加工（02）----------
SELECT 'xd_corp_check_info'                AS tbl, count(*) AS n FROM xd_corp_check_info                WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_daily_index'         AS tbl, count(*) AS n FROM xd_corp_check_daily_index         WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_fixed_loan'          AS tbl, count(*) AS n FROM xd_corp_check_fixed_loan          WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_operate_loan'        AS tbl, count(*) AS n FROM xd_corp_check_operate_loan        WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_reply_requirement'   AS tbl, count(*) AS n FROM xd_corp_check_reply_requirement   WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_checkin'             AS tbl, count(*) AS n FROM xd_corp_check_checkin             WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_credit_requirement'  AS tbl, count(*) AS n FROM xd_corp_check_credit_requirement  WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_current_opinion'     AS tbl, count(*) AS n FROM xd_corp_check_current_opinion     WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_last_opinion'        AS tbl, count(*) AS n FROM xd_corp_check_last_opinion        WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_supplier'            AS tbl, count(*) AS n FROM xd_corp_check_supplier            WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_warning_task'        AS tbl, count(*) AS n FROM xd_corp_check_warning_task        WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_warning_opinion'     AS tbl, count(*) AS n FROM xd_corp_check_warning_opinion     WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_warning_ledger'                 AS tbl, count(*) AS n FROM xd_warning_ledger                 WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_customer_info'             AS tbl, count(*) AS n FROM xd_corp_customer_info             WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_customer_control'          AS tbl, count(*) AS n FROM xd_corp_customer_control          WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_customer_shareholder'      AS tbl, count(*) AS n FROM xd_corp_customer_shareholder      WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_credit_info'                    AS tbl, count(*) AS n FROM xd_credit_info                    WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_credit_loan'                    AS tbl, count(*) AS n FROM xd_credit_loan                    WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_credit_payment'                 AS tbl, count(*) AS n FROM xd_credit_payment                 WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_single_task_check'              AS tbl, count(*) AS n FROM xd_single_task_check              WHERE reportNo = 'RPT-202609-001';

-- ---------- 押品加工（03）----------
SELECT 'xd_corp_check_collateral'          AS tbl, count(*) AS n FROM xd_corp_check_collateral          WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_collateral_mortgage' AS tbl, count(*) AS n FROM xd_corp_check_collateral_mortgage WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_corp_check_collateral_restrict' AS tbl, count(*) AS n FROM xd_corp_check_collateral_restrict WHERE reportNo = 'RPT-202609-001';

-- ---------- 贷后检查加工（04）----------
SELECT 'xd_fund_use_abnormal'              AS tbl, count(*) AS n FROM xd_fund_use_abnormal              WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_graph_hit'                      AS tbl, count(*) AS n FROM xd_graph_hit                      WHERE eid = 'ENT-CUST-001';
SELECT 'dfs_crdt_loan_cust_rel'            AS tbl, count(*) AS n FROM dfs_crdt_loan_cust_rel            WHERE reportNo = 'RPT-202609-001';
SELECT 'dfs_final_crdt_loan_cust_rel'      AS tbl, count(*) AS n FROM dfs_final_crdt_loan_cust_rel      WHERE reportNo = 'RPT-202609-001';
SELECT 'gfzx_finance_index_item'           AS tbl, count(*) AS n FROM gfzx_finance_index_item           WHERE reportNo = 'RPT-202609-001';
SELECT 'gfzx_balance_sheet_item'           AS tbl, count(*) AS n FROM gfzx_balance_sheet_item           WHERE reportNo = 'RPT-202609-001';
SELECT 'gfzx_profit_sheet_item'            AS tbl, count(*) AS n FROM gfzx_profit_sheet_item            WHERE reportNo = 'RPT-202609-001';
SELECT 'gfzx_national_dev'                 AS tbl, count(*) AS n FROM gfzx_national_dev                 WHERE reportNo = 'RPT-202609-001';

-- ---------- 财务指标加工（05）----------
SELECT 'xd_financial_report'               AS tbl, count(*) AS n FROM xd_financial_report               WHERE reportNo = 'RPT-202609-001';
SELECT 'xd_financial_subject'              AS tbl, count(*) AS n FROM xd_financial_subject              WHERE reportNo = 'RPT-202609-001';
