# 公司库 `app_` 相关表清单（贷后报告业务表）

> ⚠️ **本文档 2026-09-15 已按用户纠正重写**。此前一版是从**本机 `127.0.0.1:5432/bosz_test`** 取的，
> 口径错误 —— 用户明确：**以公司库为准，本机那份与本任务无关**。

- **公司库**：`jdbc:opengauss://172.20.2.19:8000/bosz_test?currentSchema=bosz_test`（**只读**）
- **查询方式**：只读（`D:\dbtool\DbRun`，非 SELECT 语句直接跳过）
- **查询时间**：2026-09-15 21:5x
- **结果**：`bosz_test` schema 下共 **53 张 `app_` 开头的表**
- 行数为**精确 `count(*)`**（不是 `reltuples` 估算）

## 一、53 张表（按表名）

| # | 表名 | 注释 | 列数 | 行数 | 交付包 45 张 |
|---|---|---|---|---|---|
| 1 | app_api_financial_analysis_dd_cashflow | 现金流量表 | 90 | 0 | ❌ 排除 |
| 2 | app_api_financial_analysis_dd_debt | 资产负债表 | 159 | 0 | ❌ 排除 |
| 3 | app_api_financial_analysis_dd_profit | 利润表 | 94 | 0 | ❌ 排除 |
| 4 | app_capital_flow_info | 资金回流/用途异常表 | 15 | 7 | ✅ |
| 5 | app_check_index_info | 日常检查综合指标表 | 11 | 25 | ✅ |
| 6 | app_check_object_info | 特定贷款指标检查明细表 | 13 | 65 | ✅ |
| 7 | app_check_opinion_info | 批复后续管理要求表 | 10 | 5 | ✅ |
| 8 | app_check_record_info | 现场检查打卡记录表 | 9 | 2 | ✅ |
| 9 | app_collateral_info | 押品主档表 | 16 | 3 | ✅ |
| 10 | app_collateral_mortgage_info | 押品他项权利/限制权利表 | 14 | 1 | ✅ |
| 11 | app_collateral_restricted_right | 押品限制权利表 | 8 | 1 | ✅ |
| 12 | app_credit_approval_manage_req_info | 授信批复管理要求表 | 9 | 0 | ✅ |
| 13 | app_credit_debt_detail | 征信债务明细表（按类型一期一行） | 13 | 48 | ✅ |
| 14 | app_credit_query_info | 征信查询次数表 | 16 | 3 | ✅ |
| 15 | **app_credit_report_info** | 企业征信快照表（一期一行） | **52** | 6 | ✅ |
| 16 | app_credit_use_info | 授信用信概况表 | 17 | 1 | ✅ |
| 17 | app_customer_info | 客户工商概况表 | 19 | 1 | ✅ |
| 18 | app_early_warning_info | 预警任务台账表 | 15 | 2 | ✅ |
| 19 | app_early_warning_opinion_info | 预警意见表 | 14 | 2 | ✅ |
| 20 | app_early_warning_signal_info | 预警信号明细表 | 12 | 6 | ✅ |
| 21 | app_entrust_pay_info | 受托支付明细表 | 9 | 2 | ✅ |
| 22 | app_finance_index_info | 财务指标值表（一期一行一指标，EAV） | 16 | **210** | ✅ |
| 23 | **app_finance_indicator_info** | 财务指标预定义表（宽表纵表，57 列） | **57** | 11 | ✅ |
| 24 | app_finance_report_info | 财报主档表（一期一行） | 14 | 10 | ✅ |
| 25 | app_graph_hit_info | 企业图谱命中情况 | 13 | 1 | ✅ |
| 26 | app_gs_finance_data_info | 国税财务数据表 | 21 | 1 | ✅ |
| 27 | app_gs_tax_sales_info | 国税销售额表 | 10 | 20 | ✅ |
| 28 | app_guarantor_credit_info | 担保人征信表 | 42 | 3 | ✅ |
| 29 | app_guarantor_info | 担保人信息表 | 14 | 3 | ✅ |
| 30 | app_guofa_report_info | 国发征信信息表 | 21 | 1 | ✅ |
| 31 | app_ic_info | 工商登记信息表（客户级） | 13 | 1 | ✅ |
| 32 | app_ic_shareholder_info | 工商股东变更表（多时点快照） | 13 | 4 | ✅ |
| 33 | app_loan_plan_info | 贷款产品还本付息计划表 | 11 | 0 | ✅ |
| 34 | app_loan_receipt_info | 借据信息表 | 33 | 12 | ✅ |
| 35 | app_opinion_info | 贷后意见表 | 10 | 2 | ✅ |
| 36 | app_payroll_stat_info | 代发统计表（月粒度） | 12 | 12 | ✅ |
| 37 | app_report_info | 贷后报告主表 | 15 | 0 | ✅ |
| 38 | app_reputation_event_info | 舆情事件明细表 | 10 | 4 | ✅ |
| 39 | app_settle_account_info | 结算账户表 | 9 | 5 | ✅ |
| 40 | app_settle_asset_info | 结算资产表 | 18 | 1 | ✅ |
| 41 | app_settle_counterparty_info | 结算交易对手表 | 11 | 40 | ✅ |
| 42 | app_shareholder_info | 工商股东信息表（最新时点快照） | 13 | 6 | ✅ |
| 43 | app_single_check_task_info | 单项检查任务表 | 26 | 2 | ✅ |
| 44 | app_space_config | 应用空间管理表 | 18 | 0 | ❌ 排除 |
| 45 | app_space_inspiration_config | 应用空间灵感配置表 | 15 | 0 | ❌ 排除 |
| 46 | app_space_relate_account | 应用空间关联账户信息表 | 12 | 0 | ❌ 排除 |
| 47 | app_space_relate_agent | 应用空间关联Agent信息表 | 7 | 0 | ❌ 排除 |
| 48 | app_space_relate_knowledge | 应用空间关联知识库信息表 | 15 | 0 | ❌ 排除 |
| 49 | app_specific_loan_check_info | 特定贷款检查表 | 51 | 0 | ✅ |
| 50 | app_specific_loan_operate_check_info | 特定贷款检查表-经营收入类 | 42 | 4 | ✅ |
| 51 | app_specific_loan_project_check_info | 特定贷款检查表-项目类 | 51 | 4 | ✅ |
| 52 | app_top_five_updown_info | 前五大上下游表 | 8 | 10 | ✅ |
| 53 | app_xd_shareholder_info | 信贷系统股东表（最新时点） | 14 | 6 | ✅ |

**合计**：53 张；有数据的 48 张，**总行数 553**。

> 排除 8 张（按用户口径）：`app_space_*` 5 张（应用空间，属平台能力）+ `app_api_financial_analysis_dd_*` 3 张（财务三大报表接口原始表）。
> **53 − 8 = 45 张**进入交付包 DDL。

## 二、⚠️ 本机 `127.0.0.1:5432/bosz_test` 是**另一份**，不是公司库

用户明确：本机那份是「我自己的库」，**与本任务无关**。实测两者差异很大，不能互相替代：

| 项 | 公司库 `172.20.2.19:8000` | 本机 `127.0.0.1:5432` |
|---|---|---|
| `app_` 表数 | **53** | 44 |
| 数据 | 48 张有数据、553 行 | **全部 0 行**（纯结构） |
| `app_credit_report_info` | **52 列** | 36 列 |
| `app_finance_indicator_info` | **存在（57 列）** | 不存在 |
| `app_finance_index_info` | 16 列 | 15 列 |
| `app_guarantor_info` | 14 列 | 10 列 |
| `app_loan_receipt_info` | 33 列 | 23 列 |
| `app_tax_info` | **不存在**（改由 `app_gs_tax_sales_info` 承载） | 存在（15 列） |
| 独有表 | `app_check_object_info`、`app_credit_approval_manage_req_info`、`app_early_warning_opinion_info`、`app_finance_indicator_info`、`app_graph_hit_info`、`app_gs_finance_data_info`、`app_gs_tax_sales_info`、`app_settle_asset_info`、`app_single_check_task_info`、`app_top_five_updown_info`（10 张） | `app_tax_info` |

## 三、「执行预览」报错的闭环（已解决）

原报错：`ERROR: relation "app_credit_report_info" does not exist on gaussdb`

**根因**：预览用的数据源是本地 `boszLocal` → `jdbc:opengauss://127.0.0.1:5432/bosz?currentSchema=as_agent`，
而 `as_agent` 里**根本没有这两张表**（只有 10 张 `app_report_*` 报告详情表）。

**已修复**：把公司库的 **45 张**结构（去掉 `app_report_info`，后者 as_agent 已有更新版本）建进 `as_agent`，
并把公司库这 45 张表的**业务数据 553 行**导入本地。

**实测**：那条指标 SQL（`app_credit_report_info` INNER JOIN `app_finance_indicator_info`）在 `as_agent` 已可执行，
返回 1 行真实数据：

| 报告编号 | 客户编号 | 客户名称 | 征信查询时间 | 会计月 | 财报短期借款 | 征信短期未结清 | 短期相差 | 中长期相差 | 债务偏离度 | 对外担保净资产比 |
|---|---|---|---|---|---|---|---|---|---|---|
| RPT-202603-001 | CUST-001 | 苏州XX精密机械制造有限公司 | 2026-06-24 | 202603 | 2550.00 | 350.00 | -2200.00 | -470.00 | 63.27 | 4.76 |

## 四、本次产出的文件

| 文件 | 内容 | 用途 |
|---|---|---|
| `src/main/resources/sql/三个菜单_交付包/DDL/06_F_贷后报告业务表_45张.sql` | 45 张表 DDL，**1034 条语句**（45 CREATE + 45 表注释 + **842** 列注释 + 102 索引）<br>🆕 2026-09-16：`app_reputation_event_info` +2 列（`eventtypecode`/`eventtypeorder`），原 1032 条 | **进交付包**（现场建表） |
| `src/main/resources/sql/本地自测/贷后业务数据_本地初始化_DML.sql` | 44 张表 / 553 行 INSERT | **仅本地自测，不进交付包** |

> 本清单为**只读查询 + 本地建表/导数据**的产物；**公司库全程只读，未做任何写入**。
