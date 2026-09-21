-- =====================================================================
-- 补列脚本：xd_corp_check_info 补齐 5 列（对齐行内已有结构）
-- 数据库：高斯DB（GaussDB / openGauss）
-- 日期  ：2026-09-21
--
-- 背景：行内 `xd_corp_check_info` 已是 **17 列**，外网这份 DDL 还是 **12 列**，
--       缺下面这 5 列。
--       行内来源：`szbank/aimp-plma/表结构变更整理_20260915_10点至今.sql`
--                 （提交 fc66641 12:18 / f4fdea3 15:36，含 ADD COLUMN + COMMENT ON）
--
-- 🔴 为什么**必须**补（不是"顺带对齐一下"）：
--   报告「链接溯源」的 **1010 批复链接（电子批复）** 会直接查这张表取流水号 ——
--   `LinkTraceQueryMapper.selectCorpCheckInfo`：
--       SELECT serialno, bapserialno, baserialno, electroapproveserialno, approveapplytype
--         FROM xd_corp_check_info WHERE reportno = ? ORDER BY id DESC LIMIT 1
--   其中 **baSerialNo / approveApplyType / electroApproveSerialNo 三列**就是本次要补的
--   ⇒ 不补，该接口一执行就报「列不存在」，**1010 溯源链接点不出来**（报错在库，不在模板/代码）。
--
-- ⚠️ 幂等性：本脚本**不是**幂等的。列已存在时重复执行会报
--   "column xxx of relation xd_corp_check_info already exists"，属正常现象，跳过即可。
--   ⇒ **行内不要跑**（行内这 5 列早就有了，跑了必然报上面这条）。
--
-- ⚠️ 用途说明：本脚本属**外网环境自测**用途（放在 `sql/20260819/**`，不随「往行内同步」带上）。
-- =====================================================================

-- 执行前置（按目标库 schema 调整）：
-- SET search_path = <schema>, public;

-- ① 贷后检查文本编号（对齐用；1010 不取）
ALTER TABLE xd_corp_check_info ADD COLUMN bapTextNo VARCHAR(64);
COMMENT ON COLUMN xd_corp_check_info.bapTextNo IS '贷后检查文本编号';

-- ② 上一期征信报告编号（对齐用；1010 不取）
ALTER TABLE xd_corp_check_info ADD COLUMN lastReportNo VARCHAR(64);
COMMENT ON COLUMN xd_corp_check_info.lastReportNo IS '上一期征信报告编号';

-- ③ 授信流水号 —— 🔴 1010 用（拼 pageParams 的 applySerialNo）
ALTER TABLE xd_corp_check_info ADD COLUMN baSerialNo VARCHAR(64);
COMMENT ON COLUMN xd_corp_check_info.baSerialNo IS '授信流水号';

-- ④ 批复类型 —— 🔴 1010 用（pageParams 的 approveApplyType）
ALTER TABLE xd_corp_check_info ADD COLUMN approveApplyType VARCHAR(64);
COMMENT ON COLUMN xd_corp_check_info.approveApplyType IS '批复类型';

-- ⑤ 电子批复流水号 —— 🔴 1010 用（pageParams 的 electroApproveSerialNo）
ALTER TABLE xd_corp_check_info ADD COLUMN electroApproveSerialNo VARCHAR(64);
COMMENT ON COLUMN xd_corp_check_info.electroApproveSerialNo IS '电子批复流水号';

-- =====================================================================
-- 校验（执行后应返回 5 行、is_nullable 全为 YES）
-- =====================================================================
-- SELECT column_name, data_type, character_maximum_length, is_nullable
--   FROM information_schema.columns
--  WHERE table_name = 'xd_corp_check_info'
--    AND lower(column_name) IN ('baptextno', 'lastreportno', 'baserialno',
--                               'approveapplytype', 'electroapproveserialno')
--  ORDER BY column_name;
-- =====================================================================

-- =====================================================================
-- 另：1010 还会取 serialNo / bapSerialNo，这两列**外网本来就有**，无需补：
--   · serialno     —— 日检申请流水号（1010 拼 serialNo）
--   · bapserialno  —— 批复编号（1010 拼 serialNo 与 approveSerialNo，两处都用它）
-- =====================================================================
