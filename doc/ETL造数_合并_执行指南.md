# ETL造数_合并 · 执行指南

> 最后更新：2026-09-22　（基于本地库 openGauss 实跑验证，**243 条语句 100% 通过**）
> 适用：需要为 `reportNo = 'RPT-202609-001'` 造出 39 张源头表数据，并顺带跑通 34 段加工产出 app 表。

---

## 0. 一句话

把 `src/main/resources/sql/ETL造数_合并/` 下的 **5 个文件按 `01 → 02 → 03 → 04 → 05` 顺序**跑一遍即可。
数据会**保留在库里**，用 `reportNo = 'RPT-202609-001'` 就能核验。

---

## 1. 前置条件

| 项 | 要求 |
|---|---|
| 数据库 | openGauss / GaussDB（本地 `as_agent` schema） |
| 文件位置 | `src/main/resources/sql/ETL造数_合并/`（5 个 `.sql` + 1 个核验脚本） |
| 表结构 | 目标 app 表需已建好**且列齐全**（见 §6 缺列问题） |

### 🔴 执行器要求（最容易踩的坑）

**必须是「逐条独立提交 + 单条失败继续」的执行方式。**

- 原因：openGauss/PG 在**整体事务**模式下，任何一条语句失败会把事务置为 `aborted`，**后续语句全部被拒绝**
  （`current transaction is aborted, commands ignored until end of transaction block`）
- 因此：**不要**用 IDEA / Navicat 的「执行整个文件」（默认整体事务），否则一条错就全废
- 本次采用的模式：`autoCommit = true` 逐条执行 + `try/catch` 记录错误后继续

---

## 2. 执行顺序（**必须按序，不能乱**）

| 顺序 | 文件 | 语句数 | 依赖 |
|---|---|---|---|
| 1 | `01_外数加工_合并.sql` | 32 | — |
| 2 | `02_客户企业概况加工_合并.sql` | 113 | 与 01 共享 `ws_gs_info`（但各清各的，见 §3） |
| 3 | `03_押品加工_合并.sql` | 29 | 独立（不实际引用 `xd_corp_check_info`） |
| 4 | `04_贷后检查加工_合并.sql` | 62 | **需 01 先建 `ws_gs_info` 借款人照面行；需 02 先建 `xd_credit_info` / `xd_credit_loan`** |
| 5 | `05_财务指标加工_合并.sql` | 7 | 独立 |

**为什么顺序不能乱**：
- `01` 的 §0 会清 `ws_gs_info` 的**借款人照面行**（`name IS NULL`）—— 而 `04` 的 `entId` 就挂在这一行上；
  若 `04` 先跑再跑 `01`，`entId` 会被清掉 ⇒ `app_graph_hit_info` 加工撞不到 ⇒ 0 行
- `02` 的 §0 会清 `xd_credit_info` / `xd_credit_loan` —— 而 `04` 的 `app_capital_flow_info` 要读它们取 `loanStatus`

> **重跑同理：必须从 01 开始按序重跑**，不能只重跑 04。

---

## 3. 跨组共享源表的 owner 约定（谁造谁清）

| 源表 | owner（造数 + 清理） | 其他组的角色 |
|---|---|---|
| `ws_gs_info` | **01** 造借款人工商照面行（`customerId='CUST-001'`、`name IS NULL`）<br>**02** 造 2 行收款人企业（`customerId IS NULL`） | **04 只 `UPDATE` 补 `entId`**，不 INSERT、不 DELETE |
| `xd_credit_info` | **02**（`app_credit_use_info` 的 14 列全字段版） | 04 只读（取「当前主档」id） |
| `xd_credit_loan` | **02**（`app_loan_receipt_info` 的 12 行 28 列版） | 04 只读（按 `loanSerialNo` 撞 `loanStatus`） |
| `xd_corp_check_info` 等组内父表 | 02 组内**唯一一处**（其余位置已 `[已合并]` 省略） | — |

**为什么**：这些表的清理段原本都是 `DELETE ... WHERE customerId='CUST-001' AND reportNo=...`
—— **多组共用同一条删除范围**，谁后跑谁把前面的数据清掉。收敛成「唯一 owner」后不再互相清场。

---

## 4. 预期结果

### 4.1 语句层面
| 文件 | 语句 | OK | ERR |
|---|---|---|---|
| 01 | 32 | 32 | 0 |
| 02 | 113 | 113 | 0 |
| 03 | 29 | 29 | 0 |
| 04 | 62 | 62 | 0 |
| 05 | 7 | 7 | 0 |
| **合计** | **243** | **243** | **0** |

### 4.2 源表层面（39 张 → **38 张有数据**）
用 `00_核验_源表行数.sql` 逐张核验。参考基线（本地库实测）：

| 源表 | 行数 | 源表 | 行数 |
|---|---|---|---|
| `ws_gs_info` | 3 | `xd_corp_check_warning_task` | 3 |
| `ws_beneficial_owner` | 1 | `xd_corp_check_warning_opinion` | 2 |
| `std_ecis_t_mining_tags_dd` | 4 | `xd_warning_ledger` | 6 |
| `ws_best_shareholding` | 6 | `xd_corp_customer_info` | 1 |
| `ws_equity_change` | 4 | `xd_corp_customer_control` | 2 |
| `ws_base_info` | 1 | `xd_corp_customer_shareholder` | 6 |
| `xd_corp_check_info` | 1 | `xd_credit_info` | 1 |
| `xd_corp_check_daily_index` | 25 | `xd_credit_loan` | **12** |
| `xd_corp_check_fixed_loan` | 7 | `xd_credit_payment` | 2 |
| `xd_corp_check_operate_loan` | 2 | `xd_single_task_check` | 2 |
| `xd_corp_check_reply_requirement` | 5 | `xd_corp_check_collateral` | 3 |
| `xd_corp_check_checkin` | 2 | `xd_corp_check_collateral_mortgage` | 1 |
| `xd_corp_check_credit_requirement` | 1 | `xd_corp_check_collateral_restrict` | 1 |
| `xd_corp_check_current_opinion` | 1 | `xd_fund_use_abnormal` | 7 |
| `xd_corp_check_last_opinion` | 1 | `xd_graph_hit` | 1（按 `eid`） |
| `xd_corp_check_supplier` | 10 | `dfs_crdt_loan_cust_rel` | 1 |
| `dfs_final_crdt_loan_cust_rel` | 4 | `gfzx_balance_sheet_item` | 3 |
| `gfzx_profit_sheet_item` | 1 | `gfzx_national_dev` | 1 |
| `xd_financial_report` | 18 | `xd_financial_subject` | 270 |
| ~~`gfzx_finance_index_item`~~ | **0** | | ⚠️ 脚本注释「**本表不取，预留**」⇒ **0 行属正常，不是缺陷** |

### 4.3 app 表抽查（加工产物）
| app 表 | 行数 | app 表 | 行数 |
|---|---|---|---|
| `app_check_index_info` | 25 | `app_collateral_info` | 3 |
| `app_check_object_info` | 78（见 §7.1） | `app_collateral_mortgage_info` | 1 |
| `app_customer_info` | 1 | `app_graph_hit_info` | 1 |
| `app_credit_use_info` | 1 | `app_settle_asset_info` | 1 |
| `app_loan_receipt_info` | **12** | `app_guofa_report_info` | 1 |
| `app_entrust_pay_info` | **2** | `app_reputation_event_info` | 4 |
| `app_ic_info` | 1 | `app_finance_indicator_info` | 12（见 §7.2） |
| `app_ic_shareholder_info` | 4 | `app_shareholder_info` | 6 |

---

## 5. 核验方法

```bash
# 用核验脚本逐张确认（39 条独立 SELECT，可整文件执行）
sql/ETL造数_合并/00_核验_源表行数.sql
```

判定标准：**每张表 n > 0**（唯一例外 `gfzx_finance_index_item` ⇒ 预留表，允许 0）。

---

## 6. 常见报错与处理

| 报错信息 | 根因 | 状态 |
|---|---|---|
| `syntax error at or near "Processing"` | `Processing logic (params filled, ready to run)` 那行**不是注释格式**（缺 `--`），被拼进了 SQL | ✅ 已修（34 处加 `--` 前缀） |
| `syntax error at or near ""` | 文件内**嵌入了 BOM（U+FEFF）** | ✅ 已修（清除 7 处） |
| `duplicate key ... "xd_corp_check_warning_task_pkey"` | 第 3 行与第 1 行同 serialNo 且 id 都是 1（前者是 `confirmTime` 非零填充的边界用例） | ✅ 已修（**id 1→3**，保留用例） |
| `column "notepayablechangefromyearstart" does not exist` | 列名拼写错，库里实际是 **`notespayable…`**（notes+payable） | ✅ 已修（4 处：列清单 2 + SELECT 别名 2） |
| `column c.isstient does not exist` | `app_customer_info` 加工段别名写错（应为 `i.`） | ✅ 已修（`c.` → `i.` 共 2 处） |
| `app_loan_receipt_info` / `app_entrust_pay_info` 产出 **0 行**、`app_capital_flow_info.loanStatus` 全 NULL | `xd_credit_loan.mainId` **硬编码 1**，而 `xd_credit_info.id` 是自增（重跑后已推进到 3）⇒ JOIN 失败 | ✅ 已修（12 行 `mainId` 改为**动态引用当前主档**） |
| `column "xxx" of relation "app_xxx" does not exist` | 目标 app 表**本地缺列**（表结构未同步） | ⚠️ 需补 DDL（与脚本无关） |

---

## 7. 已知偏差（**不是缺陷**，勿误修）

### 7.1 `app_check_object_info` = 78 行 vs 脚本注释目标 65 行
**根因**：源表里多了一个**真实业务合同**。

| contractNo | 202603（目标样本） | 202609（本次） |
|---|---|---|
| GDZC-2026-001 | 12 | 12 |
| GDZC-2026-002 | 12 | 12 |
| FDK-2026-003 | 13 | 13 |
| **FDK-2026-004** | **—** | **13** ← 多出来的 |
| YYWY-2026-004 | 14 | 14 |
| CFT-2026-005 | 14 | 14 |
| **合计** | **65**（5 合同） | **78**（6 合同） |

- `78 = 6 × 13`、`65 = 5 × 13`（每合同转置 13 个指标）
- 去重后仍为 78 ⇒ **不是重复插入**
- `FDK-2026-004` 是源表 `xd_corp_check_fixed_loan` 里的**真实数据**，公司库样本当时没有这笔 ⇒ **加工行为正确**
- 若必须产出 65 行，只能从源表删该合同（**不建议**，那是删真实数据）

### 7.2 `app_finance_indicator_info` = 12 行 vs 目标 11 行
脚本自带 `ISSUE-10` 已记录「多出 1 行」，属**已知待查项**（财务指标三档过滤口径），与本轮修复无关。

### 7.3 `app_capital_flow_info` 的 `loanStatus` 与原始目标差 2 个值
按裁决 **A 方案（以借据主档为准）**：

| loanSerialNo | 原目标 | **实际** |
|---|---|---|
| LOAN-202603-001 | 未结清 | **正常结清** |
| LOAN-202603-002 | 正常结清 | **提前结清** |
| LOAN-202603-003 | 逾期结清 | 逾期结清 ✅ |

原因：同一借据号的 `loanStatus` 在两处诉求矛盾，统一到借据主档（`aflCreditLoanQry` 是借据状态的唯一来源）。

---

## 8. 红线与注意事项

1. **只维护 `ETL造数_合并/` 这套**（原 `ETL造数/` 的 33 个脚本不再同步）
   —— 但注意：原 33 个脚本里同样存在 §6 表中的 5 类问题，若有人误用会踩坑
2. **不要单独重跑 04**：必须先跑 01、02
3. **不要用整体事务模式执行**（见 §1）
4. **加工段仍是快照副本**：文件里 §2 的加工 SQL 抄自 `xd_*.sql`（**本体不在本仓库**）；
   本体变更后需手动同步，否则两处脱钩
5. 数据保留在库里即可，核验完无需清理；若要清，按 `reportNo='RPT-202609-001'` + 源表清（**不要整表清**）
