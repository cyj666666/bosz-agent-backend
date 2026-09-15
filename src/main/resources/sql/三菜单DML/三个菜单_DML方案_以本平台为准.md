# 三个菜单 — DML 整体方案（**以本平台为准** + 公司数据全量导入适配）

> ## 准则（2026-09-15 用户裁定，本方案的最高优先级）
> 1. **本平台的这四类配置一律不动**：① 用户 ② 角色 + 用户角色关系 ③ 模型配置 ④ 数据源配置。
>    **公司数据导进来之后，向本平台的配置去适配**（改编码、改外键），**绝不反向覆盖**。
> 2. **只保 `admin` 一个用户**：只要 `admin` 能把三个菜单**全部功能**用起来就算达标。
>    公司那 26 个角色、另一个用户（`khjl`）**全部不管**。
> 3. **涉及到的数据都要导**（配置类 / 业务类 / 授权类 / 历史记录），**脏数据也无所谓**。
> 4. 数据来源：公司库 `bosz_test`（**只读**）→ 目标库；本地库 `as_agent`（**只读**）提供"本平台基准值"。
>
> 核对时间：2026-09-15。⚠️ 公司数据仍在变动（同一天 `knowledge_base_params` 83 → 85），
> **正式导入前建议重跑一次核对**（脚本见 §9）。

---

## 一、本平台不可动的基准（**实测值**，公司数据一律往这些值上靠）

### 1.1 用户 / 角色 / 关系（`sys_user` / `sys_role` / `sys_user_role`）

| 项 | 本平台实测值 | 说明 |
|---|---|---|
| `sys_user` | `id=1` → `admin`（管理员001，status=1）；`id=2` → `khjl001` | **只登录 `admin`** |
| `sys_role` | `id=1` → `role_code=admin`（系统管理员）；`id=2` → `khjl` | **只用 `id=1`** |
| `sys_user_role` | `(user_id=1, role_id=1)`、`(user_id=2, role_id=2)` | admin → 角色 1，**已就位** |
| `menu_permissions` | `["/reports","/users","/roles","/agent/index-config","/agent/knowledge-config","/agent/rule"]` | ✅ **已含三个 agent 路径**，本地无需补 |

> 🔴 公司 `sys_role` 是 **Jeecg 体系**（26 条、uuid 主键、**没有 `menu_permissions` 列**）——
> 与宿主**不是一套**。→ 公司的角色/用户/关系**一条都不导**，授权数据的 `role_id` 一律改写成 `'1'`。

### 1.2 大模型配置（`large_model_config`）

| 项 | 本平台实测值 | 说明 |
|---|---|---|
| `lm_code` | **`bosz-report-ai`** | 唯一一条；`model=deepseek-flash` |
| 绑定关系 | yml `agent.rule.parse-model-code: bosz-report-ai` | ✅ **与基准一致** |

> 公司那条 `lm_code=Qwen3-32B` **不导**。凡引用模型编码的地方一律改写成 `bosz-report-ai`（§4.2）。

### 1.3 数据源配置（`sys_data_source`）

| 项 | 本平台实测值 |
|---|---|
| `id` | **`bosz-dev-local-0001`** |
| `code` / `name` | `boszLocal` / 本地开发库 |
| `db_type` / `db_driver` | `opengauss` / `org.opengauss.Driver` |
| `db_url` | `jdbc:opengauss://127.0.0.1:5432/bosz` |

> 公司 8 条数据源 **不导**。指标 `script` 里引用的数据源 id 一律改写成**目标环境**的数据源 id（§4.1）。
> ⚠️ 现场的数据源 `db_url/账号` 要指向行内真实库；`db_password` 必须存 `SecurityUtil.jiami()` **密文**。

### 1.4 两个"权限过滤"开关（决定要不要灌授权数据）

| 位置 | 配置/行为 | 对 admin 的影响 |
|---|---|---|
| **指标侧** | yml `agent.index.role-filter-enabled: true` + **`role-filter-bypass-roles: [admin]`** | ✅ admin **放行**，不看 `sys_role_index` |
| **知识库侧** | **没有 bypass**；`group/query` 的 `authFlag` **默认 `true`** | 🔴 admin **要受 `sys_role_knowledge` 约束** → **必须灌**（§5.1） |

---

## 二、admin 跑通三个菜单，各需要什么数据（**这是全文的核心**）

| 菜单 | 页面功能 | 依赖的数据 | admin 是否能免授权 |
|---|---|---|---|
| **① 指标配置**<br>`/agent/index-config` | 左侧分组树、指标列表、编辑弹窗、数据源下拉、SQL 预览、KnowledgeCode 向导、关联信息、细分参数 | `index_base_group`(40)<br>`index_params`(1086)<br>`sys_data_source`(本平台1条)<br>`knowledge_base_group`+`knowledge_base_params`（KnowledgeCode 向导要用）<br>`sys_dict`+`sys_dict_item`（类型下拉） | ✅ **免授权**（bypass） |
| **② 知识配置**<br>`/agent/knowledge-config` | 分组树、知识库列表、全屏编辑器（输出要求/核心提示词/分段策略/大模型参数）、预览对流、黑盒配置、测试集 | `knowledge_base_group`(25)<br>`knowledge_base_params`(86)<br>`knowledge_base_version`(1)<br>`knowledge_relate_index`(493)<br>`knowledge_relate_input_param`(9)<br>`large_model_config`(本平台1条)<br>**`sys_role_knowledge`(必须)** | 🔴 **不免**（无 bypass）→ **必须生成授权** |
| **③ 智策引擎**<br>`/agent/rule` | 规则列表、规则表单、AI 分析（走大模型）、主题下拉、解析 | `agent_rule`(42)<br>`large_model_config`(本平台1条) | ✅ 无授权概念 |
| **（共性）** | 大模型参数引用 | `large_model_config.lm_code` 必须与 yml 一致 | — |

---

## 三、要导的数据 —— 逐表清单（**全导**，含适配动作）

> 行数 = 公司库 `bosz_test` 实测。本地库对应表**几乎全空**。

### 3.1 A 组：基础配置（先导）

| # | 表 | 公司行数 | 适配动作 | 说明 |
|---|---|---|---|---|
| 1 | `sys_dict` | **88** | 无（直接导） | 字典主表 |
| 2 | `sys_dict_item` | **24** | 无 | ⚠️ 仅 **5 个字典有项**：`ToolParamType`(10) / **`database_type`(6)** / `ToolsType`(4) / `is_open`(2) / **`online`(2)** → 其余字典是空下拉（前端降级不报错） |

### 3.2 B 组：指标配置

| # | 表 | 公司行数 | 适配动作 |
|---|---|---|---|
| 3 | `index_base_group` | **40** | 无（分组树根） |
| 4 | `index_params` | **1086** | 🔴 **§4.1 数据源 id 改写** |
| 5 | `index_relate_knowledge_info` | **492** | 无（12 条悬空，见 §8） |
| 6 | `sys_role_index` | 188 | ⛔ **不导**（admin 有 bypass；且数据本身失效）→ 可选"保险项"见 §5.3 |

### 3.3 C 组：知识配置

| # | 表 | 公司行数 | 适配动作 |
|---|---|---|---|
| 7 | `knowledge_base_group` | **25** | 无（分组树根） |
| 8 | `knowledge_base_params` | **86** | 🔴 **§4.2 模型编码改写**（含 JSON key） |
| 9 | `knowledge_base_version` | **1** | 🔴 同上 |
| 10 | `knowledge_relate_index` | **493** | 无（12 条悬空） |
| 11 | `knowledge_relate_input_param` | **9** | 无（测试集） |
| 12 | **`sys_role_knowledge`** | 580 | 🔴 **不照搬** → 按 §5.1 **重新生成**（公司 580 条里只有 25 条有效） |
| 13 | **`sys_role_knowledge_output`** | 1 | 🔴 **不照搬** → 按 §5.2 **重新生成**（公司那条是孤值，对不上任何对象） |

### 3.4 D 组：智策引擎

| # | 表 | 公司行数 | 适配动作 |
|---|---|---|---|
| 14 | `agent_rule` | **42** | 无（`rule_status` 是单字符 `Y`；`rule_code` 是拼音码；`request_params` 形如 `["entName"]`） |

### 3.5 E 组：历史记录（**量大，建议分批**）

| # | 表 | 公司行数 | 适配动作 |
|---|---|---|---|
| 15 | `call_llm_record` | **8635** | ⚠️ `large_model_code` **保留原值**（它记录"当时真实调的模型"） |
| 16 | `knowledge_query_result` | **3776** | 无 |
| 17 | `prompt_query_result` | **1466** | 无（**该表没有 `large_model_code` 列**） |
| 18 | `trace_query_result` | 0 | 无数据 |

### 3.6 明确没有数据可导的（不是遗漏）

| 表 | 情况 |
|---|---|
| `sys_category`（分类字典主表） | 🔴 **公司库也是 0 行**（表存在，22 列）→ **无数据可导**；指标分类树会是空的，需业务提供 |
| `knowledge_black_params_config` + `_version` | 两库都 0 行 → 黑盒配置页无数据 |
| `agent_config` | 两库都 0 行 → 「关联 Agent」下拉为空（本地已补建该表） |
| `ext_intf_*`(4) / `open_api_conf` / `tool_management` / `sys_role_ai_user` / `index_relate_info` / `module_code_prompt_cache` / `sync_knowledge_info` / `knowledge_sync_task`(+1) / `knowledge_query_result_for_batch` / `index_params_version` / `knowledge_black_params_cache` 等 | 两库都 0 行 |

> ⚠️ 20 行以下的"零散表"（如 `knowledge_relate_input_param` 9 条）也一并导，符合"涉及到的数据都要导"。

---

## 四、必须做的字段级改写（**不想导坏就照这个来**）

### 4.1 指标 `script` 里的数据源 id

```sql
-- 公司现状：134 条非空 script 的 "dataSource" 全部是 2095447359636992001
-- 本平台/现场：换成目标环境 sys_data_source.id
UPDATE index_params
   SET script = replace(script, '2095447359636992001', '<目标环境数据源id>')
 WHERE script LIKE '%2095447359636992001%';
```

> 另一种做法：在目标库按 `id='2095447359636992001'` 新建那条数据源（url/账号换成行内真实库），
> 就能不改 script。**二选一即可**，推荐改写（不绑死公司 id）。

### 4.2 大模型编码（**三处 + 版本表**）

| 位置 | 公司值 | 改成 |
|---|---|---|
| `knowledge_base_params.large_model_code` | `Qwen3-32B`（**86/86**） | `bosz-report-ai` |
| `knowledge_base_params.large_model_content` 的 **JSON key** | `Qwen3-32B`（另有历史残留 `qwen3`） | key → `bosz-report-ai` |
| `knowledge_base_params.large_model_param` | `{}`（全空） | 无需改 |
| `knowledge_base_version.large_model_code` / `_content` | 有值（1 条） | 同上 |
| `call_llm_record.large_model_code` | 有值 | **保留原值**（历史事实） |

```sql
UPDATE knowledge_base_params  SET large_model_code = 'bosz-report-ai' WHERE large_model_code <> 'bosz-report-ai';
UPDATE knowledge_base_version SET large_model_code = 'bosz-report-ai' WHERE large_model_code <> 'bosz-report-ai';
-- large_model_content 是 {"模型code": 条件组JSON} 的字符串 → key 也在里面，用 replace 最稳：
UPDATE knowledge_base_params
   SET large_model_content = replace(replace(large_model_content, '"Qwen3-32B":', '"bosz-report-ai":'), '"qwen3":', '"bosz-report-ai":')
 WHERE large_model_content LIKE '%"Qwen3-32B":%' OR large_model_content LIKE '%"qwen3":%';
```

> 🔴 不改 key 的后果：编辑器切到该模型时取不到那份「输出要求」，**用户一改一保存就会覆盖**（第 4 项修的就是这个）。
> ⚠️ 若目标环境将来启用**第二个**模型，`large_model_content` 里应保留各模型各一份 —— 此处是"统一收敛到当前唯一模型"的简化。

### 4.3 角色 id（**全部 → `'1'`**）

```sql
UPDATE sys_role_knowledge        SET role_id = '1' WHERE role_id <> '1';
UPDATE sys_role_knowledge_output SET role_id = '1' WHERE role_id <> '1';
-- sys_role_index 不导（§3.2）
```

> 公司 `role_id` 是 Jeecg uuid（如 `f6817f48af4fb3af11b9e8bf182f618b`），
> 本平台是宿主 `sys_role.id`（bigint 语义的字符串 `1`）。

### 4.4 字段名/编码风格提醒（**容易踩**）

| 提醒 | 说明 |
|---|---|
| 列名**两种风格混用** | `knowledge_base_group` 是 **全小写无下划线**（`groupid`/`groupstatus`/`parentgroupid`），而 `knowledge_base_params` 里又有 `input_param`/`large_model_code`/`is_top`/`split_strategy_param`。**写 SQL 前先看 `information_schema.columns`** |
| **`paramno` / `paramid` 语义相反** | `index_params`：主键=**`paramno`**（雪花）、业务编码=**`paramid`**；<br>`knowledge_base_params`：主键=**`paramid`**、业务编码=**`paramno`**。**join 前务必确认** |
| 空 `script` 保持空串 | 947/1086 条 `script=''` 是**正常**的（源工程行为），**不要"修"成 `{}`** |

---

## 五、要给 admin **生成**的授权（公司数据用不了，必须新造）

### 5.1 🔴 `sys_role_knowledge` —— **必须，否则知识库页对 admin 全空**

**代码证据**（`KnowledgeBaseConfigServiceImpl`）：

```java
// pageKnowledgeBaseParamsList（列表）:2151
List<String> knowledgeIdList = getKnowledgeIdListByRoleId();   // 取 ApiContext 的角色 → sys_role_knowledge
if (CollectionUtils.isEmpty(knowledgeIdList)) return new ListResult<>(0, 0);   // ← 直接空

// queryKnowledgeBaseGroupTree（分组树）:176 —— authFlag 由 Controller 给，默认 true
if (authFlag) { knowledgeIdList = getKnowledgeIdListByRoleId(); if (isEmpty) return new ListResult<>(0,0); }
```

过滤列是 **`knowledge_id` → `knowledge_base_group.groupid`**。
**指标侧有 `role-filter-bypass-roles: [admin]`，知识库侧没有** → `sys_role_knowledge` 为空时，
**admin 的知识库分组树 + 列表都是空的**。

**公司现状**（实测）：580 条，**只有 25 条命中现有分组**，且 `K5.not_authorized = 0`
→ 即公司那条角色**实际授权了"全部 25 个分组"**。

**生成方式**（不依赖公司数据，直接按目标库分组生成 —— 更符合"以我为准"）：

```sql
-- 把「全部知识库分组」授权给 admin
INSERT INTO sys_role_knowledge (id, role_id, knowledge_id, operate_date, operate_ip)
SELECT md5(random()::text || g.groupid), '1', g.groupid, now(), '127.0.0.1'
  FROM knowledge_base_group g
 WHERE NOT EXISTS (SELECT 1 FROM sys_role_knowledge s WHERE s.role_id = '1' AND s.knowledge_id = g.groupid);
```

### 5.2 🔴 `sys_role_knowledge_output` —— 决定 admin 能否看到「输出要求 / 核心提示词 / 分段与检索策略」

**代码证据**：`checkKnowledgeOutputAuth(roleIdList, paramId)`
→ `wrapper.in(roleId, roleIdList).eq(knowledgeId, paramId)` → **`knowledge_id` 存的是 `knowledge_base_params.paramid`（主键）**。
`roleIdList` 来自 `ApiContext.role`（宿主角色主键），**同样没有 admin 豁免**。

**公司现状**：全表 **1 条**，`knowledge_id=2089893858327494657` →
实测对不上任何 `paramid`（0）/ `paramno`（0）/ `groupid`（0）→ **纯孤值**。
**即公司真实环境里没有任何角色拥有这些区块的查看权限。**

**生成方式**（管理员本该可见全部）：

```sql
-- 把「全部知识库」的输出要求权限给 admin
INSERT INTO sys_role_knowledge_output (id, role_id, group_id, knowledge_id, operate_date)
SELECT md5(random()::text || k.paramid), '1', k.groupid, k.paramid, now()
  FROM knowledge_base_params k
 WHERE NOT EXISTS (SELECT 1 FROM sys_role_knowledge_output s WHERE s.role_id = '1' AND s.knowledge_id = k.paramid);
```

> `group_id` 只是写入时的归属标记（列表页按 role+group 查它，但**编辑器判权只看 `knowledge_id`**），
> 这里按记录自身的 `groupid` 填，保持语义一致。

### 5.3 （可选保险项）`sys_role_index`

admin 在指标侧**有 bypass，用不到它**。若你希望"即使以后把 bypass 关掉 admin 也全可见"，可以顺手生成：

```sql
-- 可选：给 admin 授权全部指标（不依赖公司那 188 条失效数据）
INSERT INTO sys_role_index (id, role_id, index_id, operate_date, operate_ip)
SELECT md5(random()::text || p.paramno), '1', p.paramid, now(), '127.0.0.1'
  FROM index_params p
 WHERE NOT EXISTS (SELECT 1 FROM sys_role_index s WHERE s.role_id = '1' AND s.index_id = p.paramid);
```
（`index_id` 按业务编码 `paramid` 填 —— 与指标页过滤口径一致。）

### 5.4 公司 580 条 `sys_role_knowledge` 的处理

**建议直接丢弃**（不导）。理由：① 公司 555 条是悬空的；② 有效的那 25 条正好等于"全部分组"，
与 §5.1 生成的结果**等价**；③ 少一步脏数据清洗。
若一定要走公司数据，就筛出命中的 25 条再把 `role_id` 改成 `'1'`，效果相同。

---

## 六、执行步骤（新库从零到 admin 可用）

> 阶段 0~1 的表结构部分见 `sql/三菜单DDL/三个菜单_表清单与核对报告.md` 第九节。

| 阶段 | 做什么 | 关键动作 |
|---|---|---|
| **0** | **宿主先就位** | `CREATE SCHEMA`（如需）+ `SET search_path` → 跑宿主 `init_auth_gaussdb.sql`（`sys_user`/`sys_role`/`sys_user_role`）+ `init_db_gaussdb.sql` → **确认 `admin` 能登录** |
| **1** | **建表** | 执行《三个菜单_建表DDL》（44 张一次跑通） |
| **2** | **基础配置（以本平台为准，本平台已有的不动）** | ① `sys_data_source` ≥1 条（**现场新建**，密码存 `jiami()` 密文）② `large_model_config.lm_code` = yml 的 `parse-model-code`（现场填行内真实模型，**api_key 明文**）③ 导 `sys_dict` → `sys_dict_item` ④ 确认 `sys_role.menu_permissions` 含三条 agent 路径 |
| **3** | **业务配置（严格顺序）** | 1. `index_base_group` → 2. `index_params` → **3. 跑 §4.1 数据源改写** → 4. `index_relate_knowledge_info` → 5. `knowledge_base_group` → 6. `knowledge_base_params` → **7. 跑 §4.2 模型编码改写** → 8. `knowledge_base_version`（同改）→ 9. `knowledge_relate_index` → 10. `knowledge_relate_input_param` → 11. `agent_rule`(42) |
| **4** | **授权（全落 admin）** | **1. §5.1 `sys_role_knowledge`（必做）** → **2. §5.2 `sys_role_knowledge_output`（必做）** → 3.（可选）§5.3 `sys_role_index` → 4. 确认 `menu_permissions` |
| **5** | **历史记录（量大，分批）** | `call_llm_record`(8635) / `knowledge_query_result`(3776) / `prompt_query_result`(1466) |
| **6** | **冒烟（admin 逐页点）** | 见 §6.1 |

### 6.1 每阶段的校验 SQL（照跑，期望值写在注释里）

```sql
-- 【阶段2】
SELECT count(*) FROM large_model_config WHERE lm_code = '<yml 里 parse-model-code 的值>';   -- 期望 ≥1
SELECT id, code, name, db_type FROM sys_data_source;                                        -- 期望 ≥1
SELECT dict_code, count(*) FROM sys_dict_item GROUP BY dict_code;                            -- 期望见 §3.1
SELECT menu_permissions FROM sys_role WHERE id = 1;                                          -- 期望含 3 条 /agent/*

-- 【阶段3】
SELECT count(*) AS total, count(g.groupid) AS matched
  FROM knowledge_base_params k LEFT JOIN knowledge_base_group g ON g.groupid = k.groupid;    -- 期望 86 / 86
SELECT count(*) FROM index_params WHERE script LIKE '%2095447359636992001%';                 -- 期望 0（改写生效）
SELECT count(*) FROM knowledge_base_params WHERE large_model_code <> 'bosz-report-ai';       -- 期望 0
SELECT count(*) FROM knowledge_base_params WHERE large_model_content LIKE '%"Qwen3-32B":%';  -- 期望 0（key 已换）

-- 【阶段4】★ 决定 admin 能否看到知识库
SELECT count(*) FROM sys_role_knowledge WHERE role_id = '1';                                 -- 期望 25（= 全部分组）
SELECT count(*) AS total, count(g.groupid) AS matched
  FROM sys_role_knowledge s LEFT JOIN knowledge_base_group g ON g.groupid = s.knowledge_id;  -- 期望 25 / 25
SELECT count(*) FROM sys_role_knowledge_output WHERE role_id = '1';                          -- 期望 86
SELECT DISTINCT role_id FROM sys_role_knowledge;                                             -- 期望只有 '1'
```

### 6.2 冒烟清单（admin 登录）

1. **指标配置**：分组树能展开 → 列表有 1086 条 → 点开任一条 → 数据源下拉有值 → SQL 预览能出结果 → KnowledgeCode 向导四步能走
2. **知识配置**：分组树能展开（**若空 = `sys_role_knowledge` 没灌**）→ 列表有 86 条 → 打开编辑器 → **切大模型时「输出要求」跟着换**（第 4 项修复点）→ 右栏 4 个模型参数可编辑 → 预览按钮能出流式结果（**若报"未找到大模型配置" = 模型编码没对齐**）
3. **智策引擎**：列表 42 条 → 打开表单 → 「AI 分析」能出流式结果

---

## 七、这次梳理新查实的 3 件事（相对上一版的变化）

| # | 结论 | 依据 |
|---|---|---|
| 1 | **知识库分组树的 `authFlag` 默认 `true`** → **分组树也走权限过滤**（上一版只确认了列表） | `KnowledgeBaseConfigController:42` `@RequestParam(defaultValue = "true")`；前端 `queryGroupTree` 不传该参数 |
| 2 | **公司那条角色的有效授权 = 全部 25 个分组**（不是"只有 25 条残值"） | `知识库分组总数 25` / `授权命中分组 25` / `未授权分组 0`；且覆盖全部 22 个"有知识库的分组" |
| 3 | **`sys_role_knowledge_output` 那条确认是孤值**（对不上 paramid/paramno/groupid 任一个） | 三方 count 全为 0 → **公司环境里没有任何角色有这些区块的权限**，必须新造 |

> 另外顺手排掉一个**虚惊**：我一开始按 `group_status` 查 `knowledge_base_group` 报"列不存在"，
> 以为代码用了库里没有的列。实际是**列名是全小写无下划线的 `groupstatus`**，是我 SQL 写错。
> **DDL 与代码是匹配的**。（教训：本库列名两种风格混用，写 SQL 前先查 `information_schema`。）

---

## 八、数据质量问题（**你说脏数据无所谓，这里只作知情**）

| # | 问题 | 影响 |
|---|---|---|
| 1 | `index_params.parentparamno` 只有 **136/1086** 指向真实分组（其余指向已删对象） | 按分组点选时只显示那 136 条；**不选分组看全部**，不阻塞 |
| 2 | `index_params.script` 里 `moduleCode` 仅 5 条有值，其中 **`jyk-yszk-AI` 在知识库表里不存在**（悬空） | 该指标的 KnowledgeCode 关联会取不到知识库 |
| 3 | `index_relate_knowledge_info` **12 条**悬空（480/492） | 关联信息列出空行 |
| 4 | `knowledge_relate_index` **12 条**悬空（481/493） | 同上 |
| 5 | `sys_role_index` **148/188** 对不上任何主键（且已决定不导） | 无影响 |
| 6 | `sys_dict_item` 只有 24 条、仅 5 个字典有项 | 其余字典下拉为空，前端降级不报错 |
| 7 | `sys_category` 两边都 0 行 | 指标分类树为空 |

---

## 九、仍在等你/业务定的（**只剩 3 条**）

| # | 事项 | 我的默认处理 |
|---|---|---|
| 1 | **现场数据源怎么建**：是"按本平台那 1 条的形态复制到现场库"还是"现场本来就有一套" | 反正**不改本平台配置**；§4.1 按"现场数据源的 id"改写就行 |
| 2 | **现场大模型**：`lm_code` 是否保持 `bosz-report-ai` | 保持（与 yml 一致即可）；换了 code 就同步改 yml |
| 3 | **`sys_category`（指标分类树）没有数据源**：公司也空 | 需要业务提供；不阻塞主流程 |

> 核对脚本（可复用，都在 `D:\dbtool\`）：
> `scan_tables3.py`（覆盖率反查）、`diff_ddl.py`/`diff_type.py`（结构核对）、
> `DbRun.java`（**只读**查询，非 SELECT 直接跳过）、`DbExec.java`（**写执行，硬护栏：非 127.0.0.1/localhost 直接拒绝**）。

---

## 附录 A：**「菜单权限」≠「数据权限」** —— 三套机制，别混为一谈

导入前最容易搞混的就是这件事。本平台一共**三套互相独立**的权限：

### A.1 菜单可见性（**已完全适配，无需任何数据**）

**链路（已逐段核实）**：

| 层 | 位置 | 行为 |
|---|---|---|
| 后端 | `AuthService#getUserMenuPermissions` | 角色编码含 **`admin`** → 直接返回 `["*"]`（**不看 `menu_permissions`**）；<br>否则合并该用户所有角色的 `sys_role.menu_permissions`（JSON 数组） |
| 前端-菜单 | `MainLayout.tsx` | `menus.includes('*')` → **渲染全部菜单**；否则按 `menus` 逐项取 `allMenus[m]` |
| 前端-路由 | `AuthGuard.tsx` | `'*'` → **不拦截任何路径**；否则按路径/明细页映射匹配 |
| 前端-配置 | `RoleList.tsx` | 角色管理页的「菜单权限」可选项 = 宿主项 **+ `agentMenuOptions`**（由 `src/agent` 提供，新增 agent 页不用改宿主） |

**三条 agent 路径三处逐字一致**（`src/agent/menu.tsx` = 后端存的 `menu_permissions` = 路由）：

```
/agent/index-config      指标配置
/agent/knowledge-config  知识配置管理
/agent/rule              智策引擎
```

✅ **结论**：**`admin` 登录就天然全可见**（靠 `role_code='admin'`，不依赖 `menu_permissions` 里存那三条）。
其他角色则在「角色管理 → 菜单权限」里勾选即可，选项已经就位。

> ⚠️ 本平台 `sys_role.id=1` 的 `menu_permissions` 里**确实也存了**三条 `/agent/*` ——
> 但 admin 走的是 `'*'` 分支，**那三条对 admin 不生效**（存了也无害，纯粹是给非 admin 角色的示例）。

### A.2 数据可见性 —— **三块各一套，这才是 DML 要解决的**

| 菜单 | 过滤机制 | admin 是否豁免 | 需要什么数据 |
|---|---|---|---|
| **指标配置** | yml `agent.index.role-filter-enabled: true` +<br>**`role-filter-bypass-roles: [admin]`** | ✅ **豁免** | **不需要** `sys_role_index` |
| **知识配置** | `getKnowledgeIdListByRoleId()`（查 `sys_role_knowledge`）<br>列表 + **分组树**都是"为空即返回 0 条" | 🔴 **不豁免**（无 bypass） | 🔴 **必须灌** `sys_role_knowledge`（§5.1） |
| 知识库编辑器区块 | `checkKnowledgeOutputAuth(roleIdList, paramId)` | 🔴 **不豁免** | 🔴 **必须灌** `sys_role_knowledge_output`（§5.2） |
| **智策引擎** | 无过滤 | — | — |

> 🔴 **一句话提醒**：菜单能看到 ≠ 里面有数据。
> **`admin` 把三个菜单点开却看到空列表**，99% 是这两件：① DML 没导；② `sys_role_knowledge` / `sys_role_knowledge_output` 没生成。

### A.3 角色体系归属（**两套 RBAC 并存，别串**）

| 体系 | 表 | 主键形态 | 用途 |
|---|---|---|---|
| **宿主自建**（以本平台为准） | `sys_user` / `sys_role` / `sys_user_role` | bigint 自增（`1`/`2`），`sys_role` **有 `menu_permissions` 列** | 登录、菜单可见性、agent 的数据授权（`role_id` 存这里的 id） |
| 公司 Jeecg（**不导**） | 同名表 | uuid | 公司那套后台自己的 |

→ agent 侧 `ApiContext` 取的是**宿主**的：`roleCodeList` = 角色编码（用于 bypass 比对），
`role` = `resolveRoleIds(userId)` = **宿主 `sys_role.id`**（用于 `sys_role_index` / `sys_role_knowledge` 的 `role_id`）。
**所以所有授权数据的 `role_id` 一律写成目标库 admin 的 `sys_role.id`（本平台 = `1`）。**

---

## 附录 B：就绪度自检 —— **"执行完就能用"还差什么**

分三档，**别把"静态核对过"当成"验证过"**。

### ✅ 已确认可用（有实测或有明确代码依据）

| 项 | 依据 |
|---|---|
| 前后端代码接缝 | `src/agent/index.ts` 统一出口，5 常量 / 4 处引用；`tsc` 0 错误 + `vite build` 成功（3219 模块） |
| 菜单可见性链路 | 后端 `AuthService` → 前端 `MainLayout`/`AuthGuard`/`RoleList`，**逐段核实**（附录 A.1） |
| 路径一致性 | 三条 `/agent/*` 在 `menu.tsx`、`sys_role.menu_permissions`、路由三处**逐字一致** |
| 表结构 | 44 张表 **列名+顺序 44/44 与公司库一致（666 列，0 差异）**；本地 44 张已齐 |
| 动态取数链路 | P1 起已实测可用（`sys_data_source` 本地已配、不依赖公司数据） |
| P4 智策引擎解析 | 已端到端实测通过（用测试指标 900001~900005） |

### ⚠️ 静态核对过、**但从未真机跑过**（代码/脚本都对，跑起来可能还有环境问题）

| 项 | 风险点 |
|---|---|
| **建表 DDL 在空库执行** | 本地是"增量补建"（新建了 `agent_config` 一张），**整份 44 张没在空 schema 跑过** |
| **DML 导入 + 映射改写** | 脚本是新写的，**没跑过**；`§B1` 的 replace 是否命中全部形态需跑后校验 |
| **大模型外调**（`CallLlmUtil`） | 需真实 `api_key` / 内网可达；本地那条指向 DeepSeek 公网 |
| **SSE 流式**（预览 / AI 分析） | 需 `SuitablePythonHttpSSEWebConfiguration` 白名单命中 + 网关不缓冲 |
| **Excel 解析入库** | 需真实模板文件 |
| **第 4/5/6 项的新改动** | 切模型载入输出要求、KnowledgeCode 四步向导、打字机 + 三个列表页重构 —— 都只过了类型检查/构建 |

### ❌ 目前一定"用不了"的（**执行 DML 前必然为空**）

| 现象 | 原因 |
|---|---|
| 三个菜单列表全空 | DML 没导（库里 0 数据） |
| **知识配置的分组树 + 列表对 admin 也是空** | 🔴 `sys_role_knowledge` 为空（**代码没有 admin 豁免**）→ 必须跑 §5.1 |
| 知识库编辑器看不到「输出要求 / 核心提示词 / 分段与检索策略」 | 🔴 `sys_role_knowledge_output` 为空 → 必须跑 §5.2 |
| 大模型下拉选不中 / 智策引擎报「未找到大模型配置」 | `large_model_config.lm_code` 与 yml `agent.rule.parse-model-code` 不一致 |
| 数据源下拉空 / SQL 预览失败 | `script.dataSource` 没改写成目标库数据源 id |
| 指标分类树为空 | `sys_category` 两库都 0 行（需业务提供） |

### 📋 上线前最小自检（6 条，跑完再交付）

```sql
-- ① 大模型编码与 yml 对齐
SELECT count(*) FROM large_model_config WHERE lm_code = '__LM_CODE__';
-- ② 数据源存在
SELECT count(*) FROM sys_data_source;
-- ③ 指标 script 改写干净
SELECT count(*) FROM index_params WHERE script LIKE '%__OLD_DATA_SOURCE_ID__%';      -- 期望 0
-- ④ 知识库模型编码改写干净
SELECT count(*) FROM knowledge_base_params WHERE large_model_code <> '__LM_CODE__';   -- 期望 0
-- ⑤ ★ admin 的知识库授权（不跑知识库页必空）
SELECT count(*) FROM sys_role_knowledge WHERE role_id = '__ADMIN_ROLE_ID__';          -- 期望 = 分组总数
-- ⑥ ★ admin 的输出要求授权
SELECT count(*) FROM sys_role_knowledge_output WHERE role_id = '__ADMIN_ROLE_ID__';   -- 期望 = 知识库总数
```
