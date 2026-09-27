-- =====================================================================
-- 模板增量 DML（由 _tools/gen_delta_dml.py 生成，勿手工改）
--
-- 用途：**目标库已跑过上一版模板 DML** ⇒ 只补差异（幂等，可重复执行）。
-- 全量版见同目录 `报告模板_新模板_dml.sql`（新环境 / 愿意重跑全量的用它）。
--
-- 变更概览（基线：`_backup_20260927_段节点前/报告模板_新模板_dml.sql` → 当前 `报告模板_新模板_dml.sql`）：
--   · 新增块 0：—
--   · 删除块 0：—
--   · 内容变更 29：V2_BLK_GUARANTEE_A07, V2_BLK_GUARANTEE_A08, V2_BLK_GUARANTEE_R09, V2_BLK_GUARANTEE_A10, V2_BLK_GUARANTEE_R11, V2_BLK_GUARANTEE_A12, V2_BLK_GUARANTEE_R13, V2_BLK_GUARANTEE_R14, V2_BLK_GUARANTEE_R15, V2_BLK_GUARANTEE_R16, V2_BLK_GUARANTEE_R17, V2_BLK_GUARANTEE_R18, V2_BLK_GUARANTEE_L19, V2_BLK_GUARANTEE_T20, V2_BLK_GUARANTEE_T21, V2_BLK_GUARANTEE_A22, V2_BLK_GUARANTEE_A23, V2_BLK_GUARANTEE_R24, V2_BLK_GUARANTEE_A25, V2_BLK_GUARANTEE_R26, V2_BLK_GUARANTEE_A27, V2_BLK_GUARANTEE_A28, V2_BLK_GUARANTEE_R29, V2_BLK_GUARANTEE_R30, V2_BLK_GUARANTEE_R31, V2_BLK_GUARANTEE_R32, V2_BLK_GUARANTEE_L33, V2_BLK_GUARANTEE_T34, V2_BLK_GUARANTEE_T35
--   · 目录表：新增 2 / 删除 0 / 变更 9  🔴 本次目录有变动 ⇒ 其 DDL 已一并生成（见 ③）；目录与块必须一起更新
--
-- 🔴 链接溯源块的 agentCode = **shareCode**（1010~1150）；标「待定预留」的写 NULL
--    （待接入行内图谱链接）⇒ 该块按 emptyStrategy 处理：HIDE 就**不渲染入口**，
--    PLACEHOLDER 才显示「暂无数据」占位。
-- =====================================================================

-- 执行前置：SET search_path = <schema>, public;

BEGIN;

-- ② 新增 + 变更：先按 code 精确删除，再插入新版本（幂等）
--   变更 29 个：V2_BLK_GUARANTEE_A07, V2_BLK_GUARANTEE_A08, V2_BLK_GUARANTEE_R09, V2_BLK_GUARANTEE_A10, V2_BLK_GUARANTEE_R11, V2_BLK_GUARANTEE_A12, V2_BLK_GUARANTEE_R13, V2_BLK_GUARANTEE_R14, V2_BLK_GUARANTEE_R15, V2_BLK_GUARANTEE_R16, V2_BLK_GUARANTEE_R17, V2_BLK_GUARANTEE_R18, V2_BLK_GUARANTEE_L19, V2_BLK_GUARANTEE_T20, V2_BLK_GUARANTEE_T21, V2_BLK_GUARANTEE_A22, V2_BLK_GUARANTEE_A23, V2_BLK_GUARANTEE_R24, V2_BLK_GUARANTEE_A25, V2_BLK_GUARANTEE_R26, V2_BLK_GUARANTEE_A27, V2_BLK_GUARANTEE_A28, V2_BLK_GUARANTEE_R29, V2_BLK_GUARANTEE_R30, V2_BLK_GUARANTEE_R31, V2_BLK_GUARANTEE_R32, V2_BLK_GUARANTEE_L33, V2_BLK_GUARANTEE_T34, V2_BLK_GUARANTEE_T35
DELETE FROM app_report_content_block WHERE blockcode IN ('V2_BLK_GUARANTEE_A07', 'V2_BLK_GUARANTEE_A08', 'V2_BLK_GUARANTEE_R09', 'V2_BLK_GUARANTEE_A10', 'V2_BLK_GUARANTEE_R11', 'V2_BLK_GUARANTEE_A12', 'V2_BLK_GUARANTEE_R13', 'V2_BLK_GUARANTEE_R14', 'V2_BLK_GUARANTEE_R15', 'V2_BLK_GUARANTEE_R16', 'V2_BLK_GUARANTEE_R17', 'V2_BLK_GUARANTEE_R18', 'V2_BLK_GUARANTEE_L19', 'V2_BLK_GUARANTEE_T20', 'V2_BLK_GUARANTEE_T21', 'V2_BLK_GUARANTEE_A22', 'V2_BLK_GUARANTEE_A23', 'V2_BLK_GUARANTEE_R24', 'V2_BLK_GUARANTEE_A25', 'V2_BLK_GUARANTEE_R26', 'V2_BLK_GUARANTEE_A27', 'V2_BLK_GUARANTEE_A28', 'V2_BLK_GUARANTEE_R29', 'V2_BLK_GUARANTEE_R30', 'V2_BLK_GUARANTEE_R31', 'V2_BLK_GUARANTEE_R32', 'V2_BLK_GUARANTEE_L33', 'V2_BLK_GUARANTEE_T34', 'V2_BLK_GUARANTEE_T35');

INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, agentParams, blockName, titleLevel, emptyStrategy, jumpAnchorCode, sortNo, isEnabled) VALUES
('V2_BLK_GUARANTEE_A07', 'V2_CAT_12_GUARANTEE_02_01', 'TEXT', 'ANALYSIS', 'dbrxx', 'reportNo,entName,guarantorName,guarantorMode=LEGAL,guarantorEmph=1', '担保人信息', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_A08', 'V2_CAT_12_GUARANTEE_02_02', 'TEXT', 'ANALYSIS', 'zxcxsjmsqy', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '征信查询时间', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R09', 'V2_CAT_12_GUARANTEE_02_02', 'TEXT', 'RULE', 'zxcxbzyxq', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '征信查询不在有效期内', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_A10', 'V2_CAT_12_GUARANTEE_02_03', 'TEXT', 'ANALYSIS', 'zxqkmsqy', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '征信情况描述', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R11', 'V2_CAT_12_GUARANTEE_02_03', 'TEXT', 'RULE', 'zhengxinyichang', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '征信异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_A12', 'V2_CAT_12_GUARANTEE_02_04', 'TEXT', 'ANALYSIS', 'zwqkmsqy', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '债务情况描述', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R13', 'V2_CAT_12_GUARANTEE_02_04', 'TEXT', 'RULE', 'zhaiwuyichang', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '债务异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_R14', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'RULE', 'feiyinrz', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '非银债务', NULL, 'HIDE', NULL, 10, 1),
('V2_BLK_GUARANTEE_R15', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'RULE', 'yinzurongzifs', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '银租融资过于分散', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_R16', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'RULE', 'fyjgjgll', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '存在非银机构较高利率借款', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_GUARANTEE_R17', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'RULE', 'ldyebh', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '流贷余额变化', NULL, 'HIDE', NULL, 40, 1),
('V2_BLK_GUARANTEE_R18', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'RULE', 'dwdbjed', 'reportNo,entName,guarantorName,guarantorMode=LEGAL', '对外担保金额大', NULL, 'HIDE', NULL, 50, 1),
('V2_BLK_GUARANTEE_L19', 'V2_CAT_12_GUARANTEE_02_05', 'TEXT', 'TRACE_LINK', '1050', 'subjectType=担保人,guarantorType=法人', '信贷-征信报告预览', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_GUARANTEE_T20', 'V2_CAT_12_GUARANTEE_02_05', 'TABLE', 'TRACE_TABLE', 'app_guarantor_info', 'reportNo,entName,guarantorName,subjectType=担保人,guarantorMode=LEGAL', '担保人信息', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_GUARANTEE_T21', 'V2_CAT_12_GUARANTEE_02_05', 'TABLE', 'TRACE_TABLE', 'app_credit_report_info', 'reportNo,entName,guarantorName,subjectType=担保人,guarantorMode=LEGAL', '企业担保人征信信息', NULL, 'HIDE', NULL, 9030, 1),
('V2_BLK_GUARANTEE_A22', 'V2_CAT_12_GUARANTEE_02_06', 'TEXT', 'ANALYSIS', 'dbrxx', 'reportNo,entName,guarantorName,guarantorMode=NATURAL,guarantorEmph=1', '担保人信息', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_A23', 'V2_CAT_12_GUARANTEE_02_07', 'TEXT', 'ANALYSIS', 'zxcxsjmsgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信查询时间-个人', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R24', 'V2_CAT_12_GUARANTEE_02_07', 'TEXT', 'RULE', 'zxcxyxx', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信查询不在有效期内', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_A25', 'V2_CAT_12_GUARANTEE_02_08', 'TEXT', 'ANALYSIS', 'zxqkmsgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信情况描述-自然人', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R26', 'V2_CAT_12_GUARANTEE_02_08', 'TEXT', 'RULE', 'zirenzhengxinyichang', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_A27', 'V2_CAT_12_GUARANTEE_02_09', 'TEXT', 'ANALYSIS', 'zwqkmsgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '债务情况描述-自然人', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_A28', 'V2_CAT_12_GUARANTEE_02_10', 'TEXT', 'ANALYSIS', 'zxcxcsgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信查询次数描述-自然人', NULL, 'PLACEHOLDER', NULL, 10, 1),
('V2_BLK_GUARANTEE_R29', 'V2_CAT_12_GUARANTEE_02_10', 'TEXT', 'RULE', 'zhengxinchaxunyichang', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '征信查询异常', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_R30', 'V2_CAT_12_GUARANTEE_02_11', 'TEXT', 'RULE', 'fyzwgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '非银债务', NULL, 'HIDE', NULL, 10, 1),
('V2_BLK_GUARANTEE_R31', 'V2_CAT_12_GUARANTEE_02_11', 'TEXT', 'RULE', 'skrxldgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '实控人学历低', NULL, 'HIDE', NULL, 20, 1),
('V2_BLK_GUARANTEE_R32', 'V2_CAT_12_GUARANTEE_02_11', 'TEXT', 'RULE', 'czfyjgglvgr', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '存在非银机构较高利率借款', NULL, 'HIDE', NULL, 30, 1),
('V2_BLK_GUARANTEE_L33', 'V2_CAT_12_GUARANTEE_02_11', 'TEXT', 'TRACE_LINK', '1050', 'subjectType=担保人,guarantorType=自然人', '信贷-征信报告预览', NULL, 'HIDE', NULL, 9010, 1),
('V2_BLK_GUARANTEE_T34', 'V2_CAT_12_GUARANTEE_02_11', 'TABLE', 'TRACE_TABLE', 'app_guarantor_info', 'reportNo,entName,guarantorName,subjectType=担保人,guarantorMode=NATURAL', '担保人信息', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_GUARANTEE_T35', 'V2_CAT_12_GUARANTEE_02_11', 'TABLE', 'TRACE_TABLE', 'app_guarantor_credit_info', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '个人担保人征信信息', NULL, 'HIDE', NULL, 9030, 1);

-- ③ 目录表：新增 / 变更 + 删除（先按 code 精确删，再插入新版本；幂等）
--    🔴 目录必须与上面②的块**同批更新**：块指向新目录而目录没进库 ⇒
--       报告生成会报「模板校验不通过：内容块所属目录不存在或已停用」。
--   新增 2 个：V2_CAT_12_GUARANTEE_02_10, V2_CAT_12_GUARANTEE_02_11
--   变更 9 个：V2_CAT_12_GUARANTEE_02_01, V2_CAT_12_GUARANTEE_02_02, V2_CAT_12_GUARANTEE_02_03, V2_CAT_12_GUARANTEE_02_04, V2_CAT_12_GUARANTEE_02_05, V2_CAT_12_GUARANTEE_02_06, V2_CAT_12_GUARANTEE_02_07, V2_CAT_12_GUARANTEE_02_08, V2_CAT_12_GUARANTEE_02_09
DELETE FROM app_report_catalog WHERE catalogcode IN ('V2_CAT_12_GUARANTEE_02_10', 'V2_CAT_12_GUARANTEE_02_11', 'V2_CAT_12_GUARANTEE_02_01', 'V2_CAT_12_GUARANTEE_02_02', 'V2_CAT_12_GUARANTEE_02_03', 'V2_CAT_12_GUARANTEE_02_04', 'V2_CAT_12_GUARANTEE_02_05', 'V2_CAT_12_GUARANTEE_02_06', 'V2_CAT_12_GUARANTEE_02_07', 'V2_CAT_12_GUARANTEE_02_08', 'V2_CAT_12_GUARANTEE_02_09');

INSERT INTO app_report_catalog (catalogCode, catalogName, catalogLevel, parentCode, sortNo, isEnabled) VALUES
('V2_CAT_12_GUARANTEE_02_10', '4.征信查询次数', 3, 'V2_CAT_12_GUARANTEE_02', 100, 1),
('V2_CAT_12_GUARANTEE_02_11', '5.其他风险', 3, 'V2_CAT_12_GUARANTEE_02', 110, 1),
('V2_CAT_12_GUARANTEE_02_01', '企业担保人信息', 3, 'V2_CAT_12_GUARANTEE_02', 10, 1),
('V2_CAT_12_GUARANTEE_02_02', '1.征信查询时间', 3, 'V2_CAT_12_GUARANTEE_02', 20, 1),
('V2_CAT_12_GUARANTEE_02_03', '2.征信情况', 3, 'V2_CAT_12_GUARANTEE_02', 30, 1),
('V2_CAT_12_GUARANTEE_02_04', '3.债务情况', 3, 'V2_CAT_12_GUARANTEE_02', 40, 1),
('V2_CAT_12_GUARANTEE_02_05', '4.其他风险', 3, 'V2_CAT_12_GUARANTEE_02', 50, 1),
('V2_CAT_12_GUARANTEE_02_06', '个人担保人信息', 3, 'V2_CAT_12_GUARANTEE_02', 60, 1),
('V2_CAT_12_GUARANTEE_02_07', '1.征信查询时间', 3, 'V2_CAT_12_GUARANTEE_02', 70, 1),
('V2_CAT_12_GUARANTEE_02_08', '2.征信情况', 3, 'V2_CAT_12_GUARANTEE_02', 80, 1),
('V2_CAT_12_GUARANTEE_02_09', '3.债务情况', 3, 'V2_CAT_12_GUARANTEE_02', 90, 1);

COMMIT;

-- ═══════════════════════════════════════════════════════════════════
-- 复核（跑完后应得 16 行；agentcode = 有值 + NULL 的「待定预留」）：
--   SELECT blockcode, agentcode, agentparams, blockname
--     FROM app_report_content_block
--    WHERE analysistype = 'TRACE_LINK'
--    ORDER BY blockcode;
-- ═══════════════════════════════════════════════════════════════════
