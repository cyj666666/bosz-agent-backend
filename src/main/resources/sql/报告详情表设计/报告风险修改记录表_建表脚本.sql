-- =====================================================================
-- 报告详情页 · 风险要点修改记录表（归档表）DDL
-- 数据库   ：高斯DB（GaussDB，风格同 20260819 建表脚本）
-- 用途     ：记录「规则类正文（AI 风险要点）」的人工修改历史，供报告详情页展示「修改记录」。
--
-- 归档维度 ：checkTaskNo（日检流水号） + blockCode（风险要点 = 内容块编号）
--            同一日检流水号下各版本共用同一套 blockCode（blockCode 来自模板），
--            故按此维度归档可**跨版本追溯**；若按 reportNo 归档，换版本后历史就断了。
--
-- 写入时机 ：POST /api/report/instance/block/content 修改正文成功时，
--            与内容实例的 content 更新**同事务**插入一条记录；
--            · 仅当内容确实发生变化时写入（点开编辑器原样保存不产生记录）
--            · 只记录人工修改，不含 AI 生成原文
-- 读取     ：GET /api/report/instance/block/edit-history?checkTaskNo=&blockCode=
--            （按 inputtime 倒序，最新在上；序号由前端拼 1..n）
--
-- 展示文案 ：N、{operatorName} {inputtime} 修改为：{contentAfter}
-- =====================================================================

CREATE TABLE app_report_risk_edit_log (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    checkTaskNo     VARCHAR(64) NOT NULL,
    blockCode       VARCHAR(64) NOT NULL,
    reportNo        VARCHAR(64) NOT NULL,
    blockName       VARCHAR(128),
    catalogCode     VARCHAR(64),
    customerId      VARCHAR(64),
    customerName    VARCHAR(128),
    contentBefore   TEXT,
    contentAfter    TEXT NOT NULL,
    operatorNo      VARCHAR(64),
    operatorName    VARCHAR(128),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

-- 归档查询主路径：同日检流水号 + 同风险要点，按修改时间倒序
CREATE INDEX idx_editlog_task_block ON app_report_risk_edit_log (checkTaskNo, blockCode, inputtime);

-- 按报告编号追溯：某次修改发生在哪一版报告上
CREATE INDEX idx_editlog_report_no ON app_report_risk_edit_log (reportNo);

COMMENT ON TABLE app_report_risk_edit_log IS '报告详情-风险要点修改记录表（归档维度：同日检流水号 + 同风险要点）';
COMMENT ON COLUMN app_report_risk_edit_log.id IS '主键（自增）';
COMMENT ON COLUMN app_report_risk_edit_log.checkTaskNo IS '日检流水号（归档维度①，跨版本追溯用）';
COMMENT ON COLUMN app_report_risk_edit_log.blockCode IS '风险要点编号（=内容块编号，归档维度②）';
COMMENT ON COLUMN app_report_risk_edit_log.reportNo IS '产生本次修改的报告编号（追溯是哪一版改的）';
COMMENT ON COLUMN app_report_risk_edit_log.blockName IS '风险要点名称（冗余，便于单独展示）';
COMMENT ON COLUMN app_report_risk_edit_log.catalogCode IS '所属目录编号（冗余）';
COMMENT ON COLUMN app_report_risk_edit_log.customerId IS '客户编号（冗余）';
COMMENT ON COLUMN app_report_risk_edit_log.customerName IS '客户名称（冗余）';
COMMENT ON COLUMN app_report_risk_edit_log.contentBefore IS '修改前文案（审计对比用）';
COMMENT ON COLUMN app_report_risk_edit_log.contentAfter IS '修改后文案（列表展示用）';
COMMENT ON COLUMN app_report_risk_edit_log.operatorNo IS '修改人账号';
COMMENT ON COLUMN app_report_risk_edit_log.operatorName IS '修改人姓名（取 sys_user.real_name，取不到回落账号）';
COMMENT ON COLUMN app_report_risk_edit_log.inputtime IS '修改时间（默认当前时间）';
