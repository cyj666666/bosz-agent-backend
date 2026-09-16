-- =====================================================================
-- 三个菜单交付包 · 附：贷后报告业务表建表 DDL（45 张）
--
-- 来源：本机 bosz_test 库 bosz_test schema 的**实际结构**（只读导出，非手抄）
-- 生成：D:\dbtool\GenDdl
-- 执行前置：SET search_path = <schema>, public;
--
-- 说明：
--   1) 本组与「三个菜单」的 44 张配置表相互独立，可单独执行；
--   2) 脚本内无外键；表之间可能互相引用数据，重建建议整体执行；
--   3) 列注释取自来源库；来源库缺注释的列由本工程补写（id -> '主键ID'，其余按**同名列既有措辞**），
--      逐列明细见文件末尾《本工程补写的列注释》；
--   4) 自增列按来源库的实际形态写成 BIGINT NOT NULL AUTO_INCREMENT；
--   5) 时间列默认值保留来源库表达式 pg_systimestamp()（PG/openGauss 通用函数）；
--   6) 标识符引用：混合大小写（如 "CONDITION"）与**保留字**（如 group）一律加双引号，
--      否则裸写会被折叠/直接语法错（公司库实测两处）。
--   7) 2026-09-16 结构变更（同事反馈）：`app_reputation_event_info` 新增两列
--      `eventtypecode`（舆情类型编码）/ `eventtypeorder`（舆情事件排序）——见 [35/45]。
--      变更来自开发侧脚本，导出库（公司库）当时**尚未**加这两列，故本文件比公司库多 2 列。
-- =====================================================================

-- ---------------------------------------------------------------
-- [1/45] app_capital_flow_info —— 资金回流/用途异常表
-- ---------------------------------------------------------------
CREATE TABLE app_capital_flow_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    loanserialno                        VARCHAR(64),
    serialno                            VARCHAR(128),
    capitalchecktasktype                VARCHAR(64),
    approvestatus                       VARCHAR(64),
    ispurposeabnormal                   VARCHAR(64),
    rectificationsituation              VARCHAR(128),
    rectificationdeadline               VARCHAR(32),
    rectificationexplanation            TEXT,
    identifyreason                      TEXT,
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    loanstatus                          VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_capital_flow_info IS '资金回流/用途异常表';
COMMENT ON COLUMN app_capital_flow_info.id IS '主键ID';
COMMENT ON COLUMN app_capital_flow_info.reportno IS '报告编号';
COMMENT ON COLUMN app_capital_flow_info.customerid IS '客户编号';
COMMENT ON COLUMN app_capital_flow_info.customername IS '客户名称';
COMMENT ON COLUMN app_capital_flow_info.loanserialno IS '借据号';
COMMENT ON COLUMN app_capital_flow_info.serialno IS '流水号';
COMMENT ON COLUMN app_capital_flow_info.capitalchecktasktype IS '任务类型（码值：资金用途检查任务类型（码值待确认））';
COMMENT ON COLUMN app_capital_flow_info.approvestatus IS '审批状态（码值：审批通过/待审批/驳回（码值待确认））';
COMMENT ON COLUMN app_capital_flow_info.ispurposeabnormal IS '是否回流异常（码值：是/否）';
COMMENT ON COLUMN app_capital_flow_info.rectificationsituation IS '整改情况';
COMMENT ON COLUMN app_capital_flow_info.rectificationdeadline IS '整改期限';
COMMENT ON COLUMN app_capital_flow_info.rectificationexplanation IS '整改情况说明';
COMMENT ON COLUMN app_capital_flow_info.identifyreason IS '认定理由';
COMMENT ON COLUMN app_capital_flow_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_capital_flow_info.loanstatus IS '借据状态）';
CREATE INDEX idx_capital_flow_info_customerid ON app_capital_flow_info (customerid);
CREATE INDEX idx_capital_flow_info_reportno ON app_capital_flow_info (reportno);

-- ---------------------------------------------------------------
-- [2/45] app_check_index_info —— 日常检查综合指标表
-- ---------------------------------------------------------------
CREATE TABLE app_check_index_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    chineseid                           VARCHAR(64),
    chinesename                         VARCHAR(128),
    yesno                               VARCHAR(32),
    remark                              TEXT,
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    indexobject                         VARCHAR(128),
    isabnormal                          VARCHAR(32),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_check_index_info IS '日常检查综合指标表';
COMMENT ON COLUMN app_check_index_info.id IS '主键ID';
COMMENT ON COLUMN app_check_index_info.reportno IS '报告编号';
COMMENT ON COLUMN app_check_index_info.customerid IS '客户编号';
COMMENT ON COLUMN app_check_index_info.customername IS '客户名称';
COMMENT ON COLUMN app_check_index_info.chineseid IS '指标编号';
COMMENT ON COLUMN app_check_index_info.chinesename IS '指标名称';
COMMENT ON COLUMN app_check_index_info.yesno IS '检查结论（是/否）';
COMMENT ON COLUMN app_check_index_info.remark IS '说明';
COMMENT ON COLUMN app_check_index_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_check_index_info.indexobject IS '指标对象';
COMMENT ON COLUMN app_check_index_info.isabnormal IS '是否异常（码值：是/否）';
CREATE INDEX idx_check_index_info_customerid ON app_check_index_info (customerid);
CREATE INDEX idx_check_index_info_reportno ON app_check_index_info (reportno);

-- ---------------------------------------------------------------
-- [3/45] app_check_object_info —— 特定贷款指标检查明细表
-- ---------------------------------------------------------------
CREATE TABLE app_check_object_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    objectname                          VARCHAR(128),
    contractno                          VARCHAR(64),
    indexno                             VARCHAR(64),
    indexname                           VARCHAR(128),
    indextype                           VARCHAR(64),
    indexresult                         TEXT,
    isabnormal                          VARCHAR(32),
    redtextrequire                      TEXT,
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_check_object_info IS '特定贷款指标检查明细表';
COMMENT ON COLUMN app_check_object_info.id IS '主键ID';
COMMENT ON COLUMN app_check_object_info.reportno IS '报告编号';
COMMENT ON COLUMN app_check_object_info.customerid IS '客户编号';
COMMENT ON COLUMN app_check_object_info.customername IS '客户名称';
COMMENT ON COLUMN app_check_object_info.objectname IS '对象名称';
COMMENT ON COLUMN app_check_object_info.contractno IS '业务合同编号';
COMMENT ON COLUMN app_check_object_info.indexno IS '指标编号';
COMMENT ON COLUMN app_check_object_info.indexname IS '指标名称';
COMMENT ON COLUMN app_check_object_info.indextype IS '指标类型';
COMMENT ON COLUMN app_check_object_info.indexresult IS '指标结果';
COMMENT ON COLUMN app_check_object_info.isabnormal IS '是否异常（码值：是/否/提示）';
COMMENT ON COLUMN app_check_object_info.redtextrequire IS '红字要求';
COMMENT ON COLUMN app_check_object_info.inputtime IS '入库时间';
CREATE INDEX idx_check_object_info_customerid ON app_check_object_info (customerid);
CREATE INDEX idx_check_object_info_reportno ON app_check_object_info (reportno);

-- ---------------------------------------------------------------
-- [4/45] app_check_opinion_info —— 批复后续管理要求表
-- ---------------------------------------------------------------
CREATE TABLE app_check_opinion_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    conditiondesc                       TEXT,
    completestatus                      VARCHAR(64),
    conditioninstruction                TEXT,
    realcompletetime                    VARCHAR(32),
    itemcategory                        VARCHAR(64),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_check_opinion_info IS '批复后续管理要求表';
COMMENT ON COLUMN app_check_opinion_info.id IS '主键ID';
COMMENT ON COLUMN app_check_opinion_info.reportno IS '报告编号';
COMMENT ON COLUMN app_check_opinion_info.customerid IS '客户编号';
COMMENT ON COLUMN app_check_opinion_info.customername IS '客户名称';
COMMENT ON COLUMN app_check_opinion_info.conditiondesc IS '批复后续管理要求';
COMMENT ON COLUMN app_check_opinion_info.completestatus IS '完成情况（码值：已完成/未完成/部分完成/持续关注，码值待确认）';
COMMENT ON COLUMN app_check_opinion_info.conditioninstruction IS '情况说明';
COMMENT ON COLUMN app_check_opinion_info.realcompletetime IS '实际完成日期';
COMMENT ON COLUMN app_check_opinion_info.itemcategory IS '事项类别';
COMMENT ON COLUMN app_check_opinion_info.inputtime IS '入库时间';
CREATE INDEX idx_check_opinion_info_customerid ON app_check_opinion_info (customerid);
CREATE INDEX idx_check_opinion_info_reportno ON app_check_opinion_info (reportno);

-- ---------------------------------------------------------------
-- [5/45] app_check_record_info —— 现场检查打卡记录表
-- ---------------------------------------------------------------
CREATE TABLE app_check_record_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    checkintime                         VARCHAR(32),
    checkinaddress                      VARCHAR(256),
    visitobj                            VARCHAR(128),
    checkinobj                          VARCHAR(128),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_check_record_info IS '现场检查打卡记录表';
COMMENT ON COLUMN app_check_record_info.id IS '主键ID';
COMMENT ON COLUMN app_check_record_info.reportno IS '报告编号';
COMMENT ON COLUMN app_check_record_info.customerid IS '客户编号';
COMMENT ON COLUMN app_check_record_info.customername IS '客户名称';
COMMENT ON COLUMN app_check_record_info.checkintime IS '打卡日期';
COMMENT ON COLUMN app_check_record_info.checkinaddress IS '打卡地址';
COMMENT ON COLUMN app_check_record_info.visitobj IS '拜访对象';
COMMENT ON COLUMN app_check_record_info.checkinobj IS '打卡对象';
COMMENT ON COLUMN app_check_record_info.inputtime IS '入库时间';
CREATE INDEX idx_check_record_info_customerid ON app_check_record_info (customerid);
CREATE INDEX idx_check_record_info_reportno ON app_check_record_info (reportno);

-- ---------------------------------------------------------------
-- [6/45] app_collateral_info —— 押品主档表
-- ---------------------------------------------------------------
CREATE TABLE app_collateral_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    owner                               VARCHAR(128),
    clrtype                             VARCHAR(64),
    clrname                             VARCHAR(128),
    clrstatus                           VARCHAR(64),
    valuationdate                       VARCHAR(32),
    choicetypename                      VARCHAR(64),
    evaluatevalue                       DECIMAL(18,2),
    rightorder                          VARCHAR(64),
    rightsum                            DECIMAL(18,2),
    confirmdate                         VARCHAR(32),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    clrid                               VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_collateral_info IS '押品主档表';
COMMENT ON COLUMN app_collateral_info.id IS '主键ID';
COMMENT ON COLUMN app_collateral_info.reportno IS '报告编号';
COMMENT ON COLUMN app_collateral_info.customerid IS '客户编号';
COMMENT ON COLUMN app_collateral_info.customername IS '客户名称';
COMMENT ON COLUMN app_collateral_info.owner IS '权属人';
COMMENT ON COLUMN app_collateral_info.clrtype IS '押品类型（码值：不动产/动产/权利类等，码值待确认）';
COMMENT ON COLUMN app_collateral_info.clrname IS '押品名称';
COMMENT ON COLUMN app_collateral_info.clrstatus IS '押品状态（码值：正常/查封/冻结/处置中，码值待确认）';
COMMENT ON COLUMN app_collateral_info.valuationdate IS '押品最新评估日期';
COMMENT ON COLUMN app_collateral_info.choicetypename IS '评估方式（评估价/协议作价）';
COMMENT ON COLUMN app_collateral_info.evaluatevalue IS '评估价值（万元）';
COMMENT ON COLUMN app_collateral_info.rightorder IS '顺位';
COMMENT ON COLUMN app_collateral_info.rightsum IS '权证金额（万元）';
COMMENT ON COLUMN app_collateral_info.confirmdate IS '认定日期';
COMMENT ON COLUMN app_collateral_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_collateral_info.clrid IS '押品编号';
CREATE INDEX idx_collateral_info_clrid ON app_collateral_info (clrid);
CREATE INDEX idx_collateral_info_customerid ON app_collateral_info (customerid);
CREATE INDEX idx_collateral_info_reportno ON app_collateral_info (reportno);

-- ---------------------------------------------------------------
-- [7/45] app_collateral_mortgage_info —— 押品他项权利/限制权利表
-- ---------------------------------------------------------------
CREATE TABLE app_collateral_mortgage_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    clrname                             VARCHAR(128),
    pledgeserialno                      VARCHAR(64),
    pledgeename                         VARCHAR(128),
    guaranteescope                      VARCHAR(256),
    pledgetypename                      VARCHAR(64),
    maxcreditoramt                      DECIMAL(18,2),
    startend                            VARCHAR(64),
    registertimestamp                   VARCHAR(32),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    clrid                               VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_collateral_mortgage_info IS '押品他项权利/限制权利表';
COMMENT ON COLUMN app_collateral_mortgage_info.id IS '主键ID';
COMMENT ON COLUMN app_collateral_mortgage_info.reportno IS '报告编号';
COMMENT ON COLUMN app_collateral_mortgage_info.customerid IS '客户编号';
COMMENT ON COLUMN app_collateral_mortgage_info.customername IS '客户名称';
COMMENT ON COLUMN app_collateral_mortgage_info.clrname IS '关联押品名称';
COMMENT ON COLUMN app_collateral_mortgage_info.pledgeserialno IS '不动产登记编号';
COMMENT ON COLUMN app_collateral_mortgage_info.pledgeename IS '他项权姓名';
COMMENT ON COLUMN app_collateral_mortgage_info.guaranteescope IS '担保范围';
COMMENT ON COLUMN app_collateral_mortgage_info.pledgetypename IS '抵押方式（码值：一般抵押/最高额抵押等，码值待确认）';
COMMENT ON COLUMN app_collateral_mortgage_info.maxcreditoramt IS '债权数额（万元）';
COMMENT ON COLUMN app_collateral_mortgage_info.startend IS '债务履行期限';
COMMENT ON COLUMN app_collateral_mortgage_info.registertimestamp IS '设定日期';
COMMENT ON COLUMN app_collateral_mortgage_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_collateral_mortgage_info.clrid IS '押品编号（关联 app_collateral_info.clrId）';
CREATE INDEX idx_collateral_mortgage_info_clrid ON app_collateral_mortgage_info (clrid);
CREATE INDEX idx_collateral_mortgage_info_customerid ON app_collateral_mortgage_info (customerid);
CREATE INDEX idx_collateral_mortgage_info_reportno ON app_collateral_mortgage_info (reportno);

-- ---------------------------------------------------------------
-- [8/45] app_collateral_restricted_right —— 押品限制权利表
-- ---------------------------------------------------------------
CREATE TABLE app_collateral_restricted_right (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    attachmentorg                       VARCHAR(128),
    attachmenttypename                  VARCHAR(64),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    clrid                               VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_collateral_restricted_right IS '押品限制权利表';
COMMENT ON COLUMN app_collateral_restricted_right.id IS '主键ID';
COMMENT ON COLUMN app_collateral_restricted_right.reportno IS '报告编号';
COMMENT ON COLUMN app_collateral_restricted_right.customerid IS '客户编号';
COMMENT ON COLUMN app_collateral_restricted_right.customername IS '客户名称';
COMMENT ON COLUMN app_collateral_restricted_right.attachmentorg IS '限制权人';
COMMENT ON COLUMN app_collateral_restricted_right.attachmenttypename IS '查封类型（码值：轮候查封/正式查封等，码值待确认）';
COMMENT ON COLUMN app_collateral_restricted_right.inputtime IS '入库时间';
COMMENT ON COLUMN app_collateral_restricted_right.clrid IS '押品编号（关联 app_collateral_info.clrId）';
CREATE INDEX idx_collateral_restricted_right_clrid ON app_collateral_restricted_right (clrid);
CREATE INDEX idx_collateral_restricted_right_customerid ON app_collateral_restricted_right (customerid);
CREATE INDEX idx_collateral_restricted_right_reportno ON app_collateral_restricted_right (reportno);

-- ---------------------------------------------------------------
-- [9/45] app_credit_approval_manage_req_info —— 授信批复管理要求表
-- ---------------------------------------------------------------
CREATE TABLE app_credit_approval_manage_req_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(255),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp() NOT NULL,
    swqno                               VARCHAR(32),
    "CONDITION"                         TEXT,
    pelativeserialno                    VARCHAR(64),
    checkdate                           DATE,
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_credit_approval_manage_req_info IS '授信批复管理要求表';
COMMENT ON COLUMN app_credit_approval_manage_req_info.id IS 'id';
COMMENT ON COLUMN app_credit_approval_manage_req_info.reportno IS '报告编号';
COMMENT ON COLUMN app_credit_approval_manage_req_info.customerid IS '客户编号';
COMMENT ON COLUMN app_credit_approval_manage_req_info.customername IS '客户名称';
COMMENT ON COLUMN app_credit_approval_manage_req_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_credit_approval_manage_req_info.swqno IS '序号';
COMMENT ON COLUMN app_credit_approval_manage_req_info."CONDITION" IS '批复后续管理要求';
COMMENT ON COLUMN app_credit_approval_manage_req_info.pelativeserialno IS '对象';
COMMENT ON COLUMN app_credit_approval_manage_req_info.checkdate IS '检查时间';
CREATE INDEX idx_credit_approval_manage_req_customerid ON app_credit_approval_manage_req_info (customerid);
CREATE INDEX idx_credit_approval_manage_req_reportno ON app_credit_approval_manage_req_info (reportno);

-- ---------------------------------------------------------------
-- [10/45] app_credit_debt_detail —— 征信债务明细表（按类型一期一行）
-- ---------------------------------------------------------------
CREATE TABLE app_credit_debt_detail (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    querytime                           VARCHAR(32),
    zxreportno                          VARCHAR(128),
    debttype                            VARCHAR(64),
    orgcount                            INT,
    balance                             DECIMAL(18,2),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    subjecttype                         VARCHAR(64),
    guarantorid                         VARCHAR(64),
    guarantorname                       VARCHAR(128),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_credit_debt_detail IS '征信债务明细表（按类型一期一行）';
COMMENT ON COLUMN app_credit_debt_detail.id IS '主键ID';
COMMENT ON COLUMN app_credit_debt_detail.reportno IS '报告编号';
COMMENT ON COLUMN app_credit_debt_detail.customerid IS '客户编号';
COMMENT ON COLUMN app_credit_debt_detail.customername IS '客户名称';
COMMENT ON COLUMN app_credit_debt_detail.querytime IS '征信查询时间';
COMMENT ON COLUMN app_credit_debt_detail.zxreportno IS '征信报告记录号';
COMMENT ON COLUMN app_credit_debt_detail.debttype IS '债务类型（中长期借款/短期借款/循环透支/贴现/银行承兑汇票/信用证/银行保函/其他担保交易）';
COMMENT ON COLUMN app_credit_debt_detail.orgcount IS '未结清机构数合计';
COMMENT ON COLUMN app_credit_debt_detail.balance IS '未结清余额合计（万元）';
COMMENT ON COLUMN app_credit_debt_detail.inputtime IS '入库时间';
COMMENT ON COLUMN app_credit_debt_detail.subjecttype IS '主体类型（码值：借款人/担保人）';
COMMENT ON COLUMN app_credit_debt_detail.guarantorid IS '担保人客户编号（subjectType=担保人时填写）';
COMMENT ON COLUMN app_credit_debt_detail.guarantorname IS '担保人名称（subjectType=担保人时填写）';
CREATE INDEX idx_credit_debt_detail_customerid ON app_credit_debt_detail (customerid);
CREATE INDEX idx_credit_debt_detail_debttype ON app_credit_debt_detail (debttype);
CREATE INDEX idx_credit_debt_detail_reportno ON app_credit_debt_detail (reportno);

-- ---------------------------------------------------------------
-- [11/45] app_credit_query_info —— 征信查询次数表
-- ---------------------------------------------------------------
CREATE TABLE app_credit_query_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    querytime                           VARCHAR(32),
    zxreportno                          VARCHAR(128),
    loanquery12m                        INT,
    loanquery6m                         INT,
    loanquery3m                         INT,
    cardquery12m                        INT,
    cardquery6m                         INT,
    cardquery3m                         INT,
    selfquery1m                         INT,
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    guarantorid                         VARCHAR(64),
    guarantorname                       VARCHAR(128),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_credit_query_info IS '征信查询次数表';
COMMENT ON COLUMN app_credit_query_info.id IS '主键ID';
COMMENT ON COLUMN app_credit_query_info.reportno IS '报告编号';
COMMENT ON COLUMN app_credit_query_info.customerid IS '客户编号';
COMMENT ON COLUMN app_credit_query_info.customername IS '客户名称';
COMMENT ON COLUMN app_credit_query_info.querytime IS '征信查询时间';
COMMENT ON COLUMN app_credit_query_info.zxreportno IS '征信报告记录号';
COMMENT ON COLUMN app_credit_query_info.loanquery12m IS '近一年贷款审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.loanquery6m IS '近6个月贷款审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.loanquery3m IS '近3个月贷款审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.cardquery12m IS '近一年信用卡审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.cardquery6m IS '近6个月信用卡审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.cardquery3m IS '近3个月信用卡审批征信查询次数';
COMMENT ON COLUMN app_credit_query_info.selfquery1m IS '近1个月本人查询征信查询次数';
COMMENT ON COLUMN app_credit_query_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_credit_query_info.guarantorid IS '担保人客户编号';
COMMENT ON COLUMN app_credit_query_info.guarantorname IS '担保人名称';
CREATE INDEX idx_credit_query_info_customerid ON app_credit_query_info (customerid);
CREATE INDEX idx_credit_query_info_reportno ON app_credit_query_info (reportno);

-- ---------------------------------------------------------------
-- [12/45] app_credit_report_info —— 企业征信快照表（一期一行）
-- ---------------------------------------------------------------
CREATE TABLE app_credit_report_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    querytime                           VARCHAR(32),
    zxreportno                          VARCHAR(128),
    expiredate                          VARCHAR(32),
    overduetotal                        DECIMAL(18,2),
    attentioncreditbal                  DECIMAL(18,2),
    badcreditbal                        DECIMAL(18,2),
    attentionguaranteebal               DECIMAL(18,2),
    badguaranteebal                     DECIMAL(18,2),
    guaranteeoverduetotal               DECIMAL(18,2),
    guaranteeattentionbal               DECIMAL(18,2),
    guaranteebadbal                     DECIMAL(18,2),
    extenddebtbal                       DECIMAL(18,2),
    restructuredebtbal                  DECIMAL(18,2),
    renewdebtbal                        DECIMAL(18,2),
    transferdebtbal                     DECIMAL(18,2),
    newolddebtbal                       DECIMAL(18,2),
    nonbankliabtotal                    DECIMAL(18,2),
    nonbankhighrateloan                 DECIMAL(12,4),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    subjecttype                         VARCHAR(64),
    guarantorid                         VARCHAR(64),
    guarantorname                       VARCHAR(128),
    nonbankguaranteebal                 DECIMAL(18,2),
    workingcapitalloanbal               DECIMAL(18,2),
    workingcapitalloan1ybal             DECIMAL(18,2),
    loanbankorgcount                    INT,
    guaranteebankorgcount               INT,
    creditshorttermdiff                 DECIMAL(18,2),
    creditlongtermdiff                  DECIMAL(18,2),
    creditdebtdeviation                 DECIMAL(12,4),
    guaranteenetasset                   DECIMAL(12,4),
    guaranteebalanceexbank              DECIMAL(18,2),
    shorttermloanorgcount               INT,
    midlongtermloanorgcount             INT,
    revolvingoverdraftorgcount          INT,
    discountorgcount                    INT,
    bankacceptancebillorgcount          INT,
    letterofcreditorgcount              INT,
    bankguaranteeorgcount               INT,
    otherguaranteetradeorgcount         INT,
    shorttermloanbal                    DECIMAL(18,2),
    midlongtermloanbal                  DECIMAL(18,2),
    revolvingoverdraftbal               DECIMAL(18,2),
    discountbal                         DECIMAL(18,2),
    bankacceptancebillbal               DECIMAL(18,2),
    letterofcreditbal                   DECIMAL(18,2),
    bankguaranteebal                    DECIMAL(18,2),
    otherguaranteetradebal              DECIMAL(18,2),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_credit_report_info IS '企业征信快照表（一期一行）';
COMMENT ON COLUMN app_credit_report_info.id IS '主键ID';
COMMENT ON COLUMN app_credit_report_info.reportno IS '报告编号';
COMMENT ON COLUMN app_credit_report_info.customerid IS '客户编号';
COMMENT ON COLUMN app_credit_report_info.customername IS '客户名称';
COMMENT ON COLUMN app_credit_report_info.querytime IS '征信查询时间';
COMMENT ON COLUMN app_credit_report_info.zxreportno IS '征信报告记录号';
COMMENT ON COLUMN app_credit_report_info.expiredate IS '征信报告有效期';
COMMENT ON COLUMN app_credit_report_info.overduetotal IS '未结清信贷的逾期总额（万元）';
COMMENT ON COLUMN app_credit_report_info.attentioncreditbal IS '未结清关注类信贷余额（万元）';
COMMENT ON COLUMN app_credit_report_info.badcreditbal IS '未结清不良类借贷余额（万元）';
COMMENT ON COLUMN app_credit_report_info.attentionguaranteebal IS '未结清关注类担保交易余额（万元）';
COMMENT ON COLUMN app_credit_report_info.badguaranteebal IS '未结清不良类担保交易余额（万元）';
COMMENT ON COLUMN app_credit_report_info.guaranteeoverduetotal IS '对外担保（相关还款责任）未结清逾期类负债总额（万元）';
COMMENT ON COLUMN app_credit_report_info.guaranteeattentionbal IS '对外担保（相关还款责任）未结清关注类负债总额（万元）';
COMMENT ON COLUMN app_credit_report_info.guaranteebadbal IS '对外担保（相关还款责任）未结清不良类负债总额（万元）';
COMMENT ON COLUMN app_credit_report_info.extenddebtbal IS '展期债务未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.restructuredebtbal IS '重组债务未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.renewdebtbal IS '无还本续贷未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.transferdebtbal IS '其他机构转入未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.newolddebtbal IS '借新还旧债务未结清余额（万元）';
COMMENT ON COLUMN app_credit_report_info.nonbankliabtotal IS '在非银机构负债合计（万元，上游直给：qy_fyjg_liab_tot/gr_fyjg_liab_tot）';
COMMENT ON COLUMN app_credit_report_info.nonbankhighrateloan IS '非银机构较高利率借款推算利率最大值（%，企业，上游直给：qy_fyjg_gjlv_loan_max；较高利率判断依据）';
COMMENT ON COLUMN app_credit_report_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_credit_report_info.subjecttype IS '主体类型（码值：借款人/担保人）';
COMMENT ON COLUMN app_credit_report_info.guarantorid IS '担保人客户编号（subjectType=担保人时填写）';
COMMENT ON COLUMN app_credit_report_info.guarantorname IS '担保人名称（subjectType=担保人时填写）';
COMMENT ON COLUMN app_credit_report_info.nonbankguaranteebal IS '在非银机构对外担保余额（万元，上游直给：qy_fyjg_dwdb_bal）';
COMMENT ON COLUMN app_credit_report_info.workingcapitalloanbal IS '流动资金贷款余额（万元，上游直给：qy_zhint_wjq_xyldk_bal）';
COMMENT ON COLUMN app_credit_report_info.workingcapitalloan1ybal IS '一年期以下的流动资金贷款余额（万元，上游直给：qy_zhint_wjq_xyldk_1year_bal）';
COMMENT ON COLUMN app_credit_report_info.loanbankorgcount IS '企业借贷交易合作银行及融资租赁机构数（上游直给：qy_jiedai_hzyh_org_cnt）';
COMMENT ON COLUMN app_credit_report_info.guaranteebankorgcount IS '企业担保交易合作银行及融资租赁机构数（上游直给：qy_danbao_hzyh_org_cnt）';
COMMENT ON COLUMN app_credit_report_info.creditshorttermdiff IS '征信短期借款未结清余额与财报短期借款相差（万元，加工结果默认已有）';
COMMENT ON COLUMN app_credit_report_info.creditlongtermdiff IS '征信中长期借款未结清余额与财报长期借款（含一年内到期的长期借款）相差（万元，加工结果默认已有）';
COMMENT ON COLUMN app_credit_report_info.creditdebtdeviation IS '征信债务与财报债务偏离度（%，加工结果默认已有）';
COMMENT ON COLUMN app_credit_report_info.guaranteenetasset IS '对外担保/净资产（%）';
COMMENT ON COLUMN app_credit_report_info.guaranteebalanceexbank IS '对外担保（相关还款责任）余额（剔除我行）（万元，上游直给：qy_dwdb_bal_exc_wx）';
COMMENT ON COLUMN app_credit_report_info.shorttermloanorgcount IS '短期借款未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.midlongtermloanorgcount IS '中长期借款未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.revolvingoverdraftorgcount IS '循环透支未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.discountorgcount IS '贴现未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.bankacceptancebillorgcount IS '银行承兑汇票未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.letterofcreditorgcount IS '信用证未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.bankguaranteeorgcount IS '银行保函未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.otherguaranteetradeorgcount IS '其他担保交易未结清机构数合计（2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.shorttermloanbal IS '短期借款未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.midlongtermloanbal IS '中长期借款未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.revolvingoverdraftbal IS '循环透支未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.discountbal IS '贴现未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.bankacceptancebillbal IS '银行承兑汇票未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.letterofcreditbal IS '信用证未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.bankguaranteebal IS '银行保函未结清余额合计（万元，2026-09-03 新增）';
COMMENT ON COLUMN app_credit_report_info.otherguaranteetradebal IS '其他担保交易未结清余额合计（万元，2026-09-03 新增）';
CREATE INDEX idx_credit_report_info_customerid ON app_credit_report_info (customerid);
CREATE INDEX idx_credit_report_info_reportno ON app_credit_report_info (reportno);

-- ---------------------------------------------------------------
-- [13/45] app_credit_use_info —— 授信用信概况表
-- ---------------------------------------------------------------
CREATE TABLE app_credit_use_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    creditsum                           DECIMAL(18,2),
    balance                             DECIMAL(18,2),
    exposureamount                      DECIMAL(18,2),
    limitbalance                        DECIMAL(18,2),
    groupamount                         DECIMAL(18,2),
    groupbalance                        DECIMAL(18,2),
    isgroup                             VARCHAR(32),
    groupname                           VARCHAR(128),
    creditdate                          VARCHAR(32),
    latestoverduedate                   VARCHAR(32),
    gdoverduecounts                     INT,
    ajoverduecounts                     INT,
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_credit_use_info IS '授信用信概况表';
COMMENT ON COLUMN app_credit_use_info.id IS '主键ID';
COMMENT ON COLUMN app_credit_use_info.reportno IS '报告编号';
COMMENT ON COLUMN app_credit_use_info.customerid IS '客户编号';
COMMENT ON COLUMN app_credit_use_info.customername IS '客户名称';
COMMENT ON COLUMN app_credit_use_info.creditsum IS '授信金额（万元）';
COMMENT ON COLUMN app_credit_use_info.balance IS '总余额（万元）';
COMMENT ON COLUMN app_credit_use_info.exposureamount IS '敞口金额（万元）';
COMMENT ON COLUMN app_credit_use_info.limitbalance IS '敞口余额（万元）';
COMMENT ON COLUMN app_credit_use_info.groupamount IS '集团授信金额（万元）';
COMMENT ON COLUMN app_credit_use_info.groupbalance IS '集团总余额（万元）';
COMMENT ON COLUMN app_credit_use_info.isgroup IS '是否集团客户（码值：是/否）';
COMMENT ON COLUMN app_credit_use_info.groupname IS '所属集团名称';
COMMENT ON COLUMN app_credit_use_info.creditdate IS '授信日期（授信时点，用于反查报表期）';
COMMENT ON COLUMN app_credit_use_info.latestoverduedate IS '企业当前最近一次逾期日期';
COMMENT ON COLUMN app_credit_use_info.gdoverduecounts IS '固贷产品近一年历史逾期次数';
COMMENT ON COLUMN app_credit_use_info.ajoverduecounts IS '按揭贷款产品近一年历史逾期次数（房开贷暂取此值，待确认）';
COMMENT ON COLUMN app_credit_use_info.inputtime IS '入库时间';
CREATE INDEX idx_credit_use_info_customerid ON app_credit_use_info (customerid);
CREATE INDEX idx_credit_use_info_reportno ON app_credit_use_info (reportno);

-- ---------------------------------------------------------------
-- [14/45] app_customer_info —— 客户工商概况表
-- ---------------------------------------------------------------
CREATE TABLE app_customer_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    legalperson                         VARCHAR(128),
    registercapital                     DECIMAL(18,2),
    paidincapital                       DECIMAL(18,2),
    industrytype                        VARCHAR(64),
    holdtype                            VARCHAR(64),
    actualcontroller                    VARCHAR(128),
    officeaddress                       VARCHAR(256),
    businessscope                       TEXT,
    dangerlevel                         VARCHAR(64),
    warninglevel                        VARCHAR(64),
    isstateowned                        VARCHAR(64),
    islistedcompany                     VARCHAR(32),
    groupname                           VARCHAR(128),
    istechcompany                       VARCHAR(64),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_customer_info IS '客户工商概况表';
COMMENT ON COLUMN app_customer_info.id IS '主键ID';
COMMENT ON COLUMN app_customer_info.reportno IS '报告编号';
COMMENT ON COLUMN app_customer_info.customerid IS '客户编号';
COMMENT ON COLUMN app_customer_info.customername IS '客户名称';
COMMENT ON COLUMN app_customer_info.legalperson IS '法定代表人';
COMMENT ON COLUMN app_customer_info.registercapital IS '注册资本（万元）';
COMMENT ON COLUMN app_customer_info.paidincapital IS '实收资本（万元）';
COMMENT ON COLUMN app_customer_info.industrytype IS '行业分类（码值：GB/T 4754 行业代码，码值待确认）';
COMMENT ON COLUMN app_customer_info.holdtype IS '控股类型（码值：国有绝对控股/国有相对控股/集体绝对控股/集体相对控股/民营/个人绝对控股，码值待确认）';
COMMENT ON COLUMN app_customer_info.actualcontroller IS '实际控制人';
COMMENT ON COLUMN app_customer_info.officeaddress IS '办公地址';
COMMENT ON COLUMN app_customer_info.businessscope IS '经营范围';
COMMENT ON COLUMN app_customer_info.dangerlevel IS '十级分类（码值：银行十级分类（1-4正常/5-6关注/7-8次级可疑/9-10损失，具体码值待确认））';
COMMENT ON COLUMN app_customer_info.warninglevel IS '预警等级（码值：高/中/低/黄色预警，码值待确认）';
COMMENT ON COLUMN app_customer_info.isstateowned IS '是否国资/国有担保（码值：是/否（由控股类型holdType判断））';
COMMENT ON COLUMN app_customer_info.islistedcompany IS '借款人是否上市公司（码值：是/否，中台接口）';
COMMENT ON COLUMN app_customer_info.groupname IS '所属集团名称';
COMMENT ON COLUMN app_customer_info.istechcompany IS '是否科创企业（码值：是/否）';
COMMENT ON COLUMN app_customer_info.inputtime IS '入库时间';
CREATE INDEX idx_customer_info_customerid ON app_customer_info (customerid);
CREATE INDEX idx_customer_info_reportno ON app_customer_info (reportno);

-- ---------------------------------------------------------------
-- [15/45] app_early_warning_info —— 预警任务台账表
-- ---------------------------------------------------------------
CREATE TABLE app_early_warning_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    confirmtime                         VARCHAR(32),
    inputdate                           VARCHAR(32),
    approvestatusname                   VARCHAR(64),
    phaseopinion                        TEXT,
    endtime                             VARCHAR(32),
    risktasktype                        VARCHAR(64),
    tasktype                            VARCHAR(64),
    warnlevel                           VARCHAR(64),
    riskreason                          TEXT,
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    serialno                            VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_early_warning_info IS '预警任务台账表';
COMMENT ON COLUMN app_early_warning_info.id IS '主键ID';
COMMENT ON COLUMN app_early_warning_info.reportno IS '报告编号';
COMMENT ON COLUMN app_early_warning_info.customerid IS '客户编号';
COMMENT ON COLUMN app_early_warning_info.customername IS '客户名称';
COMMENT ON COLUMN app_early_warning_info.confirmtime IS '预警本次认定时间';
COMMENT ON COLUMN app_early_warning_info.inputdate IS '预警本次发起时间';
COMMENT ON COLUMN app_early_warning_info.approvestatusname IS '审批状态（码值：审批通过/待审批/驳回（码值待确认））';
COMMENT ON COLUMN app_early_warning_info.phaseopinion IS '审批意见';
COMMENT ON COLUMN app_early_warning_info.endtime IS '审批日期';
COMMENT ON COLUMN app_early_warning_info.risktasktype IS '任务类型（码值：预警任务类型（码值待确认））';
COMMENT ON COLUMN app_early_warning_info.tasktype IS '任务类型（审批通过预警任务、最近一条预警任务）';
COMMENT ON COLUMN app_early_warning_info.warnlevel IS '客户风险等级（码值：高/中/低，码值待确认）';
COMMENT ON COLUMN app_early_warning_info.riskreason IS '风险原因';
COMMENT ON COLUMN app_early_warning_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_early_warning_info.serialno IS '预警任务流水号';
CREATE INDEX idx_early_warning_info_customerid ON app_early_warning_info (customerid);
CREATE INDEX idx_early_warning_info_reportno ON app_early_warning_info (reportno);

-- ---------------------------------------------------------------
-- [16/45] app_early_warning_opinion_info —— 预警意见表
-- ---------------------------------------------------------------
CREATE TABLE app_early_warning_opinion_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    serialno                            VARCHAR(64),
    confirmtime                         VARCHAR(32),
    seqno                               INT,
    activename                          VARCHAR(64),
    approveusername                     VARCHAR(64),
    approveorgname                      VARCHAR(128),
    warninglevelname                    VARCHAR(64),
    phaseopinion                        TEXT,
    endtime                             VARCHAR(32),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_early_warning_opinion_info IS '预警意见表';
COMMENT ON COLUMN app_early_warning_opinion_info.id IS '主键ID';
COMMENT ON COLUMN app_early_warning_opinion_info.reportno IS '报告编号';
COMMENT ON COLUMN app_early_warning_opinion_info.customerid IS '客户编号';
COMMENT ON COLUMN app_early_warning_opinion_info.customername IS '客户名称';
COMMENT ON COLUMN app_early_warning_opinion_info.serialno IS '预警任务流水号';
COMMENT ON COLUMN app_early_warning_opinion_info.confirmtime IS '预警本次认定时间';
COMMENT ON COLUMN app_early_warning_opinion_info.seqno IS '序号';
COMMENT ON COLUMN app_early_warning_opinion_info.activename IS '审批阶段';
COMMENT ON COLUMN app_early_warning_opinion_info.approveusername IS '审批人';
COMMENT ON COLUMN app_early_warning_opinion_info.approveorgname IS '所属机构';
COMMENT ON COLUMN app_early_warning_opinion_info.warninglevelname IS '认定等级';
COMMENT ON COLUMN app_early_warning_opinion_info.phaseopinion IS '审批意见';
COMMENT ON COLUMN app_early_warning_opinion_info.endtime IS '审批日';
COMMENT ON COLUMN app_early_warning_opinion_info.inputtime IS '入库时间';
CREATE INDEX idx_early_warning_opinion_info_customerid ON app_early_warning_opinion_info (customerid);
CREATE INDEX idx_early_warning_opinion_info_reportno ON app_early_warning_opinion_info (reportno);

-- ---------------------------------------------------------------
-- [17/45] app_early_warning_signal_info —— 预警信号明细表
-- ---------------------------------------------------------------
CREATE TABLE app_early_warning_signal_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    serialno                            VARCHAR(64),
    riskmessage                         VARCHAR(500),
    count                               INT,
    readycount                          INT,
    status                              VARCHAR(64),
    warninglevel                        VARCHAR(64),
    inputdate                           VARCHAR(64),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_early_warning_signal_info IS '预警信号明细表';
COMMENT ON COLUMN app_early_warning_signal_info.id IS '主键ID';
COMMENT ON COLUMN app_early_warning_signal_info.reportno IS '报告编号';
COMMENT ON COLUMN app_early_warning_signal_info.customerid IS '客户编号';
COMMENT ON COLUMN app_early_warning_signal_info.customername IS '客户名称';
COMMENT ON COLUMN app_early_warning_signal_info.serialno IS '预警编号（近一年预警台账接口serialNo）';
COMMENT ON COLUMN app_early_warning_signal_info.riskmessage IS '风险原因';
COMMENT ON COLUMN app_early_warning_signal_info.count IS '数量';
COMMENT ON COLUMN app_early_warning_signal_info.readycount IS '待填写数量';
COMMENT ON COLUMN app_early_warning_signal_info.status IS '信号状态（近一年预警台账接口status）';
COMMENT ON COLUMN app_early_warning_signal_info.warninglevel IS '预警信号风险等级（接口warningLevel）';
COMMENT ON COLUMN app_early_warning_signal_info.inputdate IS '信号建立时间（接口inputDate）';
COMMENT ON COLUMN app_early_warning_signal_info.inputtime IS '入库时间';
CREATE INDEX idx_early_warning_signal_info_customerid ON app_early_warning_signal_info (customerid);
CREATE INDEX idx_early_warning_signal_info_reportno ON app_early_warning_signal_info (reportno);

-- ---------------------------------------------------------------
-- [18/45] app_entrust_pay_info —— 受托支付明细表
-- ---------------------------------------------------------------
CREATE TABLE app_entrust_pay_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    paymentmode                         VARCHAR(64),
    paydate                             VARCHAR(32),
    accountname                         VARCHAR(128),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    payeecanceldate                     VARCHAR(32),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_entrust_pay_info IS '受托支付明细表';
COMMENT ON COLUMN app_entrust_pay_info.id IS '主键ID';
COMMENT ON COLUMN app_entrust_pay_info.reportno IS '报告编号';
COMMENT ON COLUMN app_entrust_pay_info.customerid IS '客户编号';
COMMENT ON COLUMN app_entrust_pay_info.customername IS '客户名称';
COMMENT ON COLUMN app_entrust_pay_info.paymentmode IS '支付方式（码值：受托支付/自主支付，码值待确认）';
COMMENT ON COLUMN app_entrust_pay_info.paydate IS '支付日期';
COMMENT ON COLUMN app_entrust_pay_info.accountname IS '收款人名称';
COMMENT ON COLUMN app_entrust_pay_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_entrust_pay_info.payeecanceldate IS '受托支付对象注销日期';
CREATE INDEX idx_entrust_pay_info_customerid ON app_entrust_pay_info (customerid);
CREATE INDEX idx_entrust_pay_info_reportno ON app_entrust_pay_info (reportno);

-- ---------------------------------------------------------------
-- [19/45] app_finance_index_info —— 财务指标值表（一期一行一指标；同比/较年初等对比值由查询层计算，不落表）
-- ---------------------------------------------------------------
CREATE TABLE app_finance_index_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    accountmonth                        VARCHAR(32),
    reportscope                         VARCHAR(64),
    sheetno                             VARCHAR(64),
    reportperiod                        VARCHAR(64),
    indextype                           VARCHAR(64),
    indexvalue                          DECIMAL(18,2),
    yoyvalue                            DECIMAL(12,4),
    changevalue                         DECIMAL(18,2),
    changerate                          DECIMAL(12,4),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    currencyunit                        VARCHAR(32),
    finreportno                         VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_finance_index_info IS '财务指标值表（一期一行一指标；同比/较年初等对比值由查询层计算，不落表）';
COMMENT ON COLUMN app_finance_index_info.id IS '主键ID';
COMMENT ON COLUMN app_finance_index_info.reportno IS '报告编号';
COMMENT ON COLUMN app_finance_index_info.customerid IS '客户编号';
COMMENT ON COLUMN app_finance_index_info.customername IS '客户名称';
COMMENT ON COLUMN app_finance_index_info.accountmonth IS '会计月';
COMMENT ON COLUMN app_finance_index_info.reportscope IS '报表口径（码值：合并/本部）';
COMMENT ON COLUMN app_finance_index_info.sheetno IS '报表类型（码值：资产负债表/利润表/现金流量表等，码值待确认）';
COMMENT ON COLUMN app_finance_index_info.reportperiod IS '报表周期（码值：年报/半年报/季报/月报，码值待确认）';
COMMENT ON COLUMN app_finance_index_info.indextype IS '指标类型（金额科目：营收/净利润/实收资本/短期借款/长期借款/一年内到期长期借款/应收账款/其他应收款/应付票据/其他应付款/存货/总资产，单位万元；比率指标：资产负债率/销售利率/净利率，存百分数值，如65.43表示65.43%）';
COMMENT ON COLUMN app_finance_index_info.indexvalue IS '指标本期值（金额科目=万元；比率指标=百分数值，如65.43表示65.43%）';
COMMENT ON COLUMN app_finance_index_info.yoyvalue IS '同比（%）：该期值÷上年同期值−1；行级属性各期行自带，上游计算或加工层预填（默认已有）';
COMMENT ON COLUMN app_finance_index_info.changevalue IS '较年初变动（万元）：该期值−上年末(12月)值；行级属性各期行自带（默认已有）';
COMMENT ON COLUMN app_finance_index_info.changerate IS '较年初增幅（%）：(该期值−上年末值)÷上年末值；行级属性各期行自带（默认已有）';
COMMENT ON COLUMN app_finance_index_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_finance_index_info.currencyunit IS '货币单位（码值：元/千/万，样例为万）';
COMMENT ON COLUMN app_finance_index_info.finreportno IS '财报编号（关联财报主档 app_finance_report_info.finReportNo）';
CREATE INDEX idx_finance_index_info_accountmonth ON app_finance_index_info (accountmonth);
CREATE INDEX idx_finance_index_info_customerid ON app_finance_index_info (customerid);
CREATE INDEX idx_finance_index_info_indextype ON app_finance_index_info (indextype);
CREATE INDEX idx_finance_index_info_reportno ON app_finance_index_info (reportno);
CREATE INDEX idx_finance_index_info_reportscope ON app_finance_index_info (reportscope);

-- ---------------------------------------------------------------
-- [20/45] app_finance_indicator_info —— 财务指标预定义表（宽表纵表，一期一行一指标口径，与 app_finance_index_info EAV 宽表并存；数据来源：附件《新增财务指标表表结构.xlsx》按"见名知意"自动译）
-- ---------------------------------------------------------------
CREATE TABLE app_finance_indicator_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    finreportno                         VARCHAR(64),
    accountmonth                        VARCHAR(32),
    reportscope                         VARCHAR(64),
    reportperiod                        VARCHAR(64),
    auditflag                           VARCHAR(32),
    currency                            VARCHAR(32),
    monetaryunit                        VARCHAR(32),
    reportstatusname                    VARCHAR(64),
    reportstatus                        VARCHAR(64),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    reporttypeno                        VARCHAR(64),
    reporttypename                      VARCHAR(128),
    sheetno                             VARCHAR(64),
    revenue                             DECIMAL(18,2),
    revenueyoy                          DECIMAL(12,4),
    netprofit                           DECIMAL(18,2),
    netprofityoy                        DECIMAL(12,4),
    paidincapital                       DECIMAL(18,2),
    totalequity                         DECIMAL(18,2),
    accountsreceivable                  DECIMAL(18,2),
    archangefromyearstart               DECIMAL(18,2),
    archangefromyearstartrate           DECIMAL(12,4),
    otherreceivable                     DECIMAL(18,2),
    orchangefromyearstart               DECIMAL(18,2),
    orchangefromyearstartrate           DECIMAL(12,4),
    arortotalassetratio                 DECIMAL(12,4),
    shortloan                           DECIMAL(18,2),
    shortloanchangefromyearstart        DECIMAL(18,2),
    shortloanchangefromyearstartrate    DECIMAL(12,4),
    longloan                            DECIMAL(18,2),
    longloanchangefromyearstart         DECIMAL(18,2),
    longloanchangefromyearstartrate     DECIMAL(12,4),
    longloanduewithin1y                 DECIMAL(18,2),
    salesloanratio                      DECIMAL(12,4),
    notespayable                        DECIMAL(18,2),
    notespayablechangefromyearstart     DECIMAL(18,2),
    notespayablechangefromyearstartrate DECIMAL(12,4),
    otherpayable                        DECIMAL(18,2),
    otherpayablechangefromyearstart     DECIMAL(18,2),
    otherpayablechangefromyearstartrate DECIMAL(12,4),
    sltotalloanyoy                      DECIMAL(12,4),
    aryoy                               DECIMAL(12,4),
    arturnoverdays                      INT,
    inventoryturnoverdays               INT,
    inventoryyoy                        DECIMAL(12,4),
    accountspayable                     DECIMAL(18,2),
    inventory                           DECIMAL(18,2),
    debtratio                           DECIMAL(12,4),
    salesprofitratio                    DECIMAL(12,4),
    netprofitratio                      DECIMAL(12,4),
    guarantorid                         VARCHAR(64),
    guarantorname                       VARCHAR(128),
    subjecttype                         VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_finance_indicator_info IS '财务指标预定义表（宽表纵表，一期一行一指标口径，与 app_finance_index_info EAV 宽表并存；数据来源：附件《新增财务指标表表结构.xlsx》按"见名知意"自动译）';
COMMENT ON COLUMN app_finance_indicator_info.id IS '主键ID';
COMMENT ON COLUMN app_finance_indicator_info.reportno IS '报告编号';
COMMENT ON COLUMN app_finance_indicator_info.customerid IS '客户编号';
COMMENT ON COLUMN app_finance_indicator_info.customername IS '客户名称';
COMMENT ON COLUMN app_finance_indicator_info.finreportno IS '财报编号';
COMMENT ON COLUMN app_finance_indicator_info.accountmonth IS '会计月';
COMMENT ON COLUMN app_finance_indicator_info.reportscope IS '报表口径（码值：合并/本部）';
COMMENT ON COLUMN app_finance_indicator_info.reportperiod IS '报表周期（码值：年报/半年报/季报/月报）';
COMMENT ON COLUMN app_finance_indicator_info.auditflag IS '是否审计（码值：是/否）';
COMMENT ON COLUMN app_finance_indicator_info.currency IS '报表币种';
COMMENT ON COLUMN app_finance_indicator_info.monetaryunit IS '货币单位（码值：元/千/万，样例为万）';
COMMENT ON COLUMN app_finance_indicator_info.reportstatusname IS '报表状态中文';
COMMENT ON COLUMN app_finance_indicator_info.reportstatus IS '报表状态码值';
COMMENT ON COLUMN app_finance_indicator_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_finance_indicator_info.reporttypeno IS '报表类型';
COMMENT ON COLUMN app_finance_indicator_info.reporttypename IS '报表类型名称';
COMMENT ON COLUMN app_finance_indicator_info.sheetno IS '科目所在财报类型';
COMMENT ON COLUMN app_finance_indicator_info.revenue IS '营业收入（万元）';
COMMENT ON COLUMN app_finance_indicator_info.revenueyoy IS '营业收入同比（%）';
COMMENT ON COLUMN app_finance_indicator_info.netprofit IS '净利润（万元）';
COMMENT ON COLUMN app_finance_indicator_info.netprofityoy IS '净利润同比（%）';
COMMENT ON COLUMN app_finance_indicator_info.paidincapital IS '实收资本（万元）';
COMMENT ON COLUMN app_finance_indicator_info.totalequity IS '所有者权益合计（万元）';
COMMENT ON COLUMN app_finance_indicator_info.accountsreceivable IS '应收账款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.archangefromyearstart IS '应收账款较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.archangefromyearstartrate IS '应收账款较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.otherreceivable IS '其他应收款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.orchangefromyearstart IS '其他应收款较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.orchangefromyearstartrate IS '其他应收款较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.arortotalassetratio IS '应收账款和其他应收款合计占总资产比例（%）';
COMMENT ON COLUMN app_finance_indicator_info.shortloan IS '短期借款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.shortloanchangefromyearstart IS '短期借款较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.shortloanchangefromyearstartrate IS '短期借款较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.longloan IS '长期借款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.longloanchangefromyearstart IS '长期借款较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.longloanchangefromyearstartrate IS '长期借款较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.longloanduewithin1y IS '一年内到期的长期借款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.salesloanratio IS '销贷比';
COMMENT ON COLUMN app_finance_indicator_info.notespayable IS '应付票据（万元）';
COMMENT ON COLUMN app_finance_indicator_info.notespayablechangefromyearstart IS '应付票据较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.notespayablechangefromyearstartrate IS '应付票据较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.otherpayable IS '其他应付款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.otherpayablechangefromyearstart IS '其他应付款较年初变动（万元）';
COMMENT ON COLUMN app_finance_indicator_info.otherpayablechangefromyearstartrate IS '其他应付款较年初增幅（%）';
COMMENT ON COLUMN app_finance_indicator_info.sltotalloanyoy IS '短期借款和长期借款合计同比（%）';
COMMENT ON COLUMN app_finance_indicator_info.aryoy IS '应收账款同比（%）';
COMMENT ON COLUMN app_finance_indicator_info.arturnoverdays IS '应收账款周转天数';
COMMENT ON COLUMN app_finance_indicator_info.inventoryturnoverdays IS '存货周转天数';
COMMENT ON COLUMN app_finance_indicator_info.inventoryyoy IS '存货同比（%）';
COMMENT ON COLUMN app_finance_indicator_info.accountspayable IS '应付账款（万元）';
COMMENT ON COLUMN app_finance_indicator_info.inventory IS '存货（万元）';
COMMENT ON COLUMN app_finance_indicator_info.debtratio IS '资产负债率（%）';
COMMENT ON COLUMN app_finance_indicator_info.salesprofitratio IS '销售利率（%）';
COMMENT ON COLUMN app_finance_indicator_info.netprofitratio IS '净利率（%）';
COMMENT ON COLUMN app_finance_indicator_info.guarantorid IS '担保人客户编号（subjectType=担保人时填写）';
COMMENT ON COLUMN app_finance_indicator_info.guarantorname IS '担保人名称（subjectType=担保人时填写）';
COMMENT ON COLUMN app_finance_indicator_info.subjecttype IS '主体类型（码值：借款人/担保人）';
CREATE INDEX idx_finance_indicator_info_customerid ON app_finance_indicator_info (customerid);
CREATE INDEX idx_finance_indicator_info_reportno ON app_finance_indicator_info (reportno);
CREATE UNIQUE INDEX uk_finance_indicator_info_biz ON app_finance_indicator_info (reportno, customerid, finreportno, accountmonth, reportscope, reportperiod, reporttypeno);

-- ---------------------------------------------------------------
-- [21/45] app_finance_report_info —— 财报主档表（一期一行）
-- ---------------------------------------------------------------
CREATE TABLE app_finance_report_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    accountmonth                        VARCHAR(32),
    sheetno                             VARCHAR(64),
    reportscope                         VARCHAR(64),
    reportperiod                        VARCHAR(64),
    auditflag                           VARCHAR(32),
    currency                            VARCHAR(32),
    reportstatus                        VARCHAR(32),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    currencyunit                        VARCHAR(32),
    finreportno                         VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_finance_report_info IS '财报主档表（一期一行）';
COMMENT ON COLUMN app_finance_report_info.id IS '主键ID';
COMMENT ON COLUMN app_finance_report_info.reportno IS '报告编号';
COMMENT ON COLUMN app_finance_report_info.customerid IS '客户编号';
COMMENT ON COLUMN app_finance_report_info.customername IS '客户名称';
COMMENT ON COLUMN app_finance_report_info.accountmonth IS '会计月';
COMMENT ON COLUMN app_finance_report_info.sheetno IS '报表类型（码值：资产负债表/利润表/现金流量表等，码值待确认）';
COMMENT ON COLUMN app_finance_report_info.reportscope IS '报表口径（码值：合并/本部）';
COMMENT ON COLUMN app_finance_report_info.reportperiod IS '报表周期（码值：年报/半年报/季报/月报，码值待确认）';
COMMENT ON COLUMN app_finance_report_info.auditflag IS '是否审计（码值：是/否）';
COMMENT ON COLUMN app_finance_report_info.currency IS '报表币种';
COMMENT ON COLUMN app_finance_report_info.reportstatus IS '报表状态（锁定/未锁定，是否锁定状态判断依据）';
COMMENT ON COLUMN app_finance_report_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_finance_report_info.currencyunit IS '货币单位（码值：元/千/万，样例为万）';
COMMENT ON COLUMN app_finance_report_info.finreportno IS '财报编号（财务报表明细标识，关联指标明细）';
CREATE INDEX idx_finance_report_info_accountmonth ON app_finance_report_info (accountmonth);
CREATE INDEX idx_finance_report_info_customerid ON app_finance_report_info (customerid);
CREATE INDEX idx_finance_report_info_reportno ON app_finance_report_info (reportno);

-- ---------------------------------------------------------------
-- [22/45] app_graph_hit_info —— 企业图谱命中情况
-- ---------------------------------------------------------------
CREATE TABLE app_graph_hit_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    suspectedfundreturn                 VARCHAR(8),
    suspectedloanpurposeabnormal        VARCHAR(8),
    suspectedborrowednameloan           VARCHAR(8),
    suspectedshellcompany               VARCHAR(8),
    suspectedguaranteecircle            VARCHAR(8),
    intrabankrelation                   VARCHAR(8),
    entrustedpaymanytoone               VARCHAR(8),
    collateralsamecommunity             VARCHAR(8),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_graph_hit_info IS '企业图谱命中情况';
COMMENT ON COLUMN app_graph_hit_info.id IS 'id';
COMMENT ON COLUMN app_graph_hit_info.reportno IS '报告编号';
COMMENT ON COLUMN app_graph_hit_info.customerid IS '客户编号';
COMMENT ON COLUMN app_graph_hit_info.customername IS '客户名称';
COMMENT ON COLUMN app_graph_hit_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_graph_hit_info.suspectedfundreturn IS '疑似资金回流（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.suspectedloanpurposeabnormal IS '贷款用途疑似异常（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.suspectedborrowednameloan IS '疑似借名贷款（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.suspectedshellcompany IS '疑似空壳公司（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.suspectedguaranteecircle IS '疑似担保圈链（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.intrabankrelation IS '行内关联关系（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.entrustedpaymanytoone IS '受托支付多对一（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_graph_hit_info.collateralsamecommunity IS '抵押物同小区关联（码值：是/否，码值待确认）';
CREATE INDEX idx_graph_hit_info_customerid ON app_graph_hit_info (customerid);
CREATE INDEX idx_graph_hit_info_reportno ON app_graph_hit_info (reportno);

-- ---------------------------------------------------------------
-- [23/45] app_gs_finance_data_info —— 国税财务数据表
-- ---------------------------------------------------------------
CREATE TABLE app_gs_finance_data_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    reportscope                         VARCHAR(64),
    beforeyear                          VARCHAR(32),
    lastyear                            VARCHAR(32),
    thisyear                            VARCHAR(32),
    gfrevenue                           DECIMAL(18,2),
    lastyearrevenue                     DECIMAL(18,2),
    beforeyearrevenue                   DECIMAL(18,2),
    gfreceivable                        DECIMAL(18,2),
    lastyearreceivable                  DECIMAL(18,2),
    beforeyearreceivable                DECIMAL(18,2),
    gfpayable                           DECIMAL(18,2),
    lastyearpayable                     DECIMAL(18,2),
    beforeyearpayable                   DECIMAL(18,2),
    gfinventory                         DECIMAL(18,2),
    lastyearinventory                   DECIMAL(18,2),
    beforeyearinventory                 DECIMAL(18,2),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_gs_finance_data_info IS '国税财务数据表';
COMMENT ON COLUMN app_gs_finance_data_info.id IS 'id';
COMMENT ON COLUMN app_gs_finance_data_info.reportno IS '报告编号';
COMMENT ON COLUMN app_gs_finance_data_info.customerid IS '客户编号';
COMMENT ON COLUMN app_gs_finance_data_info.customername IS '客户名称';
COMMENT ON COLUMN app_gs_finance_data_info.reportscope IS '财报口径';
COMMENT ON COLUMN app_gs_finance_data_info.beforeyear IS '前年日期';
COMMENT ON COLUMN app_gs_finance_data_info.lastyear IS '去年日期';
COMMENT ON COLUMN app_gs_finance_data_info.thisyear IS '最新一期日期';
COMMENT ON COLUMN app_gs_finance_data_info.gfrevenue IS '最近一期营收（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.lastyearrevenue IS '去年营收（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.beforeyearrevenue IS '前年营收（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.gfreceivable IS '最近一期应收账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.lastyearreceivable IS '去年应收账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.beforeyearreceivable IS '前年应收账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.gfpayable IS '最近一期应付账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.lastyearpayable IS '去年应付账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.beforeyearpayable IS '前年应付账款（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.gfinventory IS '最近一期存货（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.lastyearinventory IS '去年存货（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.beforeyearinventory IS '前年存货（万元）';
COMMENT ON COLUMN app_gs_finance_data_info.inputtime IS '入库时间';
CREATE INDEX idx_gs_finance_data_customerid ON app_gs_finance_data_info (customerid);
CREATE INDEX idx_gs_finance_data_reportno ON app_gs_finance_data_info (reportno);
CREATE UNIQUE INDEX uk_gs_finance_data_biz ON app_gs_finance_data_info (reportno, customerid, reportscope);

-- ---------------------------------------------------------------
-- [24/45] app_gs_tax_sales_info —— 国税销售额表
-- ---------------------------------------------------------------
CREATE TABLE app_gs_tax_sales_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    taxperiod                           VARCHAR(32),
    monthlytaxsales                     DECIMAL(18,2),
    totalsalestax                       DECIMAL(18,2),
    yoychange                           DECIMAL(18,2),
    yoyrate                             DECIMAL(12,4),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_gs_tax_sales_info IS '国税销售额表';
COMMENT ON COLUMN app_gs_tax_sales_info.id IS 'id';
COMMENT ON COLUMN app_gs_tax_sales_info.reportno IS '报告编号';
COMMENT ON COLUMN app_gs_tax_sales_info.customerid IS '客户编号';
COMMENT ON COLUMN app_gs_tax_sales_info.customername IS '客户名称';
COMMENT ON COLUMN app_gs_tax_sales_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_gs_tax_sales_info.taxperiod IS '纳税期（按月，一月一行，如202603）';
COMMENT ON COLUMN app_gs_tax_sales_info.monthlytaxsales IS '每月纳税销售额（万元）';
COMMENT ON COLUMN app_gs_tax_sales_info.totalsalestax IS '当年纳税申请总销售额累计（万元）';
COMMENT ON COLUMN app_gs_tax_sales_info.yoychange IS '当年销售额较上年同期变动额（万元）';
COMMENT ON COLUMN app_gs_tax_sales_info.yoyrate IS '当年销售额较上年同期同比（%）';
CREATE INDEX idx_gs_tax_sales_customerid ON app_gs_tax_sales_info (customerid);
CREATE INDEX idx_gs_tax_sales_reportno ON app_gs_tax_sales_info (reportno);
CREATE UNIQUE INDEX uk_gs_tax_sales_biz ON app_gs_tax_sales_info (reportno, customerid, taxperiod);

-- ---------------------------------------------------------------
-- [25/45] app_guarantor_credit_info —— 担保人征信表
-- ---------------------------------------------------------------
CREATE TABLE app_guarantor_credit_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    guarantorname                       VARCHAR(128),
    querytime                           VARCHAR(32),
    zxreportno                          VARCHAR(128),
    totalloanbal                        DECIMAL(18,2),
    operateloanbal                      DECIMAL(18,2),
    consumeloanbal                      DECIMAL(18,2),
    houseloanbal                        DECIMAL(18,2),
    otherloanbal                        DECIMAL(18,2),
    totalloancount                      INT,
    operateloancount                    INT,
    consumeloancount                    INT,
    houseloancount                      INT,
    otherloancount                      INT,
    bzcbal                              DECIMAL(18,2),
    badbal                              DECIMAL(18,2),
    loancurrentoverdue                  DECIMAL(18,2),
    cardcurrentoverdue                  DECIMAL(18,2),
    guaranteeoverdueamt                 DECIMAL(18,2),
    nonbankguaranteebal                 DECIMAL(18,2),
    nonbankhighrateloan                 DECIMAL(12,4),
    guaranteeabnormalbal                DECIMAL(18,2),
    extendbal                           DECIMAL(18,2),
    delaybal                            DECIMAL(18,2),
    creditabnormalbal                   DECIMAL(18,2),
    acctabnormalbal                     DECIMAL(18,2),
    cardabnormalbal                     DECIMAL(18,2),
    guaranteehkabnormalbal              DECIMAL(18,2),
    credituserate                       DECIMAL(12,4),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    guarantorid                         VARCHAR(64),
    nonbankliabtotal                    DECIMAL(18,2),
    loanquery12m                        INT,
    loanquery6m                         INT,
    loanquery3m                         INT,
    cardquery12m                        INT,
    cardquery6m                         INT,
    cardquery3m                         INT,
    selfquery1m                         INT,
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_guarantor_credit_info IS '担保人征信表';
COMMENT ON COLUMN app_guarantor_credit_info.id IS '主键ID';
COMMENT ON COLUMN app_guarantor_credit_info.reportno IS '报告编号';
COMMENT ON COLUMN app_guarantor_credit_info.customerid IS '客户编号';
COMMENT ON COLUMN app_guarantor_credit_info.customername IS '客户名称';
COMMENT ON COLUMN app_guarantor_credit_info.guarantorname IS '担保人';
COMMENT ON COLUMN app_guarantor_credit_info.querytime IS '征信查询时间';
COMMENT ON COLUMN app_guarantor_credit_info.zxreportno IS '征信报告记录号';
COMMENT ON COLUMN app_guarantor_credit_info.totalloanbal IS '贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.operateloanbal IS '经营性贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.consumeloanbal IS '消费类贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.houseloanbal IS '住房类贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.otherloanbal IS '其他贷款余额合计（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.totalloancount IS '贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.operateloancount IS '经营性贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.consumeloancount IS '消费类贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.houseloancount IS '住房类贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.otherloancount IS '其他贷款机构数';
COMMENT ON COLUMN app_guarantor_credit_info.bzcbal IS '被追偿余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.badbal IS '呆账余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.loancurrentoverdue IS '贷款当前逾期总金额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.cardcurrentoverdue IS '贷记卡当前逾期总金额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.guaranteeoverdueamt IS '对外担保（相关还款责任）当前逾期金额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.nonbankguaranteebal IS '在非银机构对外担保余额（万元，上游直给：qy_fyjg_dwdb_bal/gr_fyjg_dwdb_bal）';
COMMENT ON COLUMN app_guarantor_credit_info.nonbankhighrateloan IS '非银机构较高利率借款推算利率最大值（%，上游直给：qy_fyjg_gjlv_loan_max/gr_fyjg_gjlv_loan_max；较高利率判断依据）';
COMMENT ON COLUMN app_guarantor_credit_info.guaranteeabnormalbal IS '对外担保（相关还款责任）五级分类非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.extendbal IS '展期债务余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.delaybal IS '落实金融困等政策银行主动延期债务余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.creditabnormalbal IS '未结清信贷五级分类非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.acctabnormalbal IS '未结清账户状态非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.cardabnormalbal IS '未销户贷记卡账户状态非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.guaranteehkabnormalbal IS '对外担保（相关还款责任）还款状态非正常余额（万元）';
COMMENT ON COLUMN app_guarantor_credit_info.credituserate IS '信用卡使用率（%）';
COMMENT ON COLUMN app_guarantor_credit_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_guarantor_credit_info.guarantorid IS '担保人客户编号';
COMMENT ON COLUMN app_guarantor_credit_info.nonbankliabtotal IS '在非银机构负债合计（万元，个人，上游直给：gr_fyjg_liab_tot）';
COMMENT ON COLUMN app_guarantor_credit_info.loanquery12m IS '近一年贷款审批征信查询次数';
COMMENT ON COLUMN app_guarantor_credit_info.loanquery6m IS '近6个月贷款审批征信查询次数';
COMMENT ON COLUMN app_guarantor_credit_info.loanquery3m IS '近3个月贷款审批征信查询次数';
COMMENT ON COLUMN app_guarantor_credit_info.cardquery12m IS '近一年信用卡审批征信查询次数';
COMMENT ON COLUMN app_guarantor_credit_info.cardquery6m IS '近6个月信用卡审批征信查询次数';
COMMENT ON COLUMN app_guarantor_credit_info.cardquery3m IS '近3个月信用卡审批征信查询次数';
COMMENT ON COLUMN app_guarantor_credit_info.selfquery1m IS '近1个月本人查询征信查询次数';
CREATE INDEX idx_guarantor_credit_info_customerid ON app_guarantor_credit_info (customerid);
CREATE INDEX idx_guarantor_credit_info_guarantorname ON app_guarantor_credit_info (guarantorname);
CREATE INDEX idx_guarantor_credit_info_reportno ON app_guarantor_credit_info (reportno);

-- ---------------------------------------------------------------
-- [26/45] app_guarantor_info —— 担保人信息表
-- ---------------------------------------------------------------
CREATE TABLE app_guarantor_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    guarantorname                       VARCHAR(128),
    guarantortype                       VARCHAR(32),
    isstateowned                        VARCHAR(64),
    education                           VARCHAR(64),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    guarantorid                         VARCHAR(64),
    subjecttype                         VARCHAR(64),
    zxreportnozx                        VARCHAR(128),
    zxreportnosq                        VARCHAR(128),
    zxreportnosx                        VARCHAR(128),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_guarantor_info IS '担保人信息表';
COMMENT ON COLUMN app_guarantor_info.id IS '主键ID';
COMMENT ON COLUMN app_guarantor_info.reportno IS '报告编号';
COMMENT ON COLUMN app_guarantor_info.customerid IS '客户编号';
COMMENT ON COLUMN app_guarantor_info.customername IS '客户名称';
COMMENT ON COLUMN app_guarantor_info.guarantorname IS '担保人';
COMMENT ON COLUMN app_guarantor_info.guarantortype IS '担保人类型（法人/自然人）';
COMMENT ON COLUMN app_guarantor_info.isstateowned IS '是否国资/国有担保';
COMMENT ON COLUMN app_guarantor_info.education IS '学历（征信基本信息，接口zxBiEDULVL）';
COMMENT ON COLUMN app_guarantor_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_guarantor_info.guarantorid IS '担保人客户编号（行内接口字段）';
COMMENT ON COLUMN app_guarantor_info.subjecttype IS '主体类型（码值：借款人/担保人，2026-09-03 新增）';
COMMENT ON COLUMN app_guarantor_info.zxreportnozx IS '征信报告记录号-最新（2026-09-03 新增，文件字段名 zxReportNoZX）';
COMMENT ON COLUMN app_guarantor_info.zxreportnosq IS '征信报告记录号-上期（2026-09-03 新增，文件字段名 zxReportNosq）';
COMMENT ON COLUMN app_guarantor_info.zxreportnosx IS '征信报告记录号-授信（2026-09-03 新增，文件字段名 zxReportNoSX）';
CREATE INDEX idx_guarantor_info_customerid ON app_guarantor_info (customerid);
CREATE INDEX idx_guarantor_info_reportno ON app_guarantor_info (reportno);

-- ---------------------------------------------------------------
-- [27/45] app_guofa_report_info —— 国发征信信息表
-- ---------------------------------------------------------------
CREATE TABLE app_guofa_report_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    datadate                            VARCHAR(32),
    beforeyear                          VARCHAR(32),
    lastyear                            VARCHAR(32),
    thisyear                            VARCHAR(32),
    gfrevenue                           DECIMAL(18,2),
    lastyearrevenue                     DECIMAL(18,2),
    beforeyearrevenue                   DECIMAL(18,2),
    gfreceivable                        DECIMAL(18,2),
    lastyearreceivable                  DECIMAL(18,2),
    beforeyearreceivable                DECIMAL(18,2),
    gfpayable                           DECIMAL(18,2),
    lastyearpayable                     DECIMAL(18,2),
    beforeyearpayable                   DECIMAL(18,2),
    gfinventory                         DECIMAL(18,2),
    lastyearinventory                   DECIMAL(18,2),
    beforeyearinventory                 DECIMAL(18,2),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_guofa_report_info IS '国发征信信息表';
COMMENT ON COLUMN app_guofa_report_info.id IS '主键ID';
COMMENT ON COLUMN app_guofa_report_info.reportno IS '报告编号';
COMMENT ON COLUMN app_guofa_report_info.customerid IS '客户编号';
COMMENT ON COLUMN app_guofa_report_info.customername IS '客户名称';
COMMENT ON COLUMN app_guofa_report_info.datadate IS '数据日期';
COMMENT ON COLUMN app_guofa_report_info.beforeyear IS '前年日期';
COMMENT ON COLUMN app_guofa_report_info.lastyear IS '去年日期';
COMMENT ON COLUMN app_guofa_report_info.thisyear IS '最新一期日期';
COMMENT ON COLUMN app_guofa_report_info.gfrevenue IS '最近一期营收（万元）';
COMMENT ON COLUMN app_guofa_report_info.lastyearrevenue IS '去年营收（万元）';
COMMENT ON COLUMN app_guofa_report_info.beforeyearrevenue IS '前年营收（万元）';
COMMENT ON COLUMN app_guofa_report_info.gfreceivable IS '最近一期应收账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.lastyearreceivable IS '去年应收账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.beforeyearreceivable IS '前年应收账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.gfpayable IS '最近一期应付账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.lastyearpayable IS '去年应付账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.beforeyearpayable IS '前年应付账款（万元）';
COMMENT ON COLUMN app_guofa_report_info.gfinventory IS '最近一期存货（万元）';
COMMENT ON COLUMN app_guofa_report_info.lastyearinventory IS '去年存货（万元）';
COMMENT ON COLUMN app_guofa_report_info.beforeyearinventory IS '前年存货（万元）';
COMMENT ON COLUMN app_guofa_report_info.inputtime IS '入库时间';
CREATE INDEX idx_guofa_report_info_customerid ON app_guofa_report_info (customerid);
CREATE INDEX idx_guofa_report_info_reportno ON app_guofa_report_info (reportno);

-- ---------------------------------------------------------------
-- [28/45] app_ic_info —— 工商登记信息表（客户级）
-- ---------------------------------------------------------------
CREATE TABLE app_ic_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    iclegalperson                       VARCHAR(128),
    icregistercapital                   DECIMAL(18,2),
    icpaidincapital                     DECIMAL(18,2),
    icbeneficiaryname                   VARCHAR(128),
    icbeneficiarypercent                DECIMAL(12,4),
    isstateowned                        VARCHAR(64),
    isfakestateowned                    VARCHAR(64),
    cancellationdate                    VARCHAR(32),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_ic_info IS '工商登记信息表（客户级）';
COMMENT ON COLUMN app_ic_info.id IS '主键ID';
COMMENT ON COLUMN app_ic_info.reportno IS '报告编号';
COMMENT ON COLUMN app_ic_info.customerid IS '客户编号';
COMMENT ON COLUMN app_ic_info.customername IS '客户名称';
COMMENT ON COLUMN app_ic_info.iclegalperson IS '工商法定代表人';
COMMENT ON COLUMN app_ic_info.icregistercapital IS '工商注册资本（万元）';
COMMENT ON COLUMN app_ic_info.icpaidincapital IS '工商实缴资本（万元）';
COMMENT ON COLUMN app_ic_info.icbeneficiaryname IS '工商受益人名称';
COMMENT ON COLUMN app_ic_info.icbeneficiarypercent IS '工商受益人持股比例（%）';
COMMENT ON COLUMN app_ic_info.isstateowned IS '是否国有企业（工商口径）（码值：是/否（工商口径））';
COMMENT ON COLUMN app_ic_info.isfakestateowned IS '是否假冒国企（工商口径）（码值：是/否（工商口径））';
COMMENT ON COLUMN app_ic_info.cancellationdate IS '注销日期';
COMMENT ON COLUMN app_ic_info.inputtime IS '入库时间';
CREATE INDEX idx_ic_info_customerid ON app_ic_info (customerid);
CREATE INDEX idx_ic_info_reportno ON app_ic_info (reportno);

-- ---------------------------------------------------------------
-- [29/45] app_ic_shareholder_info —— 工商股东变更表（股权变更历史：变更时间/变更前后比例，多时点快照）
-- ---------------------------------------------------------------
CREATE TABLE app_ic_shareholder_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    snapshot_type                       VARCHAR(32),
    icshareholdername                   VARCHAR(128),
    icstocknum                          INT,
    icstockpercent                      DECIMAL(12,4),
    icamount                            DECIMAL(18,2),
    changetime                          VARCHAR(32),
    percentbefore                       DECIMAL(12,4),
    percentafter                        DECIMAL(12,4),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_ic_shareholder_info IS '工商股东变更表（股权变更历史：变更时间/变更前后比例，多时点快照）';
COMMENT ON COLUMN app_ic_shareholder_info.id IS '主键ID';
COMMENT ON COLUMN app_ic_shareholder_info.reportno IS '报告编号';
COMMENT ON COLUMN app_ic_shareholder_info.customerid IS '客户编号';
COMMENT ON COLUMN app_ic_shareholder_info.customername IS '客户名称';
COMMENT ON COLUMN app_ic_shareholder_info.snapshot_type IS '快照类型（latest最新/atCredit授信时）';
COMMENT ON COLUMN app_ic_shareholder_info.icshareholdername IS '工商股东名称';
COMMENT ON COLUMN app_ic_shareholder_info.icstocknum IS '工商股东持股数';
COMMENT ON COLUMN app_ic_shareholder_info.icstockpercent IS '工商股东持股比例（%）';
COMMENT ON COLUMN app_ic_shareholder_info.icamount IS '工商股东出资金额（万元）';
COMMENT ON COLUMN app_ic_shareholder_info.changetime IS '股权变更时间（授信时点后的变更）';
COMMENT ON COLUMN app_ic_shareholder_info.percentbefore IS '变更前持股比例（%）';
COMMENT ON COLUMN app_ic_shareholder_info.percentafter IS '变更后持股比例（%）';
COMMENT ON COLUMN app_ic_shareholder_info.inputtime IS '入库时间';
CREATE INDEX idx_ic_shareholder_info_customerid ON app_ic_shareholder_info (customerid);
CREATE INDEX idx_ic_shareholder_info_reportno ON app_ic_shareholder_info (reportno);

-- ---------------------------------------------------------------
-- [30/45] app_loan_plan_info —— 贷款产品还本付息计划表
-- ---------------------------------------------------------------
CREATE TABLE app_loan_plan_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    producttype                         VARCHAR(32),
    nextpaydate                         VARCHAR(32),
    payprincipalamt                     DECIMAL(18,2),
    payinterestamt                      DECIMAL(18,2),
    payfineamt                          DECIMAL(18,2),
    compoundinterest                    DECIMAL(18,2),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_loan_plan_info IS '贷款产品还本付息计划表';
COMMENT ON COLUMN app_loan_plan_info.id IS '主键ID';
COMMENT ON COLUMN app_loan_plan_info.reportno IS '报告编号';
COMMENT ON COLUMN app_loan_plan_info.customerid IS '客户编号';
COMMENT ON COLUMN app_loan_plan_info.customername IS '客户名称';
COMMENT ON COLUMN app_loan_plan_info.producttype IS '产品类型（码值：固贷/房地产开发贷款）';
COMMENT ON COLUMN app_loan_plan_info.nextpaydate IS '下次还款日';
COMMENT ON COLUMN app_loan_plan_info.payprincipalamt IS '下次还款本金（万元）';
COMMENT ON COLUMN app_loan_plan_info.payinterestamt IS '下次还款利息（万元）';
COMMENT ON COLUMN app_loan_plan_info.payfineamt IS '下次还款罚息（万元）';
COMMENT ON COLUMN app_loan_plan_info.compoundinterest IS '下次还款复利（万元）';
COMMENT ON COLUMN app_loan_plan_info.inputtime IS '入库时间';
CREATE INDEX idx_loan_plan_info_customerid ON app_loan_plan_info (customerid);
CREATE INDEX idx_loan_plan_info_reportno ON app_loan_plan_info (reportno);

-- ---------------------------------------------------------------
-- [31/45] app_loan_receipt_info —— 借据信息表
-- ---------------------------------------------------------------
CREATE TABLE app_loan_receipt_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    loanserialno                        VARCHAR(64),
    loanstatus                          VARCHAR(64),
    productname                         VARCHAR(128),
    producttype                         VARCHAR(64),
    purposename                         VARCHAR(128),
    balance                             DECIMAL(18,2),
    productbelongname                   VARCHAR(128),
    overduebalance                      DECIMAL(18,2),
    overdueinterestamt                  DECIMAL(18,2),
    isrestructed                        VARCHAR(32),
    extendbalance                       DECIMAL(18,2),
    restructedbalance                   DECIMAL(18,2),
    reorgtimes                          INT,
    reorgbalance                        DECIMAL(18,2),
    loanchangerptcounts                 INT,
    loanchangerptbalance                DECIMAL(18,2),
    occurtype                           VARCHAR(32),
    isextend                            VARCHAR(32),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    fixedassetloan                      VARCHAR(32),
    realestatedevloan                   VARCHAR(32),
    nextpaydate                         VARCHAR(32),
    payprincipalamt                     DECIMAL(18,2),
    payinterestamt                      DECIMAL(18,2),
    payfineamt                          DECIMAL(18,2),
    compoundinterest                    DECIMAL(18,2),
    businessrate                        DECIMAL(12,4),
    repaymentperiod                     VARCHAR(32),
    businesssum                         DECIMAL(18,2),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_loan_receipt_info IS '借据信息表';
COMMENT ON COLUMN app_loan_receipt_info.id IS '主键ID';
COMMENT ON COLUMN app_loan_receipt_info.reportno IS '报告编号';
COMMENT ON COLUMN app_loan_receipt_info.customerid IS '客户编号';
COMMENT ON COLUMN app_loan_receipt_info.customername IS '客户名称';
COMMENT ON COLUMN app_loan_receipt_info.loanserialno IS '借据号';
COMMENT ON COLUMN app_loan_receipt_info.loanstatus IS '借据状态（码值：正常/逾期/欠息/结清/呆账（码值待确认））';
COMMENT ON COLUMN app_loan_receipt_info.productname IS '基础产品名称';
COMMENT ON COLUMN app_loan_receipt_info.producttype IS '产品类型（基础/组合/固贷/房地产）';
COMMENT ON COLUMN app_loan_receipt_info.purposename IS '用途';
COMMENT ON COLUMN app_loan_receipt_info.balance IS '借据余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.productbelongname IS '产品归属（组合产品）';
COMMENT ON COLUMN app_loan_receipt_info.overduebalance IS '期供欠本金额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.overdueinterestamt IS '期供欠息金额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.isrestructed IS '是否重组优化贷款（码值：是/否）';
COMMENT ON COLUMN app_loan_receipt_info.extendbalance IS '展期贷款余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.restructedbalance IS '重组贷款余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.reorgtimes IS '借新还旧次数';
COMMENT ON COLUMN app_loan_receipt_info.reorgbalance IS '借新还旧余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.loanchangerptcounts IS '还款方式变更笔数';
COMMENT ON COLUMN app_loan_receipt_info.loanchangerptbalance IS '还款方式变更贷款余额（万元）';
COMMENT ON COLUMN app_loan_receipt_info.occurtype IS '发生类型';
COMMENT ON COLUMN app_loan_receipt_info.isextend IS '是否展期（码值：是/否）';
COMMENT ON COLUMN app_loan_receipt_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_loan_receipt_info.fixedassetloan IS '是否固贷产品（码值：是/否）';
COMMENT ON COLUMN app_loan_receipt_info.realestatedevloan IS '是否房地产开发产品（码值：是/否）';
COMMENT ON COLUMN app_loan_receipt_info.nextpaydate IS '下次还款日';
COMMENT ON COLUMN app_loan_receipt_info.payprincipalamt IS '下次还款本金（万元）';
COMMENT ON COLUMN app_loan_receipt_info.payinterestamt IS '下次还款利息（万元）';
COMMENT ON COLUMN app_loan_receipt_info.payfineamt IS '下次还款罚息（万元）';
COMMENT ON COLUMN app_loan_receipt_info.compoundinterest IS '下次还款复利（万元）';
COMMENT ON COLUMN app_loan_receipt_info.businessrate IS '执行年利率（%）';
COMMENT ON COLUMN app_loan_receipt_info.repaymentperiod IS '付息频率';
COMMENT ON COLUMN app_loan_receipt_info.businesssum IS '借款金额';
CREATE INDEX idx_loan_receipt_info_customerid ON app_loan_receipt_info (customerid);
CREATE INDEX idx_loan_receipt_info_reportno ON app_loan_receipt_info (reportno);

-- ---------------------------------------------------------------
-- [32/45] app_opinion_info —— 贷后意见表
-- ---------------------------------------------------------------
CREATE TABLE app_opinion_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    phaseopinion                        TEXT,
    endtime                             VARCHAR(32),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    approveusername                     VARCHAR(64),
    approveorgname                      VARCHAR(128),
    "group"                             VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_opinion_info IS '贷后意见表';
COMMENT ON COLUMN app_opinion_info.id IS '主键ID';
COMMENT ON COLUMN app_opinion_info.reportno IS '报告编号';
COMMENT ON COLUMN app_opinion_info.customerid IS '客户编号';
COMMENT ON COLUMN app_opinion_info.customername IS '客户名称';
COMMENT ON COLUMN app_opinion_info.phaseopinion IS '审批意见';
COMMENT ON COLUMN app_opinion_info.endtime IS '审批日期';
COMMENT ON COLUMN app_opinion_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_opinion_info.approveusername IS '审批人';
COMMENT ON COLUMN app_opinion_info.approveorgname IS '所属机构';
COMMENT ON COLUMN app_opinion_info."group" IS '检查分组';
CREATE INDEX idx_opinion_info_customerid ON app_opinion_info (customerid);
CREATE INDEX idx_opinion_info_reportno ON app_opinion_info (reportno);

-- ---------------------------------------------------------------
-- [33/45] app_payroll_stat_info —— 代发统计表（月粒度）
-- ---------------------------------------------------------------
CREATE TABLE app_payroll_stat_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    statmonth                           VARCHAR(32),
    payrollcount                        INT,
    payrollamount                       DECIMAL(18,2),
    countmom                            DECIMAL(12,4),
    amountmom                           DECIMAL(12,4),
    countyoy                            DECIMAL(12,4),
    amountyoy                           DECIMAL(12,4),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_payroll_stat_info IS '代发统计表（月粒度）';
COMMENT ON COLUMN app_payroll_stat_info.id IS '主键ID';
COMMENT ON COLUMN app_payroll_stat_info.reportno IS '报告编号';
COMMENT ON COLUMN app_payroll_stat_info.customerid IS '客户编号';
COMMENT ON COLUMN app_payroll_stat_info.customername IS '客户名称';
COMMENT ON COLUMN app_payroll_stat_info.statmonth IS '统计月份';
COMMENT ON COLUMN app_payroll_stat_info.payrollcount IS '代发人数';
COMMENT ON COLUMN app_payroll_stat_info.payrollamount IS '代发金额（万元）';
COMMENT ON COLUMN app_payroll_stat_info.countmom IS '代发人数环比';
COMMENT ON COLUMN app_payroll_stat_info.amountmom IS '代发金额环比';
COMMENT ON COLUMN app_payroll_stat_info.countyoy IS '代发人数同比';
COMMENT ON COLUMN app_payroll_stat_info.amountyoy IS '代发金额同比';
COMMENT ON COLUMN app_payroll_stat_info.inputtime IS '入库时间';
CREATE INDEX idx_payroll_stat_info_customerid ON app_payroll_stat_info (customerid);
CREATE INDEX idx_payroll_stat_info_reportno ON app_payroll_stat_info (reportno);

-- ---------------------------------------------------------------
-- [34/45] app_report_info —— 贷后报告主表
-- ---------------------------------------------------------------
CREATE TABLE app_report_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    reporttitle                         VARCHAR(128),
    checktaskno                         VARCHAR(64),
    reportdate                          VARCHAR(32),
    reportstatus                        VARCHAR(32),
    generatorname                       VARCHAR(64),
    generatetime                        TIMESTAMP,
    approvestatus                       VARCHAR(32),
    approveopinion                      TEXT,
    approvetime                         TIMESTAMP,
    reporturl                           VARCHAR(256),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_report_info IS '贷后报告主表';
COMMENT ON COLUMN app_report_info.id IS '主键ID';
COMMENT ON COLUMN app_report_info.reportno IS '报告编号（一次贷后报告的记录号）';
COMMENT ON COLUMN app_report_info.customerid IS '客户编号';
COMMENT ON COLUMN app_report_info.customername IS '客户名称';
COMMENT ON COLUMN app_report_info.reporttitle IS '报告标题';
COMMENT ON COLUMN app_report_info.checktaskno IS '日检任务编号';
COMMENT ON COLUMN app_report_info.reportdate IS '报告日期（贷后检查日）';
COMMENT ON COLUMN app_report_info.reportstatus IS '报告状态（生成中/已生成/已审批）';
COMMENT ON COLUMN app_report_info.generatorname IS '生成人';
COMMENT ON COLUMN app_report_info.generatetime IS '生成时间';
COMMENT ON COLUMN app_report_info.approvestatus IS '审批状态（码值：待审批/审批通过/审批驳回（码值待确认））';
COMMENT ON COLUMN app_report_info.approveopinion IS '审批意见';
COMMENT ON COLUMN app_report_info.approvetime IS '审批时间';
COMMENT ON COLUMN app_report_info.reporturl IS '报告链接';
COMMENT ON COLUMN app_report_info.inputtime IS '入库时间';
CREATE UNIQUE INDEX uk_report_no ON app_report_info (reportno);

-- ---------------------------------------------------------------
-- [35/45] app_reputation_event_info —— 舆情事件明细表
-- ---------------------------------------------------------------
CREATE TABLE app_reputation_event_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    subjecttype                         VARCHAR(32),
    subjectname                         VARCHAR(128),
    eventtime                           VARCHAR(32),
    eventtype                           VARCHAR(64),
    eventdesc                           TEXT,
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    -- ↓↓ 2026-09-16 同事反馈的表结构变更（原表无此两列，见文件头说明 7）
    eventtypecode                       VARCHAR(64),
    eventtypeorder                      INTEGER,
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_reputation_event_info IS '舆情事件明细表';
COMMENT ON COLUMN app_reputation_event_info.id IS '主键ID';
COMMENT ON COLUMN app_reputation_event_info.reportno IS '报告编号';
COMMENT ON COLUMN app_reputation_event_info.customerid IS '客户编号';
COMMENT ON COLUMN app_reputation_event_info.customername IS '客户名称';
COMMENT ON COLUMN app_reputation_event_info.subjecttype IS '主体类型（码值：借款人/股东）';
COMMENT ON COLUMN app_reputation_event_info.subjectname IS '主体名称（借款人名称/股东名称）';
COMMENT ON COLUMN app_reputation_event_info.eventtime IS '舆情发生时间';
COMMENT ON COLUMN app_reputation_event_info.eventtype IS '舆情类型（码值：证券市场违规/股票戴帽/退市风险/评级下调/高管无法履职/财务造假/其他，待确认）';
COMMENT ON COLUMN app_reputation_event_info.eventdesc IS '舆情事件描述';
COMMENT ON COLUMN app_reputation_event_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_reputation_event_info.eventtypecode IS '舆情类型编码';
COMMENT ON COLUMN app_reputation_event_info.eventtypeorder IS '舆情事件排序';
CREATE INDEX idx_reputation_event_info_customerid ON app_reputation_event_info (customerid);
CREATE INDEX idx_reputation_event_info_reportno ON app_reputation_event_info (reportno);

-- ---------------------------------------------------------------
-- [36/45] app_settle_account_info —— 结算账户表
-- ---------------------------------------------------------------
CREATE TABLE app_settle_account_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    accountno                           VARCHAR(64),
    accountstatus                       VARCHAR(64),
    accountbalance                      DECIMAL(18,2),
    superviseflag                       VARCHAR(64),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_settle_account_info IS '结算账户表';
COMMENT ON COLUMN app_settle_account_info.id IS '主键ID';
COMMENT ON COLUMN app_settle_account_info.reportno IS '报告编号';
COMMENT ON COLUMN app_settle_account_info.customerid IS '客户编号';
COMMENT ON COLUMN app_settle_account_info.customername IS '客户名称';
COMMENT ON COLUMN app_settle_account_info.accountno IS '账号';
COMMENT ON COLUMN app_settle_account_info.accountstatus IS '账户状态（码值：正常/冻结/销户，码值待确认）';
COMMENT ON COLUMN app_settle_account_info.accountbalance IS '账户余额（万元）';
COMMENT ON COLUMN app_settle_account_info.superviseflag IS '监管标识（码值：是/否，码值待确认）';
COMMENT ON COLUMN app_settle_account_info.inputtime IS '入库时间';
CREATE INDEX idx_settle_account_info_customerid ON app_settle_account_info (customerid);
CREATE INDEX idx_settle_account_info_reportno ON app_settle_account_info (reportno);

-- ---------------------------------------------------------------
-- [37/45] app_settle_asset_info —— 结算资产表
-- ---------------------------------------------------------------
CREATE TABLE app_settle_asset_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    frozenamount                        DECIMAL(18,2),
    debitsamenametransferratio          DECIMAL(5,2),
    creditsamenametransferratio         DECIMAL(5,2),
    yearavgdeposit                      DECIMAL(18,2),
    lastyearavgdeposit                  DECIMAL(18,2),
    propertyincome                      DECIMAL(18,2),
    propertyincomeyoy                   DECIMAL(18,2),
    propertyincomesupervised            DECIMAL(18,2),
    electricfeeincome                   DECIMAL(18,2),
    electricfeeyoy                      DECIMAL(18,2),
    electricfeesupervised               DECIMAL(18,2),
    keywordcounterpartycreditamount     DECIMAL(18,2),
    keywordremarkcreditamount           DECIMAL(18,2),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_settle_asset_info IS '结算资产表';
COMMENT ON COLUMN app_settle_asset_info.id IS '主键ID';
COMMENT ON COLUMN app_settle_asset_info.reportno IS '报告编号';
COMMENT ON COLUMN app_settle_asset_info.customerid IS '客户编号';
COMMENT ON COLUMN app_settle_asset_info.customername IS '客户名称';
COMMENT ON COLUMN app_settle_asset_info.frozenamount IS '冻结金额（万元）';
COMMENT ON COLUMN app_settle_asset_info.debitsamenametransferratio IS '借方同名划转金额占比（%）';
COMMENT ON COLUMN app_settle_asset_info.creditsamenametransferratio IS '贷方同名划转金额占比（%）';
COMMENT ON COLUMN app_settle_asset_info.yearavgdeposit IS '年日均存款（万元）';
COMMENT ON COLUMN app_settle_asset_info.lastyearavgdeposit IS '上年年日均存款（万元）';
COMMENT ON COLUMN app_settle_asset_info.propertyincome IS '当年物业收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.propertyincomeyoy IS '当年物业收入累计较上年同期（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.propertyincomesupervised IS '当年监管账户物业收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.electricfeeincome IS '当年电费收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.electricfeeyoy IS '当年电费收入累计较上年同期（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.electricfeesupervised IS '当年监管账户当年电费收入（万元，接口待确认）';
COMMENT ON COLUMN app_settle_asset_info.keywordcounterpartycreditamount IS '当年交易对手中出现小额贷款、担保等关键字的公司贷方发生额（万元）';
COMMENT ON COLUMN app_settle_asset_info.keywordremarkcreditamount IS '当年备注中有担保、借款、投资关键字贷方发生额（万元）';
COMMENT ON COLUMN app_settle_asset_info.inputtime IS '入库时间';
CREATE INDEX idx_settle_asset_info_customerid ON app_settle_asset_info (customerid);
CREATE INDEX idx_settle_asset_info_reportno ON app_settle_asset_info (reportno);

-- ---------------------------------------------------------------
-- [38/45] app_settle_counterparty_info —— 结算交易对手表
-- ---------------------------------------------------------------
CREATE TABLE app_settle_counterparty_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    counterpartyname                    VARCHAR(128),
    direction                           VARCHAR(16),
    amount                              DECIMAL(18,2),
    rankno                              VARCHAR(16),
    upstreamflag                        VARCHAR(32),
    remark                              VARCHAR(512),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_settle_counterparty_info IS '结算交易对手表';
COMMENT ON COLUMN app_settle_counterparty_info.id IS '主键ID';
COMMENT ON COLUMN app_settle_counterparty_info.reportno IS '报告编号';
COMMENT ON COLUMN app_settle_counterparty_info.customerid IS '客户编号';
COMMENT ON COLUMN app_settle_counterparty_info.customername IS '客户名称';
COMMENT ON COLUMN app_settle_counterparty_info.counterpartyname IS '交易对手名称';
COMMENT ON COLUMN app_settle_counterparty_info.direction IS '方向（借方/贷方）';
COMMENT ON COLUMN app_settle_counterparty_info.amount IS '发生额（万元）';
COMMENT ON COLUMN app_settle_counterparty_info.rankno IS '排名（TOP1-10）';
COMMENT ON COLUMN app_settle_counterparty_info.upstreamflag IS '是否前五大上游客户（码值：是/否）';
COMMENT ON COLUMN app_settle_counterparty_info.remark IS '交易备注（预留：备注含担保/借款/投资关键字贷方发生额筛选用，接口待补充）';
COMMENT ON COLUMN app_settle_counterparty_info.inputtime IS '入库时间';
CREATE INDEX idx_settle_counterparty_info_customerid ON app_settle_counterparty_info (customerid);
CREATE INDEX idx_settle_counterparty_info_direction ON app_settle_counterparty_info (direction);
CREATE INDEX idx_settle_counterparty_info_reportno ON app_settle_counterparty_info (reportno);

-- ---------------------------------------------------------------
-- [39/45] app_shareholder_info —— 工商股东信息表（最新时点快照，字段详细；与信贷系统股东 app_xd_shareholder_info 口径对比）
-- ---------------------------------------------------------------
CREATE TABLE app_shareholder_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    name                                VARCHAR(128),
    stock_num                           INT,
    amount                              DECIMAL(18,2),
    stock_percent                       DECIMAL(12,4),
    is_quoted                           VARCHAR(32),
    is_state_owned                      VARCHAR(64),
    is_fake_state_owned                 VARCHAR(32),
    is_listed_company                   VARCHAR(32),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_shareholder_info IS '工商股东信息表（最新时点快照，字段详细；与信贷系统股东 app_xd_shareholder_info 口径对比）';
COMMENT ON COLUMN app_shareholder_info.id IS '主键ID';
COMMENT ON COLUMN app_shareholder_info.reportno IS '报告编号';
COMMENT ON COLUMN app_shareholder_info.customerid IS '客户编号';
COMMENT ON COLUMN app_shareholder_info.customername IS '客户名称';
COMMENT ON COLUMN app_shareholder_info.name IS '股东名称';
COMMENT ON COLUMN app_shareholder_info.stock_num IS '持股数';
COMMENT ON COLUMN app_shareholder_info.amount IS '应出资金额（万元）';
COMMENT ON COLUMN app_shareholder_info.stock_percent IS '持股比例（%）';
COMMENT ON COLUMN app_shareholder_info.is_quoted IS '是否已出资（码值：是/否）';
COMMENT ON COLUMN app_shareholder_info.is_state_owned IS '是否国资股东（码值：是/否）';
COMMENT ON COLUMN app_shareholder_info.is_fake_state_owned IS '股东假冒国企标签（码值：是/否；苏企查/中台按股东主体查询，仅企业股东有值，自然人股东为空）';
COMMENT ON COLUMN app_shareholder_info.is_listed_company IS '股东是否上市公司（码值：是/否，中台按股东主体查询）';
COMMENT ON COLUMN app_shareholder_info.inputtime IS '入库时间';
CREATE INDEX idx_shareholder_info_customerid ON app_shareholder_info (customerid);
CREATE INDEX idx_shareholder_info_reportno ON app_shareholder_info (reportno);

-- ---------------------------------------------------------------
-- [40/45] app_single_check_task_info —— 单项检查任务表
-- ---------------------------------------------------------------
CREATE TABLE app_single_check_task_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    itemcategory                        VARCHAR(64),
    serialno                            VARCHAR(64),
    creditno                            VARCHAR(64),
    approvetextno                       VARCHAR(64),
    startdate                           VARCHAR(32),
    maturity                            VARCHAR(32),
    groupname                           VARCHAR(128),
    productname                         VARCHAR(128),
    checkdate                           VARCHAR(32),
    balance                             DECIMAL(18,2),
    condition                           TEXT,
    implementstatus                     VARCHAR(64),
    extenddate                          VARCHAR(32),
    opinion                             TEXT,
    conditioninstruction                TEXT,
    creditapproveusername               VARCHAR(64),
    approveauthor                       VARCHAR(64),
    operatebelongorgname                VARCHAR(128),
    operateorgname                      VARCHAR(128),
    operateusername                     VARCHAR(64),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    approvestatusname                   VARCHAR(64),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_single_check_task_info IS '单项检查任务表';
COMMENT ON COLUMN app_single_check_task_info.id IS '主键ID';
COMMENT ON COLUMN app_single_check_task_info.reportno IS '报告编号';
COMMENT ON COLUMN app_single_check_task_info.customerid IS '客户编号';
COMMENT ON COLUMN app_single_check_task_info.customername IS '客户名称';
COMMENT ON COLUMN app_single_check_task_info.itemcategory IS '事项类别';
COMMENT ON COLUMN app_single_check_task_info.serialno IS '单项检查任务流水号';
COMMENT ON COLUMN app_single_check_task_info.creditno IS '授信编号';
COMMENT ON COLUMN app_single_check_task_info.approvetextno IS '批复编号';
COMMENT ON COLUMN app_single_check_task_info.startdate IS '批复生效日期';
COMMENT ON COLUMN app_single_check_task_info.maturity IS '批复到期日';
COMMENT ON COLUMN app_single_check_task_info.groupname IS '集团名称';
COMMENT ON COLUMN app_single_check_task_info.productname IS '对象';
COMMENT ON COLUMN app_single_check_task_info.checkdate IS '检查时间';
COMMENT ON COLUMN app_single_check_task_info.balance IS '对象项下借据余额（万元）';
COMMENT ON COLUMN app_single_check_task_info.condition IS '批复后续管理要求';
COMMENT ON COLUMN app_single_check_task_info.implementstatus IS '落实情况';
COMMENT ON COLUMN app_single_check_task_info.extenddate IS '延期日期';
COMMENT ON COLUMN app_single_check_task_info.opinion IS '签署意见';
COMMENT ON COLUMN app_single_check_task_info.conditioninstruction IS '情况说明';
COMMENT ON COLUMN app_single_check_task_info.creditapproveusername IS '授信审查人';
COMMENT ON COLUMN app_single_check_task_info.approveauthor IS '审批权限';
COMMENT ON COLUMN app_single_check_task_info.operatebelongorgname IS '分行';
COMMENT ON COLUMN app_single_check_task_info.operateorgname IS '支行';
COMMENT ON COLUMN app_single_check_task_info.operateusername IS '经办客户经理';
COMMENT ON COLUMN app_single_check_task_info.inputtime IS '入库时间';
COMMENT ON COLUMN app_single_check_task_info.approvestatusname IS '审批状态名称';
CREATE INDEX idx_single_check_task_info_customerid ON app_single_check_task_info (customerid);
CREATE INDEX idx_single_check_task_info_reportno ON app_single_check_task_info (reportno);

-- ---------------------------------------------------------------
-- [41/45] app_specific_loan_check_info —— 特定贷款检查表
-- ---------------------------------------------------------------
CREATE TABLE app_specific_loan_check_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    objectname                          VARCHAR(64),
    productname                         VARCHAR(128),
    productbelongname                   VARCHAR(128),
    contractno                          VARCHAR(64),
    businesssum                         DECIMAL(18,2),
    balance                             DECIMAL(18,2),
    duebilltotalbusinesssum             DECIMAL(18,2),
    nominalbalancesum                   DECIMAL(18,2),
    repaysum                            DECIMAL(18,2),
    purpose                             VARCHAR(128),
    vouchtype                           VARCHAR(32),
    projectbegindate                    VARCHAR(32),
    projectfinishdate                   VARCHAR(32),
    ifbulid                             VARCHAR(32),
    ifconstructionexpect                VARCHAR(32),
    ifgetpermission                     VARCHAR(32),
    ifmatch                             VARCHAR(32),
    ifopenaccount                       VARCHAR(32),
    ifsign                              VARCHAR(32),
    ifoverinvest                        VARCHAR(32),
    overinvest                          TEXT,
    ifoperate                           VARCHAR(32),
    ifrunexpect                         VARCHAR(32),
    schedulecheckcondition              TEXT,
    lastschedulecheckcondition          TEXT,
    capitalcheckcondition               TEXT,
    lastcapitalcheckcondition           TEXT,
    purchasecheckcondition              TEXT,
    lastpurchasecheckcondition          TEXT,
    runcheckcondition                   TEXT,
    lastruncheckcondition               TEXT,
    supervisecheckcondition             TEXT,
    lastsupervisecheckcondition         TEXT,
    capitalfundinvoiced                 DECIMAL(18,2),
    capitalfunduninvoiced               DECIMAL(18,2),
    capitalfundused                     DECIMAL(18,2),
    loanfundinvoiced                    DECIMAL(18,2),
    loanfunduninvoiced                  DECIMAL(18,2),
    loanfundused                        DECIMAL(18,2),
    otherfundinvoiced                   DECIMAL(18,2),
    otherfunduninvoiced                 DECIMAL(18,2),
    otherfundused                       DECIMAL(18,2),
    totalinvestinvoiced                 DECIMAL(18,2),
    totalinvestuninvoiced               DECIMAL(18,2),
    totalinvestused                     DECIMAL(18,2),
    explain                             TEXT,
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_specific_loan_check_info IS '特定贷款检查表';
COMMENT ON COLUMN app_specific_loan_check_info.id IS '主键ID';
COMMENT ON COLUMN app_specific_loan_check_info.reportno IS '报告编号';
COMMENT ON COLUMN app_specific_loan_check_info.customerid IS '客户编号';
COMMENT ON COLUMN app_specific_loan_check_info.customername IS '客户名称';
COMMENT ON COLUMN app_specific_loan_check_info.objectname IS '对象名称（码值：固定资产/房地产开发贷款/经营性物业贷款/厂房通贷款）';
COMMENT ON COLUMN app_specific_loan_check_info.productname IS '基础产品';
COMMENT ON COLUMN app_specific_loan_check_info.productbelongname IS '产品归属';
COMMENT ON COLUMN app_specific_loan_check_info.contractno IS '业务合同编号';
COMMENT ON COLUMN app_specific_loan_check_info.businesssum IS '授信金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.balance IS '用信余额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.duebilltotalbusinesssum IS '用信金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.nominalbalancesum IS '用信敞口余额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.repaysum IS '已还本金（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.purpose IS '用途';
COMMENT ON COLUMN app_specific_loan_check_info.vouchtype IS '担保方式';
COMMENT ON COLUMN app_specific_loan_check_info.projectbegindate IS '项目启动年月';
COMMENT ON COLUMN app_specific_loan_check_info.projectfinishdate IS '（预计）项目完工年月';
COMMENT ON COLUMN app_specific_loan_check_info.ifbulid IS '是否建设期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifconstructionexpect IS '建设期进度是否符合预期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifgetpermission IS '是否取得预售证（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifmatch IS '资金使用是否与项目进度匹配（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifopenaccount IS '是否开立监管账户（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifsign IS '资金监管协议是否已签署（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifoverinvest IS '是否存在超投情况（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.overinvest IS '超投情况说明';
COMMENT ON COLUMN app_specific_loan_check_info.ifoperate IS '是否运营期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.ifrunexpect IS '运营是否符合预期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_check_info.schedulecheckcondition IS '项目建设进度本次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.lastschedulecheckcondition IS '项目建设进度前次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.capitalcheckcondition IS '项目资本金情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.lastcapitalcheckcondition IS '项目资本金情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.purchasecheckcondition IS '建安工程或设备采购支出情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.lastpurchasecheckcondition IS '建安工程或设备采购支出情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.runcheckcondition IS '运营检查本次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.lastruncheckcondition IS '运营检查前次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.supervisecheckcondition IS '资金监管情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.lastsupervisecheckcondition IS '资金监管情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_check_info.capitalfundinvoiced IS '资本金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.capitalfunduninvoiced IS '资本金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.capitalfundused IS '资本金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.loanfundinvoiced IS '贷款资金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.loanfunduninvoiced IS '贷款资金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.loanfundused IS '贷款资金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.otherfundinvoiced IS '其他资金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.otherfunduninvoiced IS '其他资金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.otherfundused IS '其他资金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.totalinvestinvoiced IS '总投资已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.totalinvestuninvoiced IS '总投资未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.totalinvestused IS '总投资已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_check_info.explain IS '说明';
COMMENT ON COLUMN app_specific_loan_check_info.inputtime IS '入库时间';
CREATE INDEX idx_specific_loan_check_info_customerid ON app_specific_loan_check_info (customerid);
CREATE INDEX idx_specific_loan_check_info_reportno ON app_specific_loan_check_info (reportno);

-- ---------------------------------------------------------------
-- [42/45] app_specific_loan_operate_check_info —— 特定贷款检查表-经营收入类（经营性物业贷款/厂房通贷款，检查租金经营收入/租户/出租预期/抵押物/监管）
-- ---------------------------------------------------------------
CREATE TABLE app_specific_loan_operate_check_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    objectname                          VARCHAR(64),
    balance                             DECIMAL(18,2),
    businesssum                         DECIMAL(18,2),
    contractno                          VARCHAR(64),
    duebilltotalbusinesssum             DECIMAL(18,2),
    expectation                         VARCHAR(64),
    expectation2                        VARCHAR(64),
    ifchange                            VARCHAR(32),
    ifdown                              VARCHAR(32),
    ifdownexplain                       TEXT,
    ifopenaccount                       VARCHAR(32),
    ifpledge                            VARCHAR(32),
    ifpledgeexplain                     TEXT,
    ifsign                              VARCHAR(32),
    ifsupervise                         VARCHAR(32),
    income                              DECIMAL(18,2),
    incomecompare                       VARCHAR(64),
    indexyear                           INT,
    indexyearcompare                    INT,
    lastincome                          DECIMAL(18,2),
    lastincomecompare                   VARCHAR(64),
    lastlesseecount                     INT,
    lastlesseecountcompare              VARCHAR(64),
    lastoperatecdincomecondition        TEXT,
    lastoperateincomecondition          TEXT,
    lesseecount                         INT,
    lesseecountcompare                  VARCHAR(64),
    nominalbalancesum                   DECIMAL(18,2),
    operatecdincomecondition            TEXT,
    operateincomecondition              TEXT,
    productbelongname                   VARCHAR(128),
    productname                         VARCHAR(128),
    purpose                             VARCHAR(128),
    repaysum                            DECIMAL(18,2),
    signexplain                         TEXT,
    superviseexplain                    TEXT,
    vouchtype                           VARCHAR(32),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_specific_loan_operate_check_info IS '特定贷款检查表-经营收入类（经营性物业贷款/厂房通贷款，检查租金经营收入/租户/出租预期/抵押物/监管）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.id IS '主键ID';
COMMENT ON COLUMN app_specific_loan_operate_check_info.reportno IS '报告编号';
COMMENT ON COLUMN app_specific_loan_operate_check_info.customerid IS '客户编号';
COMMENT ON COLUMN app_specific_loan_operate_check_info.customername IS '客户名称';
COMMENT ON COLUMN app_specific_loan_operate_check_info.objectname IS '对象名称（码值：经营性物业贷款/厂房通贷款）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.balance IS '用信余额（万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.businesssum IS '授信金额（万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.contractno IS '业务合同编号';
COMMENT ON COLUMN app_specific_loan_operate_check_info.duebilltotalbusinesssum IS '用信金额（万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.expectation IS '出租情况是否符合预期（码值：是/否，文本结论）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.expectation2 IS '物业收入是否符合预期（码值：是/否，接口字段名保留）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifchange IS '出租情况或物业使用情况是否较授信时发生变化（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifdown IS '抵押物价值是否有显著下降（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifdownexplain IS '抵押物价值显著下降说明';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifopenaccount IS '是否开立监管账户（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifpledge IS '抵押物是否存在查封或其他抵押的情况（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifpledgeexplain IS '抵押物查封或其他抵押情况说明';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifsign IS '租金监管协议是否已签署（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.ifsupervise IS '物业经营收入是否需要监管（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.income IS '承贷物业的经营收入（本次检查，万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.incomecompare IS '承贷物业的经营收入与业务申报方案相比（结论文本）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.indexyear IS '年份（本次检查年度，如2026）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.indexyearcompare IS '比较年份（如2025）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastincome IS '经营收入（上年/前次，万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastincomecompare IS '经营收入与业务申报方案相比（上年/前次）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastlesseecount IS '租户租数（前次/上年）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastlesseecountcompare IS '租户租数与业务申报方案相比（前次/上年）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastoperatecdincomecondition IS '承贷物业的经营收入前次检查情况';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lastoperateincomecondition IS '前次物业收入及还款来源分析';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lesseecount IS '租户租数（本次）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.lesseecountcompare IS '租户租数与业务申报方案相比（本次）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.nominalbalancesum IS '用信敞口余额（万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.operatecdincomecondition IS '承贷物业的经营收入本次检查情况';
COMMENT ON COLUMN app_specific_loan_operate_check_info.operateincomecondition IS '物业收入及还款来源分析（本次）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.productbelongname IS '产品归属';
COMMENT ON COLUMN app_specific_loan_operate_check_info.productname IS '基础产品';
COMMENT ON COLUMN app_specific_loan_operate_check_info.purpose IS '用途';
COMMENT ON COLUMN app_specific_loan_operate_check_info.repaysum IS '已还本金（万元）';
COMMENT ON COLUMN app_specific_loan_operate_check_info.signexplain IS '租金监管协议签署说明';
COMMENT ON COLUMN app_specific_loan_operate_check_info.superviseexplain IS '开立监管账户说明';
COMMENT ON COLUMN app_specific_loan_operate_check_info.vouchtype IS '担保方式';
COMMENT ON COLUMN app_specific_loan_operate_check_info.inputtime IS '入库时间';
CREATE INDEX idx_specific_loan_operate_check_info_customerid ON app_specific_loan_operate_check_info (customerid);
CREATE INDEX idx_specific_loan_operate_check_info_reportno ON app_specific_loan_operate_check_info (reportno);

-- ---------------------------------------------------------------
-- [43/45] app_specific_loan_project_check_info —— 特定贷款检查表-项目类（固定资产贷款/房地产开发贷款，检查项目资本金/建设进度/资金开票使用/超投/预售）
-- ---------------------------------------------------------------
CREATE TABLE app_specific_loan_project_check_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    objectname                          VARCHAR(64),
    balance                             DECIMAL(18,2),
    businesssum                         DECIMAL(18,2),
    capitalcheckcondition               TEXT,
    capitalfundinvoiced                 DECIMAL(18,2),
    capitalfunduninvoiced               DECIMAL(18,2),
    capitalfundused                     DECIMAL(18,2),
    contractno                          VARCHAR(64),
    duebilltotalbusinesssum             DECIMAL(18,2),
    explain                             TEXT,
    ifbuild                             VARCHAR(32),
    ifconstructionexpect                VARCHAR(32),
    ifgetpermission                     VARCHAR(32),
    ifmatch                             VARCHAR(32),
    ifopenaccount                       VARCHAR(32),
    ifoperate                           VARCHAR(32),
    ifoverinvest                        VARCHAR(32),
    ifrunexpect                         VARCHAR(32),
    ifsign                              VARCHAR(32),
    lastcapitalcheckcondition           TEXT,
    lastpurchasecheckcondition          TEXT,
    lastruncheckcondition               TEXT,
    lastschedulecheckcondition          TEXT,
    lastsupervisecheckcondition         TEXT,
    loanfundinvoiced                    DECIMAL(18,2),
    loanfunduninvoiced                  DECIMAL(18,2),
    loanfundused                        DECIMAL(18,2),
    nominalbalancesum                   DECIMAL(18,2),
    otherfundinvoiced                   DECIMAL(18,2),
    otherfunduninvoiced                 DECIMAL(18,2),
    otherfundused                       DECIMAL(18,2),
    overinvest                          TEXT,
    productbelongname                   VARCHAR(128),
    productname                         VARCHAR(128),
    projectbegindate                    VARCHAR(32),
    projectfinishdate                   VARCHAR(32),
    purchasecheckcondition              TEXT,
    purpose                             VARCHAR(128),
    repaysum                            DECIMAL(18,2),
    runcheckcondition                   TEXT,
    schedulecheckcondition              TEXT,
    supervisecheckcondition             TEXT,
    totalinvestinvoiced                 DECIMAL(18,2),
    totalinvestuninvoiced               DECIMAL(18,2),
    totalinvestused                     DECIMAL(18,2),
    vouchtype                           VARCHAR(32),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_specific_loan_project_check_info IS '特定贷款检查表-项目类（固定资产贷款/房地产开发贷款，检查项目资本金/建设进度/资金开票使用/超投/预售）';
COMMENT ON COLUMN app_specific_loan_project_check_info.id IS '主键ID';
COMMENT ON COLUMN app_specific_loan_project_check_info.reportno IS '报告编号';
COMMENT ON COLUMN app_specific_loan_project_check_info.customerid IS '客户编号';
COMMENT ON COLUMN app_specific_loan_project_check_info.customername IS '客户名称';
COMMENT ON COLUMN app_specific_loan_project_check_info.objectname IS '对象名称（码值：固定资产/房地产开发贷款）';
COMMENT ON COLUMN app_specific_loan_project_check_info.balance IS '用信余额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.businesssum IS '授信金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.capitalcheckcondition IS '项目资本金情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.capitalfundinvoiced IS '资本金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.capitalfunduninvoiced IS '资本金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.capitalfundused IS '资本金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.contractno IS '业务合同编号';
COMMENT ON COLUMN app_specific_loan_project_check_info.duebilltotalbusinesssum IS '用信金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.explain IS '说明（项目情况说明）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifbuild IS '是否建设期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifconstructionexpect IS '建设期进度是否符合预期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifgetpermission IS '是否取得预售证（码值：是/否/不涉及）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifmatch IS '资金使用是否与项目进度匹配（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifopenaccount IS '是否开立监管账户（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifoperate IS '是否运营期（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifoverinvest IS '是否存在超投情况（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifrunexpect IS '运营是否符合预期（码值：是/否/不涉及）';
COMMENT ON COLUMN app_specific_loan_project_check_info.ifsign IS '资金监管协议是否已签署（码值：是/否）';
COMMENT ON COLUMN app_specific_loan_project_check_info.lastcapitalcheckcondition IS '项目资本金情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.lastpurchasecheckcondition IS '建安工程或设备采购支出情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.lastruncheckcondition IS '运营检查前次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.lastschedulecheckcondition IS '项目建设进度前次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.lastsupervisecheckcondition IS '资金监管情况前次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.loanfundinvoiced IS '贷款资金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.loanfunduninvoiced IS '贷款资金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.loanfundused IS '贷款资金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.nominalbalancesum IS '用信敞口余额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.otherfundinvoiced IS '其他资金已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.otherfunduninvoiced IS '其他资金未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.otherfundused IS '其他资金已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.overinvest IS '超投情况说明';
COMMENT ON COLUMN app_specific_loan_project_check_info.productbelongname IS '产品归属';
COMMENT ON COLUMN app_specific_loan_project_check_info.productname IS '基础产品';
COMMENT ON COLUMN app_specific_loan_project_check_info.projectbegindate IS '项目启动年月';
COMMENT ON COLUMN app_specific_loan_project_check_info.projectfinishdate IS '（预计）项目完工年月';
COMMENT ON COLUMN app_specific_loan_project_check_info.purchasecheckcondition IS '建安工程或设备采购支出情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.purpose IS '用途';
COMMENT ON COLUMN app_specific_loan_project_check_info.repaysum IS '已还本金（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.runcheckcondition IS '运营检查本次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.schedulecheckcondition IS '项目建设进度本次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.supervisecheckcondition IS '资金监管情况本次检查情况';
COMMENT ON COLUMN app_specific_loan_project_check_info.totalinvestinvoiced IS '总投资已开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.totalinvestuninvoiced IS '总投资未开票金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.totalinvestused IS '总投资已使用金额（万元）';
COMMENT ON COLUMN app_specific_loan_project_check_info.vouchtype IS '担保方式';
COMMENT ON COLUMN app_specific_loan_project_check_info.inputtime IS '入库时间';
CREATE INDEX idx_specific_loan_project_check_info_customerid ON app_specific_loan_project_check_info (customerid);
CREATE INDEX idx_specific_loan_project_check_info_reportno ON app_specific_loan_project_check_info (reportno);

-- ---------------------------------------------------------------
-- [44/45] app_top_five_updown_info —— 前五大上下游表
-- ---------------------------------------------------------------
CREATE TABLE app_top_five_updown_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    supplier                            VARCHAR(128),
    suppliertype                        VARCHAR(64),
    suppliertypename                    VARCHAR(64),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_top_five_updown_info IS '前五大上下游表';
COMMENT ON COLUMN app_top_five_updown_info.id IS '主键ID';
COMMENT ON COLUMN app_top_five_updown_info.reportno IS '报告编号';
COMMENT ON COLUMN app_top_five_updown_info.customerid IS '客户编号';
COMMENT ON COLUMN app_top_five_updown_info.customername IS '客户名称';
COMMENT ON COLUMN app_top_five_updown_info.supplier IS '供应商名称';
COMMENT ON COLUMN app_top_five_updown_info.suppliertype IS '供应商类型';
COMMENT ON COLUMN app_top_five_updown_info.suppliertypename IS '供应商类型名称';
COMMENT ON COLUMN app_top_five_updown_info.inputtime IS '入库时间';
CREATE INDEX idx_top_five_updown_info_customerid ON app_top_five_updown_info (customerid);
CREATE INDEX idx_top_five_updown_info_reportno ON app_top_five_updown_info (reportno);

-- ---------------------------------------------------------------
-- [45/45] app_xd_shareholder_info —— 信贷系统股东表（最新时点）
-- ---------------------------------------------------------------
CREATE TABLE app_xd_shareholder_info (
    id                                  BIGINT NOT NULL AUTO_INCREMENT,
    reportno                            VARCHAR(64) NOT NULL,
    customerid                          VARCHAR(64),
    customername                        VARCHAR(128),
    name                                VARCHAR(128),
    investmentprop                      DECIMAL(12,4),
    relationship                        VARCHAR(128),
    currencytype                        VARCHAR(64),
    oughtsum                            DECIMAL(18,2),
    investmentsum                       DECIMAL(18,2),
    investdate                          VARCHAR(64),
    inputuserid                         VARCHAR(64),
    inputorgid                          VARCHAR(64),
    inputtime                           TIMESTAMP DEFAULT pg_systimestamp(),
    PRIMARY KEY (id)
);
COMMENT ON TABLE app_xd_shareholder_info IS '信贷系统股东表（最新时点）';
COMMENT ON COLUMN app_xd_shareholder_info.id IS '主键ID';
COMMENT ON COLUMN app_xd_shareholder_info.reportno IS '报告编号';
COMMENT ON COLUMN app_xd_shareholder_info.customerid IS '客户编号';
COMMENT ON COLUMN app_xd_shareholder_info.customername IS '客户名称';
COMMENT ON COLUMN app_xd_shareholder_info.name IS '股东名称';
COMMENT ON COLUMN app_xd_shareholder_info.investmentprop IS '持股比例（%）';
COMMENT ON COLUMN app_xd_shareholder_info.relationship IS '出资方式';
COMMENT ON COLUMN app_xd_shareholder_info.currencytype IS '币种';
COMMENT ON COLUMN app_xd_shareholder_info.oughtsum IS '应出资金额（万元）';
COMMENT ON COLUMN app_xd_shareholder_info.investmentsum IS '实际投资金额（万元）';
COMMENT ON COLUMN app_xd_shareholder_info.investdate IS '投资时间';
COMMENT ON COLUMN app_xd_shareholder_info.inputuserid IS '登记人';
COMMENT ON COLUMN app_xd_shareholder_info.inputorgid IS '登记机构';
COMMENT ON COLUMN app_xd_shareholder_info.inputtime IS '入库时间';
CREATE INDEX idx_xd_shareholder_info_customerid ON app_xd_shareholder_info (customerid);
CREATE INDEX idx_xd_shareholder_info_reportno ON app_xd_shareholder_info (reportno);


-- =====================================================================
-- 附：《本工程补写的列注释》共 45 列（来源库这些列本就无注释）
-- =====================================================================
--   app_capital_flow_info.id  ->  主键ID
--   app_check_index_info.id  ->  主键ID
--   app_check_object_info.id  ->  主键ID
--   app_check_opinion_info.id  ->  主键ID
--   app_check_record_info.id  ->  主键ID
--   app_collateral_info.id  ->  主键ID
--   app_collateral_mortgage_info.id  ->  主键ID
--   app_collateral_restricted_right.id  ->  主键ID
--   app_credit_approval_manage_req_info.CONDITION  ->  批复后续管理要求
--   app_credit_debt_detail.id  ->  主键ID
--   app_credit_query_info.id  ->  主键ID
--   app_credit_report_info.id  ->  主键ID
--   app_credit_use_info.id  ->  主键ID
--   app_customer_info.id  ->  主键ID
--   app_early_warning_info.id  ->  主键ID
--   app_early_warning_opinion_info.id  ->  主键ID
--   app_early_warning_signal_info.id  ->  主键ID
--   app_entrust_pay_info.id  ->  主键ID
--   app_finance_index_info.id  ->  主键ID
--   app_finance_indicator_info.id  ->  主键ID
--   app_finance_indicator_info.guarantorid  ->  担保人客户编号（subjectType=担保人时填写）
--   app_finance_indicator_info.guarantorname  ->  担保人名称（subjectType=担保人时填写）
--   app_finance_indicator_info.subjecttype  ->  主体类型（码值：借款人/担保人）
--   app_finance_report_info.id  ->  主键ID
--   app_guarantor_credit_info.id  ->  主键ID
--   app_guarantor_info.id  ->  主键ID
--   app_guofa_report_info.id  ->  主键ID
--   app_ic_info.id  ->  主键ID
--   app_ic_shareholder_info.id  ->  主键ID
--   app_loan_plan_info.id  ->  主键ID
--   app_loan_receipt_info.id  ->  主键ID
--   app_opinion_info.id  ->  主键ID
--   app_payroll_stat_info.id  ->  主键ID
--   app_report_info.id  ->  主键ID
--   app_reputation_event_info.id  ->  主键ID
--   app_settle_account_info.id  ->  主键ID
--   app_settle_asset_info.id  ->  主键ID
--   app_settle_counterparty_info.id  ->  主键ID
--   app_shareholder_info.id  ->  主键ID
--   app_single_check_task_info.id  ->  主键ID
--   app_specific_loan_check_info.id  ->  主键ID
--   app_specific_loan_operate_check_info.id  ->  主键ID
--   app_specific_loan_project_check_info.id  ->  主键ID
--   app_top_five_updown_info.id  ->  主键ID
--   app_xd_shareholder_info.id  ->  主键ID
--
-- 语句统计：CREATE TABLE 45 张 / 列 842 / 索引 102 个
--   （2026-09-16 变更前为 840 列；+2 = app_reputation_event_info.eventtypecode / eventtypeorder）
