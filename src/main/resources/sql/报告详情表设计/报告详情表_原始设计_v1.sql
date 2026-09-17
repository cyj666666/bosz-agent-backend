-- =====================================================================
-- 报告详情页 · 通用模板表结构 DDL（原始设计 v1，高斯DB版）
-- 数据库：高斯DB（GaussDB，参考 20260819 建表脚本风格）
-- 内容  ：两张配置表
--         1) app_report_catalog        目录表（左侧目录树，一/二/三级可配置）
--         2) app_report_content_block  报告正文内容表（每目录挂 N 个内容块）
-- 约定  ：camelCase 列名 / COMMENT ON 注释 / SMALLINT 表布尔 / 索引名全库唯一 / 不用 IF NOT EXISTS
-- 日期  ：2026-09-10
-- =====================================================================

-- ============================================================
-- 一、目录表
--    一级目录 parentCode 为 NULL；
--    目录级别连续性（catalogLevel = 上级.catalogLevel + 1）由应用层校验；
--    sortNo 为同一上级目录内的排序。
-- ============================================================

CREATE TABLE app_report_catalog (
    id             BIGINT NOT NULL AUTO_INCREMENT,
    catalogCode    VARCHAR(64) NOT NULL,
    catalogName    VARCHAR(128) NOT NULL,
    catalogLevel   SMALLINT NOT NULL,
    parentCode     VARCHAR(64),
    sortNo         INT DEFAULT 0,
    isEnabled      SMALLINT DEFAULT 1,
    inputtime      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_report_catalog IS '报告详情-目录配置表（模板层·目录树）';
COMMENT ON COLUMN app_report_catalog.id IS '主键（自增）';
COMMENT ON COLUMN app_report_catalog.catalogCode IS '目录编号（全局唯一）';
COMMENT ON COLUMN app_report_catalog.catalogName IS '目录名称';
COMMENT ON COLUMN app_report_catalog.catalogLevel IS '目录级别：1-一级 2-二级 3-三级';
COMMENT ON COLUMN app_report_catalog.parentCode IS '上级目录编号（一级目录为NULL，其余必填；应用层校验层级连续）';
COMMENT ON COLUMN app_report_catalog.sortNo IS '排序（同一上级目录内）';
COMMENT ON COLUMN app_report_catalog.isEnabled IS '是否可用：1-可用 0-停用';
COMMENT ON COLUMN app_report_catalog.inputtime IS '入库时间';

CREATE UNIQUE INDEX uk_report_catalog_code ON app_report_catalog (catalogCode);
CREATE INDEX idx_report_catalog_parent ON app_report_catalog (parentCode);
CREATE INDEX idx_report_catalog_level ON app_report_catalog (catalogLevel, isEnabled);


-- ============================================================
-- 二、报告正文内容表
--    每个目录（catalogCode）下挂 N 个内容块，前端按 sortNo 顺序渲染。
--    catalogCode 为 NULL 表示报告级内容块（如报告头，不进目录树，渲染在正文顶部）。
--    fillType 填充类型枚举：
--        TITLE       - 标题（整块仅为兼容固定标题展示，只有一个标题；级别见 titleLevel）
--        TEXT        - 文本（analysisType / agentCode 在 TEXT / TABLE 下才有值）
--        TABLE       - 表格（content 为「表格成品片段」；同样可由智能体加工，故也允许配 analysisType / agentCode）
--        SOURCE_LINK - 溯源按钮（块本身即按钮，其实例 content 存外部跳转链接，点击新开浏览器标签页）
--    analysisType 分析文本类型枚举（仅 fillType = TEXT / TABLE 时有值）：
--        RULE        - 经验规则类（此时 blockName 即规则名称；agentCode 已含经验规则编号）
--        ANALYSIS    - 文本分析类（知识库：content 存文本，有表格以 md 形式存）
--        TRACE_TABLE - 表格溯源类（agentCode = 表英文名 app_*；agentParams 存查询条件，可带 `列=值` 过滤令牌；
--                      加工时查表拼 md 表格；严格按条件查，**不做担保人轮询**）
--        TRACE_LINK  - 链接溯源类（content 存"链接开头"，前端调接口补全 + SM4 加密后跳转）
--        EXTERNAL    - 外部灌入类（内容不由本服务产出，后续由别的接口直接落 content）
--        ⚠️ 只对 TEXT / TABLE 放开 —— 判据与 AgentReportContentProvider 的 analysable 同口径；
--           TITLE / SOURCE_LINK 配了会在模板校验阶段 fail-fast。
--    blockName 内容块名称（必填）：模板层与实例层同名同值；analysisType=RULE 时其业务含义即规则名称
--    emptyStrategy 空数据策略：实例内容为空时，PLACEHOLDER-显示暂无数据占位（默认）/ HIDE-整块隐藏
--    jumpAnchorCode 块间跳转目标锚点（单向）：值 = 目标块的 anchorCode（即目标块 blockCode）。
--        跳转关系属于报告结构、在模板层配置，生成时快照到实例层；与填充类型无关，
--        任何填充类型的块配置了本值即可点击跳转（前端滚动定位，不新开页面）；无跳转则为 NULL。
-- ============================================================

CREATE TABLE app_report_content_block (
    id             BIGINT NOT NULL AUTO_INCREMENT,
    blockCode      VARCHAR(64) NOT NULL,
    catalogCode    VARCHAR(64),
    fillType       VARCHAR(16) NOT NULL,
    analysisType   VARCHAR(16),
    agentCode      VARCHAR(64),
    agentParams    VARCHAR(256),
    blockName      VARCHAR(128) NOT NULL,
    titleLevel     SMALLINT,
    emptyStrategy  VARCHAR(16) DEFAULT 'PLACEHOLDER',
    jumpAnchorCode VARCHAR(64),
    sortNo         INT DEFAULT 0,
    isEnabled      SMALLINT DEFAULT 1,
    inputtime      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_report_content_block IS '报告详情-正文内容块配置表（模板层·内容块）';
COMMENT ON COLUMN app_report_content_block.id IS '主键（自增）';
COMMENT ON COLUMN app_report_content_block.blockCode IS '内容块编号（全局唯一）';
COMMENT ON COLUMN app_report_content_block.catalogCode IS '所属目录编号（关联 app_report_catalog.catalogCode；报告级内容块（如报告头）为NULL，不进目录树）';
COMMENT ON COLUMN app_report_content_block.fillType IS '填充类型：TITLE-标题 TEXT-文本 TABLE-表格 SOURCE_LINK-溯源链接';
COMMENT ON COLUMN app_report_content_block.analysisType IS '分析文本类型：RULE-经验规则类 ANALYSIS-文本分析类 TRACE_TABLE-表格溯源（agentCode=表名）TRACE_LINK-链接溯源 EXTERNAL-外部灌入（仅 fillType=TEXT/TABLE 时有值，否则为NULL）';
COMMENT ON COLUMN app_report_content_block.agentCode IS '智能体编码（仅 fillType=TEXT/TABLE 时有值，否则为NULL；已含经验规则编号；为与内容实例、AI 风险实例的关联键）';
COMMENT ON COLUMN app_report_content_block.agentParams IS '调智能体入参清单（逗号分隔的参数名，仅 TEXT/TABLE 有值）：reportNo,entName 或 reportNo,entName,guarantorName（后者按担保人口径、多担保人时轮循）。2026-09-17 新增：同一 agentCode 在不同章节可能是借款人/担保人两种口径，入参不同结果不同，必须有此列区分';
COMMENT ON COLUMN app_report_content_block.blockName IS '内容块名称（analysisType=RULE 时即规则名称；模板层与实例层同名同值）';
COMMENT ON COLUMN app_report_content_block.titleLevel IS '标题级别：1-报告主标题 2-章节标题 3-小节标题（仅 fillType=TITLE 时有值，否则为NULL）';
COMMENT ON COLUMN app_report_content_block.emptyStrategy IS '空数据策略（实例内容为空时生效）：PLACEHOLDER-显示暂无数据占位（默认） HIDE-整块隐藏';
COMMENT ON COLUMN app_report_content_block.jumpAnchorCode IS '块间跳转目标锚点（单向）：点击本块时滚动定位到的目标块 anchorCode（=目标块 blockCode）；跳转关系属报告结构、在模板层配置，生成时快照到实例层；与填充类型无关，无跳转则为NULL';
COMMENT ON COLUMN app_report_content_block.sortNo IS '排序（同一目录内内容块顺序）';
COMMENT ON COLUMN app_report_content_block.isEnabled IS '是否可用：1-可用 0-停用';
COMMENT ON COLUMN app_report_content_block.inputtime IS '入库时间';

CREATE UNIQUE INDEX uk_report_block_code ON app_report_content_block (blockCode);
CREATE INDEX idx_report_block_catalog ON app_report_content_block (catalogCode);
CREATE INDEX idx_report_block_type ON app_report_content_block (fillType);
