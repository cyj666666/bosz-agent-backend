-- =============================================================================
-- 报告 AI 全文分析表 app_report_ai_analysis
-- =============================================================================
-- 用途：承载报告详情页右侧「AI分析全文」的结果与执行状态。
-- 生成方式：**前端手动触发** → 后台独立线程池异步执行 → 前端按状态轮询。
-- 归档维度：**挂在报告编号 reportNo 上，保留多次**（同一版本可反复分析，按 id 倒序取最新一次）。
-- 并发约束：同一 reportNo 同时只允许一条 status='RUNNING'（应用层校验，不加唯一约束）。
-- 约定：不使用 IF NOT EXISTS；不使用反引号 / ENGINE / CHARSET；
--       camelCase 列名（实体必须显式 @TableField）；COMMENT ON 独立语句；索引名全库唯一。
-- =============================================================================

CREATE TABLE app_report_ai_analysis (
    id                 BIGINT        NOT NULL AUTO_INCREMENT,
    reportNo           VARCHAR(64)   NOT NULL,
    checkTaskNo        VARCHAR(64)   NOT NULL,
    customerId         VARCHAR(64),
    customerName       VARCHAR(128),
    status             VARCHAR(16)   NOT NULL,
    analysisContent    TEXT,
    summary            TEXT,
    riskLevel          VARCHAR(32),
    lmCode             VARCHAR(100),
    modelName          VARCHAR(100),
    sourceSnapshot     TEXT,
    promptSnapshot     TEXT,
    operatorNo         VARCHAR(64),
    operatorName       VARCHAR(128),
    costMillis         BIGINT,
    failReason         VARCHAR(1024),
    generateTime       TIMESTAMP,
    inputtime          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE INDEX idx_ai_analysis_report_no ON app_report_ai_analysis (reportNo, id);
CREATE INDEX idx_ai_analysis_task_no ON app_report_ai_analysis (checkTaskNo, inputtime);
CREATE INDEX idx_ai_analysis_status ON app_report_ai_analysis (status);

COMMENT ON TABLE app_report_ai_analysis IS '报告AI全文分析表（挂在报告编号上、保留多次，同一报告同时只允许一次进行中）';
COMMENT ON COLUMN app_report_ai_analysis.id IS '主键ID';
COMMENT ON COLUMN app_report_ai_analysis.reportNo IS '报告编号（归档维度，同一报告可保留多次分析记录）';
COMMENT ON COLUMN app_report_ai_analysis.checkTaskNo IS '日检流水号（冗余，便于按流水号追溯）';
COMMENT ON COLUMN app_report_ai_analysis.customerId IS '客户编号';
COMMENT ON COLUMN app_report_ai_analysis.customerName IS '客户名称';
COMMENT ON COLUMN app_report_ai_analysis.status IS '分析状态：RUNNING-进行中 / DONE-已完成 / FAILED-失败';
COMMENT ON COLUMN app_report_ai_analysis.analysisContent IS '分析正文（成品HTML片段，前端直接渲染）';
COMMENT ON COLUMN app_report_ai_analysis.summary IS '综合结论摘要';
COMMENT ON COLUMN app_report_ai_analysis.riskLevel IS '大模型给出的总体风险等级';
COMMENT ON COLUMN app_report_ai_analysis.lmCode IS '所用大模型配置编码（large_model_config.lm_code）';
COMMENT ON COLUMN app_report_ai_analysis.modelName IS '实际调用的模型名';
COMMENT ON COLUMN app_report_ai_analysis.sourceSnapshot IS '送进大模型的素材快照（正文摘取 + 外部数据，便于追溯与复算）';
COMMENT ON COLUMN app_report_ai_analysis.promptSnapshot IS '实际使用的提示词快照';
COMMENT ON COLUMN app_report_ai_analysis.operatorNo IS '触发人账号';
COMMENT ON COLUMN app_report_ai_analysis.operatorName IS '触发人姓名';
COMMENT ON COLUMN app_report_ai_analysis.costMillis IS '大模型调用耗时（毫秒）';
COMMENT ON COLUMN app_report_ai_analysis.failReason IS '失败原因（超1000字符截断）';
COMMENT ON COLUMN app_report_ai_analysis.generateTime IS '分析完成时间';
COMMENT ON COLUMN app_report_ai_analysis.inputtime IS '创建时间';
