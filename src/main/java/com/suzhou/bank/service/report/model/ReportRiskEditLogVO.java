package com.suzhou.bank.service.report.model;

import lombok.Data;

import java.util.Date;

/**
 * 风险要点修改记录项（详情页「修改记录」弹窗数据源）
 *
 * <p>归档维度为「同日检流水号 + 同风险要点」，故本 VO 不含 reportNo 之外的行身份字段；
 * 前端按 inputtime 倒序（最新在上）编号为 {@code 1、2、3…}，展示文案形如：</p>
 * <pre>1、张三  2026-09-12 16:30  修改为：xxxxxxxx</pre>
 *
 * @author cyj666666
 * @since 1.2.0
 */
@Data
public class ReportRiskEditLogVO {

    /** 修改人姓名（取不到 real_name 时回落账号） */
    private String operatorName;

    /** 修改人账号 */
    private String operatorNo;

    /** 修改时间 */
    private Date inputtime;

    /** 修改后文案（列表展示用） */
    private String contentAfter;

    /** 修改前文案（审计对比用；前端默认不展示，需要时可做前后对比） */
    private String contentBefore;

    /** 该次修改发生在哪一版报告上 */
    private String reportNo;
}
