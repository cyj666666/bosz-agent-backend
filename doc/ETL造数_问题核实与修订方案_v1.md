# ETL造数 · 问题核实与修订方案 v1

> 日期：2026-09-22　依据：34 个加工段逐字精读 + 本地库（`127.0.0.1:5432/bosz?currentSchema=as_agent`）**只读**实测
> 重要：**本文件只出方案，未改动任何脚本**。

## 0. 处置总览

| # | 我提的问题 | 曹哥回复 | 我的核实结果 | 处置 |
|---|---|---|---|---|
| 1 | `"CONDITION"` 双引号 | 实测不需要加 | 🔴 **实测相反**：本地库上不加引号、小写引号**都报错**，只有 `"CONDITION"` 通过 | **建议保留引号**（详见 §1） |
| 2 | `snapshot_type` 支路缺失 | 该字段**已废弃**，保留但无需关注 | — | ✅ **撤销该条**，从缺陷清单移除 |
| 3 | `settle_asset` 判 `\N` 写法失效 | 你看下怎么优化 | 已确认失效（`'\N'`=2 字符 vs `'\\N'`=3 字符） | **方案见 §3**，建议与 #5 合并为一套写法 |
| 4 | `isGroup` 的 `ELSE '否'` 不可达 | 分析上下游代码后调整 | 上下游已查清：**Java 侧零消费**，仅 SQL + 溯源白名单 | **方案见 §4** |
| 5 | 7 处"数字守卫"承诺未实现 | 你看下怎么优化 | 已拿到 7 处目标列的**实测类型** | **统一写法见 §5** |
| 6 | `gs_tax_sales` / `settle_counterparty` / `check_object` 三处 | 你看下怎么优化 | 已拿到源列长度实测值 | **逐条方案见 §6** |

## 1. `"CONDITION"` 双引号 —— 已定论：**三张表列名不同，两边结论各自成立**（2026-09-22 补测）

**环境实测**：`sql_compatibility = B`（MySQL 兼容模式）、openGauss 5.0.0、`standard_conforming_strings = on`。

**三条列 × 三种写法，逐条实测**：

| 表.列 | 库中**实际列名** | 不加引号 | 加引号 | 结论 |
|---|---|---|---|---|
| `app_credit_approval_manage_req_info.CONDITION` | **`CONDITION`（大写）** | ❌ `ERROR: column "condition" does not exist`（位置 82） | ✅ 通过 | **引号必须保留**（不加引号会被折叠成小写 ⇒ 匹配不上大写列名） |
| `app_opinion_info.group` | `group`（小写，**保留字**） | ❌ `ERROR: syntax error at or near "group"`（位置 60） | ✅ 通过 | **引号必须保留**（保留字，不加直接语法错） |
| `app_single_check_task_info.condition` | `condition`（小写） | ✅ 通过 | ✅ 通过 | 引号**可留可去**（冗余，但留着无害） |

**⇒ 结论**：曹哥"不需要加引号"在**小写非保留字列**（`condition`）上**成立**；我说的"必须加引号"在**大写列名**（`CONDITION`）和**保留字列**（`group`）上**成立**。分歧的根因是**这三列的大小写/保留字属性不同**，不是环境差异。

**建议**：
- `"CONDITION"`、`"group"` —— **保留引号**（这两处删了必炸，且与库的兼容模式无关）。
- `"condition"` —— 若想统一"不加引号"的风格，**只有这一处可以去**（留也无害）。


**实测（本地 openGauss，三条语句）**：

```sql
-- ① 不加引号
SELECT count(*) FROM app_credit_approval_manage_req_info WHERE condition IS NULL;
--   → ERROR: column "condition" does not exist   位置：79
-- ② 小写引号
SELECT count(*) FROM app_credit_approval_manage_req_info WHERE "condition" IS NULL;
--   → ERROR: column "condition" does not exist   位置：83
-- ③ 大写引号（现脚本的写法）
SELECT count(*) FROM app_credit_approval_manage_req_info WHERE "CONDITION" IS NULL;
--   → 通过
```

**库中真实列名**（`information_schema.columns`）：

| 表 | 列名 | 脚本写法 | 本地库结论 |
|---|---|---|---|
| `app_credit_approval_manage_req_info` | **`CONDITION`（大写）** | `"CONDITION"` | ✅ 必须加引号 |
| `app_single_check_task_info` | `condition`（小写） | `"condition"` | ✅ 可行（不加引号也行） |
| `app_opinion_info` | `group`（小写） | `"group"` | ✅ 必须加引号（保留字） |

**注**：本地库 `sql_compatibility=B`（MySQL 兼容模式）**也照样**把未加引号的标识符折叠为小写 ⇒ 关键变量是**列名本身的大小写/是否保留字**，与兼容模式无关（我原先推测"外网 PG 模式才敏感"已被这次实测推翻）。

## 2. `snapshot_type` —— 撤销

已确认该字段废弃 ⇒ 从《加工段精读台账》缺陷清单中移除；`app_ic_shareholder_info` 只产"变更"一类快照为**预期行为**。

## 3. `settle_asset` 的 `\N` 空值判断 —— 建议"改成数字白名单"，而不是修字面量

**现状**（13 处同型 CASE）：

```sql
CAST(CASE WHEN t.v_fzn IS NULL OR t.v_fzn IN ('', '\\N') THEN NULL ELSE t.v_fzn END AS DECIMAL(18,2))
```

**问题**：`standard_conforming_strings=on`（实测）下 `'\\N'` = 3 个字符（`\` `\` `N`），而数据里是 `\N` = 2 个字符 ⇒ 判空失效 ⇒ 走到 `CAST('\N')` **报错**。

**方案 A（最小改动，改字面量）**：把 `'\\N'` 全部改成 `'\N'`。
- ✅ 改动小、语义直白
- ⚠️ 依赖 `standard_conforming_strings` 的设置（换库/换客户端可能又反）；且源侧若出现 `\N` 之外的空标记（如 `NULL`、`-`）仍会漏

**方案 B（推荐：数字白名单，一次通杀）**：不再枚举"什么算空"，只认"什么算数字"：

```sql
CAST(CASE WHEN REGEXP_LIKE(BTRIM(t.v_fzn), '^-?[0-9]+([.][0-9]+)?$')
          THEN BTRIM(t.v_fzn) END AS DECIMAL(18,2)) AS frozenAmount
```

- ✅ `\N`、空串、`--`、中文、`1,200.00` 一律 → NULL，**彻底不用管 `\N` 是几个字符**
- ✅ 与 §5 的"数字守卫"是**同一套写法**，7+1=8 处可以一次性统一
- ✅ 只用 `REGEXP_LIKE`（openGauss / 行内 GaussDB / MySQL 8 三方通用，符合项目红线）
- ⚠️ **副作用**：原本能跑过去的脏值会变成 NULL（静默丢数）⇒ 建议**同时加一条自检**统计被置 NULL 的行数（见 §7）

**方案 C（改数据侧）**：让上游把 `\N` 落成真正的 NULL。最干净但依赖上游配合，不作为本轮手段。

## 4. `isGroup` 的 `ELSE '否'` 不可达 —— 上下游已查清，改 SQL 即可

**上下游链路**：

```
上游 xd_corp_customer_info.groupClientNo VARCHAR(64) / groupClientName VARCHAR(255)
   ↓ 加工（现存 CASE：空 → NULL，非空 → '是'；'否' 分支不可达）
app_credit_use_info.isGroup VARCHAR(32)   ← DDL 注释：「是否集团客户（码值：是/否）」
   ↓ 下游
resources/report/trace-table-fields.json 两处（章节表格溯源白名单，label「是否集团客户（码值：是/否）」）
   ↓ 前端渲染报告表格
【Java 侧：grep isGroup 仅命中 json + sql，零业务消费代码 ⇒ 不需要改 Java】
```

**结论**：DDL 注释与溯源 label **都写的是"码值：是/否"两值** ⇒ 设计意图是"空 = 否"，现实现输出 NULL 属**实现偏离设计**。

**改法（推荐）**：

```sql
CASE WHEN cc.groupClientNo IS NULL OR BTRIM(cc.groupClientNo) = '' THEN '否' ELSE '是' END AS isGroup
```

（等价简写：`CASE WHEN BTRIM(COALESCE(cc.groupClientNo,'')) = '' THEN '否' ELSE '是' END`）

**附带确认（2026-09-22）**：`groupName` "空则回退存 `groupClientNo`" —— **曹哥确认保持该逻辑，不改**。

## 5. 7 处"数字守卫"承诺未实现 —— 统一写法（附实测类型）

**统一写法**（按目标列类型分两种）：

```sql
-- 目标列 NUMERIC(18,2) / NUMERIC(12,4)
CAST(CASE WHEN REGEXP_LIKE(BTRIM(源列), '^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(源列) END AS DECIMAL(18,2))

-- 目标列 INTEGER（正则必须收紧为纯整数，否则 '3.5' 会隐式取整/报错）
CAST(CASE WHEN REGEXP_LIKE(BTRIM(源列), '^-?[0-9]+$') THEN BTRIM(源列) END AS INTEGER)
```

**逐处对照（目标列类型为实测值）**：

| 文件 | 列 | 目标列**实测类型** | 建议 |
|---|---|---|---|
| `06 guofa` | `gfRevenue` / `lastYearRevenue` / `gfReceivable` / `gfPayable` / `gfInventory` | NUMERIC(18,2) | 套 NUMERIC 写法（4 组 LEFT JOIN 的取值列各加守卫） |
| `23 loan_receipt` | `loanChangeRptCounts` | **INTEGER** | 纯整数正则 |
| | `businessRate` | NUMERIC(12,4) | NUMERIC 写法 |
| `25 single_check_task` | `balance` | NUMERIC(18,2) | NUMERIC 写法（含注释承诺的 `NULLIF` 防空串） |
| `31 shareholder_info` | `stock_num` | **INTEGER** | 纯整数正则 |
| | `amount` | NUMERIC(18,2) | NUMERIC 写法（`percent` 已实现，保持） |
| `32 collateral_info` | `evaluateValue` / `rightSum` | NUMERIC(18,2) | NUMERIC 写法（另 `maxCreditorAmt` 在他项表，同样处理） |
| `20 early_warning_opinion` | `seqNo` | **INTEGER** | 纯整数正则 |
| `30 ic_shareholder` | `icStockNum` | **INTEGER** | 纯整数正则 |
| | `icAmount` | NUMERIC(18,2) | NUMERIC 写法（`percentBefore/After` 已实现，保持） |
| `01 finance_indicator` | `value1`/`value2` → 全部指标列 | NUMERIC | 在 `x` 子查询的 `v1n/v2n` 处加统一守卫（**一处改，全表受益**）：<br>`CAST(CASE WHEN REGEXP_LIKE(BTRIM(s.value2),'^-?[0-9]+([.][0-9]+)?$') THEN BTRIM(s.value2) END AS DECIMAL)` |

**为什么之前一直没暴露**：实测 `xd_financial_subject` 270 行 value1/value2 **100% 是合法数字** —— 造数数据太干净，把 8 处风险全盖住了。
**⇒ 建议顺手加一条"脏值自检"**（见 §7），别只修不验。

## 6. 另三处

### 6.1 `gs_tax_sales`：`WHERE r.amt > 0` 吞掉真实 0 销售额月

**现状**：`WHERE r.amt > 0`（注释说的是"只输出有值月"）。
**改法**：增一个"有值月"标记，用标记过滤而不是用 `amt > 0`：

```sql
-- 在 e 子查询里加
CASE WHEN elval IS NULL OR elval = '' THEN 0 ELSE 1 END AS hasVal
-- 最外层过滤改为
WHERE r.hasVal = 1
```

⇒ 真实 `0` 销售额的月份能出行，缺失月不出行，YTD 里两者仍都按 0 累计（行为不变）。

### 6.2 `gs_tax_sales` / `settle_account`：CROSS JOIN 序号上限可能不够

**实测源列长度**：`mon_sale_amt VARCHAR(800)`、`acct_zhxx VARCHAR(10000)`。

| 文件 | 现上限 | 理论可容纳 | 结论 |
|---|---|---|---|
| `05 gs_tax_sales` | 1..**60** | 800 ÷ 最短元素 `202601:1\|`（11 字符）≈ **72** | ⚠️ **上限不足**，建议提到 **1..80** |
| `09 settle_account` | 1..**50** | 10000 ÷ 每账户约 55 字符 ≈ **180** | ⚠️ 明显偏小；业务上账户数通常远小于此，但**静默截断无告警**，建议至少提到 100 或按业务上限定 |
| `07 payroll` | 1..**12** | `instd_sal_moly` 就 12 个月键 | ✅ 刚好（若将来跨年 24 期需同步调大） |
| `11 settle_counterparty` | 1..**20** | 源是"前十大"（每方向 ≤10） | ✅ 足够，是兜底 |

### 6.3 `settle_counterparty`：注释 TOP10 vs 代码 `<= 20`

代码 `WHERE r.dr <= 20` 是**兜底**（序号表拆到 20），业务含义是 TOP10（源串为"前十大"）。
**建议**：**代码保留 20**（多兜一点更安全），**把注释改准**：
> `rankNo <- 排名 TOP1-10（源为「前十大」数组；DENSE_RANK 兜底上限 20）`

### 6.4 `check_object` 驱动表的 `indexName` 疑似笔误

`superviseCheckCondition`（固定资产、房地产开发贷款各 1 处）的 `indexName` 写成 **「项目资本金情况本次检查情况」** —— 与 `capitalCheckCondition` **完全重名**，而它的 `redTextRequire` 描述的是"销售资金合计金额、是否都进入监管账户、监管账户余额…"。按语义应为「**资金监管情况本次检查情况**」之类。
**⇒ 需对照《SZ银行DH智能体》附录3 原文定稿**（我手上没有附录3，无法单方面改）。定位：`源头数据_app_check_object_info.sql` 驱动表 `u` 内 2 处。

## 7. 建议配套：加一条"脏值自检"（防止修完静默丢数）

修完 §3/§5 后，脏值会从"报错"变成"NULL"。建议加一条只读自检，跑完加工后统计被置 NULL 的行数：

```sql
-- 例：财务指标科目值有多少条会因守卫被置 NULL
SELECT count(*) AS total,
       sum(CASE WHEN value1 IS NOT NULL AND BTRIM(value1) <> ''
                 AND NOT REGEXP_LIKE(BTRIM(value1), '^-?[0-9]+([.][0-9]+)?$') THEN 1 ELSE 0 END) AS would_be_null
  FROM xd_financial_subject;
```

当前实测值：`total=270 / would_be_null=0` ⇒ **现在改不会丢任何数据**，正是改的好时机。

## 8. 优先级建议

| 优先级 | 项 | 理由 |
|---|---|---|
| P0 | §4 `isGroup`（一行 CASE） | 语义与 DDL 注释/前端 label 不符，直接影响报告展示 |
| P0 | §3 `\N`（13 处，建议套 §5 写法） | 遇到真实 `\N` 直接**报错中断**整个结算资产加工 |
| P1 | §5 七处守卫（可一次统一） | 生产脏值会中断加工；当前数据干净，改造成本最低 |
| P1 | §6.1 `amt > 0` / §6.2 序号上限 | 静默丢数（比报错更隐蔽） |
| P2 | §6.3 注释订正 / §1 引号复核 | 文档一致性 / 需曹哥确认环境 |
| 待定 | §6.4 `indexName` 笔误 | 需附录3 原文 |

---

## 9. 源表 owner 收敛 —— 同一张源表被多处造数（2026-09-22 追加）

> 背景：33→5 合并时暴露出的新一类问题 —— 有些源表**被多个分组的脚本各自造一遍**。组内可靠"合并 + 只留一处"解决，**跨组的必须做 owner 收敛 + 清理收窄**。
> 本节结论全部来自**只读**实测（本地库 `information_schema` / `pg_indexes` / 目标 app 表现值）+ 造数段与加工段逐字比对。

### 9.1 `xd_credit_info` / `xd_credit_loan` —— 客户组与贷后组各造一套

**造数方：`xd_credit_info` 有 4 处、`xd_credit_loan` 有 3 处（不是 2 处）**

| 源表 | 造数文件 | 分组 | 行数 | 列 | 关键值 | id |
|---|---|---|---|---|---|---|
| `xd_credit_info` | `app_credit_use_info.sql` | 02 客户 | 1 | **14 列全字段** | creditSum=800.00 / creditDate='202509' / groupAmount… | 无（自增） |
| 〃 | `app_entrust_pay_info.sql` | 02 客户 | 1 | 占位 5 列 | — | **显式 1** |
| 〃 | `app_loan_receipt_info.sql` | 02 客户 | 1 | 占位 5 列 | — | **显式 1** |
| 〃 | `app_capital_flow_info.sql` | 04 贷后 | 1 | 占位 5 列 | — | **显式 1** |
| `xd_credit_loan` | `app_loan_receipt_info.sql` | 02 客户 | **12** | **28 列最全** | 001=正常结清 / 002=提前结清 / 003=逾期结清 | **显式 1-12** |
| 〃 | `app_entrust_pay_info.sql` | 02 客户 | 1 | 7 列（**无 loanStatus**） | 001，loanStatus=NULL | **显式 1** |
| 〃 | `app_capital_flow_info.sql` | 04 贷后 | 3 | 7 列 | 001=**未结清** / 002=**正常结清** / 003=逾期结清 | 无（自增） |

**三层冲突**

1. **主键**：两表实测**只有 `id` 唯一约束**（`xd_credit_info_pkey` / `xd_credit_loan_pkey`，无 loanSerialNo 唯一键）。4 处都硬编码 `id=1` ⇒ **谁后跑谁撞 duplicate key**。
2. **列覆盖不全**：占位版只有 5/7 列 ⇒ 一旦占位版"赢"，`app_loan_receipt_info` 需要的 productName/businessSum/balance/overdueBalance… 全 NULL ⇒ **该表报废**。
3. **🔴 值矛盾（最要命）**：同一借据号的 `loanStatus` 两处诉求不同 ——

   | 借据号 | `loan_receipt` 要求 | `capital_flow` 要求 | 库里目标 app 表现值 |
   |---|---|---|---|
   | LOAN-202603-001 | 正常结清 | **未结清** | receipt=正常结清 / flow=未结清（**两边就这么矛盾地并存**） |
   | LOAN-202603-002 | 提前结清 | **正常结清** | receipt=提前结清 / flow=正常结清 |
   | LOAN-202603-003 | 逾期结清 | 逾期结清 | 一致 ✓ |

**库里现状实锤（只读）**

- `xd_credit_info` 现存 **1 行**：`creditSum=NULL`、`creditDate=NULL` ⇒ **占位版赢**（全字段版被清掉）
- `xd_credit_loan` 现存 **1 行**：`LOAN-202603-001`、`loanStatus=NULL`、`inputtime=09:00` ⇒ **entrust_pay 版赢**，`loan_receipt` 的 12 行根本不在库里
- ⇒ 按现在的源表状态**跑不出** `app_credit_use_info`（缺 creditSum）和 `app_loan_receipt_info`（缺 12 行）
- ⇒ 库里那两张 app 表的值**是 DML 直写的**，把这个坑盖住了

**✅ 收敛方案（"只造一次"）**

- `xd_credit_info` owner = **`app_credit_use_info`（14 列全字段版）**；其余 3 处**删掉 INSERT**
- `xd_credit_loan` owner = **`app_loan_receipt_info`（12 行 28 列）**；其余 2 处**删掉 INSERT**
- 三处加工**不受影响**（已逐条核对）：
  - `app_entrust_pay_info` 只需 `loan.id` 去 JOIN `xd_credit_payment.mainId=1` ⇒ 12 行版里 001 就是 **id=1** ✓
  - `app_capital_flow_info` 只需 `loanStatus`（按 loanSerialNo 撞）✓

**⚠️ 有一个"无法两全"的点，必须拍板**

只造一次 ⇒ `loanStatus` 只能有一份真值 ⇒ **必然有一张 app 表对不上现有目标值**：

| 选项 | 做法 | 代价 |
|---|---|---|
| **A（推荐）** | 以**借据主档为准**（`loan_receipt` 12 行）⇒ flow 的 001/002 变 `正常结清/提前结清` | `app_capital_flow_info` 与库里样本差 **2 个值** |
| B | 以 **capital_flow 目标为准** ⇒ 改 receipt 的 001=未结清、002=正常结清 | `app_loan_receipt_info` 与库里样本差 **2 个值** |

**推荐 A 的依据**：`loanStatus` 是**借据自身属性**，唯一来源是 `aflCreditLoanQry`（落 `xd_credit_loan`）；`capital_flow` 的加工注释自己也写着「loanStatus ← loanSerialNo 撞「当前借据」取 loanStatus」⇒ 它本来就是**借用**借据表的值，不该反过来定义。
换言之：**库里那份样本数据本身就不自洽**，选 A 是让数据回到业务自洽，代价是承认样本有 2 处笔误。

### 9.2 `ws_gs_info` —— 三个组各造一遍，DELETE 条件**逐字相同**（更阴险）

| 造数文件 | 分组 | id | customerId | name | 工商照面列（operName/registCapi/actualCapi/currency_unit/endDate） | entId | inputtime |
|---|---|---|---|---|---|---|---|
| `app_ic_info.sql` | **01 外数** | 无（自增） | CUST-001 | NULL | **有** | NULL | 2026-09-15 10:00 |
| `app_entrust_pay_info.sql` ×2 | **02 客户** | **显式 1、2** | **NULL** | 有（两个账户名） | 无 | NULL | 09-01 10:00 / 08-05 09:00 |
| `app_graph_hit_info.sql` | **04 贷后** | 无（自增） | CUST-001 | NULL | 无 | ENT-CUST-001 | 2026-09-11 12:00 |

**三处 DELETE 逐字相同**：`WHERE customerId = 'CUST-001' AND reportNo = 'RPT-202609-001'`

**⇒ 两个后果（都是硬伤）**

1. **01 与 04 必然互相清场**（两者的行 `customerId='CUST-001'`，落在同一删除范围）：
   - 01 → 04：01 的照面行被删 ⇒ 只剩 04 那行（**operName/registCapi/actualCapi/currency_unit/endDate 全 NULL**）⇒ `app_ic_info` 的 `icLegalPerson` / `icRegisterCapital` / `icPaidInCapital` / `currencyUnit` / `cancellationDate` **全空 ⇒ 该表报废**
   - 04 → 01：04 的 entId 行被删 ⇒ `app_graph_hit_info` 的 `INNER JOIN ws_gs_info.entId = xd_graph_hit.eid` **撞不到 ⇒ 0 行 ⇒ 该表报废**
2. **🔴 `app_entrust_pay_info` 的 2 行 `customerId=NULL`，落在删除范围之外** ⇒ 3 条 DELETE 都删不掉它们：
   - **重跑必撞主键**（显式 `id=1/2`，删不掉又重插 ⇒ duplicate key）
   - 反过来，也正因为 `customerId=NULL`，这 2 行**不会**被 01/04 的加工取到（它们的加工都带 `customerId='CUST-001'` 过滤）⇒ 目前**没有污染**，纯属侥幸

**✅ 收敛方案（= 上一轮 ①，你说"可以"的那版，按实测微调）**

- **借款人行（1 行）**：由 **01 外数** 建（带全部工商照面列 + `customerId='CUST-001'`）；**04 贷后改成 `UPDATE` 补 `entId`**，不再 INSERT
- **收款人行（2 行）**：**02 客户**独立保留（`customerId=NULL`），与借款人行互不干扰
- **三处清理段按业务键收窄**（关键，否则收敛白做）：
  - 01：`... AND customerId='CUST-001' AND name IS NULL`（只清借款人行）
  - 02：`... AND reportNo=... AND customerId IS NULL AND name IS NOT NULL`（只清自己那 2 行 ⇒ **顺带修掉"重跑撞主键"**）
  - 04：**删掉自己的 DELETE**（不造数了，也就不该清）
- **执行顺序**：`01 → 02 → 04`（04 依赖 01 的借款人行）

### 9.3 顺带：合并文件 §0「同一张表只清一次」**没真正做到**（我的疏漏，需修）

实测统计（`DELETE` 归一化后去重）：

| 合并文件 | DELETE 总数 | 唯一 | 重复组数 |
|---|---|---|---|
| 01 外数 | 15 | 15 | 0 |
| **02 客户** | **81** | **73** | **8** |
| **03 押品** | **24** | **12** | **9** |
| 04 贷后 | 41 | 41 | 0 |
| 05 财务 | 5 | 5 | 0 |

- 02 的 8 组：`app_customer_info`、`app_xd_shareholder_info`、`xd_corp_customer_control`、`xd_corp_customer_shareholder`、`xd_credit_info`、`xd_credit_loan` 各 ×2
- 03 的 9 组：押品三兄弟各跑一遍完整「押品三表」⇒ 每条 DELETE ×3
- **重复 DELETE 本身幂等无害**，但与上一轮报告里"同一张表只清一次"的说法不符 ⇒ **需修**（去重键要吃掉空白差异）

**跨组共享表清理冲突（靠 owner 收敛解决）**：`ws_gs_info`(01,02,04)、`xd_credit_info`(02,04)、`xd_credit_loan`(02,04)

### 9.4 拍板与落地（2026-09-22 已执行）

| # | 事项 | 裁决 | 落地 |
|---|---|---|---|
| 1 | `loanStatus` 真值 | **A：以借据主档为准** | 02 组的 12 行版为唯一真值；04 组不再造借据 |
| 2 | 04 组的 credit 造数 | **(a) 直接删 + 注明"依赖 02 先跑"** | 已删 2 段造数 + 3 条清理权；文件头注明顺序 |
| 3 | §0 去重 | **修** | 02 §0 41→35、03 §0 12→6 |

**本轮改动清单（只改 `ETL造数_合并/`，原 33 个脚本未动）**

| 文件 | 改动 |
|---|---|
| `01_外数加工_合并.sql` | §0 的 `ws_gs_info` DELETE **收窄为 `AND name IS NULL`**（只清借款人照面行）；文件头新增「执行顺序 + owner 约定」 |
| `02_客户企业概况加工_合并.sql` | §0 去重 **41→35 条**（去掉 `xd_credit_info`/`xd_credit_loan`/`app_customer_info`/`app_xd_shareholder_info`/`xd_corp_customer_control`/`xd_corp_customer_shareholder` 各 1 条重复）；`ws_gs_info` DELETE **收窄为 `customerId IS NULL AND name IS NOT NULL`**（原条件删不到自己造的行 ⇒ 重跑撞主键）；文件头补 owner 说明；3 处 `[已合并]` 标记补 owner 归属 |
| `03_押品加工_合并.sql` | §0 去重 **12→6 条**（押品三兄弟各带一套完整三表 DELETE） |
| `04_贷后检查加工_合并.sql` | §0 删除 3 条（`xd_credit_info`/`xd_credit_loan`/`ws_gs_info` 清理权交回 owner）；§1 删除 credit 主档占位 + 3 行借据造数（改为说明注释）；`ws_gs_info` INSERT → **`UPDATE ... SET entId`**；`loanStatus` 注释更新为 A 方案实际值 + 差异提示；文件头补依赖说明 |
| `05_财务指标加工_合并.sql` | 无（3 条 DELETE 无重复） |

**只读验证（本地库，未执行任何 DML）**

| 探测 | 结果 |
|---|---|
| `ws_gs_info` 库中总行数 | **2** |
| 01 收窄条件命中（借款人行） | 0 ⇒ 库里**没有**借款人行（01 未跑过 / 行被清过） |
| 02 收窄条件命中（收款人行） | **2** ✅ 正是那两行 `customerId=NULL` ⇒ **证实原 DELETE 删不到自己** |
| 04 UPDATE 目标行 | 0 ⇒ 需 01 先跑（符合「01→02→04」的设计） |
| `ws_gs_info.entId` 列 | 存在 ✅ |
| `xd_credit_info` / `xd_credit_loan` 现有行 | 各 1 行（仍是旧占位版；owner 生效后会由 02 重建为全字段 / 12 行） |

**剩余重复（仅 §2 加工段内，幂等无害，刻意保留以对齐加工本体）**：02 全文 75/73（2 条 = `app_customer_info` / `app_xd_shareholder_info` 的带 `OR ... IS NULL` 形式，双胞胎各带一条）；03 全文 18/12（6 条 = `app_collateral_*` 的 `OR` 形式 ×3，押品三兄弟各一套）。

**已执行（2026-09-22 · 曹哥授权本地库跑通）**：详见 `doc/ETL造数_本地执行核验报告_20260922.md` ——
243 条语句 242 通过、**39 张源表 38 张已造出数据**（唯一 0 行的是「预留不取」表）、
执行中又修掉 5 个阻塞问题（`Processing logic` 裸行 ×34、内嵌 BOM ×7、`c./i.` 别名 ×2、`warning_task` id 撞主键、**`xd_credit_loan.mainId` 硬编码 1 导致 3 个 app 表产出 0 行/NULL**）。
