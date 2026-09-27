-- =====================================================================
-- 模板增量 DML（由 _tools/gen_delta_dml.py 生成，勿手工改）
--
-- 用途：**目标库已跑过上一版模板 DML** ⇒ 只补差异（幂等，可重复执行）。
-- 全量版见同目录 `报告模板_新模板_dml.sql`（新环境 / 愿意重跑全量的用它）。
--
-- 变更概览（diff：prev.sql → 报告模板_新模板_dml.sql）：
--   · 新增块 0：—
--   · 删除块 0：—
--   · 内容变更 4：V2_BLK_GUARANTEE_T20, V2_BLK_GUARANTEE_T21, V2_BLK_GUARANTEE_T34, V2_BLK_GUARANTEE_T35
--   · 目录表：新增 0 / 删除 0 / 变更 0
--
-- 🔴 链接溯源块的 agentCode = **shareCode**（1010~1150）；标「待定预留」的写 NULL
--    （待接入行内图谱链接）⇒ 该块按 emptyStrategy 处理：HIDE 就**不渲染入口**，
--    PLACEHOLDER 才显示「暂无数据」占位。
-- =====================================================================

-- 执行前置：SET search_path = <schema>, public;

BEGIN;

-- ② 新增 + 变更：先按 code 精确删除，再插入新版本（幂等）
--   变更 4 个：V2_BLK_GUARANTEE_T20, V2_BLK_GUARANTEE_T21, V2_BLK_GUARANTEE_T34, V2_BLK_GUARANTEE_T35
DELETE FROM app_report_content_block WHERE blockcode IN ('V2_BLK_GUARANTEE_T20', 'V2_BLK_GUARANTEE_T21', 'V2_BLK_GUARANTEE_T34', 'V2_BLK_GUARANTEE_T35');

INSERT INTO app_report_content_block (blockCode, catalogCode, fillType, analysisType, agentCode, agentParams, blockName, titleLevel, emptyStrategy, jumpAnchorCode, sortNo, isEnabled) VALUES
('V2_BLK_GUARANTEE_T20', 'V2_CAT_12_GUARANTEE_02_05', 'TABLE', 'TRACE_TABLE', 'app_guarantor_info', 'reportNo,entName,guarantorName,subjectType=担保人,guarantorMode=LEGAL', '担保人信息', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_GUARANTEE_T21', 'V2_CAT_12_GUARANTEE_02_05', 'TABLE', 'TRACE_TABLE', 'app_credit_report_info', 'reportNo,entName,guarantorName,subjectType=担保人,guarantorMode=LEGAL', '企业担保人征信信息', NULL, 'HIDE', NULL, 9030, 1),
('V2_BLK_GUARANTEE_T34', 'V2_CAT_12_GUARANTEE_02_11', 'TABLE', 'TRACE_TABLE', 'app_guarantor_info', 'reportNo,entName,guarantorName,subjectType=担保人,guarantorMode=NATURAL', '担保人信息', NULL, 'HIDE', NULL, 9020, 1),
('V2_BLK_GUARANTEE_T35', 'V2_CAT_12_GUARANTEE_02_11', 'TABLE', 'TRACE_TABLE', 'app_guarantor_credit_info', 'reportNo,entName,guarantorName,guarantorMode=NATURAL', '个人担保人征信信息', NULL, 'HIDE', NULL, 9030, 1);

COMMIT;

-- ═══════════════════════════════════════════════════════════════════
-- 复核（跑完后应得 16 行；agentcode = 有值 + NULL 的「待定预留」）：
--   SELECT blockcode, agentcode, agentparams, blockname
--     FROM app_report_content_block
--    WHERE analysistype = 'TRACE_LINK'
--    ORDER BY blockcode;
-- ═══════════════════════════════════════════════════════════════════
