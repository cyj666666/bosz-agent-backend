-- =====================================================================
-- 报告模板数据（DML）· 依据《报告详情设计.xlsx》Sheet3 生成
-- ⚠️ 本文件由脚本生成（_tools/gen_report_template.py），改 Excel 后重新生成，不要手工改。
-- 数据库：高斯DB（GaussDB/openGauss）
-- 前置：先执行 补列_内容块_agentParams.sql（本模板用到了新列 agentParams）
--
-- 口径（按 H 列「位置」分流）：
--   H=正文   → 知识库   fillType = TEXT（content 存文本，有表格就以 md 形式存）              analysisType = ANALYSIS
--   H=经验库 → 智策引擎 fillType 默认 TEXT（内容带 md 表格也无所谓，都是文本）      analysisType = RULE
--   H=溯源   → 表格溯源 fillType = TABLE   analysisType = TRACE_TABLE（E=表名 F=表中文名 G=条件；查表→拼 md，不做担保人轮询）
--            → 链接溯源 fillType = TEXT   analysisType = TRACE_LINK（content 存"链接开头"，本版留空+HIDE）
--   外部灌入 → fillType = TEXT   analysisType = EXTERNAL（暂未接入，后续接口直接落 content）
--   A/B/C 列章节 → **完整三级目录树**（catalogLevel 1/2/3），标题由 catalogName 渲染
--   E 列 → agentCode；G 列 → agentParams；F 列 → blockName
--   🔴 表格溯源块的 blockName 取**「溯源表展示中文名」**（Sheet3 第 4 列，2026-09-18 用户口径）：
--      报告里溯源的中文名显示的就是 blockName（前端溯源按钮文案 + 弹窗标题都取它），
--      要的是配置里这条展示名，**不是**数据库表结构的中文注释口径（F 列那种）。
--      新列为空时回落 F → E；F 列不再进库，只留在 Excel 作设计参考。
--   🔴 轮询只发生在 经验库/正文（G 列带 guarantorName 的知识库/规则块）；溯源严格按条件查
--   🔴 guarantorName 三种口径（2026-09-18）—— 用元令牌 `guarantorMode=` 表达，provider 读走后不透传给 agent：
--        OWN     = 借款人本人（guarantorName 就是 entName），**不轮询**
--        LEGAL   = 企业担保人（app_guarantor_info: subjectType=担保人 + guarantorType=法人），**轮询**
--        NATURAL = 自然人担保人（guarantorType=自然人），**轮询**
--      轮询 = 每个担保人产出一整块（前端按 .rpt-guarantor 分块渲染）；
--      `guarantorEmph=1` 标记「担保人信息」块，前端加强调样式（多个担保人更醒目）
--   一、（一）风险要点 → 1 个总结块 + N 个要点条目块，条目块 jumpAnchorCode 指回对应 RULE 块
--
-- code 字母：A=知识库分析 R=经验规则 E=要点条目 T=表格溯源 L=链接溯源 X=外部灌入
-- 🔴 全部 code 加 V2_ 前缀：旧模板行是「置 isEnabled=0 保留」而非删除，
--    不加前缀会与旧行撞唯一键（CAT_01_SUMMARY / BLK_HEAD_01 两边同名）。
--
-- 执行顺序：① 幂等清理 V2_ 行 → ② 停用旧模板 → ③ 插目录 → ④ 插内容块 → ⑤ 校验
--
-- 🔴 溯源块「尾块归位」：溯源行按该行的**最小章节**定位，并排在它之后。
--    但前端渲染目录树是「先本节点的块、再子节点」⇒ 留在章节级会显示在章节标题下、各小节之前。
--    故生成时把它下移到「最小章节的**最后一个后代目录**」——渲染出来即"该章节之后"。
--    （另一种做法是前端识别 sortNo>=9000 的尾块延后渲染，要改两个前端工程，未采用。）
--
-- 🔴 溯源块名字统一以「溯源」结尾（表格溯源 = 展示名 +「溯源」；链接溯源的兜底名
--    「溯源信息」本就含「溯源」故不重复加）—— 免得和正文块重名（如正文「担保人信息」）。
-- 🔴 溯源按担保人段分流：企业的溯源挂在**企业段最后一个 L3**、个人的挂在**个人段最后一个 L3**。
-- =====================================================================

-- ============================================================
-- ① 幂等清理：删掉上一轮导入的 V2_ 行，随后重新插入。
--    改 Excel → 重跑生成器 → 重导本文件即可，**不用手工清库**。
--    ⚠️ 用 substr(code, 1, 3) 精确判前缀，**不用 LIKE** —— `_` 在 LIKE 里是单字符通配符。
--    实例层（app_report_content_instance / app_report_ai_risk）存的是**快照 code**、
--    无物理外键指向模板表 ⇒ 删除并重建模板**不影响历史报告**。
-- ============================================================
DELETE FROM app_report_content_block WHERE substr(blockCode,   1, 3) = 'V2_';
DELETE FROM app_report_catalog       WHERE substr(catalogCode, 1, 3) = 'V2_';

-- ============================================================
-- ② 停用旧模板（demo 派生那套）：**保留数据**，便于回退 —— 把 isEnabled 改回 1 即可复活。
--    用 NOT LIKE 'V2_%' 前缀匹配（新模板 code 一律以 V2_ 开头）。
-- ============================================================
UPDATE app_report_catalog       SET isEnabled = 0 WHERE catalogCode NOT LIKE 'V2_%';
UPDATE app_report_content_block SET isEnabled = 0 WHERE blockCode  NOT LIKE 'V2_%';

-- ============================================================
-- ③ 目录表：56 行（一级 12 / 二级 25 / 三级 19）
-- ============================================================
INSERT INTO app_report_catalog (catalogCode, catalogName, catalogLevel, parentCode, sortNo, isEnabled) VALUES
('V2_CAT_01_SUMMARY', '一、总结概述', 1, NULL, 10, 1),
('V2_CAT_01_SUMMARY_01', '（一）风险要点', 2, 'V2_CAT_01_SUMMARY', 10, 1),
('V2_CAT_01_SUMMARY_02', '（二）检查重点', 2, 'V2_CAT_01_SUMMARY', 20, 1),
('V2_CAT_02_CUSTOMER', '二、客户基本情况', 1, NULL, 20, 1),
('V2_CAT_03_BUSINESS', '三、业务基本情况', 1, NULL, 30, 1),
('V2_CAT_04_POSTLOAN', '四、本次日常定期检查开展情况', 1, NULL, 40, 1),
('V2_CAT_04_POSTLOAN_01', '（一)现场打卡情况', 2, 'V2_CAT_04_POSTLOAN', 10, 1),
('V2_CAT_04_POSTLOAN_02', '（二)批复后续管理要求落实情况', 2, 'V2_CAT_04_POSTLOAN', 20, 1),
('V2_CAT_04_POSTLOAN_03', '（三)单此检查任务落实情况', 2, 'V2_CAT_04_POSTLOAN', 30, 1),
('V2_CAT_04_POSTLOAN_04', '（四）日常贷后检查报告揭示风险', 2, 'V2_CAT_04_POSTLOAN', 40, 1),
('V2_CAT_04_POSTLOAN_05', '（五）特定贷款的检查情况', 2, 'V2_CAT_04_POSTLOAN', 50, 1),
('V2_CAT_05_FINANCE', '五、财务指标变化和潜在风险', 1, NULL, 50, 1),
('V2_CAT_05_FINANCE_01', '（一)最新报表期数', 2, 'V2_CAT_05_FINANCE', 10, 1),
('V2_CAT_05_FINANCE_02', '（二）报表审计情况', 2, 'V2_CAT_05_FINANCE', 20, 1),
('V2_CAT_05_FINANCE_03', '（三）报表并表情况', 2, 'V2_CAT_05_FINANCE', 30, 1),
('V2_CAT_05_FINANCE_04', '（四）重点财务指标分析', 2, 'V2_CAT_05_FINANCE', 40, 1),
('V2_CAT_05_FINANCE_04_01', '1.营业收入', 3, 'V2_CAT_05_FINANCE_04', 10, 1),
('V2_CAT_05_FINANCE_04_02', '2.净利润', 3, 'V2_CAT_05_FINANCE_04', 20, 1),
('V2_CAT_05_FINANCE_04_03', '3.销售利率、净利率', 3, 'V2_CAT_05_FINANCE_04', 30, 1),
('V2_CAT_05_FINANCE_04_04', '4.实收资本', 3, 'V2_CAT_05_FINANCE_04', 40, 1),
('V2_CAT_05_FINANCE_04_05', '5.应收账款和其他应收款', 3, 'V2_CAT_05_FINANCE_04', 50, 1),
('V2_CAT_05_FINANCE_04_06', '6.资产负债率', 3, 'V2_CAT_05_FINANCE_04', 60, 1),
('V2_CAT_05_FINANCE_04_07', '7.重要负债科目', 3, 'V2_CAT_05_FINANCE_04', 70, 1),
('V2_CAT_05_FINANCE_04_08', '8.其他风险', 3, 'V2_CAT_05_FINANCE_04', 80, 1),
('V2_CAT_06_CREDIT', '六、征信情况和潜在风险', 1, NULL, 60, 1),
('V2_CAT_06_CREDIT_01', '（一）征信查询时间', 2, 'V2_CAT_06_CREDIT', 10, 1),
('V2_CAT_06_CREDIT_02', '（二）征信情况', 2, 'V2_CAT_06_CREDIT', 20, 1),
('V2_CAT_06_CREDIT_03', '（三）债务情况', 2, 'V2_CAT_06_CREDIT', 30, 1),
('V2_CAT_06_CREDIT_04', '（三）其他风险', 2, 'V2_CAT_06_CREDIT', 40, 1),
('V2_CAT_07_FUND', '七、资金疑似回流或用途异常', 1, NULL, 70, 1),
('V2_CAT_07_FUND_01', '（一）疑似资金回流', 2, 'V2_CAT_07_FUND', 10, 1),
('V2_CAT_07_FUND_02', '（二）疑似资金用途异常', 2, 'V2_CAT_07_FUND', 20, 1),
('V2_CAT_08_COMPLIANCE', '八、潜在合规风险关注点', 1, NULL, 80, 1),
('V2_CAT_09_SETTLEMENT', '九、结算情况和潜在风险', 1, NULL, 90, 1),
('V2_CAT_09_SETTLEMENT_01', '（一）我行结算账户与资产情况', 2, 'V2_CAT_09_SETTLEMENT', 10, 1),
('V2_CAT_09_SETTLEMENT_02', '（二）我行结算交易对手情况', 2, 'V2_CAT_09_SETTLEMENT', 20, 1),
('V2_CAT_09_SETTLEMENT_03', '（三）我行代发业务情况', 2, 'V2_CAT_09_SETTLEMENT', 30, 1),
('V2_CAT_10_LOCALZG', '十、地方征信和潜在风险', 1, NULL, 100, 1),
('V2_CAT_11_WARNING', '十一、预警信息和潜在风险', 1, NULL, 110, 1),
('V2_CAT_11_WARNING_01', '（一）预警任务及预警信号情况', 2, 'V2_CAT_11_WARNING', 10, 1),
('V2_CAT_11_WARNING_02', '（二）风险归因模型分析', 2, 'V2_CAT_11_WARNING', 20, 1),
('V2_CAT_11_WARNING_03', '（三）行业变化分析', 2, 'V2_CAT_11_WARNING', 30, 1),
('V2_CAT_12_GUARANTEE', '十二、担保情况和潜在风险', 1, NULL, 120, 1),
('V2_CAT_12_GUARANTEE_01', '（一）抵押物', 2, 'V2_CAT_12_GUARANTEE', 10, 1),
('V2_CAT_12_GUARANTEE_02', '（二）担保人征信信息', 2, 'V2_CAT_12_GUARANTEE', 20, 1),
('V2_CAT_12_GUARANTEE_02_01', '企业担保人信息', 3, 'V2_CAT_12_GUARANTEE_02', 10, 1),
('V2_CAT_12_GUARANTEE_02_02', '1.征信查询时间', 3, 'V2_CAT_12_GUARANTEE_02', 20, 1),
('V2_CAT_12_GUARANTEE_02_03', '2.征信情况', 3, 'V2_CAT_12_GUARANTEE_02', 30, 1),
('V2_CAT_12_GUARANTEE_02_04', '3.债务情况', 3, 'V2_CAT_12_GUARANTEE_02', 40, 1),
('V2_CAT_12_GUARANTEE_02_05', '4.其他风险', 3, 'V2_CAT_12_GUARANTEE_02', 50, 1),
('V2_CAT_12_GUARANTEE_02_06', '个人担保人信息', 3, 'V2_CAT_12_GUARANTEE_02', 60, 1),
('V2_CAT_12_GUARANTEE_02_07', '1.征信查询时间', 3, 'V2_CAT_12_GUARANTEE_02', 70, 1),
('V2_CAT_12_GUARANTEE_02_08', '2.征信情况', 3, 'V2_CAT_12_GUARANTEE_02', 80, 1),
('V2_CAT_12_GUARANTEE_02_09', '3.债务情况', 3, 'V2_CAT_12_GUARANTEE_02', 90, 1),
('V2_CAT_12_GUARANTEE_02_10', '4.征信查询次数', 3, 'V2_CAT_12_GUARANTEE_02', 100, 1),
('V2_CAT_12_GUARANTEE_02_11', '5.其他风险', 3, 'V2_CAT_12_GUARANTEE_02', 110, 1);

-- ============================================================
-- ④ 内容块：报告头 3 + 正文/经验库/溯源 182 = 185
-- ============================================================
INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, agentParams, blockName, titleLevel, emptyStrategy, jumpAnchorCode, sortNo, isEnabled) VALUES
('V2_BLK_HEAD_01', NULL, 'TITLE', NULL, NULL, NULL, '报告主标题', 1, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_HEAD_02', NULL, 'TEXT', NULL, NULL, NULL, '报告副标题', NULL, 'PLACEHOLDER', NULL, 20, 1),
('V2_BLK_HEAD_03', NULL, 'TEXT', NULL, NULL, NULL, '报告说明', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_SUMMARY_A00', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_SUMMARY', 'reportNo,entName', '风险要点总结', NULL, 'HIDE', NULL, 10, 1),
('V2_BLK_SUMMARY_E01', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CUSTOMER_R02', NULL, '工商受益人和系统实控人不一致', NULL, 'HIDE', 'V2_BLK_CUSTOMER_R02', 20, 1),
('V2_BLK_SUMMARY_E02', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CUSTOMER_R03', NULL, '国有股东出资比例降低', NULL, 'HIDE', 'V2_BLK_CUSTOMER_R03', 30, 1),
('V2_BLK_SUMMARY_E03', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CUSTOMER_R04', NULL, '重要股东变更', NULL, 'HIDE', 'V2_BLK_CUSTOMER_R04', 40, 1),
('V2_BLK_SUMMARY_E04', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CUSTOMER_R05', NULL, '疑似假国资', NULL, 'HIDE', 'V2_BLK_CUSTOMER_R05', 50, 1),
('V2_BLK_SUMMARY_E05', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CUSTOMER_R06', NULL, '重大负面舆情', NULL, 'HIDE', 'V2_BLK_CUSTOMER_R06', 60, 1),
('V2_BLK_SUMMARY_E06', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R06', NULL, '营收快速下降', NULL, 'HIDE', 'V2_BLK_FINANCE_R06', 70, 1),
('V2_BLK_SUMMARY_E07', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R07', NULL, '纳税申报销售额异常', NULL, 'HIDE', 'V2_BLK_FINANCE_R07', 80, 1),
('V2_BLK_SUMMARY_E08', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R09', NULL, '净利润异常', NULL, 'HIDE', 'V2_BLK_FINANCE_R09', 90, 1),
('V2_BLK_SUMMARY_E09', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R12', NULL, '实收资本异常', NULL, 'HIDE', 'V2_BLK_FINANCE_R12', 100, 1),
('V2_BLK_SUMMARY_E10', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R14', NULL, '应收账款/其他应收款占比高', NULL, 'HIDE', 'V2_BLK_FINANCE_R14', 110, 1),
('V2_BLK_SUMMARY_E11', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R16', NULL, '资产负债率偏离度高', NULL, 'HIDE', 'V2_BLK_FINANCE_R16', 120, 1),
('V2_BLK_SUMMARY_E12', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R18', NULL, '融资过度扩张', NULL, 'HIDE', 'V2_BLK_FINANCE_R18', 130, 1),
('V2_BLK_SUMMARY_E13', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R19', NULL, '应收账款周转天数延长', NULL, 'HIDE', 'V2_BLK_FINANCE_R19', 140, 1),
('V2_BLK_SUMMARY_E14', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R20', NULL, '存货周转天数延长', NULL, 'HIDE', 'V2_BLK_FINANCE_R20', 150, 1),
('V2_BLK_SUMMARY_E15', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R21', NULL, '应收账款/存货增速异常', NULL, 'HIDE', 'V2_BLK_FINANCE_R21', 160, 1),
('V2_BLK_SUMMARY_E16', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FINANCE_R22', NULL, '报表真实性', NULL, 'HIDE', 'V2_BLK_FINANCE_R22', 170, 1),
('V2_BLK_SUMMARY_E17', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CREDIT_R02', NULL, '征信查询不在有效期内', NULL, 'HIDE', 'V2_BLK_CREDIT_R02', 180, 1),
('V2_BLK_SUMMARY_E18', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CREDIT_R04', NULL, '征信异常', NULL, 'HIDE', 'V2_BLK_CREDIT_R04', 190, 1),
('V2_BLK_SUMMARY_E19', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CREDIT_R06', NULL, '债务异常', NULL, 'HIDE', 'V2_BLK_CREDIT_R06', 200, 1),
('V2_BLK_SUMMARY_E20', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CREDIT_R07', NULL, '非银债务', NULL, 'HIDE', 'V2_BLK_CREDIT_R07', 210, 1),
('V2_BLK_SUMMARY_E21', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CREDIT_R08', NULL, '银租融资过于分散', NULL, 'HIDE', 'V2_BLK_CREDIT_R08', 220, 1),
('V2_BLK_SUMMARY_E22', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CREDIT_R09', NULL, '存在非银机构较高利率借款', NULL, 'HIDE', 'V2_BLK_CREDIT_R09', 230, 1),
('V2_BLK_SUMMARY_E23', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_CREDIT_R10', NULL, '流贷余额变化', NULL, 'HIDE', 'V2_BLK_CREDIT_R10', 240, 1),
('V2_BLK_SUMMARY_E24', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FUND_R02', NULL, '疑似资金回流未被认定', NULL, 'HIDE', 'V2_BLK_FUND_R02', 250, 1),
('V2_BLK_SUMMARY_E25', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FUND_R05', NULL, '股东借款未归还', NULL, 'HIDE', 'V2_BLK_FUND_R05', 260, 1),
('V2_BLK_SUMMARY_E26', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_FUND_R06', NULL, '受托支付异常', NULL, 'HIDE', 'V2_BLK_FUND_R06', 270, 1),
('V2_BLK_SUMMARY_E27', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_COMPLIANCE_R01', NULL, '潜在合规风险关注点', NULL, 'HIDE', 'V2_BLK_COMPLIANCE_R01', 280, 1),
('V2_BLK_SUMMARY_E28', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_SETTLEMENT_R02', NULL, '物业收入异常', NULL, 'HIDE', 'V2_BLK_SETTLEMENT_R02', 290, 1),
('V2_BLK_SUMMARY_E29', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_SETTLEMENT_R03', NULL, '电费收入异常', NULL, 'HIDE', 'V2_BLK_SETTLEMENT_R03', 300, 1),
('V2_BLK_SUMMARY_E30', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_SETTLEMENT_R04', NULL, '交易对象异常', NULL, 'HIDE', 'V2_BLK_SETTLEMENT_R04', 310, 1),
('V2_BLK_SUMMARY_E31', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_SETTLEMENT_R06', NULL, '结算与经营不匹配', NULL, 'HIDE', 'V2_BLK_SETTLEMENT_R06', 320, 1),
('V2_BLK_SUMMARY_E32', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_SETTLEMENT_R08', NULL, '代发工资异常', NULL, 'HIDE', 'V2_BLK_SETTLEMENT_R08', 330, 1),
('V2_BLK_SUMMARY_E33', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R02', NULL, '抵押物多次抵押', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R02', 340, 1),
('V2_BLK_SUMMARY_E34', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R03', NULL, '存在限制权利', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R03', 350, 1),
('V2_BLK_SUMMARY_E35', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R10', NULL, '征信查询不在有效期内', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R10', 360, 1),
('V2_BLK_SUMMARY_E36', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R12', NULL, '征信异常', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R12', 370, 1),
('V2_BLK_SUMMARY_E37', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R14', NULL, '债务异常', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R14', 380, 1),
('V2_BLK_SUMMARY_E38', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R15', NULL, '非银债务', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R15', 390, 1),
('V2_BLK_SUMMARY_E39', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R16', NULL, '银租融资过于分散', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R16', 400, 1),
('V2_BLK_SUMMARY_E40', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R17', NULL, '存在非银机构较高利率借款', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R17', 410, 1),
('V2_BLK_SUMMARY_E41', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R18', NULL, '流贷余额变化', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R18', 420, 1),
('V2_BLK_SUMMARY_E42', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R19', NULL, '对外担保金额大', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R19', 430, 1),
('V2_BLK_SUMMARY_E43', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R22', NULL, '征信查询不在有效期内', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R22', 440, 1),
('V2_BLK_SUMMARY_E44', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R24', NULL, '征信异常', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R24', 450, 1),
('V2_BLK_SUMMARY_E45', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R27', NULL, '征信查询异常', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R27', 460, 1),
('V2_BLK_SUMMARY_E46', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R28', NULL, '非银债务', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R28', 470, 1),
('V2_BLK_SUMMARY_E47', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R29', NULL, '实控人学历低', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R29', 480, 1),
('V2_BLK_SUMMARY_E48', 'V2_CAT_01_SUMMARY_01', 'TEXT', 'ANALYSIS', 'RULE_ENTRY#V2_BLK_GUARANTEE_R30', NULL, '存在非银机构较高利率借款', NULL, 'HIDE', 'V2_BLK_GUARANTEE_R30', 490, 1),
('V2_BLK_SUMMARY_A01', 'V2_CAT_01_SUMMARY_02', 'TEXT', 'ANALYSIS', 'scdhjcyj', 'reportNo,entName', '上一次贷后检查意见', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_SUMMARY_A02', 'V2_CAT_01_SUMMARY_02', 'TEXT', 'ANALYSIS', 'zjycyspyjyj', 'reportNo,entName', '最近一次（已审批）预警意见', NULL, 'PLACEHOLDER', NULL, 20, 1),
('V2_BLK_SUMMARY_L03', 'V2_CAT_01_SUMMARY_02', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_CUSTOMER_A01', 'V2_CAT_02_CUSTOMER', 'TEXT', 'ANALYSIS', 'kehujigudonggk', 'reportNo,entName', '客户及股东概况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_CUSTOMER_R02', 'V2_CAT_02_CUSTOMER', 'TEXT', 'RULE', 'shouyirenshikongrenyizhixing', 'reportNo,entName', '工商受益人和系统实控人不一致', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_CUSTOMER_R03', 'V2_CAT_02_CUSTOMER', 'TEXT', 'RULE', 'gygdczbljd', 'reportNo,entName', '国有股东出资比例降低', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_CUSTOMER_R04', 'V2_CAT_02_CUSTOMER', 'TEXT', 'RULE', 'zygdbg', 'reportNo,entName', '重要股东变更', NULL, 'HIDE', NULL, 40, 1),
('V2_BLK_CUSTOMER_R05', 'V2_CAT_02_CUSTOMER', 'TEXT', 'RULE', 'ysjgz', 'reportNo,entName', '疑似假国资', NULL, 'HIDE', NULL, 50, 1),
('V2_BLK_CUSTOMER_R06', 'V2_CAT_02_CUSTOMER', 'TEXT', 'RULE', 'zdfmyq', 'reportNo,entName', '重大负面舆情', NULL, 'HIDE', NULL, 60, 1),
('V2_BLK_CUSTOMER_T07', 'V2_CAT_02_CUSTOMER', 'TABLE', 'TRACE_TABLE', 'app_customer_info', 'reportNo,entName', '系统基本信息溯源', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_CUSTOMER_T08', 'V2_CAT_02_CUSTOMER', 'TABLE', 'TRACE_TABLE', 'app_ic_info', 'reportNo,entName', '工商登记信息溯源', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_CUSTOMER_T09', 'V2_CAT_02_CUSTOMER', 'TABLE', 'TRACE_TABLE', 'app_xd_shareholder_info', 'reportNo,entName', '信贷股东信息溯源', NULL, 'HIDE', NULL, 9030, 1),
('V2_BLK_CUSTOMER_T10', 'V2_CAT_02_CUSTOMER', 'TABLE', 'TRACE_TABLE', 'app_shareholder_info', 'reportNo,entName', '工商股东信息溯源', NULL, 'HIDE', NULL, 9040, 1),
('V2_BLK_CUSTOMER_T11', 'V2_CAT_02_CUSTOMER', 'TABLE', 'TRACE_TABLE', 'app_ic_shareholder_info', 'reportNo,entName', '工商股权变更溯源', NULL, 'HIDE', NULL, 9050, 1),
('V2_BLK_CUSTOMER_T12', 'V2_CAT_02_CUSTOMER', 'TABLE', 'TRACE_TABLE', 'app_reputation_event_info', 'reportNo,entName', '舆情事件溯源', NULL, 'HIDE', NULL, 9060, 1),
('V2_BLK_BUSINESS_A01', 'V2_CAT_03_BUSINESS', 'TEXT', 'ANALYSIS', 'qiyesxyxqk', 'reportNo,entName', '企业授信用信情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_BUSINESS_A02', 'V2_CAT_03_BUSINESS', 'TEXT', 'ANALYSIS', 'qiyezhuyaoywchanpin', 'reportNo,entName', '企业主要业务产品', NULL, 'PLACEHOLDER', NULL, 20, 1),
('V2_BLK_BUSINESS_A03', 'V2_CAT_03_BUSINESS', 'TEXT', 'ANALYSIS', 'gdcphkjh', 'reportNo,entName', '固贷类下次还款计划', NULL, 'PLACEHOLDER', NULL, 30, 1),
('V2_BLK_BUSINESS_A04', 'V2_CAT_03_BUSINESS', 'TEXT', 'ANALYSIS', 'fdckflcphkjh', 'reportNo,entName', '房地产开发类下次还款计划', NULL, 'PLACEHOLDER', NULL, 40, 1),
('V2_BLK_BUSINESS_A05', 'V2_CAT_03_BUSINESS', 'TEXT', 'ANALYSIS', 'xmdkytzs', 'reportNo,entName', '固定资产贷款、房地产开发贷款用途展示', NULL, 'PLACEHOLDER', NULL, 50, 1),
('V2_BLK_BUSINESS_A06', 'V2_CAT_03_BUSINESS', 'TEXT', 'ANALYSIS', 'jkrsjfljyq', 'reportNo,entName', '借款人十级分类及逾期', NULL, 'PLACEHOLDER', NULL, 60, 1),
('V2_BLK_BUSINESS_T07', 'V2_CAT_03_BUSINESS', 'TABLE', 'TRACE_TABLE', 'app_credit_use_info', 'reportNo,entName', '授信用信概况溯源', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_BUSINESS_T08', 'V2_CAT_03_BUSINESS', 'TABLE', 'TRACE_TABLE', 'app_loan_receipt_info', 'reportNo,entName', '借据信息溯源', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_BUSINESS_L09', 'V2_CAT_03_BUSINESS', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9030, 1),
('V2_BLK_POSTLOAN_A01', 'V2_CAT_04_POSTLOAN_01', 'TEXT', 'ANALYSIS', 'xcdkqk', 'reportNo,entName', '现场打卡情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_POSTLOAN_L02', 'V2_CAT_04_POSTLOAN_01', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_POSTLOAN_A03', 'V2_CAT_04_POSTLOAN_02', 'TEXT', 'ANALYSIS', 'pfglyqlsqk', 'reportNo,entName', '批复后续管理要求落实情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_POSTLOAN_L04', 'V2_CAT_04_POSTLOAN_02', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_POSTLOAN_A05', 'V2_CAT_04_POSTLOAN_03', 'TEXT', 'ANALYSIS', 'dxjclsqk', 'reportNo,entName', '单项检查任务落实情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_POSTLOAN_L06', 'V2_CAT_04_POSTLOAN_03', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_POSTLOAN_A07', 'V2_CAT_04_POSTLOAN_04', 'TEXT', 'ANALYSIS', 'rcdhjcbgjsfx', 'reportNo,entName', '日常贷后检查报告揭示风险', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_POSTLOAN_A08', 'V2_CAT_04_POSTLOAN_05', 'TEXT', 'ANALYSIS', 'tddkjcqk', 'reportNo,entName', '特定贷款的检查情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_A01', 'V2_CAT_05_FINANCE_01', 'TEXT', 'ANALYSIS', 'caiwu-zuixinqici', 'reportNo,entName', '最新财务期次', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_A02', 'V2_CAT_05_FINANCE_02', 'TEXT', 'ANALYSIS', 'caiwu-zuixinqicishenji', 'reportNo,entName', '最新财务期次审计情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_A03', 'V2_CAT_05_FINANCE_03', 'TEXT', 'ANALYSIS', 'caiwu-zuixinqicibingbiao', 'reportNo,entName', '最新财务期次并表情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_A04', 'V2_CAT_05_FINANCE_04_01', 'TEXT', 'ANALYSIS', 'caiwu-yingyeshouru', 'reportNo,entName', '重点财务指标分析-营业收入', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_A05', 'V2_CAT_05_FINANCE_04_01', 'TEXT', 'ANALYSIS', 'caiwu-nashuishouru', 'reportNo,entName', '重点财务指标分析-纳税销售收入', NULL, 'PLACEHOLDER', NULL, 20, 1),
('V2_BLK_FINANCE_R06', 'V2_CAT_05_FINANCE_04_01', 'TEXT', 'RULE', 'yingshoukuaisuxiajiang', 'reportNo,entName', '营收快速下降', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_FINANCE_R07', 'V2_CAT_05_FINANCE_04_01', 'TEXT', 'RULE', 'nsshenbaoxiaoshoueyichang', 'reportNo,entName', '纳税申报销售额异常', NULL, 'HIDE', NULL, 40, 1),
('V2_BLK_FINANCE_A08', 'V2_CAT_05_FINANCE_04_02', 'TEXT', 'ANALYSIS', 'caiwu-jinglirun', 'reportNo,entName', '重点财务指标分析-净利润', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_R09', 'V2_CAT_05_FINANCE_04_02', 'TEXT', 'RULE', 'jinglirunyichang', 'reportNo,entName', '净利润异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_FINANCE_A10', 'V2_CAT_05_FINANCE_04_03', 'TEXT', 'ANALYSIS', 'caiwu-xslljll', 'reportNo,entName', '重点财务指标分析-销售利率和净利率', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_A11', 'V2_CAT_05_FINANCE_04_04', 'TEXT', 'ANALYSIS', 'caiwu-shishouziben', 'reportNo,entName', '重点财务指标分析-实收资本', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_R12', 'V2_CAT_05_FINANCE_04_04', 'TEXT', 'RULE', 'sszbyc', 'reportNo,entName', '实收资本异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_FINANCE_A13', 'V2_CAT_05_FINANCE_04_05', 'TEXT', 'ANALYSIS', 'caiwu-yszk', 'reportNo,entName', '重点财务指标分析-应收账款和其他应收款', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_R14', 'V2_CAT_05_FINANCE_04_05', 'TEXT', 'RULE', 'yyzk', 'reportNo,entName', '应收账款/其他应收款占比高', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_FINANCE_A15', 'V2_CAT_05_FINANCE_04_06', 'TEXT', 'ANALYSIS', 'caiwu-zcfzlfx', 'reportNo,entName', '重点财务指标分析-资产负债率', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_R16', 'V2_CAT_05_FINANCE_04_06', 'TEXT', 'RULE', 'zcfzlpg', 'reportNo,entName', '资产负债率偏离度高', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_FINANCE_A17', 'V2_CAT_05_FINANCE_04_07', 'TEXT', 'ANALYSIS', 'caiwu-zyfzkm', 'reportNo,entName', '重点财务指标分析-重要负债科目', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FINANCE_R18', 'V2_CAT_05_FINANCE_04_08', 'TEXT', 'RULE', 'rongzikuozhang', 'reportNo,entName', '融资过度扩张', NULL, 'HIDE', NULL, 10, 1),
('V2_BLK_FINANCE_R19', 'V2_CAT_05_FINANCE_04_08', 'TEXT', 'RULE', 'yszkzztsyc', 'reportNo,entName', '应收账款周转天数延长', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_FINANCE_R20', 'V2_CAT_05_FINANCE_04_08', 'TEXT', 'RULE', 'chzutsyc', 'reportNo,entName', '存货周转天数延长', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_FINANCE_R21', 'V2_CAT_05_FINANCE_04_08', 'TEXT', 'RULE', 'yyzkchyingchang', 'reportNo,entName', '应收账款/存货增速异常', NULL, 'HIDE', NULL, 40, 1),
('V2_BLK_FINANCE_R22', 'V2_CAT_05_FINANCE_04_08', 'TEXT', 'RULE', 'bbzsxi', 'reportNo,entName', '报表真实性', NULL, 'HIDE', NULL, 50, 1),
('V2_BLK_FINANCE_T23', 'V2_CAT_05_FINANCE_04_08', 'TABLE', 'TRACE_TABLE', 'app_finance_indicator_info', 'reportNo,entName,subjectType=借款人', '报表指标信息溯源', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_FINANCE_T24', 'V2_CAT_05_FINANCE_04_08', 'TABLE', 'TRACE_TABLE', 'app_guofa_report_info', 'reportNo,entName', '国发财务信息溯源', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_FINANCE_T25', 'V2_CAT_05_FINANCE_04_08', 'TABLE', 'TRACE_TABLE', 'app_gs_finance_data_info', 'reportNo,entName', '国税财务信息溯源', NULL, 'HIDE', NULL, 9030, 1),
('V2_BLK_FINANCE_L26', 'V2_CAT_05_FINANCE_04_08', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9040, 1),
('V2_BLK_CREDIT_A01', 'V2_CAT_06_CREDIT_01', 'TEXT', 'ANALYSIS', 'zxcxsjmsqy', 'reportNo,entName,guarantorName,guarantorMode=OWN', '征信查询时间', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_CREDIT_R02', 'V2_CAT_06_CREDIT_01', 'TEXT', 'RULE', 'zxcxbzyxq', 'reportNo,entName,guarantorName,guarantorMode=OWN', '征信查询不在有效期内', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_CREDIT_A03', 'V2_CAT_06_CREDIT_02', 'TEXT', 'ANALYSIS', 'zxqkmsqy', 'reportNo,entName,guarantorName,guarantorMode=OWN', '征信情况描述', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_CREDIT_R04', 'V2_CAT_06_CREDIT_02', 'TEXT', 'RULE', 'zhengxinyichang', 'reportNo,entName,guarantorName,guarantorMode=OWN', '征信异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_CREDIT_A05', 'V2_CAT_06_CREDIT_03', 'TEXT', 'ANALYSIS', 'zwqkmsqy', 'reportNo,entName,guarantorName,guarantorMode=OWN', '债务情况描述', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_CREDIT_R06', 'V2_CAT_06_CREDIT_03', 'TEXT', 'RULE', 'zhaiwuyichang', 'reportNo,entName,guarantorName,guarantorMode=OWN', '债务异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_CREDIT_R07', 'V2_CAT_06_CREDIT_04', 'TEXT', 'RULE', 'feiyinrz', 'reportNo,entName,guarantorName,guarantorMode=OWN', '非银债务', NULL, 'HIDE', NULL, 10, 1),
('V2_BLK_CREDIT_R08', 'V2_CAT_06_CREDIT_04', 'TEXT', 'RULE', 'yinzurongzifs', 'reportNo,entName,guarantorName,guarantorMode=OWN', '银租融资过于分散', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_CREDIT_R09', 'V2_CAT_06_CREDIT_04', 'TEXT', 'RULE', 'fyjgjgll', 'reportNo,entName,guarantorName,guarantorMode=OWN', '存在非银机构较高利率借款', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_CREDIT_R10', 'V2_CAT_06_CREDIT_04', 'TEXT', 'RULE', 'ldyebh', 'reportNo,entName,guarantorName,guarantorMode=OWN', '流贷余额变化', NULL, 'HIDE', NULL, 40, 1),
('V2_BLK_CREDIT_T11', 'V2_CAT_06_CREDIT_04', 'TABLE', 'TRACE_TABLE', 'app_credit_report_info', 'reportNo,entName,subjectType=借款人', '企业征信信息溯源', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_CREDIT_L12', 'V2_CAT_06_CREDIT_04', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_FUND_A01', 'V2_CAT_07_FUND_01', 'TEXT', 'ANALYSIS', 'yszjhlyc', 'reportNo,entName', '疑似资金回流异常', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FUND_R02', 'V2_CAT_07_FUND_01', 'TEXT', 'RULE', 'yszjllwbrd', 'reportNo,entName', '疑似资金回流未被认定', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_FUND_L03', 'V2_CAT_07_FUND_01', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_FUND_A04', 'V2_CAT_07_FUND_02', 'TEXT', 'ANALYSIS', 'zjysytyc', 'reportNo,entName', '资金疑似用途异常', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_FUND_R05', 'V2_CAT_07_FUND_02', 'TEXT', 'RULE', 'gdjkwgh', 'reportNo,entName', '股东借款未归还', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_FUND_R06', 'V2_CAT_07_FUND_02', 'TEXT', 'RULE', 'stzfyc', 'reportNo,entName', '受托支付异常', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_FUND_L07', 'V2_CAT_07_FUND_02', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_COMPLIANCE_R01', 'V2_CAT_08_COMPLIANCE', 'TEXT', 'RULE', 'qzhgfxgzd', 'reportNo,entName', '潜在合规风险关注点', NULL, 'HIDE', NULL, 10, 1),
('V2_BLK_COMPLIANCE_L02', 'V2_CAT_08_COMPLIANCE', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_SETTLEMENT_A01', 'V2_CAT_09_SETTLEMENT_01', 'TEXT', 'ANALYSIS', 'whjszhyzcqk', 'reportNo,entName', '我行结算账户与资产情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_SETTLEMENT_R02', 'V2_CAT_09_SETTLEMENT_01', 'TEXT', 'RULE', 'wysryc', 'reportNo,entName', '物业收入异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_SETTLEMENT_R03', 'V2_CAT_09_SETTLEMENT_01', 'TEXT', 'RULE', 'dfsryc', 'reportNo,entName', '电费收入异常', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_SETTLEMENT_R04', 'V2_CAT_09_SETTLEMENT_01', 'TEXT', 'RULE', 'jyzfdxy', 'reportNo,entName', '交易对象异常', NULL, 'HIDE', NULL, 40, 1),
('V2_BLK_SETTLEMENT_A05', 'V2_CAT_09_SETTLEMENT_02', 'TEXT', 'ANALYSIS', 'whjsjydsqk', 'reportNo,entName', '我行结算交易对手情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_SETTLEMENT_R06', 'V2_CAT_09_SETTLEMENT_02', 'TEXT', 'RULE', 'jsyjybpp', 'reportNo,entName', '结算与经营不匹配', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_SETTLEMENT_A07', 'V2_CAT_09_SETTLEMENT_03', 'TEXT', 'ANALYSIS', 'whywdfk', 'reportNo,entName', '我行代发业务情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_SETTLEMENT_R08', 'V2_CAT_09_SETTLEMENT_03', 'TEXT', 'RULE', 'daifgzyc', 'reportNo,entName', '代发工资异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_SETTLEMENT_T09', 'V2_CAT_09_SETTLEMENT_03', 'TABLE', 'TRACE_TABLE', 'app_settle_account_info', 'reportNo,entName', '结算账户溯源', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_SETTLEMENT_T10', 'V2_CAT_09_SETTLEMENT_03', 'TABLE', 'TRACE_TABLE', 'app_settle_asset_info', 'reportNo,entName', '结算资产溯源', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_SETTLEMENT_T11', 'V2_CAT_09_SETTLEMENT_03', 'TABLE', 'TRACE_TABLE', 'app_entrust_pay_info', 'reportNo,entName', '受托支付明细溯源', NULL, 'HIDE', NULL, 9030, 1),
('V2_BLK_SETTLEMENT_T12', 'V2_CAT_09_SETTLEMENT_03', 'TABLE', 'TRACE_TABLE', 'app_top_five_updown_info', 'reportNo,entName', '前五大上下游溯源', NULL, 'HIDE', NULL, 9040, 1),
('V2_BLK_SETTLEMENT_T13', 'V2_CAT_09_SETTLEMENT_03', 'TABLE', 'TRACE_TABLE', 'app_settle_counterparty_info', 'reportNo,entName', '结算交易对手溯源', NULL, 'HIDE', NULL, 9050, 1),
('V2_BLK_SETTLEMENT_T14', 'V2_CAT_09_SETTLEMENT_03', 'TABLE', 'TRACE_TABLE', 'app_payroll_stat_info', 'reportNo,entName', '代发月度统计溯源', NULL, 'HIDE', NULL, 9060, 1),
('V2_BLK_LOCALZG_L01', 'V2_CAT_10_LOCALZG', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_WARNING_A01', 'V2_CAT_11_WARNING_01', 'TEXT', 'ANALYSIS', 'yjrwjyjxh', 'reportNo,entName', '预警任务及预警信号情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_WARNING_L02', 'V2_CAT_11_WARNING_01', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_WARNING_L03', 'V2_CAT_11_WARNING_01', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_WARNING_X04', 'V2_CAT_11_WARNING_02', 'TEXT', 'EXTERNAL', 'Risk-RiskReferenceAfter-Analysis-Customer-Suz', 'entName', '风险归因分析（贷后视角）', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_WARNING_X05', 'V2_CAT_11_WARNING_03', 'TEXT', 'EXTERNAL', 'post_loan_industry_change_impact_code', 'entName', '行业宏观变化贷后检查code模式', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_A01', 'V2_CAT_12_GUARANTEE_01', 'TEXT', 'ANALYSIS', 'dyawuqingkuang', 'reportNo,entName', '抵押物情况', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R02', 'V2_CAT_12_GUARANTEE_01', 'TEXT', 'RULE', 'yapindywdcdy', 'reportNo,entName', '抵押物多次抵押', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_R03', 'V2_CAT_12_GUARANTEE_01', 'TEXT', 'RULE', 'yapinczxzql', 'reportNo,entName', '存在限制权利', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_GUARANTEE_T04', 'V2_CAT_12_GUARANTEE_01', 'TABLE', 'TRACE_TABLE', 'app_collateral_info', 'reportNo,entName', '押品基本信息溯源', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_GUARANTEE_T05', 'V2_CAT_12_GUARANTEE_01', 'TABLE', 'TRACE_TABLE', 'app_collateral_mortgage_info', 'reportNo,entName', '押品他项权利溯源', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_GUARANTEE_T06', 'V2_CAT_12_GUARANTEE_01', 'TABLE', 'TRACE_TABLE', 'app_collateral_restricted_right', 'reportNo,entName', '押品限制权利溯源', NULL, 'HIDE', NULL, 9030, 1),
('V2_BLK_GUARANTEE_L07', 'V2_CAT_12_GUARANTEE_01', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9040, 1),
('V2_BLK_GUARANTEE_A08', 'V2_CAT_12_GUARANTEE_02_01', 'TEXT', 'ANALYSIS', 'dbrxx', 'reportNo,entName,guarantorName,guarantorMode=LEGAL,guarantorEmph=1', '担保人信息', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_A09', 'V2_CAT_12_GUARANTEE_02_02', 'TEXT', 'ANALYSIS', 'zxcxsjmsqy', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '征信查询时间', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R10', 'V2_CAT_12_GUARANTEE_02_02', 'TEXT', 'RULE', 'zxcxbzyxq', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '征信查询不在有效期内', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_A11', 'V2_CAT_12_GUARANTEE_02_03', 'TEXT', 'ANALYSIS', 'zxqkmsqy', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '征信情况描述', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R12', 'V2_CAT_12_GUARANTEE_02_03', 'TEXT', 'RULE', 'zhengxinyichang', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '征信异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_A13', 'V2_CAT_12_GUARANTEE_02_04', 'TEXT', 'ANALYSIS', 'zwqkmsqy', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '债务情况描述', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R14', 'V2_CAT_12_GUARANTEE_02_04', 'TEXT', 'RULE', 'zhaiwuyichang', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '债务异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_R15', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'RULE', 'feiyinrz', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '非银债务', NULL, 'HIDE', NULL, 10, 1),
('V2_BLK_GUARANTEE_R16', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'RULE', 'yinzurongzifs', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '银租融资过于分散', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_R17', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'RULE', 'fyjgjgll', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '存在非银机构较高利率借款', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_GUARANTEE_R18', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'RULE', 'ldyebh', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '流贷余额变化', NULL, 'HIDE', NULL, 40, 1),
('V2_BLK_GUARANTEE_R19', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'RULE', 'dwdbjed', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '对外担保金额大', NULL, 'HIDE', NULL, 50, 1),
('V2_BLK_GUARANTEE_A20', 'V2_CAT_12_GUARANTEE_02_06', 'TEXT', 'ANALYSIS', 'dbrxx', 'reportNo,entName,guarantorName,guarantorMode=NATURAL,guarantorEmph=1', '担保人信息', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_A21', 'V2_CAT_12_GUARANTEE_02_07', 'TEXT', 'ANALYSIS', 'zxcxsjmsgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信查询时间-个人', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R22', 'V2_CAT_12_GUARANTEE_02_07', 'TEXT', 'RULE', 'zxcxyxx', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信查询不在有效期内', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_A23', 'V2_CAT_12_GUARANTEE_02_08', 'TEXT', 'ANALYSIS', 'zxqkmsgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信情况描述-自然人', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R24', 'V2_CAT_12_GUARANTEE_02_08', 'TEXT', 'RULE', 'zirenzhengxinyichang', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_A25', 'V2_CAT_12_GUARANTEE_02_09', 'TEXT', 'ANALYSIS', 'zwqkmsgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '债务情况描述-自然人', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_A26', 'V2_CAT_12_GUARANTEE_02_10', 'TEXT', 'ANALYSIS', 'zxcxcsgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信查询次数描述-自然人', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R27', 'V2_CAT_12_GUARANTEE_02_10', 'TEXT', 'RULE', 'zhengxinchaxunyichang', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信查询异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_R28', 'V2_CAT_12_GUARANTEE_02_11', 'TEXT', 'RULE', 'fyzwgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '非银债务', NULL, 'HIDE', NULL, 10, 1),
('V2_BLK_GUARANTEE_R29', 'V2_CAT_12_GUARANTEE_02_11', 'TEXT', 'RULE', 'skrxldgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '实控人学历低', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_R30', 'V2_CAT_12_GUARANTEE_02_11', 'TEXT', 'RULE', 'czfyjgglvgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '存在非银机构较高利率借款', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_GUARANTEE_T31', 'V2_CAT_12_GUARANTEE_02_11', 'TABLE', 'TRACE_TABLE', 'app_guarantor_info', 'reportNo,entName,subjectType=担保人', '担保人信息溯源', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_GUARANTEE_T32', 'V2_CAT_12_GUARANTEE_02_05', 'TABLE', 'TRACE_TABLE', 'app_credit_report_info', 'reportNo,entName,subjectType=担保人', '企业担保人征信信息溯源', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_GUARANTEE_T33', 'V2_CAT_12_GUARANTEE_02_11', 'TABLE', 'TRACE_TABLE', 'app_guarantor_credit_info', 'reportNo,entName', '个人担保人征信信息溯源', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_GUARANTEE_L34', 'V2_CAT_12_GUARANTEE_02_11', 'TEXT', 'TRACE_LINK', NULL, NULL, '溯源信息', NULL, 'HIDE', NULL, 9030, 1);

-- ============================================================
-- ⑤ 校验（可选，执行后应满足）：目录 56 行 / 内容块 185 行
--    SELECT catalogLevel, COUNT(*) FROM app_report_catalog WHERE isEnabled = 1 AND catalogCode LIKE 'V2_%' GROUP BY catalogLevel ORDER BY 1;
--    SELECT COUNT(*) FROM app_report_content_block WHERE isEnabled = 1 AND blockCode LIKE 'V2_%';
-- ============================================================
