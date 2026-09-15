-- =====================================================================
-- 三个菜单 · 基础配置模板（**属于「本平台配置」，现场已有则整份跳过**）
--
-- 本交付包**不含**这三项的现成数据（有意不导公司的那份，以本平台为准），
-- 但它们是三个菜单能跑起来的前提，现场若还没配，照下面改：
--   ① sys_data_source      ≥1 条，指向行内真实业务库   ← 05_映射改写.sql 要用
--   ② large_model_config   ≥1 条且 use_flag='Y'        ← 05_映射改写.sql 要用
--   ③ sys_role.admin       菜单可见性靠 role_code='admin'（代码里走 '*' 分支）
--
-- 前置：SET search_path = <schema>, public;
-- =====================================================================

-- ① 数据源
--    ⚠️ db_password 必须存 SecurityUtil.jiami() 的**密文**（不是明文）
--    ⚠️ db_type 是数字码：4=MySQL / 6=PostgreSQL / 16=openGauss
--    ⚠️ id 是 ≤36 位字符串（不是自增数字）
INSERT INTO sys_data_source (id, code, name, remark, db_type, db_driver, db_url, db_name, db_username, db_password)
VALUES ('ds-0001',
        'boszBiz',
        '行内业务库',
        '指标取数用',
        '16',
        'org.opengauss.Driver',
        'jdbc:opengauss://<ip>:<port>/<db>',
        '<db>',
        '<user>',
        '<SecurityUtil.jiami() 生成的密文>');

SELECT id, code, name, db_type, db_driver, db_url FROM sys_data_source;

-- ② 大模型
--    ⚠️ lm_code 必须**逐字等于**后端 yml 里的 agent.rule.parse-model-code，
--       否则智策引擎会报「未找到大模型配置」、知识库预览也跑不通
--    ⚠️ api_key 用**明文**
INSERT INTO large_model_config (lm_code, model, lm_name, url, api_key, use_flag, with_think, max_tokens)
VALUES ('bosz-report-ai',
        '<模型标识，如 deepseek-flash>',
        '贷后报告-AI全文分析',
        '<https://.../chat/completions>',
        '<明文 api key>',
        'Y',
        'Y',
        8192);

SELECT lm_code, model, use_flag FROM large_model_config;

-- ③ 角色（admin 已存在时跳过）
--    admin **不需要** menu_permissions 里存那三条 agent 路径 ——
--    AuthService 对 role_code='admin' 直接返回 ["*"]，前端全放行。
INSERT INTO sys_role (role_code, role_name, description, menu_permissions)
VALUES ('admin', '系统管理员', '拥有所有权限', '[]');

-- ③b （仅当要放行**非 admin** 角色时才需要）
--     ⚠️ 下面会**整体覆盖**该角色的菜单权限，请先把原有值抄下来合并
UPDATE sys_role
   SET menu_permissions = '["/reports","/agent/index-config","/agent/knowledge-config","/agent/rule"]'
 WHERE role_code = '<非admin的角色编码>';

SELECT id, role_code, menu_permissions FROM sys_role;

-- =====================================================================
-- 配完后执行 05_映射改写.sql —— 它靠上面这两张表自动取目标口径的值。
-- =====================================================================
