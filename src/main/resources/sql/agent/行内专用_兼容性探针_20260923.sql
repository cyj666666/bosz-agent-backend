-- =====================================================================
-- 【行内专用】GaussDB 兼容性探针（2026-09-23）
-- =====================================================================
-- 目的：**逐条**在行内库上执行，把"哪些 PG 写法能用、哪些必须改"一次性摸清。
--       只有拿到结果，改 SQL 才不是瞎猜 —— 改错一次就要在内网再来回一趟。
--
-- 用法（重要）：
--   ① **一条一条单独执行**（不要整段跑）—— 报错的那条就记下来，继续跑下一条。
--   ② 每条都带行号列 `seq`，方便对照本文件。
--   ③ 把"报错的 seq 列表"发回来即可，我来定批量改法。
--
-- 判定口径：某条**报错** ⇒ 该写法在本库不可用；某条**返回 OK** ⇒ 可用。
-- =====================================================================


-- =====================================================================
-- 第 1 组 · 库身份（先确认兼容模式，这是所有判断的根）
-- =====================================================================

-- 1.1 兼容模式（GaussDB 常规可查；返回 B = MySQL 兼容 / A = Oracle兼容 / PG = PG兼容）
SHOW sql_compatibility; -- M

-- 1.2 版本
SELECT 12 AS seq, version(); --gaussdb(GAUSSDB Kernel 505.2.1.SPC0800 build)

-- 1.3 库名 + 兼容模式（PG 侧视图，MySQL 模式可能查不到 —— 查不到不算错）
SELECT 13 AS seq, datname, datcompatibility FROM pg_database WHERE datname = current_database(); -- 12/plmadbsit/M


-- =====================================================================
-- 第 2 组 · 类型转换 `::` vs `CAST`（仓库里 397 处 `::` 都卡这里）
-- =====================================================================

-- 2.1 PG 转写语法（预期：行内报 syntax error near "text"）
SELECT 21 AS seq, '1'::text AS v; 21 1

-- 2.2 ✅ 标准 CAST —— 这是首选替代（外网 PG 也认，两库交集）
SELECT 22 AS seq, CAST('1' AS INTEGER) AS v; --syntax error at or near "INTEGER"

-- 2.3 CAST 的短名写法
SELECT 23 AS seq, CAST('1' AS INT) AS v;--syntax error at or near "INT"

-- 2.4 MySQL 系写法（PG 不认 —— 若只有这条能跑，说明不能用 2.2）
SELECT 24 AS seq, CAST('1' AS SIGNED) AS v; -- 24,1

-- 2.5 转字符串：**注意别用 VARCHAR / CHAR**
--     实测：`CAST(x AS varchar)` 在行内报 syntax error near "varchar"
SELECT 25 AS seq, CAST(1 AS CHAR) AS v;--25,1

-- 2.6 数字转字符串的**两库交集写法**（无论 2.5 结果如何，这条都该 OK）
SELECT 26 AS seq, concat('', 1) AS v; --26,1

-- 2.7 转日期
SELECT 27 AS seq, CAST('20260901' AS DATE) AS v;-- 正常

-- 2.8 小数（指标 SQL 大量用到）
SELECT 28 AS seq, CAST('58.2' AS DECIMAL(18,4)) AS v; -- 正常


-- =====================================================================
-- 第 3 组 · 字符串拼接 `||` vs `concat`（仓库里 2432 处）
-- =====================================================================

-- 3.1 `||` 的真实行为：**光看报不报错不够，要看返回值**
--     若返回 'a1' ⇒ 是拼接；若返回 0/1 或报错 ⇒ 被当逻辑或
SELECT 31 AS seq, 'a' || '1' AS v; --31，[v]

-- 3.2 concat 接字符串
SELECT 32 AS seq, concat('2026', '0901') AS v; --正常

-- 3.3 concat 接**数字**（指标 SQL 里形如 ACCOUNTMONTH || '01'，ACCOUNTMONTH 常是数字）
SELECT 33 AS seq, concat(202609, '01') AS v; --33,20260901

-- 3.4 concat 遇 NULL（`||` 遇 NULL 返回 NULL；concat 会忽略 —— **语义差异，需要知道**）
SELECT 34 AS seq, concat('a', NULL, 'b') AS v; --34,null


-- =====================================================================
-- 第 4 组 · 日期函数（诊断报告建议把 TO_DATE 换 STR_TO_DATE，**先验证别乱换**）
-- =====================================================================

-- 4.1 TO_DATE 是否可用（三参/两参形态）
SELECT 41 AS seq, TO_DATE('20260901', 'YYYYMMDD') AS v; -- 正常
SELECT 42 AS seq, TO_DATE('2026-09-01', 'YYYY-MM-DD') AS v;-- 正常

-- 4.2 换成字符串拼接后的 TO_DATE（这才是报错现场的正确形态）
SELECT 43 AS seq, TO_DATE(concat('2026', '0901'), 'YYYYMMDD') AS v;-- 正常

-- 4.3 STR_TO_DATE（MySQL 系）—— 若 4.1 可用就**不要用它**，PG 模式没有它
SELECT 44 AS seq, STR_TO_DATE('20260901', '%Y%m%d') AS v;-- 正常

-- 4.4 取当前月的 01 号
SELECT 45 AS seq, to_char(CURRENT_DATE, 'YYYYMM') AS v;-- 5747207


-- =====================================================================
-- 第 5 组 · 标识符引号（`"CONDITION"` / `"group"` 报错的根治点）
-- =====================================================================

-- 5.1 双引号做**别名**（报错 ⇒ 双引号不是标识符定界符）
SELECT 51 AS seq, 1 AS "CONDITION";-- 51,1

-- 5.2 反引号做**别名**
SELECT 52 AS seq, 1 AS `CONDITION`; -- 52,1

-- 5.3 裸写保留字做别名（不带任何引号）
SELECT 53 AS seq, 1 AS CONDITION; -- 53,1

-- 5.4 🔴 关键：行内 `app_credit_approval_manage_req_info` 里那个列，**实际叫什么**
--     （返回的 column_name 大小写形态，决定 SQL 里该怎么写）
SELECT 54 AS seq, column_name, data_type, character_maximum_length
  FROM information_schema.columns
 WHERE table_name = 'app_credit_approval_manage_req_info'
   AND lower(column_name) = 'condition'; -- 54，CONDITION，text，65535

-- 5.5 🔴 同理查那个 `"group"` 列（在哪张表里）
SELECT 55 AS seq, table_name, column_name
  FROM information_schema.columns
 WHERE lower(column_name) = 'group'
 ORDER BY table_name; --55，app_opinion,group


-- =====================================================================
-- 第 6 组 · 连接方式（`FULL OUTER JOIN` 报 syntax error near "FULL"）
-- =====================================================================

-- 6.1 FULL OUTER JOIN（行内预期报错）
SELECT 61 AS seq, count(*) AS v
  FROM (SELECT 1 AS x) a
  FULL OUTER JOIN (SELECT 1 AS x) b ON a.x = b.x; --报 syntax error near "FULL"

-- 6.2 ✅ 替代形态 A：LEFT JOIN + 补 UNION（两库通吃，改写时用这个）
SELECT 62 AS seq, count(*) AS v
  FROM (SELECT 1 AS x) a
  LEFT JOIN (SELECT 1 AS x) b ON a.x = b.x; --62,1

-- 6.3 替代形态 B：`UNION` 去重拼接（做"两表并集"更直接）
SELECT 63 AS seq, count(*) AS v FROM (SELECT 1 AS x UNION SELECT 2) t; --63,2

-- 6.4 派生表是否需要别名（MySQL 系强制要求 AS）
SELECT 64 AS seq, count(*) AS v FROM (SELECT 1 AS x) t; --64,1


-- =====================================================================
-- 第 7 组 · JSON / 其他 PG 函数（诊断报告提到 json_build_object）
-- =====================================================================

-- 7.1 PG 风格
SELECT 71 AS seq, json_build_object('a', 1) AS v; -- 71,{"a",1}

-- 7.2 标准/MySQL 风格
SELECT 72 AS seq, CAST('{"a":1}' AS JSON) AS v; -- 71,{"a",1}

-- 7.3 常用聚合/字符串函数的交集形态
SELECT 73 AS seq, coalesce(NULL, 'x') AS v; --73,x
SELECT 74 AS seq, length('abc') AS v; --74,3
SELECT 75 AS seq, substring('abcdef', 1, 3) AS v; -- 75,abc
SELECT 76 AS seq, position('b' IN 'abc') AS v; --76,2

-- 7.4 行号/分页（PG 系支持，MySQL 系可能要 LIMIT）
SELECT 77 AS seq, 1 AS v LIMIT 1; --77,1


-- =====================================================================
-- 第 8 组 · 容量问题（`Data too long for type text` —— prompt_query_result.query_result）
-- =====================================================================

-- 8.1 该列**实际**的类型与长度（诊断说 DDL 写 TEXT，实际带长度上限）
SELECT 81 AS seq, column_name, data_type, character_maximum_length, udt_name
  FROM information_schema.columns
 WHERE table_name = 'prompt_query_result'
   AND column_name IN ('query_result', 'prompt', 'result'); -- udtname不存在

-- 8.2 该表全部列（一次看清）
SELECT 82 AS seq, column_name, data_type, character_maximum_length
  FROM information_schema.columns
 WHERE table_name = 'prompt_query_result'
 ORDER BY ordinal_position; --query_result,text,65535

-- 8.3 现在最长的一条有多长（判断要扩容到多少）
--     ⚠️ 若 8.1 显示 character_maximum_length 为 NULL 或极大，说明确实是 TEXT，那问题在别处
SELECT 83 AS seq, max(length(query_result)) AS max_len, count(*) AS cnt
  FROM prompt_query_result; -- 83,32542,124


-- =====================================================================
-- 第 9 组 · 触发现场的原始语句（直接复现，比推理可靠）
-- =====================================================================

-- 9.1 把报错的那条指标 SQL 里最可疑的两个片段，单独拉出来跑：
--     ① `::` 片段（取自 SHAREHOLDERVS / 报 near "INTEGER" 的）
--     ② `||` 片段（取自 ACCOUNTMONTH || '01'）
--     把这两行换成你日志里的**原样片段**再跑（下面是我按现象重建的最小版）
SELECT 91 AS seq, concat('2026', '0901') || '' AS v;  --91,[v]    -- 同时含 concat 与 || 的形态
SELECT 92 AS seq, CAST(1 AS INTEGER) AS v;      --报near "INTEGER"            -- :: 的替代是否真能跑


-- =====================================================================
-- 附：本探针要回答的 4 个问题
-- =====================================================================
-- Q1 行内到底是哪种兼容模式？（第 1 组）
-- Q2 `::` 能不能用？不能用的话 `CAST(... AS INTEGER)` 行不行？（第 2 组）
-- Q3 `||` 是拼接还是逻辑或？`concat()` 能不能完全替代（含 NULL 语义）？（第 3 组）
-- Q4 双引号标识符能不能用？那两个保留字列在库里**实际叫什么**？（第 5 组）
--    ⇒ Q4 决定 `"CONDITION"`/`"group"` 是"改引号"还是"改列名/删掉保留字"


-- =====================================================================
-- 第 10 组 · 【第二轮补充】修 16 条指标 SQL 所依赖的写法
--   背景：本地库 820 条 script 里只有 16 条含问题（::INTEGER 28 处 / ::DATE 3 处 /
--        || 2 处 / FULL OUTER JOIN 2 处 / EXTRACT(EPOCH 1 处 / ADD_MONTHS 1 处）。
--        下面这些是"改法能不能用"的直接判据，**逐条跑**。
-- =====================================================================

-- 10.1 整数语义 —— 拟用 `CAST(x AS DECIMAL(18,0))` 替代 `::INTEGER`（要用 28 处）
SELECT 101 AS seq, CAST('202609' AS DECIMAL(18,0)) AS v;                 -- 期望 202609
SELECT 102 AS seq, CAST('202609' AS DECIMAL(18,0)) / 100 AS v;           -- 期望 2026.09
SELECT 103 AS seq, FLOOR(CAST('202609' AS DECIMAL(18,0)) / 100) AS v;    -- 期望 2026
SELECT 104 AS seq, CAST(202609 AS DECIMAL(18,0)) AS v;                   -- 数字入参也要能用

-- 10.2 `::DATE`（`stzfdxzxjdqys` 用了 3 处）—— 注意 `::INTEGER` 不可用，但类型名 DATE 也许认
SELECT 105 AS seq, '20260901'::DATE AS v;
SELECT 106 AS seq, CAST('20260901' AS DATE) AS v;                        -- 对照（第 2 组已知可用）

-- 10.3 🔴 `EXTRACT(EPOCH FROM ...)`（`stzfdxzxjdqys`，PG 特有）
SELECT 107 AS seq,
       EXTRACT(EPOCH FROM (CAST('2026-09-01' AS DATE) - CAST('2026-08-01' AS DATE))) AS v;

-- 10.4 日期差的替代写法（同上那条 SQL 需要"两个日期差多少天/月"）
SELECT 108 AS seq, DATEDIFF(CAST('2026-09-01' AS DATE), CAST('2026-08-01' AS DATE)) AS v;   -- MySQL 系
SELECT 109 AS seq, CAST('2026-09-01' AS DATE) - CAST('2026-08-01' AS DATE) AS v;             -- PG 系
SELECT 110 AS seq, TIMESTAMPDIFF(MONTH, CAST('2026-08-01' AS DATE), CAST('2026-09-01' AS DATE)) AS v;

-- 10.5 🔴 `ADD_MONTHS(date, n)`（`zxycwjc`，Oracle 函数）
SELECT 111 AS seq, ADD_MONTHS(CAST('2026-09-01' AS DATE), 4) AS v;
SELECT 112 AS seq, DATE_ADD(CAST('2026-09-01' AS DATE), INTERVAL 4 MONTH) AS v;              -- MySQL 系
SELECT 113 AS seq, CAST('2026-09-01' AS DATE) + INTERVAL '4' MONTH AS v;                     -- PG 系

-- 10.6 日期与 timestamp 比较（`zxycwjc` 里 c.QUERYTIME >= TO_DATE(...)）
SELECT 114 AS seq, CASE WHEN CURRENT_TIMESTAMP >= TO_DATE(concat('2026', '0901'), 'YYYYMMDD')
                        THEN 'OK' ELSE 'FAIL' END AS v;

-- 10.7 大数精度（ACCOUNTMONTH 是 6 位，确认 DECIMAL(18,0) 绰绰有余）
SELECT 115 AS seq, CAST('999999999999999999' AS DECIMAL(18,0)) AS v;


-- =====================================================================
-- 第 11 组 · 【第三轮补充】`CAST(... AS UNSIGNED/SIGNED)` 引发的
--            `不良的类型值 bigdecimal`（2026-09-23 现场报错）
--   背景：指标 SQL 里 `CAST(f.ACCOUNTMONTH AS UNSIGNED)` 报「不良的类型值 bigdecimal」+ 语法错。
--        已确认 ACCOUNTMONTH 数据是干净的（varchar(32)，值全是 6 位数字，无 NULL/空串）。
--        ⇒ 怀疑是 **CAST 的目标类型** 有问题（UNSIGNED 未验证；且返回的非标类型会让 JDBC 映射 BigDecimal 失败）。
--   ⚠️ 请在 DBeaver 里**留意每列显示的返回类型**（不只是值）—— 那是判断 JDBC 能否映射的关键。
-- =====================================================================

-- 11.1 `UNSIGNED` 能不能用（**现场用的就是它**，前面探针没测过）
SELECT 201 AS seq, CAST('202603' AS UNSIGNED) AS v_unsigned;
SELECT 202 AS seq, CAST('202603' AS SIGNED) AS v_signed;        -- 第 2 组 2.4 已证可用

-- 11.2 DECIMAL —— 推荐替代（标准 numeric，JDBC → BigDecimal 无争议）
SELECT 203 AS seq, CAST('202603' AS DECIMAL(18,0)) AS v;
SELECT 204 AS seq, CAST('202603' AS DECIMAL(18,0)) / 100 AS v;          -- 期望 2026.03
SELECT 205 AS seq, FLOOR(CAST('202603' AS DECIMAL(18,0)) / 100) AS v;   -- 期望 2026

-- 11.3 🔴 并排对比返回类型（关键：看 UNSIGNED 出来的是什么类型）
SELECT 206 AS seq,
       CAST('202603' AS UNSIGNED)       AS v_unsigned,
       CAST('202603' AS SIGNED)         AS v_signed,
       CAST('202603' AS DECIMAL(18,0))  AS v_decimal;

-- 11.4 不加 CAST，让 GaussDB 自己隐式转（看是否可行）
SELECT 207 AS seq, CASE WHEN '202603' = 202603 THEN 'OK' ELSE 'NO' END AS v;

-- 11.5 这条 SQL 里的其它可疑片段
SELECT 208 AS seq, SUBSTRING(TRIM('20251231'), 1, 6) AS v;      -- TRIM+SUBSTRING
SELECT 209 AS seq, NULLIF(ABS(CAST('58.2' AS DECIMAL(18,4))), 0) AS v;
SELECT 210 AS seq, ROUND(ABS(CAST('1.5' AS DECIMAL(18,4))) / NULLIF(ABS(CAST('3' AS DECIMAL(18,4))), 0) * 100, 2) AS v;

-- 11.6 `CAST` 到 DECIMAL 时遇到空串/NULL（防御性确认，虽然本批数据是干净的）
SELECT 211 AS seq, CAST(NULL AS DECIMAL(18,0)) AS v;
SELECT 212 AS seq, CAST('' AS DECIMAL(18,0)) AS v;              -- 可能报错，报错也正常（记录即可）
