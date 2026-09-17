-- =====================================================================
-- 补列脚本：app_report_content_block 增加 agentParams（调智能体入参清单）
-- 数据库：高斯DB（GaussDB/openGauss）
-- 日期  ：2026-09-17
--
-- 背景：对齐《报告详情设计》G 列「知识库/智策引擎参数」。
--   源表的 G 列只有两种取值：
--     · `借款人entName`
--     · `借款人entName\n担保人guarantorname\n多个担保人时轮循`
--   归一成逗号分隔的参数名后落本列：
--     · `reportNo,entName`
--     · `reportNo,entName,guarantorName`
--
-- 🔴 为什么必须单独一列，不能靠 agentCode 区分：
--   同一个 agentCode 会在不同章节复用（源表里 zxcxsjmsqy / zxcxbzyxq / zxqkmsqy /
--   zhengxinyichang / zwqkmsqy / zhaiwuyichang / feiyinrz / yinzurongzifs / fyjgjgll /
--   ldyebh 在「六、征信情况和潜在风险」与「十二、（二）担保人征信信息」各出现一次）。
--   前者是**借款人**口径、后者是**担保人**口径 —— 入参不同、结果完全不同，
--   调度侧既不能去重也不能混用，只靠 agentCode 无法区分。
--
-- ⚠️ 幂等性：本脚本**不是**幂等的。若该列已存在，重复执行会报
--   "column agentParams of relation app_report_content_block already exists"，
--   属正常现象，跳过即可。
-- =====================================================================

ALTER TABLE app_report_content_block ADD COLUMN agentParams VARCHAR(256);

COMMENT ON COLUMN app_report_content_block.agentParams IS '调智能体入参清单（逗号分隔的参数名，仅 TEXT/TABLE 有值）：reportNo,entName 或 reportNo,entName,guarantorName（后者按担保人口径、多担保人时轮循）。2026-09-17 新增：同一 agentCode 在不同章节可能是借款人/担保人两种口径，入参不同结果不同，必须有此列区分';

-- =====================================================================
-- 校验（执行后应返回 1 行、is_nullable = YES）
-- =====================================================================
-- SELECT column_name, data_type, character_maximum_length, is_nullable
--   FROM information_schema.columns
--  WHERE table_name = 'app_report_content_block' AND column_name = 'agentparams';
-- =====================================================================
