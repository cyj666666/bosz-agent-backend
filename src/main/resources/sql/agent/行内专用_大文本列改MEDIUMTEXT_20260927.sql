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
--   4. 脚本用 `ALTER COLUMN ... TYPE`（PG 语法）。**若行内报语法错**，改用文末的 `MODIFY COLUMN` 备选写法。
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
ALTER TABLE app_report_ai_analysis ALTER COLUMN promptsnapshot TYPE MEDIUMTEXT;

-- ---------------------------------------------------------------------
-- ⑥ 报告预警建议批次（同上，由 ReportWarningAdviceTask 写入）
-- ---------------------------------------------------------------------
ALTER TABLE app_report_warning_advice_batch ALTER COLUMN promptsnapshot TYPE MEDIUMTEXT;

-- ---------------------------------------------------------------------
-- ③ prompt 请求结果记录（query_result 已实际报过 Data too long）
-- ---------------------------------------------------------------------
ALTER TABLE prompt_query_result ALTER COLUMN query_result TYPE MEDIUMTEXT;
ALTER TABLE prompt_query_result ALTER COLUMN query_param  TYPE MEDIUMTEXT;

-- ---------------------------------------------------------------------
-- ④ 大模型调用记录（request_body = 完整请求体，content = 模型完整输出）
-- ---------------------------------------------------------------------
ALTER TABLE call_llm_record ALTER COLUMN request_body TYPE MEDIUMTEXT;
ALTER TABLE call_llm_record ALTER COLUMN content      TYPE MEDIUMTEXT;


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
-- 【第二部分 · 改类型】改回 TEXT。
-- 🔴 回滚前**必须**确认该列最大字节数 ≤ 65535，否则回滚本身会报 Data too long。
--    用上面那条 max(octet_length(...)) 查询确认。
--
-- ALTER TABLE app_report_ai_analysis          ALTER COLUMN promptsnapshot TYPE TEXT;
-- ALTER TABLE app_report_warning_advice_batch ALTER COLUMN promptsnapshot TYPE TEXT;
-- ALTER TABLE prompt_query_result             ALTER COLUMN query_result   TYPE TEXT;
-- ALTER TABLE prompt_query_result             ALTER COLUMN query_param    TYPE TEXT;
-- ALTER TABLE call_llm_record                 ALTER COLUMN request_body   TYPE TEXT;
-- ALTER TABLE call_llm_record                 ALTER COLUMN content        TYPE TEXT;


-- =====================================================================
-- 备选写法（仅当上面 `ALTER COLUMN ... TYPE` 报语法错时使用）
--   M 兼容模式下 MySQL 风格语法同样可用：
--   ⚠️ MODIFY COLUMN 只用于「改类型」（第二部分）；DROP COLUMN 两种模式语法一致，无需备选。
-- =====================================================================
-- ALTER TABLE app_report_ai_analysis          MODIFY COLUMN promptsnapshot MEDIUMTEXT;
-- ALTER TABLE app_report_warning_advice_batch MODIFY COLUMN promptsnapshot MEDIUMTEXT;
-- ALTER TABLE prompt_query_result             MODIFY COLUMN query_result   MEDIUMTEXT;
-- ALTER TABLE prompt_query_result             MODIFY COLUMN query_param    MEDIUMTEXT;
-- ALTER TABLE call_llm_record                 MODIFY COLUMN request_body   MEDIUMTEXT;
-- ALTER TABLE call_llm_record                 MODIFY COLUMN content        MEDIUMTEXT;
