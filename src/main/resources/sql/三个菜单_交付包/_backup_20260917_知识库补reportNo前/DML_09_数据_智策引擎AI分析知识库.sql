-- ============================================================================================
--  智策引擎「AI分析」知识库配置  —— 新增配置（本平台增量，非公司库镜像）
-- ============================================================================================
--
--  为什么需要这一条
--  ------------------------------------------------------------------------------------------
--  智策引擎「开始校验」会触发两段流式分析，两者的 moduleCode 来源不同：
--    · AI分析     → `IntelligentStrategyEngine`（**前端与后端都写死**：
--                    `RuleFormModal.startAiAnalysis` 与 `AgentPromptController#getRule` L131）
--    · 补充分析   → moduleCode 取「补充分析」下拉选中的知识库 paramNo（如 jyk-dfsryc）
--  后端 `KnowledgeBaseConfigServiceImpl#queryKnowledgeBaseParams(moduleCode)`
--  → `KnowledgeBaseParamsServiceImpl#getByParamNo`：按 `paramno` 精确查 + `"online"='Y'`，
--  查不到 → 没有 prompt、没有 large_model_code → `CallLlmUtil` 直接返回「非法的大模型CODE:」
--  → 前端 AI分析整块拿不到任何内容。
--
--  【已实证】这条配置在**本地库、本交付包 DML、公司库三处都不存在**：
--    · 本地库 / 交付包：86 行 knowledge_base_params，paramno 无 'IntelligentStrategyEngine'
--    · 公司库（172.20.2.19:8000/bosz_test，只读核对）：共 86 行，paramno='IntelligentStrategyEngine'
--      0 行；paramname 含「策略」0 行
--  → 也就是说**源系统在当前数据下同样出不来 AI 分析内容**，这是配置缺失，不是迁移问题。
--
--  提示词里可用的「入参占位符」语法（源码实证，别记错）
--  ------------------------------------------------------------------------------------------
--    · `[#xxx#]`     ← `ParamUtil#replacePromptParam` 按**请求参数名**替换；
--                      取不到值时替换成**空字符串**（不会留占位符），所以提示词必须容忍空值。
--    · `{{objectName}}` ← `parsePrompt`（KnowledgeBaseConfigServiceImpl L868~871）特判 =
--                      请求里的 `entName`（企业名称）。
--    · `{{指标名||指标编号}}` ← 知识库引擎取指标值；**本配置不用**（AI分析的数据来自入参，
--                      不绑定指标，因此 relate_index_set 留空）。
--    · `[[规则名]]`  ← `getRuleList` 取规则类文案；本配置也不用。
--  7 个入参（`AgentPromptController#getRule` L114~129 逐条注释过，与前端请求体一致）：
--    [#rule_name#]      检查项名称          ← agent_rule.rule_name
--    [#input#]          阈值设定            ← agent_rule.threshold_config
--    [#result#]         规则引擎命中结果     ← 命中才走这段，恒为命中
--    [#data#]           命中指标明细（JSON 数组：indexCode/indexName/actualValue/dataUnit）
--    [#risk#]           风险释义            ← agent_rule.risk_remark
--    [#content#]        处置意见            ← agent_rule.disposal_advice
--    [#factExpression#] 事实分析表达式
--
--  ⚠️ 素材填充率实测（交付包 04_数据_智策引擎.sql，42 条检查项）
--    rule_name 42/42、rule_text 42/42、parsed_expression 42/42、request_params 42/42
--    threshold_config 27/42（64%）
--    risk_remark 0/42、disposal_advice 0/42、fact_analysis 0/42   ← **三列全空**
--  → 现实素材只有「检查项名称 + 阈值口径 + 命中的指标实际值」。因此本条提示词
--    **只做"事实性复述 + 与阈值口径对照 + 提示性建议"**，不判风险等级、不给审批结论。
--  → 另注：42/42 条检查项**都已配了「补充分析」**（指向 jyk-* 经验库文案，逐条定制）。
--    AI分析（通用一条）与补充分析（逐检查项定制）在业务上**存在职责重叠**，两者都会输出文案；
--    本条的定位是「通用兜底 + 事实口径对照」，措辞已刻意避开结论性判断。
--
--  🔵 结构字段取值**逐项对齐本库真实样本行**（`paramno='jyk-dfsryc'`，2026-09-16 实测）：
--    paramtype=OBJECT / paramentitytype='' / paramlabel=NULL / modelno=Public / agentid=''
--    prompttype=basic / is_top=N / is_markdown=N / is_client_search=N / is_online_search=N
--    is_cloud_search=N / trace_config='' / image_config='' / whole_source_config=''
--    relate_index_set='' / input_index='' / splitter_param='' / user_prompt=''
--    param_description='' / tool_parameters_config=NULL / business_experience=NULL
--    input_condition={"output":"","usePrompt":"","modelInfo":{"largeModelCode":"bosz-report-ai"}}
--    split_strategy_param 与样本行逐字一致（isActive=false → 不走分段策略）
--  ⇒ 这些字段都在 `getPromptContent`/`handleMorePromptContent` 里被读取，取值已按代码分支
--    反推过：空值一律走「跳过」分支，不会触发 JSON 解析异常，也不会把原始 JSON 当提示词发出去。
--
--  ⚠️ large_model_code 直接写本平台目标口径 `bosz-report-ai`（不是公司库的 Qwen3-32B），
--     所以本文件**不需要**再走一遍 `05_映射改写.sql`。
--  ⚠️ is_top=N ⇒ 拼接顺序为「数据块在前、输出要求在后」
--     （代码：`is_top='N'` → `promptContent + LINE_BREAK + outputRequirements`）。
--
--  执行前置
--  ------------------------------------------------------------------------------------------
--    ① knowledge_base_group 里存在分组 '2095350487701274625'（「征信情况和潜在风险-企业」）
--    ② sys_role_knowledge 已把该分组授权给 admin（06_授权生成.sql 第①步会补）
--    ③ large_model_config 里 lm_code='bosz-report-ai' 且 use_flag='Y'
--  幂等：① 主 INSERT 用 NOT EXISTS 守卫，可重复执行；② 授权 INSERT 同样带 NOT EXISTS。
--
--  回滚（三处都要删干净，否则残留授权行）
--  ------------------------------------------------------------------------------------------
--    DELETE FROM sys_role_knowledge_output WHERE knowledge_id = '2100000000000000001';
--    DELETE FROM knowledge_base_params    WHERE paramno  = 'IntelligentStrategyEngine';
--
--  执行记录：2026-09-16 已在本机 as_agent 执行通过（详见同目录 00_执行说明.md 第 7 步）。
-- ============================================================================================


-- -------------------------------------------------------------------------------------------
-- ① 知识库配置本体
-- -------------------------------------------------------------------------------------------
INSERT INTO knowledge_base_params (
    paramid, paramno, paramname, paramtype, paramentitytype, paramlabel, modelno,
    parentparamid, parentparamname, reportversion, sortno, prompt, agentid, otherconfig,
    paramstatus, inputuserid, inputtime, updateuserid, updatetime, groupid, "online",
    prompttype, contentdesc, input_param, large_model_code, trace_config, image_config,
    whole_source_config, large_model_content, relate_index_set, black_content_desc,
    black_model_code, is_markdown, param_description, input_condition, is_client_search,
    is_online_search, input_index, large_model_param, is_top, splitter_param,
    tool_parameters_config, is_cloud_search, user_prompt, split_strategy_param,
    business_experience
)
SELECT
    '2100000000000000001',
    'IntelligentStrategyEngine',
    '智策引擎-AI分析（命中风险解读）',
    'OBJECT',
    '', NULL, 'Public',
    NULL, NULL, NULL, NULL,

    -- ① prompt：喂给模型的「输入素材」块。is_top=N ⇒ 本块在前、输出要求(contentdesc)在后。
    --    注意 {{objectName}} 会被替换成企业名称；[#xxx#] 取不到值时变空串。
    --    resourceFlag=false 且 resource=[] ⇒ 不触发指标溯源分支；本块无 {{a||b}} 占位符，
    --    因此 getParamNoList 返回空、不会去查指标值（已核代码）。
    '[{"if":{"condition":"","variables":[],"output":"企业名称：{{objectName}}\n\n检查项：[#rule_name#]\n阈值口径：[#input#]\n规则引擎命中结果：[#result#]\n\n命中指标明细（JSON）：\n[#data#]\n\n行内风险释义：[#risk#]\n行内处置意见：[#content#]\n事实分析表达式：[#factExpression#]","reference":[],"resourceFlag":false},"id":"a1b2c3d4-0001-4a01-9b01-000000000001"}]',

    '', NULL,
    'Y', 'admin', '2026-09-16 00:00:00', 'admin', '2026-09-16 00:00:00',

    -- 复用现有「征信情况和潜在风险-企业」分组（2095350487701274625，12 条），
    -- 该分组已授权给 admin（sys_role_knowledge），因此**无需再补分组授权**。
    -- 如需独立成组：先在 knowledge_base_group 插一行拿新 groupid，再在 sys_role_knowledge
    -- 补该分组的角色授权（否则知识配置列表看不到它）。
    '2095350487701274625',
    'Y',
    'basic',

    -- ② contentdesc：核心提示词（模型实际收到的「# 角色 / # 任务 / # 输出要求」段）
    '[{"if":{"condition":"","variables":[],"output":"# 角色\n\n你是银行贷后管理领域的信贷风险分析助手，熟悉贷后检查、财务口径与风险提示的行文习惯。\n\n# 任务\n\n规则引擎已经判定某条贷后检查项「命中」。请基于系统给出的检查项口径、命中指标明细与行内既有口径，输出一段供客户经理阅读的风险分析：\n\n1. 说明是哪条检查项命中、命中的是哪些指标、这些指标的实际取值是多少；\n2. 说明该取值相对检查项的阈值口径意味着什么（只做事实与口径的对照，不做额外推测）；\n3. 给出提示性关注建议（例如「提请核实相关情况」「建议结合其他资料进一步确认」）。\n\n# 输入说明\n\n输入包括：检查项名称、阈值口径、规则引擎命中结果、命中指标明细（JSON 数组，含指标编号、指标名称、实际值、单位）、行内风险释义、行内处置意见、事实分析表达式。\n\n以上素材均由业务侧维护，**可能为空**。素材为空时不得猜测或补写其内容，直接跳过该项。\n\n# 输出要求\n\n- 只输出一个 Markdown 片段：第一行用 `### ` 加检查项名称作为小标题；\n- 正文分两段，第一段为事实描述，第二段为关注建议；\n- 涉及数值必须原样引用输入中的实际取值，不得换算、不得四舍五入、不得编造；\n- 不得输出授信审批结论、客户评级结论或法律意见；\n- 不得输出「以上由 AI 生成」之类的说明文字；\n- 全文控制在 300 字以内。","usePrompt":"","modelInfo":{}},"id":"a1b2c3d4-0002-4a02-9b02-000000000002"}]',

    -- ③ input_param：与样本行同构（只声明 entName）
    '[{"defaultValue":"","name":"entName","id":"a1b2c3d4-0003-4a03-9b03-000000000003"}]',

    'bosz-report-ai',

    '', '', '',

    -- large_model_content 先占位，紧随其后的第③步用 SQL 由 contentdesc 生成真实映射
    -- （格式与现存 86 行一致：{"<大模型CODE>": "<输出要求>"}）
    '{}',

    '', NULL, NULL,
    'N', '',
    '{"output":"","usePrompt":"","modelInfo":{"largeModelCode":"bosz-report-ai"}}',
    'N', 'N', '', '{}', 'N', '',
    NULL, 'N', '',
    '{"isActive":false,"splitStrategy":"auto","floorLevel":1,"splitLabel":"","splitMaxLength":null,"retrievalStrategy":"auto","retrievalMode":[],"retrievalKeywords":"","returnCount":10,"promptStrategy":"strict","promptContent":"","checkKeyword":"","checkLlm":""}',
    NULL
  FROM (SELECT 1) AS t
 WHERE NOT EXISTS (
         SELECT 1 FROM knowledge_base_params WHERE paramno = 'IntelligentStrategyEngine');


-- -------------------------------------------------------------------------------------------
-- ② 「输出要求」区块的编辑权限（admin）
--    判权口径：`checkKnowledgeOutputAuth` → role_id in (...) AND knowledge_id = paramId
--    即 knowledge_id 存的是 knowledge_base_params.paramid（主键）。
--    没有这一行 → 知识配置编辑器里「输出要求」区块视为无权限（hasAuth=false）。
--    与 06_授权生成.sql 第②步同源同格式，幂等可重复执行。
-- -------------------------------------------------------------------------------------------
INSERT INTO sys_role_knowledge_output (id, role_id, group_id, knowledge_id, operate_date)
SELECT md5('rko-' || k.paramid),
       (SELECT id::text FROM sys_role WHERE role_code = 'admin' LIMIT 1),
       k.groupid, k.paramid, now()
  FROM knowledge_base_params k
 WHERE k.paramno = 'IntelligentStrategyEngine'
   AND NOT EXISTS (
         SELECT 1 FROM sys_role_knowledge_output s
          WHERE s.role_id = (SELECT id::text FROM sys_role WHERE role_code = 'admin' LIMIT 1)
            AND s.knowledge_id = k.paramid);


-- -------------------------------------------------------------------------------------------
-- ③ 用 contentdesc 生成 large_model_content（{"bosz-report-ai":"<输出要求>"}）
--    该列只在「知识配置保存」路径被读取（用于按模型分别保存输出要求），运行时不读；
--    这里补齐是为了与本库 86 行「非空」的形态保持一致。
-- -------------------------------------------------------------------------------------------
UPDATE knowledge_base_params
   SET large_model_content = json_build_object('bosz-report-ai', contentdesc)::text
 WHERE paramno = 'IntelligentStrategyEngine';


-- -------------------------------------------------------------------------------------------
-- 执行后校验（应与后端「按 moduleCode 取知识库」的查询同口径）
-- -------------------------------------------------------------------------------------------
-- SELECT paramid, paramno, paramname, paramstatus, "online", large_model_code, prompttype
--   FROM knowledge_base_params
--  WHERE paramno = 'IntelligentStrategyEngine' AND "online" = 'Y';
-- 期望：1 行；large_model_code = bosz-report-ai
--
-- SELECT count(*) FROM sys_role_knowledge_output WHERE knowledge_id = '2100000000000000001';
-- 期望：1
