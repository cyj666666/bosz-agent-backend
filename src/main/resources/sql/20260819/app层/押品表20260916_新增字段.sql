-- =====================================================================
-- 苏州银行 贷后报告 押品表结构变更：app_collateral_info 新增 4 列
-- 目标表：app_collateral_info（押品主档表）
-- 依据：同事反馈的表结构变更 —— 新增 4 个「是否存在 XX 登记」标志位
-- 说明：
--   1. 若目标表已按最新建表脚本重建，无需执行本脚本。最新建表脚本有两处，均已同步这 4 列：
--      · DDL/06_F_贷后报告业务表_45张.sql（交付包全量，见文件头说明 8）
--      · app_贷后报告_建表脚本.sql
--   2. 本脚本供**已建库**的环境增量执行，与上述两份建表脚本保持一致；
--   3. 4 列均为标志位 VARCHAR(2)，未设默认值，历史数据为 NULL（不加非空约束，避免存量数据报错）；
--   4. 脚本内**无 `IF NOT EXISTS`**（遵循本项目 DDL 约定）：已执行过的环境请勿重复执行，重复会报「列已存在」。
-- =====================================================================

-- ---------- app_collateral_info：+dyqdj / yydj / cfdj / ygdj ----------
ALTER TABLE app_collateral_info ADD COLUMN dyqdj VARCHAR(2);
COMMENT ON COLUMN app_collateral_info.dyqdj IS '是否存在地役权登记';

ALTER TABLE app_collateral_info ADD COLUMN yydj VARCHAR(2);
COMMENT ON COLUMN app_collateral_info.yydj IS '是否存在异议登记';

ALTER TABLE app_collateral_info ADD COLUMN cfdj VARCHAR(2);
COMMENT ON COLUMN app_collateral_info.cfdj IS '是否存在查封登记';

ALTER TABLE app_collateral_info ADD COLUMN ygdj VARCHAR(2);
COMMENT ON COLUMN app_collateral_info.ygdj IS '是否存在预告登记';
