-- =====================================================================
-- 报告主表 report · 最终 DDL（取代 app_report_info）
-- 数据库：高斯DB（GaussDB，风格同 20260819 建表脚本）
-- 说明  ：报告实例生成模块的报告记录由上游预生成（初始 status=111-待开始），
--         生成服务只负责状态流转（000 进行中 / 888 已完成 / 999 失败）与失败原因落库。
--         本表列名为下划线命名（snake_case），对应实体 com.suzhou.bank.entity.Report
--         （@TableName("report")）。
-- 关键字段：
--   · report_no    报告编号（业务唯一键，VARCHAR(64)）
--   · check_task_no 日检流水号（同一流水号下多个版本）
--   · version      报告版本号（整数 1/2/3…，区分历史版本；"V"前缀由前端拼接）
--   · status       111-待开始 / 000-进行中 / 888-已完成 / 999-失败
--   · fail_reason  生成失败时记录技术/业务异常详情（成功为空）
-- 已建库环境：直接执行文件「二、已建库补丁（ALTER）」段即可，无需重建表。
-- 日期  ：2026-09-12
-- =====================================================================


-- ---------------------------------------------------------------------
-- 一、全新环境完整建表（与 init_db_gaussdb.sql 中 report 表保持一致）
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS report (
    id              BIGINT NOT NULL AUTO_INCREMENT,
    report_no       VARCHAR(64),
    customer_id     VARCHAR(64) NOT NULL,
    customer_name   VARCHAR(200),
    check_task_no   VARCHAR(64),
    user_no         VARCHAR(64),
    version         INTEGER,
    report_title    VARCHAR(300) NOT NULL,
    report_type     VARCHAR(50) NOT NULL,
    status          VARCHAR(20) DEFAULT '111',
    fail_reason     VARCHAR(1024),
    know_kit_task_id BIGINT,
    content_html    TEXT,
    data_snapshot   TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_report_no ON report (report_no);
CREATE INDEX IF NOT EXISTS idx_report_customer_id ON report (customer_id);
CREATE INDEX IF NOT EXISTS idx_report_report_type ON report (report_type);
CREATE INDEX IF NOT EXISTS idx_report_check_task_no ON report (check_task_no);

COMMENT ON TABLE report IS '贷后报告主表（报告实例入口，取代 app_report_info）';
COMMENT ON COLUMN report.report_no IS '报告编号（业务唯一键，VARCHAR(64)，关联内容实例表与 AI 风险表）';
COMMENT ON COLUMN report.customer_id IS '客户编号';
COMMENT ON COLUMN report.customer_name IS '客户名称';
COMMENT ON COLUMN report.check_task_no IS '日检任务编号（日检流水号）';
COMMENT ON COLUMN report.version IS '报告版本号（整数 1/2/3…，同一日检流水号下区分历史版本；仅已完成（888）时赋予，失败/未完成可为空；展示时由前端拼 V 前缀）';
COMMENT ON COLUMN report.report_title IS '报告标题';
COMMENT ON COLUMN report.report_type IS '报告类型';
COMMENT ON COLUMN report.status IS '报告状态：111-待开始 000-进行中 888-已完成 999-失败';
COMMENT ON COLUMN report.fail_reason IS '失败原因（生成过程发生技术类/业务类异常时记录详细信息，成功时为空）';
COMMENT ON COLUMN report.created_at IS '入库时间';
COMMENT ON COLUMN report.updated_at IS '更新时间（状态流转/失败原因写入时刷新）';


-- ---------------------------------------------------------------------
-- 二、已建库补丁（ALTER）：把"旧版 report 表"升级为上述最终结构
--     适用：库中已存在旧版 report 表（缺 report_no / customer_name / check_task_no /
--           user_no / version / fail_reason 等列）。
--     说明：若某列已补过，对应 ADD COLUMN 会报"column already exists"，
--           属正常现象，跳过该条继续执行即可。
-- ---------------------------------------------------------------------
-- 1) 补缺失列
ALTER TABLE report ADD COLUMN report_no VARCHAR(64);
ALTER TABLE report ADD COLUMN customer_name VARCHAR(200);
ALTER TABLE report ADD COLUMN check_task_no VARCHAR(64);
ALTER TABLE report ADD COLUMN user_no VARCHAR(64);
ALTER TABLE report ADD COLUMN fail_reason VARCHAR(1024);
-- 2) customer_id 类型统一为 VARCHAR(64)（旧表可能为 BIGINT）
ALTER TABLE report MODIFY COLUMN customer_id VARCHAR(64);
-- 3) status 默认值改为 111（待开始）
ALTER TABLE report MODIFY COLUMN status VARCHAR(20) DEFAULT '111';
-- 4) report_no 唯一索引（已存在则跳过）
CREATE UNIQUE INDEX uk_report_no ON report (report_no);

-- 5) version 列：最终为整数（INTEGER），二选一执行
--    5.1 若 report 表【没有】version 列 → 直接新增整数列：
ALTER TABLE report ADD COLUMN version INTEGER;
--    5.2 若 report 表【已有】version 列且是字符串（VARCHAR，值形如 'V1'/'V2'）→ 执行迁移，
--        此时【不要】执行 5.1；迁移后 version 由 'V1' 变为 1，历史数据不丢：
-- ALTER TABLE report ADD COLUMN version_num INTEGER;
-- UPDATE report SET version_num = CAST(REGEXP_REPLACE(version, '[^0-9]', '', 'g') AS INTEGER)
--  WHERE version IS NOT NULL AND REGEXP_REPLACE(version, '[^0-9]', '', 'g') <> '';
-- ALTER TABLE report DROP COLUMN version;
-- ALTER TABLE report RENAME COLUMN version_num TO version;


-- ---------------------------------------------------------------------
-- 三、清理旧表 app_report_info（可选，仅当库中已建该表且确认不再使用）
--     报告实例生成模块已完全改用 report，不再读写 app_report_info。
--     执行前请确认无其他系统依赖该表。
-- ---------------------------------------------------------------------
-- DROP TABLE IF EXISTS app_report_info;
