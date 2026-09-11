-- =====================================================================
-- 报告详情页 · 模板层初始数据（DML）
-- 数据库：高斯DB（GaussDB）
-- 依据  ：前端报告详情页 mock 数据（src/hooks/useReportApi.ts，V5.2 移植版）
-- 内容  ：app_report_catalog（12 个一级目录）+ app_report_content_block（82 个内容块）
--
-- 结构映射约定：
--   ① 目录：mock 页左侧目录为 12 个章节，故建 12 个一级目录（catalogLevel=1，parentCode=NULL）。
--      二级/三级目录能力已在表结构中支持，后续有子目录需求时追加数据即可。
--   ② 报告头：不属于任何目录，用 catalogCode=NULL 的报告级内容块承载
--      （1 个主标题块 + 1 个副标题块 + 1 个说明块）。
--   ③ 章节内结构：章节标题（titleLevel=2）→ 小节标题（titleLevel=3，仅 mock 中有 h4 的章节）
--      → 正文块 → 表格块 → 溯源按钮块 → AI 风险块。
--   ④ sortNo：标题/正文 10、20、30…递增；溯源按钮固定 900；AI 风险块 1000 起。
--      如需把风险提示穿插进正文中间，只需调整对应块的 sortNo。
--   ⑤ emptyStrategy：全部统一为 PLACEHOLDER（保留结构、实例内容为空时显示暂无数据占位）。
--   ⑥ 编码规则：
--      · 内容块编号 BLK_<章节缩写>_<序号>，风险块 BLK_<章节缩写>_R<序号>；
--      · 智能体编码 = 经验规则编号 + 章节维度：
--        经验规则类 AGT_RULE_<4位规则序号>_<章节缩写>，文本分析类 AGT_TXT_<章节缩写>_<序号>。
--   ⑦ AI 风险块与 mock 的 22 条风险 1:1（analysisType=RULE），riskName 取自 mock 的 ruleName，
--      风险文案与解读由前置加工在实例层写入。
--
-- 说明：本脚本只插初始数据，不含 DELETE。catalogCode / blockCode 有唯一约束，
--       重复执行会报唯一键冲突，需要重灌时先手工清理两张表。
-- 日期：2026-09-11
-- =====================================================================


-- ============================================================
-- 一、目录表（12 个一级目录）
-- ============================================================
INSERT INTO app_report_catalog (catalogCode, catalogName, catalogLevel, parentCode, sortNo, isEnabled) VALUES
('CAT_01_SUMMARY',    '一、总体概览',                  1, NULL, 1,  1),
('CAT_02_CUSTOMER',   '二、客户基本情况',              1, NULL, 2,  1),
('CAT_03_BUSINESS',   '三、业务基本情况',              1, NULL, 3,  1),
('CAT_04_POSTLOAN',   '四、本次日常定期检查开展情况',  1, NULL, 4,  1),
('CAT_05_FINANCE',    '五、财务指标变化和潜在风险',    1, NULL, 5,  1),
('CAT_06_CREDIT',     '六、征信情况和潜在风险',        1, NULL, 6,  1),
('CAT_07_FUND',       '七、资金用途异常',              1, NULL, 7,  1),
('CAT_08_COMPLIANCE', '八、潜在合规风险关注点',        1, NULL, 8,  1),
('CAT_09_SETTLEMENT', '九、结算情况和潜在风险',        1, NULL, 9,  1),
('CAT_10_LOCAL',      '十、地方征信和潜在风险',        1, NULL, 10, 1),
('CAT_11_JUDICIAL',   '十一、预警信息和潜在风险',      1, NULL, 11, 1),
('CAT_12_GUARANTEE',  '十二、担保情况和潜在风险',      1, NULL, 12, 1);


-- ============================================================
-- 二、报告级内容块（catalogCode = NULL，渲染在正文顶部）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_HEAD_01', NULL, 'TITLE', NULL, NULL, NULL, 1, 'PLACEHOLDER', 10, 1),
('BLK_HEAD_02', NULL, 'TEXT',  NULL, NULL, NULL, NULL, 'PLACEHOLDER', 20, 1),
('BLK_HEAD_03', NULL, 'TEXT',  NULL, NULL, NULL, NULL, 'PLACEHOLDER', 30, 1);


-- ============================================================
-- 三、一、总体概览（CAT_01_SUMMARY）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_SUM_01',         'CAT_01_SUMMARY', 'TITLE',       NULL,       NULL,                 NULL, 2,    'PLACEHOLDER', 10,  1),
('BLK_SUM_02',         'CAT_01_SUMMARY', 'TITLE',       NULL,       NULL,                 NULL, 3,    'PLACEHOLDER', 20,  1),
('BLK_SUM_03',         'CAT_01_SUMMARY', 'TEXT',        'ANALYSIS', 'AGT_TXT_SUM_01',     NULL, NULL, 'PLACEHOLDER', 30,  1),
('BLK_SUM_04',         'CAT_01_SUMMARY', 'TITLE',       NULL,       NULL,                 NULL, 3,    'PLACEHOLDER', 40,  1),
('BLK_SUM_05',         'CAT_01_SUMMARY', 'TEXT',        'ANALYSIS', 'AGT_TXT_SUM_02',     NULL, NULL, 'PLACEHOLDER', 50,  1),
('BLK_SUM_90',         'CAT_01_SUMMARY', 'SOURCE_LINK', NULL,       NULL,                 NULL, NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 四、二、客户基本情况（CAT_02_CUSTOMER）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_CUST_01',        'CAT_02_CUSTOMER', 'TITLE',       NULL,       NULL,                 NULL,                                 2,    'PLACEHOLDER', 10,   1),
('BLK_CUST_02',        'CAT_02_CUSTOMER', 'TEXT',        'ANALYSIS', 'AGT_TXT_CUST_01',    NULL,                                 NULL, 'PLACEHOLDER', 20,   1),
('BLK_CUST_90',        'CAT_02_CUSTOMER', 'SOURCE_LINK', NULL,       NULL,                 NULL,                                 NULL, 'PLACEHOLDER', 900,  1),
('BLK_CUST_R01',       'CAT_02_CUSTOMER', 'TEXT',        'RULE',     'AGT_RULE_0001_CUST', '工商受益人和系统实控人不一致',       NULL, 'PLACEHOLDER', 1000, 1);


-- ============================================================
-- 五、三、业务基本情况（CAT_03_BUSINESS）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_BUS_01',         'CAT_03_BUSINESS', 'TITLE',       NULL,       NULL,                NULL,               2,    'PLACEHOLDER', 10,   1),
('BLK_BUS_02',         'CAT_03_BUSINESS', 'TEXT',        'ANALYSIS', 'AGT_TXT_BUS_01',    NULL,               NULL, 'PLACEHOLDER', 20,   1),
('BLK_BUS_03',         'CAT_03_BUSINESS', 'TABLE',       NULL,       NULL,                NULL,               NULL, 'PLACEHOLDER', 30,   1),
('BLK_BUS_04',         'CAT_03_BUSINESS', 'TEXT',        'ANALYSIS', 'AGT_TXT_BUS_02',    NULL,               NULL, 'PLACEHOLDER', 40,   1),
('BLK_BUS_90',         'CAT_03_BUSINESS', 'SOURCE_LINK', NULL,       NULL,                NULL,               NULL, 'PLACEHOLDER', 900,  1),
('BLK_BUS_R01',        'CAT_03_BUSINESS', 'TEXT',        'RULE',     'AGT_RULE_0002_BUS', '利息/本金逾期',     NULL, 'PLACEHOLDER', 1000, 1);


-- ============================================================
-- 六、四、本次日常定期检查开展情况（CAT_04_POSTLOAN）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_POST_01',        'CAT_04_POSTLOAN', 'TITLE',       NULL,       NULL,              NULL, 2,    'PLACEHOLDER', 10,  1),
('BLK_POST_02',        'CAT_04_POSTLOAN', 'TEXT',        'ANALYSIS', 'AGT_TXT_POST_01', NULL, NULL, 'PLACEHOLDER', 20,  1),
('BLK_POST_90',        'CAT_04_POSTLOAN', 'SOURCE_LINK', NULL,       NULL,              NULL, NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 七、五、财务指标变化和潜在风险（CAT_05_FINANCE，6 条经验规则）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_FIN_01',         'CAT_05_FINANCE', 'TITLE',       NULL,       NULL,                 NULL,                                     2,    'PLACEHOLDER', 10,   1),
('BLK_FIN_02',         'CAT_05_FINANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_FIN_01',     NULL,                                     NULL, 'PLACEHOLDER', 20,   1),
('BLK_FIN_03',         'CAT_05_FINANCE', 'TITLE',       NULL,       NULL,                 NULL,                                     3,    'PLACEHOLDER', 30,   1),
('BLK_FIN_04',         'CAT_05_FINANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_FIN_02',     NULL,                                     NULL, 'PLACEHOLDER', 40,   1),
('BLK_FIN_90',         'CAT_05_FINANCE', 'SOURCE_LINK', NULL,       NULL,                 NULL,                                     NULL, 'PLACEHOLDER', 900,  1),
('BLK_FIN_R01',        'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0003_FIN',  '纳税申报销售额异常',                       NULL, 'PLACEHOLDER', 1000, 1),
('BLK_FIN_R02',        'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0004_FIN',  '净利润过低及净利润快速下降',               NULL, 'PLACEHOLDER', 1001, 1),
('BLK_FIN_R03',        'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0005_FIN',  '费用率高',                                 NULL, 'PLACEHOLDER', 1002, 1),
('BLK_FIN_R04',        'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0006_FIN',  '应收账款与其他应收款占比过高',             NULL, 'PLACEHOLDER', 1003, 1),
('BLK_FIN_R05',        'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0007_FIN',  '资产负债率偏离度高',                       NULL, 'PLACEHOLDER', 1004, 1),
('BLK_FIN_R06',        'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0008_FIN',  '经营现金流下降及营运周转放缓',             NULL, 'PLACEHOLDER', 1005, 1);


-- ============================================================
-- 八、六、征信情况和潜在风险（CAT_06_CREDIT，4 条经验规则）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_CRED_01',        'CAT_06_CREDIT', 'TITLE',       NULL,       NULL,                   NULL,                 2,    'PLACEHOLDER', 10,   1),
('BLK_CRED_02',        'CAT_06_CREDIT', 'TEXT',        'ANALYSIS', 'AGT_TXT_CRED_01',      NULL,                 NULL, 'PLACEHOLDER', 20,   1),
('BLK_CRED_90',        'CAT_06_CREDIT', 'SOURCE_LINK', NULL,       NULL,                   NULL,                 NULL, 'PLACEHOLDER', 900,  1),
('BLK_CRED_R01',       'CAT_06_CREDIT', 'TEXT',        'RULE',     'AGT_RULE_0009_CRED',   '征信异常',           NULL, 'PLACEHOLDER', 1000, 1),
('BLK_CRED_R02',       'CAT_06_CREDIT', 'TEXT',        'RULE',     'AGT_RULE_0010_CRED',   '账外负债识别',       NULL, 'PLACEHOLDER', 1001, 1),
('BLK_CRED_R03',       'CAT_06_CREDIT', 'TEXT',        'RULE',     'AGT_RULE_0011_CRED',   '银租融资过于分散',   NULL, 'PLACEHOLDER', 1002, 1),
('BLK_CRED_R04',       'CAT_06_CREDIT', 'TEXT',        'RULE',     'AGT_RULE_0012_CRED',   '征信查询频率异常',   NULL, 'PLACEHOLDER', 1003, 1);


-- ============================================================
-- 九、七、资金用途异常（CAT_07_FUND，3 条经验规则）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_FUND_01',        'CAT_07_FUND', 'TITLE',       NULL,       NULL,                  NULL,                   2,    'PLACEHOLDER', 10,   1),
('BLK_FUND_02',        'CAT_07_FUND', 'TEXT',        'ANALYSIS', 'AGT_TXT_FUND_01',     NULL,                   NULL, 'PLACEHOLDER', 20,   1),
('BLK_FUND_90',        'CAT_07_FUND', 'SOURCE_LINK', NULL,       NULL,                  NULL,                   NULL, 'PLACEHOLDER', 900,  1),
('BLK_FUND_R01',       'CAT_07_FUND', 'TEXT',        'RULE',     'AGT_RULE_0013_FUND',  '股东借款未归还',       NULL, 'PLACEHOLDER', 1000, 1),
('BLK_FUND_R02',       'CAT_07_FUND', 'TEXT',        'RULE',     'AGT_RULE_0014_FUND',  '疑似资金回流未被认定', NULL, 'PLACEHOLDER', 1001, 1),
('BLK_FUND_R03',       'CAT_07_FUND', 'TEXT',        'RULE',     'AGT_RULE_0015_FUND',  '受托支付异常',         NULL, 'PLACEHOLDER', 1002, 1);


-- ============================================================
-- 十、八、潜在合规风险关注点（CAT_08_COMPLIANCE，4 条经验规则）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_COMP_01',        'CAT_08_COMPLIANCE', 'TITLE',       NULL,       NULL,                   NULL,             2,    'PLACEHOLDER', 10,   1),
('BLK_COMP_02',        'CAT_08_COMPLIANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_COMP_01',      NULL,             NULL, 'PLACEHOLDER', 20,   1),
('BLK_COMP_90',        'CAT_08_COMPLIANCE', 'SOURCE_LINK', NULL,       NULL,                   NULL,             NULL, 'PLACEHOLDER', 900,  1),
('BLK_COMP_R01',       'CAT_08_COMPLIANCE', 'TEXT',        'RULE',     'AGT_RULE_0016_COMP',   '疑似借名贷款',   NULL, 'PLACEHOLDER', 1000, 1),
('BLK_COMP_R02',       'CAT_08_COMPLIANCE', 'TEXT',        'RULE',     'AGT_RULE_0017_COMP',   '疑似担保圈链',   NULL, 'PLACEHOLDER', 1001, 1),
('BLK_COMP_R03',       'CAT_08_COMPLIANCE', 'TEXT',        'RULE',     'AGT_RULE_0018_COMP',   '受托支付多对一', NULL, 'PLACEHOLDER', 1002, 1),
('BLK_COMP_R04',       'CAT_08_COMPLIANCE', 'TEXT',        'RULE',     'AGT_RULE_0019_COMP',   '抵质押物同小区', NULL, 'PLACEHOLDER', 1003, 1);


-- ============================================================
-- 十一、九、结算情况和潜在风险（CAT_09_SETTLEMENT，1 条经验规则）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_SETT_01',        'CAT_09_SETTLEMENT', 'TITLE',       NULL,       NULL,                 NULL,               2,    'PLACEHOLDER', 10,  1),
('BLK_SETT_02',        'CAT_09_SETTLEMENT', 'TITLE',       NULL,       NULL,                 NULL,               3,    'PLACEHOLDER', 20,  1),
('BLK_SETT_03',        'CAT_09_SETTLEMENT', 'TEXT',        'ANALYSIS', 'AGT_TXT_SETT_01',    NULL,               NULL, 'PLACEHOLDER', 30,  1),
('BLK_SETT_04',        'CAT_09_SETTLEMENT', 'TABLE',       NULL,       NULL,                 NULL,               NULL, 'PLACEHOLDER', 40,  1),
('BLK_SETT_05',        'CAT_09_SETTLEMENT', 'TITLE',       NULL,       NULL,                 NULL,               3,    'PLACEHOLDER', 50,  1),
('BLK_SETT_06',        'CAT_09_SETTLEMENT', 'TEXT',        'ANALYSIS', 'AGT_TXT_SETT_02',    NULL,               NULL, 'PLACEHOLDER', 60,  1),
('BLK_SETT_07',        'CAT_09_SETTLEMENT', 'TABLE',       NULL,       NULL,                 NULL,               NULL, 'PLACEHOLDER', 70,  1),
('BLK_SETT_08',        'CAT_09_SETTLEMENT', 'TITLE',       NULL,       NULL,                 NULL,               3,    'PLACEHOLDER', 80,  1),
('BLK_SETT_09',        'CAT_09_SETTLEMENT', 'TABLE',       NULL,       NULL,                 NULL,               NULL, 'PLACEHOLDER', 85,  1),
('BLK_SETT_90',        'CAT_09_SETTLEMENT', 'SOURCE_LINK', NULL,       NULL,                 NULL,               NULL, 'PLACEHOLDER', 900, 1),
('BLK_SETT_R01',       'CAT_09_SETTLEMENT', 'TEXT',        'RULE',     'AGT_RULE_0020_SETT', '结算与经营不匹配', NULL, 'PLACEHOLDER', 1000, 1);


-- ============================================================
-- 十二、十、地方征信和潜在风险（CAT_10_LOCAL）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_LOCAL_01',       'CAT_10_LOCAL', 'TITLE',       NULL,       NULL,               NULL, 2,    'PLACEHOLDER', 10,  1),
('BLK_LOCAL_02',       'CAT_10_LOCAL', 'TEXT',        'ANALYSIS', 'AGT_TXT_LOCAL_01', NULL, NULL, 'PLACEHOLDER', 20,  1),
('BLK_LOCAL_90',       'CAT_10_LOCAL', 'SOURCE_LINK', NULL,       NULL,               NULL, NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 十三、十一、预警信息和潜在风险（CAT_11_JUDICIAL）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_JUD_01',         'CAT_11_JUDICIAL', 'TITLE',       NULL,       NULL,               NULL, 2,    'PLACEHOLDER', 10,  1),
('BLK_JUD_02',         'CAT_11_JUDICIAL', 'TITLE',       NULL,       NULL,               NULL, 3,    'PLACEHOLDER', 20,  1),
('BLK_JUD_03',         'CAT_11_JUDICIAL', 'TEXT',        'ANALYSIS', 'AGT_TXT_JUD_01',   NULL, NULL, 'PLACEHOLDER', 30,  1),
('BLK_JUD_04',         'CAT_11_JUDICIAL', 'TITLE',       NULL,       NULL,               NULL, 3,    'PLACEHOLDER', 40,  1),
('BLK_JUD_05',         'CAT_11_JUDICIAL', 'TEXT',        'ANALYSIS', 'AGT_TXT_JUD_02',   NULL, NULL, 'PLACEHOLDER', 50,  1),
('BLK_JUD_06',         'CAT_11_JUDICIAL', 'TABLE',       NULL,       NULL,               NULL, NULL, 'PLACEHOLDER', 60,  1),
('BLK_JUD_90',         'CAT_11_JUDICIAL', 'SOURCE_LINK', NULL,       NULL,               NULL, NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 十四、十二、担保情况和潜在风险（CAT_12_GUARANTEE，2 条经验规则）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, ruleName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_GUAR_01',        'CAT_12_GUARANTEE', 'TITLE',       NULL,       NULL,                  NULL,       2,    'PLACEHOLDER', 10,   1),
('BLK_GUAR_02',        'CAT_12_GUARANTEE', 'TITLE',       NULL,       NULL,                  NULL,       3,    'PLACEHOLDER', 20,   1),
('BLK_GUAR_03',        'CAT_12_GUARANTEE', 'TEXT',        'ANALYSIS', 'AGT_TXT_GUAR_01',     NULL,       NULL, 'PLACEHOLDER', 30,   1),
('BLK_GUAR_04',        'CAT_12_GUARANTEE', 'TITLE',       NULL,       NULL,                  NULL,       3,    'PLACEHOLDER', 40,   1),
('BLK_GUAR_05',        'CAT_12_GUARANTEE', 'TEXT',        'ANALYSIS', 'AGT_TXT_GUAR_02',     NULL,       NULL, 'PLACEHOLDER', 50,   1),
('BLK_GUAR_90',        'CAT_12_GUARANTEE', 'SOURCE_LINK', NULL,       NULL,                  NULL,       NULL, 'PLACEHOLDER', 900,  1),
('BLK_GUAR_R01',       'CAT_12_GUARANTEE', 'TEXT',        'RULE',     'AGT_RULE_0021_GUAR',  '抵押物多次抵押',   NULL, 'PLACEHOLDER', 1000, 1),
('BLK_GUAR_R02',       'CAT_12_GUARANTEE', 'TEXT',        'RULE',     'AGT_RULE_0022_GUAR',  '担保人债务异常',   NULL, 'PLACEHOLDER', 1001, 1);
