-- ============================================================================
-- agent 模块 —— sys_data_source 初始数据（as_agent schema）
-- ============================================================================
-- 作用：配置「指标取数」用的数据源。指标配置里的 SQL 预览、表元数据查询、
--       数据预览、快速引入，以及智策引擎执行规则时的取值，都依赖这条配置。
--
-- 字段语义（对应 DynamicDataSourceModel）：
--   code         数据源编码 —— 动态连接池以它作为缓存 key，也是前端下拉项的 value
--   name         显示名
--   db_type      数据库类型，取 DriverTypeEnum 的 id（mysql/oracle/postgresql/dm/hive/opengauss/db2/opensearch）
--   db_driver    JDBC 驱动类全限定名（SysDataSourceServiceImpl 用它 contains 判断方言分支）
--   db_url       JDBC 连接串
--   db_username  账号
--   db_password  【密文】—— 见下方说明，不能直接填明文
--
-- ⚠️ db_password 必须加密后写入：
--   读取侧 SysDataSourceServiceImpl#toDynamicModel 会调用 SecurityUtil.jiemi(dbPassword) 解密，
--   若直接存明文，解密会抛异常，表现为「连不上库 / 认证失败」，极易误判成账号密码配错。
--
--   加密算法（与 SecurityUtil 完全一致）：
--     hutool: new SymmetricCrypto(SymmetricAlgorithm.AES, "JEECGBOOT1423670".getBytes()).encryptHex(明文)
--     JDK:    AES/ECB/PKCS5Padding，key = "JEECGBOOT1423670"（16 字节），输出小写 hex
--
--   本开发环境的示例：明文 AsAgent@2024 → 密文 3314b4d8bde42a9bbdcaad76733a1756
--   （该密文仅供本地 127.0.0.1 环境使用；换环境请重新生成，不要跨环境复制凭据）
--
-- 执行：本地库 127.0.0.1:5432/bosz，schema as_agent
-- ============================================================================

SET search_path = as_agent, public;

-- 幂等：先清理同 id / 同 code 的历史记录
DELETE FROM sys_data_source WHERE id = 'bosz-dev-local-0001' OR code = 'boszLocal';

INSERT INTO sys_data_source
    (id, code, name, remark, db_type, db_driver, db_url, db_name, db_username, db_password,
     create_by, create_time, update_by, update_time, sys_org_code)
VALUES
    ('bosz-dev-local-0001',
     'boszLocal',
     '苏州银行本地库',
     '本地开发环境：127.0.0.1:5432/bosz 的 as_agent schema（指标取数用）',
     'opengauss',
     'org.opengauss.Driver',
     'jdbc:opengauss://127.0.0.1:5432/bosz?currentSchema=as_agent',
     'bosz',
     'as_agent',
     '3314b4d8bde42a9bbdcaad76733a1756',   -- AsAgent@2024 的密文（仅本地环境）
     'agent', now(), 'agent', now(), NULL);

-- 校验（如需人工核对，去掉注释单独执行）：
-- SELECT id, code, name, db_type, db_driver, db_url, db_name, db_username FROM sys_data_source;
