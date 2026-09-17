-- =============================================================================
-- 10_修正_指标SQL企业过滤.sql
-- -----------------------------------------------------------------------------
-- 目的：修正指标 `gscbycwtqxcfdsn`（国税财报4指标-与财务同期值及相差幅度-**上年**）
--       的 SQL —— 它**没有做企业过滤**，取的是"全库最新一期的借款人本部财报"，
--       与同族其余指标（`gscbycwtqxcfdqn` 前年 / `gfcbycwtqxcfd*` 国发族）口径不一致。
--
-- 病征（2026-09-16 实测）：
--   · 该指标下 4 个子指标（营业收入/应收账款/应付账款/存货 偏差幅度）**与 entName 无关**，
--     恒定返回库里最新一期数据的偏差幅度；
--   · 检查项「报表真实性」的表达式是 `A>20 || B>20 || ...`，这 4 个值恰好全部 > 20
--     ⇒ **OR 链恒为真 ⇒ 随便填什么企业名都判"命中"**，并照常触发 AI 分析。
--   · 影响面**跨菜单**：智策引擎校验、AI 分析、报告生成都会用到该指标。
--
-- 改法：比照同族「前年」`gscbycwtqxcfdqn` 的口径，给**主查询与子查询**都补上
--       `f.REPORTNO = :reportNo` / `f.CUSTOMERID = :customerId` / `f.CUSTOMERNAME = :entName`。
--       这三个命名参数在 `paramData` 里**早已声明**（默认值 RPT-202603-001 / CUST-001 /
--       苏州XX精密机械制造有限公司），只是 SQL 之前没引用 —— 所以本修正**不需要改 paramData**。
--
-- 幂等：带 `script NOT LIKE '%:entName%'` 守卫，重复执行不会二次改写。
-- 影响行数：**1 行**（`paramid='gscbycwtqxcfdsn'`），但它带 4 个子指标一起生效。
-- 回滚：文件末尾附原始值（注释形式）。
-- =============================================================================

-- ① 修正 ---------------------------------------------------------------
UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT\n    f.ACCOUNTMONTH AS 会计月,\n    g.LASTYEAR AS 国税去年日期,\n\n    f.REVENUE AS 财报营业收入,\n    g.LASTYEARREVENUE AS 国税营业收入,\n    ROUND(\n        ABS(f.REVENUE - g.LASTYEARREVENUE)\n        / NULLIF(ABS(f.REVENUE), 0) * 100,\n        2\n    ) AS 营业收入偏差幅度,\n\n    f.ACCOUNTSRECEIVABLE AS 财报应收账款,\n    g.LASTYEARRECEIVABLE AS 国税应收账款,\n    ROUND(\n        ABS(f.ACCOUNTSRECEIVABLE - g.LASTYEARRECEIVABLE)\n        / NULLIF(ABS(f.ACCOUNTSRECEIVABLE), 0) * 100,\n        2\n    ) AS 应收账款偏差幅度,\n\n    f.ACCOUNTSPAYABLE AS 财报应付账款,\n    g.LASTYEARPAYABLE AS 国税应付账款,\n    ROUND(\n        ABS(f.ACCOUNTSPAYABLE - g.LASTYEARPAYABLE)\n        / NULLIF(ABS(f.ACCOUNTSPAYABLE), 0) * 100,\n        2\n    ) AS 应付账款偏差幅度,\n\n    f.INVENTORY AS 财报存货,\n    g.LASTYEARINVENTORY AS 国税存货,\n    ROUND(\n        ABS(f.INVENTORY - g.LASTYEARINVENTORY)\n        / NULLIF(ABS(f.INVENTORY), 0) * 100,\n        2\n    ) AS 存货偏差幅度\n\nFROM APP_FINANCE_INDICATOR_INFO f\nLEFT JOIN APP_GS_FINANCE_DATA_INFO g\n    ON f.REPORTNO = g.REPORTNO\n    AND f.CUSTOMERID = g.CUSTOMERID\n    AND f.CUSTOMERNAME = g.CUSTOMERNAME\n    AND g.REPORTSCOPE = ''本部''\n    AND f.ACCOUNTMONTH = SUBSTRING(TRIM(g.LASTYEAR), 1, 6)\n\nWHERE f.REPORTNO = :reportNo\n  AND f.CUSTOMERID = :customerId\n  AND f.CUSTOMERNAME = :entName\n  AND f.REPORTSCOPE = ''本部''\n  AND f.subjectType=''借款人''\n  AND f.ACCOUNTMONTH::INTEGER = (\n      SELECT\n          (FLOOR(MAX(f2.ACCOUNTMONTH::INTEGER) / 100) - 1) * 100 + 12\n      FROM APP_FINANCE_INDICATOR_INFO f2\n      WHERE f2.REPORTNO = :reportNo\n        AND f2.CUSTOMERID = :customerId\n        AND f2.CUSTOMERNAME = :entName\n  AND f2.subjectType=''借款人''\n  )\nORDER BY f.INPUTTIME DESC\nLIMIT 1","paramData":[{"id":"54b10e26-eac0-d8dd-0c52-1154a40f3c5a","name":"reportNo","desc":"","type":"1","isSync":"Y","defaultValue":"''RPT-202603-001''","relateIndex":null},{"id":"60dfe437-041d-15ed-ee8c-38b56b9a782e","name":"customerId","desc":"","type":"1","isSync":"Y","defaultValue":"''CUST-001''","relateIndex":null},{"id":"6c7e9878-e4ba-ae73-4754-f3f5165bb750","name":"entName","desc":"","type":"1","isSync":"Y","defaultValue":"''苏州XX精密机械制造有限公司''","relateIndex":null}],"moduleCode":"","knowledgeCode":"","knowledgeName":"","knowledgeGroupInfo":[],"withModelSummary":false,"knowledgeParamList":[{"key":"1","paramName":"entName","paramValue":"科大讯飞股份有限公司"}],"entName":"科大讯飞股份有限公司"}'
 WHERE paramid = 'gscbycwtqxcfdsn'
   AND paramno = '2099487507734343681'
   AND script NOT LIKE '%:entName%';

-- ② 校验（应返回 1 行，has_ent_filter = 1） ------------------------------
SELECT paramno,
       paramid,
       paramname,
       CASE WHEN script LIKE '%:entName%' THEN 1 ELSE 0 END AS has_ent_filter,
       CASE WHEN script LIKE '%:customerId%' THEN 1 ELSE 0 END AS has_customer_filter,
       CASE WHEN script LIKE '%:reportNo%' THEN 1 ELSE 0 END AS has_report_filter
  FROM index_params
 WHERE paramid = 'gscbycwtqxcfdsn';

-- ③ 全量复查：所有 Sql 类型指标里，还有谁读业务表却没做企业过滤 ------------------
--    （修正后预期：APP_FINANCE_INDICATOR_INFO 相关的指标全部带 :entName）
SELECT count(1) AS sql_metrics,
       sum(CASE WHEN script LIKE '%:entName%' THEN 1 ELSE 0 END) AS with_ent_filter
  FROM index_params
 WHERE scripttype = 'Sql'
   AND script LIKE '%SELECT%';

-- ④ 回滚（如需还原：取消注释执行） ---------------------------------------------
-- UPDATE index_params SET script = '{"dataSource":"2095447359636992001","sql":"SELECT\n    f.ACCOUNTMONTH AS 会计月,\n    g.LASTYEAR AS 国税去年日期,\n\n    f.REVENUE AS 财报营业收入,\n    g.LASTYEARREVENUE AS 国税营业收入,\n    ROUND(\n        ABS(f.REVENUE - g.LASTYEARREVENUE)\n        / NULLIF(ABS(f.REVENUE), 0) * 100,\n        2\n    ) AS 营业收入偏差幅度,\n\n    f.ACCOUNTSRECEIVABLE AS 财报应收账款,\n    g.LASTYEARRECEIVABLE AS 国税应收账款,\n    ROUND(\n        ABS(f.ACCOUNTSRECEIVABLE - g.LASTYEARRECEIVABLE)\n        / NULLIF(ABS(f.ACCOUNTSRECEIVABLE), 0) * 100,\n        2\n    ) AS 应收账款偏差幅度,\n\n    f.ACCOUNTSPAYABLE AS 财报应付账款,\n    g.LASTYEARPAYABLE AS 国税应付账款,\n    ROUND(\n        ABS(f.ACCOUNTSPAYABLE - g.LASTYEARPAYABLE)\n        / NULLIF(ABS(f.ACCOUNTSPAYABLE), 0) * 100,\n        2\n    ) AS 应付账款偏差幅度,\n\n    f.INVENTORY AS 财报存货,\n    g.LASTYEARINVENTORY AS 国税存货,\n    ROUND(\n        ABS(f.INVENTORY - g.LASTYEARINVENTORY)\n        / NULLIF(ABS(f.INVENTORY), 0) * 100,\n        2\n    ) AS 存货偏差幅度\n\nFROM APP_FINANCE_INDICATOR_INFO f\nLEFT JOIN APP_GS_FINANCE_DATA_INFO g\n    ON f.REPORTNO = g.REPORTNO\n    AND f.CUSTOMERID = g.CUSTOMERID\n    AND f.CUSTOMERNAME = g.CUSTOMERNAME\n    AND g.REPORTSCOPE = ''本部''\n    AND f.ACCOUNTMONTH = SUBSTRING(TRIM(g.LASTYEAR), 1, 6)\n\nWHERE \n   f.REPORTSCOPE = ''本部''\n  AND f.subjectType=''借款人''\n  AND f.ACCOUNTMONTH::INTEGER = (\n      SELECT\n          (FLOOR(MAX(f2.ACCOUNTMONTH::INTEGER) / 100) - 1) * 100 + 12\n      FROM APP_FINANCE_INDICATOR_INFO f2\n      WHERE \n       f2.subjectType=''借款人''\n  )\nORDER BY f.INPUTTIME DESC\nLIMIT 1","paramData":[{"id":"54b10e26-eac0-d8dd-0c52-1154a40f3c5a","name":"reportNo","desc":"","type":"1","isSync":"Y","defaultValue":"''RPT-202603-001''","relateIndex":null},{"id":"60dfe437-041d-15ed-ee8c-38b56b9a782e","name":"customerId","desc":"","type":"1","isSync":"Y","defaultValue":"''CUST-001''","relateIndex":null},{"id":"6c7e9878-e4ba-ae73-4754-f3f5165bb750","name":"entName","desc":"","type":"1","isSync":"Y","defaultValue":"''苏州XX精密机械制造有限公司''","relateIndex":null}],"moduleCode":"","knowledgeCode":"","knowledgeName":"","knowledgeGroupInfo":[],"withModelSummary":false,"knowledgeParamList":[{"key":"1","paramName":"entName","paramValue":"科大讯飞股份有限公司"}],"entName":"科大讯飞股份有限公司"}'
--  WHERE paramid = 'gscbycwtqxcfdsn' AND paramno = '2099487507734343681';
