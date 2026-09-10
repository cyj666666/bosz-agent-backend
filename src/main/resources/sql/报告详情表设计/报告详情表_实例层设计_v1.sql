-- =====================================================================
-- 报告详情页 · 实例层表结构 DDL（v1，高斯DB版）
-- 数据库   ：高斯DB（GaussDB，风格同 20260819 建表脚本）
-- 生成依据 ：模板层两张表
--            · app_report_catalog        （目录表）
--            · app_report_content_block  （内容块表）
-- 上级表   ：app_report_info（报告主表，reportNo 关联，不重复建报告实例表）
-- 实例层共 2 张表：
--   1) app_report_content_instance  内容实例表 —— 报告正文内容
--        一条内容块 → 一条实例，所有填充类型（TITLE/TEXT/TABLE/SOURCE_LINK，
--        含 analysisType=RULE 经验规则类）的内容体一律落在 content 大字段。
--   2) app_report_ai_risk           AI 风险实例表 —— 右侧「AI 风险识别列表」数据源
--        一条风险一条记录，riskDesc 与内容实例 content（RULE 场景）为同一份文案；
--        额外承载列表展示所需字段与处置状态。
-- 说明     ：目录不单独建实例表 —— 前端按内容实例的 catalogCode 聚合 + 模板目录属性渲染目录树；
--            某目录下内容块全部为空且 emptyStrategy=HIDE 时，该目录自然不出现。
-- 设计要点 ：
--    ① 实例表结构性字段（fillType/analysisType/agentCode/ruleName/titleLevel/sortNo/catalogCode）
--       是生成时从模板快照过来的，目的是渲染一次查询、不 join 模板，且模板改版不污染历史报告。
--    ② 块间跳转锚点是单向的：只存"本块 → 目标块锚点"，不存反向关系；
--       与填充类型无关，任何填充类型的块配置了 jumpAnchorCode 即可跳转。
--       外链跳转是另一回事：SOURCE_LINK 块把链接存在自己的 content 里。
--    ③ AI 风险与正文的关联：agentCode 为关联键（两侧同值，且已含经验规则编号），
--       blockCode 为落地定位键（唯一键依据）。
--    ④ 正文 content 为准、列表 riskDesc 为副本：内容可编辑时两处必须同事务同步更新，
--       且编辑入口只开在正文侧，同步方向恒为 正文 → 列表（单向，禁止双向写）。
-- 已确认前提（2026-09-10 用户确认，DDL 已落约束，变更其一需同步改索引）：
--    · RULE 类内容块与 AI 风险实例为 1:1 —— 唯一键 (reportNo, blockCode)
--    · agentCode 在单份报告内唯一（编码 = 经验规则编号 + 章节维度） —— 唯一键 (reportNo, agentCode)
--    · 跳转锚点单向
-- 日期     ：2026-09-10
-- =====================================================================


-- ============================================================
-- 一、内容实例表
--    填充类型与 content 的对应：
--        TITLE       - 标题文案（报告头公司名等；titleLevel 区分主/章/节标题）
--        TEXT        - 分析文本；analysisType=RULE 时即经验规则类的正文内容体
--        TABLE       - 表格成品内容
--        SOURCE_LINK - 溯源按钮（块本身就是按钮，content 存外部跳转链接，点击新开浏览器标签页）
--    两类"跳转"互相独立，不要混：
--        ① 外链：SOURCE_LINK 填充类型的块，链接在其 content 中；
--        ② 块间定位：anchorCode / jumpAnchorCode，与填充类型无关，
--           任何填充类型的块只要配了 jumpAnchorCode 即可点击跳到目标块。
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
    ruleName        VARCHAR(128),
    titleLevel      SMALLINT,
    sortNo          INT DEFAULT 0,
    anchorCode      VARCHAR(64),
    jumpAnchorCode  VARCHAR(64),
    content         TEXT,
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_report_content_instance IS '报告详情-内容实例表（实例层·由内容块表生成·报告正文内容）';
COMMENT ON COLUMN app_report_content_instance.id IS '主键（自增）';
COMMENT ON COLUMN app_report_content_instance.reportNo IS '报告编号（关联 app_report_info.reportNo）';
COMMENT ON COLUMN app_report_content_instance.customerId IS '客户编号';
COMMENT ON COLUMN app_report_content_instance.customerName IS '客户名称';
COMMENT ON COLUMN app_report_content_instance.blockCode IS '内容块编号（关联 app_report_content_block.blockCode）';
COMMENT ON COLUMN app_report_content_instance.catalogCode IS '所属目录编号（报告级内容块（如报告头）为NULL）';
COMMENT ON COLUMN app_report_content_instance.fillType IS '填充类型（生成时自模板快照）：TITLE-标题 TEXT-文本 TABLE-表格 SOURCE_LINK-溯源按钮（content 为外部跳转链接）';
COMMENT ON COLUMN app_report_content_instance.analysisType IS '分析文本类型（自模板快照）：RULE-经验规则类 ANALYSIS-文本分析类';
COMMENT ON COLUMN app_report_content_instance.agentCode IS '智能体编码（自模板快照，已含经验规则编号；与 AI 风险实例的关联键）';
COMMENT ON COLUMN app_report_content_instance.ruleName IS '经验规则名称（自模板快照，仅 analysisType=RULE 时有值，否则为NULL）';
COMMENT ON COLUMN app_report_content_instance.titleLevel IS '标题级别（自模板快照）：1-报告主标题 2-章节标题 3-小节标题';
COMMENT ON COLUMN app_report_content_instance.sortNo IS '排序（自模板快照，同一目录内）';
COMMENT ON COLUMN app_report_content_instance.anchorCode IS '锚点编码：本块在报告内的定位锚点（默认取 blockCode），作为其它块跳转的目标标识；与填充类型无关';
COMMENT ON COLUMN app_report_content_instance.jumpAnchorCode IS '块间跳转锚点（单向，仅用于内容块之间的点击快速定位）：点击本块时跳转到的目标块 anchorCode；非外部跳转链接；与填充类型无关，任何块配置了本值即可跳转；无跳转则为NULL';
COMMENT ON COLUMN app_report_content_instance.content IS '内容（大文本）：TITLE-标题文案 TEXT-分析文本（analysisType=RULE 时为经验规则类内容体）TABLE-表格内容 SOURCE_LINK-外部跳转链接（块本身即按钮，点击新开浏览器标签页）';
COMMENT ON COLUMN app_report_content_instance.inputtime IS '入库时间';

CREATE UNIQUE INDEX uk_report_ci_report_block ON app_report_content_instance (reportNo, blockCode);
CREATE INDEX idx_report_ci_report ON app_report_content_instance (reportNo);
CREATE INDEX idx_report_ci_anchor ON app_report_content_instance (reportNo, anchorCode);
CREATE INDEX idx_report_ci_catalog ON app_report_content_instance (reportNo, catalogCode);
CREATE INDEX idx_report_ci_agent ON app_report_content_instance (reportNo, agentCode);


-- ============================================================
-- 二、AI 风险实例表（右侧「AI 风险识别列表」数据源）
--    「一条 RULE 内容块 ↔ 一条风险」的 1:1 关系（用户确认）：
--        正文内容由内容实例的 content 承载，本表只承载列表展示字段与处置状态，
--        riskDesc 与内容实例 content（analysisType=RULE 场景）为同一份文案。
--    唯一性约束：
--        uk_report_ai_risk_report_block  (reportNo, blockCode) —— 行身份，1:1
--        uk_report_ai_risk_report_agent  (reportNo, agentCode) —— 报告内 agentCode 唯一
--        两条约束互为印证；若将来出现"一条规则命中多个内容块"，需先移除 agent 唯一约束。
--    写入纪律：正文内容支持编辑时，content 与 riskDesc 必须在同一事务内同步更新，
--              以 content 为准本、riskDesc 为副本；编辑入口只开在正文侧，方向单向。
--    小文本字段（原有 rawRiskDesc/aiRead/suggestion）按最新设计已移除。
--    处置状态：PENDING-待处理 ADOPTED-已采纳 INVALID-已无效。
-- ============================================================

CREATE TABLE app_report_ai_risk (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    customerName    VARCHAR(128),
    blockCode       VARCHAR(64) NOT NULL,
    agentCode       VARCHAR(64) NOT NULL,
    ruleName        VARCHAR(128),
    riskDesc        TEXT,
    status          VARCHAR(16) DEFAULT 'PENDING',
    jumpAnchorCode  VARCHAR(64),
    sortNo          INT DEFAULT 0,
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

COMMENT ON TABLE app_report_ai_risk IS '报告详情-AI风险实例表（实例层·右侧AI风险识别列表）';
COMMENT ON COLUMN app_report_ai_risk.id IS '主键（自增）';
COMMENT ON COLUMN app_report_ai_risk.reportNo IS '报告编号（关联 app_report_info.reportNo）';
COMMENT ON COLUMN app_report_ai_risk.customerId IS '客户编号';
COMMENT ON COLUMN app_report_ai_risk.customerName IS '客户名称';
COMMENT ON COLUMN app_report_ai_risk.blockCode IS '内容块编号（关联 app_report_content_instance.blockCode，唯一键依据与落地定位键）';
COMMENT ON COLUMN app_report_ai_risk.agentCode IS '智能体编码（已含经验规则编号；与正文内容实例的关联键，两侧同值）';
COMMENT ON COLUMN app_report_ai_risk.ruleName IS '经验规则名称（列表展示）';
COMMENT ON COLUMN app_report_ai_risk.riskDesc IS '风险描述（列表展示文案；与内容实例 content 同一份文案，编辑正文时同事务同步更新）';
COMMENT ON COLUMN app_report_ai_risk.status IS '处置状态：PENDING-待处理 ADOPTED-已采纳 INVALID-已无效';
COMMENT ON COLUMN app_report_ai_risk.jumpAnchorCode IS '跳转锚点（单向，仅用于点击快速定位）：点击该风险行时跳转到的正文锚点（内容实例 anchorCode）；非外部跳转链接';
COMMENT ON COLUMN app_report_ai_risk.sortNo IS '排序（风险列表内顺序）';
COMMENT ON COLUMN app_report_ai_risk.inputtime IS '入库时间';

CREATE UNIQUE INDEX uk_report_ai_risk_report_block ON app_report_ai_risk (reportNo, blockCode);
CREATE UNIQUE INDEX uk_report_ai_risk_report_agent ON app_report_ai_risk (reportNo, agentCode);
CREATE INDEX idx_report_ai_risk_report ON app_report_ai_risk (reportNo);
CREATE INDEX idx_report_ai_risk_status ON app_report_ai_risk (reportNo, status);
