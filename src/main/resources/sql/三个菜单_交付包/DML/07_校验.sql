-- =====================================================================
-- 三个菜单 · DML 步骤 4/4 —— 校验（照跑，看「实际值」列）
-- 期望值参考：本地 2026-09-15 实跑的结果（见下表注释）
-- =====================================================================

-- 【一】数据是否导全（期望值 = 公司库行数）
SELECT 'index_base_group'              AS 表, count(*) AS 实际值, 40   AS 期望值 FROM index_base_group
UNION ALL SELECT 'index_params',              count(*), 1086 FROM index_params
UNION ALL SELECT 'index_relate_knowledge_info', count(*), 492 FROM index_relate_knowledge_info
UNION ALL SELECT 'knowledge_base_group',      count(*), 25   FROM knowledge_base_group
UNION ALL SELECT 'knowledge_base_params',     count(*), 86   FROM knowledge_base_params
UNION ALL SELECT 'knowledge_base_version',    count(*), 1    FROM knowledge_base_version
UNION ALL SELECT 'knowledge_relate_index',    count(*), 493  FROM knowledge_relate_index
UNION ALL SELECT 'knowledge_relate_input_param', count(*), 9 FROM knowledge_relate_input_param
UNION ALL SELECT 'agent_rule',                count(*), 42   FROM agent_rule
UNION ALL SELECT 'sys_dict',                  count(*), 88   FROM sys_dict
UNION ALL SELECT 'sys_dict_item',             count(*), 24   FROM sys_dict_item
ORDER BY 1;

-- 【二】映射改写是否生效（①②③④ 四个"残留"都必须是 0）
SELECT '① 旧数据源id残留(期望0)'      AS 检查项, count(*) AS 实际值 FROM index_params            WHERE script LIKE '%2095447359636992001%'
UNION ALL SELECT '② 旧模型code残留(期望0)',   count(*) FROM knowledge_base_params  WHERE large_model_code IS NOT NULL AND large_model_code <> (SELECT lm_code FROM large_model_config WHERE use_flag='Y' ORDER BY id LIMIT 1)
UNION ALL SELECT '③ 旧JSON-key残留(期望0)',   count(*) FROM knowledge_base_params  WHERE large_model_content LIKE '%"Qwen3-32B":%' OR large_model_content LIKE '%"qwen3":%'
-- ④ 「模型信息」里**嵌套的** largeModelCode 残留（漏改会让详情页显示旧模型名）
UNION ALL SELECT '④ 嵌套largeModelCode残留(期望0)', count(*)
  FROM knowledge_base_params
 WHERE contentdesc     LIKE '%Qwen3-32B%' OR contentdesc     LIKE '%qwen3%'
    OR input_condition LIKE '%Qwen3-32B%' OR input_condition LIKE '%qwen3%'
    OR large_model_content LIKE '%Qwen3-32B%' OR large_model_content LIKE '%qwen3%'
UNION ALL SELECT '   新数据源id命中(期望134)', count(*) FROM index_params           WHERE script LIKE '%' || (SELECT id FROM sys_data_source ORDER BY id LIMIT 1) || '%'
UNION ALL SELECT '   新JSON-key命中(期望86)',  count(*) FROM knowledge_base_params  WHERE large_model_content LIKE '%"' || (SELECT lm_code FROM large_model_config WHERE use_flag='Y' ORDER BY id LIMIT 1) || '":%'
UNION ALL SELECT '   新模型code命中(期望86)',  count(*) FROM knowledge_base_params  WHERE large_model_code = (SELECT lm_code FROM large_model_config WHERE use_flag='Y' ORDER BY id LIMIT 1)
ORDER BY 1;

-- 【三】授权是否生成（🔴 这两条决定知识库页是否有内容）
SELECT 'admin 知识库分组授权(期望=分组总数)' AS 检查项, count(*) AS 实际值
  FROM sys_role_knowledge WHERE role_id = (SELECT id::text FROM sys_role WHERE role_code='admin' LIMIT 1)
UNION ALL SELECT 'admin 输出要求授权(期望=知识库总数)', count(*)
  FROM sys_role_knowledge_output WHERE role_id = (SELECT id::text FROM sys_role WHERE role_code='admin' LIMIT 1)
ORDER BY 1;

-- 【四】关键引用完整性（两条都应全命中）
SELECT '知识库↔分组(期望 86/86)' AS 检查项, count(*) AS 总数, count(g.groupid) AS 命中
  FROM knowledge_base_params k LEFT JOIN knowledge_base_group g ON g.groupid = k.groupid;
SELECT '分组授权↔分组(期望 25/25)' AS 检查项, count(*) AS 总数, count(g.groupid) AS 命中
  FROM sys_role_knowledge s LEFT JOIN knowledge_base_group g ON g.groupid = s.knowledge_id;

-- 【五】基础配置是否就位（模型 code 必须等于后端 yml 的 agent.rule.parse-model-code）
SELECT 'large_model_config' AS 项, lm_code, model, use_flag FROM large_model_config;
SELECT 'sys_data_source'    AS 项, id, code, db_type FROM sys_data_source;
SELECT 'sys_role(admin)'    AS 项, id::text, role_code FROM sys_role WHERE role_code = 'admin';

-- 【六】表级深度对账（期望 0 差异，可选用）
SELECT '列名差异' AS 项, count(*) AS 实际值 FROM (
  SELECT c.table_name, c.column_name
    FROM information_schema.columns c
   WHERE c.table_schema = current_schema()
     AND c.table_name IN ('index_base_group','index_params','index_relate_knowledge_info',
                          'knowledge_base_group','knowledge_base_params','knowledge_base_version',
                          'knowledge_relate_index','knowledge_relate_input_param','agent_rule',
                          'sys_dict','sys_dict_item','sys_role_knowledge','sys_role_knowledge_output')
   GROUP BY 1,2
) t;   -- 仅作参考；列名是否齐全以《三个菜单_表清单与核对报告.md》为准
