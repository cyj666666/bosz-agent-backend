-- =============================================================================
-- 报告预警建议明细表 app_report_warning_advice
-- =============================================================================
-- 用途：承载「预警建议」的**每一条预警信号**（一行=一条），是「采纳/不采纳」的操作对象。
-- 为什么逐条独立成行：采纳与否是**一条信号一个决定**，必须能单独改状态、单独记处理人与时间。
-- 与批次表的关系：app_report_warning_advice_batch 1 : N 本表（batchId）。
-- 等级码值：RED-红色预警 / ORANGE-橙色预警 / YELLOW-黄色预警（前端映射中文展示）。
-- 处理状态：PENDING-待处理 / ADOPTED-已采纳 / INVALID-无效（与 AI 风险要点同一套三态口径）。
-- 约定：不使用 IF NOT EXISTS；不使用反引号 / ENGINE / CHARSET；
--       camelCase 列名（实体必须显式 @TableField）；COMMENT ON 独立语句；索引名全库唯一。
-- =============================================================================

CREATE TABLE app_report_warning_advice (
    id                 BIGINT        NOT NULL AUTO_INCREMENT,
    batchId            BIGINT        NOT NULL,
    reportNo           VARCHAR(64)   NOT NULL,
    seqNo              INT,
    warningLevel       VARCHAR(16)   NOT NULL,
    signalDesc         TEXT,
    triggerCondition   TEXT,
    sourceText         TEXT,
    riskDesc           TEXT,
    chapter            VARCHAR(256),
    status             VARCHAR(16)   NOT NULL,
    operatorNo         VARCHAR(64),
    operatorName       VARCHAR(128),
    operateTime        TIMESTAMP,
    inputtime          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE INDEX idx_wa_batch ON app_report_warning_advice (batchId, seqNo);
CREATE INDEX idx_wa_report_no ON app_report_warning_advice (reportNo);

COMMENT ON TABLE app_report_warning_advice IS '报告预警建议明细表（一行=一条预警信号，逐条采纳/不采纳）';
COMMENT ON COLUMN app_report_warning_advice.id IS '主键ID';
COMMENT ON COLUMN app_report_warning_advice.batchId IS '所属批次（app_report_warning_advice_batch.id）';
COMMENT ON COLUMN app_report_warning_advice.reportNo IS '报告编号（冗余，便于直接按报告查询）';
COMMENT ON COLUMN app_report_warning_advice.seqNo IS '序号（模型输出顺序，已按红>橙>黄排序）';
COMMENT ON COLUMN app_report_warning_advice.warningLevel IS '建议预警等级：RED-红色 / ORANGE-橙色 / YELLOW-黄色';
COMMENT ON COLUMN app_report_warning_advice.signalDesc IS '预警信号描述';
COMMENT ON COLUMN app_report_warning_advice.triggerCondition IS '触发条件/判断依据';
COMMENT ON COLUMN app_report_warning_advice.sourceText IS '原文依据（引用原文关键句）';
COMMENT ON COLUMN app_report_warning_advice.riskDesc IS '风险点描述（未关联到风险点时为空）';
COMMENT ON COLUMN app_report_warning_advice.chapter IS '所在章节/段落';
COMMENT ON COLUMN app_report_warning_advice.status IS '处理状态：PENDING-待处理 / ADOPTED-已采纳 / INVALID-无效';
COMMENT ON COLUMN app_report_warning_advice.operatorNo IS '处理人账号';
COMMENT ON COLUMN app_report_warning_advice.operatorName IS '处理人姓名';
COMMENT ON COLUMN app_report_warning_advice.operateTime IS '处理时间';
COMMENT ON COLUMN app_report_warning_advice.inputtime IS '创建时间';
