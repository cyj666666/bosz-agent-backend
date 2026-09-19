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

-- ① 预览：确认**本补丁覆盖的这 10 条**的「例如：」出现次数
--    🔴 口径必须带 `paramno IN (...)`！
--    2026-09-19 踩过：写成全表 `WHERE contentdesc LIKE '%例如：%'` 时，
--    全库有 61 条命中、本补丁只改 10 条 ⇒ 复核永远剩 51 条，被误判成"补丁没生效"。
SELECT paramno, paramname, (char_length(contentdesc) - char_length(replace(contentdesc, '例如：', ''))) / char_length('例如：') AS eg_cnt
  FROM knowledge_base_params
 WHERE paramno IN ('caiwu-jinglirun','caiwu-nashuishouru','caiwu-yingyeshouru','caiwu-yszk','caiwu-zcfzlfx','caiwu-zyfzkm','fdckflcphkjh','gdcphkjh','jyk-fyjljglvjkgr','jyk-fyjljglvjkqy')
   AND contentdesc LIKE '%例如：%'
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

-- ②' 补充：`jyk-zuyichangqy`（经验库文案-债务异常描述）—— 2026-09-19 追加
--     全库**唯一**一条「纯格式说明」写法的同形示例：原文 `3. 例如输入“9.8000”，输出“9.80%”。`
--     改法：换成 X 占位（X.XXXX 不是合法数字，模型无从照抄）。
--
--     🔴 **为什么只改这一条**：另 13 条含 `例如输入 / 示例输入` 的配置都**不能动** ——
--        · 10 条是**完整 few-shot「示例输入→输出」段**（提示词工程手段，删了输出会不稳）
--        · 2 条（`whywdfk` / `jkrsjfljyq`）**已自带防误用声明**（"以上数据仅用于说明…不得作为数据来源"）
--        · 1 条 `xmdkytzs` 里的 `示例输入` 是**禁令文本的一部分**
--          （"不得根据历史案例、**示例输入**、上下文中的其他企业数据进行补充"）⇒
--          ⛔ 盲目 replace 会把这句话改坏、语义反转。
--     ✅ 已执行（`[UPD] 1`；复核 `position('9.8000' in contentdesc) = 0`）
UPDATE knowledge_base_params
   SET contentdesc = replace(contentdesc,
        '3. 例如输入“9.8000”，输出“9.80%”。',
        '3. 格式说明（下列数字仅为占位，严禁作为本次报告的实际数据）：输入 X.XXXX → 输出 X.XX%。')
 WHERE paramno = 'jyk-zuyichangqy'
   AND position('例如输入“9.8000”' in contentdesc) > 0;

SELECT count(*) AS should_be_zero_jyk_zuyichangqy
  FROM knowledge_base_params
 WHERE paramno = 'jyk-zuyichangqy'
   AND position('9.8000' in contentdesc) > 0;

-- ③ 复核：**应为 0 行**（同样只查本补丁覆盖的这 10 条）
--    ⛔ 不要用全表 `WHERE contentdesc LIKE '%例如：%'` —— 全库 61 条含「例如：」，
--    本补丁只覆盖"示例数值与业务数值同形"的 10 条，改完仍剩 51 条，会被误判成"没生效"。
SELECT paramno, paramname
  FROM knowledge_base_params
 WHERE paramno IN ('caiwu-jinglirun','caiwu-nashuishouru','caiwu-yingyeshouru','caiwu-yszk','caiwu-zcfzlfx','caiwu-zyfzkm','fdckflcphkjh','gdcphkjh','jyk-fyjljglvjkgr','jyk-fyjljglvjkqy')
   AND contentdesc LIKE '%例如：%'
 ORDER BY paramno;
