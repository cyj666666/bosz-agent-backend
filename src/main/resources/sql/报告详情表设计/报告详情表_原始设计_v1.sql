-- =============================================================================
-- 报告详情页 · 通用模板表结构 DDL（原始设计 v1）
-- 数据库   : MySQL 8.0+ （InnoDB / utf8mb4）
-- 内容     : 按原始设计仅包含两张配置表
--            1) 目录表           —— 报告左侧目录树（一级/二级/三级，可配置）
--            2) 报告正文内容表   —— 每个目录关联 N 个内容块，按填充类型渲染
-- 生成日期 : 2026-09-10
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. 目录表
--    报告左侧目录列表，支持一级、二级、三级目录，可配置化。
--    约定：
--      · 一级目录 parent_code 为 NULL；
--      · 目录级别应用层校验 level = 上级目录.level + 1；
--      · sort_no 为同一上级目录内的排序。
-- -----------------------------------------------------------------------------
CREATE TABLE `t_report_catalog` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键（自增）',
  `catalog_code`  VARCHAR(64)  NOT NULL                COMMENT '目录编号（全局唯一）',
  `catalog_name`  VARCHAR(128) NOT NULL                COMMENT '目录名称',
  `catalog_level` TINYINT      NOT NULL                COMMENT '目录级别：1-一级 2-二级 3-三级',
  `parent_code`   VARCHAR(64)           DEFAULT NULL   COMMENT '上级目录编号（一级目录为 NULL，其余必填）',
  `sort_no`       INT          NOT NULL DEFAULT 0      COMMENT '排序（同一上级目录内）',
  `is_enabled`    TINYINT(1)   NOT NULL DEFAULT 1      COMMENT '是否可用：1-可用 0-停用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_catalog_code` (`catalog_code`),
  KEY `idx_parent_code` (`parent_code`),
  KEY `idx_level_enabled` (`catalog_level`, `is_enabled`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '报告详情-目录配置表（模板层·目录树）';


-- -----------------------------------------------------------------------------
-- 2. 报告正文内容表
--    每个目录（catalog_code）下挂 N 个内容块，前端按 sort_no 顺序渲染。
--    填充类型 fill_type 枚举：
--        TITLE       - 标题     （仅为兼容固定标题展示，整块只有一个标题）
--        TEXT        - 文本     （analysis_type / agent_code 仅在该类型下有值）
--        TABLE       - 表格
--        SOURCE_LINK - 溯源链接
--    分析文本类型 analysis_type 枚举（仅 fill_type = TEXT 时有值）：
--        RULE     - 经验规则类
--        ANALYSIS - 文本分析类
-- -----------------------------------------------------------------------------
CREATE TABLE `t_report_content_block` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键（自增）',
  `block_code`    VARCHAR(64)  NOT NULL                COMMENT '内容块编号（全局唯一）',
  `catalog_code`  VARCHAR(64)  NOT NULL                COMMENT '所属目录编号（关联 t_report_catalog.catalog_code）',
  `fill_type`     VARCHAR(16)  NOT NULL                COMMENT '填充类型：TITLE-标题 TEXT-文本 TABLE-表格 SOURCE_LINK-溯源链接',
  `analysis_type` VARCHAR(16)           DEFAULT NULL   COMMENT '分析文本类型：RULE-经验规则类 ANALYSIS-文本分析类（仅 fill_type=TEXT 时有值，否则为 NULL）',
  `agent_code`    VARCHAR(64)           DEFAULT NULL   COMMENT '智能体编码（仅 fill_type=TEXT 时有值，否则为 NULL）',
  `sort_no`       INT          NOT NULL DEFAULT 0      COMMENT '排序（同一目录内内容块顺序）',
  `is_enabled`    TINYINT(1)   NOT NULL DEFAULT 1      COMMENT '是否可用：1-可用 0-停用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_block_code` (`block_code`),
  KEY `idx_catalog_code` (`catalog_code`),
  KEY `idx_fill_type` (`fill_type`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '报告详情-正文内容块配置表（模板层·内容块）';
