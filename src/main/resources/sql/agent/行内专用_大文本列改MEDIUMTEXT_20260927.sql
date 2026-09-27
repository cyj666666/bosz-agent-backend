-- =====================================================================
-- 行内专用 · 删冗余列 + 大文本列改 MEDIUMTEXT（2026-09-27）
-- =====================================================================
-- 🔴 **本脚本含两个独立部分，执行条件不同、顺序不能颠倒**：
--     【第一部分】删 `sourceSnapshot` 列 × 2  —— ⚠️ **前提：Java 侧改动已上线**
--     【第二部分】6 个大文本列改 `MEDIUMTEXT` —— 无前提，可独立执行
--   详见下面各自的说明。
--
-- =====================================================================
-- 【为什么必须改】
-- =====================================================================
-- 行内 = **集中式 GaussDB M 兼容模式**（内核 505.2.1.SPC0800，sql_compatibility='M'）。
-- 该模式下 **TEXT 上限只有 65,535 字节（64KB）** —— ⚠️ 与外网 openGauss(PG) 的 1GB **完全不同**。
-- 中文按 UTF-8 占 3 字节 ⇒ 单列最多约 **2.18 万个中文**；
-- 超出即报 `Data too long for text`（行内 sql_mode 含 strict_trans_tables ⇒ **直接报错、不静默截断**）。
--
-- 【实测依据】（行内探针，2026-09-24 已执行）
--   TEXT       : 21845 个中文（65535 字节）✅ 成功 ／ 21846 个（65538 字节）❌ Data too long
--   MEDIUMTEXT : 30000 个中文（9 万字节）  ✅ 成功  ⇒ 容量 16,777,215 字节，可用
--   VARCHAR(n) : n 按「**字符数**」计算 ⇒ VARCHAR 类字段**无需处理**（本项目已排除）
--
-- =====================================================================
-- 【第一部分】删除 `sourceSnapshot` 列（2026-09-27 新增）
-- =====================================================================
-- 删这两列（各一张表）：
--     app_report_ai_analysis.sourceSnapshot
--     app_report_warning_advice_batch.sourceSnapshot
--
-- 【为什么删】（完整评估见 .workbuddy/memory/2026-09-27.md）
--   ① **零独有信息** —— 它是 `promptSnapshot` 的子串：
--      `renderUserPrompt(prompt, material)` 三个分支都把素材嵌进 userPrompt，
--      而 promptSnapshot = "[system]\n" + systemPrompt + "\n\n[user]\n" + userPrompt。
--   ② **零读取** —— 全仓（含前端）没有任何 `getSourceSnapshot()`，纯写不读。
--   ③ 顺带省掉**每行重复的一份素材**（上限 6 万字符 ≈ 18 万字节）与一次重写表开销。
--   ⇒ 排查「当时 AI 看到了什么」看 `promptSnapshot` 的 `[user]` 段即可。
--
-- 🔴 【执行前提 — 绝不能省】
--   必须**先**确认 Java 侧改动已上线（两个 entity 删字段 + 三个 Task 删 setter），
--   **再**执行 DROP。因为 MyBatis-Plus 按**实体字段**拼列清单：
--   若实体还留着 sourceSnapshot 而库列已删 ⇒ 查询会拼出不存在的列
--   ⇒ 报告详情页 AI 面板 / 预警建议 / 分析历史列表**全部报错**。
--
-- 🔴 【不可逆】DROP COLUMN 之后数据即丢失。若想留一手，先跑文末的备份语句。
--
-- =====================================================================
-- 【第二部分】6 个大文本列改 MEDIUMTEXT
-- =====================================================================
--   （依据：doc/大文本字段容量排查_20260924.md  §七「人工收敛」）
--   ③ prompt_query_result.query_result / query_param
--   ④ call_llm_record.request_body / content
--   ⑤ app_report_ai_analysis.promptsnapshot
--   ⑥ app_report_warning_advice_batch.promptsnapshot
--
--   🔴 **故意不改的**（已复核不会超，别顺手加进来）：
--      · app_report_ai_analysis.analysiscontent —— 提示词限定「全文 ≤600 字」
--      · app_report_content_instance.content / app_report_risk_edit_log.* —— **一行 = 一个内容块**
--      · app_report_prompt.* / knowledge_base_params.* / agent_rule.* —— 配置 / 文案类，KB 级
--
-- 【执行前必读】
--   1. 🔴 `ALTER COLUMN ... TYPE` 会**重写整张表**。`call_llm_record` / `prompt_query_result`
--      是**调用/请求记录表**，数据量可能很大 ⇒ **务必挑业务低峰执行**。
--   2. ✅ **已确认可改（曹哥 2026-09-27）**：`prompt_query_result` / `call_llm_record`
--      在行内**仅本 agent 使用**，改列类型无跨系统影响，不受「行内表结构不能动」那条口径约束。
--   3. 列类型由 TEXT 变宽为 MEDIUMTEXT（同族字符串类型）⇒ 对 Java / MyBatis-Plus 无影响，
--      **不需要改代码、不需要重新打包**。
--   4. 🔴 **语法：行内（M 兼容模式）必须用 `MODIFY COLUMN`** ——
--      2026-09-27 行内实测：`ALTER TABLE … ALTER COLUMN … TYPE MEDIUMTEXT` **报「不支持 TYPE」**。
--      本脚本正文已全部改为 `MODIFY COLUMN`；PG 风格写法见文末「备选」，
--      那套**只在外网 openGauss(PG) 上用**，别再拿到行内跑。
--   5. ⚠️ `MODIFY COLUMN` 在 MySQL 语义下**会重置列定义**（没写出来的属性会丢：
--      NOT NULL / DEFAULT / 内联 COMMENT）。✅ 已核对这 6 列建表时**都是裸 `TEXT,`**
--      （无 NOT NULL、无 DEFAULT，注释走独立的 `COMMENT ON COLUMN`）⇒ 只写类型是安全的。
--      **改完顺手核一下列注释还在不在**，若丢了用文末的 `COMMENT ON COLUMN` 补回。
--   5. （可选，建议）这 6 列存的都是**记录 / 快照性质**的数据（非业务主数据）；
--      若想稳妥可先备份，例：`CREATE TABLE prompt_query_result_bak_20260927 AS SELECT * FROM prompt_query_result;`
--
-- 【前置步骤（强烈建议）】
--   先跑 doc/大文本字段容量排查_20260924.md §7.4 的体检 SQL 看实际数据量级：
--     max(octet_length(col)) > 60000 的列 = 已经/即将出问题。
--   （有些列可能实际远没到 64KB，那就先不用改 —— 毕竟 ALTER 要重写表。）
--
-- 【幂等性】
--   · DROP COLUMN：**不幂等**，重复执行会报「列不存在」。请先跑文末校验 SQL 确认列是否还在。
--   · ALTER TYPE ：同类型再 ALTER 一次是 no-op（不报错），但**仍会扫表验证** ⇒ 数据量大时也耗时。
-- 【回滚】见文末（⚠️ 改类型回滚前必须确认数据未超 65535 字节，否则会报 Data too long）
-- =====================================================================

-- 按行内实际 schema 调整（与 agent_模块建表_as_agent.sql 一致）
SET search_path = as_agent, public;


-- =====================================================================
-- 【第一部分】删冗余列（⚠️ 前提：Java 侧改动已上线）
-- =====================================================================

-- 🔴 备份（可选但建议 —— DROP 不可逆；不需要留底可跳过本段）
-- CREATE TABLE app_report_ai_analysis_bak_ss_20260927 AS
--     SELECT id, reportNo, sourceSnapshot FROM app_report_ai_analysis;
-- CREATE TABLE app_report_warning_advice_batch_bak_ss_20260927 AS
--     SELECT id, reportNo, sourceSnapshot FROM app_report_warning_advice_batch;

ALTER TABLE app_report_ai_analysis          DROP COLUMN sourceSnapshot;
ALTER TABLE app_report_warning_advice_batch DROP COLUMN sourceSnapshot;


-- =====================================================================
-- 【第二部分】6 列改 MEDIUMTEXT
-- =====================================================================

-- ---------------------------------------------------------------------
-- ⑤ 报告 AI 全文分析（提示词快照 —— 含 6 万字符素材，必然超 64KB）
-- ---------------------------------------------------------------------
ALTER TABLE app_report_ai_analysis          MODIFY COLUMN promptsnapshot MEDIUMTEXT;

-- ---------------------------------------------------------------------
-- ⑥ 报告预警建议批次（同上，由 ReportWarningAdviceTask 写入）
-- ---------------------------------------------------------------------
ALTER TABLE app_report_warning_advice_batch MODIFY COLUMN promptsnapshot MEDIUMTEXT;

-- ---------------------------------------------------------------------
-- ③ prompt 请求结果记录（query_result 已实际报过 Data too long）
-- ---------------------------------------------------------------------
ALTER TABLE prompt_query_result             MODIFY COLUMN query_result   MEDIUMTEXT;
ALTER TABLE prompt_query_result             MODIFY COLUMN query_param    MEDIUMTEXT;

-- ---------------------------------------------------------------------
-- ④ 大模型调用记录（request_body = 完整请求体，content = 模型完整输出）
-- ---------------------------------------------------------------------
ALTER TABLE call_llm_record                 MODIFY COLUMN request_body   MEDIUMTEXT;
ALTER TABLE call_llm_record                 MODIFY COLUMN content        MEDIUMTEXT;


-- =====================================================================
-- 校验 1：第一部分 —— 确认两列已删除（期望 **0 行**）
-- =====================================================================
SELECT table_name, column_name
FROM information_schema.columns
WHERE (table_name, column_name) IN (
        ('app_report_ai_analysis',         'sourcesnapshot'),
        ('app_report_warning_advice_batch','sourcesnapshot')
      );

-- =====================================================================
-- 校验 2：第二部分 —— 确认 6 列都变成了 mediumtext（期望 **6 行**）
-- =====================================================================
SELECT table_name, column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE (table_name, column_name) IN (
        ('app_report_ai_analysis',         'promptsnapshot'),
        ('app_report_warning_advice_batch','promptsnapshot'),
        ('prompt_query_result',            'query_result'),
        ('prompt_query_result',            'query_param'),
        ('call_llm_record',                'request_body'),
        ('call_llm_record',                'content')
      )
ORDER BY table_name, column_name;

-- 期望：6 行全部 data_type = mediumtext（character_maximum_length 可能为 NULL，属正常）

-- 顺带看一眼各列现有数据的**最大字节数**（确认改动确实有意义 / 没有新超限的）
SELECT 'app_report_ai_analysis.promptsnapshot' AS col,        max(octet_length(promptsnapshot)) AS max_bytes FROM app_report_ai_analysis
UNION ALL SELECT 'app_report_warning_advice_batch.promptsnapshot', max(octet_length(promptsnapshot))  FROM app_report_warning_advice_batch
UNION ALL SELECT 'prompt_query_result.query_result',               max(octet_length(query_result))    FROM prompt_query_result
UNION ALL SELECT 'prompt_query_result.query_param',                max(octet_length(query_param))     FROM prompt_query_result
UNION ALL SELECT 'call_llm_record.request_body',                   max(octet_length(request_body))    FROM call_llm_record
UNION ALL SELECT 'call_llm_record.content',                        max(octet_length(content))         FROM call_llm_record
ORDER BY max_bytes DESC NULLS LAST;


-- =====================================================================
-- 回滚
-- =====================================================================
-- 【第一部分 · 删列】⚠️ **不可逆**。若要恢复只能：
--   ① ADD COLUMN 重新建列（类型按需要给 MEDIUMTEXT），
--   ② 再从上面的 `*_bak_ss_20260927` 备份表回灌数据（若没备份则数据已丢）。
-- ALTER TABLE app_report_ai_analysis          ADD COLUMN sourceSnapshot MEDIUMTEXT;
-- ALTER TABLE app_report_warning_advice_batch ADD COLUMN sourceSnapshot MEDIUMTEXT;
-- UPDATE app_report_ai_analysis t SET sourceSnapshot = b.sourceSnapshot
--     FROM app_report_ai_analysis_bak_ss_20260927 b WHERE b.id = t.id;
-- UPDATE app_report_warning_advice_batch t SET sourceSnapshot = b.sourceSnapshot
--     FROM app_report_warning_advice_batch_bak_ss_20260927 b WHERE b.id = t.id;
--
-- 【第二部分 · 改类型】改回 TEXT（行内同样用 `MODIFY COLUMN`）。
-- 🔴 回滚前**必须**确认该列最大字节数 ≤ 65535，否则回滚本身会报 Data too long。
--    用上面那条 max(octet_length(...)) 查询确认。
--
-- ALTER TABLE app_report_ai_analysis          MODIFY COLUMN promptsnapshot TEXT;
-- ALTER TABLE app_report_warning_advice_batch MODIFY COLUMN promptsnapshot TEXT;
-- ALTER TABLE prompt_query_result             MODIFY COLUMN query_result   TEXT;
-- ALTER TABLE prompt_query_result             MODIFY COLUMN query_param    TEXT;
-- ALTER TABLE call_llm_record                 MODIFY COLUMN request_body   TEXT;
-- ALTER TABLE call_llm_record                 MODIFY COLUMN content        TEXT;


-- =====================================================================
-- 【附 A】补回列注释（**仅当** MODIFY COLUMN 之后发现注释丢了才跑）
--   ⚠️ 本脚本的 6 列注释是独立 `COMMENT ON COLUMN`（建表脚本里就有）——
--      MySQL 语义的 MODIFY 只重置「内联 COMMENT」，正常不会动独立 COMMENT ON 的元数据；
--      但个别版本会清掉 ⇒ 改完核一下（见下），丢了再跑这几条。
-- =====================================================================
-- 核对（期望 6 行都带 comment，不为空）：
--   SELECT table_name, column_name, data_type, character_maximum_length, column_comment
--     FROM information_schema.columns
--    WHERE (table_name, column_name) IN (
--            ('app_report_ai_analysis','promptsnapshot'),
--            ('app_report_warning_advice_batch','promptsnapshot'),
--            ('prompt_query_result','query_result'),
--            ('prompt_query_result','query_param'),
--            ('call_llm_record','request_body'),
--            ('call_llm_record','content')
--          )
--    ORDER BY table_name, column_name;
--
-- 若 column_comment 为空 ⇒ 按【原建表脚本里的原文】补：
-- COMMENT ON COLUMN app_report_ai_analysis.promptsnapshot IS '实际使用的提示词快照（systemPrompt + userPrompt，userPrompt 里已含送模型的素材）';
-- COMMENT ON COLUMN app_report_warning_advice_batch.promptsnapshot IS '实际使用的提示词快照（systemPrompt + userPrompt，userPrompt 里已含送模型的素材）';
-- COMMENT ON COLUMN prompt_query_result.query_result IS '查询结果';
-- COMMENT ON COLUMN prompt_query_result.query_param  IS '查询参数';
-- COMMENT ON COLUMN call_llm_record.request_body     IS '请求体';
-- COMMENT ON COLUMN call_llm_record.content          IS '模型返回内容';

-- =====================================================================
-- 【附 B】PG 风格写法（**仅外网 openGauss 用；行内实测报「不支持 TYPE」**）
--   ⛔ 不要再把这段拿到行内跑。
-- =====================================================================
-- ALTER TABLE app_report_ai_analysis          ALTER COLUMN promptsnapshot TYPE MEDIUMTEXT;
-- ALTER TABLE app_report_warning_advice_batch ALTER COLUMN promptsnapshot TYPE MEDIUMTEXT;
-- ALTER TABLE prompt_query_result             ALTER COLUMN query_result   TYPE MEDIUMTEXT;
-- ALTER TABLE prompt_query_result             ALTER COLUMN query_param    TYPE MEDIUMTEXT;
-- ALTER TABLE call_llm_record                 ALTER COLUMN request_body   TYPE MEDIUMTEXT;
-- ALTER TABLE call_llm_record                 ALTER COLUMN content        TYPE MEDIUMTEXT;

-- =====================================================================
-- 【附 C】若 `MODIFY COLUMN` 在行内**也**报错时的退路（按顺序试，哪条通用哪条）
--   注意：这三种都是 MySQL 家族的等价写法，列定义同样只写类型。
-- =====================================================================
-- ① 省略 COLUMN 关键字：
-- ALTER TABLE app_report_ai_analysis MODIFY promptsnapshot MEDIUMTEXT;
-- ② SET DATA TYPE（部分 M 模式实现认这个）：
-- ALTER TABLE app_report_ai_analysis ALTER COLUMN promptsnapshot SET DATA TYPE MEDIUMTEXT;
-- ③ 终极退路 —— 重建列（数据量大，务必低峰；先备份）：
-- ALTER TABLE app_report_ai_analysis ADD COLUMN promptsnapshot_new MEDIUMTEXT;
-- UPDATE app_report_ai_analysis SET promptsnapshot_new = promptsnapshot;
-- ALTER TABLE app_report_ai_analysis DROP COLUMN promptsnapshot;
-- ALTER TABLE app_report_ai_analysis RENAME COLUMN promptsnapshot_new TO promptsnapshot;
