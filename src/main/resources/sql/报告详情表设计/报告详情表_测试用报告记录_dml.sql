-- =====================================================================
-- 报告生成流程 · 测试用报告记录（DML）
-- 数据库：高斯DB（GaussDB）
-- 用途  ：报告记录本应由上游预生成（初始状态 111-待开始）。本脚本插入一条测试记录，
--         用于手工调用生成接口走通"报告实例加工"全流程。
-- 表    ：report（原 app_report_info 已弃用，报告主表统一落到 report）
-- 调用  ：POST /api/report/instance/generate?reportNo=RPT20260911000001
--         生成成功后 status：111 → 000 → 888；异常则 999。
-- 日期  ：2026-09-11
-- =====================================================================

INSERT INTO report (report_no, customer_id, customer_name, report_title, report_type, check_task_no, status) VALUES
('RPT20260911000001', 'CUST0001', '泰州三有建设工程有限公司', '泰州三有建设工程有限公司贷后管理定期检查报告', '贷后管理报告', 'TASK20260911001', '111');


-- =====================================================================
-- 重复演练用（首次执行不需要）：把状态改回 111 并清掉该报告的实例数据，即可再跑一次
-- —— 因为生成本身不做重跑清理，同一 reportNo 重复生成会撞实例表的唯一键。
-- =====================================================================
-- UPDATE report SET status = '111', fail_reason = NULL WHERE report_no = 'RPT20260911000001';
-- DELETE FROM app_report_content_instance WHERE reportNo = 'RPT20260911000001';
-- DELETE FROM app_report_ai_risk WHERE reportNo = 'RPT20260911000001';
