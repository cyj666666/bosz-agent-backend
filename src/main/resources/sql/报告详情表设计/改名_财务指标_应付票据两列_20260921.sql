-- =====================================================================
-- 改名：app_finance_indicator_info —— 应付票据「较年初变动 / 增幅」两列拼写修正
--
--   旧（库里现状，错）：notepayablechangefromyearstart      ← 少一个 s
--   新（DDL / 指标 SQL，对）：notespayablechangefromyearstart
--
--   旧（库里现状，错）：notepayablechangefromyearstartrate  ← 少一个 s
--   新（DDL / 指标 SQL，对）：notespayablechangefromyearstartrate
--
-- 背景（2026-09-21 实测）：
--   同一张表的 pos 41 `notespayable`（应付票据）**本身是带 s 的**，
--   说明这两列是后加时手抖漏了字母。结果 30 条指标 SQL（引用正确名
--   `notespayablechangefromyearstart`）全部报：
--       ERROR: column i.notespayablechangefromyearstart does not exist
--   本地错误日志里该报错出现 512 次。
--
-- 为什么用 RENAME 而不是 DROP + ADD：
--   🔴 该表共 24 行，这两列各有 **18 行非空数据** ⇒ DROP 会丢数据；
--      RENAME 保留数据，且**原注释自动跟随**（已核对，注释本来就写对了）。
--
-- 安全性（已实测，非推断）：
--   · 全仓 SQL grep 旧名 → 0 处命中（改掉不会断开任何配置/脚本）
--   · 库侧 index_params.script 引用旧名 → 0 条；引用新名 → 30 条（改完立即生效）
--   · 视图 / 函数引用旧名 → 0
--   · 新列名当前不存在 ⇒ 不会撞名
--   · 两列类型沿用原 `numeric`，本脚本不动类型（避免无谓风险）
--
-- 执行前置：按你的 schema 调整下面这行（本项目 schema = as_agent）。
-- 幂等性：**非幂等** —— 重复执行会报 column "notepayablechangefromyearstart" does not exist，
--         属正常，说明已经改过了（跑末尾复核 SQL 确认即可）。
-- =====================================================================

SET search_path = as_agent;

BEGIN;

ALTER TABLE app_finance_indicator_info
    RENAME COLUMN notePayableChangeFromYearStart TO notesPayableChangeFromYearStart;

ALTER TABLE app_finance_indicator_info
    RENAME COLUMN notePayableChangeFromYearStartRate TO notesPayableChangeFromYearStartRate;

COMMIT;

-- =====================================================================
-- 执行后复核 ①：这两列应变成「带 s」的正确名（结果里不应再出现少 s 的那两个）
-- =====================================================================
SELECT ordinal_position AS pos, column_name, data_type
  FROM information_schema.columns
 WHERE table_schema = current_schema()
   AND lower(table_name) = 'app_finance_indicator_info'
   AND lower(column_name) LIKE '%payable%'
 ORDER BY ordinal_position;

-- =====================================================================
-- 执行后复核 ②：数据没丢（应仍为 18 / 18）
-- =====================================================================
SELECT count(*) AS total_rows,
       count(notespayablechangefromyearstart)     AS col1_notnull,
       count(notespayablechangefromyearstartrate) AS col2_notnull
  FROM app_finance_indicator_info;
