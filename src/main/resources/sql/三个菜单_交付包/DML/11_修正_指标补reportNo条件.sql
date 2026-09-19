-- =============================================================================
-- 11_修正_指标补reportNo条件.sql
-- -----------------------------------------------------------------------------
-- 目的：给「已配了取数表、却没有取数 SQL」的指标补上**带报告编号过滤**的查询。
--
-- 🔴 2026-09-19 状态：本修复**已直接合并进 `DML/02_数据_指标配置.sql`**
--    （其中 748 个元组的 `script` 字段已由 NULL 就地替换，备份在
--     `DML/_backup_20260919_指标补reportNo前/`）。
--    ⇒ **新环境按顺序导入 02 即为修复后状态，本文件可跳过**；
--      仅「已按旧包导过数据」的库（本地开发库 / 行内已导过旧包的库）才需要本补丁。本文件幂等。
--
-- ✅ 执行记录（本地库，2026-09-19 20:34）：748 条 UPDATE 全部成功、errors=0，
--    文件内 ② 号校验 `still_missing = 0`。
-- ⚠️ 另有 **55 个被规则引用的指标仍缺 script** —— 它们**连取数表（columnFromTable）都没有**，
--    无法自动补，需人工确认取值来源（可能是"由父指标计算得出"的计算型指标）。
--    清单见 `doc/报告规则指标_无报告编号依赖_排查清单_v1.md`。
--
-- 病征（2026-09-19 实测）：
--   这类指标 scriptType=Sql 但 script 为空 ⇒ 取数层组装入参时
--   `if (StringUtils.isNotEmpty(script))` 整段被跳过 ⇒ params 为空数组、
--   同时 intfNo 被赋成 columnFromTable ⇒ 实际执行的是 `SELECT 列 FROM 表` ——
--   **没有 WHERE，连 entName 都没有**。同一批数据会服务所有报告版本。
--
--   典型表现：更新报告（新 reportNo）后，这些指标仍能取到值；
--   实测 V2 与 V1 有 12 个内容块**逐字相同**（167/167、60/60、51/51 字节），
--   其中就包含「电费收入异常」「纳税申报销售额异常」「营收快速下降」等规则块。
--
-- 改法：给每个指标补一个最小可用 SQL：
--       SELECT <acturecolumn> FROM <columnfromtable> WHERE REPORTNO = :reportNo
--   并声明 reportNo 参数（defaultValue 留空 —— 避免样例值兜底参与真实取数）。
--   ⚠️ 不加 `AS 别名`：保持结果列名 = acturecolumn，与取数侧按列名取值一致。
--   ⚠️ 只补 reportNo 一个条件（用户口径：报告编号是最大的前提）。
--      如某指标业务上还需客户/担保人维度，请在该行基础上自行追加
--      `AND CUSTOMERNAME = :entName` / `AND GUARANTORNAME = :guarantorName`。
--
-- 前置校验（已做）：涉及的 9 张表**全部含 reportno 列**，补条件可安全执行。
--
--   · APP_CREDIT_REPORT_INFO            52 个指标
--   · APP_CREDIT_USE_INFO               17 个指标
--   · APP_CUSTOMER_INFO                 19 个指标
--   · APP_FINANCE_INDICATOR_INFO       560 个指标
--   · APP_GRAPH_HIT_INFO                13 个指标
--   · APP_GUARANTOR_CREDIT_INFO         42 个指标
--   · APP_GUARANTOR_INFO                14 个指标
--   · APP_IC_INFO                       13 个指标
--   · APP_SETTLE_ASSET_INFO             18 个指标
--
-- 幂等：每条都带 `script IS NULL OR length(script) = 0` 守卫，重复执行不会二次改写。
-- 影响行数：**748 行**（每个指标 1 行）。
-- 配套代码：IndexParamsServiceImpl#JoinSql 已改为「拒绝生成无 WHERE 的全表查询」；
--           KnowledgeBaseConfigServiceImpl#concatIndexParam 已改为「script 为空则跳过该指标」。
-- 回滚：如需还原，`UPDATE index_params SET script = NULL WHERE paramno IN (…)`（见文件末尾清单）。
-- =============================================================================

-- ① 修正（748 条）-------------------------------------------------------

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039161'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039162'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039163'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039164'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT QUERYTIME FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039165'
   AND (script IS NULL OR length(script) = 0);   -- 征信查询时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ZXREPORTNO FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039166'
   AND (script IS NULL OR length(script) = 0);   -- 征信报告记录号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT EXPIREDATE FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039167'
   AND (script IS NULL OR length(script) = 0);   -- 征信报告有效期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OVERDUETOTAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039168'
   AND (script IS NULL OR length(script) = 0);   -- 未结清信贷的逾期总额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ATTENTIONCREDITBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039169'
   AND (script IS NULL OR length(script) = 0);   -- 未结清关注类信贷余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT BADCREDITBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039170'
   AND (script IS NULL OR length(script) = 0);   -- 未结清不良类借贷余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ATTENTIONGUARANTEEBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039171'
   AND (script IS NULL OR length(script) = 0);   -- 未结清关注类担保交易余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT BADGUARANTEEBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039172'
   AND (script IS NULL OR length(script) = 0);   -- 未结清不良类担保交易余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTEEOVERDUETOTAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039173'
   AND (script IS NULL OR length(script) = 0);   -- 对外担保相关还款责任未结清逾期类负债总额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTEEATTENTIONBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039174'
   AND (script IS NULL OR length(script) = 0);   -- 对外担保相关还款责任未结清关注类负债总额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTEEBADBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039175'
   AND (script IS NULL OR length(script) = 0);   -- 对外担保相关还款责任未结清不良类负债总额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT EXTENDDEBTBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039176'
   AND (script IS NULL OR length(script) = 0);   -- 展期债务未结清余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT RESTRUCTUREDEBTBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039177'
   AND (script IS NULL OR length(script) = 0);   -- 重组债务未结清余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT RENEWDEBTBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039178'
   AND (script IS NULL OR length(script) = 0);   -- 无还本续贷未结清余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TRANSFERDEBTBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039179'
   AND (script IS NULL OR length(script) = 0);   -- 其他机构转入未结清余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NEWOLDDEBTBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039180'
   AND (script IS NULL OR length(script) = 0);   -- 借新还旧债务未结清余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NONBANKLIABTOTAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039181'
   AND (script IS NULL OR length(script) = 0);   -- 在非银机构负债合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NONBANKHIGHRATELOAN FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039182'
   AND (script IS NULL OR length(script) = 0);   -- 非银机构较高利率借款推算利率最大值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039183'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SUBJECTTYPE FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039184'
   AND (script IS NULL OR length(script) = 0);   -- 主体类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTORID FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039185'
   AND (script IS NULL OR length(script) = 0);   -- 担保人客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTORNAME FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039186'
   AND (script IS NULL OR length(script) = 0);   -- 担保人名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NONBANKGUARANTEEBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039187'
   AND (script IS NULL OR length(script) = 0);   -- 在非银机构对外担保余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT WORKINGCAPITALLOANBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039188'
   AND (script IS NULL OR length(script) = 0);   -- 流动资金贷款余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT WORKINGCAPITALLOAN1YBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039189'
   AND (script IS NULL OR length(script) = 0);   -- 一年期以下的流动资金贷款余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LOANBANKORGCOUNT FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039190'
   AND (script IS NULL OR length(script) = 0);   -- 企业借贷交易合作银行及融资租赁机构数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTEEBANKORGCOUNT FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039191'
   AND (script IS NULL OR length(script) = 0);   -- 企业担保交易合作银行及融资租赁机构数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CREDITSHORTTERMDIFF FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039192'
   AND (script IS NULL OR length(script) = 0);   -- 征信短期借款未结清余额与财报短期借款相差

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CREDITLONGTERMDIFF FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039193'
   AND (script IS NULL OR length(script) = 0);   -- 征信中长期借款未结清余额与财报长期借款含一年内到期的长期借款相差

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CREDITDEBTDEVIATION FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039194'
   AND (script IS NULL OR length(script) = 0);   -- 征信债务与财报债务偏离度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTEENETASSET FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039195'
   AND (script IS NULL OR length(script) = 0);   -- 对外担保占净资产

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTEEBALANCEEXBANK FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039196'
   AND (script IS NULL OR length(script) = 0);   -- 对外担保相关还款责任余额剔除我行

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTTERMLOANORGCOUNT FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039197'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款未结清机构数合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MIDLONGTERMLOANORGCOUNT FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039198'
   AND (script IS NULL OR length(script) = 0);   -- 中长期借款未结清机构数合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVOLVINGOVERDRAFTORGCOUNT FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039199'
   AND (script IS NULL OR length(script) = 0);   -- 循环透支未结清机构数合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DISCOUNTORGCOUNT FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039200'
   AND (script IS NULL OR length(script) = 0);   -- 贴现未结清机构数合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT BANKACCEPTANCEBILLORGCOUNT FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039201'
   AND (script IS NULL OR length(script) = 0);   -- 银行承兑汇票未结清机构数合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LETTEROFCREDITORGCOUNT FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039202'
   AND (script IS NULL OR length(script) = 0);   -- 信用证未结清机构数合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT BANKGUARANTEEORGCOUNT FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039203'
   AND (script IS NULL OR length(script) = 0);   -- 银行保函未结清机构数合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERGUARANTEETRADEORGCOUNT FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039204'
   AND (script IS NULL OR length(script) = 0);   -- 其他担保交易未结清机构数合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTTERMLOANBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039205'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款未结清余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MIDLONGTERMLOANBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039206'
   AND (script IS NULL OR length(script) = 0);   -- 中长期借款未结清余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVOLVINGOVERDRAFTBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039207'
   AND (script IS NULL OR length(script) = 0);   -- 循环透支未结清余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DISCOUNTBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039208'
   AND (script IS NULL OR length(script) = 0);   -- 贴现未结清余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT BANKACCEPTANCEBILLBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039209'
   AND (script IS NULL OR length(script) = 0);   -- 银行承兑汇票未结清余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LETTEROFCREDITBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039210'
   AND (script IS NULL OR length(script) = 0);   -- 信用证未结清余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT BANKGUARANTEEBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039211'
   AND (script IS NULL OR length(script) = 0);   -- 银行保函未结清余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERGUARANTEETRADEBAL FROM APP_CREDIT_REPORT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903195039212'
   AND (script IS NULL OR length(script) = 0);   -- 其他担保交易未结清余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829276'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829277'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829278'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829279'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CREDITSUM FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829280'
   AND (script IS NULL OR length(script) = 0);   -- 授信金额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT BALANCE FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829281'
   AND (script IS NULL OR length(script) = 0);   -- 总余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT EXPOSUREAMOUNT FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829282'
   AND (script IS NULL OR length(script) = 0);   -- 敞口金额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LIMITBALANCE FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829283'
   AND (script IS NULL OR length(script) = 0);   -- 敞口余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GROUPAMOUNT FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829284'
   AND (script IS NULL OR length(script) = 0);   -- 集团授信金额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GROUPBALANCE FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829285'
   AND (script IS NULL OR length(script) = 0);   -- 集团总余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ISGROUP FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829286'
   AND (script IS NULL OR length(script) = 0);   -- 是否集团客户

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GROUPNAME FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829287'
   AND (script IS NULL OR length(script) = 0);   -- 所属集团名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CREDITDATE FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829288'
   AND (script IS NULL OR length(script) = 0);   -- 授信日期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LATESTOVERDUEDATE FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829289'
   AND (script IS NULL OR length(script) = 0);   -- 企业当前最近一次逾期日期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GDOVERDUECOUNTS FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829290'
   AND (script IS NULL OR length(script) = 0);   -- 固贷产品近一年历史逾期次数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AJOVERDUECOUNTS FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829291'
   AND (script IS NULL OR length(script) = 0);   -- 按揭贷款产品近一年历史逾期次数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_CREDIT_USE_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903212829292'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943308'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943309'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943310'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943311'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LEGALPERSON FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943312'
   AND (script IS NULL OR length(script) = 0);   -- 法定代表人

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REGISTERCAPITAL FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943313'
   AND (script IS NULL OR length(script) = 0);   -- 注册资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943314'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INDUSTRYTYPE FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943315'
   AND (script IS NULL OR length(script) = 0);   -- 行业分类

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT HOLDTYPE FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943316'
   AND (script IS NULL OR length(script) = 0);   -- 控股类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACTUALCONTROLLER FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943317'
   AND (script IS NULL OR length(script) = 0);   -- 实际控制人

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OFFICEADDRESS FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943318'
   AND (script IS NULL OR length(script) = 0);   -- 办公地址

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT BUSINESSSCOPE FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943319'
   AND (script IS NULL OR length(script) = 0);   -- 经营范围

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DANGERLEVEL FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943320'
   AND (script IS NULL OR length(script) = 0);   -- 十级分类

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT WARNINGLEVEL FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943321'
   AND (script IS NULL OR length(script) = 0);   -- 预警等级

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ISSTATEOWNED FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943322'
   AND (script IS NULL OR length(script) = 0);   -- 是否国资/国有担保

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ISLISTEDCOMPANY FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943323'
   AND (script IS NULL OR length(script) = 0);   -- 借款人是否上市公司

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GROUPNAME FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943324'
   AND (script IS NULL OR length(script) = 0);   -- 所属集团名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ISTECHCOMPANY FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943325'
   AND (script IS NULL OR length(script) = 0);   -- 是否科创企业

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_CUSTOMER_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090943326'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043790344193'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043790344194'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043794538498'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043794538499'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FINREPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043794538500'
   AND (script IS NULL OR length(script) = 0);   -- 财报编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTMONTH FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043794538501'
   AND (script IS NULL OR length(script) = 0);   -- 会计月

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSCOPE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043794538502'
   AND (script IS NULL OR length(script) = 0);   -- 报表口径

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTPERIOD FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043798732802'
   AND (script IS NULL OR length(script) = 0);   -- 报表周期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AUDITFLAG FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043798732803'
   AND (script IS NULL OR length(script) = 0);   -- 是否审计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CURRENCY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043798732804'
   AND (script IS NULL OR length(script) = 0);   -- 报表币种

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MONETARYUNIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043798732805'
   AND (script IS NULL OR length(script) = 0);   -- 货币单位

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUSNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043798732806'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态中文

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043802927105'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态码值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043802927106'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043802927107'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043807121410'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHEETNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043807121411'
   AND (script IS NULL OR length(script) = 0);   -- 科目所在财报类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043807121412'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUEYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043807121413'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043811315714'
   AND (script IS NULL OR length(script) = 0);   -- 净利润

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043811315715'
   AND (script IS NULL OR length(script) = 0);   -- 净利润同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043811315716'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALEQUITY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043811315717'
   AND (script IS NULL OR length(script) = 0);   -- 所有者权益合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043811315718'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043815510017'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043815510018'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043815510019'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043815510020'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043815510021'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARORTOTALASSETRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043819704322'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款和其他应收款合计占总资产比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043819704323'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043819704324'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043819704325'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043823898625'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043823898626'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043823898627'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANDUEWITHIN1Y FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043823898628'
   AND (script IS NULL OR length(script) = 0);   -- 一年内到期的长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESLOANRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043823898629'
   AND (script IS NULL OR length(script) = 0);   -- 销贷比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043828092929'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043828092930'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043828092931'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043828092932'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043828092933'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043832287234'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SLTOTALLOANYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043832287235'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款和长期借款合计同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043832287236'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043832287237'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043832287238'
   AND (script IS NULL OR length(script) = 0);   -- 存货周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043832287239'
   AND (script IS NULL OR length(script) = 0);   -- 存货同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043840675841'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043840675842'
   AND (script IS NULL OR length(script) = 0);   -- 存货

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBTRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043840675843'
   AND (script IS NULL OR length(script) = 0);   -- 资产负债率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043840675844'
   AND (script IS NULL OR length(script) = 0);   -- 销售利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099321043840675845'
   AND (script IS NULL OR length(script) = 0);   -- 净利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FINREPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942002311170'
   AND (script IS NULL OR length(script) = 0);   -- 财报编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942019088385'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTMONTH FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942019088386'
   AND (script IS NULL OR length(script) = 0);   -- 会计月

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSCOPE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942019088387'
   AND (script IS NULL OR length(script) = 0);   -- 报表口径

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTPERIOD FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942019088388'
   AND (script IS NULL OR length(script) = 0);   -- 报表周期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942019088389'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942019088390'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942023282689'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AUDITFLAG FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942023282690'
   AND (script IS NULL OR length(script) = 0);   -- 是否审计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CURRENCY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942027476993'
   AND (script IS NULL OR length(script) = 0);   -- 报表币种

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MONETARYUNIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942027476994'
   AND (script IS NULL OR length(script) = 0);   -- 货币单位

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUSNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942031671297'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态中文

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942031671298'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态码值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942031671299'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942031671300'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942035865602'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHEETNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942035865603'
   AND (script IS NULL OR length(script) = 0);   -- 科目所在财报类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942040059906'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUEYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942044254209'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942044254210'
   AND (script IS NULL OR length(script) = 0);   -- 净利润

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942044254211'
   AND (script IS NULL OR length(script) = 0);   -- 净利润同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942048448513'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALEQUITY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942048448514'
   AND (script IS NULL OR length(script) = 0);   -- 所有者权益合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942048448515'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942052642818'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942052642819'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942052642820'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942052642821'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942061031426'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARORTOTALASSETRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942061031427'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款和其他应收款合计占总资产比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942061031428'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942065225730'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942069420033'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942073614337'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942073614338'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942077808642'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANDUEWITHIN1Y FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942077808643'
   AND (script IS NULL OR length(script) = 0);   -- 一年内到期的长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESLOANRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942077808644'
   AND (script IS NULL OR length(script) = 0);   -- 销贷比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942077808645'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942086197250'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942086197251'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942086197252'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942086197253'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942090391554'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SLTOTALLOANYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942090391555'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款和长期借款合计同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942090391556'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942090391557'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942098780161'
   AND (script IS NULL OR length(script) = 0);   -- 存货周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942098780162'
   AND (script IS NULL OR length(script) = 0);   -- 存货同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942098780163'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942098780164'
   AND (script IS NULL OR length(script) = 0);   -- 存货

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBTRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942107168769'
   AND (script IS NULL OR length(script) = 0);   -- 资产负债率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942107168770'
   AND (script IS NULL OR length(script) = 0);   -- 销售利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099322942107168771'
   AND (script IS NULL OR length(script) = 0);   -- 净利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FINREPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827482800130'
   AND (script IS NULL OR length(script) = 0);   -- 财报编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827482800131'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTMONTH FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827482800132'
   AND (script IS NULL OR length(script) = 0);   -- 会计月

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSCOPE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827482800133'
   AND (script IS NULL OR length(script) = 0);   -- 报表口径

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTPERIOD FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827482800134'
   AND (script IS NULL OR length(script) = 0);   -- 报表周期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827482800135'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827486994434'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827486994435'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AUDITFLAG FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827486994436'
   AND (script IS NULL OR length(script) = 0);   -- 是否审计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CURRENCY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827486994437'
   AND (script IS NULL OR length(script) = 0);   -- 报表币种

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MONETARYUNIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827491188738'
   AND (script IS NULL OR length(script) = 0);   -- 货币单位

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUSNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827491188739'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态中文

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827495383041'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态码值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827495383042'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827495383043'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827499577346'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHEETNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827499577347'
   AND (script IS NULL OR length(script) = 0);   -- 科目所在财报类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827499577348'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUEYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827499577349'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827499577350'
   AND (script IS NULL OR length(script) = 0);   -- 净利润

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827503771650'
   AND (script IS NULL OR length(script) = 0);   -- 净利润同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827503771651'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALEQUITY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827507965954'
   AND (script IS NULL OR length(script) = 0);   -- 所有者权益合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827507965955'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827507965956'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827507965957'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827512160258'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827512160259'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827512160260'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARORTOTALASSETRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827512160261'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款和其他应收款合计占总资产比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827512160262'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827516354561'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827516354562'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827516354563'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827516354564'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827520548866'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANDUEWITHIN1Y FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827520548867'
   AND (script IS NULL OR length(script) = 0);   -- 一年内到期的长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESLOANRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827520548868'
   AND (script IS NULL OR length(script) = 0);   -- 销贷比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827520548869'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827520548870'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827524743170'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827524743171'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827524743172'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827528937473'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SLTOTALLOANYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827528937474'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款和长期借款合计同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827528937475'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827528937476'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827528937477'
   AND (script IS NULL OR length(script) = 0);   -- 存货周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827533131777'
   AND (script IS NULL OR length(script) = 0);   -- 存货同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827533131778'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827533131779'
   AND (script IS NULL OR length(script) = 0);   -- 存货

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBTRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827533131780'
   AND (script IS NULL OR length(script) = 0);   -- 资产负债率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827533131781'
   AND (script IS NULL OR length(script) = 0);   -- 销售利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099323827537326082'
   AND (script IS NULL OR length(script) = 0);   -- 净利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSCOPE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805201993730'
   AND (script IS NULL OR length(script) = 0);   -- 报表口径

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTPERIOD FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805227159553'
   AND (script IS NULL OR length(script) = 0);   -- 报表周期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805227159554'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805227159555'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805227159556'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AUDITFLAG FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805231353858'
   AND (script IS NULL OR length(script) = 0);   -- 是否审计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CURRENCY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805231353859'
   AND (script IS NULL OR length(script) = 0);   -- 报表币种

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MONETARYUNIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805231353860'
   AND (script IS NULL OR length(script) = 0);   -- 货币单位

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTMONTH FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805231353861'
   AND (script IS NULL OR length(script) = 0);   -- 会计月

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FINREPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805235548162'
   AND (script IS NULL OR length(script) = 0);   -- 财报编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805235548163'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUSNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805235548164'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态中文

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805235548165'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态码值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805235548166'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805239742466'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805239742467'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHEETNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805239742468'
   AND (script IS NULL OR length(script) = 0);   -- 科目所在财报类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805243936770'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUEYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805243936771'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805243936772'
   AND (script IS NULL OR length(script) = 0);   -- 净利润

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805243936773'
   AND (script IS NULL OR length(script) = 0);   -- 净利润同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805243936774'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALEQUITY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805248131073'
   AND (script IS NULL OR length(script) = 0);   -- 所有者权益合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805248131074'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805248131075'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805248131076'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805248131077'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805252325377'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805252325378'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARORTOTALASSETRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805252325379'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款和其他应收款合计占总资产比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805252325380'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805256519681'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805256519682'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805256519683'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805256519684'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805260713986'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANDUEWITHIN1Y FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805260713987'
   AND (script IS NULL OR length(script) = 0);   -- 一年内到期的长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESLOANRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805260713988'
   AND (script IS NULL OR length(script) = 0);   -- 销贷比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805260713989'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805260713990'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805264908289'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805264908290'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805264908291'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805264908292'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SLTOTALLOANYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805269102594'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款和长期借款合计同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805269102595'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805269102596'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805269102597'
   AND (script IS NULL OR length(script) = 0);   -- 存货周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805273296897'
   AND (script IS NULL OR length(script) = 0);   -- 存货同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805273296898'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805273296899'
   AND (script IS NULL OR length(script) = 0);   -- 存货

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBTRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805273296900'
   AND (script IS NULL OR length(script) = 0);   -- 资产负债率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805277491202'
   AND (script IS NULL OR length(script) = 0);   -- 销售利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099325805277491203'
   AND (script IS NULL OR length(script) = 0);   -- 净利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSCOPE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306602778626'
   AND (script IS NULL OR length(script) = 0);   -- 报表口径

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTPERIOD FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306602778627'
   AND (script IS NULL OR length(script) = 0);   -- 报表周期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306606972930'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306606972931'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306606972932'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AUDITFLAG FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306606972933'
   AND (script IS NULL OR length(script) = 0);   -- 是否审计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CURRENCY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306606972934'
   AND (script IS NULL OR length(script) = 0);   -- 报表币种

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MONETARYUNIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306611167233'
   AND (script IS NULL OR length(script) = 0);   -- 货币单位

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTMONTH FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306611167234'
   AND (script IS NULL OR length(script) = 0);   -- 会计月

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FINREPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306611167235'
   AND (script IS NULL OR length(script) = 0);   -- 财报编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306611167236'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUSNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306615361537'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态中文

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306615361538'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态码值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306615361539'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306619555842'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306619555843'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHEETNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306619555844'
   AND (script IS NULL OR length(script) = 0);   -- 科目所在财报类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306619555845'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUEYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306619555846'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306623750146'
   AND (script IS NULL OR length(script) = 0);   -- 净利润

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306623750147'
   AND (script IS NULL OR length(script) = 0);   -- 净利润同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306623750148'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALEQUITY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306627944449'
   AND (script IS NULL OR length(script) = 0);   -- 所有者权益合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306627944450'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306627944451'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306627944452'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306627944453'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306632138754'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306632138755'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARORTOTALASSETRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306632138756'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款和其他应收款合计占总资产比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306632138757'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306632138758'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306636333058'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306636333059'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306636333060'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306636333061'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANDUEWITHIN1Y FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306640527362'
   AND (script IS NULL OR length(script) = 0);   -- 一年内到期的长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESLOANRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306640527363'
   AND (script IS NULL OR length(script) = 0);   -- 销贷比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306640527364'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306640527365'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306640527366'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306644721665'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306644721666'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306644721667'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SLTOTALLOANYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306644721668'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款和长期借款合计同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306648915969'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306648915970'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306648915971'
   AND (script IS NULL OR length(script) = 0);   -- 存货周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306648915972'
   AND (script IS NULL OR length(script) = 0);   -- 存货同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306648915973'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306653110274'
   AND (script IS NULL OR length(script) = 0);   -- 存货

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBTRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306653110275'
   AND (script IS NULL OR length(script) = 0);   -- 资产负债率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306653110276'
   AND (script IS NULL OR length(script) = 0);   -- 销售利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099329306653110277'
   AND (script IS NULL OR length(script) = 0);   -- 净利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSCOPE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308391317506'
   AND (script IS NULL OR length(script) = 0);   -- 报表口径

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTPERIOD FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308391317507'
   AND (script IS NULL OR length(script) = 0);   -- 报表周期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308391317508'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308395511809'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308395511810'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AUDITFLAG FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308395511811'
   AND (script IS NULL OR length(script) = 0);   -- 是否审计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CURRENCY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308399706114'
   AND (script IS NULL OR length(script) = 0);   -- 报表币种

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MONETARYUNIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308399706115'
   AND (script IS NULL OR length(script) = 0);   -- 货币单位

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTMONTH FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308399706116'
   AND (script IS NULL OR length(script) = 0);   -- 会计月

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FINREPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308399706117'
   AND (script IS NULL OR length(script) = 0);   -- 财报编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308403900417'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUSNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308403900418'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态中文

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308403900419'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态码值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308403900420'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308403900421'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308408094721'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHEETNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308408094722'
   AND (script IS NULL OR length(script) = 0);   -- 科目所在财报类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308408094723'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUEYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308408094724'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308412289025'
   AND (script IS NULL OR length(script) = 0);   -- 净利润

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308412289026'
   AND (script IS NULL OR length(script) = 0);   -- 净利润同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308412289027'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALEQUITY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308412289028'
   AND (script IS NULL OR length(script) = 0);   -- 所有者权益合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308416483329'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308416483330'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308416483331'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308416483332'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308416483333'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308420677634'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARORTOTALASSETRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308420677635'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款和其他应收款合计占总资产比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308420677636'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308420677637'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308424871938'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308424871939'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308424871940'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308424871941'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANDUEWITHIN1Y FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308424871942'
   AND (script IS NULL OR length(script) = 0);   -- 一年内到期的长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESLOANRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308429066241'
   AND (script IS NULL OR length(script) = 0);   -- 销贷比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308429066242'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308429066243'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308433260545'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308433260546'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308433260547'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308433260548'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SLTOTALLOANYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308433260549'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款和长期借款合计同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308437454849'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308437454850'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308437454851'
   AND (script IS NULL OR length(script) = 0);   -- 存货周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308437454852'
   AND (script IS NULL OR length(script) = 0);   -- 存货同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308437454853'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308441649154'
   AND (script IS NULL OR length(script) = 0);   -- 存货

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBTRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308441649155'
   AND (script IS NULL OR length(script) = 0);   -- 资产负债率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308441649156'
   AND (script IS NULL OR length(script) = 0);   -- 销售利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099330308441649157'
   AND (script IS NULL OR length(script) = 0);   -- 净利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSCOPE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486734888961'
   AND (script IS NULL OR length(script) = 0);   -- 报表口径

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTPERIOD FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486734888962'
   AND (script IS NULL OR length(script) = 0);   -- 报表周期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486734888963'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486743277569'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486743277570'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AUDITFLAG FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486743277571'
   AND (script IS NULL OR length(script) = 0);   -- 是否审计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CURRENCY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486743277572'
   AND (script IS NULL OR length(script) = 0);   -- 报表币种

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MONETARYUNIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486747471873'
   AND (script IS NULL OR length(script) = 0);   -- 货币单位

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTMONTH FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486747471874'
   AND (script IS NULL OR length(script) = 0);   -- 会计月

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FINREPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486747471875'
   AND (script IS NULL OR length(script) = 0);   -- 财报编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486751666177'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUSNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486751666178'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态中文

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486751666179'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态码值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486755860482'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486755860483'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486755860484'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHEETNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486755860485'
   AND (script IS NULL OR length(script) = 0);   -- 科目所在财报类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486755860486'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUEYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486755860487'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486764249089'
   AND (script IS NULL OR length(script) = 0);   -- 净利润

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486764249090'
   AND (script IS NULL OR length(script) = 0);   -- 净利润同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486764249091'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALEQUITY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486768443393'
   AND (script IS NULL OR length(script) = 0);   -- 所有者权益合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486768443394'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486768443395'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486768443396'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486772637697'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486772637698'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486772637699'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARORTOTALASSETRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486772637700'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款和其他应收款合计占总资产比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486776832001'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486776832002'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486776832003'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486776832004'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486781026306'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486781026307'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANDUEWITHIN1Y FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486781026308'
   AND (script IS NULL OR length(script) = 0);   -- 一年内到期的长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESLOANRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486781026309'
   AND (script IS NULL OR length(script) = 0);   -- 销贷比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486781026310'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486785220609'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486785220610'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486785220611'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486785220612'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486789414913'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SLTOTALLOANYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486789414914'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款和长期借款合计同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486789414915'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486789414916'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486793609218'
   AND (script IS NULL OR length(script) = 0);   -- 存货周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486793609219'
   AND (script IS NULL OR length(script) = 0);   -- 存货同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486793609220'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486793609221'
   AND (script IS NULL OR length(script) = 0);   -- 存货

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBTRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486797803522'
   AND (script IS NULL OR length(script) = 0);   -- 资产负债率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486797803523'
   AND (script IS NULL OR length(script) = 0);   -- 销售利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099331486797803524'
   AND (script IS NULL OR length(script) = 0);   -- 净利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSCOPE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716724027394'
   AND (script IS NULL OR length(script) = 0);   -- 报表口径

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTPERIOD FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716724027395'
   AND (script IS NULL OR length(script) = 0);   -- 报表周期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716724027396'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716724027397'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716728221697'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AUDITFLAG FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716728221698'
   AND (script IS NULL OR length(script) = 0);   -- 是否审计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CURRENCY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716728221699'
   AND (script IS NULL OR length(script) = 0);   -- 报表币种

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MONETARYUNIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716728221700'
   AND (script IS NULL OR length(script) = 0);   -- 货币单位

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTMONTH FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716732416002'
   AND (script IS NULL OR length(script) = 0);   -- 会计月

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FINREPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716732416003'
   AND (script IS NULL OR length(script) = 0);   -- 财报编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716736610305'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUSNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716736610306'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态中文

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716736610307'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态码值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716736610308'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716736610309'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716740804610'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHEETNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716740804611'
   AND (script IS NULL OR length(script) = 0);   -- 科目所在财报类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716740804612'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUEYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716740804613'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716744998914'
   AND (script IS NULL OR length(script) = 0);   -- 净利润

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716744998915'
   AND (script IS NULL OR length(script) = 0);   -- 净利润同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716744998916'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALEQUITY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716744998917'
   AND (script IS NULL OR length(script) = 0);   -- 所有者权益合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716749193217'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716749193218'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716749193219'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716749193220'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716749193221'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716753387521'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARORTOTALASSETRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716753387522'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款和其他应收款合计占总资产比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716753387523'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716753387524'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716757581825'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716757581826'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716757581827'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716757581828'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANDUEWITHIN1Y FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716757581829'
   AND (script IS NULL OR length(script) = 0);   -- 一年内到期的长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESLOANRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716761776130'
   AND (script IS NULL OR length(script) = 0);   -- 销贷比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716761776131'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716761776132'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716761776133'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716761776134'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716761776135'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716770164738'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SLTOTALLOANYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716770164739'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款和长期借款合计同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716774359041'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716774359042'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716774359043'
   AND (script IS NULL OR length(script) = 0);   -- 存货周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716774359044'
   AND (script IS NULL OR length(script) = 0);   -- 存货同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716774359045'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716774359046'
   AND (script IS NULL OR length(script) = 0);   -- 存货

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBTRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716778553345'
   AND (script IS NULL OR length(script) = 0);   -- 资产负债率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716778553346'
   AND (script IS NULL OR length(script) = 0);   -- 销售利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099335716778553347'
   AND (script IS NULL OR length(script) = 0);   -- 净利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099387837104271362'
   AND (script IS NULL OR length(script) = 0);   -- 纳税期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099387837104271363'
   AND (script IS NULL OR length(script) = 0);   -- 当年纳税销售额累计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099387837104271364'
   AND (script IS NULL OR length(script) = 0);   -- 当年销售额较上年同期变动额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099387837108465666'
   AND (script IS NULL OR length(script) = 0);   -- 当年销售额较上年同期同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099391513537556482'
   AND (script IS NULL OR length(script) = 0);   -- 纳税期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099391513537556483'
   AND (script IS NULL OR length(script) = 0);   -- 当年纳税销售额累计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099391513537556484'
   AND (script IS NULL OR length(script) = 0);   -- 当年销售额较上年同期变动额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099391513541750785'
   AND (script IS NULL OR length(script) = 0);   -- 当年销售额较上年同期同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSCOPE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094654570497'
   AND (script IS NULL OR length(script) = 0);   -- 报表口径

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTPERIOD FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094658764802'
   AND (script IS NULL OR length(script) = 0);   -- 报表周期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094658764803'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094662959105'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094662959106'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AUDITFLAG FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094662959107'
   AND (script IS NULL OR length(script) = 0);   -- 是否审计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CURRENCY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094662959108'
   AND (script IS NULL OR length(script) = 0);   -- 报表币种

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MONETARYUNIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094662959109'
   AND (script IS NULL OR length(script) = 0);   -- 货币单位

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTMONTH FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094667153409'
   AND (script IS NULL OR length(script) = 0);   -- 会计月

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FINREPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094667153410'
   AND (script IS NULL OR length(script) = 0);   -- 财报编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094667153411'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUSNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094667153412'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态中文

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094667153413'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态码值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094671347714'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094671347715'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094671347716'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHEETNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094671347717'
   AND (script IS NULL OR length(script) = 0);   -- 科目所在财报类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094675542018'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUEYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094675542019'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094675542020'
   AND (script IS NULL OR length(script) = 0);   -- 净利润

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094675542021'
   AND (script IS NULL OR length(script) = 0);   -- 净利润同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094675542022'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALEQUITY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094679736322'
   AND (script IS NULL OR length(script) = 0);   -- 所有者权益合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094679736323'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094679736324'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094679736325'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094679736326'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094683930626'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094683930627'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARORTOTALASSETRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094683930628'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款和其他应收款合计占总资产比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094683930629'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094688124929'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094688124930'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094688124931'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094688124932'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094688124933'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANDUEWITHIN1Y FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094692319233'
   AND (script IS NULL OR length(script) = 0);   -- 一年内到期的长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESLOANRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094692319234'
   AND (script IS NULL OR length(script) = 0);   -- 销贷比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094692319235'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094692319236'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094692319237'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094696513538'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094696513539'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094696513540'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SLTOTALLOANYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094696513541'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款和长期借款合计同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094696513542'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094700707841'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094700707842'
   AND (script IS NULL OR length(script) = 0);   -- 存货周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094700707843'
   AND (script IS NULL OR length(script) = 0);   -- 存货同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094700707844'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094700707845'
   AND (script IS NULL OR length(script) = 0);   -- 存货

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBTRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094704902146'
   AND (script IS NULL OR length(script) = 0);   -- 资产负债率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094704902147'
   AND (script IS NULL OR length(script) = 0);   -- 销售利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099473094704902148'
   AND (script IS NULL OR length(script) = 0);   -- 净利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228043591681'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT AUDITFLAG FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228047785986'
   AND (script IS NULL OR length(script) = 0);   -- 是否审计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CURRENCY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228047785987'
   AND (script IS NULL OR length(script) = 0);   -- 报表币种

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT MONETARYUNIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228047785988'
   AND (script IS NULL OR length(script) = 0);   -- 货币单位

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTMONTH FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228051980290'
   AND (script IS NULL OR length(script) = 0);   -- 会计月

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FINREPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228051980291'
   AND (script IS NULL OR length(script) = 0);   -- 财报编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228056174593'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUSNAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228056174594'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态中文

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSTATUS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228056174595'
   AND (script IS NULL OR length(script) = 0);   -- 报表状态码值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228060368897'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228060368898'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTTYPENAME FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228060368899'
   AND (script IS NULL OR length(script) = 0);   -- 报表类型名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTSCOPE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228060368900'
   AND (script IS NULL OR length(script) = 0);   -- 报表口径

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTPERIOD FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228060368901'
   AND (script IS NULL OR length(script) = 0);   -- 报表周期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228060368902'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228060368903'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHEETNO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228060368904'
   AND (script IS NULL OR length(script) = 0);   -- 科目所在财报类型

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228060368905'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REVENUEYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228060368906'
   AND (script IS NULL OR length(script) = 0);   -- 营业收入同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFIT FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228077146114'
   AND (script IS NULL OR length(script) = 0);   -- 净利润

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228077146115'
   AND (script IS NULL OR length(script) = 0);   -- 净利润同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PAIDINCAPITAL FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228077146116'
   AND (script IS NULL OR length(script) = 0);   -- 实收资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALEQUITY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228077146117'
   AND (script IS NULL OR length(script) = 0);   -- 所有者权益合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228077146118'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340417'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340418'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERRECEIVABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340419'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340420'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ORCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340421'
   AND (script IS NULL OR length(script) = 0);   -- 其他应收款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARORTOTALASSETRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340422'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款和其他应收款合计占总资产比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340423'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340424'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SHORTLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340425'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOAN FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340426'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340427'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANCHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340428'
   AND (script IS NULL OR length(script) = 0);   -- 长期借款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LONGLOANDUEWITHIN1Y FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340429'
   AND (script IS NULL OR length(script) = 0);   -- 一年内到期的长期借款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESLOANRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340430'
   AND (script IS NULL OR length(script) = 0);   -- 销贷比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228081340431'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228106506241'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NOTESPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228106506242'
   AND (script IS NULL OR length(script) = 0);   -- 应付票据较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228106506243'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTART FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228106506244'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初变动

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERPAYABLECHANGEFROMYEARSTARTRATE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228110700546'
   AND (script IS NULL OR length(script) = 0);   -- 其他应付款较年初增幅

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SLTOTALLOANYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228110700547'
   AND (script IS NULL OR length(script) = 0);   -- 短期借款和长期借款合计同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228110700548'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228114894849'
   AND (script IS NULL OR length(script) = 0);   -- 应收账款周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228114894850'
   AND (script IS NULL OR length(script) = 0);   -- 存货周转天数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYYOY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228119089153'
   AND (script IS NULL OR length(script) = 0);   -- 存货同比

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCOUNTSPAYABLE FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228119089154'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORY FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228123283458'
   AND (script IS NULL OR length(script) = 0);   -- 存货

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBTRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228123283459'
   AND (script IS NULL OR length(script) = 0);   -- 资产负债率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SALESPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228123283460'
   AND (script IS NULL OR length(script) = 0);   -- 销售利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NETPROFITRATIO FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099474228127477761'
   AND (script IS NULL OR length(script) = 0);   -- 净利率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099486550321541121'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099486550321541122'
   AND (script IS NULL OR length(script) = 0);   -- 存货偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099487507818229762'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099487507818229763'
   AND (script IS NULL OR length(script) = 0);   -- 存货偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099492014513991681'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099492014513991682'
   AND (script IS NULL OR length(script) = 0);   -- 存货偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099493652599418883'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099493652599418884'
   AND (script IS NULL OR length(script) = 0);   -- 存货偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099493932376272899'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099493932376272900'
   AND (script IS NULL OR length(script) = 0);   -- 存货偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ARTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099494367472398339'
   AND (script IS NULL OR length(script) = 0);   -- 应付账款偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INVENTORYTURNOVERDAYS FROM APP_FINANCE_INDICATOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2099494367472398340'
   AND (script IS NULL OR length(script) = 0);   -- 存货偏差幅度

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SUSPECTEDSHELLCOMPANY FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260914194856100'
   AND (script IS NULL OR length(script) = 0);   -- 疑似空壳公司

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SUSPECTEDGUARANTEECIRCLE FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260914194856101'
   AND (script IS NULL OR length(script) = 0);   -- 疑似担保圈链

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INTRABANKRELATION FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260914194856102'
   AND (script IS NULL OR length(script) = 0);   -- 行内关联关系

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ENTRUSTEDPAYMANYTOONE FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260914194856103'
   AND (script IS NULL OR length(script) = 0);   -- 受托支付多对一

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT COLLATERALSAMECOMMUNITY FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260914194856104'
   AND (script IS NULL OR length(script) = 0);   -- 抵押物同小区关联

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091419485692'
   AND (script IS NULL OR length(script) = 0);   -- id

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091419485693'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091419485694'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091419485695'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091419485696'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SUSPECTEDFUNDRETURN FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091419485697'
   AND (script IS NULL OR length(script) = 0);   -- 疑似资金回流

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SUSPECTEDLOANPURPOSEABNORMAL FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091419485698'
   AND (script IS NULL OR length(script) = 0);   -- 贷款用途疑似异常

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SUSPECTEDBORROWEDNAMELOAN FROM APP_GRAPH_HIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091419485699'
   AND (script IS NULL OR length(script) = 0);   -- 疑似借名贷款

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033214'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033215'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033216'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033217'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTORNAME FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033218'
   AND (script IS NULL OR length(script) = 0);   -- 担保人

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT QUERYTIME FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033219'
   AND (script IS NULL OR length(script) = 0);   -- 征信查询时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ZXREPORTNO FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033220'
   AND (script IS NULL OR length(script) = 0);   -- 征信报告记录号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALLOANBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033221'
   AND (script IS NULL OR length(script) = 0);   -- 贷款余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OPERATELOANBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033222'
   AND (script IS NULL OR length(script) = 0);   -- 经营性贷款余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CONSUMELOANBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033223'
   AND (script IS NULL OR length(script) = 0);   -- 消费类贷款余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT HOUSELOANBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033224'
   AND (script IS NULL OR length(script) = 0);   -- 住房类贷款余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERLOANBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033225'
   AND (script IS NULL OR length(script) = 0);   -- 其他贷款余额合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT TOTALLOANCOUNT FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033226'
   AND (script IS NULL OR length(script) = 0);   -- 贷款机构数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OPERATELOANCOUNT FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033227'
   AND (script IS NULL OR length(script) = 0);   -- 经营性贷款机构数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CONSUMELOANCOUNT FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033228'
   AND (script IS NULL OR length(script) = 0);   -- 消费类贷款机构数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT HOUSELOANCOUNT FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033229'
   AND (script IS NULL OR length(script) = 0);   -- 住房类贷款机构数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT OTHERLOANCOUNT FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033230'
   AND (script IS NULL OR length(script) = 0);   -- 其他贷款机构数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT BZCBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033231'
   AND (script IS NULL OR length(script) = 0);   -- 被追偿余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT BADBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033232'
   AND (script IS NULL OR length(script) = 0);   -- 呆账余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LOANCURRENTOVERDUE FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033233'
   AND (script IS NULL OR length(script) = 0);   -- 贷款当前逾期总金额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CARDCURRENTOVERDUE FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033234'
   AND (script IS NULL OR length(script) = 0);   -- 贷记卡当前逾期总金额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTEEOVERDUEAMT FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033235'
   AND (script IS NULL OR length(script) = 0);   -- 对外担保相关还款责任当前逾期金额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NONBANKGUARANTEEBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033236'
   AND (script IS NULL OR length(script) = 0);   -- 在非银机构对外担保余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NONBANKHIGHRATELOAN FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033237'
   AND (script IS NULL OR length(script) = 0);   -- 非银机构较高利率借款推算利率最大值

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTEEABNORMALBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033238'
   AND (script IS NULL OR length(script) = 0);   -- 对外担保相关还款责任五级分类非正常余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT EXTENDBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033239'
   AND (script IS NULL OR length(script) = 0);   -- 展期债务余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DELAYBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033240'
   AND (script IS NULL OR length(script) = 0);   -- 落实金融困等政策银行主动延期债务余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CREDITABNORMALBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033241'
   AND (script IS NULL OR length(script) = 0);   -- 未结清信贷五级分类非正常余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ACCTABNORMALBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033242'
   AND (script IS NULL OR length(script) = 0);   -- 未结清账户状态非正常余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CARDABNORMALBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033243'
   AND (script IS NULL OR length(script) = 0);   -- 未销户贷记卡账户状态非正常余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTEEHKABNORMALBAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033244'
   AND (script IS NULL OR length(script) = 0);   -- 对外担保相关还款责任还款状态非正常余额

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CREDITUSERATE FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033245'
   AND (script IS NULL OR length(script) = 0);   -- 信用卡使用率

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033246'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT GUARANTORID FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033247'
   AND (script IS NULL OR length(script) = 0);   -- 担保人客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT NONBANKLIABTOTAL FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033248'
   AND (script IS NULL OR length(script) = 0);   -- 在非银机构负债合计

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LOANQUERY12M FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033249'
   AND (script IS NULL OR length(script) = 0);   -- 近一年贷款审批征信查询次数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LOANQUERY6M FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033250'
   AND (script IS NULL OR length(script) = 0);   -- 近6个月贷款审批征信查询次数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LOANQUERY3M FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033251'
   AND (script IS NULL OR length(script) = 0);   -- 近3个月贷款审批征信查询次数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CARDQUERY12M FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033252'
   AND (script IS NULL OR length(script) = 0);   -- 近一年信用卡审批征信查询次数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CARDQUERY6M FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033253'
   AND (script IS NULL OR length(script) = 0);   -- 近6个月信用卡审批征信查询次数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CARDQUERY3M FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033254'
   AND (script IS NULL OR length(script) = 0);   -- 近3个月信用卡审批征信查询次数

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT SELFQUERY1M FROM APP_GUARANTOR_CREDIT_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260903201033255'
   AND (script IS NULL OR length(script) = 0);   -- 近1个月本人查询征信查询次数

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT GUARANTORID FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026090317121810'
   AND (script IS NULL OR length(script) = 0);   -- 担保人客户编号

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT SUBJECTTYPE FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026090317121811'
   AND (script IS NULL OR length(script) = 0);   -- 主体类型

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT ZXREPORTNOZX FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026090317121812'
   AND (script IS NULL OR length(script) = 0);   -- 征信报告记录号最新

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT ZXREPORTNOSQ FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026090317121813'
   AND (script IS NULL OR length(script) = 0);   -- 征信报告记录号上期

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT ZXREPORTNOSX FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026090317121814'
   AND (script IS NULL OR length(script) = 0);   -- 征信报告记录号授信

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT ID FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026090317121815'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT REPORTNO FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '202609031712182'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT CUSTOMERID FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '202609031712183'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT CUSTOMERNAME FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '202609031712184'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT GUARANTORNAME FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '202609031712185'
   AND (script IS NULL OR length(script) = 0);   -- 担保人

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT GUARANTORTYPE FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '202609031712186'
   AND (script IS NULL OR length(script) = 0);   -- 担保人类型

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT ISSTATEOWNED FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '202609031712187'
   AND (script IS NULL OR length(script) = 0);   -- 是否国有担保

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT EDUCATION FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '202609031712188'
   AND (script IS NULL OR length(script) = 0);   -- 学历

UPDATE index_params
   SET script = '{"dataSource":"2092788284460699650","sql":"SELECT INPUTTIME FROM APP_GUARANTOR_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '202609031712189'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513294'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513295'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513296'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513297'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ICLEGALPERSON FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513298'
   AND (script IS NULL OR length(script) = 0);   -- 工商法定代表人

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ICREGISTERCAPITAL FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513299'
   AND (script IS NULL OR length(script) = 0);   -- 工商注册资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ICPAIDINCAPITAL FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513300'
   AND (script IS NULL OR length(script) = 0);   -- 工商实缴资本

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ICBENEFICIARYNAME FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513301'
   AND (script IS NULL OR length(script) = 0);   -- 工商受益人名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ICBENEFICIARYPERCENT FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513302'
   AND (script IS NULL OR length(script) = 0);   -- 工商受益人持股比例

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ISSTATEOWNED FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513303'
   AND (script IS NULL OR length(script) = 0);   -- 是否国有企业

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ISFAKESTATEOWNED FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513304'
   AND (script IS NULL OR length(script) = 0);   -- 是否假冒国企

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CANCELLATIONDATE FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513305'
   AND (script IS NULL OR length(script) = 0);   -- 注销日期

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_IC_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '20260904090513306'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ID FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242418'
   AND (script IS NULL OR length(script) = 0);   -- ID

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT REPORTNO FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242419'
   AND (script IS NULL OR length(script) = 0);   -- 报告编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERID FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242420'
   AND (script IS NULL OR length(script) = 0);   -- 客户编号

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CUSTOMERNAME FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242421'
   AND (script IS NULL OR length(script) = 0);   -- 客户名称

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT FROZENAMOUNT FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242422'
   AND (script IS NULL OR length(script) = 0);   -- 冻结金额（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT DEBITSAMENAMETRANSFERRATIO FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242423'
   AND (script IS NULL OR length(script) = 0);   -- 借方同名划转金额占比（%）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT CREDITSAMENAMETRANSFERRATIO FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242424'
   AND (script IS NULL OR length(script) = 0);   -- 贷方同名划转金额占比（%）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT YEARAVGDEPOSIT FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242425'
   AND (script IS NULL OR length(script) = 0);   -- 年日均存款（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT LASTYEARAVGDEPOSIT FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242426'
   AND (script IS NULL OR length(script) = 0);   -- 上年年日均存款（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PROPERTYINCOME FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242427'
   AND (script IS NULL OR length(script) = 0);   -- 当年物业收入（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PROPERTYINCOMEYOY FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242428'
   AND (script IS NULL OR length(script) = 0);   -- 当年物业收入累计较上年同期（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT PROPERTYINCOMESUPERVISED FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242429'
   AND (script IS NULL OR length(script) = 0);   -- 当年监管账户物业收入（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ELECTRICFEEINCOME FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242430'
   AND (script IS NULL OR length(script) = 0);   -- 当年电费收入（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ELECTRICFEEYOY FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242431'
   AND (script IS NULL OR length(script) = 0);   -- 当年电费收入累计较上年同期（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT ELECTRICFEESUPERVISED FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242432'
   AND (script IS NULL OR length(script) = 0);   -- 当年监管账户当年电费收入（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT KEYWORDCOUNTERPARTYCREDITAMOUNT FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242433'
   AND (script IS NULL OR length(script) = 0);   -- 当年交易对手中出现小额贷款、担保等关键字的公司贷方发生额（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT KEYWORDREMARKCREDITAMOUNT FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242434'
   AND (script IS NULL OR length(script) = 0);   -- 当年备注中有担保、借款、投资关键字贷方发生额（万元）

UPDATE index_params
   SET script = '{"dataSource":"2095447359636992001","sql":"SELECT INPUTTIME FROM APP_SETTLE_ASSET_INFO WHERE REPORTNO = :reportNo","paramData":[{"name":"reportNo","desc":"报告编号","type":"1","isSync":"Y","defaultValue":"","relateIndex":null}]}'
 WHERE paramno = '2026091114242435'
   AND (script IS NULL OR length(script) = 0);   -- 入库时间

-- ② 校验：预期 no_reportno = 0，补上数 = 748 
--    （脚本未在本文件内执行，请单跑这条 SELECT 复核）
SELECT count(*) AS still_missing
  FROM index_params
 WHERE scripttype = 'Sql'
   AND (script IS NULL OR length(script) = 0)
   AND columnfromtable IS NOT NULL AND length(columnfromtable) > 0;

-- ③ 规则侧复核：被规则引用且仍缺 script 的指标应归零
SELECT count(DISTINCT p.paramno) AS used_by_rules_still_missing
  FROM index_params p JOIN agent_rule r ON position(p.paramno in r.parsed_expression) > 0
 WHERE p.scripttype = 'Sql' AND (p.script IS NULL OR length(p.script) = 0);

-- ④ 回滚清单（748 个 paramno，还原成 NULL 即可）-------------------
-- UPDATE index_params SET script = NULL WHERE paramno IN (
--   '20260903195039161', '20260903195039162', '20260903195039163', '20260903195039164', '20260903195039165', '20260903195039166', '20260903195039167', '20260903195039168', '20260903195039169', '20260903195039170',
--   '20260903195039171', '20260903195039172', '20260903195039173', '20260903195039174', '20260903195039175', '20260903195039176', '20260903195039177', '20260903195039178', '20260903195039179', '20260903195039180',
--   '20260903195039181', '20260903195039182', '20260903195039183', '20260903195039184', '20260903195039185', '20260903195039186', '20260903195039187', '20260903195039188', '20260903195039189', '20260903195039190',
--   '20260903195039191', '20260903195039192', '20260903195039193', '20260903195039194', '20260903195039195', '20260903195039196', '20260903195039197', '20260903195039198', '20260903195039199', '20260903195039200',
--   '20260903195039201', '20260903195039202', '20260903195039203', '20260903195039204', '20260903195039205', '20260903195039206', '20260903195039207', '20260903195039208', '20260903195039209', '20260903195039210',
--   '20260903195039211', '20260903195039212', '20260903212829276', '20260903212829277', '20260903212829278', '20260903212829279', '20260903212829280', '20260903212829281', '20260903212829282', '20260903212829283',
--   '20260903212829284', '20260903212829285', '20260903212829286', '20260903212829287', '20260903212829288', '20260903212829289', '20260903212829290', '20260903212829291', '20260903212829292', '20260904090943308',
--   '20260904090943309', '20260904090943310', '20260904090943311', '20260904090943312', '20260904090943313', '20260904090943314', '20260904090943315', '20260904090943316', '20260904090943317', '20260904090943318',
--   '20260904090943319', '20260904090943320', '20260904090943321', '20260904090943322', '20260904090943323', '20260904090943324', '20260904090943325', '20260904090943326', '2099321043790344193', '2099321043790344194',
--   '2099321043794538498', '2099321043794538499', '2099321043794538500', '2099321043794538501', '2099321043794538502', '2099321043798732802', '2099321043798732803', '2099321043798732804', '2099321043798732805', '2099321043798732806',
--   '2099321043802927105', '2099321043802927106', '2099321043802927107', '2099321043807121410', '2099321043807121411', '2099321043807121412', '2099321043807121413', '2099321043811315714', '2099321043811315715', '2099321043811315716',
--   '2099321043811315717', '2099321043811315718', '2099321043815510017', '2099321043815510018', '2099321043815510019', '2099321043815510020', '2099321043815510021', '2099321043819704322', '2099321043819704323', '2099321043819704324',
--   '2099321043819704325', '2099321043823898625', '2099321043823898626', '2099321043823898627', '2099321043823898628', '2099321043823898629', '2099321043828092929', '2099321043828092930', '2099321043828092931', '2099321043828092932',
--   '2099321043828092933', '2099321043832287234', '2099321043832287235', '2099321043832287236', '2099321043832287237', '2099321043832287238', '2099321043832287239', '2099321043840675841', '2099321043840675842', '2099321043840675843',
--   '2099321043840675844', '2099321043840675845', '2099322942002311170', '2099322942019088385', '2099322942019088386', '2099322942019088387', '2099322942019088388', '2099322942019088389', '2099322942019088390', '2099322942023282689',
--   '2099322942023282690', '2099322942027476993', '2099322942027476994', '2099322942031671297', '2099322942031671298', '2099322942031671299', '2099322942031671300', '2099322942035865602', '2099322942035865603', '2099322942040059906',
--   '2099322942044254209', '2099322942044254210', '2099322942044254211', '2099322942048448513', '2099322942048448514', '2099322942048448515', '2099322942052642818', '2099322942052642819', '2099322942052642820', '2099322942052642821',
--   '2099322942061031426', '2099322942061031427', '2099322942061031428', '2099322942065225730', '2099322942069420033', '2099322942073614337', '2099322942073614338', '2099322942077808642', '2099322942077808643', '2099322942077808644',
--   '2099322942077808645', '2099322942086197250', '2099322942086197251', '2099322942086197252', '2099322942086197253', '2099322942090391554', '2099322942090391555', '2099322942090391556', '2099322942090391557', '2099322942098780161',
--   '2099322942098780162', '2099322942098780163', '2099322942098780164', '2099322942107168769', '2099322942107168770', '2099322942107168771', '2099323827482800130', '2099323827482800131', '2099323827482800132', '2099323827482800133',
--   '2099323827482800134', '2099323827482800135', '2099323827486994434', '2099323827486994435', '2099323827486994436', '2099323827486994437', '2099323827491188738', '2099323827491188739', '2099323827495383041', '2099323827495383042',
--   '2099323827495383043', '2099323827499577346', '2099323827499577347', '2099323827499577348', '2099323827499577349', '2099323827499577350', '2099323827503771650', '2099323827503771651', '2099323827507965954', '2099323827507965955',
--   '2099323827507965956', '2099323827507965957', '2099323827512160258', '2099323827512160259', '2099323827512160260', '2099323827512160261', '2099323827512160262', '2099323827516354561', '2099323827516354562', '2099323827516354563',
--   '2099323827516354564', '2099323827520548866', '2099323827520548867', '2099323827520548868', '2099323827520548869', '2099323827520548870', '2099323827524743170', '2099323827524743171', '2099323827524743172', '2099323827528937473',
--   '2099323827528937474', '2099323827528937475', '2099323827528937476', '2099323827528937477', '2099323827533131777', '2099323827533131778', '2099323827533131779', '2099323827533131780', '2099323827533131781', '2099323827537326082',
--   '2099325805201993730', '2099325805227159553', '2099325805227159554', '2099325805227159555', '2099325805227159556', '2099325805231353858', '2099325805231353859', '2099325805231353860', '2099325805231353861', '2099325805235548162',
--   '2099325805235548163', '2099325805235548164', '2099325805235548165', '2099325805235548166', '2099325805239742466', '2099325805239742467', '2099325805239742468', '2099325805243936770', '2099325805243936771', '2099325805243936772',
--   '2099325805243936773', '2099325805243936774', '2099325805248131073', '2099325805248131074', '2099325805248131075', '2099325805248131076', '2099325805248131077', '2099325805252325377', '2099325805252325378', '2099325805252325379',
--   '2099325805252325380', '2099325805256519681', '2099325805256519682', '2099325805256519683', '2099325805256519684', '2099325805260713986', '2099325805260713987', '2099325805260713988', '2099325805260713989', '2099325805260713990',
--   '2099325805264908289', '2099325805264908290', '2099325805264908291', '2099325805264908292', '2099325805269102594', '2099325805269102595', '2099325805269102596', '2099325805269102597', '2099325805273296897', '2099325805273296898',
--   '2099325805273296899', '2099325805273296900', '2099325805277491202', '2099325805277491203', '2099329306602778626', '2099329306602778627', '2099329306606972930', '2099329306606972931', '2099329306606972932', '2099329306606972933',
--   '2099329306606972934', '2099329306611167233', '2099329306611167234', '2099329306611167235', '2099329306611167236', '2099329306615361537', '2099329306615361538', '2099329306615361539', '2099329306619555842', '2099329306619555843',
--   '2099329306619555844', '2099329306619555845', '2099329306619555846', '2099329306623750146', '2099329306623750147', '2099329306623750148', '2099329306627944449', '2099329306627944450', '2099329306627944451', '2099329306627944452',
--   '2099329306627944453', '2099329306632138754', '2099329306632138755', '2099329306632138756', '2099329306632138757', '2099329306632138758', '2099329306636333058', '2099329306636333059', '2099329306636333060', '2099329306636333061',
--   '2099329306640527362', '2099329306640527363', '2099329306640527364', '2099329306640527365', '2099329306640527366', '2099329306644721665', '2099329306644721666', '2099329306644721667', '2099329306644721668', '2099329306648915969',
--   '2099329306648915970', '2099329306648915971', '2099329306648915972', '2099329306648915973', '2099329306653110274', '2099329306653110275', '2099329306653110276', '2099329306653110277', '2099330308391317506', '2099330308391317507',
--   '2099330308391317508', '2099330308395511809', '2099330308395511810', '2099330308395511811', '2099330308399706114', '2099330308399706115', '2099330308399706116', '2099330308399706117', '2099330308403900417', '2099330308403900418',
--   '2099330308403900419', '2099330308403900420', '2099330308403900421', '2099330308408094721', '2099330308408094722', '2099330308408094723', '2099330308408094724', '2099330308412289025', '2099330308412289026', '2099330308412289027',
--   '2099330308412289028', '2099330308416483329', '2099330308416483330', '2099330308416483331', '2099330308416483332', '2099330308416483333', '2099330308420677634', '2099330308420677635', '2099330308420677636', '2099330308420677637',
--   '2099330308424871938', '2099330308424871939', '2099330308424871940', '2099330308424871941', '2099330308424871942', '2099330308429066241', '2099330308429066242', '2099330308429066243', '2099330308433260545', '2099330308433260546',
--   '2099330308433260547', '2099330308433260548', '2099330308433260549', '2099330308437454849', '2099330308437454850', '2099330308437454851', '2099330308437454852', '2099330308437454853', '2099330308441649154', '2099330308441649155',
--   '2099330308441649156', '2099330308441649157', '2099331486734888961', '2099331486734888962', '2099331486734888963', '2099331486743277569', '2099331486743277570', '2099331486743277571', '2099331486743277572', '2099331486747471873',
--   '2099331486747471874', '2099331486747471875', '2099331486751666177', '2099331486751666178', '2099331486751666179', '2099331486755860482', '2099331486755860483', '2099331486755860484', '2099331486755860485', '2099331486755860486',
--   '2099331486755860487', '2099331486764249089', '2099331486764249090', '2099331486764249091', '2099331486768443393', '2099331486768443394', '2099331486768443395', '2099331486768443396', '2099331486772637697', '2099331486772637698',
--   '2099331486772637699', '2099331486772637700', '2099331486776832001', '2099331486776832002', '2099331486776832003', '2099331486776832004', '2099331486781026306', '2099331486781026307', '2099331486781026308', '2099331486781026309',
--   '2099331486781026310', '2099331486785220609', '2099331486785220610', '2099331486785220611', '2099331486785220612', '2099331486789414913', '2099331486789414914', '2099331486789414915', '2099331486789414916', '2099331486793609218',
--   '2099331486793609219', '2099331486793609220', '2099331486793609221', '2099331486797803522', '2099331486797803523', '2099331486797803524', '2099335716724027394', '2099335716724027395', '2099335716724027396', '2099335716724027397',
--   '2099335716728221697', '2099335716728221698', '2099335716728221699', '2099335716728221700', '2099335716732416002', '2099335716732416003', '2099335716736610305', '2099335716736610306', '2099335716736610307', '2099335716736610308',
--   '2099335716736610309', '2099335716740804610', '2099335716740804611', '2099335716740804612', '2099335716740804613', '2099335716744998914', '2099335716744998915', '2099335716744998916', '2099335716744998917', '2099335716749193217',
--   '2099335716749193218', '2099335716749193219', '2099335716749193220', '2099335716749193221', '2099335716753387521', '2099335716753387522', '2099335716753387523', '2099335716753387524', '2099335716757581825', '2099335716757581826',
--   '2099335716757581827', '2099335716757581828', '2099335716757581829', '2099335716761776130', '2099335716761776131', '2099335716761776132', '2099335716761776133', '2099335716761776134', '2099335716761776135', '2099335716770164738',
--   '2099335716770164739', '2099335716774359041', '2099335716774359042', '2099335716774359043', '2099335716774359044', '2099335716774359045', '2099335716774359046', '2099335716778553345', '2099335716778553346', '2099335716778553347',
--   '2099387837104271362', '2099387837104271363', '2099387837104271364', '2099387837108465666', '2099391513537556482', '2099391513537556483', '2099391513537556484', '2099391513541750785', '2099473094654570497', '2099473094658764802',
--   '2099473094658764803', '2099473094662959105', '2099473094662959106', '2099473094662959107', '2099473094662959108', '2099473094662959109', '2099473094667153409', '2099473094667153410', '2099473094667153411', '2099473094667153412',
--   '2099473094667153413', '2099473094671347714', '2099473094671347715', '2099473094671347716', '2099473094671347717', '2099473094675542018', '2099473094675542019', '2099473094675542020', '2099473094675542021', '2099473094675542022',
--   '2099473094679736322', '2099473094679736323', '2099473094679736324', '2099473094679736325', '2099473094679736326', '2099473094683930626', '2099473094683930627', '2099473094683930628', '2099473094683930629', '2099473094688124929',
--   '2099473094688124930', '2099473094688124931', '2099473094688124932', '2099473094688124933', '2099473094692319233', '2099473094692319234', '2099473094692319235', '2099473094692319236', '2099473094692319237', '2099473094696513538',
--   '2099473094696513539', '2099473094696513540', '2099473094696513541', '2099473094696513542', '2099473094700707841', '2099473094700707842', '2099473094700707843', '2099473094700707844', '2099473094700707845', '2099473094704902146',
--   '2099473094704902147', '2099473094704902148', '2099474228043591681', '2099474228047785986', '2099474228047785987', '2099474228047785988', '2099474228051980290', '2099474228051980291', '2099474228056174593', '2099474228056174594',
--   '2099474228056174595', '2099474228060368897', '2099474228060368898', '2099474228060368899', '2099474228060368900', '2099474228060368901', '2099474228060368902', '2099474228060368903', '2099474228060368904', '2099474228060368905',
--   '2099474228060368906', '2099474228077146114', '2099474228077146115', '2099474228077146116', '2099474228077146117', '2099474228077146118', '2099474228081340417', '2099474228081340418', '2099474228081340419', '2099474228081340420',
--   '2099474228081340421', '2099474228081340422', '2099474228081340423', '2099474228081340424', '2099474228081340425', '2099474228081340426', '2099474228081340427', '2099474228081340428', '2099474228081340429', '2099474228081340430',
--   '2099474228081340431', '2099474228106506241', '2099474228106506242', '2099474228106506243', '2099474228106506244', '2099474228110700546', '2099474228110700547', '2099474228110700548', '2099474228114894849', '2099474228114894850',
--   '2099474228119089153', '2099474228119089154', '2099474228123283458', '2099474228123283459', '2099474228123283460', '2099474228127477761', '2099486550321541121', '2099486550321541122', '2099487507818229762', '2099487507818229763',
--   '2099492014513991681', '2099492014513991682', '2099493652599418883', '2099493652599418884', '2099493932376272899', '2099493932376272900', '2099494367472398339', '2099494367472398340', '20260914194856100', '20260914194856101',
--   '20260914194856102', '20260914194856103', '20260914194856104', '2026091419485692', '2026091419485693', '2026091419485694', '2026091419485695', '2026091419485696', '2026091419485697', '2026091419485698',
--   '2026091419485699', '20260903201033214', '20260903201033215', '20260903201033216', '20260903201033217', '20260903201033218', '20260903201033219', '20260903201033220', '20260903201033221', '20260903201033222',
--   '20260903201033223', '20260903201033224', '20260903201033225', '20260903201033226', '20260903201033227', '20260903201033228', '20260903201033229', '20260903201033230', '20260903201033231', '20260903201033232',
--   '20260903201033233', '20260903201033234', '20260903201033235', '20260903201033236', '20260903201033237', '20260903201033238', '20260903201033239', '20260903201033240', '20260903201033241', '20260903201033242',
--   '20260903201033243', '20260903201033244', '20260903201033245', '20260903201033246', '20260903201033247', '20260903201033248', '20260903201033249', '20260903201033250', '20260903201033251', '20260903201033252',
--   '20260903201033253', '20260903201033254', '20260903201033255', '2026090317121810', '2026090317121811', '2026090317121812', '2026090317121813', '2026090317121814', '2026090317121815', '202609031712182',
--   '202609031712183', '202609031712184', '202609031712185', '202609031712186', '202609031712187', '202609031712188', '202609031712189', '20260904090513294', '20260904090513295', '20260904090513296',
--   '20260904090513297', '20260904090513298', '20260904090513299', '20260904090513300', '20260904090513301', '20260904090513302', '20260904090513303', '20260904090513304', '20260904090513305', '20260904090513306',
--   '2026091114242418', '2026091114242419', '2026091114242420', '2026091114242421', '2026091114242422', '2026091114242423', '2026091114242424', '2026091114242425', '2026091114242426', '2026091114242427',
--   '2026091114242428', '2026091114242429', '2026091114242430', '2026091114242431', '2026091114242432', '2026091114242433', '2026091114242434', '2026091114242435'
-- );

-- =============================================================================
-- 文件结束
-- =============================================================================
