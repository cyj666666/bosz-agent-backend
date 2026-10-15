# 行内 ⇄ 外网 双向同步 + Vue3 迁移 实施方案

> 日期：2026-09-16
> 前序分析：`doc/行内版报告模块同步_差异分析.md`（全量差异清单）
> 本文目的：把「agent 三菜单进行内」+「外网报告与行内交互一致」+「前端转 Vue3」三件事拆成互不阻塞的工作流，并给出**影响面精确到文件**的执行口径

> ### ⚠️ 2026-09-16 20:2x 裁决更新（以 `报告模块_前端交互契约_v1.md` 为准）
> 本文写于裁决之前，以下 5 处的结论**已被推翻**，执行时请按契约：
> | 本文原结论 | 最终裁决 |
> |---|---|
> | `/credit/report` 独立页 ❌ 不整合 | ✅ **整合**，外网维护一份 |
> | `store.setCreditAuth()` ❌ 不整合 | ✅ **整合**（信贷页要用） |
> | `/plma` basename ❌ 部署差异、不带过去 | ✅ **外网跟行内一致**（`main.tsx` 基路径重定向也按行内） |
> | 信贷 `resolve` 用 mock 替身 | ✅ **搬行内 SM4 三件套**（`CreditTokenController` + `CreditTokenService` + `Sm4Service` + `credit.sm4-key` + `/api/credit/**` 白名单） |
> | 列表页「生成」按钮 / 999 弹框 待裁决 | ✅ 按钮**去掉**；失败走 **888 + `fail_reason` 软备注**；**999 前端统一隐藏** |
> 其余结论（agent 规模、3 处后端加法、接缝文件以外网为底、安全护栏）仍然有效。

---

## 0. TL;DR

1. **报告模块的接口面两端已经 100% 一致**（20 个端点，路径 / 方法 / 入参 / 出参逐一对齐，见 §2）。→ 你担心的"交互不一致"在**接口层根本不存在**，不需要搬后端代码。
2. 真正的差异只有 **2 个字段 + 1 处状态语义 + 4 处页面行为**（见 §3），全部是"加法"，影响面可枚举。
3. **接缝文件的行内增量 = 0**。`MainLayout`/`router`/`AuthGuard`/`store`/`main.tsx`/`types` 里行内"多出来的"东西（`/rules` 菜单、`/credit/report`、`setCreditAuth`、`/plma` basename）**全部属于要舍弃的行内专有件或已被外网 agent 模块覆盖**，一个都不用整合（见 §4）。
4. 所以正确姿势不是"同步后端代码"，而是**冻结一份《报告前端交互契约》**，让 Vue3 版和行内 React 版都照着它实现；外网后端只补 3 处即可充当验证替身。

---

## 1. 诉求拆解与建议路径

| 工作流 | 内容 | 方向 | 建议做法 |
|---|---|---|---|
| **W1** | agent 三菜单（指标配置 / 知识配置 / 智策引擎） | **外网 → 行内** | 后端整包搬运（自包含设计，改动面小）；前端**直接用 Vue3 重写**（React 版即将作废，不要搬） |
| **W2** | 报告模块"前端交互一致" | 以行内为准，**只对齐契约** | 不搬行内后端实现；外网后端只做 **3 处加法**；行内专有件一律不同步 |
| **W3** | 前端 React → Vue3 | 外网先做 | **契约驱动**（不逐行照抄 React），先"交互等价"再优化 |

> 一句话：**W2 的目的只是给 W3 提供"两端都能跑"的验证环境，不是真的要把行内后端搬过来。**

---

## 2. 【关键发现】报告模块接口面两端 100% 一致

对账方式：抽取两侧 `src/api/report.ts` 里 `reportApi.*` 实际调用的 URL 字面量，逐条比对（前端 baseURL 两端都是 `/api`，`api/request.ts` 字节级一致）。

**20 个端点，路径 / 方法 / 入参 / 出参全部一致：**

| # | 方法 | 路径 | 入参 | 出参 | 前端用在哪 |
|---|---|---|---|---|---|
| 1 | GET | `/report/instance/page` | `ReportPageQuery` | `PageResult<ReportInstanceSummary>` | 列表页 |
| 2 | POST | `/report/instance/create` | `ReportCreatePayload` | `ReportInstanceSummary` | 列表页「发起报告」 |
| 3 | GET | `/report/instance/{reportNo}` | path | `ReportInstanceDetail` | 详情页 |
| 4 | GET | `/report/instance/versions` | `checkTaskNo` | `ReportVersionItem[]` | 详情页版本下拉 |
| 5 | GET | `/report/instance/latest` | `checkTaskNo` | `ReportInstanceDetail` | 列表「查看」直达 |
| 6 | POST | `/report/instance/renew` | `checkTaskNo` | `ReportVersionItem` | 详情页「更新报告」 |
| 7 | POST | `/report/instance/generate` | `reportNo` | `{success,failReason,…统计}` | 「生成」（仅外网列表页用） |
| 8 | POST | `/report/instance/process` | `reportNo` | 同上 | 联调 |
| 9 | POST | `/report/instance/risk/status` | `{reportNo,blockCode,status}` | void | AI 风险 采纳/无效 |
| 10 | POST | `/report/instance/block/content` | `{reportNo,blockCode,content}` | void | 规则类正文编辑 |
| 11 | GET | `/report/instance/block/edit-history` | `checkTaskNo,blockCode` | `ReportRiskEditLogItem[]` | 「修改记录(N)」弹窗 |
| 12 | GET | `/report/instance/ai-analysis` | `checkTaskNo` | `ReportAiAnalysisItem \| null` | 智能体分析面板 |
| 13 | GET | `/report/instance/ai-analysis/list` | `reportNo` | `ReportAiAnalysisItem[]` | 历史分析列表 |
| 14 | POST | `/report/instance/ai-analysis/generate` | `{reportNo}` | `ReportAiAnalysisItem` | 触发全文分析 |
| 15 | POST | `/report/instance/ai-analysis/retry` | `{reportNo}` | `ReportAiAnalysisItem` | 重新分析 |
| 16 | GET | `/report/instance/ai-analysis/{id}` | path | `ReportAiAnalysisItem \| null` | 单次分析详情 |
| 17 | GET | `/report/instance/warning-advice` | `reportNo` | `ReportWarningAdviceVO \| null` | 预警建议 |
| 18 | POST | `/report/instance/warning-advice/generate` | `{reportNo}` | `ReportWarningAdviceVO` | 触发预警建议 |
| 19 | POST | `/report/instance/warning-advice/status` | `{id,status}` | void | 预警处置状态 |
| 20 | POST | `/report/instance/ai-chain/generate` | `{reportNo}` | `ReportAiAnalysisItem` | 链式（分析+预警） |

**数据模型也一致**：`ReportInstanceSummary` / `ReportPageQuery` / `ReportCreatePayload` / `ReportInstanceBlock` / `ReportInstanceCatalog` / `ReportInstanceRisk` / `ReportAiAnalysisItem` / `ReportWarningAdviceItem` / `ReportWarningAdviceVO` / `ReportRiskEditLogItem` / `ReportInstanceDetail` / `ReportVersionItem` —— 名字、字段名、类型全同。

> 结论：**前端交互的后端契约已经对齐**。剩下的只是 3 处字段/语义 + 4 处页面行为。

---

## 3. W2：报告模块需要对齐的**全部**差异（这才是影响面）

### 3.1 需要外网后端做的（**只有 3 处，纯加法**）

| # | 位置 | 行内现状 | 外网现状 | 改动量 |
|---|---|---|---|---|
| 1 | `ReportCreatePayload` / `ReportCreateRequest` | 有 `reportNo?: string`（选填，传了服务端跳过取号） | 无 | +1 字段 + create 分支判断（约 10 行） |
| 2 | `ReportInstanceDetail` / `ReportDetailVO` | 有 `failReason?: string`（**软备注**：部分块/模板/落库失败时写入，status 仍 888） | 无该字段 | +1 字段 + 生成结束时汇总块级失败写入（外网已有 `markFailReason`，改调用点即可） |
| 3 | 生成失败语义 | **888 唯一终态**：失败只写 `fail_reason` 软备注，不再产生 999 | 失败置 `999` 独立版本 + 前端弹框 | 改 `ReportServiceImpl.generate()` 的终态分支（约 20 行） |

**明确不搬**（外网不需要、搬了只会引入无效依赖与密钥配置）：
`SeqGeneratorService` / `DistributedLockService` / `claimReport()` / `clearInstances()` / `ReportGenerateJob`（生成池）/ `ReportDataCollectOrchestrator`（采集编排）/ `service/upstream/**`（CRCS·DFS·ESB·启信宝）/ `entity/upstream/**` / 上游 56 个 Mapper / `service/rams/**` / `service/credit/**` / `service/esb` / `service/crcs` / `service/seq` / `service/lock` / `plma/ssf/**` + `plma-ssf-api` 模块 / `Sm4Service` / `SsfConfig` / `RamsProperties` / `UpstreamInvokeProperties` / `CreditTokenController` / `EchoController` / `RamsSyncController` / `CreditShareUrlService` + `/share-url` / `AppCreditReportInfo` 等征信实体 / `sql/源头表|外网加工|押品加工|...` 全部 DDL。

> ⚠️ 其中 **③ 生成失败语义**是唯一的"行为变更"，且它与已裁决过的旧口径（"状态置 999 + failReason 持久化"）冲突，需要你重新确认一次（见 §7-A）。

### 3.2 需要外网**前端**做的（4 处，若外网还要维护 React 版）

| # | 位置 | 行内行为 | 外网现状 |
|---|---|---|---|
| 1 | 列表页 | **不提供**「生成」按钮；`111`/`000` 都显示"进行中…" | 有「生成」按钮（`Popconfirm`）；只有 `000` 显示进行中 |
| 2 | 详情页 | 失败 = 顶部**黄色软备注横幅** `.report-fail-note`；结果弹框只有成功态；版本下拉展示全部版本 | 失败 = 居中弹框（`failedVersion`+`clearFailed`）；版本下拉过滤 999 |
| 3 | 详情页 props | `{checkTaskNo?, hideBackButton?, canRenew?}`（信贷独立页复用）+ CSS 变量 `--report-header-offset` | 无 props、高度硬编码 |
| 4 | 创建弹框 | 多一个「报告编号（选填）」输入 | 无 |

> 若外网**只做 Vue3 版**、不维护 React 版，则这一节直接并入 W3 的契约实现，**不用改 React 代码**。

### 3.3 接缝文件的行内增量 = **0**（逐个核对结论）

| 文件 | 行内"多出来的" | 判定 |
|---|---|---|
| `MainLayout.tsx` | `'/rules': 知识库管理` 菜单项 | ❌ 已被外网 `agentMenus`（智策引擎规则管理）覆盖 → 不整合 |
| `router/index.tsx` | `/credit/report` 独立页、`/rules`、`basename:'/plma'` | ❌ 行内专有件 + 部署路径差异 → 不整合 |
| `AuthGuard.tsx` | 无（比外网**少** `DETAIL_PARENT`+`agentDetailParents`） | ❌ 无增量 |
| `store/index.ts` | `setCreditAuth()`（信贷 standalone 页专用） | ❌ 行内专有 → 不整合 |
| `main.tsx` | `/plma` 基路径重定向 | ❌ 部署路径差异 → 不整合 |
| `types/index.ts` | 无（比外网**少** `CollectorConfig` 等 4 个类型） | ❌ 无增量 |
| `index.css` | 报告页样式在 `ReportView` 的**内联 `REPORT_CSS`** 里，不在此文件 | ✅ 无增量（软备注样式随 `ReportView` 一起走） |

**影响面 = 0 行。** 你之前担心的"要往接缝里塞行车西"其实不存在。

---

## 4. W1：agent 三菜单 → 行内

### 4.1 后端（外网 → 行内）

| 类别 | 内容 | 规模 |
|---|---|---|
| Java 整包 | `com.suzhou.bank.agent/**`（自包含，**不依赖**宿主 `service/entity/mapper/common`） | **341 个文件** |
| 资源 | `resources/mapper/agent/*.xml`（28）+ `prompts/` + `sql/agent/*` | 28+ |
| 宿主接缝 | `MyBatisPlusConfig`（`@MapperScan` + bean 名生成器）/ `application.yml`（**新增 `agent:` 整段**）/ `AuthInterceptor`（`/api/agent/**` 放行）/ `pom.xml`（依赖） | 4 处 |

**配置差异（已核对）**
- 行内 `application.yml` 顶级键：`server / app / spring / mybatis-plus / know-kit / rams / credit / jwt / report / upstream / dfs`
- 外网 `application.yml` 顶级键：`server / app / spring / mybatis-plus / know-kit / jwt / report / agent`
- → **行内完全没有 `agent:` 段**（外网约 30+ 行：`lm-code`、指标角色过滤、进程内缓存键等），必须整段搬过去。`application.yml` 全量差异 148 行、`application-dev.yml` 33 行、`prod/uat` 各 8 行、`pom.xml` 215 行。
- ⚠️ `AgentDataCacheConfig` 里三个缓存键是 `@Value` **直读**，必须与 yml 键名**逐字一致**。

**行内适配点**
- 接口前缀统一 `/api/agent/**`（`AuthInterceptor` 只拦 `/api/**`）
- 菜单三处逐字一致：`menu.tsx` 的 key = 库里 `menu_permissions` = 前端路由
- 新增「列表→详情」页要在 `agentDetailParents` 登记
- 「配置」类弹框一律整屏（antd v6 用 `styles.container`）

### 4.2 前端（外网 React `src/agent/**` 42 文件 → **行内 Vue3，需重写**）

React/antd v6 代码**不能**直接进行内 Vue3 工程。建议：
1. 先把 `src/agent/**` 的**结构**（菜单 → 页面 → 组件 → API）整理成一张对照表（1 个菜单对应 1 个路由 + N 个页面 + N 个弹框）；
2. 页面按"列表页 / 编辑弹框 / 树选择器 / 溯源配置"四类归并成可复用 Vue3 组件（`useAgentTable` / `FilterForm` / `AgentRunning` / `ThinkText` / `MarkdownText` 这 5 个是外网已经抽好的通用件，Vue3 里对应实现一次即可到处用）；
3. `api/*.ts` 是纯 axios 封装，**几乎可以 1:1 平移**（改 `import` 与类型写法）。

---

## 5. W3：前端 React → Vue3（建议的做法）

**核心原则：以《报告前端交互契约》为唯一依据，不逐行照抄 React。**

契约应包含：
1. **接口表**：§2 那 20 行（路径/方法/入参/出参字段），Vue3 直接用。
2. **状态映射表**：`111/000/888/999` 在【列表状态列】【版本下拉】【详情页顶部】【AI 分析状态】【预警建议状态】各自怎么显示（文案 + 颜色 + 是否可点）。
3. **页面行为清单**：每个页面的按钮集合、弹框类型、加载态/空态/失败态、确认文案（例如「更新报告」的 `Popconfirm`、软备注横幅、失败弹框文案）。
4. **布局口径**：详情页三栏（目录 / 正文 / 侧栏）的 sticky 高度算式（行内用 `--report-header-offset` 变量，系统内 96px / 独立页 56px）——**这块最容易"看起来不一样"**。
5. **markdown 渲染**：正文必须接 markdown 渲染器，宽表独立横滚。

分两阶段：
- **Phase 1（交互等价）**：功能、状态、文案、布局与行内一致，不自作主张改 UI。
- **Phase 2（优化）**：视觉/性能优化，另行评审。

---

## 6. 安全护栏（8 条）

1. **两边的行内仓库只读**（`aimp-plma` / `aimp-plmaf` 是快照，各自只有 1 个提交，不要在里面改）。
2. **外网动手前先提交当前 15+9 项未提交改动**（全是 memory/doc，先把基线钉住，方便回滚）。
3. **W1 / W2 / W3 分开分支**（建议 `feat-agent-to-inner` / `feat-report-contract` / `feat-vue3`），互不阻塞。
4. **外网后端只做加法**：不删现有实现，不引入行内的锁/序列号/生成池/采集。每处改动后 `mvn -B -o -DskipTests package`（**必须 package**，启动读 `target/*.jar`）+ 接口冒烟。
5. **契约先冻结再写代码**（contract-first），避免"边写边改契约"导致两端再次漂移。
6. **W1 整包搬运时**：搬完立刻做"孤儿扫描"（有没有漏搬的引用的类/Bean/配置项），并用 `tsc 0 错误 ≠ 接线成功` 的心态做人工冒烟（三菜单各点一遍）。
7. **数据库改动（`sql/agent/**`、菜单 `menu_permissions` DML）单独授权**后再执行。
8. **换行符统一**：行内是 CRLF、外网是 LF，搬运时按目标仓库统一，否则产生整文件 diff 噪音（已知 `useReportApi.ts` / `UserList.tsx` / `api/auth|role|user.ts` 就是纯 EOL 假差异）。

---

## 7. 需要你拍板的 5 件事

| # | 问题 | 建议 |
|---|---|---|
| **A** | 生成失败语义：外网从「999 独立版本 + 失败弹框」改成行内的「888 + `fail_reason` 软备注」？ | **建议跟行内**（否则两端详情页行为不一致，Vue3 要写两套） |
| **B** | 列表页「生成」按钮：保留还是去掉？ | **建议去掉**（行内已收敛到详情页「更新报告」，少一个入口 = 少一处不一致） |
| **C** | 外网是否还继续维护 React 版？ | 若**不维护**，§3.2 的 4 处前端改动直接并入 Vue3 契约，**React 代码一行都不改**（最省） |
| **D** | Vue3 迁移范围：只迁报告+系统，还是连 agent 三菜单一起迁？ | **建议一起**（agent 前端反正要 Vue3 重写，一次设计一次实现） |
| **E** | 《报告前端交互契约》由谁定稿？ | **建议我先出一版**（基于行内 React 实际行为 + 20 接口对账结果），你审完冻结，再动 Vue3 |

---

## 附：本次核对产生的中间产物

已清理。核对脚本/清单如需要可随时重跑（方法：把两侧 `src` 复制到纯 ASCII 路径后用 `git diff --no-index --text` 比对，行内仓库无共同 git 历史无法直接 diff）。
