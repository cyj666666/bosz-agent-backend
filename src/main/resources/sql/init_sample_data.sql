-- =============================================
-- 示例数据初始化：5个客户 + 指标数据 + 知识库规则
-- 基于《苏州银行贷后智能体-经验库0625.xlsx》
-- 不硬编码任何ID，全部用子查询动态引用
-- =============================================

-- ==================== 1. 客户 ====================
INSERT INTO customer (company_name, credit_code, legal_person, actual_controller, registered_capital, paid_capital, establish_date, industry, biz_scope, register_address, holding_type, shareholder, group_name, customer_type, first_loan_date, last_approval_date, main_bank, settlement_bank, status, created_at) VALUES
('苏州天翔精密制造有限公司', '91320500MA1N2C3D4E', '张建国', '张建国', '5000万人民币', '5000万人民币', '2010-03-15', '制造业', '精密机械零部件设计、制造、销售', '苏州市工业园区苏虹中路398号', '民营控股', '张建国(60%), 张建军(15%), 苏州天翔投资合伙企业(25%)', '天翔集团', '大中型企业', '2015-06-20', '2024-12-10', '苏州银行工业园区支行', '苏州银行工业园区支行', '正常', NOW()),
('无锡华丰纺织印染有限公司', '91320200MA2N3C4D5F', '李志强', '李志强', '3000万人民币', '3000万人民币', '2008-07-22', '制造业', '纺织品印染、加工、销售', '无锡市锡山区东港镇纺织工业园', '民营控股', '李志强(55%), 华丰控股有限公司(45%)', '华丰系', '中型企业', '2016-03-10', '2025-01-15', '苏州银行无锡分行', '苏州银行无锡分行', '正常', NOW()),
('常州金茂贸易有限公司', '91320400MA3N4C5D6G', '王明华', '王明华', '800万人民币', '800万人民币', '2015-11-08', '批发零售业', '金属材料、化工原料、机械设备销售', '常州市新北区通江中路168号', '民营控股', '王明华(70%), 王明亮(30%)', '', '小微企业', '2019-08-15', '2024-06-30', '苏州银行常州分行', '苏州银行常州分行', '正常', NOW()),
('南京建工集团有限公司', '91320100MA4N5C6D7H', '陈伟民', '南京市国资委', '50000万人民币', '50000万人民币', '1998-05-18', '建筑业', '房屋建筑工程施工总承包、市政公用工程施工', '南京市建邺区江东中路289号', '国有控股', '南京市国资委(80%), 南京城建集团(20%)', '南京建工集团', '大型企业', '2010-01-20', '2025-02-28', '苏州银行南京分行', '苏州银行南京分行', '正常', NOW()),
('昆山新锐电子科技有限公司', '91320583MA5N6C7D8I', '赵海峰', '赵海峰', '2000万人民币', '2000万人民币', '2012-09-01', '制造业', '电子元器件、半导体封装测试', '昆山市经济技术开发区前进东路888号', '民营控股', '赵海峰(45%), 深圳锐芯投资(35%), 昆山创投(20%)', '新锐系', '中型企业', '2017-05-12', '2024-09-20', '苏州银行昆山支行', '苏州银行昆山支行', '正常', NOW());

-- 快捷方法：按 credit_code 查客户 ID
-- c1=苏州天翔 c2=无锡华丰 c3=常州金茂 c4=南京建工 c5=昆山新锐

-- ==================== 2. 指标数据 — 苏州天翔（财务承压型） ====================
INSERT INTO indicator_data (customer_id, indicator_key, indicator_name, current_value, previous_value, change_desc, data_unit, domain, period, sort_order, created_at)
SELECT c.id, v.k, v.n, v.cv, v.pv, v.cd, v.u, v.d, '2025Q1', v.so, NOW()
FROM customer c
CROSS JOIN (VALUES
(1,'91320500MA1N2C3D4E','total_assets','总资产','85000.00','82000.00','↑3.7%','万元','FINANCE'),
(2,'91320500MA1N2C3D4E','revenue','营业收入','12000.00','15500.00','↓22.6%','万元','FINANCE'),
(3,'91320500MA1N2C3D4E','net_profit','净利润','280.00','650.00','↓56.9%','万元','FINANCE'),
(4,'91320500MA1N2C3D4E','asset_liability_ratio','资产负债率','72.5','65.0','↑7.5ppt','%','FINANCE'),
(5,'91320500MA1N2C3D4E','operating_cash_flow','经营现金流净额','-850.00','-200.00','恶化','万元','FINANCE'),
(6,'91320500MA1N2C3D4E','cash_equivalents','货币资金','3200.00','4800.00','↓33.3%','万元','FINANCE'),
(7,'91320500MA1N2C3D4E','accounts_receivable','应收账款','5200.00','3800.00','↑36.8%','万元','FINANCE'),
(8,'91320500MA1N2C3D4E','ar_turnover_days','应收账款周转天数','158','92','↑66天','天','FINANCE'),
(9,'91320500MA1N2C3D4E','inventory','存货','4100.00','3500.00','↑17.1%','万元','FINANCE'),
(10,'91320500MA1N2C3D4E','net_cash_ratio','净现比','0.35','0.52','↓32.7%','比率','FINANCE'),
(11,'91320500MA1N2C3D4E','other_bank_credit','他行授信总额','8000.00','12000.00','↓33.3%','万元','CREDIT'),
(12,'91320500MA1N2C3D4E','non_bank_financing','非银融资余额','1500.00','800.00','↑87.5%','万元','CREDIT'),
(13,'91320500MA1N2C3D4E','external_guarantee','对外担保余额','3200.00','2500.00','↑28.0%','万元','CREDIT'),
(14,'91320500MA1N2C3D4E','credit_overdue','征信逾期次数','2','0','新增2笔','次','CREDIT'),
(15,'91320500MA1N2C3D4E','tax_sales','纳税申报销售额','10800.00','14200.00','↓23.9%','万元','TAX'),
(16,'91320500MA1N2C3D4E','social_security_count','社保缴纳人数','265','310','↓14.5%','人','SOCIAL_SECURITY'),
(17,'91320500MA1N2C3D4E','electricity_consumption','用电量','82.00','98.00','↓16.3%','万度','UTILITY'),
(18,'91320500MA1N2C3D4E','salary_payment_count','代发工资人数','258','268','↓3.7%','人','SETTLEMENT'),
(19,'91320500MA1N2C3D4E','new_litigation','新增作为被告诉讼数','2','0','新增2件','件','JUDICIAL'),
(20,'91320500MA1N2C3D4E','litigation_amount','涉诉金额','1200.00','0','新增','万元','JUDICIAL')
) AS v(so,cc,k,n,cv,pv,cd,u,d)
WHERE c.credit_code = v.cc;

-- 苏州天翔 — 定性/图谱类指标
INSERT INTO indicator_data (customer_id, indicator_key, indicator_name, current_value, previous_value, change_desc, data_unit, domain, period, sort_order, created_at)
SELECT c.id, v.k, v.n, v.cv, v.pv, v.cd, v.u, v.d, '2025Q1', v.so, NOW()
FROM customer c
CROSS JOIN (VALUES
(21,'91320500MA1N2C3D4E','shareholder_change','实控人/股东变更','是','否','发生变更','','INDUSTRY_COMMERCE'),
(22,'91320500MA1N2C3D4E','pledge_ratio','累计质押比例','55','40','↑15.0ppt','%','CREDIT'),
(23,'91320500MA1N2C3D4E','controller_pledge_ratio','实控人质押比例','62','45','↑17.0ppt','%','CREDIT'),
(24,'91320500MA1N2C3D4E','biz_abnormal','工商经营异常','是','否','新增异常','','INDUSTRY_COMMERCE'),
(25,'91320500MA1N2C3D4E','negative_news','重大负面舆情','是','否','存在负面','','JUDICIAL'),
(26,'91320500MA1N2C3D4E','debt_restructure','债务重组/展期记录','是','否','存在重组','','CREDIT'),
(27,'91320500MA1N2C3D4E','fund_flow_anomaly','信贷资金流向异常','是','否','存在异常','','SETTLEMENT'),
(28,'91320500MA1N2C3D4E','supplier_customer_anomaly','上下游客户异常','是','否','存在异常','','MANAGEMENT'),
(29,'91320500MA1N2C3D4E','gov_penalty','政府行政处罚','是','否','新增处罚','','JUDICIAL'),
(30,'91320500MA1N2C3D4E','suspected_nominee_loan','疑似借名贷款','是','否','图谱判定','','GRAPH'),
(31,'91320500MA1N2C3D4E','suspected_guarantee_chain','疑似担保圈链','是','否','图谱判定','','GRAPH'),
(32,'91320500MA1N2C3D4E','blacklist_relation','黑名单关联','是','否','图谱判定','','GRAPH'),
(33,'91320500MA1N2C3D4E','group_credit_omission','未纳入集团授信','是','否','图谱判定','','GRAPH'),
(34,'91320500MA1N2C3D4E','non_bank_institution_count','新增非银机构数','3','0','新增3家','家','CREDIT'),
(35,'91320500MA1N2C3D4E','guarantee_to_equity_ratio','对外担保/净资产','0.65','0.45','↑20.0ppt','比率','CREDIT'),
(36,'91320500MA1N2C3D4E','litigation_to_equity_ratio','涉诉金额/净资产','0.25','0','新增','比率','JUDICIAL')
) AS v(so,cc,k,n,cv,pv,cd,u,d)
WHERE c.credit_code = v.cc;

-- ==================== 2b. 指标数据 — 无锡华丰 ====================
INSERT INTO indicator_data (customer_id, indicator_key, indicator_name, current_value, previous_value, change_desc, data_unit, domain, period, sort_order, created_at)
SELECT c.id, v.k, v.n, v.cv, v.pv, v.cd, v.u, v.d, '2025Q1', v.so, NOW()
FROM customer c
CROSS JOIN (VALUES
(1,'91320200MA2N3C4D5F','total_assets','总资产','18000.00','17500.00','↑2.9%','万元','FINANCE'),
(2,'91320200MA2N3C4D5F','revenue','营业收入','3800.00','5200.00','↓26.9%','万元','FINANCE'),
(3,'91320200MA2N3C4D5F','net_profit','净利润','45.00','180.00','↓75.0%','万元','FINANCE'),
(4,'91320200MA2N3C4D5F','asset_liability_ratio','资产负债率','58.0','55.0','↑3.0ppt','%','FINANCE'),
(5,'91320200MA2N3C4D5F','operating_cash_flow','经营现金流净额','-120.00','85.00','由正转负','万元','FINANCE'),
(6,'91320200MA2N3C4D5F','water_consumption','用水量','1.80','4.20','↓57.1%','万吨','UTILITY'),
(7,'91320200MA2N3C4D5F','electricity_consumption','用电量','35.00','42.00','↓16.7%','万度','UTILITY'),
(8,'91320200MA2N3C4D5F','customs_export','海关出口额','220.00','480.00','↓54.2%','万美元','CUSTOMS'),
(9,'91320200MA2N3C4D5F','tax_sales','纳税申报销售额','3500.00','4900.00','↓28.6%','万元','TAX'),
(10,'91320200MA2N3C4D5F','social_security_count','社保缴纳人数','180','220','↓18.2%','人','SOCIAL_SECURITY'),
(11,'91320200MA2N3C4D5F','accounts_receivable','应收账款','1800.00','1500.00','↑20.0%','万元','FINANCE'),
(12,'91320200MA2N3C4D5F','credit_overdue','征信逾期次数','0','0','无变化','次','CREDIT'),
(13,'91320200MA2N3C4D5F','external_guarantee','对外担保余额','600.00','550.00','↑9.1%','万元','CREDIT'),
(14,'91320200MA2N3C4D5F','new_litigation','新增作为被告诉讼数','0','0','无变化','件','JUDICIAL'),
(15,'91320200MA2N3C4D5F','salary_payment_count','代发工资人数','175','215','↓18.6%','人','SETTLEMENT')
) AS v(so,cc,k,n,cv,pv,cd,u,d)
WHERE c.credit_code = v.cc;

-- ==================== 2c. 指标数据 — 常州金茂 ====================
INSERT INTO indicator_data (customer_id, indicator_key, indicator_name, current_value, previous_value, change_desc, data_unit, domain, period, sort_order, created_at)
SELECT c.id, v.k, v.n, v.cv, v.pv, v.cd, v.u, v.d, '2025Q1', v.so, NOW()
FROM customer c
CROSS JOIN (VALUES
(1,'91320400MA3N4C5D6G','total_assets','总资产','3200.00','3100.00','↑3.2%','万元','FINANCE'),
(2,'91320400MA3N4C5D6G','revenue','营业收入','2500.00','2800.00','↓10.7%','万元','FINANCE'),
(3,'91320400MA3N4C5D6G','non_bank_financing','非银融资余额','85.00','40.00','↑112.5%','万元','CREDIT'),
(4,'91320400MA3N4C5D6G','credit_query_count','近3个月贷款审批查询次数','8','3','↑5次','次','CREDIT'),
(5,'91320400MA3N4C5D6G','external_guarantee','对外担保余额','450.00','300.00','↑50.0%','万元','CREDIT'),
(6,'91320400MA3N4C5D6G','capital_return_rate','资金归集率','55.0','62.0','↓7.0ppt','%','SETTLEMENT'),
(7,'91320400MA3N4C5D6G','tax_sales','纳税申报销售额','2300.00','2650.00','↓13.2%','万元','TAX'),
(8,'91320400MA3N4C5D6G','social_security_count','社保缴纳人数','28','32','↓12.5%','人','SOCIAL_SECURITY'),
(9,'91320400MA3N4C5D6G','accounts_receivable','应收账款','980.00','750.00','↑30.7%','万元','FINANCE'),
(10,'91320400MA3N4C5D6G','credit_overdue','征信逾期次数','1','0','新增1笔','次','CREDIT'),
(11,'91320400MA3N4C5D6G','new_litigation','新增作为被告诉讼数','1','0','新增1件','件','JUDICIAL'),
(12,'91320400MA3N4C5D6G','salary_payment_count','代发工资人数','26','31','↓16.1%','人','SETTLEMENT')
) AS v(so,cc,k,n,cv,pv,cd,u,d)
WHERE c.credit_code = v.cc;

-- ==================== 2d. 指标数据 — 南京建工 ====================
INSERT INTO indicator_data (customer_id, indicator_key, indicator_name, current_value, previous_value, change_desc, data_unit, domain, period, sort_order, created_at)
SELECT c.id, v.k, v.n, v.cv, v.pv, v.cd, v.u, v.d, '2025Q1', v.so, NOW()
FROM customer c
CROSS JOIN (VALUES
(1,'91320100MA4N5C6D7H','total_assets','总资产','180000.00','165000.00','↑9.1%','万元','FINANCE'),
(2,'91320100MA4N5C6D7H','revenue','营业收入','45000.00','48000.00','↓6.3%','万元','FINANCE'),
(3,'91320100MA4N5C6D7H','net_profit','净利润','1200.00','1800.00','↓33.3%','万元','FINANCE'),
(4,'91320100MA4N5C6D7H','asset_liability_ratio','资产负债率','78.0','72.0','↑6.0ppt','%','FINANCE'),
(5,'91320100MA4N5C6D7H','operating_cash_flow','经营现金流净额','-3500.00','-1800.00','恶化','万元','FINANCE'),
(6,'91320100MA4N5C6D7H','cash_equivalents','货币资金','15000.00','22000.00','↓31.8%','万元','FINANCE'),
(7,'91320100MA4N5C6D7H','accounts_receivable','应收账款','28000.00','22000.00','↑27.3%','万元','FINANCE'),
(8,'91320100MA4N5C6D7H','external_guarantee','对外担保余额','65000.00','52000.00','↑25.0%','万元','CREDIT'),
(9,'91320100MA4N5C6D7H','other_bank_credit','他行授信总额','52000.00','55000.00','↓5.5%','万元','CREDIT'),
(10,'91320100MA4N5C6D7H','credit_overdue','征信逾期次数','0','0','无变化','次','CREDIT'),
(11,'91320100MA4N5C6D7H','tax_sales','纳税申报销售额','42000.00','45000.00','↓6.7%','万元','TAX'),
(12,'91320100MA4N5C6D7H','social_security_count','社保缴纳人数','1200','1250','↓4.0%','人','SOCIAL_SECURITY'),
(13,'91320100MA4N5C6D7H','new_litigation','新增作为被告诉讼数','3','1','新增2件','件','JUDICIAL'),
(14,'91320100MA4N5C6D7H','litigation_amount','涉诉金额','8500.00','2000.00','↑325.0%','万元','JUDICIAL'),
(15,'91320100MA4N5C6D7H','salary_payment_count','代发工资人数','1180','1230','↓4.1%','人','SETTLEMENT')
) AS v(so,cc,k,n,cv,pv,cd,u,d)
WHERE c.credit_code = v.cc;

-- ==================== 2e. 指标数据 — 昆山新锐（正常对照） ====================
INSERT INTO indicator_data (customer_id, indicator_key, indicator_name, current_value, previous_value, change_desc, data_unit, domain, period, sort_order, created_at)
SELECT c.id, v.k, v.n, v.cv, v.pv, v.cd, v.u, v.d, '2025Q1', v.so, NOW()
FROM customer c
CROSS JOIN (VALUES
(1,'91320583MA5N6C7D8I','total_assets','总资产','25000.00','23000.00','↑8.7%','万元','FINANCE'),
(2,'91320583MA5N6C7D8I','revenue','营业收入','6800.00','6200.00','↑9.7%','万元','FINANCE'),
(3,'91320583MA5N6C7D8I','net_profit','净利润','850.00','780.00','↑9.0%','万元','FINANCE'),
(4,'91320583MA5N6C7D8I','asset_liability_ratio','资产负债率','45.0','46.0','↓1.0ppt','%','FINANCE'),
(5,'91320583MA5N6C7D8I','operating_cash_flow','经营现金流净额','920.00','850.00','↑8.2%','万元','FINANCE'),
(6,'91320583MA5N6C7D8I','accounts_receivable','应收账款','2200.00','2000.00','↑10.0%','万元','FINANCE'),
(7,'91320583MA5N6C7D8I','ar_turnover_days','应收账款周转天数','85','82','↑3天','天','FINANCE'),
(8,'91320583MA5N6C7D8I','external_guarantee','对外担保余额','500.00','500.00','持平','万元','CREDIT'),
(9,'91320583MA5N6C7D8I','other_bank_credit','他行授信总额','6000.00','5800.00','↑3.4%','万元','CREDIT'),
(10,'91320583MA5N6C7D8I','tax_sales','纳税申报销售额','6500.00','6000.00','↑8.3%','万元','TAX'),
(11,'91320583MA5N6C7D8I','social_security_count','社保缴纳人数','320','310','↑3.2%','人','SOCIAL_SECURITY'),
(12,'91320583MA5N6C7D8I','electricity_consumption','用电量','45.00','42.00','↑7.1%','万度','UTILITY'),
(13,'91320583MA5N6C7D8I','salary_payment_count','代发工资人数','315','305','↑3.3%','人','SETTLEMENT'),
(14,'91320583MA5N6C7D8I','new_litigation','新增作为被告诉讼数','0','0','无变化','件','JUDICIAL'),
(15,'91320583MA5N6C7D8I','credit_overdue','征信逾期次数','0','0','无变化','次','CREDIT')
) AS v(so,cc,k,n,cv,pv,cd,u,d)
WHERE c.credit_code = v.cc;

-- ==================== 3. 知识库规则 ====================
INSERT INTO knowledge_rule (rule_code, rule_name, rule_type, description, enabled, sort_order, created_at) VALUES
('R001', '实控人/重要股东/法人代表变更', 'BOOLEAN', '实际控制人变更、受益人变更、重要股东名单发生变更、法人代表/董监高变更。智能体基于大模型通识做深度推理。', 1, 1, NOW()),
('R002', '股权冻结及累计质押比例过高', 'THRESHOLD', '新增股权冻结、新增股权出质且累计质押比例过高、实控新增股权出质且累计质押比例过高。', 1, 2, NOW()),
('R003', '工商经营异常', 'BOOLEAN', '企业被列入工商经营异常名录。', 1, 3, NOW()),
('R004', '重大负面舆情', 'BOOLEAN', '证监立案调查等重大负面舆情。待行内分析后确定具体判定条件。', 1, 4, NOW()),
('R005', '资产负债率异常攀升', 'THRESHOLD', '资产负债率较去年同期显著攀升（国企↑≥5%，通用↑≥10%）。智能体对财务异动进行归因分析。', 1, 5, NOW()),
('R006', '经营现金流持续为负且流动性快速消耗', 'COMPOSITE', '经营现金流持续(近4季≥3季/连续2年)为负且货币资金下降≥30%。智能体对财务异动进行归因分析。', 1, 6, NOW()),
('R007', '经营性现金流实质性落后于收入', 'THRESHOLD', '净现比同比下降≥10%，经营现金流实质性落后于收入增长。智能体对财务异动进行归因分析。', 1, 7, NOW()),
('R008', '收入增速异常偏离经营基本面', 'COMPOSITE', '营收同比增速连续2年高于应收账款增速+30%、存货增速+30%、现金流增速+30%。智能体对财务异动进行归因分析。', 1, 8, NOW()),
('R009', '应收账款回收周期延长', 'THRESHOLD', '应收账款周转天数较去年同期延长超过60天或DSO翻倍。智能体对财务异动进行归因分析。', 1, 9, NOW()),
('R010', '他行授信压缩/抽贷', 'THRESHOLD', '全部他行授信总额大幅下降≥30%，疑似被其他金融机构压缩授信或抽贷。', 1, 10, NOW()),
('R011', '新增非银融资及征信查询异常', 'THRESHOLD', '非银融资余额增长≥30%、新增非银机构≥2家、近3月征信查询≥6次，融资渠道转向高成本非银机构。', 1, 11, NOW()),
('R012', '对外担保大幅增加', 'THRESHOLD', '对外担保余额较上期增长≥50%，或对外担保余额/净资产>50%（国企>60%）。', 1, 12, NOW()),
('R013', '征信新增逾期/垫款/代偿记录', 'BOOLEAN', '征信出现新增逾期>30天、多笔逾期、垫款或代偿记录、资产管理公司介入处置。', 1, 13, NOW()),
('R014', '债务重组/展期及分类劣化', 'BOOLEAN', '出现债务重组或展期记录、贷款五级分类劣化为关注及以下。', 1, 14, NOW()),
('R015', '信贷资金疑似回流或用途异常', 'BOOLEAN', '信贷资金疑似回流、资金用途疑似异常、受托支付资金疑似归集。以行内图谱判定结果为准。', 1, 15, NOW()),
('R016', '上下游客户异常', 'BOOLEAN', '上下游客户出现失信被执行人或被执行人、结算与授信申报上下游客户不匹配（≥3家不一致）。', 1, 16, NOW()),
('R017', '纳税申报异常', 'THRESHOLD', '纳税申报销售额同比大幅下降（小微↓≥30%，通用↓≥50%），企业实际经营规模收缩。', 1, 17, NOW()),
('R018', '经营运营数据异常（社保、水电气、海关）', 'COMPOSITE', '通用企业：用电↓≥15%且社保↓≥15%且纳税↓≥20%；纺织化工：用水骤降≥50%；外贸企业：海关出口骤降≥50%。交叉验证。', 1, 18, NOW()),
('R019', '政府管理部门负面信息', 'BOOLEAN', '新增行政处罚且处罚金额>50万、环保评级不良/严重不良、严重违法记录。', 1, 19, NOW()),
('R020', '新增作为被告的关键法诉记录', 'THRESHOLD', '任意一种满足：涉案金额>500万或>20%净资产、涉刑/破产。智能体基于大模型通识做深度推理。', 1, 20, NOW()),
('R021', '代发工资及用工异常', 'THRESHOLD', '连续2个月代发人数环比减少>30%，企业用工规模显著收缩。', 1, 21, NOW()),
('R022', '疑似借名贷款', 'BOOLEAN', '关联方交易及资金流向疑似存在借名贷款行为。以行内图谱判定结果为准。', 1, 22, NOW()),
('R023', '疑似担保圈链', 'BOOLEAN', '企业对外担保关系复杂，疑似构成担保圈链风险。以行内图谱判定结果为准。', 1, 23, NOW()),
('R024', '疑似与黑名单客户构成关联关系', 'BOOLEAN', '企业关联方中存在黑名单客户，疑似存在风险传导。以行内图谱判定结果为准。', 1, 24, NOW()),
('R025', '疑似未纳入集团授信', 'BOOLEAN', '关联企业疑似应纳入集团授信管理但尚未纳入。以行内图谱判定结果为准。', 1, 25, NOW());

-- ==================== 4. 规则条件（通过 rule_code 子查询引用规则 ID） ====================
INSERT INTO rule_condition (rule_id, indicator_key, operator, threshold, logic_order, logic_connector)
SELECT k.id, v.ik, v.op, v.th, v.lo, v.lc
FROM knowledge_rule k
CROSS JOIN (VALUES
('R001','shareholder_change','EXISTS',NULL,1,'AND'),
('R002','pledge_ratio','GT','50',1,'OR'),
('R002','controller_pledge_ratio','GTE','50',2,'OR'),
('R003','biz_abnormal','EXISTS',NULL,1,'AND'),
('R004','negative_news','EXISTS',NULL,1,'AND'),
('R005','asset_liability_ratio','GTE','5',1,'AND'),
('R006','operating_cash_flow','LT','0',1,'AND'),
('R006','cash_equivalents','LTE','-30',2,'AND'),
('R007','net_cash_ratio','LTE','-10',1,'AND'),
('R008','revenue','GT','0',1,'AND'),
('R008','accounts_receivable','GT','0',2,'AND'),
('R008','inventory','GT','0',3,'AND'),
('R008','operating_cash_flow','GT','0',4,'AND'),
('R009','ar_turnover_days','GT','60',1,'AND'),
('R010','other_bank_credit','LTE','-30',1,'AND'),
('R011','non_bank_financing','GTE','30',1,'OR'),
('R011','non_bank_institution_count','GTE','2',2,'OR'),
('R011','credit_query_count','GTE','6',3,'OR'),
('R012','external_guarantee','GTE','50',1,'OR'),
('R012','guarantee_to_equity_ratio','GT','50',2,'OR'),
('R013','credit_overdue','EXISTS',NULL,1,'AND'),
('R014','debt_restructure','EXISTS',NULL,1,'AND'),
('R015','fund_flow_anomaly','EXISTS',NULL,1,'AND'),
('R016','supplier_customer_anomaly','EXISTS',NULL,1,'AND'),
('R017','tax_sales','LTE','-30',1,'AND'),
('R018','electricity_consumption','LTE','-15',1,'AND'),
('R018','social_security_count','LTE','-15',2,'AND'),
('R018','tax_sales','LTE','-20',3,'AND'),
('R018','water_consumption','LTE','-50',4,'AND'),
('R018','customs_export','LTE','-50',5,'AND'),
('R019','gov_penalty','EXISTS',NULL,1,'AND'),
('R020','litigation_amount','GT','500',1,'OR'),
('R020','litigation_to_equity_ratio','GT','20',2,'OR'),
('R021','salary_payment_count','LTE','-30',1,'AND'),
('R022','suspected_nominee_loan','EXISTS',NULL,1,'AND'),
('R023','suspected_guarantee_chain','EXISTS',NULL,1,'AND'),
('R024','blacklist_relation','EXISTS',NULL,1,'AND'),
('R025','group_credit_omission','EXISTS',NULL,1,'AND')
) AS v(rc,ik,op,th,lo,lc)
WHERE k.rule_code = v.rc;

-- ==================== 5. 规则标签（通过 rule_code 子查询引用规则 ID） ====================
INSERT INTO rule_tag (rule_id, tag_type, tag_value)
SELECT k.id, v.tt, v.tv
FROM knowledge_rule k
CROSS JOIN (VALUES
('R001','RISK_TYPE','客户主体风险'),('R001','SCENARIO','公司治理'),
('R002','RISK_TYPE','客户主体风险'),('R002','SCENARIO','公司治理'),
('R003','RISK_TYPE','客户主体风险'),('R003','SCENARIO','公司治理'),
('R004','RISK_TYPE','客户主体风险'),('R004','SCENARIO','公司治理'),
('R005','RISK_TYPE','客户主体风险'),('R005','SCENARIO','财务健康度'),
('R006','RISK_TYPE','客户主体风险'),('R006','SCENARIO','财务健康度'),
('R007','RISK_TYPE','客户主体风险'),('R007','SCENARIO','财务健康度'),
('R008','RISK_TYPE','客户主体风险'),('R008','SCENARIO','财务健康度'),
('R009','RISK_TYPE','客户主体风险'),('R009','SCENARIO','财务健康度'),
('R010','RISK_TYPE','客户主体风险'),('R010','SCENARIO','信用履约能力'),
('R011','RISK_TYPE','客户主体风险'),('R011','SCENARIO','信用履约能力'),
('R012','RISK_TYPE','客户主体风险'),('R012','SCENARIO','信用履约能力'),
('R013','RISK_TYPE','客户主体风险'),('R013','SCENARIO','信用履约能力'),
('R014','RISK_TYPE','客户主体风险'),('R014','SCENARIO','信用履约能力'),
('R015','RISK_TYPE','交易行为风险'),('R015','SCENARIO','信贷资金流向异常'),
('R016','RISK_TYPE','交易行为风险'),('R016','SCENARIO','经营活动异动'),
('R017','RISK_TYPE','交易行为风险'),('R017','SCENARIO','经营活动异动'),
('R018','RISK_TYPE','交易行为风险'),('R018','SCENARIO','经营活动异动'),
('R019','RISK_TYPE','交易行为风险'),('R019','SCENARIO','经营活动异动'),
('R020','RISK_TYPE','交易行为风险'),('R020','SCENARIO','经营活动异动'),
('R021','RISK_TYPE','交易行为风险'),('R021','SCENARIO','结算行为偏离'),
('R022','RISK_TYPE','关联关系合规风险'),('R022','SCENARIO','关联关系'),
('R023','RISK_TYPE','关联关系合规风险'),('R023','SCENARIO','关联关系'),
('R024','RISK_TYPE','关联关系合规风险'),('R024','SCENARIO','关联关系'),
('R025','RISK_TYPE','关联关系合规风险'),('R025','SCENARIO','关联关系')
) AS v(rc,tt,tv)
WHERE k.rule_code = v.rc;

-- ==================== 6. 规则场景 ====================
INSERT INTO rule_scenario (scenario_code, scenario_name, description) VALUES
('FULL_CHECK', '全面贷后检查', '依据贷后管理制度执行的全面贷后风险检查，覆盖客户主体风险、交易行为风险、关联关系合规风险三大维度。');
