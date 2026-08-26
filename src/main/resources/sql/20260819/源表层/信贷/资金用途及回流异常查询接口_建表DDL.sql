-- =====================================================================
-- 资金用途及回流异常查询接口 · 数据落表 DDL（v1.1）
-- 数据库：GaussDB（openGauss 内核 · MySQL 兼容模式）
--
-- 设计约定：
--   1. 接口仅含 1 个数组（资金用途及回流异常排查数组），无嵌套结构，
--      采用单表落库，一行 = 一条排查记录
--   2. 英文字段名 100% 照抄接口材料（驼峰/全大写保持），不做格式转换
--   3. 公共字段：reportNo(报告编号)、customerId(信贷客户编号)、
--      customerName(客户名称)、inputtime(入库时间)
--   4. 类型映射：材料 String -> VARCHAR；inputtime -> TIMESTAMP
--   5. reportNo / customerId / customerName 列均建索引
--   6. 接口返回直接追加插入，不做去重约束
--
-- 语法适配（实测验证）：
--   - 建表语句内不写列注释/表注释/索引子句
--   - 注释用 COMMENT ON TABLE / COMMENT ON COLUMN 单独写
--   - 索引用 CREATE INDEX IF NOT EXISTS 单独建
--   - 主键：id BIGINT not null AUTO_INCREMENT + 表级 primary key (id)
-- =====================================================================

-- #####################################################################
-- 1. 资金用途及回流异常排查表（资金用途及回流异常排查数组）
-- #####################################################################
CREATE TABLE IF NOT EXISTS xd_fund_use_abnormal (
    id                              BIGINT not null AUTO_INCREMENT,
    reportNo                        VARCHAR(64) NOT NULL,
    customerId                      VARCHAR(64),
    customerName                    VARCHAR(128),
    serialNo                        VARCHAR(64),
    loanSerialNo                    VARCHAR(64),
    capitalCheckTaskType            VARCHAR(64),
    approvestatus                   VARCHAR(64),
    purposeIdentifiyReason          VARCHAR(1000),
    isPurposeabnormal               VARCHAR(64),
    rectificationPurposesituation   VARCHAR(64),
    rectificationPurposeDeadline    VARCHAR(64),
    rectificationPurposeExplanation VARCHAR(1000),
    inputtime                       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    primary key (id)
);

COMMENT ON TABLE xd_fund_use_abnormal IS '资金用途及回流异常排查表';
COMMENT ON COLUMN xd_fund_use_abnormal.id IS '主键';
COMMENT ON COLUMN xd_fund_use_abnormal.reportNo IS '报告编号';
COMMENT ON COLUMN xd_fund_use_abnormal.customerId IS '信贷客户编号';
COMMENT ON COLUMN xd_fund_use_abnormal.customerName IS '客户名称';
COMMENT ON COLUMN xd_fund_use_abnormal.serialNo IS '申请流水号';
COMMENT ON COLUMN xd_fund_use_abnormal.loanSerialNo IS '借据号';
COMMENT ON COLUMN xd_fund_use_abnormal.capitalCheckTaskType IS '任务类型(01 资金用途异常|02 资金回流异常)';
COMMENT ON COLUMN xd_fund_use_abnormal.approvestatus IS '审批状态(Accepted 通过|Adjournment 续议|Approving 审批中|AutoConfirmed 自动审批已确认|AutoToBeConfirm 自动审批待确认|Cancel 取消|CustomerRegister 客户经理登记中|EarlyTerminate 提前结束|Finished 审批通过|GoBack 退回|Ineffective 失效|PreConfirmed 待确认|PreSubmit 待提交|Register 登记中|Registered 登记完成|Reject 否决|Review 复核中)';
COMMENT ON COLUMN xd_fund_use_abnormal.purposeIdentifiyReason IS '认定理由';
COMMENT ON COLUMN xd_fund_use_abnormal.isPurposeabnormal IS '是否用途异常';
COMMENT ON COLUMN xd_fund_use_abnormal.rectificationPurposesituation IS '整改情况';
COMMENT ON COLUMN xd_fund_use_abnormal.rectificationPurposeDeadline IS '整改期限';
COMMENT ON COLUMN xd_fund_use_abnormal.rectificationPurposeExplanation IS '整改情况说明';
COMMENT ON COLUMN xd_fund_use_abnormal.inputtime IS '入库时间';

CREATE INDEX IF NOT EXISTS idx_reportNo ON xd_fund_use_abnormal (reportNo);
CREATE INDEX IF NOT EXISTS idx_customerId ON xd_fund_use_abnormal (customerId);
CREATE INDEX IF NOT EXISTS idx_customerName ON xd_fund_use_abnormal (customerName);
