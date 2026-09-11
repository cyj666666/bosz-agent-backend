-- =====================================================================
-- 报告详情页 · 模板层初始数据（DML）
-- 数据库：高斯DB（GaussDB）
-- 依据  ：前端报告详情页 mock 数据（src/hooks/useReportApi.ts，V5.2 移植版）
-- 内容  ：app_report_catalog（12 个一级目录）+ app_report_content_block（94 个内容块）
--
-- 结构映射约定：
--   ① 目录：mock 页左侧目录为 12 个章节，故建 12 个一级目录（catalogLevel=1，parentCode=NULL）。
--      二级/三级目录能力已在表结构中支持，后续有子目录需求时追加数据即可。
--   ② 报告头：不属于任何目录，用 catalogCode=NULL 的报告级内容块承载
--      （1 个主标题块 + 1 个副标题块 + 1 个说明块）。
--   ③ 块顺序严格还原 demo 正文的实际顺序：AI 风险块（经验规则类）就排在它对应的
--      "风险提示：xxx，提请关注"段落在正文中的原位，不是统一堆到章节末尾。
--      例外：mock 正文中没有对应风险段的风险（如"费用率高""征信查询频率异常"），
--      按风险列表顺序插在相邻风险块之间；图谱识别的 4 条风险在 mock 中由一段文字并列提及，
--      故正文段之后依次排列 4 个风险块。
--   ④ sortNo：按文档顺序 10、20、30…递增；溯源按钮固定 900。
--   ⑤ emptyStrategy：全部统一为 PLACEHOLDER（保留结构、实例内容为空时显示暂无数据占位）。
--   ⑥ 编码规则：
--      · 内容块编号 BLK_<章节缩写>_<序号>（按文档顺序编号），风险块 BLK_<章节缩写>_R<序号>；
--      · 智能体编码 = 经验规则编号 + 章节维度：
--        经验规则类 AGT_RULE_<4位规则序号>_<章节缩写>，文本分析类 AGT_TXT_<章节缩写>_<序号>。
--   ⑦ blockName 内容块名称：**每个块都必须有值**（必填）。
--      analysisType=RULE 时即规则名称（与 mock 的 ruleName 一致，22 条风险 1:1）；
--      其余类型为块的展示名称（标题名/正文主题/表格名/溯源按钮名）。
--   ⑧ AI 风险块与 mock 的 22 条风险 1:1（analysisType=RULE），风险文案与解读由前置加工在实例层写入。
--
-- 说明：本脚本只插初始数据，不含 DELETE。catalogCode / blockCode 有唯一约束，
--       重复执行会报唯一键冲突，需要重灌时先手工清理两张表。
-- 块间锚点（已按此原则拆分）：demo 中一个块内出现多个内部跳转链接时，必须拆成多个内容块，
--       因为一个块只有 1 个 jumpAnchorCode。已拆：总体概览"（一）风险要点"→ BLK_SUM_04/05/06
--       三个文本块，分别对应"一是净利润异常""二是报表真实性""三是抵押物多次抵押"。
--       跳转目标在模板层配置（jumpAnchorCode 列），生成时快照到实例层；见文件末尾的 UPDATE。
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
--    注：两个文本块不调智能体（agentCode 留空），由前置加工直接写入固定文案。
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_HEAD_01', NULL, 'TITLE', NULL, NULL, '报告主标题', 1,    'PLACEHOLDER', 10, 1),
('BLK_HEAD_02', NULL, 'TEXT',  NULL, NULL, '报告副标题', NULL, 'PLACEHOLDER', 20, 1),
('BLK_HEAD_03', NULL, 'TEXT',  NULL, NULL, '报告说明',   NULL, 'PLACEHOLDER', 30, 1);


-- ============================================================
-- 三、一、总体概览（CAT_01_SUMMARY）
--    正文顺序：（一）风险要点 → （二）检查重点；本章节无经验规则类风险。
--    块间锚点拆分：demo 中"（一）风险要点"是一个列表，其中"一是净利润异常""二是报表真实性"
--    "三是抵押物多次抵押"三项带内部跳转链接（href="#finance"、href="#guarantee"）。
--    因一个内容块只有 1 个 jumpAnchorCode，此处已拆为 3 个独立文本块（BLK_SUM_04/05/06），
--    跳转目标在模板层配置（见文件末尾 UPDATE）：BLK_SUM_04→BLK_FIN_R02 净利润风险、
--    BLK_SUM_05→BLK_FIN_10 报表真实性段、BLK_SUM_06→BLK_GUAR_R01 抵押物风险）。
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_SUM_01', 'CAT_01_SUMMARY', 'TITLE', NULL,       NULL,             '一、总体概览',       2,    'PLACEHOLDER', 10,  1),
('BLK_SUM_02', 'CAT_01_SUMMARY', 'TITLE', NULL,       NULL,             '（一）风险要点',     3,    'PLACEHOLDER', 20,  1),
('BLK_SUM_03', 'CAT_01_SUMMARY', 'TEXT',  'ANALYSIS', 'AGT_TXT_SUM_01', '风险要点引言',       NULL, 'PLACEHOLDER', 30,  1),
('BLK_SUM_04', 'CAT_01_SUMMARY', 'TEXT',  'ANALYSIS', 'AGT_TXT_SUM_02', '一是净利润异常',     NULL, 'PLACEHOLDER', 40,  1),
('BLK_SUM_05', 'CAT_01_SUMMARY', 'TEXT',  'ANALYSIS', 'AGT_TXT_SUM_03', '二是报表真实性',     NULL, 'PLACEHOLDER', 50,  1),
('BLK_SUM_06', 'CAT_01_SUMMARY', 'TEXT',  'ANALYSIS', 'AGT_TXT_SUM_04', '三是抵押物多次抵押', NULL, 'PLACEHOLDER', 60,  1),
('BLK_SUM_07', 'CAT_01_SUMMARY', 'TEXT',  'ANALYSIS', 'AGT_TXT_SUM_05', '风险要点小结',       NULL, 'PLACEHOLDER', 70,  1),
('BLK_SUM_08', 'CAT_01_SUMMARY', 'TITLE', NULL,       NULL,             '（二）检查重点',     3,    'PLACEHOLDER', 80,  1),
('BLK_SUM_09', 'CAT_01_SUMMARY', 'TEXT',  'ANALYSIS', 'AGT_TXT_SUM_06', '检查重点',           NULL, 'PLACEHOLDER', 90,  1),
('BLK_SUM_90', 'CAT_01_SUMMARY', 'SOURCE_LINK', NULL, NULL, '查看溯源信息', NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 四、二、客户基本情况（CAT_02_CUSTOMER）
--    正文顺序：工商概况正文 → 风险提示（工商受益人和系统实控人不一致）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_CUST_01',  'CAT_02_CUSTOMER', 'TITLE',       NULL,       NULL,                 '二、客户基本情况',               2,    'PLACEHOLDER', 10,  1),
('BLK_CUST_02',  'CAT_02_CUSTOMER', 'TEXT',        'ANALYSIS', 'AGT_TXT_CUST_01',    '工商概况与股权结构',             NULL, 'PLACEHOLDER', 20,  1),
('BLK_CUST_R01', 'CAT_02_CUSTOMER', 'TEXT',        'RULE',     'AGT_RULE_0001_CUST', '工商受益人和系统实控人不一致',   NULL, 'PLACEHOLDER', 30,  1),
('BLK_CUST_90',  'CAT_02_CUSTOMER', 'SOURCE_LINK', NULL,       NULL,                 '查看溯源信息',                   NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 五、三、业务基本情况（CAT_03_BUSINESS）
--    正文顺序：授信情况正文 → 表格 → 风险段（期供欠本/欠息，即利息/本金逾期）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_BUS_01',  'CAT_03_BUSINESS', 'TITLE',       NULL,       NULL,                '三、业务基本情况',                            2,    'PLACEHOLDER', 10,  1),
('BLK_BUS_02',  'CAT_03_BUSINESS', 'TEXT',        'ANALYSIS', 'AGT_TXT_BUS_01',    '授信与用信情况',                               NULL, 'PLACEHOLDER', 20,  1),
('BLK_BUS_03',  'CAT_03_BUSINESS', 'TABLE',       NULL,       NULL,                '固定资产贷款、房地产开发贷款用途展示',        NULL, 'PLACEHOLDER', 30,  1),
('BLK_BUS_R01', 'CAT_03_BUSINESS', 'TEXT',        'RULE',     'AGT_RULE_0002_BUS', '利息/本金逾期',                                NULL, 'PLACEHOLDER', 40,  1),
('BLK_BUS_90',  'CAT_03_BUSINESS', 'SOURCE_LINK', NULL,       NULL,                '查看溯源信息',                                 NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 六、四、本次日常定期检查开展情况（CAT_04_POSTLOAN）
--    本章节无经验规则类风险。
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_POST_01', 'CAT_04_POSTLOAN', 'TITLE',       NULL,       NULL,              '四、本次日常定期检查开展情况', 2,    'PLACEHOLDER', 10,  1),
('BLK_POST_02', 'CAT_04_POSTLOAN', 'TEXT',        'ANALYSIS', 'AGT_TXT_POST_01', '本次检查开展情况',             NULL, 'PLACEHOLDER', 20,  1),
('BLK_POST_90', 'CAT_04_POSTLOAN', 'SOURCE_LINK', NULL,       NULL,              '查看溯源信息',                 NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 七、五、财务指标变化和潜在风险（CAT_05_FINANCE，6 条经验规则）
--    正文顺序严格按 demo：营收 → 风险(纳税申报) → 净利润 → 风险(净利润异常) → 利润率/实收资本
--    → 风险(费用率高，demo 正文无对应段，按列表顺序插入) → 应收款 → 风险(应收占比)
--    → 资产负债率 → 风险(负债率偏离) → 重要负债科目/其他风险 → 风险(经营现金流)
--    → 报表真实性段（demo 中有此正文，但无对应风险条目）
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_FIN_01',  'CAT_05_FINANCE', 'TITLE',       NULL,       NULL,                '五、财务指标变化和潜在风险',       2,    'PLACEHOLDER', 10,  1),
('BLK_FIN_02',  'CAT_05_FINANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_FIN_01',    '报表期数与审计情况',               NULL, 'PLACEHOLDER', 20,  1),
('BLK_FIN_03',  'CAT_05_FINANCE', 'TITLE',       NULL,       NULL,                '（四）重点财务指标分析',           3,    'PLACEHOLDER', 30,  1),
('BLK_FIN_04',  'CAT_05_FINANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_FIN_02',    '营业收入',                         NULL, 'PLACEHOLDER', 40,  1),
('BLK_FIN_R01', 'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0003_FIN', '纳税申报销售额异常',               NULL, 'PLACEHOLDER', 50,  1),
('BLK_FIN_05',  'CAT_05_FINANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_FIN_03',    '净利润',                           NULL, 'PLACEHOLDER', 60,  1),
('BLK_FIN_R02', 'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0004_FIN', '净利润过低及净利润快速下降',       NULL, 'PLACEHOLDER', 70,  1),
('BLK_FIN_06',  'CAT_05_FINANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_FIN_04',    '销售利率与净利率、实收资本',       NULL, 'PLACEHOLDER', 80,  1),
('BLK_FIN_R03', 'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0005_FIN', '费用率高',                         NULL, 'PLACEHOLDER', 90,  1),
('BLK_FIN_07',  'CAT_05_FINANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_FIN_05',    '应收账款和其他应收款',             NULL, 'PLACEHOLDER', 100, 1),
('BLK_FIN_R04', 'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0006_FIN', '应收账款与其他应收款占比过高',     NULL, 'PLACEHOLDER', 110, 1),
('BLK_FIN_08',  'CAT_05_FINANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_FIN_06',    '资产负债率',                       NULL, 'PLACEHOLDER', 120, 1),
('BLK_FIN_R05', 'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0007_FIN', '资产负债率偏离度高',               NULL, 'PLACEHOLDER', 130, 1),
('BLK_FIN_09',  'CAT_05_FINANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_FIN_07',    '重要负债科目与其他风险',           NULL, 'PLACEHOLDER', 140, 1),
('BLK_FIN_R06', 'CAT_05_FINANCE', 'TEXT',        'RULE',     'AGT_RULE_0008_FIN', '经营现金流下降及营运周转放缓',     NULL, 'PLACEHOLDER', 150, 1),
('BLK_FIN_10',  'CAT_05_FINANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_FIN_08',    '报表真实性',                       NULL, 'PLACEHOLDER', 160, 1),
('BLK_FIN_90',  'CAT_05_FINANCE', 'SOURCE_LINK', NULL,       NULL,                '查看溯源信息',                     NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 八、六、征信情况和潜在风险（CAT_06_CREDIT，4 条经验规则）
--    正文顺序：最新查询/征信情况 → 风险(征信异常) → 债务情况 → 风险(债务异常=账外负债识别)
--    → 风险(银租融资过于分散，对应 demo 其他风险段) → 风险(征信查询频率异常，正文无对应段)
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_CRED_01',  'CAT_06_CREDIT', 'TITLE',       NULL,       NULL,                 '六、征信情况和潜在风险',   2,    'PLACEHOLDER', 10,  1),
('BLK_CRED_02',  'CAT_06_CREDIT', 'TEXT',        'ANALYSIS', 'AGT_TXT_CRED_01',    '征信查询与征信情况',       NULL, 'PLACEHOLDER', 20,  1),
('BLK_CRED_R01', 'CAT_06_CREDIT', 'TEXT',        'RULE',     'AGT_RULE_0009_CRED', '征信异常',                 NULL, 'PLACEHOLDER', 30,  1),
('BLK_CRED_03',  'CAT_06_CREDIT', 'TEXT',        'ANALYSIS', 'AGT_TXT_CRED_02',    '债务情况',                 NULL, 'PLACEHOLDER', 40,  1),
('BLK_CRED_R02', 'CAT_06_CREDIT', 'TEXT',        'RULE',     'AGT_RULE_0010_CRED', '账外负债识别',             NULL, 'PLACEHOLDER', 50,  1),
('BLK_CRED_R03', 'CAT_06_CREDIT', 'TEXT',        'RULE',     'AGT_RULE_0011_CRED', '银租融资过于分散',         NULL, 'PLACEHOLDER', 60,  1),
('BLK_CRED_R04', 'CAT_06_CREDIT', 'TEXT',        'RULE',     'AGT_RULE_0012_CRED', '征信查询频率异常',         NULL, 'PLACEHOLDER', 70,  1),
('BLK_CRED_90',  'CAT_06_CREDIT', 'SOURCE_LINK', NULL,       NULL,                 '查看溯源信息',             NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 九、七、资金用途异常（CAT_07_FUND，3 条经验规则）
--    正文顺序：资金回流命中情况 → 风险(疑似资金回流未被认定) → 资金用途异常/其他风险
--    → 风险(股东借款未归还) → 风险(受托支付异常)
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_FUND_01',  'CAT_07_FUND', 'TITLE',       NULL,       NULL,                  '七、资金用途异常',       2,    'PLACEHOLDER', 10,  1),
('BLK_FUND_02',  'CAT_07_FUND', 'TEXT',        'ANALYSIS', 'AGT_TXT_FUND_01',     '资金回流命中情况',        NULL, 'PLACEHOLDER', 20,  1),
('BLK_FUND_R01', 'CAT_07_FUND', 'TEXT',        'RULE',     'AGT_RULE_0014_FUND',  '疑似资金回流未被认定',    NULL, 'PLACEHOLDER', 30,  1),
('BLK_FUND_03',  'CAT_07_FUND', 'TEXT',        'ANALYSIS', 'AGT_TXT_FUND_02',     '资金用途异常与其他风险',  NULL, 'PLACEHOLDER', 40,  1),
('BLK_FUND_R02', 'CAT_07_FUND', 'TEXT',        'RULE',     'AGT_RULE_0013_FUND',  '股东借款未归还',          NULL, 'PLACEHOLDER', 50,  1),
('BLK_FUND_R03', 'CAT_07_FUND', 'TEXT',        'RULE',     'AGT_RULE_0015_FUND',  '受托支付异常',            NULL, 'PLACEHOLDER', 60,  1),
('BLK_FUND_90',  'CAT_07_FUND', 'SOURCE_LINK', NULL,       NULL,                  '查看溯源信息',            NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 十、八、潜在合规风险关注点（CAT_08_COMPLIANCE，4 条经验规则）
--    demo 中图谱识别的 4 个风险标签由一段文字并列提及，故正文段之后依次排列 4 个风险块。
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_COMP_01',  'CAT_08_COMPLIANCE', 'TITLE',       NULL,       NULL,                 '八、潜在合规风险关注点',  2,    'PLACEHOLDER', 10,  1),
('BLK_COMP_02',  'CAT_08_COMPLIANCE', 'TEXT',        'ANALYSIS', 'AGT_TXT_COMP_01',    '图谱系统风险标签',        NULL, 'PLACEHOLDER', 20,  1),
('BLK_COMP_R01', 'CAT_08_COMPLIANCE', 'TEXT',        'RULE',     'AGT_RULE_0016_COMP', '疑似借名贷款',            NULL, 'PLACEHOLDER', 30,  1),
('BLK_COMP_R02', 'CAT_08_COMPLIANCE', 'TEXT',        'RULE',     'AGT_RULE_0017_COMP', '疑似担保圈链',            NULL, 'PLACEHOLDER', 40,  1),
('BLK_COMP_R03', 'CAT_08_COMPLIANCE', 'TEXT',        'RULE',     'AGT_RULE_0018_COMP', '受托支付多对一',          NULL, 'PLACEHOLDER', 50,  1),
('BLK_COMP_R04', 'CAT_08_COMPLIANCE', 'TEXT',        'RULE',     'AGT_RULE_0019_COMP', '抵质押物同小区',          NULL, 'PLACEHOLDER', 60,  1),
('BLK_COMP_90',  'CAT_08_COMPLIANCE', 'SOURCE_LINK', NULL,       NULL,                 '查看溯源信息',            NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 十一、九、结算情况和潜在风险（CAT_09_SETTLEMENT，1 条经验规则）
--    注意：风险块在章节中段——demo 里"风险提示：结算与经营不匹配"位于（二）交易对手之后、
--    （三）代发业务之前，故 sortNo 排在 80，而不是章节末尾。
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_SETT_01',  'CAT_09_SETTLEMENT', 'TITLE',       NULL,       NULL,                 '九、结算情况和潜在风险',      2,    'PLACEHOLDER', 10,  1),
('BLK_SETT_02',  'CAT_09_SETTLEMENT', 'TITLE',       NULL,       NULL,                 '（一）我行结算账户与资产情况', 3,    'PLACEHOLDER', 20,  1),
('BLK_SETT_03',  'CAT_09_SETTLEMENT', 'TEXT',        'ANALYSIS', 'AGT_TXT_SETT_01',    '结算账户与日均存款',          NULL, 'PLACEHOLDER', 30,  1),
('BLK_SETT_04',  'CAT_09_SETTLEMENT', 'TABLE',       NULL,       NULL,                 '日均存款',                    NULL, 'PLACEHOLDER', 40,  1),
('BLK_SETT_05',  'CAT_09_SETTLEMENT', 'TITLE',       NULL,       NULL,                 '（二）我行结算交易对手情况', 3,    'PLACEHOLDER', 50,  1),
('BLK_SETT_06',  'CAT_09_SETTLEMENT', 'TEXT',        'ANALYSIS', 'AGT_TXT_SETT_02',    '结算交易对手',                NULL, 'PLACEHOLDER', 60,  1),
('BLK_SETT_07',  'CAT_09_SETTLEMENT', 'TABLE',       NULL,       NULL,                 '结算交易对手明细',            NULL, 'PLACEHOLDER', 70,  1),
('BLK_SETT_R01', 'CAT_09_SETTLEMENT', 'TEXT',        'RULE',     'AGT_RULE_0020_SETT', '结算与经营不匹配',            NULL, 'PLACEHOLDER', 80,  1),
('BLK_SETT_08',  'CAT_09_SETTLEMENT', 'TITLE',       NULL,       NULL,                 '（三）我行代发业务情况',     3,    'PLACEHOLDER', 90,  1),
('BLK_SETT_09',  'CAT_09_SETTLEMENT', 'TABLE',       NULL,       NULL,                 '代发人数与代发金额',          NULL, 'PLACEHOLDER', 100, 1),
('BLK_SETT_90',  'CAT_09_SETTLEMENT', 'SOURCE_LINK', NULL,       NULL,                 '查看溯源信息',                NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 十二、十、地方征信和潜在风险（CAT_10_LOCAL）
--    本章节无经验规则类风险。
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_LOCAL_01', 'CAT_10_LOCAL', 'TITLE',       NULL,       NULL,               '十、地方征信和潜在风险', 2,    'PLACEHOLDER', 10,  1),
('BLK_LOCAL_02', 'CAT_10_LOCAL', 'TEXT',        'ANALYSIS', 'AGT_TXT_LOCAL_01', '地方征信查询',           NULL, 'PLACEHOLDER', 20,  1),
('BLK_LOCAL_90', 'CAT_10_LOCAL', 'SOURCE_LINK', NULL,       NULL,               '查看溯源信息',           NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 十三、十一、预警信息和潜在风险（CAT_11_JUDICIAL）
--    本章节无经验规则类风险。
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_JUD_01', 'CAT_11_JUDICIAL', 'TITLE',       NULL,       NULL,               '十一、预警信息和潜在风险',       2,    'PLACEHOLDER', 10,  1),
('BLK_JUD_02', 'CAT_11_JUDICIAL', 'TITLE',       NULL,       NULL,               '（一）预警任务及预警信号情况',   3,    'PLACEHOLDER', 20,  1),
('BLK_JUD_03', 'CAT_11_JUDICIAL', 'TEXT',        'ANALYSIS', 'AGT_TXT_JUD_01',   '预警任务及预警信号',             NULL, 'PLACEHOLDER', 30,  1),
('BLK_JUD_04', 'CAT_11_JUDICIAL', 'TITLE',       NULL,       NULL,               '（二）风险归因模型分析',         3,    'PLACEHOLDER', 40,  1),
('BLK_JUD_05', 'CAT_11_JUDICIAL', 'TEXT',        'ANALYSIS', 'AGT_TXT_JUD_02',   '风险归因模型分析',               NULL, 'PLACEHOLDER', 50,  1),
('BLK_JUD_06', 'CAT_11_JUDICIAL', 'TABLE',       NULL,       NULL,               '归因标签变动明细',               NULL, 'PLACEHOLDER', 60,  1),
('BLK_JUD_90', 'CAT_11_JUDICIAL', 'SOURCE_LINK', NULL,       NULL,               '查看溯源信息',                   NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 十四、十二、担保情况和潜在风险（CAT_12_GUARANTEE，2 条经验规则）
--    正文顺序：（一）抵押物情况 → 风险(抵押物多次抵押) →（二）保证人情况/徐某某征信
--    → 风险(担保人债务异常) → 徐某某债务情况与贾平征信
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, blockName, titleLevel, emptyStrategy, sortNo, isEnabled) VALUES
('BLK_GUAR_01',  'CAT_12_GUARANTEE', 'TITLE',       NULL,       NULL,                  '十二、担保情况和潜在风险',  2,    'PLACEHOLDER', 10,  1),
('BLK_GUAR_02',  'CAT_12_GUARANTEE', 'TITLE',       NULL,       NULL,                  '（一）抵押物情况',          3,    'PLACEHOLDER', 20,  1),
('BLK_GUAR_03',  'CAT_12_GUARANTEE', 'TEXT',        'ANALYSIS', 'AGT_TXT_GUAR_01',     '抵押物情况',                 NULL, 'PLACEHOLDER', 30,  1),
('BLK_GUAR_R01', 'CAT_12_GUARANTEE', 'TEXT',        'RULE',     'AGT_RULE_0021_GUAR',  '抵押物多次抵押',             NULL, 'PLACEHOLDER', 40,  1),
('BLK_GUAR_04',  'CAT_12_GUARANTEE', 'TITLE',       NULL,       NULL,                  '（二）保证人情况',          3,    'PLACEHOLDER', 50,  1),
('BLK_GUAR_05',  'CAT_12_GUARANTEE', 'TEXT',        'ANALYSIS', 'AGT_TXT_GUAR_02',     '保证人征信情况',             NULL, 'PLACEHOLDER', 60,  1),
('BLK_GUAR_R02', 'CAT_12_GUARANTEE', 'TEXT',        'RULE',     'AGT_RULE_0022_GUAR',  '担保人债务异常',             NULL, 'PLACEHOLDER', 70,  1),
('BLK_GUAR_06',  'CAT_12_GUARANTEE', 'TEXT',        'ANALYSIS', 'AGT_TXT_GUAR_03',     '保证人债务情况',             NULL, 'PLACEHOLDER', 80,  1),
('BLK_GUAR_90',  'CAT_12_GUARANTEE', 'SOURCE_LINK', NULL,       NULL,                  '查看溯源信息',               NULL, 'PLACEHOLDER', 900, 1);


-- ============================================================
-- 十五、块间跳转锚点（模板层配置，生成时快照到实例层）
--    jumpAnchorCode 的值 = 目标块的 anchorCode（即目标块 blockCode）。
--    单向：点击本块 → 前端滚动定位到目标块（同页面定位，不新开页面）。
--    跳转关系属报告结构、配在模板层；前置加工只负责内容，不涉及跳转。
-- ============================================================
UPDATE app_report_content_block SET jumpAnchorCode = 'BLK_FIN_R02'  WHERE blockCode = 'BLK_SUM_04';
UPDATE app_report_content_block SET jumpAnchorCode = 'BLK_FIN_10'   WHERE blockCode = 'BLK_SUM_05';
UPDATE app_report_content_block SET jumpAnchorCode = 'BLK_GUAR_R01' WHERE blockCode = 'BLK_SUM_06';
