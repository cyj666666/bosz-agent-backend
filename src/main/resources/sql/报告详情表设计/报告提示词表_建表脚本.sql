-- =============================================================================
-- 报告提示词表 app_report_prompt
-- =============================================================================
-- 用途：把「AI 全文分析」「预警建议」等场景的提示词从代码里挪到表里，改提示词不用改代码、不用发版。
-- 取用方式：**每次调用时按 promptCode 查表**（与 large_model_config 相同的习惯，改完立即生效）；
--          表里查不到或 isEnabled != 'Y' 时，自动回落到代码里的兜底提示词常量
--          （兜底见 ReportAiAnalysisPrompt / ReportWarningAdvicePrompt），所以空库也能跑。
-- 变量占位：userPromptTemplate 里用 {material} 占位，调用时整段替换为组装好的素材。
-- 约定：不使用 IF NOT EXISTS；不使用反引号 / ENGINE / CHARSET；
--       camelCase 列名（实体必须显式 @TableField）；COMMENT ON 独立语句；索引名全库唯一。
-- =============================================================================

CREATE TABLE app_report_prompt (
    id                 BIGINT        NOT NULL AUTO_INCREMENT,
    promptCode         VARCHAR(64)   NOT NULL,
    promptName         VARCHAR(128),
    sceneType          VARCHAR(32),
    systemPrompt       TEXT,
    userPromptTemplate TEXT,
    isEnabled          VARCHAR(2)    DEFAULT 'Y' NOT NULL,
    remark             VARCHAR(512),
    inputtime          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updateTime         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX uk_report_prompt_code ON app_report_prompt (promptCode);

COMMENT ON TABLE app_report_prompt IS '报告提示词表（按 promptCode 取用，改提示词无需改代码；查不到回落到代码兜底常量）';
COMMENT ON COLUMN app_report_prompt.id IS '主键ID';
COMMENT ON COLUMN app_report_prompt.promptCode IS '提示词编码（唯一）：AI_FULL_ANALYSIS-全文分析 / WARNING_ADVICE-预警建议';
COMMENT ON COLUMN app_report_prompt.promptName IS '提示词名称（界面展示用）';
COMMENT ON COLUMN app_report_prompt.sceneType IS '场景分类（AI_ANALYSIS 等，便于分组管理）';
COMMENT ON COLUMN app_report_prompt.systemPrompt IS '系统提示词（角色、要求、输出格式）';
COMMENT ON COLUMN app_report_prompt.userPromptTemplate IS '用户提示词模板，用 {material} 占位，调用时替换为素材';
COMMENT ON COLUMN app_report_prompt.isEnabled IS '是否启用：Y-启用 N-停用（停用则回落到代码兜底常量）';
COMMENT ON COLUMN app_report_prompt.remark IS '备注';
COMMENT ON COLUMN app_report_prompt.inputtime IS '创建时间';
COMMENT ON COLUMN app_report_prompt.updateTime IS '更新时间';
