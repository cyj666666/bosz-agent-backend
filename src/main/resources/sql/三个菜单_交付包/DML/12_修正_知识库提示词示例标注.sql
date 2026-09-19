-- ============================================================================
-- 12_修正_知识库提示词示例标注.sql
--
-- 病征：部分知识库提示词的「数值处理规则」里写了**与业务数值同形**的格式示例，
--       例如：17.6000 → 17.60% / 13.6000 → 13.60% / 10.5000 → 10.50%
--       实测（2026-09-19）：报告正文出现了 17.60 / 13.60 / 10.50 这三个数，
--       而那一次取数是**空结果** —— 模型把示例数字当成了实际数据照抄。
--
-- 改法：**不改结构、不删示例**，只在「例如：」后插入一句防误用标注。
--       示例本身是稳定输出格式的手段，删了会更糟；要消除的是"被当成数据"的歧义。
--
-- 幂等：WHERE 带 LIKE '%例如：%' 守卫 ⇒ 重复执行 0 行更新。
-- 回滚：_backup_20260919_提示词示例标注前/contentdesc_回滚.sql
--
-- ⚠️ 光有本补丁不够：**代码侧已加"取数全空则不调用大模型"短路**
--    （KnowledgeBaseConfigServiceImpl#getPromptContent，2026-09-19），
--    两者配合才能既"没数据不出内容"、又"有数据时示例不干扰"。
-- ============================================================================

-- ① 预览：确认每条的「例如：」出现次数
SELECT paramno, paramname, (char_length(contentdesc) - char_length(replace(contentdesc, '例如：', ''))) / char_length('例如：') AS eg_cnt
  FROM knowledge_base_params
 WHERE contentdesc LIKE '%例如：%'
 ORDER BY paramno;

-- ② 逐条更新

-- caiwu-jinglirun（8 处）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '例如：',
                                     '例如（下列数字仅为格式说明，严禁作为本次报告的实际数据）：')
 WHERE paramno = 'caiwu-jinglirun' AND contentdesc LIKE '%例如：%';

-- caiwu-nashuishouru（7 处）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '例如：',
                                     '例如（下列数字仅为格式说明，严禁作为本次报告的实际数据）：')
 WHERE paramno = 'caiwu-nashuishouru' AND contentdesc LIKE '%例如：%';

-- caiwu-yingyeshouru（7 处）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '例如：',
                                     '例如（下列数字仅为格式说明，严禁作为本次报告的实际数据）：')
 WHERE paramno = 'caiwu-yingyeshouru' AND contentdesc LIKE '%例如：%';

-- caiwu-yszk（1 处）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '例如：',
                                     '例如（下列数字仅为格式说明，严禁作为本次报告的实际数据）：')
 WHERE paramno = 'caiwu-yszk' AND contentdesc LIKE '%例如：%';

-- caiwu-zcfzlfx（4 处）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '例如：',
                                     '例如（下列数字仅为格式说明，严禁作为本次报告的实际数据）：')
 WHERE paramno = 'caiwu-zcfzlfx' AND contentdesc LIKE '%例如：%';

-- caiwu-zyfzkm（2 处）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '例如：',
                                     '例如（下列数字仅为格式说明，严禁作为本次报告的实际数据）：')
 WHERE paramno = 'caiwu-zyfzkm' AND contentdesc LIKE '%例如：%';

-- fdckflcphkjh（10 处）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '例如：',
                                     '例如（下列数字仅为格式说明，严禁作为本次报告的实际数据）：')
 WHERE paramno = 'fdckflcphkjh' AND contentdesc LIKE '%例如：%';

-- gdcphkjh（5 处）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '例如：',
                                     '例如（下列数字仅为格式说明，严禁作为本次报告的实际数据）：')
 WHERE paramno = 'gdcphkjh' AND contentdesc LIKE '%例如：%';

-- jyk-fyjljglvjkgr（4 处）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '例如：',
                                     '例如（下列数字仅为格式说明，严禁作为本次报告的实际数据）：')
 WHERE paramno = 'jyk-fyjljglvjkgr' AND contentdesc LIKE '%例如：%';

-- jyk-fyjljglvjkqy（2 处）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc, '例如：',
                                     '例如（下列数字仅为格式说明，严禁作为本次报告的实际数据）：')
 WHERE paramno = 'jyk-fyjljglvjkqy' AND contentdesc LIKE '%例如：%';

-- ③ 复核：应为 0 行（除回滚脚本外，任何地方都不该再有裸的「例如：…数字」）
SELECT paramno, paramname
  FROM knowledge_base_params
 WHERE contentdesc LIKE '%例如：%'
 ORDER BY paramno;
