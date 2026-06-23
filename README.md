# 贷后管理智能体项目 - 后端服务

## 项目简介

本项目是贷后管理智能体项目的后端服务，为贷后管理场景提供数据采集、知识库管理、智能体适配和报告生成等核心能力。

系统采用"数据层 + 知识库层 + Know-Kit智能体适配层 + 报告层"四层架构，其中 Know-Kit 智能体由第三方提供，本系统负责：

- **数据层**：多源数据接入（API/DB/SFTP/OCR等），结构化存储为客户维度的指标和文本
- **知识库层**：风险判定规则管理，按场景/行业/产品标签分类，支持规则匹配
- **Know-Kit 适配层**：组装数据+规则，调用智能体分析，接收分析结论
- **报告层**：基于智能体输出 + 原始数据生成 H5 交互式贷后管理报告

## 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Java | 1.8 | 运行环境 |
| Spring Boot | 2.7.18 | 应用框架 |
| MyBatis-Plus | 3.5.5 | ORM框架 |
| MySQL | 5.7 | 数据库 |
| Druid | 1.2.20 | 连接池 |
| Fastjson2 | 2.0.51 | JSON序列化 |
| Lombok | - | 代码简化 |

## 架构思路

### 核心设计理念：采集器-解析器分离

数据接入层采用策略模式，将"从哪拿数据"（Collector）和"怎么解析数据"（Parser）解耦：

```
外部数据源 --> Collector（HTTP/SFTP/DB/Upload/Webhook）
                  |
                  v
              原始数据（JSON/Excel/PDF/文本）
                  |
                  v
             Parser（JSONPath/Excel模板/OCR文本/Groovy脚本）
                  |
                  v
          indicator_data + text_data（统一结构化存储）
```

Collector 和 Parser 各自由数据库表 `collector_config` 和 `parser_config` 驱动，支持运行时动态配置，无需修改代码即可接入新数据源。

### 数据存储策略

不按数据域分表，而是用三张核心表覆盖所有数据域：

- `indicator_data`：所有结构化指标（营收、负债率、社保人数等）
- `text_data`：所有文本数据（OCR原始文本、分析总结等）
- `data_snapshot`（report 表内 JSON）：报告生成时的数据快照

新的数据域只需增加 `domain` 枚举值，无需新建表。

### Know-Kit 适配层设计

Know-Kit 是第三方提供的智能体产品。本系统适配层职责极简：

1. `KnowKitRequestBuilder`：查询客户指标+文本+匹配规则，组装成 Know-Kit 要的 JSON
2. `KnowKitAdapterService`：HTTP 调用 Know-Kit API，存储请求/响应记录
3. `ReportGenerateService`：将 Know-Kit 输出 + 原始数据渲染为报告

适配层不包含任何业务逻辑，仅为数据搬运和格式转换。

## 项目结构

```
bosz-agent-backend/
├── pom.xml
└── src/main/java/com/suzhou/bank/
    ├── SuzhouBankApplication.java          # 应用入口
    ├── common/
    │   └── Result.java                     # 统一返回体 Result<T>
    ├── config/
    │   ├── CorsConfig.java                 # 跨域配置
    │   ├── MyBatisPlusConfig.java          # MyBatis-Plus分页插件
    │   └── KnowKitConfig.java              # Know-Kit连接配置
    ├── entity/                             # 13个实体类（@TableName映射）
    ├── mapper/                             # 13个Mapper接口
    ├── controller/
    │   ├── CustomerController.java         # 客户管理API
    │   ├── DataConfigController.java       # 数据源配置API + 采集触发
    │   ├── KnowledgeController.java        # 知识库规则API
    │   ├── KnowKitController.java          # Know-Kit适配API
    │   └── ReportController.java           # 报告生成/查询API
    ├── service/
    │   ├── CustomerService.java            # 客户服务
    │   ├── data/
    │   │   ├── DataConfigService.java      # 采集器/解析器配置管理
    │   │   ├── DataCollectService.java     # 数据采集编排
    │   │   ├── collector/DataCollector.java # 采集器接口（策略模式）
    │   │   └── parser/DataParser.java       # 解析器接口（策略模式）
    │   ├── knowledge/
    │   │   └── KnowledgeService.java        # 规则CRUD + 标签匹配
    │   ├── knowkit/
    │   │   └── KnowKitService.java          # Know-Kit适配
    │   └── report/
    │       └── ReportService.java           # 报告生成
    └── service/impl/                       # 6个Service实现类
```

## API 概览

所有 API 返回统一格式 `Result<T>`：`{"code":200, "message":"success", "data":...}`

### 客户管理 `/api/customer`

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/page?page=1&size=10&keyword=xxx` | 分页查询 |
| GET | `/{id}` | 查询详情 |
| POST | `/` | 新增客户 |
| PUT | `/` | 更新客户 |
| DELETE | `/{id}` | 删除客户 |

### 数据源配置 `/api/data-config`

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/collector/page` | 采集器分页 |
| POST | `/collector` | 新增采集器 |
| PUT | `/collector` | 更新采集器 |
| DELETE | `/collector/{id}` | 删除采集器 |
| GET | `/parser/list/{collectorId}` | 解析器列表 |
| POST | `/parser` | 新增解析器 |
| POST | `/collect/{collectorId}?customerId=1` | 触发采集 |

### 知识库管理 `/api/knowledge`

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/scenario/all` | 场景列表 |
| POST | `/scenario` | 新增场景 |
| GET | `/rule/page?keyword=xxx` | 规则分页 |
| POST | `/rule` | 新增规则 |
| PUT | `/rule` | 更新规则 |
| DELETE | `/rule/{id}` | 删除规则（级联删除条件+标签） |
| GET | `/rule/{id}/conditions` | 规则条件列表 |
| POST | `/rule/{id}/conditions` | 保存规则条件 |
| GET | `/rule/{id}/tags` | 规则标签列表 |
| POST | `/rule/{id}/tags` | 保存规则标签 |

### Know-Kit `/api/know-kit`

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/analyze?customerId=1` | 提交分析任务 |
| GET | `/task/{taskId}` | 查询任务结果 |
| POST | `/task/{taskId}/retry` | 重试失败任务 |

### 报告 `/api/report`

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/generate?customerId=1&knowKitTaskId=1` | 生成报告 |
| GET | `/page` | 报告列表 |
| GET | `/{id}` | 报告详情 |
| GET | `/{id}/html` | 报告HTML内容 |
| DELETE | `/{id}` | 删除报告 |

## 数据库设计

### ER 关系图

```
customer (客户主表)
    |
    ├── indicator_data (指标数据)    -- 按 customer_id + domain 索引
    ├── text_data (文本数据)          -- 按 customer_id + domain 索引
    ├── credit_record (用信记录)      -- 按 customer_id 索引
    ├── know_kit_task (KnowKit任务)   -- 按 customer_id + status 索引
    └── report (报告)                -- 按 customer_id + report_type 索引

collector_config (采集器配置)
    └── parser_config (解析器配置)     -- 按 collector_id 索引

knowledge_rule (规则) --< rule_condition (规则条件) -- 按 rule_id 索引
knowledge_rule (规则) --< rule_tag (规则标签) -- 按 rule_id + tag_type + tag_value 索引
rule_scenario (场景定义) -- 独立表，场景编码唯一

raw_data_log (原始数据日志) -- 每次采集的记录，按 customer_id + collect_time 索引
```

### 13张表清单

| 表名 | 说明 | 核心用途 |
|------|------|---------|
| customer | 客户主表 | 企业基本信息 |
| collector_config | 采集器配置表 | 定义"从哪拿数据" |
| parser_config | 解析器配置表 | 定义"怎么解析数据" |
| raw_data_log | 原始数据日志 | 审计追溯、故障排查 |
| indicator_data | 结构化指标数据 | Know-Kit输入、报告表格 |
| text_data | 文本数据 | Know-Kit输入、报告文字 |
| credit_record | 用信记录 | 征信信息存储 |
| knowledge_rule | 风险判定规则 | 知识库核心 |
| rule_condition | 规则条件 | 规则的判断条件 |
| rule_tag | 规则标签 | 场景/行业/产品标签 |
| rule_scenario | 场景定义 | 场景编码和名称 |
| know_kit_task | Know-Kit任务记录 | 智能体调用记录 |
| report | 报告主表 | 报告存储（含HTML和数据快照） |

### 关键设计决策

**1. indicator_data 和 text_data 是核心数据出口**

- 所有数据域共享同一套表结构，通过 `domain` 字段区分
- Know-Kit 只从这两张表读取数据，不关心原始来源

**2. report.data_snapshot 存储生成时的数据快照**

- 报告一旦生成，即使后续数据更新，报告内容不变
- 支持历史回溯

**3. knowledge_rule.description 用自然语言**

- 因为 Know-Kit 是大模型驱动，规则的"自然语言描述"比"结构化条件"更重要
- `rule_condition` 表的结构化条件用于管理端展示和版本管理

**4. know_kit_task 独立存储**

- 每次分析任务独立记录，请求/响应完整存储
- 支持重试、对比、审计

## 启动方式

```bash
# 1. 初始化数据库
mysql -u root -p --default-character-set=utf8mb4 < init_db.sql

# 2. 修改 application.yml 中的数据库连接信息（如需要）

# 3. 启动
cd backend
mvn spring-boot:run

# 服务端口: 8080
```

## 开发进度

- [x] Collector 具体实现（HttpApiCollector  ✅ / DbSyncCollector ✅ / SftpFileCollector ✅ / FileUploadCollector ✅）
- [x] Parser 具体实现（JsonPathParser ✅ / ExcelTemplateParser ✅ / OcrTextParser ✅）
- [x] Know-Kit API 对接（Mock 实现，生成逼真分析结果用于流程联调）
- [x] 报告 HTML 模板渲染引擎（三栏式布局，五章节完整报告）
- [ ] 数据采集定时任务调度（后续按需实现）
- [ ] 接口文档 Swagger/Knife4j（后续按需实现）
