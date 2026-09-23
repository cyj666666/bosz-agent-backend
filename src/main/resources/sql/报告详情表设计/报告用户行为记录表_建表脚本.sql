-- =====================================================================
-- 报告详情页 · 用户行为记录表（审计流水）DDL
-- 数据库   ：GaussDB / openGauss（风格同 20260921 建表脚本）
-- 日期     ：2026-09-23（来源：20260923 测试问题统计 #6）
-- 用途     ：记录「AI 风险要点」与「预警建议」的**采纳 / 无效 / 恢复待处理**人工操作，
--            回答"谁、什么时候、把哪一条、从什么状态改成了什么状态"。
--
-- 归档维度 ：checkTaskNo（日检流水号） + targetType（对象类型） + targetCode（对象编号）
--            与 app_report_risk_edit_log 同一套归档思路 ⇒ 可**跨版本追溯**
--            （同一日检流水号下各版本共用模板 blockCode，按 reportNo 归档则换版即断）。
--
-- 写入时机 ：POST /api/report/instance/risk/status          （AI 风险）
--            POST /api/report/instance/warning-advice/status（预警建议）
--            两个接口在状态更新成功后**尽力追加**一条 —— 留痕失败只打 ERROR，
--            ⛔ 不影响操作结果（用户点了采纳就该看到成功，不能因为日志写不进去而回滚）。
--
-- 🔴 为什么单独建表，而不给两张业务表各加 operator 列：
--    ① 业务表只能留住"最后一次是谁处理的"，改回来就没了；本表是流水，能追溯变更历史；
--    ② app_report_ai_risk 原本连 operator 列都没有，加列要动存量表结构 ——
--       而行内的存量表结构是不能随便动的。新建表不动任何既有表。
--
-- 约定：不使用 IF NOT EXISTS；不使用反引号 / ENGINE / CHARSET；
--       camelCase 列名（实体必须显式 @TableField）；COMMENT ON 独立语句；索引名全库唯一。
-- =====================================================================

CREATE TABLE app_report_action_log (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    checkTaskNo     VARCHAR(64),
    reportNo        VARCHAR(64) NOT NULL,
    targetType      VARCHAR(32) NOT NULL,
    targetId        BIGINT,
    targetCode      VARCHAR(64),
    targetName      VARCHAR(512),
    statusBefore    VARCHAR(32),
    statusAfter     VARCHAR(32) NOT NULL,
    operatorNo      VARCHAR(64),
    operatorName    VARCHAR(128),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

-- 归档查询主路径：同日检流水号 + 同对象类型 + 同对象编号，按操作时间倒序（详情页"操作历史"用）
CREATE INDEX idx_actionlog_task_target ON app_report_action_log (checkTaskNo, targetType, targetCode, inputtime);

-- 按报告编号追溯：某次操作发生在哪一版报告上
CREATE INDEX idx_actionlog_report_no ON app_report_action_log (reportNo);

-- 按人查：某人做过哪些操作（行为审计）
CREATE INDEX idx_actionlog_operator ON app_report_action_log (operatorNo, inputtime);

COMMENT ON TABLE app_report_action_log IS '报告详情-用户行为记录表（AI风险 / 预警建议 的采纳·无效流水，只增不改）';
COMMENT ON COLUMN app_report_action_log.id IS '主键（自增）';
COMMENT ON COLUMN app_report_action_log.checkTaskNo IS '日检流水号（归档维度①，跨版本追溯用；取不到 report 时为空）';
COMMENT ON COLUMN app_report_action_log.reportNo IS '产生本次操作的报告编号（定位到哪一版）';
COMMENT ON COLUMN app_report_action_log.targetType IS '行为对象类型：AI_RISK-AI风险要点 / WARNING_ADVICE-预警建议';
COMMENT ON COLUMN app_report_action_log.targetId IS '行为对象主键（app_report_ai_risk.id / app_report_warning_advice.id）';
COMMENT ON COLUMN app_report_action_log.targetCode IS '行为对象业务编号（AI风险=blockCode / 预警建议=seqNo）';
COMMENT ON COLUMN app_report_action_log.targetName IS '行为对象名称（AI风险=规则名 / 预警建议=预警信号描述，超长截断到 500）';
COMMENT ON COLUMN app_report_action_log.statusBefore IS '变更前状态（ADOPTED / INVALID / PENDING）';
COMMENT ON COLUMN app_report_action_log.statusAfter IS '变更后状态（ADOPTED-已采纳 / INVALID-无效 / PENDING-待处理）';
COMMENT ON COLUMN app_report_action_log.operatorNo IS '操作人账号';
COMMENT ON COLUMN app_report_action_log.operatorName IS '操作人姓名（取 sys_user.real_name，取不到回落账号）';
COMMENT ON COLUMN app_report_action_log.inputtime IS '操作时间（默认当前时间）';

-- =====================================================================
-- 复核（建完看一眼，两张表都要有）
-- =====================================================================
-- SELECT table_name FROM information_schema.tables
--  WHERE lower(table_name) IN ('app_report_action_log')
--    AND table_schema = current_schema();
