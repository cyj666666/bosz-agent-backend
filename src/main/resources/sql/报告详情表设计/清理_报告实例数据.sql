-- =====================================================================
-- 清理脚本：按「报告编号」清掉一次报告加工产生的实例数据
-- 数据库：高斯DB（GaussDB/openGauss）
-- 日期  ：2026-09-17
--
-- 用途：重跑一次报告加工前的清理。典型场景：
--   · 忘了改 report.mock-content.enabled（或忘了重启）→ 这次用的是 mock 样例内容，
--     要清掉重跑；
--   · 模板 / 知识配置 / 规则改完了，想用同一个 reportNo 重跑。
--
-- 🔴 为什么必须「删掉 → 重新发起」，而不是在详情页点「更新报告」：
--   `renew()` 固定调用 `generateReportNo()` 生成**新号**，且不接受自定义编号。
--   而 app_* 取数表全部是按 `reportno` 关联数据的
--   （指标 SQL 形如 `WHERE customername = :entName AND reportno = :reportNo`）。
--   换号以后，新版本取数取到的是**空**（上游没有按新号落过数据；
--   行内那套采集编排 `ReportDataCollectOrchestrator` 外网没有）。
--   ⇒ 自测阶段想复用同一套造数数据，只能：**删掉旧记录 → 重新「发起」→ 手填同一个 reportNo**。
--
-- 一次「发起」会写到哪些表：
--   ① report                            报告主表（1 行）
--   ② app_report_content_instance       内容实例（= 启用块数；新模板 156）
--   ③ app_report_ai_risk                AI 风险（= 命中的规则条数，≤48）
--   ④ app_report_risk_edit_log          正文修改记录（**按 checkTaskNo 归档**，见第 2 步）
--   ⑤ app_report_ai_analysis            AI 全文分析（手动点过才有）
--   ⑥ app_report_warning_advice(_batch) 预警建议（手动点过才有）
--
-- ⛔ **本脚本不动的表**（不是按报告存的，删了会伤到别的报告 / 全局配置）：
--   · app_report_prompt                        提示词（全局）
--   · app_report_catalog / app_report_content_block   模板层
--   · app_customer_info / app_guarantor_info 等 app_* 业务数据表（那是取数源，不能删！）
--
-- ⚠️ 列名两种风格（写错就报"列不存在"）：
--   report 表 → snake_case（report_no / check_task_no）
--   其余 app_report_* → **不加引号的小写驼峰**（reportno / checktaskno / blockcode）
-- =====================================================================


-- =====================================================================
-- 第 0 步：先看清楚要清的是哪一条（**确认后再删**）
-- =====================================================================

SELECT id, report_no, check_task_no, customer_id, customer_name,
       status, version, fail_reason, created_at, updated_at
  FROM report
 WHERE report_no = 'RPT-202603-001';          -- ← 改成你要清的报告编号

-- 不记得编号了？按客户名 / 时间倒序找：
-- SELECT id, report_no, check_task_no, customer_name, status, version, created_at
--   FROM report
--  WHERE customer_name = '苏州XX精密机械制造有限公司'
--  ORDER BY id DESC;

-- 顺带看一眼"到底落了多少数据"（这三个数就是"这次跑没跑、跑出多少"的直接证据）：
-- SELECT (SELECT count(*) FROM app_report_content_instance WHERE reportno = 'RPT-202603-001') AS 内容实例,
--        (SELECT count(*) FROM app_report_ai_risk          WHERE reportno = 'RPT-202603-001') AS AI风险,
--        (SELECT count(*) FROM app_report_ai_analysis      WHERE reportno = 'RPT-202603-001') AS 全文分析;


-- =====================================================================
-- 第 1 步：清理「必删」的 3 张表（每次加工都会有）
-- =====================================================================

BEGIN;

DELETE FROM app_report_content_instance WHERE reportno = 'RPT-202603-001';
DELETE FROM app_report_ai_risk          WHERE reportno = 'RPT-202603-001';
DELETE FROM report                      WHERE report_no = 'RPT-202603-001';

-- 确认每个 DELETE 的影响行数符合预期（156 / 命中的条数 / 1）后再提交
COMMIT;
-- 不对就 ROLLBACK;


-- =====================================================================
-- 第 2 步（按需）：只有"手动触发过"才会有数据的表
--
-- ⚠️ 这几张表**本地不一定建过**（DDL 在仓库里，但不一定执行过）。
--    表不存在时 DELETE 会报错 —— 所以默认**注释掉**，你用过哪个就打开哪个。
-- =====================================================================

-- ② 正文修改记录：**归档维度是 checkTaskNo + blockCode**（跨版本追溯），
--    所以这里要用**日检流水号**删；只按 reportno 删会留下本次产生的记录，
--    并被下一版当成"历史修改"显示出来（详情页会出现莫名的「修改记录(N)」）。
-- DELETE FROM app_report_risk_edit_log WHERE checktaskno = '你的日检流水号';

-- ③ AI 全文分析（详情页点过「智能体分析」才有）
-- DELETE FROM app_report_ai_analysis WHERE reportno = 'RPT-202603-001';

-- ④ 预警建议：明细表也冗余了 reportno，可以直接按它删（不必绕 batchId）
-- DELETE FROM app_report_warning_advice       WHERE reportno = 'RPT-202603-001';
-- DELETE FROM app_report_warning_advice_batch WHERE reportno = 'RPT-202603-001';


-- =====================================================================
-- 第 3 步：复核（应全部为 0）
-- =====================================================================

SELECT '0_报告主表'   AS 表, count(*) AS 剩余行数 FROM report                         WHERE report_no = 'RPT-202603-001'
UNION ALL SELECT '1_内容实例', count(*) FROM app_report_content_instance WHERE reportno = 'RPT-202603-001'
UNION ALL SELECT '2_AI风险',   count(*) FROM app_report_ai_risk          WHERE reportno = 'RPT-202603-001';


-- =====================================================================
-- 附：清完之后的正确重跑步骤（顺序不能错）
-- ---------------------------------------------------------------------
--   1. 确认 report.mock-content.enabled = false（已配在 application-dev.yml）
--   2. **重启后端**（@ConditionalOnProperty 是启动期判定的，不重启不生效）
--   3. 列表页「发起报告」，六项这样填：
--        客户编号   CUST-001
--        客户名称   苏州XX精密机械制造有限公司      ← 直接当 entName 用
--        日检流水号 任意（如 TASK20260917002）
--        报告标题/类型 用默认值即可
--        报告编号   RPT-202603-001                  ← 🔴 必须填它，才能对上造数数据
--   4. 看日志 `【报告内容加工】`，再按第 3 步复核表
-- =====================================================================
