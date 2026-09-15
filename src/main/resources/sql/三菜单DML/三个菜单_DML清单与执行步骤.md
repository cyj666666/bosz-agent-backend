# 三个菜单 — DML 清单与执行步骤

> ⚠️ **本文档已被取代（2026-09-15）**：用户明确「**以本平台为准 + 角色只用 admin + 分类字典和历史记录都要导**」后，
> 请以 **`三个菜单_DML方案_以本平台为准.md`** 为准。
> 本文档保留作**双库盘查的原始记录**（逐表行数对比、引用完整性问题清单仍然有效）。

> 适用场景：**客户现场新建库**（或本地补齐数据）。
> 数据盘查时间：2026-09-15，来源 = 公司库 `bosz_test`（**只读**）+ 本地库 `as_agent`（只读）双库比对。
> 配套：`sql/三菜单DDL/三个菜单_建表DDL.sql`（44 张表）、`sql/三菜单DDL/三个菜单_表清单与核对报告.md`

---

## 一、总体结论（先看这个）

1. **建表 → 一份 DDL 就够**（空 schema；前提是宿主 RBAC 已存在，见 §4 阶段 0）。
2. **DML 要分三类**，别一股脑把公司库全导：
   - ✅ **必须灌**（不灌功能不可用）
   - 🟡 **可选灌**（历史记录类，灌了能演示/溯源）
   - ⛔ **不用灌**（两边都空 / 版本表 / 未启用模块）
3. 🔴 **有 5 个引用陷阱**，直接导会把数据导坏（§3）——**这是本次盘查最重要的产出**。
4. 🔴 **`sys_role_index` 这 188 条建议不导**（公司库里它自己就已经"对不上任何指标"，§3.5）。

---

## 二、逐表 DML 清单

### ✅ A. 必须灌（配置类，11 张）

| 表 | 公司库 | 本地库 | 灌什么 / 注意 |
|---|---|---|---|
| `sys_data_source` | 8 | 1 | **数据源被指标 script 引用（见 §3.1）**；`db_password` 必须是 `SecurityUtil.jiami()` 密文 |
| `large_model_config` | 1 | 1 | 公司是 `Qwen3-32B`、本地是 `bosz-report-ai`；**必须与 `agent.rule.parse-model-code` 一致（§3.2）**；`api_key` 用明文 |
| `sys_dict` | 88 | 0 | 字典定义（含 agent 用到的 `KnowledgeGroup` / `largeModelCode` / `entity_type` / `index_resource` / `ParamType` 等） |
| `sys_dict_item` | 24 | 0 | ⚠️ **只有 5 个字典有项**（`ToolParamType` 10 / `database_type` 6 / `ToolsType` 4 / `is_open` 2 / `online` 2）→ **agent 三个菜单用到的字典基本没有字典项**，灌了也是空下拉（前端会降级，不报错） |
| `index_base_group` | 40 | 0 | 指标分组树（3 层，只有 1 个根）→ **必须最先灌** |
| `index_params` | 1086 | 5 | 指标主表；**947 条 script 为空串**（正常，见 §3.1） |
| `knowledge_base_group` | 25 | 0 | 知识库分组树（根 `苏州银行`，`parentgroupid='0'`）→ **必须最先灌** |
| `knowledge_base_params` | 86 | 0 | 知识库主表；**`groupid` 100% 命中分组（86/86）✓** |
| `knowledge_base_version` | 1 | 0 | 版本表，1 条 |
| `knowledge_relate_index` | 493 | 0 | 细分参数配置；⚠️ **12 条 `knowledge_id` 指向已不存在的知识库（481/493 命中）** |
| `index_relate_knowledge_info` | 492 | 0 | 指标↔知识库关联；⚠️ **12 条悬空（480/492）** |

### 🟡 B. 可选灌（历史记录类，4 张，为了演示/溯源有数据）

| 表 | 公司库 | 本地库 | 说明 |
|---|---|---|---|
| `call_llm_record` | 8635 | 6 | 大模型调用记录；**量大**，建议只导最近 N 条或不导 |
| `knowledge_query_result` | 3776 | 0 | 知识库查询记录 |
| `prompt_query_result` | 1466 | 0 | prompt 请求结果记录 |
| `knowledge_relate_input_param` | 9 | 0 | 测试集（知识库预览可选测试数据，量小，**建议导**） |

### 🟡 C. 授权类（3 张，**需重新生成，不能原样导**）

| 表 | 公司库 | 本地库 | 关键问题 |
|---|---|---|---|
| `sys_role_index` | 188 | 0 | 🔴 **role_id 是公司角色 uuid；index_id 148/188 对不上任何现有指标** → **建议不导**，由业务在新库重新授权（§3.5） |
| `sys_role_knowledge` | 580 | 0 | role_id 要重映射；`knowledge_id` 存的是**分组 id**（580 条中**仅 25 条命中现有分组**）→ 只需保留能命中的 25 条并改写 role_id |
| `sys_role_knowledge_output` | 1 | 0 | role_id 要重映射；`knowledge_id = 2089893858327494657` **是孤值（对不上任何知识库）** → **结论：真实环境里其实没有角色有「输出要求」权限**，`hasAuth` 天然为 false，**可以不导** |

### ⛔ D. 不用灌（两边都 0 或本就不需要，26 张）

`agent_config`(智能体)、`agent_rule_prompt`、`ext_intf_manage` / `ext_intf_param_define` / `ext_intf_param_manage` / `ext_intf_supplier_manage`、
`index_params_version`、`index_relate_index_info`、`index_relate_info`、
`knowledge_black_params_config`(+`_version`)、`knowledge_query_result_for_batch`、`knowledge_relate_index_version`、
`knowledge_relate_input_param_version`、`knowledge_sync_task`(+`_exception_record`)、`module_code_prompt_cache`、
`open_api_conf`、`prompt_verify_scene_info`(+`_relate_prompt_info`)、`sync_knowledge_info`、
`sys_category`、`sys_role_ai_user`、`tool_management`、`trace_query_result`

> 其中 `sys_category` 两边都空 → **指标配置的分类树是空的**（需业务提供，不阻塞）；
> `ext_intf_*` 全空 → 外部接口管理向导无数据（同上）。

### 🔵 E. 业务数据（1 张，等公司）

| 表 | 公司库 | 说明 |
|---|---|---|
| `agent_rule` | **42** | 智策引擎的规则数据。**这是唯一一张"业务数据"表**，公司已有 42 条真实规则；新库要不要灌这 42 条，**建议确认后再说**（可能属行内业务口径，不宜照搬） |

---

## 三、🔴 五个引用陷阱（照抄会导坏，逐个说明）

### 3.1 指标 `script.dataSource` → `sys_data_source.id`（**id 必须对齐**）

- 公司库：`index_params.script` 里 `"dataSource"` **134 条全部引用 `2095447359636992001`**
  （= `sys_data_source.code='openGauss'` 那条，`db_type=16`）。
- 本地库那条数据源的 id 是 **`bosz-dev-local-0001`**（字符串）→ **两边 id 完全不同**。
- **后果**：只导 `index_params` 不导对应 `sys_data_source`（或导了但 id 不同），
  指标预览/取数会因为找不到数据源而失败。
- ✅ **做法**：导指标时**连同 id 为 `2095447359636992001` 的 openGauss 数据源一起导**（保持 id 一致）；
  或导入后把 script 里的 `dataSource` 批量改写成新库数据源 id。

### 3.2 `large_model_config.lm_code` ↔ 三处引用（**必须一致**）

同一个「大模型编码」被三处引用，**改名就会连锁失效**：

| 引用方 | 现用值 |
|---|---|
| `application-*.yml` 的 `agent.rule.parse-model-code` | 本地 `bosz-report-ai` |
| `knowledge_base_params.large_model_code` | 公司 **86/86 全是 `Qwen3-32B`** |
| `knowledge_base_params.large_model_content` 的 map key | 公司是 `Qwen3-32B`（另有历史 `qwen3`） |

- **后果**：`large_model_config` 里没有对应 `lm_code`，则模型下拉选不中、
  知识库预览取不到模型参数、智策引擎直接报"未找到大模型配置"。
- ✅ **做法**：新库先定 `lm_code`，然后 **①`large_model_config` 用它 ②yml 配置改它 ③知识库数据里的 code 改它**（三者一致）。

### 3.3 分组 id 必须先灌、且保持一致

- `knowledge_base_params.groupid` → `knowledge_base_group.groupid`（**末级分组**，已验证 86/86 命中）；
  `index_params.parentparamno` → `index_base_group.groupid`。
- ✅ **顺序**：`*_group` → 主表 → 关联表。若换成新 id，所有引用字段都要同步。

### 3.4 角色 id 必须**重映射**（不能原样导）

| 授权表 | 公司库 `role_id` 实际值 | 宿主/新库要用 |
|---|---|---|
| `sys_role_index` | `f6817f48af4fb3af11b9e8bf182f618b`(185) + `1965713153722445826`(3) | 宿主 `sys_role.id`（bigint，如 admin=1 / khjl=2） |
| `sys_role_knowledge` | `f6817f48af4fb3af11b9e8bf182f618b`(580) | 同上 |
| `sys_role_knowledge_output` | `2014532867719659522` | 同上 |

- **公司就是 Jeecg 角色体系**（`sys_role` 26 条、且**公司 `sys_role` 根本没有 `menu_permissions` 列**），
  宿主是自建 RBAC（`sys_role` 带 `menu_permissions`）→ **两套体系，角色 id 必然不同**。
- ✅ **做法**：一对一（或一对多）映射公司角色 → 宿主角色后**重新生成**；映射关系**需业务方确认**。

### 3.5 ⚠️ `sys_role_index` 建议不导（公司库自己就对不上）

- 188 条里：`index_id` 命中 `index_params.paramno` = **0**、命中 `paramid` = **0**、
  命中 `index_base_group.groupid` = **40**，**其余 148 条对不上任何现有主键**。
- `index_id` 取值形如 `2` / `10` / `11` / `1833756722415247361` —— 像**旧环境遗留 id**。
- **后果**：若原样导入，非 admin 角色按它过滤指标 → **看到的指标列表几乎必然为空**。
- ✅ **做法**：**不导**。由业务在新库用界面重新授权；或先只给 admin（admin 走 `*` 特判不受影响）。

---

## 四、执行步骤（客户现场新库）

> 每阶段末尾都有**校验 SQL**，跑通了再进下一阶段。

### 阶段 0 — 宿主先就位（**不可跳过**）

1. `CREATE SCHEMA <schema>;`（如目标 schema 不存在）
2. `SET search_path = <schema>, public;`
3. 执行**宿主自己的**初始化脚本：
   - `sql/init_auth_gaussdb.sql` → 建 `sys_user` / `sys_role` / `sys_user_role`（**agent 依赖这三张，但不在我们的 DDL 里**）
   - `sql/init_db_gaussdb.sql` → 宿主业务表
4. 宿主侧要有可登录的**用户 + 角色**（至少一个管理员）

**校验**
```sql
SELECT count(*) FROM sys_user;
SELECT count(*) FROM sys_role;
SELECT count(*) FROM sys_user_role;
```

### 阶段 1 — 建 agent 侧表（44 张）

执行 `sql/三菜单DDL/三个菜单_建表DDL.sql`（**一次跑通**：无外键、无序列依赖、索引名不冲突）。

**校验**
```sql
SELECT count(*) FROM information_schema.tables
WHERE table_schema = current_schema()
  AND table_name IN ( /* 44 张表名，见 DDL 的 CREATE TABLE 清单 */ );
-- 期望 44
```

### 阶段 2 — 基础配置（**有严格顺序**）

1. `sys_data_source`（**id 要与指标 script 对齐，见 §3.1**；密码用 `SecurityUtil.jiami()` 密文）
2. `large_model_config`（`lm_code` 与 yml 的 `agent.rule.parse-model-code` 一致，见 §3.2；`api_key` 明文）
3. `sys_dict` → `sys_dict_item`（先主表再子表）

**校验**
```sql
SELECT code, name, db_type FROM sys_data_source;         -- 指标 script 引用的 id 必须在
SELECT lm_code, model, use_flag FROM large_model_config; -- 必须含 yml 里配的那个 lm_code
SELECT count(*) FROM sys_dict; SELECT count(*) FROM sys_dict_item;
```

### 阶段 3 — 业务配置（**先分组、后主表、再关联**）

1. `index_base_group`
2. `index_params`（947 条 script 为空是正常的，不要"修"）
3. `index_relate_knowledge_info`
4. `knowledge_base_group`
5. `knowledge_base_params`
6. `knowledge_base_version`
7. `knowledge_relate_index`
8. `knowledge_relate_input_param`（测试集，可选）
9. `agent_rule`（42 条，**建议先确认**）

**校验（引用完整性，务必跑）**
```sql
-- 指标 ↔ 分组
SELECT count(*) AS total, count(g.groupid) AS matched
FROM index_params i LEFT JOIN index_base_group g ON g.groupid = i.parentparamno;
-- 知识库 ↔ 分组（期望 100%）
SELECT count(*) AS total, count(g.groupid) AS matched
FROM knowledge_base_params k LEFT JOIN knowledge_base_group g ON g.groupid = k.groupid;
-- 指标 script 的数据源是否都在
SELECT DISTINCT substring(script from '"dataSource"[[:space:]]*:[[:space:]]*"([^"]+)"') AS ds_id
FROM index_params WHERE script LIKE '%dataSource%';
-- 上一步结果里的每个 ds_id，都要能在 sys_data_source.id 里查到
```

### 阶段 4 — 授权 + 菜单可见性

1. **菜单授权（最关键，不灌则侧边栏看不到三个菜单）**
```sql
UPDATE sys_role SET menu_permissions = '["<原有菜单>","/agent/index-config","/agent/knowledge-config","/agent/rule"]'
WHERE id = <角色主键>;
-- 路径必须与 src/agent/routes.tsx 逐字一致；admin 走 "*" 特判不受影响
```
2. `sys_role_knowledge`：**只保留能命中现有分组的行**，并把 `role_id` 换成宿主角色主键
3. `sys_role_index`：**建议不导**（§3.5）
4. `sys_role_knowledge_output`：**可不导**（原值是孤值，§3.4/C 类说明）

**校验**
```sql
SELECT id, role_code, menu_permissions FROM sys_role ORDER BY id;   -- 三个 /agent/ 路径在不在
SELECT count(*) AS total, count(g.groupid) AS matched
FROM sys_role_knowledge s LEFT JOIN knowledge_base_group g ON g.groupid = s.knowledge_id;
```

### 阶段 5 — 应用侧配置 + 冒烟

1. 确认 yml：`agent.rule.parse-model-code` == `large_model_config.lm_code`
2. 起服务（显式端口），逐页点：
   - 指标配置：分组树 / 列表 / 数据源下拉 / 「关联信息」/ `KnowledgeCode` 4 步向导
   - 知识配置：列表 / 编辑器（切模型看「输出要求」是否跟着换）/ 预览（流式）
   - 智策引擎：规则列表 / 表单 / **AI 分析**（走大模型，验证 `lm_code` 链路）
3. 若"关联 Agent"下拉为空 → `agent_config` 表为空（正常，公司库也是空的）

---

## 五、待业务 / 公司确认（4 条）

| # | 事项 | 为什么不能自行决定 |
|---|---|---|
| 1 | **公司 26 个角色 → 新库角色的映射** | 决定 `sys_role_index` / `sys_role_knowledge` / `menu_permissions` 怎么给 |
| 2 | **`agent_rule` 那 42 条要不要带到新库** | 属业务规则口径，可能只是测试/演示数据 |
| 3 | **`sys_category` 分类字典数据** | 两边都空，但指标配置的分类树要用 → 需业务提供 |
| 4 | **是否导历史记录**（`call_llm_record` 8635 / `knowledge_query_result` 3776 / `prompt_query_result` 1466） | 演示/溯源需要 vs 数据量 |

---

## 六、本次盘查发现的引用完整性问题（5 条，都需知悉）

| # | 问题 | 数据证据 |
|---|---|---|
| 1 | `sys_role_knowledge.knowledge_id` 是**分组 id** 而非知识库 id，且 555/580 悬空 | 580 条中仅 25 条命中 `knowledge_base_group.groupid` |
| 2 | `sys_role_knowledge_output.knowledge_id` 是**孤值** | 对不上 paramid / paramno / groupid 任一种 → **真实环境无「输出要求」授权** |
| 3 | `index_relate_knowledge_info` 有 **12 条悬空** | 492 条，480 条可对应；`relate_group_id` 同样 480/492 |
| 4 | `knowledge_relate_index` 有 **12 条悬空** | 493 条，481 条命中 `knowledge_base_params.paramid` |
| 5 | `sys_role_index.index_id` **148/188 对不上任何主键** | paramno 命中 0 / paramid 命中 0 / groupid 命中 40 |

> 🔎 另一个容易搞反的事实（写代码/写 SQL 时注意）：
> **`index_params` 的主键是 `paramno`（雪花数字），`paramid` 才是业务编码**（如 `cwkm-jll`）；
> 而 **`knowledge_base_params` 正相反**：主键是 `paramid`（雪花），`paramno` 是业务编码（如 `jyk-yszk-AI`）。
> 两张表的 `paramno`/`paramid` 语义是**反的**，join 前务必确认。
