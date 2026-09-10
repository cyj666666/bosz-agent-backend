-- =====================================================================
-- 报告详情页 · 实例层表结构 DDL（v1，高斯DB版）
-- 数据库   ：高斯DB（GaussDB，风格同 20260819 建表脚本）
-- 生成依据 ：模板层两张表
--            · app_report_catalog        （目录表）
--            · app_report_content_block  （内容块表）
-- 上级表   ：app_report_info（报告主表，reportNo 关联，不重复建报告实例表）
-- 实例层共 2 张表：
--   1) app_report_content_instance  内容实例表
--        一条内容块 → 一条实例；TITLE/TEXT/TABLE/SOURCE_LINK 的内容一律落在 content 大字段；
--        表格等内容为前置加工好的成品片段，直接存文本，前端不解析结构。
--   2) app_report_ai_risk           AI 风险实例表（即 analysisType=RULE 经验规则类的内容体）
--        RULE 类内容块不落 content，改为逐条风险明细，每条含可编辑文案 + 处置状态。
-- 说明     ：目录不单独建实例表 —— 前端按内容实例的 catalogCode 聚合 + 模板目录属性渲染目录树；
--            某目录下内容块全部为空且 emptyStrategy=HIDE 时，该目录自然不出现。
-- 设计要点 ：
--    ① 实例表结构性字段（fillType/analysisType/agentCode/titleLevel/sortNo/catalogCode）
--       是生成时从模板快照过来的，目的是渲染一次查询、不 join 模板，且模板改版不污染历史报告。
--    ② 跳转锚点是单向的：只存"本块 → 目标锚点"，不存反向关系。
--    ③ AI 风险与内容块的关联：agentCode 为业务关联键（两侧同值），blockCode 为落地定位键。
-- 日期     ：2026-09-10
-- =====================================================================


-- ============================================================
-- 一、内容实例表
--    填充类型与 content 的对应：
--        TITLE       - 标题文案（报告头公司名等；titleLevel 区分主/章/节标题）
--        TEXT        - 分析文本（analysisType=ANALYSIS）
--        TABLE       - 表格成品内容
--        SOURCE_LINK - 溯源面板内容（被正文块的 jumpAnchorCode 单向指向）
--    analysisType=RULE 的经验规则类内容块：content 为空，内容体见 app_report_ai_risk。
-- ============================================================

CREATE TABLE app_report_content_instance (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    customerName    VARCHAR(128),
    blockCode       VARCHAR(64) NOT NULL,
    catalogCode     VARCHAR(64),
    fillType        VARCHAR(16) NOT NULL,
    analysisType    VARCHAR(16),
    agentCode       VARCHAR(64),
    titleLevel      SMALLINT,
    sortNo          INT DEFAULT 0,
    anchorCode      VARCHAR(64),
    jumpAnchorCode  VARCHAR(64),
    content         TEXT,
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_report_content_instance IS '报告详情-内容实例表（实例层·由内容块表生成）';
COMMENT ON COLUMN app_report_content_instance.id IS '主键（自增）';
COMMENT ON COLUMN app_report_content_instance.reportNo IS '报告编号（关联 app_report_info.reportNo）';
COMMENT ON COLUMN app_report_content_instance.customerId IS '客户编号';
COMMENT ON COLUMN app_report_content_instance.customerName IS '客户名称';
COMMENT ON COLUMN app_report_content_instance.blockCode IS '内容块编号（关联 app_report_content_block.blockCode）';
COMMENT ON COLUMN app_report_content_instance.catalogCode IS '所属目录编号（报告级内容块（如报告头）为NULL）';
COMMENT ON COLUMN app_report_content_instance.fillType IS '填充类型（生成时自模板快照）：TITLE-标题 TEXT-文本 TABLE-表格 SOURCE_LINK-溯源链接';
COMMENT ON COLUMN app_report_content_instance.analysisType IS '分析文本类型（自模板快照）：RULE-经验规则类 ANALYSIS-文本分析类；RULE 类 content 为空，见 app_report_ai_risk';
COMMENT ON COLUMN app_report_content_instance.agentCode IS '智能体编码（自模板快照；与 AI 风险实例的关联键）';
COMMENT ON COLUMN app_report_content_instance.titleLevel IS '标题级别（自模板快照）：1-报告主标题 2-章节标题 3-小节标题';
COMMENT ON COLUMN app_report_content_instance.sortNo IS '排序（自模板快照，同一目录内）';
COMMENT ON COLUMN app_report_content_instance.anchorCode IS '锚点编码：本块在报告内的定位锚点（默认取 blockCode），供跳转定位与 AI 风险关联使用';
COMMENT ON COLUMN app_report_content_instance.jumpAnchorCode IS '跳转锚点（单向）：点击本块时跳转到的目标块 anchorCode；无跳转则为NULL';
COMMENT ON COLUMN app_report_content_instance.content IS '内容（大文本）：TITLE-标题文案 TEXT-分析文本 TABLE-表格内容 SOURCE_LINK-溯源内容；RULE 类为空';
COMMENT ON COLUMN app_report_content_instance.inputtime IS '入库时间';

CREATE UNIQUE INDEX uk_report_ci_report_block ON app_report_content_instance (reportNo, blockCode);
CREATE INDEX idx_report_ci_report ON app_report_content_instance (reportNo);
CREATE INDEX idx_report_ci_anchor ON app_report_content_instance (reportNo, anchorCode);
CREATE INDEX idx_report_ci_catalog ON app_report_content_instance (reportNo, catalogCode);


-- ============================================================
-- 二、AI 风险实例表（经验规则类内容块的内容体）
--    一个 RULE 类内容块 → N 条风险明细（一条经验规则命中 = 一条）。
--    支持前端编辑：编辑后文案覆盖 riskDesc，原始生成文案留在 rawRiskDesc。
--    处置状态：PENDING-待处理 ADOPTED-已采纳 INVALID-已无效。
-- ============================================================

CREATE TABLE app_report_ai_risk (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    customerName    VARCHAR(128),
    riskCode        VARCHAR(64) NOT NULL,
    blockCode       VARCHAR(64) NOT NULL,
    agentCode       VARCHAR(64),
    ruleCode        VARCHAR(64),
    ruleName        VARCHAR(128),
    riskDesc        TEXT,
    rawRiskDesc     TEXT,
    aiRead          TEXT,
    suggestion      TEXT,
    status          VARCHAR(16) DEFAULT 'PENDING',
    jumpAnchorCode  VARCHAR(64),
    sortNo          INT DEFAULT 0,
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_report_ai_risk IS '报告详情-AI风险实例表（实例层·经验规则类内容体）';
COMMENT ON COLUMN app_report_ai_risk.id IS '主键（自增）';
COMMENT ON COLUMN app_report_ai_risk.reportNo IS '报告编号（关联 app_report_info.reportNo）';
COMMENT ON COLUMN app_report_ai_risk.customerId IS '客户编号';
COMMENT ON COLUMN app_report_ai_risk.customerName IS '客户名称';
COMMENT ON COLUMN app_report_ai_risk.riskCode IS '风险编号（全局唯一）';
COMMENT ON COLUMN app_report_ai_risk.blockCode IS '所属内容块编号（关联 app_report_content_instance.blockCode，落地定位键）';
COMMENT ON COLUMN app_report_ai_risk.agentCode IS '智能体编码（与内容块/内容实例的业务关联键，两侧同值）';
COMMENT ON COLUMN app_report_ai_risk.ruleCode IS '经验规则编号（关联经验规则库）';
COMMENT ON COLUMN app_report_ai_risk.ruleName IS '经验规则名称';
COMMENT ON COLUMN app_report_ai_risk.riskDesc IS '风险描述（正文风险段落文案，前端可编辑；编辑后覆盖本列）';
COMMENT ON COLUMN app_report_ai_risk.rawRiskDesc IS '智能体原始生成文案（生成时写入，前端编辑不改动，用于留痕与还原）';
COMMENT ON COLUMN app_report_ai_risk.aiRead IS 'AI解读（右侧风险列表展示）';
COMMENT ON COLUMN app_report_ai_risk.suggestion IS '处置建议（右侧风险列表展示）';
COMMENT ON COLUMN app_report_ai_risk.status IS '处置状态：PENDING-待处理 ADOPTED-已采纳 INVALID-已无效';
COMMENT ON COLUMN app_report_ai_risk.jumpAnchorCode IS '跳转锚点（单向）：点击该风险行时跳转到的正文锚点（内容实例 anchorCode）';
COMMENT ON COLUMN app_report_ai_risk.sortNo IS '排序（同一内容块内风险顺序）';
COMMENT ON COLUMN app_report_ai_risk.inputtime IS '入库时间';

CREATE UNIQUE INDEX uk_report_ai_risk_code ON app_report_ai_risk (riskCode);
CREATE INDEX idx_report_ai_risk_report ON app_report_ai_risk (reportNo);
CREATE INDEX idx_report_ai_risk_block ON app_report_ai_risk (blockCode);
CREATE INDEX idx_report_ai_risk_agent ON app_report_ai_risk (reportNo, agentCode);
