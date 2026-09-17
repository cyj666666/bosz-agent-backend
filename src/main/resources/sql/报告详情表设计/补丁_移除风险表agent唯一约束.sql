-- =====================================================================
-- 补丁：移除 app_report_ai_risk 的 (reportNo, agentCode) 唯一约束
-- 数据库：高斯DB（GaussDB/openGauss）
-- 日期  ：2026-09-17
--
-- 背景（原设计已预判，见 报告详情表_实例层设计_v1.sql 第 103 行原注释）：
--   「两条约束互为印证；若将来出现"一条规则命中多个内容块"，需先移除 agent 唯一约束。」
--
--   这个场景现在到了。报告模板（依据《报告详情设计.xlsx》）里，
--   **同一个 agentCode 会在不同章节合法复用**，典型是征信类规则：
--     · 六、征信情况和潜在风险          → 借款人 口径（入参 entName）
--     · 十二、（二）担保人征信信息      → 担保人 口径（入参 entName + guarantorName，多担保人轮循）
--   两处是同一 ruleCode、不同入参、不同结果，必须各生成一条风险明细，
--   否则第二条会被 (reportNo, agentCode) 唯一索引拦下 → 报告生成整体报错。
--
--   行身份本来就是 (reportNo, blockCode)，而 blockCode 全局唯一（uk_report_block_code），
--   所以只保留 report_block 那条唯一约束即可；agentCode 降为普通索引，仅用于查询。
--
-- 幂等性：无（DROP INDEX 重复执行会报 "index ... does not exist"，属正常）
-- =====================================================================

DROP INDEX uk_report_ai_risk_report_agent;

-- 保留查询用普通索引（若已存在会报 already exists，跳过即可）
CREATE INDEX idx_report_ai_risk_agent ON app_report_ai_risk (reportNo, agentCode);

-- =====================================================================
-- 校验（执行后应只剩 1 条唯一索引：uk_report_ai_risk_report_block）
-- =====================================================================
-- SELECT indexname, indexdef
--   FROM pg_indexes
--  WHERE tablename = 'app_report_ai_risk'
--  ORDER BY indexname;
-- =====================================================================
