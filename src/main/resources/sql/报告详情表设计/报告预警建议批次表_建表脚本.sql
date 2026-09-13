-- =============================================================================
-- 报告预警建议批次表 app_report_warning_advice_batch
-- =============================================================================
-- 用途：承载「预警建议」每一次生成的**批次级**信息。
-- 生成方式：**前端手动触发** → 后台线程池异步执行 → 前端按状态轮询。
-- 归档维度：挂在报告编号 reportNo 上，保留多次（同一报告可反复生成，按 id 倒序取最新批次）。
-- 为什么单独一张批次表（而不是并进明细表）：
--   ① 模型调用失败时**一条明细都没有**，「失败状态 + 失败原因」无处可写；
--   ② 「核心提示」一次生成只有一句，并进明细表就得在 N 行里重复 N 遍。
-- 与明细表的关系：batch 1 : N advice（app_report_warning_advice.batchId）。
-- 并发约束：同一 reportNo 同时只允许一条 status='RUNNING'（应用层校验，不加唯一约束）。
-- 约定：不使用 IF NOT EXISTS；不使用反引号 / ENGINE / CHARSET；
--       camelCase 列名（实体必须显式 @TableField）；COMMENT ON 独立语句；索引名全库唯一。
-- =============================================================================

CREATE TABLE app_report_warning_advice_batch (
    id                 BIGINT        NOT NULL AUTO_INCREMENT,
    reportNo           VARCHAR(64)   NOT NULL,
    checkTaskNo        VARCHAR(64)   NOT NULL,
    analysisId         BIGINT,
    customerId         VARCHAR(64),
    customerName       VARCHAR(128),
    status             VARCHAR(16)   NOT NULL,
    coreTip            TEXT,
    promptCode         VARCHAR(64),
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

CREATE INDEX idx_wa_batch_report_no ON app_report_warning_advice_batch (reportNo, id);
CREATE INDEX idx_wa_batch_task_no ON app_report_warning_advice_batch (checkTaskNo, inputtime);
CREATE INDEX idx_wa_batch_status ON app_report_warning_advice_batch (status);

COMMENT ON TABLE app_report_warning_advice_batch IS '报告预警建议批次表（一行=一次生成，承载状态/核心提示/模型信息/失败原因）';
COMMENT ON COLUMN app_report_warning_advice_batch.id IS '主键ID';
COMMENT ON COLUMN app_report_warning_advice_batch.reportNo IS '报告编号（归档维度，同一报告可保留多次）';
COMMENT ON COLUMN app_report_warning_advice_batch.checkTaskNo IS '日检流水号（冗余，便于按流水号追溯）';
COMMENT ON COLUMN app_report_warning_advice_batch.analysisId IS '基于哪一次全文分析生成（app_report_ai_analysis.id）；为空表示生成时该报告尚无成功的全文分析';
COMMENT ON COLUMN app_report_warning_advice_batch.customerId IS '客户编号';
COMMENT ON COLUMN app_report_warning_advice_batch.customerName IS '客户名称';
COMMENT ON COLUMN app_report_warning_advice_batch.status IS '生成状态：RUNNING-进行中 / DONE-已完成 / FAILED-失败';
COMMENT ON COLUMN app_report_warning_advice_batch.coreTip IS '核心提示（模型总结，1~3句话概括最需关注的风险）';
COMMENT ON COLUMN app_report_warning_advice_batch.promptCode IS '所用提示词编码（app_report_prompt.promptCode）';
COMMENT ON COLUMN app_report_warning_advice_batch.lmCode IS '所用大模型配置编码（large_model_config.lm_code）';
COMMENT ON COLUMN app_report_warning_advice_batch.modelName IS '实际调用的模型名';
COMMENT ON COLUMN app_report_warning_advice_batch.sourceSnapshot IS '送进大模型的素材快照（便于追溯与复算）';
COMMENT ON COLUMN app_report_warning_advice_batch.promptSnapshot IS '实际使用的提示词快照';
COMMENT ON COLUMN app_report_warning_advice_batch.operatorNo IS '触发人账号';
COMMENT ON COLUMN app_report_warning_advice_batch.operatorName IS '触发人姓名';
COMMENT ON COLUMN app_report_warning_advice_batch.costMillis IS '大模型调用耗时（毫秒）';
COMMENT ON COLUMN app_report_warning_advice_batch.failReason IS '失败原因（超1000字符截断）';
COMMENT ON COLUMN app_report_warning_advice_batch.generateTime IS '生成完成时间';
COMMENT ON COLUMN app_report_warning_advice_batch.inputtime IS '创建时间';
