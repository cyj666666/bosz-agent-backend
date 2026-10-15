# 链接溯源 · pageParams 装配设计（B 方案）v1

> 口径：2026-09-21 曹哥拍板 —— **直接走 B**（前端传 shareCode/reportNo，后端**实时**查表拼 pageParams 再调信贷）；
> 主体区分用 **`agentParams` 存元令牌**（与知识库块 `guarantorMode=LEGAL` 同风格）。
>
> ## ✅ 状态：**已实施**（2026-09-21 18:4x 首轮 / 19:1x 收口）—— 三个待确认问题已全部解答：
> ① 行内 `xd_corp_check_info` **DDL 已更新**（`baSerialNo` / `electroApproveSerialNo` / `approveApplyType` 都在）
> ② `subjecttype` = 中文 `借款人` / `担保人`
> ③ 担保人定位 = 方案 a（前端带 `guarantorName`）
>
> 代码：行内后端 6 处 + 前端 4 处；前端 `vue-tsc` 0 错误 + `vite build` 16.73s。
> 已补齐：Sheet3 三个 `1050` 块 **H 列主体令牌**已填并落库 → 重跑生成器 + 增量 DML（见 §8）。
>
> ### 🆕 19:1x 收口（两处通电）
> 1. **`agentParams` 通电（零 DDL）**：实例表 `app_report_content_instance` **没有** `agentParams` 列
>    ⇒ 详情接口原来不返回它 ⇒ 前端多担保人按钮**写了但走不到**。
>    改为后端 `ReportServiceImpl#detail` 从**模板表** `app_report_content_block` 按 blockCode
>    **内存合并**补上（复用已加载的 `loadEnabledBlocks()`，**零额外查询**、零 DDL）：
>    `ReportBlockVO` 加字段 + `toBlockVO` 加参 + `detail()` 建 `agentParamsMap`。**外网 + 行内各一套**。
> 2. 🔴 **`userId` 口径修正**：取 **`report.user_no`（报告发起人）**，**不是当前登录态账号**。
>    `ReportDetailVO` 新增 `userNo` 字段（`detail.setUserNo(reportInfo.getUserNo())`），
>    前端 `openTraceLink` 改读 `detail.userNo`，取不到**直接报错、不退回登录态**。

---

## 1. 结论：链路（B 方案）

```
前端点击「🔗 溯源」按钮
   └─ POST /api/report/share-url   body = { userId(=report.user_no), shareCode, reportNo, blockCode, guarantorName? }
        └─ 后端 LinkTraceParamBuilder（🆕）
             ① 按 blockCode 读模板块的 agentParams（主体令牌）
             ② 按 shareCode 选「取值策略」，从 report / 业务表实时取数
             ③ 拼出 pageParams（serialNo=xxx&customerId=xxx&…）
        └─ CreditShareUrlService.getPageShareUrl(userId, shareCode, pageParams)
             └─ 信贷 getPageShareUrlN（appCode 固定 AIMP-PLMA）→ 返回 url
   └─ 前端 window.open(url)
```

🔴 **链接实时取、参数实时拼，全程不落库** ✅ 符合「不能前置加工、有时效」的红线。

---

## 2. 接口契约（对前端）

| 项 | 值 |
|---|---|
| 路径 | `POST /api/report/share-url`（不变） |
| **body** | **`{ userId, shareCode, reportNo, blockCode?, guarantorName? }`** ← 由 3 字段扩到 5 字段（后两个可选） |
| 返回 | `{ url, relativeUrl }`（不变） |

- `shareCode` 仍取自块的 `agentCode`（前端已有）
- 🔴 **`userId` = 报告发起人 `report.user_no`**（详情接口新增返回 `userNo`），**不是登录态**；
  前端取不到就报错、**不退回登录态**（否则链接归属会挂错人）
- `reportNo` / `blockCode` 前端都已有（`currentReportNo` + 按钮的 `data-trace-link`）
- `guarantorName` 仅 `1050` 征信的担保人块用（按担保人拆多按钮时回传）
- ⛔ `pageParams` **不再由前端传** —— 改由后端装配（前端不用懂表结构）

---

## 3. 11 个 shareCode 的取值逻辑（逐条，实测表结构后写定）

通用取值来源：`report` 表（`report_no` / `customer_id` / `customer_name` / `check_task_no`，全部 snake_case）。

| shareCode | 名称 | pageParams（键=值） | 取值 SQL 要点 |
|---|---|---|---|
| **1010** | 批复链接（电子批复） | `serialNo` / `customerId` / `applySerialNo` / `approveSerialNo` / `electroApproveSerialNo` / `applyType` | ⚠️ **见表 §6 待确认 1**；`customerId` ← `report.customer_id`；`applyType` 固定 |
| **1020** | 打卡 | `serialNo`=check_task_no / `customerId` / `customerName` / `isOnlyRead`=false | `report` |
| **1030** | 批复落实 | `serialNo`=check_task_no / `customerId` / `customerName` / `isOnlyRead`=false / `modifyPermission`=false | `report` |
| **1040** | 财务分析表 | `menuType`=1 / `customerIds`=customer_id / `customerNames`=customer_name | `report` |
| **1050** | 征信 | `creditRecordNo` / `fileType`=2 / `customerId` | **按主体令牌三分支，见 §4** |
| **1060** | 资金用途及回流异常排查台账 | `customerId` | `report` |
| **1080** | 预警台账 | `customerId` | `report` |
| **1090** | 地方征信 | `customerType`=01 / `customerId` | `report` |
| **1120** | 对公日常贷后检查 | `customerId` / `applyType`=AFPublicDailyCheckApply | `report` |
| **1130** | 资金用途及回流异常延期整改台账 | `customerId` | `report` |
| **1150** | 预警信号台账 | `customerId` | `report` |

拼接格式：`k1=v1&k2=v2`（值需 URL 编码）；**常量项直接写死**，动态项查库。

---

## 4. `1050` 征信：主体令牌 → 三分支（本设计的核心）

三个 `1050` 块的 `shareCode` 完全相同 ⇒ **必须靠块的 `agentParams` 区分主体**：

| 块 | 位置 | `agentParams`（Sheet3 **H 列**填） | `creditRecordNo` 取值 |
|---|---|---|---|
| `V2_BLK_CREDIT_L12` | 六、征信情况和潜在风险 | `subjectType=借款人`（或留空=默认借款人） | `app_credit_report_info.zxreportno`（`reportno` + `subjecttype='借款人'`） |
| `V2_BLK_GUARANTEE_L19` | 十二（二）**企业**担保人段 | `subjectType=担保人,guarantorType=法人` | `app_credit_report_info.zxreportno`（`reportno` + `subjecttype='担保人'` + `guarantorname`） |
| `V2_BLK_GUARANTEE_L34` | 十二（二）**个人**担保人段 | `subjectType=担保人,guarantorType=自然人` | `app_guarantor_credit_info.zxreportno`（`reportno` + `guarantorname`） |

**实测列（已确认存在）**
- `app_credit_report_info`：`reportno` / `customerid` / `customername` / **`zxreportno`** / `querytime` / `subjecttype` / `guarantorid` / `guarantorname`
- `app_guarantor_credit_info`：`reportno` / `customerid` / `customername` / **`guarantorname`** / **`zxreportno`** / `querytime`

⚠️ `guarantorName` 从哪来？—— 报告生成时知识库/规则块就用 `guarantorName` 轮询（`guarantorMode=LEGAL/NATURAL`）⇒ 链接溯源同样按**同一口径**取担保人名。
🔴 但「点链接的那一下」要知道**当前是哪个担保人** ⇒ `blockCode` 不够（一块对应多担保人轮询）。
   ⇒ **备选**：前端把该块的 `data-*` 里带上 `guarantorName`（生成时前端按 `.rpt-guarantor` 分块渲染，能拿到）—— **待定，见表 §6 待确认 3**。

---

## 5. 代码改动清单（✅ 已实施）

### 5.1 行内后端

| # | 文件 | 改动 |
|---|---|---|
| 1 | 🆕 `mapper/LinkTraceQueryMapper.java` | 只读**注解 SQL**（不依赖实体，只取需要列）；🔴 列名全写小写（这些表建表未加引号，物理列已折小写） |
| 2 | 🆕 `service/report/LinkTraceParamBuilder.java` | 按 shareCode 装配 pageParams（11 个策略 + 1050 三分支）；`kv()` 带 URL 编码 + 空值丢弃 |
| 3 | `api/dto/CreditShareUrlRequest.java` | 加 `reportNo`（必填）/ `blockCode` / `guarantorName`；`pageParams` 降级为"可选覆盖" |
| 4 | `controller/ReportController#shareUrl` | 传了 `pageParams` 用传入值，否则实时装配 |
| 5 | `service/report/CreditShareUrlService` | 签名不变（`userId, shareCode, pageParams`）✅ |
| 6 | `controller/EchoController#echo37` | 同步加字段 |

### 5.2 前端 `bosz-agent-frontend-vue3`

| # | 文件 | 改动 |
|---|---|---|
| 1 | `api/report.ts#instanceShareUrl` | body `{ userId, shareCode, reportNo, blockCode?, guarantorName? }` |
| 2 | `pages/report/ReportView.vue#openTraceLink` | 传 `reportNo`（`currentReportNo`）+ `blockCode` + `guarantorName`；`pageParams` 不拼 |
| 3 | `composables/useReportInstance.ts` | 多担保人拆按钮（`extractGuarantorNames` 从同章节 `dbrxx` 块正则提名字 + `traceLinkGuarantors`） |

### 5.3 生成器 + Sheet3

| # | 项 | 改动 |
|---|---|---|
| 1 | `gen_report_template.py` | ✅ 链接溯源的 `params_for()` 已改为**从 H 列取**（同知识库块 `plus_params`） |
| 2 | Excel Sheet3 | ✅ 3 个 `1050` 块 **H 列**填主体令牌；G 列填按钮名（16 个） |

### 5.4 🆕 `agentParams` 通电 + `userId` 口径（19:1x 收口，**外网 + 行内各一套**）

| # | 文件 | 改动 |
|---|---|---|
| 1 | `service/report/model/ReportBlockVO.java` | 🆕 字段 `agentParams`（模板层合入，实例表无此列） |
| 2 | `service/report/model/ReportDetailVO.java` | 🆕 字段 `userNo`（= `report.user_no`，报告发起人） |
| 3 | `service/impl/ReportServiceImpl#detail` | 建 `agentParamsMap`（复用 `loadEnabledBlocks()`，零额外查询）+ `detail.setUserNo(reportInfo.getUserNo())` |
| 4 | `service/impl/ReportServiceImpl#toBlockVO` | 加参 `agentParams` 并 `vo.setAgentParams(...)` |
| 5 | `pages/report/ReportView.vue` | `openTraceLink` 的 `userId` 改读 `detail.userNo`（删掉 `useAppStore` 依赖） |
| 6 | `api/report.ts` | `ReportInstanceDetail` 加 `userNo?`；`agentParams?` 注释改为"已通电" |

---

## 6. ✅ 三点已解答（原「待确认」）

**① `xd_corp_check_info` 的列名** —— ✅ **行内 DDL 已更新**，现 17 列
（`baSerialNo` / `electroApproveSerialNo` / `approveApplyType` 都在）。
> ⚠️ **外网那份同名 DDL 还是旧的**（12 列）⇒ 外网要同步这份，否则建表少列。

**② `app_credit_report_info.subjecttype`** —— ✅ 中文 `借款人` / `担保人`
（个人担保人走 `app_guarantor_credit_info`，不需要 subjecttype）。

**③ 点链接时如何知道「当前是哪个担保人」** —— ✅ 方案 a（前端带 `guarantorName`）。
> 🔴 但实测发现：链接溯源块**不在担保人轮询分段内**（是章节末尾的独立一块），
> 且实例表有 `UNIQUE (reportNo, blockCode)` ⇒ **后端轮询出多实例根本不可行**。
> 故改为**前端从同章节 `dbrxx` 块的 content 里正则提名字**（格式固定
> `<p class="rpt-guarantor-name">企业担保人：XXX</p>`），每人生成一个按钮、各带 `data-guarantor`。

---

## 7. 实施顺序（✅ 已全部完成）

1. ✅ 生成器改 `params_for`（链接溯源取 H 列）→ 重跑 → 校验 → 出增量 DML
2. ✅ `CreditShareUrlRequest` 加字段 + `LinkTraceParamBuilder` 实现 11 个策略
3. ✅ `ReportController#shareUrl` 接线
4. ✅ 前端 body 加字段 + `openTraceLink` 调整 + 多担保人拆按钮
5. ✅ `agentParams` 通电（外网 + 行内 detail 合入）+ `userId` 改取 `report.user_no`
6. ⏳ **行内编译**（T6）+ UAT 联调 —— 行内后端本机编译不了（缺私服依赖）
7. ⏳ **外网那份 `xd_corp_check_info` DDL 要同步行内新版**（17 列）

---

## 8. 🔴 环境配置（不随公共 yml）

`credit.share.base-url` **各环境不同** ⇒ 已从 `application.yml` 移除、改为**按环境 yml 配**；
`CreditShareProperties.baseUrl` **去掉默认值**、`CreditShareUrlService#joinUrl` 空值 **fail-fast 抛错**
（避免退化成本服务域下的死链接且零报错）。

```yaml
credit:
  share:
    base-url: "http://<该环境信贷地址>/crcs/"   # 末尾带 /
```
⏳ 待曹哥提供 dev / uat / prod 三个环境的地址。

---

## 9. 🆕 20:0x —— 展示口径 + 行内外双向同步（收尾）

### 9.1 展示口径：**有才展示**（曹哥 19:31 定案）
「链接未生成 ⇒ 按钮不展示、默认不展示、按 `emptyStrategy` 控制；表格溯源同理」⇒ 前端统一：

| 块类型 | 「有」的判据 |
|---|---|
| `TRACE_LINK` 链接溯源 | **有 `shareCode`**（= 链接能否生成的前提，块 `agentCode` 非空） |
| `TRACE_TABLE` 表格溯源 | **有 `content`**（**原本就如此**，本轮只统一口径、未改行为） |

都没有 ⇒ 交给 `emptyBlockHtml`：`HIDE` 整块不渲染 / `PLACEHOLDER` 显示"暂无数据"。
⇒ 3 个「待定预留」块（`POSTLOAN_L06` / `FUND_L08` / `COMPLIANCE_L02`，均 `HIDE`）**完全不出现**。
⚠️ 代价：缺 `shareCode` 不再"一眼可见"（原设计是置灰+提示）⇒ 靠生成器 `WARN` + DML `agentCode=NULL` 追踪。

### 9.2 行内外同步（**双向**，台账见 `doc/往行内同步_清单_v1.md` 首节）

| 方向 | 内容 | 验证 |
|---|---|---|
| 行内 → 外网 | 本类 + `LinkTraceQueryMapper` + `CreditShareUrlRequest` + `CreditShareProperties`（**零 SSF 依赖**，同包同路径、**SHA1 逐字一致**） | 外网 `mvn -o compile` **BUILD SUCCESS** |
| ⛔ 不同步 | `CreditShareUrlService`（依赖行内 SSF `AuthApi`）+ `ReportController#shareUrl` + `EchoController#echo37` | **外网无 SSF 的真实边界** |
| 外网 → 行内 | 模板 DML（全量+增量）+ `_tools` 4 脚本 + 2 份设计 DDL + 模板 Excel（行内原本连 `file/` 都没有） | 行内实跑 `verify [OK]`、`regen_all` 重跑后 **DML SHA1 不变** |

> 🔑 **前端只有一套** ⇒ 前端改动两边同时生效、**不进同步清单**；
> 但它依赖的字段（`userNo` / `agentParams`）**两边后端都得返回** ⇒ 这才是「外网也要改」的原因。
