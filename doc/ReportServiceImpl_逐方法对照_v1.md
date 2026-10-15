# `ReportServiceImpl` 逐方法对照清单 v1

> 对比对象：行内 `plma-agent-backend/.../service/impl/ReportServiceImpl.java`
> vs 外网 `bosz-agent-backend/.../service/impl/ReportServiceImpl.java`（1883 行）
> `git diff` 规模：**+813 / -411（共 1224 行）** ⇒ 属「两代分叉」，**不可整拷**，须逐方法对照
> 生成日期：2026-09-20 ｜ 台账：`doc/行内同步台账.md` 批次 2
>
> ✅ **全部完成（2026-09-20）**：①②③④⑤⑥ 六步全落地 —— 行内 `ReportServiceImpl` 现 **2139 行**。
> 合计 = 外网增量全部摘入 + **3 处行内专属增强**（`createReport` 立即触发 / `generateManually` 入口闸门 /
> `seenBlockCodes` 线程安全）+ **1 处旧 bug 修复**（`buildRisk` 去重键 `agentCode` → `blockCode`）。
> ⚠️ **本文件对应的行内版本已成为「行内专属改动」的载体** —— 增量合入外网时**禁止整文件覆盖**，
> 详见 `doc/行内同步台账.md` §二·补「行内专属修改清单」。

---

## 0. 结论摘要

| 类别 | 数量 | 处理 |
|---|---|---|
| **行内独有** | 7 个方法 | ⛔ **一律保留**（SSF / 分布式锁 / 取数编排） |
| **外网独有** | 7 个方法 + 1 个内部类 + 4 个常量 | ✅ **摘入** |
| **两边都有但实现不同** | 9 个方法 | 🔃 **逐个合并**（行内为底 + 外网增量） |
| **两边完全一致的** | 其余约 40 个 | ⏭️ 不动 |

---

## 1. ⛔ 行内独有 —— 保留不动（7 个）

| 方法 | 行内行号 | 作用 | 外网为什么没有 |
|---|---|---|---|
| `buildInitLockName(String)` | 94 | 报告初始化锁名 | 外网**不加分布式锁**（靠上游统一加锁） |
| `buildVersionLockName(String)` | 99 | 版本锁名 | 同上 |
| `submit(ReportSubmitRequest)` | 134 | **SSF 信贷发起入口** | 外网无 SSF 渠道 |
| `newPendingReport(...)` | 160 | 落 111 的统一内核（锁内校验在途 + 取号） | 外网无此内核 |
| `toNoResult(Report)` | 197 | `Report` → `ReportNoResult` | 外网无该 DTO |
| `latest(String checkTaskNo)` | 209 | SSF 按流水号查记录（返 `ReportNoResult`） | ⚠️ **外网的 `latest` 是详情页方法（返 `ReportDetailVO`）—— 同名同参不同返回值，绝不能混** |
| `claimReport(String reportNo)` | 317 | CAS 认领 `111/999 → 000` | 外网无认领（由上游加锁） |

> 🔴 **连带影响**：行内 `latestC(String)`（详情页，返 `ReportDetailVO`）**保持原名**，不要改成 `latest`。

---

## 2. ✅ 外网独有 —— 摘入（7 方法 + 1 内部类 + 4 常量）

| # | 成员 | 外网行号 | 作用 | 依赖 |
|---|---|---|---|---|
| 1 | `blockTimeoutNote()` | 132 | 块阶段超时的一次性软备注文案 | 常量 `BLOCK_PHASE_TIMEOUT_MILLIS` |
| 2 | `isDeferredBlock(AppReportContentBlock)` | 503 | 判断「延后到阶段 2」的块：<br>`RULE_SUMMARY` / `RULE_SUMMARY_TAIL` / `RULE_ENTRY#*` | 3 个 `AGENT_*` 常量 |
| 3 | `fillRiskSummaryBlocks(...)` | 531 | **阶段 2**：回填风险要点三段式<br>· `RULE_SUMMARY` 总结（1 次大模型调用，`#PICK#`/`#TAIL#` 分隔）<br>· `RULE_ENTRY#*` 条目（复用对应 RULE 内容，不调模型）<br>· `RULE_SUMMARY_TAIL` 收尾 | `reportContentProvider`、`slots`、`blockFailures` |
| 4 | `isAgentFillable(AppReportContentBlock)` | 1909 | 块是否需要调 agent | — |
| 5 | `markStatus(String, String)` | 1920 | 状态置位（含 999 兼容分支） | — |
| 6 | `generateReportNo()` | 1634 | `RPT + yyyyMMddHHmmss + 4位随机` | — |
| 7 | `nextVersionOf(String checkTaskNo)` | 1654 | 取下一个版本号 | — |
| 8 | `class BlockOutcome`（内部类） | — | 把「实例 + 加工产物 payload」一起带出（供 `buildRisk` 拿 `checkResult`） | — |

**4 个常量**：

| 常量 | 值/来源 | 备注 |
|---|---|---|
| `AGENT_RULE_SUMMARY` | `"RULE_SUMMARY"` | 外网 **L97**，Service **自己定义**（注释标注"与 provider 同值"，⚠️ 不是引用 provider 常量） |
| `AGENT_RULE_SUMMARY_TAIL` | `"RULE_SUMMARY_TAIL"` | 外网 **L106** |
| `AGENT_RULE_ENTRY_PREFIX` | `"RULE_ENTRY#"` | 外网 **L112** |
| `BLOCK_PHASE_TIMEOUT_MILLIS` | `10 * 60 * 1000L`（**10 分钟**）<br>实测单块 21:17:06→21:17:35 已过大半，10 分钟预算宽裕 | 外网 **L129**；`blockTimeoutNote()`（L132-135）引用它 |

**1 个字段注入**：

```java
/** 内容块级并发池：一份报告内多个内容块并行调智能体用（与 reportGenerateExecutor 是两层，不能合并） */
@Resource(name = "reportBlockExecutor")
private ThreadPoolTaskExecutor reportBlockExecutor;
```
> 外网 L171-172。Bean 已在批次 2 由 `ReportGenerateConfig` 注册 ✅

> ✅ **`markStatus` / `generateReportNo` / `nextVersionOf` 的取舍已定（⑥ 核对结论）**：
> · `nextVersionOf` → **已摘入**（`markDone` 取号用，行内行号 **1681**）
> · `markStatus` → **不摘**（行内用 `claimReport` 的 CAS `111/999 → 000` 置位，更严谨）
> · `generateReportNo` → **不摘**（行内用**流水号服务**取报告编号，见 `newPendingReport`；<br>
>   外网是 `RPT + yyyyMMddHHmmss + 4位随机`，行内口径更优）

---

## 3. 🔃 两边都有但实现不同 —— 逐个合并（9 个）

| # | 方法 | 行内行数 | 外网行数 | 状态 / 合并要点 |
|---|---|---|---|---|
| 1 | `doProcess()` | 486-678（193）| 287-486（200）| ✅ **已完成（④）**：串行 → **并发（`reportBlockExecutor` + `slots[]`/`riskSlots[]`）+ 阶段 2 回填 + 10 分钟超时预算 + 逐行隔离落库**，见 §4。<br>⚠️ **保留了行内的 `dataCollectOrchestrator.collect(reportInfo)`**（取数编排，外网没有）—— 已自检 ✅<br>➕ 额外加固：`seenBlockCodes` 改用**线程安全 Set**（外网是普通 `HashSet`，多块并发 `add` 可能丢更新 ⇒ 脏模板下重复行漏检） |
| 2 | `buildInstance()` | 1432-1481（50，1 个）| 1701-1770（70，**2 个重载**）| ✅ **已并（③）**：返回类型 `AppReportContentInstance` → **`BlockOutcome`**；拆 6 参 / 7 参两个重载（7 参版多带 `payload`） |
| 3 | `buildRisk()` | 1497-1517（21，3 参）| 1803-1832（30，**4 参**）| ✅ **已并（③）**：加 `ContentPayload` 参数 + `setCheckResult(...)`。<br>🔴 顺带修掉一个**会打挂报告**的旧实现：去重键 `agentCode` → **`blockCode`**，重复时由「抛异常」改「warn + 跳过」（同一规则跨章节合法复用） |
| 4 | `latestAiAnalysis()` | 1037（参 `checkTaskNo`）| 1254（参 `reportNo`）| ✅ **已改（⑤）**：改按 `reportNo` 查，连带改 `ReportService` 接口 + `ReportController` 入参。<br>⚠️ 不改则前端（Vue3 传 `reportNo`）**永远拿不到数据**（面板一直空态） |
| 5 | `generate()` | 241-291 | 191-262 | ✅ **核对完（⑥）→ 以行内为准，不改**。行内是演进版：`claimReport` CAS 认领 `111/999 → 000` + 基础设施异常交生成池「000 超时兜底」；外网是简化版（`loadReportInfo` + `markStatus` + 兜底**就地置 888**）。<br>**外网没有生成池**，换过去 = 丢掉行内整套兜底 |
| 6 | `process()` | 292-316 | 263-286 | ✅ **核对完（⑥）→ 两边语义完全一致，不改**（仅注释措辞不同，都直接转 `doProcess`） |
| 7 | `markDone()` | 350-382 | 1953-1971 | ✅ **已并（⑥）**：摘外网「**沿用已有 version**」修复（详见 §3.1）+ **保留行内版本锁**；取号口径由 `记录总数(count)` → `nextVersionOf(max+1)` |
| 8 | `createReport()` | 934-961 | 845-915（70）| ✅ 核对完（⑥）**判定不照搬外网版**；🔧 另按用户裁决做了 **行内增强**：改用共用的 `triggerImmediately()` **立即触发**（原来「落 111 就返回」、纯靠池）。<br>⇒ 管理员入口不再等池轮询间隔，且**不依赖池开关**。<br>⛔ 外网版（**无条件** `execute`）**仍然不能照搬** —— 行内有池，而 `claimReport` 对 `000` 是「直接放行」⇒ 无条件触发会**重复加工**；必须走 CAS 闸门 |
| 9 | `renew()` | 1044-1087 | 1004-1061 | ✅ **核对完（⑥）→ 以行内为准，不改**。行内：`newPendingReport` 落 111 → **CAS 认领** 111→000 → **抢到才** `reportGenerateExecutor.execute` 立即执行（抢不到什么都不做，让池下轮捞）；外网：创建时**直接写** `version = nextVersionOf()` 并无条件异步触发 |

> 📌 **🔧 行内触发路径已按用户裁决调整（2026-09-20）—— 4 条路径全表**
>
> | 路径 | 入口 | 主动触发 | 闸门 | 池停用时 |
> |---|---|---|---|---|
> | SSF 信贷发起（正规） | `POST /report/submit` → `submit()` | ❌ 纯靠池 | 池 CAS 认领 | ⛔ 需人工补偿 |
> | **管理员入口（非正规）** | `POST /report/instance/create` → `createReport()` | ✅ **立即触发**（本轮新加） | **CAS 认领，抢到才 execute** | ✅ **照常可用** |
> | **详情页更新报告** | `POST /report/instance/renew` → `renew()` | ✅ 立即触发 | **CAS 认领，抢到才 execute** | ✅ **照常可用** |
> | 补偿入口 | `POST /report/instance/generate` → `generateManually()` | ✅ 同步直调 | **入口状态闸门：仅放行 111/999**（本轮新加） | ✅ 可用 |
>
> **① `triggerImmediately(reportNo)`（新增私有方法，`renew` + `createReport` 共用）**
> ```
> CAS: UPDATE report SET status=000 WHERE reportNo=? AND status=111
>   ├─ 抢到(1) → reportGenerateExecutor.execute(generate)      [池满被拒 → 退回 111 交池]
>   └─ 抢不到(0) → 什么都不做（池已认领，由池跑）              ⇒ 两条路径互斥，绝不重复加工
> ```
> 不碰 `version`（仍由 `markDone` 在 checkTaskNo 锁内统一取号）、不依赖池开关
> （`reportGenerateExecutor` 在 `ReportGeneratePoolConfig` **无条件注册**，与 `enabled` 无关）。
>
> **② `generateManually(reportNo)`（新增，`/instance/generate` 专用）**
> `claimReport` 对 `000` 是「直接放行」（为池路径设计：池已认领为 000 后再调不该被拦），
> 所以它**挡不住第二个触发者** ⇒ 必须在入口拦：`000` 拒（正在加工）、`888` 拒（重跑走「更新报告」），
> 只放行 `111 / 999`。
>
> **③ 为什么外网版 `createReport` 依然不能照搬**：外网**没有池**（`ReportGenerateJob` /
> `ReportGeneratePoolConfig` / `ReportGeneratePoolProperties` 三个文件外网均不存在），
> 它的无条件 `execute` 在其环境里成立；放进行内 ⇒ 与池抢跑 ⇒ `claimReport` 对 000 放行 ⇒ **重复加工**。
> **结论：行内要的是「立即触发 + CAS 闸门」，不是「无条件触发」。**
>
> ⚠️ **另一个同类隐患（未处理，待评估）**：`POST /report/instance/process` → `process()` 是**纯加工**
> （不改状态、不认领），任何状态都能跑。若池正在加工同一条，调它会并发 `clearInstances` + 重写实例。
> 建议同样加限制，或仅在联调环境暴露。

> 其余同名方法（`detail` / `page` / `versions` / `updateRiskStatus` / `updateBlockContent` / `startAiAnalysis` / `aiAnalysisList` / `startWarningAdvice` / `startAiChain` / `toCatalogNode` / `validateTemplate` / `loadEnabled*` / `sortCatalogBlocks` / `trimToNull` / `assertReportNoPresent` …）**行数一致或差异极小**，确认后不动。

---

## 3.1 🔴 `markDone()` 版本号口径变更（⑥ 的关键判断）

| | 行内旧版 | 改后（沿用行内结构 + 外网修复） |
|---|---|---|
| **取号时机** | 每次 `markDone` 都重算 | **已有 version 则沿用**，只有为空才取号 |
| **取号规则** | `count(*)`（该流水号下**记录总数**） | `nextVersionOf()` = **已赋版本号的最大值 +1** |
| **锁** | 锁内读 count | **保留**：锁内读最大值（防并发翻 888 撞号） |
| **风险** | 🔴 同一记录被**重跑**（000 超时兜底重置 111 后重捞）时，若期间新增了版本，version 会**漂移** ⇒ 出现「两条记录同版本号」的串号 | ✅ 版本号与记录绑定、一次写入终身不变 |

```java
// 改前（行内）
Long count = reportMapper.selectCount(...eq(checkTaskNo));
version = count == null ? 1 : count.intValue();

// 改后（沿用行内锁 + 外网「沿用」修复）
Integer version = reportInfo.getVersion();                     // ① 沿用
if (version == null && StringUtils.hasText(checkTaskNo)) {
    lock { version = nextVersionOf(checkTaskNo); }             // ② 锁内取号（max+1）
}
```

**为什么不完全照搬外网版**：外网版**不带锁**（其并发由「发起时不允许重复 + renew 校验在途」挡住）。
行内保留了版本锁作为**历史脏数据的双保险** ⇒ 符合「以行内实现为准 + 只摘必要修复」。
`suspend` 连带：行内 `buildVersionLockName()` 与 2 个 `REPORT_VERSION_LOCK_*` 常量**继续在用**，无死代码 ✅

> **`markStatus()` / `generateReportNo()` 结论：不需要摘** —— 行内用 `claimReport` CAS 置 000（不需要 `markStatus`）、
> 用**流水号服务**取报告编号（`newPendingReport` 内，比外网的 `RPT+时间戳+随机` 更严谨）。

---

## 4. ✅ `doProcess()` 步骤级对照（④ 已全部落地）

| 步骤 | 行内（1655 行版） | 外网（1883 行版） | 处理 |
|---|---|---|---|
| 1 报告抬头 | ✅ 同 | ✅ 同 | 不动 |
| **1.5 取数编排** | ✅ `dataCollectOrchestrator.collect(reportInfo)`<br>失败汇总进 `blockFailures` | ❌ **没有** | **保留行内** ✅（外网无采集链路） |
| 2 模板载入 + 校验 | ✅ 同 | ✅ 同 | 不动 |
| 3 逐块加工 | **串行 `for` 循环**<br>直接 `buildInstance(...)` → `instances.add` | **并发**：<br>· `reportBlockExecutor.submit(...)`<br>· `slots[]` / `riskSlots[]` 按索引占位<br>· `isDeferredBlock(block)` → `continue`（阶段 2 负责）<br>· `isRuleBlock(block) && hasText(instance.getContent())` 才建风险行<br>· `buildRisk(instance, block, outcome.getPayload(), seenBlockCodes)` | 🔴 **摘外网并发版** |
| 3 收尾（等待） | — | `Future.get(remain)` + **块阶段总预算**<br>`BLOCK_PHASE_TIMEOUT_MILLIS` 超时 → `cancel(true)` + 记一次 `blockTimeoutNote()` | 🔴 **摘**（防单块阻塞把报告卡在 000，2026-09-19 实测） |
| **3.5 阶段 2** | ❌ 无 | ✅ `fillRiskSummaryBlocks(reportNo, customerId, customerName, blocks, catalogMap, slots, blockFailures)` | 🔴 **摘**（风险要点三段式的关键） |
| 3 结果收敛 | 边跑边 `add` | 按 `slots` 顺序收敛（跳过 null） | 随并发改造 |
| 4 落库 | `clearInstances` + **整批一个 try-catch** | `clearInstances` + **逐行隔离落库**（每行独立 try-catch，失败只进软备注） | 🔴 **摘**（防「一行冲突丢掉其后所有行」→ 报告 888 但风险列表莫名少几条） |
| 5 结果统计 | ✅ 同 | ✅ 同 | 不动 |

### ✅ ④ 落地记录（2026-09-20，上表「处理」列已全部执行完毕）

| 项 | 行内位置 | 说明 |
|---|---|---|
| 阶段 1 并发提交 + 槽位 | **L532-572** | `reportBlockExecutor.submit` + `slots[]` / `riskSlots[]` + `failureSink`（`synchronizedList`） |
| 超时预算 + 取消 | **L573-607** | `BLOCK_PHASE_TIMEOUT_MILLIS`（10 分钟）；超时 `cancel(true)` + `blockTimeoutNote()` 只记一次 |
| 阶段 2 回填 | **L609-613** | `fillRiskSummaryBlocks(reportNo, customerId, customerName, blocks, catalogMap, slots, blockFailures)` |
| 结果收敛 | **L615-635** | 按 `slots` 顺序，跳过 null（含阶段 2 判定为 HIDE 的块） |
| 逐行隔离落库 | **L637-664** | 实例 / 风险各自逐行 try-catch，失败只进软备注（**不再整批中断**） |
| ⚠️ **保留行内取数编排** | **L482-494** | `dataCollectOrchestrator.collect(reportInfo)` —— 外网**没有**，**摘并发版时最容易漏的一处** |
| ➕ 主动加固 | **L532** | `seenBlockCodes` 用 `Collections.synchronizedSet`（外网是普通 `HashSet`，多块并发 `add` 可能丢更新） |
| ➕ 顺带清理 | L496 附近 | 删掉 8 行残留空行（早期改动留下） |

**✅ 合并后自检（对照 §5 清单，全部通过）**

| # | 检查项 | 结果 |
|---|---|---|
| 1 | `dataCollectOrchestrator` 未丢 | ✅ L14 import / L77 字段 / **L486 调用** |
| 2 | 行内独有件未误伤 | ✅ `submit` L189 / `newPendingReport` L215 / `latest`(SSF) L264 / `claimReport` L391 / `latestC` L1141 |
| 3 | `clearInstances` 调用点仍在（支持重跑） | ✅ L638 |
| 4 | 4 个常量定义 + 被引用 | ✅ `AGENT_RULE_SUMMARY`×6 / `BLOCK_PHASE_TIMEOUT_MILLIS`×4 |
| 5 | 上轮行内增强仍在 | ✅ `generateManually` L364 / `triggerImmediately` L1208 |
| 6 | 形式检查 | ✅ 括号配平 396/396；文件 **2139 行** |
| 7 | 旧串行代码残留 | ✅ 已清零（`agentCodes` 仅剩 `fillRiskSummaryBlocks` 内的 `ruleAgentCodes`，是不同用途的局部变量） |

> ⚠️ **一个细节差异**：`blockFailures` 的获取方式
> 行内：`List<String> blockFailures = new ArrayList<>(); result.setBlockFailures(blockFailures);`
> 外网：`List<String> blockFailures = result.getBlockFailures();`
> 两者等价（`ReportGenerateResult` 已初始化该 list），**以行内为准**即可。

---

## 5. 合并顺序建议（降低回归风险）

```
✅ ① 已摘「无副作用的独立件」：4 个常量 + 内部类 BlockOutcome + blockTimeoutNote() + reportBlockExecutor 字段
✅ ② 已摘「只被新逻辑调用的方法」：isDeferredBlock() / isAgentFillable() / fillRiskSummaryBlocks()
      ⚠️ 连带同步放宽两处口径（否则自相矛盾）：isRuleBlock() 由 FILL_TEXT → TEXT || TABLE；
         validateTemplate() 的 analysisType 校验同步放宽
✅ ③ 已改「签名变化」：buildInstance() → BlockOutcome（含新增 7 参重载）、buildRisk() → 4 参 + setCheckResult()
✅ ④ 已完成：doProcess() 串行 → 并发 + 两阶段 + 10 分钟超时预算 + 逐行落库
      ⚠️ 已确认保留 `dataCollectOrchestrator.collect(reportInfo)`（L486）—— 落地记录见 §4
✅ ⑤ 已完成：latestAiAnalysis() 改按 reportNo（连带 ReportService 接口 + ReportController 入参）
✅ ⑥ 已完成：5 个方法逐个核对 —— generate / process / createReport / renew **均以行内为准不改**；
      markDone 摘入「沿用已有 version」修复（口径详见 §3.1）
```

**每一步后的自检**：
- `dataCollectOrchestrator` 字段仍在、仍被调用
- `claimReport` / `submit` / `latest`(SSF) / `latestC` 未被动过
- `clearInstances` 调用点仍在（重跑支持）
- 所有 `AGENT_*` / `BLOCK_PHASE_TIMEOUT_MILLIS` 常量已定义且被引用

---

## 6. 🔴 风险与红线

| # | 风险 | 说明 |
|---|---|---|
| 1 | **行内状态机不能被覆盖** | `submit` / `claimReport` / 锁 / `generate-pool` 是行内演进成果，外网版没有 ⇒ 整拷=回退 |
| 2 | **`latest` 名字冲突** | 行内 `latest`(SSF) vs 外网 `latest`(详情) ⇒ 保留行内 `latestC` |
| 3 | **`dataCollectOrchestrator` 必须保留** | 外网 `doProcess` 没有取数编排；漏掉=行内报告取不到数 |
| 4 | **并发改造会引入线程安全变量** | `seenBlockCodes`（`buildRisk` 内去重）、`slots`/`riskSlots` 数组、`failureSink`（`synchronizedList`）—— 必须与外网一致，否则会有竞态 |
| 5 | **`reportBlockExecutor` Bean 依赖** | 批次 2 已在 `ReportGenerateConfig` 加好 ✅；`report.agent.block-pool-size` 有默认值 5 ✅ |
| 6 | **本机无法编译验证** | 行内私有依赖本机 `~/.m2` 缺失（`ssf-app-api` 等）⇒ 只能在行内环境验证 |

---

## 7. 决策记录与剩余事项

| # | 问题 | 裁决 / 结论 |
|---|---|---|
| 1 | 是否按 §5 的顺序动手合并？ | ✅ **已定：同意** —— ①②③ 已落，④ 单独一步并重点自检 |
| 2 | 5 个「待细看」方法要不要先出详细 diff？ | ✅ **已定：先出** → ⑤⑥ 已完成（见 §3 表格逐条结论） |
| 3 | `markStatus` / `nextVersionOf` / `generateReportNo` 要不要摘？ | ✅ **已定**：只摘 `nextVersionOf`；另两个不摘（理由见 §2 末尾） |

### 剩余事项

| # | 事项 | 风险 | 说明 |
|---|---|---|---|
| 1 | 🔴 **④ `doProcess()` 并发改造** | 最高 | 见 §4；**唯一剩余的代码改动** |
| 2 | 行内环境编译验证 | — | 本机缺行内私服依赖（`ssf-app-api` 等）⇒ **必须在行内环境 `mvn compile`** |
| 3 | `app_guarantor_info` 表 | 中 | `AppGuarantorInfo` + Mapper 已拷入，**依赖该表存在**（属交付包 DDL 范畴） |
| 4 | ⚠️ React 前端（若行内仍在跑） | 中 | ⑤ 把 `/instance/ai-analysis` 入参由 `checkTaskNo` 改为 `reportNo`；<br>**Vue3 前端本来就传 `reportNo` ✅**，但行内若还挂 React 版前端需留意 |
