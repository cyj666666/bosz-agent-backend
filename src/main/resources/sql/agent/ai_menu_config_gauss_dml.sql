-- =====================================================================
-- ai_menu_config 千寻菜单配置表 —— 初始数据（openGauss / GaussDB 兼容 MySQL 版）
--
--   目标 schema  : bosz_test
--   表结构来源   : sql/agent/agent_gauss_ddl.sql 第 365-389 行
--                  （10 字段：id/menu_code/menu_name/status/url/input_time/
--                    update_time/order_num/icon/component_url，PRIMARY KEY(id) + 2 索引）
--   数据来源     : amar-agent-server/doc/db/mysql/DML.sql 中的 ai_menu_config 9 条记录
--   改动说明     : 字段值原样搬运，未做任何增删改；
--                  仅做两件事 —— ① 补 SET search_path；
--                  ② 标识符统一为不加双引号（与 agent_gauss_ddl.sql 建表风格一致）；
--                  ③ 按 order_num 升序排列（便于与菜单实际展示顺序对照，不改变数据）。
--   为什么单独出这份：公司交付的 agent_gauss_dml.sql 只覆盖 JeecgBoot 系统层
--                     （sys_dict / sys_permission / sys_role / sys_user 等 7 张表），
--                     不含本表数据，这里是补齐。
--
--   执行注意：
--     ① 前置条件：bosz_test.ai_menu_config 必须已由 agent_gauss_ddl.sql 建好。
--     ② 本库为 SQL_ASCII 编码 + schema collation = binary，中文以字节原样存储，
--        不做编码转换。执行客户端编码必须与应用的编码一致（统一 UTF-8），
--        否则中文菜单名会变成乱码。本文件保存为 UTF-8（无 BOM）。
--     ③ 本脚本不幂等：id 是 PRIMARY KEY，重复执行会主键冲突报错。
--        需重跑时先自行执行：DELETE FROM ai_menu_config;
-- =====================================================================

SET search_path = bosz_test, public;

INSERT INTO ai_menu_config (id, menu_code, menu_name, status, url, input_time, update_time, order_num, icon, component_url) VALUES
('6266976404736822145', 'Component',       '智能组件库',    'Y', '',                       '2025-04-01 16:35:31', '2025-08-25 10:13:55', 1, 'https://cloud.amardata.com/oss/zhishu-demo/1756088033974_component.svg', ''),
('1907344171418357751', 'PairTrace',       '舆情追踪',      'Y', '/senti/sentiment',       '2025-04-01 16:35:31', '2025-08-25 10:04:56', 2, 'https://cloud.amardata.com/oss/zhishu-demo/1756087495057_sentiment.svg', 'senti/Sentiment'),
('1910503147054735362', 'CheckRule',       '合规检查',      'Y', '/check/checkRule',       '2025-04-11 09:20:20', '2025-08-25 10:04:08', 3, 'https://cloud.amardata.com/oss/zhishu-demo/1756087446969_check.svg',     'check/CheckRule'),
('1907344171418353761', 'RiskSearch',      '风险筛查',      'Y', '/risk/riskFilter',       '2025-04-01 16:35:31', '2025-08-25 10:04:45', 4, 'https://cloud.amardata.com/oss/zhishu-demo/1756087484840_risk.svg',      'riskFilter/RiskFilter'),
('1932607844113813506', 'CreditProcess',   '营销尽调',      'Y', '/credit/creditProcess',  '2025-06-11 09:16:30', '2025-08-25 10:04:37', 5, 'https://cloud.amardata.com/oss/zhishu-demo/1756087476564_credit.svg',    'credit/CreditProcessV2'),
('1999305888419979266', 'FinanceAgent',    '财务智能体',    'Y', '/agent/finance',         '2025-12-12 10:30:43', '2025-12-12 10:30:43', 6, 'https://cloud.amardata.com/oss/zhishu/1764157504373_finance_icon.svg',   'agent/main/finance/FinanceAgent'),
('1999305778743123970', 'IndustryAgent',   '行业智能体',    'Y', '/agent/industry',        '2025-12-12 10:30:17', '2025-12-12 10:30:17', 7, 'https://cloud.amardata.com/oss/zhishu/1764157537252_industry_icon.svg',  'agent/main/industry/IndustryAgent'),
('2009516408681766914', 'FinanceAgentPro', '行业智能体V2.0', 'Y', '/agent/industry/pro',    '2026-01-09 14:43:41', '2026-01-09 14:43:41', 8, 'https://cloud.amardata.com/oss/zhishu-demo/1767941018257_industry_icon.svg', 'agent/main/industry/IndustryAgentPro'),
('1999305685373722626', 'ComplianceAgent', '合规智能体',    'Y', '/agent/compliance',      '2025-12-12 10:29:55', '2026-01-09 14:43:49', 9, 'https://cloud.amardata.com/oss/zhishu/1764157572812_compliance_icon.svg', 'agent/main/compliance/ComplianceAgent');

-- 校验：应返回 9 行
-- SELECT order_num, menu_code, menu_name, url, component_url FROM ai_menu_config ORDER BY order_num;
