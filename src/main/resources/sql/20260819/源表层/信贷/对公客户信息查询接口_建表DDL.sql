-- =====================================================================
-- 对公客户信息查询接口 · 数据落表 DDL（v1.0）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 设计约定：
--   1. 按接口嵌套层级拆分：1 张主表 + 7 张子表
--      - 主表 = 企业概况对象 entCustomerInfoDto（单条对象，135 字段）+ 入参字段并入
--      - 子表 = 7 个数组（证件/高管/股东/对外投资/资产/账户/实际控制人）
--      - 注：实际控制人数组内还嵌套"实控人信息"数组（材料未定义内层字段，暂不建表，待补充）
--   2. 英文字段名 100% 照抄接口材料（驼峰/全大写保持），不做格式转换
--   3. 每张表公共字段：reportNo(报告编号)、customerId(客户编号)、
--      mfCustomerNo(核心客户编号，入参)、customerName(客户名称)、inputtime(入库时间)
--   4. 子表 mainId 逐层指向直接上级表主键（不建物理外键）
--   5. 类型映射：材料 [string]/[date]/[datetime] -> VARCHAR（存原串）；
--      材料 [double] -> DECIMAL(18,2)；inputtime -> TIMESTAMP
--   6. reportNo / customerId / mfCustomerNo / customerName 列均建索引
--   7. 接口返回直接追加插入，不做去重约束
--
-- 字段冲突处理（材料字段与公共字段同名，库列名不区分大小写）：
--   - 高管数组 customerName(高管姓名)    -> executiveName
--   - 股东数组 customerName(股东姓名)    -> shareholderName
--   - 投资数组 customerName(投向企业姓名) -> investCustomerName
--   - 各数组 customerId 与公共字段同义，合并使用公共字段
--   - 实控人数组 customerName(客户名称) 与公共字段同义，合并
--   - 材料 operateuserId/operateorgId/inputorgId/corpgId 等小写拼写按材料原样保留
--
-- 语法适配（实测验证）：
--   - 建表语句内不写列注释/表注释/索引子句
--   - 注释用 COMMENT ON TABLE / COMMENT ON COLUMN 单独写
--   - 索引用 CREATE INDEX IF NOT EXISTS 单独建
--   - 主键：id BIGINT not null AUTO_INCREMENT + 表级 primary key (id)
-- =====================================================================

-- #####################################################################
-- 1. 企业概况主表（entCustomerInfoDto + 入参并入）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_customer_info (
    id                          BIGINT not null AUTO_INCREMENT,
    reportNo                    VARCHAR(64) NOT NULL,
    mfCustomerNo                VARCHAR(64),
    customerId                  VARCHAR(64),
    customerName                VARCHAR(128),
    customerType                VARCHAR(64),
    certType                    VARCHAR(64),
    certId                      VARCHAR(64),
    status                      VARCHAR(64),
    inputOrgId                  VARCHAR(64),
    inputUserId                 VARCHAR(64),
    inputDate                   VARCHAR(64),
    remark                      VARCHAR(1000),
    certCountry                 VARCHAR(64),
    certMaturity                VARCHAR(64),
    manageUserId                VARCHAR(64),
    manageUserName              VARCHAR(128),
    manageOrgId                 VARCHAR(64),
    manageOrgName               VARCHAR(128),
    corpOrgId                   VARCHAR(64),
    completeFlag                VARCHAR(64),
    mfCustomerId                VARCHAR(64),
    englishName                 VARCHAR(128),
    uniformCreditCode           VARCHAR(64),
    orgNature                   VARCHAR(64),
    entScale                    VARCHAR(64),
    licenseNo                   VARCHAR(64),
    licenseDate                 VARCHAR(64),
    licenseMaturity             VARCHAR(64),
    licenseNoUpdateDate         VARCHAR(64),
    taxNo                       VARCHAR(64),
    loancardNo                  VARCHAR(64),
    corpCritUpdateDate          VARCHAR(64),
    supercorpName               VARCHAR(128),
    supercertType               VARCHAR(64),
    superloanCertId             VARCHAR(64),
    superloancardNo             VARCHAR(64),
    isProsecurity               VARCHAR(64),
    orgCategory                 VARCHAR(64),
    isRelacust                  VARCHAR(64),
    entType                     VARCHAR(64),
    enterpriseNature            VARCHAR(64),
    sourceType                  VARCHAR(64),
    holdType                    VARCHAR(64),
    rcCurrency                  VARCHAR(64),
    registerCapital             DECIMAL(18,2),
    pcCurrency                  VARCHAR(64),
    paidUpCapital               DECIMAL(18,2),
    registerCountry             VARCHAR(64),
    registerCountryCName        VARCHAR(128),
    registerRegioncode          VARCHAR(64),
    registerRegioncodeCName     VARCHAR(128),
    registerAdd                 VARCHAR(255),
    officeCountry               VARCHAR(64),
    officeRegioncode            VARCHAR(64),
    officeAdd                   VARCHAR(255),
    registerZip                 VARCHAR(64),
    officeZip                   VARCHAR(64),
    isCountryfirm               VARCHAR(64),
    enterpriseBelong            VARCHAR(64),
    isDevelopFlag               VARCHAR(64),
    govStation                  VARCHAR(128),
    isInvolveagriculture        VARCHAR(64),
    contactPeople               VARCHAR(128),
    officeTel                   VARCHAR(64),
    financedeptTel              VARCHAR(64),
    officeFax                   VARCHAR(64),
    emailAdd                    VARCHAR(128),
    webAdd                      VARCHAR(128),
    isGovfinpla                 VARCHAR(64),
    belongLevel                 VARCHAR(64),
    listingCorpCrit             VARCHAR(64),
    listingCorpCountryCrit      VARCHAR(64),
    breakRuleRate               VARCHAR(64),
    enterpriseIsOutPlace        VARCHAR(64),
    creditCustomerIndustryInfo  VARCHAR(1000),
    creditCustomerIndustryName  VARCHAR(128),
    fictitiousPerson            VARCHAR(128),
    isLocatedatIndustrialPark   VARCHAR(64),
    formattedAddress            VARCHAR(255),
    officeFormattedAddress      VARCHAR(255),
    setupDate                   VARCHAR(64),
    operateUserId               VARCHAR(64),
    operateOrgId                VARCHAR(64),
    operateDate                 VARCHAR(64),
    updateUserId                VARCHAR(64),
    updateOrgId                 VARCHAR(64),
    updateDate                  VARCHAR(64),
    transFlag                   VARCHAR(64),
    tbName                      VARCHAR(64),
    orgType                     VARCHAR(64),
    industryType                VARCHAR(64),
    employeeNumber              DECIMAL(18,2),
    annualIncome                DECIMAL(18,2),
    totalAssets                 DECIMAL(18,2),
    listingCorpType             VARCHAR(64),
    closeFlag                   VARCHAR(64),
    importRightsFlag            VARCHAR(64),
    creditLevel                 VARCHAR(64),
    workFieldArea               DECIMAL(18,2),
    revenue                     DECIMAL(18,2),
    workFieldFee                VARCHAR(64),
    isEntityEnt                 VARCHAR(64),
    strategicType               VARCHAR(64),
    isIndustupGrade             VARCHAR(64),
    industrialType              VARCHAR(64),
    isCulturalFlag              VARCHAR(64),
    intelligentType             VARCHAR(64),
    isStiEnt                    VARCHAR(64),
    isForeignTrade              VARCHAR(64),
    additionalRemark            VARCHAR(1000),
    businessScope               VARCHAR(1000),
    manageInfo                  VARCHAR(1000),
    customerHistory             VARCHAR(1000),
    mainProduction              VARCHAR(1000),
    nationCode                  VARCHAR(64),
    offSiteStatisticalOrgCode   VARCHAR(64),
    otherCreditLevel            VARCHAR(64),
    otherOrgName                VARCHAR(128),
    isKeyMan                    VARCHAR(64),
    listingCorpOrNot            VARCHAR(64),
    listingCityCode             VARCHAR(64),
    listingRegionCode           VARCHAR(64),
    listingRegionName           VARCHAR(128),
    listingCorpAdd              VARCHAR(255),
    economyType                 VARCHAR(64),
    isHeadOffice                VARCHAR(64),
    headOfficeNo                VARCHAR(128),
    manageArea                  VARCHAR(128),
    isBelongManager             VARCHAR(64),
    groupClientNo               VARCHAR(64),
    isCountyArea                VARCHAR(64),
    creditRatingResult          VARCHAR(64),
    warningLevel                VARCHAR(64),
    dangerLevel                 VARCHAR(64),
    corpCrit                    VARCHAR(64),
    formalStatus                VARCHAR(64),
    officeRegioncodeCName       VARCHAR(128),
    inputtime                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_customer_info IS '对公客户信息-企业概况主表（entCustomerInfoDto+入参）';
COMMENT ON COLUMN xd_corp_customer_info.id IS '主键';
COMMENT ON COLUMN xd_corp_customer_info.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_customer_info.mfCustomerNo IS '核心客户编号';
COMMENT ON COLUMN xd_corp_customer_info.customerId IS '客户编号';
COMMENT ON COLUMN xd_corp_customer_info.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_customer_info.customerType IS '客户分类';
COMMENT ON COLUMN xd_corp_customer_info.certType IS '证件类型';
COMMENT ON COLUMN xd_corp_customer_info.certId IS '证件号码';
COMMENT ON COLUMN xd_corp_customer_info.status IS '状态';
COMMENT ON COLUMN xd_corp_customer_info.inputOrgId IS '登记机构';
COMMENT ON COLUMN xd_corp_customer_info.inputUserId IS '登记人';
COMMENT ON COLUMN xd_corp_customer_info.inputDate IS '登记日期';
COMMENT ON COLUMN xd_corp_customer_info.remark IS '备注';
COMMENT ON COLUMN xd_corp_customer_info.certCountry IS '证件国别';
COMMENT ON COLUMN xd_corp_customer_info.certMaturity IS '证件到期日';
COMMENT ON COLUMN xd_corp_customer_info.manageUserId IS '主办客户经理工号';
COMMENT ON COLUMN xd_corp_customer_info.manageUserName IS '主办客户经理姓名';
COMMENT ON COLUMN xd_corp_customer_info.manageOrgId IS '主办机构编号';
COMMENT ON COLUMN xd_corp_customer_info.manageOrgName IS '主办机构名称';
COMMENT ON COLUMN xd_corp_customer_info.corpOrgId IS '经办机构';
COMMENT ON COLUMN xd_corp_customer_info.completeFlag IS '数据录入完整性标识';
COMMENT ON COLUMN xd_corp_customer_info.mfCustomerId IS 'ECIF客户号';
COMMENT ON COLUMN xd_corp_customer_info.englishName IS '客户英文名';
COMMENT ON COLUMN xd_corp_customer_info.uniformCreditCode IS '统一社会信用代码证';
COMMENT ON COLUMN xd_corp_customer_info.orgNature IS '机构类型';
COMMENT ON COLUMN xd_corp_customer_info.entScale IS '企业规模';
COMMENT ON COLUMN xd_corp_customer_info.licenseNo IS '工商营业执照号码';
COMMENT ON COLUMN xd_corp_customer_info.licenseDate IS '营业执照登记日';
COMMENT ON COLUMN xd_corp_customer_info.licenseMaturity IS '营业执照到期日';
COMMENT ON COLUMN xd_corp_customer_info.licenseNoUpdateDate IS '营业执照更新日期';
COMMENT ON COLUMN xd_corp_customer_info.taxNo IS '税务登记证号(国税)';
COMMENT ON COLUMN xd_corp_customer_info.loancardNo IS '中征码';
COMMENT ON COLUMN xd_corp_customer_info.corpCritUpdateDate IS '组织机构代码更新日期';
COMMENT ON COLUMN xd_corp_customer_info.supercorpName IS '上级公司名称';
COMMENT ON COLUMN xd_corp_customer_info.supercertType IS '上级公司证件类型';
COMMENT ON COLUMN xd_corp_customer_info.superloanCertId IS '上级公司证件号码';
COMMENT ON COLUMN xd_corp_customer_info.superloancardNo IS '上级公司中征码';
COMMENT ON COLUMN xd_corp_customer_info.isProsecurity IS '是否为专业担保公司';
COMMENT ON COLUMN xd_corp_customer_info.orgCategory IS '机构类别';
COMMENT ON COLUMN xd_corp_customer_info.isRelacust IS '是否我行关联方客户';
COMMENT ON COLUMN xd_corp_customer_info.entType IS '企业类型';
COMMENT ON COLUMN xd_corp_customer_info.enterpriseNature IS '企业性质';
COMMENT ON COLUMN xd_corp_customer_info.sourceType IS '客户来源渠道';
COMMENT ON COLUMN xd_corp_customer_info.holdType IS '控股类型';
COMMENT ON COLUMN xd_corp_customer_info.rcCurrency IS '注册资本币种';
COMMENT ON COLUMN xd_corp_customer_info.registerCapital IS '注册资本';
COMMENT ON COLUMN xd_corp_customer_info.pcCurrency IS '实收资本币种';
COMMENT ON COLUMN xd_corp_customer_info.paidUpCapital IS '实收资本';
COMMENT ON COLUMN xd_corp_customer_info.registerCountry IS '注册地址（国家）码值';
COMMENT ON COLUMN xd_corp_customer_info.registerCountryCName IS '注册地址（国家）名字';
COMMENT ON COLUMN xd_corp_customer_info.registerRegioncode IS '注册地址（省市区）码值';
COMMENT ON COLUMN xd_corp_customer_info.registerRegioncodeCName IS '注册地址（省市区）名字';
COMMENT ON COLUMN xd_corp_customer_info.registerAdd IS '注册地址（街道门牌号）';
COMMENT ON COLUMN xd_corp_customer_info.officeCountry IS '办公地址(国家)';
COMMENT ON COLUMN xd_corp_customer_info.officeRegioncode IS '办公地址（省市区）';
COMMENT ON COLUMN xd_corp_customer_info.officeAdd IS '办公地址（街道门牌号）';
COMMENT ON COLUMN xd_corp_customer_info.registerZip IS '注册地址邮政编码';
COMMENT ON COLUMN xd_corp_customer_info.officeZip IS '办公地址邮政编码';
COMMENT ON COLUMN xd_corp_customer_info.isCountryfirm IS '是否农村企业';
COMMENT ON COLUMN xd_corp_customer_info.enterpriseBelong IS '隶属关系';
COMMENT ON COLUMN xd_corp_customer_info.isDevelopFlag IS '是否属于开发区';
COMMENT ON COLUMN xd_corp_customer_info.govStation IS '人民政府驻地所在的乡、镇或街道';
COMMENT ON COLUMN xd_corp_customer_info.isInvolveagriculture IS '是否涉农';
COMMENT ON COLUMN xd_corp_customer_info.contactPeople IS '联系人';
COMMENT ON COLUMN xd_corp_customer_info.officeTel IS '联系电话';
COMMENT ON COLUMN xd_corp_customer_info.financedeptTel IS '财务部联系电话';
COMMENT ON COLUMN xd_corp_customer_info.officeFax IS '传真电话';
COMMENT ON COLUMN xd_corp_customer_info.emailAdd IS '公司E-Mail';
COMMENT ON COLUMN xd_corp_customer_info.webAdd IS '公司网址';
COMMENT ON COLUMN xd_corp_customer_info.isGovfinpla IS '是否政信类客户';
COMMENT ON COLUMN xd_corp_customer_info.belongLevel IS '所属层级';
COMMENT ON COLUMN xd_corp_customer_info.listingCorpCrit IS '上市公司代码';
COMMENT ON COLUMN xd_corp_customer_info.listingCorpCountryCrit IS '上市公司国别代码';
COMMENT ON COLUMN xd_corp_customer_info.breakRuleRate IS '违规概率';
COMMENT ON COLUMN xd_corp_customer_info.enterpriseIsOutPlace IS '企业是否在苏州银行网点覆盖外';
COMMENT ON COLUMN xd_corp_customer_info.creditCustomerIndustryInfo IS '授信客户行业情况';
COMMENT ON COLUMN xd_corp_customer_info.creditCustomerIndustryName IS '行业名称';
COMMENT ON COLUMN xd_corp_customer_info.fictitiousPerson IS '法人代表';
COMMENT ON COLUMN xd_corp_customer_info.isLocatedatIndustrialPark IS '经营场所是否在产业园';
COMMENT ON COLUMN xd_corp_customer_info.formattedAddress IS '标准注册地址';
COMMENT ON COLUMN xd_corp_customer_info.officeFormattedAddress IS '标准办公地址';
COMMENT ON COLUMN xd_corp_customer_info.setupDate IS '企业成立日期';
COMMENT ON COLUMN xd_corp_customer_info.operateUserId IS '操作人';
COMMENT ON COLUMN xd_corp_customer_info.operateOrgId IS '操作机构';
COMMENT ON COLUMN xd_corp_customer_info.operateDate IS '操作时间';
COMMENT ON COLUMN xd_corp_customer_info.updateUserId IS '更新人';
COMMENT ON COLUMN xd_corp_customer_info.updateOrgId IS '更新机构';
COMMENT ON COLUMN xd_corp_customer_info.updateDate IS '更新时间';
COMMENT ON COLUMN xd_corp_customer_info.transFlag IS '移植标识';
COMMENT ON COLUMN xd_corp_customer_info.tbName IS '移植原表名';
COMMENT ON COLUMN xd_corp_customer_info.orgType IS '机构类型';
COMMENT ON COLUMN xd_corp_customer_info.industryType IS '国标行业分类';
COMMENT ON COLUMN xd_corp_customer_info.employeeNumber IS '企业职工人数';
COMMENT ON COLUMN xd_corp_customer_info.annualIncome IS '年营业收入';
COMMENT ON COLUMN xd_corp_customer_info.totalAssets IS '资产总额';
COMMENT ON COLUMN xd_corp_customer_info.listingCorpType IS '上市公司类型';
COMMENT ON COLUMN xd_corp_customer_info.closeFlag IS '企业关停标志';
COMMENT ON COLUMN xd_corp_customer_info.importRightsFlag IS '有无进出口经营权';
COMMENT ON COLUMN xd_corp_customer_info.creditLevel IS '本行即期信用等级';
COMMENT ON COLUMN xd_corp_customer_info.workFieldArea IS '经营场地面积';
COMMENT ON COLUMN xd_corp_customer_info.revenue IS '地方财政收入';
COMMENT ON COLUMN xd_corp_customer_info.workFieldFee IS '经营场地所有权';
COMMENT ON COLUMN xd_corp_customer_info.isEntityEnt IS '是否实体企业';
COMMENT ON COLUMN xd_corp_customer_info.strategicType IS '战略新兴产业类型';
COMMENT ON COLUMN xd_corp_customer_info.isIndustupGrade IS '是否工业转型升级';
COMMENT ON COLUMN xd_corp_customer_info.industrialType IS '产业结构调整类型';
COMMENT ON COLUMN xd_corp_customer_info.isCulturalFlag IS '是否文化产业';
COMMENT ON COLUMN xd_corp_customer_info.intelligentType IS '智能制造类型';
COMMENT ON COLUMN xd_corp_customer_info.isStiEnt IS '是否科创企业';
COMMENT ON COLUMN xd_corp_customer_info.isForeignTrade IS '是否外贸型企业';
COMMENT ON COLUMN xd_corp_customer_info.additionalRemark IS '附加说明';
COMMENT ON COLUMN xd_corp_customer_info.businessScope IS '经营范围';
COMMENT ON COLUMN xd_corp_customer_info.manageInfo IS '合法经营情况';
COMMENT ON COLUMN xd_corp_customer_info.customerHistory IS '历史沿革、管理水平简介';
COMMENT ON COLUMN xd_corp_customer_info.mainProduction IS '主要产品情况';
COMMENT ON COLUMN xd_corp_customer_info.nationCode IS '国别风险';
COMMENT ON COLUMN xd_corp_customer_info.offSiteStatisticalOrgCode IS '非现场统计机构编码';
COMMENT ON COLUMN xd_corp_customer_info.otherCreditLevel IS '外部评级结果';
COMMENT ON COLUMN xd_corp_customer_info.otherOrgName IS '外部评级来源';
COMMENT ON COLUMN xd_corp_customer_info.isKeyMan IS '是否本行股东';
COMMENT ON COLUMN xd_corp_customer_info.listingCorpOrNot IS '是否上市公司';
COMMENT ON COLUMN xd_corp_customer_info.listingCityCode IS '上市地点';
COMMENT ON COLUMN xd_corp_customer_info.listingRegionCode IS '行政区代码';
COMMENT ON COLUMN xd_corp_customer_info.listingRegionName IS '行政区名称';
COMMENT ON COLUMN xd_corp_customer_info.listingCorpAdd IS '街道';
COMMENT ON COLUMN xd_corp_customer_info.economyType IS '经济性质';
COMMENT ON COLUMN xd_corp_customer_info.isHeadOffice IS '是否总公司（总行）';
COMMENT ON COLUMN xd_corp_customer_info.headOfficeNo IS '总公司（总行）名称';
COMMENT ON COLUMN xd_corp_customer_info.manageArea IS '所在国内地区';
COMMENT ON COLUMN xd_corp_customer_info.isBelongManager IS '是否落管护客户经理';
COMMENT ON COLUMN xd_corp_customer_info.groupClientNo IS '集团客户号';
COMMENT ON COLUMN xd_corp_customer_info.isCountyArea IS '是否县城城区';
COMMENT ON COLUMN xd_corp_customer_info.creditRatingResult IS '信用评级等级';
COMMENT ON COLUMN xd_corp_customer_info.warningLevel IS '预警等级';
COMMENT ON COLUMN xd_corp_customer_info.dangerLevel IS '风险分类结果';
COMMENT ON COLUMN xd_corp_customer_info.corpCrit IS '组织机构代码证';
COMMENT ON COLUMN xd_corp_customer_info.formalStatus IS '客户类型状态（正式客户临时客户）';
COMMENT ON COLUMN xd_corp_customer_info.officeRegioncodeCName IS '办公地址（省市区）';
COMMENT ON COLUMN xd_corp_customer_info.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_customer_info (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_customer_info (customerId);
CREATE INDEX IF NOT EXISTS idx_mfCustomerNo ON xd_corp_customer_info (mfCustomerNo);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_customer_info (customerName);

-- #####################################################################
-- 2. 企业证件表（customerCert 数组）
--    mainId -> xd_corp_customer_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_customer_cert (
    id              BIGINT not null AUTO_INCREMENT,
    mainId          BIGINT NOT NULL,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    mfCustomerNo    VARCHAR(64),
    customerName    VARCHAR(128),
    serialNo        VARCHAR(64),
    certType        VARCHAR(64),
    certId          VARCHAR(64),
    isMainCert      VARCHAR(64),
    certMaturity    VARCHAR(64),
    status          VARCHAR(64),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_customer_cert IS '对公客户信息-企业证件表（customerCert）';
COMMENT ON COLUMN xd_corp_customer_cert.id IS '主键';
COMMENT ON COLUMN xd_corp_customer_cert.mainId IS '关联主表主键id（xd_corp_customer_info.id）';
COMMENT ON COLUMN xd_corp_customer_cert.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_customer_cert.customerId IS '客户编号';
COMMENT ON COLUMN xd_corp_customer_cert.mfCustomerNo IS '核心客户编号';
COMMENT ON COLUMN xd_corp_customer_cert.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_customer_cert.serialNo IS '流水号';
COMMENT ON COLUMN xd_corp_customer_cert.certType IS '公司证件类型';
COMMENT ON COLUMN xd_corp_customer_cert.certId IS '公司证件编号';
COMMENT ON COLUMN xd_corp_customer_cert.isMainCert IS '是否主证件';
COMMENT ON COLUMN xd_corp_customer_cert.certMaturity IS '证件到期日';
COMMENT ON COLUMN xd_corp_customer_cert.status IS '证件状态';
COMMENT ON COLUMN xd_corp_customer_cert.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_customer_cert (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_customer_cert (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_customer_cert (customerId);
CREATE INDEX IF NOT EXISTS idx_mfCustomerNo ON xd_corp_customer_cert (mfCustomerNo);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_customer_cert (customerName);

-- #####################################################################
-- 3. 高管概况表（customerShipExecutives 数组）
--    mainId -> xd_corp_customer_info.id
--    说明：材料 customerName(高管姓名) 与公共字段同名，改名 executiveName
-- =====================================================================
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_customer_executive (
    id              BIGINT not null AUTO_INCREMENT,
    mainId          BIGINT NOT NULL,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    mfCustomerNo    VARCHAR(64),
    customerName    VARCHAR(128),
    serialNo        VARCHAR(64),
    entCustomerId   VARCHAR(64),
    executiveName   VARCHAR(128),
    certType        VARCHAR(64),
    certId          VARCHAR(64),
    certMaturity    VARCHAR(64),
    nation          VARCHAR(64),
    relationShip    VARCHAR(64),
    iscontrol       VARCHAR(64),
    sex             VARCHAR(64),
    birthday        VARCHAR(64),
    eduExperience   VARCHAR(64),
    telephone       VARCHAR(64),
    holdDate        VARCHAR(64),
    engageTerm      VARCHAR(64),
    holdStock       VARCHAR(64),
    describe        VARCHAR(1000),
    remark          VARCHAR(1000),
    operateuserId   VARCHAR(64),
    operateorgId    VARCHAR(64),
    operateDate     VARCHAR(64),
    inputUserId     VARCHAR(64),
    inputorgId      VARCHAR(64),
    inputDate       VARCHAR(64),
    updateUserId    VARCHAR(64),
    updateOrgId     VARCHAR(64),
    updateDate      VARCHAR(64),
    corpgId         VARCHAR(64),
    mfCustomerId    VARCHAR(64),
    status          VARCHAR(64),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_customer_executive IS '对公客户信息-高管概况表（customerShipExecutives）';
COMMENT ON COLUMN xd_corp_customer_executive.id IS '主键';
COMMENT ON COLUMN xd_corp_customer_executive.mainId IS '关联主表主键id（xd_corp_customer_info.id）';
COMMENT ON COLUMN xd_corp_customer_executive.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_customer_executive.customerId IS '客户编号';
COMMENT ON COLUMN xd_corp_customer_executive.mfCustomerNo IS '核心客户编号';
COMMENT ON COLUMN xd_corp_customer_executive.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_customer_executive.serialNo IS '流水号';
COMMENT ON COLUMN xd_corp_customer_executive.entCustomerId IS '客户编号';
COMMENT ON COLUMN xd_corp_customer_executive.executiveName IS '高管姓名';
COMMENT ON COLUMN xd_corp_customer_executive.certType IS '证件类型';
COMMENT ON COLUMN xd_corp_customer_executive.certId IS '证件号码';
COMMENT ON COLUMN xd_corp_customer_executive.certMaturity IS '证件到期日';
COMMENT ON COLUMN xd_corp_customer_executive.nation IS '国别';
COMMENT ON COLUMN xd_corp_customer_executive.relationShip IS '担任职务';
COMMENT ON COLUMN xd_corp_customer_executive.iscontrol IS '是否实际控制人';
COMMENT ON COLUMN xd_corp_customer_executive.sex IS '性别';
COMMENT ON COLUMN xd_corp_customer_executive.birthday IS '出生日期';
COMMENT ON COLUMN xd_corp_customer_executive.eduExperience IS '学历';
COMMENT ON COLUMN xd_corp_customer_executive.telephone IS '联系电话';
COMMENT ON COLUMN xd_corp_customer_executive.holdDate IS '担任该职务时间';
COMMENT ON COLUMN xd_corp_customer_executive.engageTerm IS '相关行业从业年限(年)';
COMMENT ON COLUMN xd_corp_customer_executive.holdStock IS '持股情况';
COMMENT ON COLUMN xd_corp_customer_executive.describe IS '工作简历';
COMMENT ON COLUMN xd_corp_customer_executive.remark IS '备注';
COMMENT ON COLUMN xd_corp_customer_executive.operateuserId IS '操作人';
COMMENT ON COLUMN xd_corp_customer_executive.operateorgId IS '操作机构';
COMMENT ON COLUMN xd_corp_customer_executive.operateDate IS '操作时间';
COMMENT ON COLUMN xd_corp_customer_executive.inputUserId IS '登记人';
COMMENT ON COLUMN xd_corp_customer_executive.inputorgId IS '登记机构';
COMMENT ON COLUMN xd_corp_customer_executive.inputDate IS '登记时间';
COMMENT ON COLUMN xd_corp_customer_executive.updateUserId IS '更新人';
COMMENT ON COLUMN xd_corp_customer_executive.updateOrgId IS '更新机构';
COMMENT ON COLUMN xd_corp_customer_executive.updateDate IS '更新时间';
COMMENT ON COLUMN xd_corp_customer_executive.corpgId IS '法人机构号';
COMMENT ON COLUMN xd_corp_customer_executive.mfCustomerId IS 'ecif客户号';
COMMENT ON COLUMN xd_corp_customer_executive.status IS '状态';
COMMENT ON COLUMN xd_corp_customer_executive.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_customer_executive (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_customer_executive (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_customer_executive (customerId);
CREATE INDEX IF NOT EXISTS idx_mfCustomerNo ON xd_corp_customer_executive (mfCustomerNo);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_customer_executive (customerName);

-- #####################################################################
-- 4. 股东信息表（customerShipShareholds 数组）
--    mainId -> xd_corp_customer_info.id
--    说明：材料 customerName(股东姓名) 与公共字段同名，改名 shareholderName
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_customer_shareholder (
    id              BIGINT not null AUTO_INCREMENT,
    mainId          BIGINT NOT NULL,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    mfCustomerNo    VARCHAR(64),
    customerName    VARCHAR(128),
    serialNo        VARCHAR(64),
    customerType    VARCHAR(64),
    shareholderName VARCHAR(128),
    relationShip    VARCHAR(64),
    certType        VARCHAR(64),
    certId          VARCHAR(64),
    currencyType    VARCHAR(64),
    investmentProp  DECIMAL(18,2),
    oughtSum        DECIMAL(18,2),
    investmentSum   DECIMAL(18,2),
    investDate      VARCHAR(64),
    certMaturity    VARCHAR(64),
    loanCardNo      VARCHAR(64),
    remark          VARCHAR(1000),
    inputUserId     VARCHAR(64),
    inputDate       VARCHAR(64),
    inputOrgId      VARCHAR(64),
    updateUserId    VARCHAR(64),
    updateOrgId     VARCHAR(64),
    updateDate      VARCHAR(64),
    corpOrgId       VARCHAR(64),
    countryOrRegion VARCHAR(64),
    economyType     VARCHAR(64),
    mfCustomerId    VARCHAR(64),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_customer_shareholder IS '对公客户信息-股东信息表（customerShipShareholds）';
COMMENT ON COLUMN xd_corp_customer_shareholder.id IS '主键';
COMMENT ON COLUMN xd_corp_customer_shareholder.mainId IS '关联主表主键id（xd_corp_customer_info.id）';
COMMENT ON COLUMN xd_corp_customer_shareholder.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_customer_shareholder.customerId IS '客户编号';
COMMENT ON COLUMN xd_corp_customer_shareholder.mfCustomerNo IS '核心客户编号';
COMMENT ON COLUMN xd_corp_customer_shareholder.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_customer_shareholder.serialNo IS '流水号';
COMMENT ON COLUMN xd_corp_customer_shareholder.customerType IS '股东类型';
COMMENT ON COLUMN xd_corp_customer_shareholder.shareholderName IS '股东姓名';
COMMENT ON COLUMN xd_corp_customer_shareholder.relationShip IS '出资方式';
COMMENT ON COLUMN xd_corp_customer_shareholder.certType IS '股东证件类型';
COMMENT ON COLUMN xd_corp_customer_shareholder.certId IS '股东证件号码';
COMMENT ON COLUMN xd_corp_customer_shareholder.currencyType IS '投资币种';
COMMENT ON COLUMN xd_corp_customer_shareholder.investmentProp IS '投资比例';
COMMENT ON COLUMN xd_corp_customer_shareholder.oughtSum IS '投资金额';
COMMENT ON COLUMN xd_corp_customer_shareholder.investmentSum IS '实缴金额';
COMMENT ON COLUMN xd_corp_customer_shareholder.investDate IS '总投资最迟到位日期';
COMMENT ON COLUMN xd_corp_customer_shareholder.certMaturity IS '股东结构对应日期';
COMMENT ON COLUMN xd_corp_customer_shareholder.loanCardNo IS '股权证号';
COMMENT ON COLUMN xd_corp_customer_shareholder.remark IS '备注';
COMMENT ON COLUMN xd_corp_customer_shareholder.inputUserId IS '登记人';
COMMENT ON COLUMN xd_corp_customer_shareholder.inputDate IS '登记日期';
COMMENT ON COLUMN xd_corp_customer_shareholder.inputOrgId IS '登记机构';
COMMENT ON COLUMN xd_corp_customer_shareholder.updateUserId IS '更新人';
COMMENT ON COLUMN xd_corp_customer_shareholder.updateOrgId IS '更新机构';
COMMENT ON COLUMN xd_corp_customer_shareholder.updateDate IS '更新日期';
COMMENT ON COLUMN xd_corp_customer_shareholder.corpOrgId IS '法人机构编号';
COMMENT ON COLUMN xd_corp_customer_shareholder.countryOrRegion IS '所在国家或地区';
COMMENT ON COLUMN xd_corp_customer_shareholder.economyType IS '经济性质';
COMMENT ON COLUMN xd_corp_customer_shareholder.mfCustomerId IS '核心客户号';
COMMENT ON COLUMN xd_corp_customer_shareholder.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_customer_shareholder (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_customer_shareholder (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_customer_shareholder (customerId);
CREATE INDEX IF NOT EXISTS idx_mfCustomerNo ON xd_corp_customer_shareholder (mfCustomerNo);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_customer_shareholder (customerName);

-- #####################################################################
-- 5. 对外股权投资表（customerShipInvests 数组）
--    mainId -> xd_corp_customer_info.id
--    说明：材料 customerName(投向企业姓名) 与公共字段同名，改名 investCustomerName
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_customer_invest (
    id                  BIGINT not null AUTO_INCREMENT,
    mainId              BIGINT NOT NULL,
    reportNo            VARCHAR(64) NOT NULL,
    customerId          VARCHAR(64),
    mfCustomerNo        VARCHAR(64),
    customerName        VARCHAR(128),
    serialNo            VARCHAR(64),
    relativeCustomerId  VARCHAR(64),
    certType            VARCHAR(64),
    certId              VARCHAR(64),
    investCustomerName  VARCHAR(128),
    relationShip        VARCHAR(64),
    indName             VARCHAR(128),
    loanCardNo          VARCHAR(64),
    currency            VARCHAR(64),
    investmentProp      DECIMAL(18,2),
    oughtSum            DECIMAL(18,2),
    investmentSum       DECIMAL(18,2),
    investDate          VARCHAR(64),
    firstEarnings       DECIMAL(18,2),
    inputUserId         VARCHAR(64),
    inputDate           VARCHAR(64),
    inputOrgId          VARCHAR(64),
    remark              VARCHAR(1000),
    updateUserId        VARCHAR(64),
    updateOrgId         VARCHAR(64),
    updateDate          VARCHAR(64),
    certTypeName        VARCHAR(64),
    relationShipName    VARCHAR(64),
    currencyName        VARCHAR(64),
    status              VARCHAR(64),
    statusName          VARCHAR(64),
    inputOrgName        VARCHAR(128),
    inputUserName       VARCHAR(128),
    updateOrgName       VARCHAR(128),
    updateUserName      VARCHAR(128),
    mfCustomerId        VARCHAR(64),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_customer_invest IS '对公客户信息-对外股权投资表（customerShipInvests）';
COMMENT ON COLUMN xd_corp_customer_invest.id IS '主键';
COMMENT ON COLUMN xd_corp_customer_invest.mainId IS '关联主表主键id（xd_corp_customer_info.id）';
COMMENT ON COLUMN xd_corp_customer_invest.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_customer_invest.customerId IS '客户编号';
COMMENT ON COLUMN xd_corp_customer_invest.mfCustomerNo IS '核心客户编号';
COMMENT ON COLUMN xd_corp_customer_invest.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_customer_invest.serialNo IS '流水号';
COMMENT ON COLUMN xd_corp_customer_invest.relativeCustomerId IS '关联客户编号';
COMMENT ON COLUMN xd_corp_customer_invest.certType IS '投向企业证件类型';
COMMENT ON COLUMN xd_corp_customer_invest.certId IS '投向企业证件号码';
COMMENT ON COLUMN xd_corp_customer_invest.investCustomerName IS '投向企业姓名';
COMMENT ON COLUMN xd_corp_customer_invest.relationShip IS '投资方式';
COMMENT ON COLUMN xd_corp_customer_invest.indName IS '投向企业法人代表名称';
COMMENT ON COLUMN xd_corp_customer_invest.loanCardNo IS '投向企业贷款卡编号';
COMMENT ON COLUMN xd_corp_customer_invest.currency IS '出资币种';
COMMENT ON COLUMN xd_corp_customer_invest.investmentProp IS '出资比例';
COMMENT ON COLUMN xd_corp_customer_invest.oughtSum IS '出资金额';
COMMENT ON COLUMN xd_corp_customer_invest.investmentSum IS '实际投资金额';
COMMENT ON COLUMN xd_corp_customer_invest.investDate IS '投资日期';
COMMENT ON COLUMN xd_corp_customer_invest.firstEarnings IS '第一年投资收益';
COMMENT ON COLUMN xd_corp_customer_invest.inputUserId IS '登记人';
COMMENT ON COLUMN xd_corp_customer_invest.inputDate IS '登记日期';
COMMENT ON COLUMN xd_corp_customer_invest.inputOrgId IS '登记机构';
COMMENT ON COLUMN xd_corp_customer_invest.remark IS '备注';
COMMENT ON COLUMN xd_corp_customer_invest.updateUserId IS '更新人';
COMMENT ON COLUMN xd_corp_customer_invest.updateOrgId IS '更新机构';
COMMENT ON COLUMN xd_corp_customer_invest.updateDate IS '更新日期';
COMMENT ON COLUMN xd_corp_customer_invest.certTypeName IS '投向企业证件类型';
COMMENT ON COLUMN xd_corp_customer_invest.relationShipName IS '投资方式';
COMMENT ON COLUMN xd_corp_customer_invest.currencyName IS '出资币种';
COMMENT ON COLUMN xd_corp_customer_invest.status IS '是否有效码值';
COMMENT ON COLUMN xd_corp_customer_invest.statusName IS '是否有效';
COMMENT ON COLUMN xd_corp_customer_invest.inputOrgName IS '登记机构名';
COMMENT ON COLUMN xd_corp_customer_invest.inputUserName IS '登记用户名';
COMMENT ON COLUMN xd_corp_customer_invest.updateOrgName IS '更新机构名';
COMMENT ON COLUMN xd_corp_customer_invest.updateUserName IS '更新用户名';
COMMENT ON COLUMN xd_corp_customer_invest.mfCustomerId IS '核心客户号';
COMMENT ON COLUMN xd_corp_customer_invest.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_customer_invest (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_customer_invest (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_customer_invest (customerId);
CREATE INDEX IF NOT EXISTS idx_mfCustomerNo ON xd_corp_customer_invest (mfCustomerNo);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_customer_invest (customerName);

-- #####################################################################
-- 6. 资产信息表（entAssets 数组）
--    mainId -> xd_corp_customer_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_customer_asset (
    id              BIGINT not null AUTO_INCREMENT,
    mainId          BIGINT NOT NULL,
    reportNo        VARCHAR(64) NOT NULL,
    customerId      VARCHAR(64),
    mfCustomerNo    VARCHAR(64),
    customerName    VARCHAR(128),
    serialNo        VARCHAR(64),
    assetsType      VARCHAR(64),
    assetsName      VARCHAR(128),
    location        VARCHAR(255),
    certificateNo   VARCHAR(64),
    bookValue       VARCHAR(64),
    useStatus       VARCHAR(64),
    currentValue    VARCHAR(64),
    guarantyFlag    VARCHAR(64),
    guarantyOwner   VARCHAR(128),
    guarantyValue   DECIMAL(18,2),
    purchaseTime    VARCHAR(64),
    purchaseValue   VARCHAR(64),
    remark          VARCHAR(1000),
    inputUserId     VARCHAR(64),
    inputDate       VARCHAR(64),
    inputOrgId      VARCHAR(64),
    updateUserId    VARCHAR(64),
    updateOrgId     VARCHAR(64),
    updateDate      VARCHAR(64),
    corpOrgId       VARCHAR(64),
    inputtime       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_customer_asset IS '对公客户信息-资产信息表（entAssets）';
COMMENT ON COLUMN xd_corp_customer_asset.id IS '主键';
COMMENT ON COLUMN xd_corp_customer_asset.mainId IS '关联主表主键id（xd_corp_customer_info.id）';
COMMENT ON COLUMN xd_corp_customer_asset.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_customer_asset.customerId IS '客户编号';
COMMENT ON COLUMN xd_corp_customer_asset.mfCustomerNo IS '核心客户编号';
COMMENT ON COLUMN xd_corp_customer_asset.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_customer_asset.serialNo IS '流水号';
COMMENT ON COLUMN xd_corp_customer_asset.assetsType IS '资产类型';
COMMENT ON COLUMN xd_corp_customer_asset.assetsName IS '资产名称';
COMMENT ON COLUMN xd_corp_customer_asset.location IS '位置';
COMMENT ON COLUMN xd_corp_customer_asset.certificateNo IS '权利证书号';
COMMENT ON COLUMN xd_corp_customer_asset.bookValue IS '账面净值';
COMMENT ON COLUMN xd_corp_customer_asset.useStatus IS '使用状态';
COMMENT ON COLUMN xd_corp_customer_asset.currentValue IS '目前价值';
COMMENT ON COLUMN xd_corp_customer_asset.guarantyFlag IS '是否抵押';
COMMENT ON COLUMN xd_corp_customer_asset.guarantyOwner IS '抵押权人';
COMMENT ON COLUMN xd_corp_customer_asset.guarantyValue IS '抵押金额';
COMMENT ON COLUMN xd_corp_customer_asset.purchaseTime IS '购置时间';
COMMENT ON COLUMN xd_corp_customer_asset.purchaseValue IS '购置价格';
COMMENT ON COLUMN xd_corp_customer_asset.remark IS '备注';
COMMENT ON COLUMN xd_corp_customer_asset.inputUserId IS '登记人';
COMMENT ON COLUMN xd_corp_customer_asset.inputDate IS '登记日期';
COMMENT ON COLUMN xd_corp_customer_asset.inputOrgId IS '登记机构';
COMMENT ON COLUMN xd_corp_customer_asset.updateUserId IS '更新人';
COMMENT ON COLUMN xd_corp_customer_asset.updateOrgId IS '更新机构';
COMMENT ON COLUMN xd_corp_customer_asset.updateDate IS '更新日期';
COMMENT ON COLUMN xd_corp_customer_asset.corpOrgId IS '法人机构编号';
COMMENT ON COLUMN xd_corp_customer_asset.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_customer_asset (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_customer_asset (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_customer_asset (customerId);
CREATE INDEX IF NOT EXISTS idx_mfCustomerNo ON xd_corp_customer_asset (mfCustomerNo);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_customer_asset (customerName);

-- #####################################################################
-- 7. 账户信息表（customerAccounts 数组）
--    mainId -> xd_corp_customer_info.id
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_customer_account (
    id                  BIGINT not null AUTO_INCREMENT,
    mainId              BIGINT NOT NULL,
    reportNo            VARCHAR(64) NOT NULL,
    customerId          VARCHAR(64),
    mfCustomerNo        VARCHAR(64),
    customerName        VARCHAR(128),
    serialNo            VARCHAR(64),
    accountName         VARCHAR(128),
    accountBank         VARCHAR(128),
    accountNumber       VARCHAR(64),
    accountType         VARCHAR(64),
    accumulate          VARCHAR(64),
    relativeAccount     VARCHAR(64),
    remark              VARCHAR(1000),
    inputUserId         VARCHAR(64),
    inputOrgId          VARCHAR(64),
    inputDate           VARCHAR(64),
    updateUserId        VARCHAR(64),
    updateOrgId         VARCHAR(64),
    updateDate          VARCHAR(64),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_customer_account IS '对公客户信息-账户信息表（customerAccounts）';
COMMENT ON COLUMN xd_corp_customer_account.id IS '主键';
COMMENT ON COLUMN xd_corp_customer_account.mainId IS '关联主表主键id（xd_corp_customer_info.id）';
COMMENT ON COLUMN xd_corp_customer_account.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_customer_account.customerId IS '客户编号';
COMMENT ON COLUMN xd_corp_customer_account.mfCustomerNo IS '核心客户编号';
COMMENT ON COLUMN xd_corp_customer_account.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_customer_account.serialNo IS '流水号';
COMMENT ON COLUMN xd_corp_customer_account.accountName IS '账户名称';
COMMENT ON COLUMN xd_corp_customer_account.accountBank IS '账户标识';
COMMENT ON COLUMN xd_corp_customer_account.accountNumber IS '账号';
COMMENT ON COLUMN xd_corp_customer_account.accountType IS '账号类型';
COMMENT ON COLUMN xd_corp_customer_account.accumulate IS '积数合计';
COMMENT ON COLUMN xd_corp_customer_account.relativeAccount IS '关联帐户关系';
COMMENT ON COLUMN xd_corp_customer_account.remark IS '备注';
COMMENT ON COLUMN xd_corp_customer_account.inputUserId IS '登记人';
COMMENT ON COLUMN xd_corp_customer_account.inputOrgId IS '登记机构';
COMMENT ON COLUMN xd_corp_customer_account.inputDate IS '登记时间';
COMMENT ON COLUMN xd_corp_customer_account.updateUserId IS '更新人';
COMMENT ON COLUMN xd_corp_customer_account.updateOrgId IS '更新机构';
COMMENT ON COLUMN xd_corp_customer_account.updateDate IS '更新时间';
COMMENT ON COLUMN xd_corp_customer_account.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_customer_account (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_customer_account (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_customer_account (customerId);
CREATE INDEX IF NOT EXISTS idx_mfCustomerNo ON xd_corp_customer_account (mfCustomerNo);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_customer_account (customerName);

-- #####################################################################
-- 8. 实际控制人表（controlshipExecutives 数组）
--    mainId -> xd_corp_customer_info.id
--    说明：材料 customerId(客户号)、customerName(客户名称) 与公共字段同义，合并；
--          材料 corpgId 小写拼写按材料原样保留
--    待补充：controlshipExecutives 数组内嵌套"实控人信息"数组，材料未定义内层字段，暂不建表
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_corp_customer_control (
    id                  BIGINT not null AUTO_INCREMENT,
    mainId              BIGINT NOT NULL,
    reportNo            VARCHAR(64) NOT NULL,
    customerId          VARCHAR(64),
    mfCustomerNo        VARCHAR(64),
    customerName        VARCHAR(128),
    serialNo            VARCHAR(64),
    relativeCustomerId  VARCHAR(64),
    certType            VARCHAR(64),
    certId              VARCHAR(64),
    customerType        VARCHAR(64),
    orgNature           VARCHAR(64),
    deleteFlag          VARCHAR(64),
    isControl           VARCHAR(64),
    status              VARCHAR(64),
    inputUserId         VARCHAR(64),
    inputOrgId          VARCHAR(64),
    inputDate           VARCHAR(64),
    updateUserId        VARCHAR(64),
    updateOrgId         VARCHAR(64),
    updateDate          VARCHAR(64),
    corpgId             VARCHAR(64),
    inputtime           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_corp_customer_control IS '对公客户信息-实际控制人表（controlshipExecutives）';
COMMENT ON COLUMN xd_corp_customer_control.id IS '主键';
COMMENT ON COLUMN xd_corp_customer_control.mainId IS '关联主表主键id（xd_corp_customer_info.id）';
COMMENT ON COLUMN xd_corp_customer_control.reportNo IS '报告编号';
COMMENT ON COLUMN xd_corp_customer_control.customerId IS '客户编号';
COMMENT ON COLUMN xd_corp_customer_control.mfCustomerNo IS '核心客户编号';
COMMENT ON COLUMN xd_corp_customer_control.customerName IS '客户名称';
COMMENT ON COLUMN xd_corp_customer_control.serialNo IS '流水号';
COMMENT ON COLUMN xd_corp_customer_control.relativeCustomerId IS '关联客户号';
COMMENT ON COLUMN xd_corp_customer_control.certType IS '证件类型';
COMMENT ON COLUMN xd_corp_customer_control.certId IS '证件号';
COMMENT ON COLUMN xd_corp_customer_control.customerType IS '客户类型';
COMMENT ON COLUMN xd_corp_customer_control.orgNature IS '机构类型';
COMMENT ON COLUMN xd_corp_customer_control.deleteFlag IS '删除标志';
COMMENT ON COLUMN xd_corp_customer_control.isControl IS '是否实际控制人';
COMMENT ON COLUMN xd_corp_customer_control.status IS '状态';
COMMENT ON COLUMN xd_corp_customer_control.inputUserId IS '登记人';
COMMENT ON COLUMN xd_corp_customer_control.inputOrgId IS '登记机构';
COMMENT ON COLUMN xd_corp_customer_control.inputDate IS '登记日期';
COMMENT ON COLUMN xd_corp_customer_control.updateUserId IS '修改人';
COMMENT ON COLUMN xd_corp_customer_control.updateOrgId IS '修改机构';
COMMENT ON COLUMN xd_corp_customer_control.updateDate IS '修改时间';
COMMENT ON COLUMN xd_corp_customer_control.corpgId IS '法人机构编号';
COMMENT ON COLUMN xd_corp_customer_control.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_mainId ON xd_corp_customer_control (mainId);
CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_corp_customer_control (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_corp_customer_control (customerId);
CREATE INDEX IF NOT EXISTS idx_mfCustomerNo ON xd_corp_customer_control (mfCustomerNo);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_corp_customer_control (customerName);
