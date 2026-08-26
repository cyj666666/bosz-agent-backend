-- =====================================================================
-- 征信信息（企业/个人）· 数据落表 DDL（v1.1）
-- 数据来源：temp.xlsx（A列数据类别=征信信息；B列数据维度=企业|个人；C列中文字段；I列英文字段）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 设计约定：
--   1. 按 B 列数据维度拆 2 张表：企业征信信息表 + 个人征信信息表
--   2. 英文字段名照抄材料 I 列（含大小写/数字），按用户确认做以下处理：
--      - 去掉"新增："前缀（如 新增：qy_dwdb_bal_exc_wx -> qy_dwdb_bal_exc_wx）
--      - 多来源"|"分隔的字段两个都存（征信报告编号：企业 EA01A_I01+BGBH；个人 GRZX_234+PA01AI01）
--      - 描述性字段按材料 org_Type 用 sumOrgBal 拼（zhanqi_sumOrgBal 等 5 处）
--      - 非法字符修正（qy_wjq.yhcdhp_cnt -> qy_wjq_yhcdhp_cnt）
--      - 材料笔误修正（IOAN_CURRENT_TOTAL_OVERDUE -> LOAN_CURRENT_TOTAL_OVERDUE）
--   3. 中文注释严格按材料 C 列/K 列（合并单元格 C56:C57 的补充字段中文名取 K 列）
--   4. 每张表公共字段：reportNo(报告编号)、zx_record_no(征信报告查询记录号，来自信贷)、
--      customerId(信贷客户编号)、customerName(客户名称)、inputtime(入库时间)
--   5. 类型：材料无类型列，全部 VARCHAR（用户确认）
--   6. reportNo / customerId / customerName 列均建索引
--   7. 接口返回直接追加插入，不做去重约束
--
-- 新增合计字段说明：
--   - 企业 qy_zqjk_dqjk_bal：中长期借款与短期借款未结清余额合计（= qy_wjq_zcqjkzh_bal + qy_wjq_dqjkzh_bal）
--   - 个人 gr_dwdb_wjfl_abn_bal：对外担保（相关还款责任）五级分类非正常余额合计
--     （= as_all_all_class2_balAmt 对外担保关注余额 + ge_as_defaultclass_balAmt 个人对外担保不良余额）
--
-- 语法适配（实测验证）：
--   - 建表语句内不写列注释/表注释/索引子句
--   - 注释用 COMMENT ON TABLE / COMMENT ON COLUMN 单独写
--   - 索引用 CREATE INDEX IF NOT EXISTS 单独建
--   - 主键：id BIGINT not null AUTO_INCREMENT + 表级 primary key (id)
-- =====================================================================

-- #####################################################################
-- 1. 企业征信信息表（B列=企业，行2~38）
-- #####################################################################
CREATE TABLE IF NOT EXISTS zx_ent_credit_info (
    id                          BIGINT not null AUTO_INCREMENT,
    reportNo                    VARCHAR(64) NOT NULL,
    customerId                  VARCHAR(64),
    customerName                VARCHAR(128),
    zx_record_no                VARCHAR(64),
    EA01A_I01                   VARCHAR(64),
    BGBH                        VARCHAR(64),
    BGSJ                        VARCHAR(64),
    EB02A_J03                   VARCHAR(64),
    eb01a_j06                   VARCHAR(64),
    EB01A_J03                   VARCHAR(64),
    eb01a_j07                   VARCHAR(64),
    EB01A_J04                   VARCHAR(64),
    BTX_ZRLXBZR_WJFLHJ_YQZE     VARCHAR(64),
    BTX_ZRLXBZR_WJFLGZ_YE       VARCHAR(64),
    BTX_ZRLXBZR_WJFLBL_YE       VARCHAR(64),
    qy_dwdb_bal_exc_wx          VARCHAR(64),
    qy_fyjg_dwdb_bal            VARCHAR(64),
    qy_fyjg_liab_tot            VARCHAR(64),
    qy_hzyh_rzzl_cnt            VARCHAR(64),
    zhanqi_sumOrgBal            VARCHAR(64),
    zichanChongzu_sumOrgBal     VARCHAR(64),
    wubenXudai_sumOrgBal        VARCHAR(64),
    qitaZhuanru_sumOrgBal       VARCHAR(64),
    jiexinHuanjiu_sumOrgBal     VARCHAR(64),
    qy_wjq_zcqjkzh_cnt          VARCHAR(64),
    qy_wjq_zcqjkzh_bal          VARCHAR(64),
    qy_wjq_dqjkzh_cnt           VARCHAR(64),
    qy_wjq_dqjkzh_bal           VARCHAR(64),
    qy_wjq_xhtzzh_cnt           VARCHAR(64),
    qy_wjq_xhtzzh_bal           VARCHAR(64),
    qy_wjq_txzh_cnt             VARCHAR(64),
    qy_wjq_txzh_bal             VARCHAR(64),
    qy_wjq_yhcdhp_cnt           VARCHAR(64),
    qy_wjq_yhcdhp_bal           VARCHAR(64),
    qy_wjq_xyz_cnt              VARCHAR(64),
    qy_wjq_xyz_bal              VARCHAR(64),
    qy_wjq_yhbh_cnt             VARCHAR(64),
    qy_wjq_yhbh_bal             VARCHAR(64),
    qy_wjq_qtdbzh_cnt           VARCHAR(64),
    qy_wjq_qtdbzh_bal           VARCHAR(64),
    qy_zqjk_dqjk_bal            VARCHAR(64),
    qy_fyjg_gjlv_loan_max       VARCHAR(64),
    inputtime                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE zx_ent_credit_info IS '企业征信信息表（B列=企业）';
COMMENT ON COLUMN zx_ent_credit_info.id IS '主键';
COMMENT ON COLUMN zx_ent_credit_info.reportNo IS '报告编号';
COMMENT ON COLUMN zx_ent_credit_info.customerId IS '信贷客户编号';
COMMENT ON COLUMN zx_ent_credit_info.customerName IS '客户名称';
COMMENT ON COLUMN zx_ent_credit_info.zx_record_no IS '征信报告查询记录号（来自信贷）';
COMMENT ON COLUMN zx_ent_credit_info.EA01A_I01 IS '企业征信报告编号（征信简报）';
COMMENT ON COLUMN zx_ent_credit_info.BGBH IS '企业征信报告编号（衍生平台）';
COMMENT ON COLUMN zx_ent_credit_info.BGSJ IS '征信查询时间';
COMMENT ON COLUMN zx_ent_credit_info.EB02A_J03 IS '未结清信贷的逾期总额';
COMMENT ON COLUMN zx_ent_credit_info.eb01a_j06 IS '未结清关注类担保交易余额';
COMMENT ON COLUMN zx_ent_credit_info.EB01A_J03 IS '未结清关注类信贷余额';
COMMENT ON COLUMN zx_ent_credit_info.eb01a_j07 IS '未结清不良类担保交易余额';
COMMENT ON COLUMN zx_ent_credit_info.EB01A_J04 IS '未结清不良类借贷余额';
COMMENT ON COLUMN zx_ent_credit_info.BTX_ZRLXBZR_WJFLHJ_YQZE IS '对外担保（相关还款责任）未结清逾期类负债总额';
COMMENT ON COLUMN zx_ent_credit_info.BTX_ZRLXBZR_WJFLGZ_YE IS '对外担保（相关还款责任）未结清关注类负债总额';
COMMENT ON COLUMN zx_ent_credit_info.BTX_ZRLXBZR_WJFLBL_YE IS '对外担保（相关还款责任）未结清不良类负债总额';
COMMENT ON COLUMN zx_ent_credit_info.qy_dwdb_bal_exc_wx IS '对外担保（相关还款责任）余额（剔除我行）';
COMMENT ON COLUMN zx_ent_credit_info.qy_fyjg_dwdb_bal IS '在非银机构对外担保余额';
COMMENT ON COLUMN zx_ent_credit_info.qy_fyjg_liab_tot IS '在非银机构负债合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_hzyh_rzzl_cnt IS '合作银行及融资租赁机构数';
COMMENT ON COLUMN zx_ent_credit_info.zhanqi_sumOrgBal IS '展期债务未结清余额（org_Type=zhanqi展期，sumOrgBal合计余额）';
COMMENT ON COLUMN zx_ent_credit_info.zichanChongzu_sumOrgBal IS '重组债务未结清余额（org_Type=zichanChongzu资产重组，sumOrgBal合计余额）';
COMMENT ON COLUMN zx_ent_credit_info.wubenXudai_sumOrgBal IS '无还本续贷未结清余额（org_Type=wubenXudai无本续贷，sumOrgBal合计余额）';
COMMENT ON COLUMN zx_ent_credit_info.qitaZhuanru_sumOrgBal IS '其他机构转入未结清余额（org_Type=qitaZhuanru其他机构转入，sumOrgBal合计余额）';
COMMENT ON COLUMN zx_ent_credit_info.jiexinHuanjiu_sumOrgBal IS '借新还旧债务未结清余额（org_Type=jiexinHuanjiu借新还旧，sumOrgBal合计余额）';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_zcqjkzh_cnt IS '中长期借款未结清账户数合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_zcqjkzh_bal IS '中长期借款未结清余额合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_dqjkzh_cnt IS '短期借款未结清账户数合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_dqjkzh_bal IS '短期借款未结清余额合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_xhtzzh_cnt IS '循环透支未结清账户数合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_xhtzzh_bal IS '循环透支未结清余额合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_txzh_cnt IS '贴现未结清账户数合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_txzh_bal IS '贴现未结清余额合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_yhcdhp_cnt IS '银行承兑汇票未结清账户数合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_yhcdhp_bal IS '银行承兑汇票未结清余额合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_xyz_cnt IS '信用证未结清账户数合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_xyz_bal IS '信用证未结清余额合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_yhbh_cnt IS '银行保函未结清账户数合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_yhbh_bal IS '银行保函未结清余额合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_qtdbzh_cnt IS '其他担保交易未结清账户数合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_wjq_qtdbzh_bal IS '其他担保交易未结清余额合计';
COMMENT ON COLUMN zx_ent_credit_info.qy_zqjk_dqjk_bal IS '中长期借款与短期借款未结清余额合计（=qy_wjq_zcqjkzh_bal中长期借款未结清余额+qy_wjq_dqjkzh_bal短期借款未结清余额）';
COMMENT ON COLUMN zx_ent_credit_info.qy_fyjg_gjlv_loan_max IS '企业存在非银机构较高利率借款（企业非银机构流贷等贷款的推算利率最大值）';
COMMENT ON COLUMN zx_ent_credit_info.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_reportNo ON zx_ent_credit_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON zx_ent_credit_info (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON zx_ent_credit_info (customerName);
CREATE INDEX IF NOT EXISTS idx_zx_record_no ON zx_ent_credit_info (zx_record_no);

-- #####################################################################
-- 2. 个人征信信息表（B列=个人，行39~75）
-- #####################################################################
CREATE TABLE IF NOT EXISTS zx_per_credit_info (
    id                              BIGINT not null AUTO_INCREMENT,
    reportNo                        VARCHAR(64) NOT NULL,
    customerId                      VARCHAR(64),
    customerName                    VARCHAR(128),
    zx_record_no                    VARCHAR(64),
    GRZX_234                        VARCHAR(64),
    PA01AI01                        VARCHAR(64),
    zxBiRPTIME                      VARCHAR(64),
    TOTAL_COUNT                     VARCHAR(64),
    JY_LOAN_BAL                     VARCHAR(64),
    XF_LOAN_BAL                     VARCHAR(64),
    ZF_LOAN_BAL                     VARCHAR(64),
    QT_LOAN_BAL                     VARCHAR(64),
    TOTAL_BAL                       VARCHAR(64),
    JY_LOAN_COUNT                   VARCHAR(64),
    XF_LOAN_COUNT                   VARCHAR(64),
    ZF_LOAN_COUNT                   VARCHAR(64),
    QT_LOAN_COUNT                   VARCHAR(64),
    BZC_BAL                         VARCHAR(64),
    BAD_BAL                         VARCHAR(64),
    LOAN_CURRENT_TOTAL_OVERDUE      VARCHAR(64),
    CREDIT_CARD_CUR_TOTAL_OVERDUE   VARCHAR(64),
    ge_dwdb_ovd_amt                 VARCHAR(64),
    as_all_all_class2_balAmt        VARCHAR(64),
    ge_as_defaultclass_balAmt       VARCHAR(64),
    gr_dwdb_wjfl_abn_bal            VARCHAR(64),
    SPEC_EXT_BALANCE                VARCHAR(64),
    SPEC_DELAY_BALANCE              VARCHAR(64),
    gr_wjq_crd_wjfl_abn_bal         VARCHAR(64),
    gr_wjq_acct_st_abn_bal          VARCHAR(64),
    gr_wxh_cc_st_abn_bal            VARCHAR(64),
    gr_dwdb_hk_st_abn_bal           VARCHAR(64),
    gr_fyjg_liab_tot                VARCHAR(64),
    gr_fyjg_dwdb_bal                VARCHAR(64),
    zxUtpgGt6uCCPr                  VARCHAR(64),
    zxBiEDULVL                      VARCHAR(64),
    QUERY_02_12                     VARCHAR(64),
    QUERY_02_6                      VARCHAR(64),
    QUERY_02_3                      VARCHAR(64),
    QUERY_03_12                     VARCHAR(64),
    QUERY_03_6                      VARCHAR(64),
    QUERY_03_3                      VARCHAR(64),
    zxRcy1MQuerCnt                  VARCHAR(64),
    gr_fyjg_gjlv_loan_max           VARCHAR(64),
    inputtime                       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE zx_per_credit_info IS '个人征信信息表（B列=个人）';
COMMENT ON COLUMN zx_per_credit_info.id IS '主键';
COMMENT ON COLUMN zx_per_credit_info.reportNo IS '报告编号';
COMMENT ON COLUMN zx_per_credit_info.customerId IS '信贷客户编号';
COMMENT ON COLUMN zx_per_credit_info.customerName IS '客户名称';
COMMENT ON COLUMN zx_per_credit_info.zx_record_no IS '征信报告查询记录号（来自信贷）';
COMMENT ON COLUMN zx_per_credit_info.GRZX_234 IS '个人征信报告编号（衍生平台）';
COMMENT ON COLUMN zx_per_credit_info.PA01AI01 IS '个人征信报告编号（征信简报）';
COMMENT ON COLUMN zx_per_credit_info.zxBiRPTIME IS '征信查询时间（报告时间）';
COMMENT ON COLUMN zx_per_credit_info.TOTAL_COUNT IS '贷款余额合计（合计-贷款余额）';
COMMENT ON COLUMN zx_per_credit_info.JY_LOAN_BAL IS '经营性贷款余额合计';
COMMENT ON COLUMN zx_per_credit_info.XF_LOAN_BAL IS '消费类贷款余额合计';
COMMENT ON COLUMN zx_per_credit_info.ZF_LOAN_BAL IS '住房类贷款余额合计';
COMMENT ON COLUMN zx_per_credit_info.QT_LOAN_BAL IS '其他贷款余额合计';
COMMENT ON COLUMN zx_per_credit_info.TOTAL_BAL IS '贷款机构数（所有贷款合计_贷款机构数，状态非结清）';
COMMENT ON COLUMN zx_per_credit_info.JY_LOAN_COUNT IS '经营性贷款机构数（状态非结清）';
COMMENT ON COLUMN zx_per_credit_info.XF_LOAN_COUNT IS '消费类贷款机构数（状态非结清）';
COMMENT ON COLUMN zx_per_credit_info.ZF_LOAN_COUNT IS '住房类贷款机构数（状态非结清）';
COMMENT ON COLUMN zx_per_credit_info.QT_LOAN_COUNT IS '其他贷款机构数（状态非结清）';
COMMENT ON COLUMN zx_per_credit_info.BZC_BAL IS '被追偿余额（被追偿信息汇总余额）';
COMMENT ON COLUMN zx_per_credit_info.BAD_BAL IS '呆账余额（呆账信息汇总余额）';
COMMENT ON COLUMN zx_per_credit_info.LOAN_CURRENT_TOTAL_OVERDUE IS '贷款当前逾期总金额（材料 IOAN_CURRENT_TOTAL_OVERDUE 笔误修正）';
COMMENT ON COLUMN zx_per_credit_info.CREDIT_CARD_CUR_TOTAL_OVERDUE IS '贷记卡当前逾期总金额';
COMMENT ON COLUMN zx_per_credit_info.ge_dwdb_ovd_amt IS '对外担保（相关还款责任）当前逾期金额（个人对外担保逾期余额）';
COMMENT ON COLUMN zx_per_credit_info.as_all_all_class2_balAmt IS '对外担保（相关还款责任）五级分类非正常余额-关注（对外担保关注余额）';
COMMENT ON COLUMN zx_per_credit_info.ge_as_defaultclass_balAmt IS '个人对外担保不良余额';
COMMENT ON COLUMN zx_per_credit_info.gr_dwdb_wjfl_abn_bal IS '对外担保（相关还款责任）五级分类非正常余额合计（=as_all_all_class2_balAmt对外担保关注余额+ge_as_defaultclass_balAmt个人对外担保不良余额）';
COMMENT ON COLUMN zx_per_credit_info.SPEC_EXT_BALANCE IS '展期债务余额（展期余额）';
COMMENT ON COLUMN zx_per_credit_info.SPEC_DELAY_BALANCE IS '落实金融困等政策银行主动延期债务余额（银行主动延期余额）';
COMMENT ON COLUMN zx_per_credit_info.gr_wjq_crd_wjfl_abn_bal IS '未结清信贷五级分类非正常余额（关注+不良）';
COMMENT ON COLUMN zx_per_credit_info.gr_wjq_acct_st_abn_bal IS '未结清账户状态非正常余额';
COMMENT ON COLUMN zx_per_credit_info.gr_wxh_cc_st_abn_bal IS '未销户贷记卡账户状态非正常余额';
COMMENT ON COLUMN zx_per_credit_info.gr_dwdb_hk_st_abn_bal IS '对外担保（相关还款责任）还款状态非正常余额';
COMMENT ON COLUMN zx_per_credit_info.gr_fyjg_liab_tot IS '在非银机构负债合计（贷款_非银机构全部_余额）';
COMMENT ON COLUMN zx_per_credit_info.gr_fyjg_dwdb_bal IS '在非银机构对外担保余额';
COMMENT ON COLUMN zx_per_credit_info.zxUtpgGt6uCCPr IS '信用卡使用率（贷记卡账户最近6个月平均使用额度/授信总额）';
COMMENT ON COLUMN zx_per_credit_info.zxBiEDULVL IS '学历（基本信息学历）';
COMMENT ON COLUMN zx_per_credit_info.QUERY_02_12 IS '近一年贷款审批查征信询次数（近12个月查询记录数）';
COMMENT ON COLUMN zx_per_credit_info.QUERY_02_6 IS '近6个月贷款审批征信查询次数';
COMMENT ON COLUMN zx_per_credit_info.QUERY_02_3 IS '近3个月贷款审批征信查询次数';
COMMENT ON COLUMN zx_per_credit_info.QUERY_03_12 IS '近一年信用卡审批征信查询次数（近12个月查询记录数）';
COMMENT ON COLUMN zx_per_credit_info.QUERY_03_6 IS '近6个月信用卡审批征信查询次数';
COMMENT ON COLUMN zx_per_credit_info.QUERY_03_3 IS '近3个月信用卡审批征信查询次数';
COMMENT ON COLUMN zx_per_credit_info.zxRcy1MQuerCnt IS '近1个月本人查询征信查询次数';
COMMENT ON COLUMN zx_per_credit_info.gr_fyjg_gjlv_loan_max IS '个人存在非银机构较高利率借款';
COMMENT ON COLUMN zx_per_credit_info.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_reportNo ON zx_per_credit_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON zx_per_credit_info (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON zx_per_credit_info (customerName);
CREATE INDEX IF NOT EXISTS idx_zx_record_no ON zx_per_credit_info (zx_record_no);
