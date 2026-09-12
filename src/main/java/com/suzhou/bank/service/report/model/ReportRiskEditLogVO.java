package com.suzhou.bank.service.report.model;

import lombok.Data;

import java.util.Date;

/**
 * 风险要点修改记录项（详情页「修改记录」弹窗数据源）
 *
 * <p>归档维度为「同日检流水号 + 同风险要点」，故本 VO 不含 reportNo 之外的行身份字段；
 * 列表按 <b>inputtime 正序（最早在上）</b>返回，首位是置顶的「原始版本」条目，其后人工修改记录
 * 按 1、2、3… 编号（自早向晚），展示文案形如：</p>
 * <pre>1、张三  2026-09-12 16:30  修改为：xxxxxxxx</pre>
 *
 * <p>{@link #original} 为 true 的项是**人造的「原始版本」条目**（不在归档表里）：正文的 content 是原地覆盖的，
 * AI 生成的第一版只能由「最早一条归档的 contentBefore」反推，故由后端在列表**首位**补一条，
 * 前端置顶展示、且不参与「N 次修改」的计数与序号编号。</p>
 *
 * @author cyj666666
 * @since 1.2.0
 */
@Data
public class ReportRiskEditLogVO {

    /** 是否为「原始版本」（AI 生成的第一版内容）；仅列表首条可能为 true */
    private Boolean original;

    /** 修改人姓名（取不到 real_name 时回落账号；原始版本条目为空） */
    private String operatorName;

    /** 修改人账号（原始版本条目为空） */
    private String operatorNo;

    /** 修改时间（原始版本条目为空——AI 生成时间未单独留存） */
    private Date inputtime;

    /** 修改后文案（列表展示用）；原始版本条目即 AI 生成的第一版内容 */
    private String contentAfter;

    /** 修改前文案（审计对比用；前端默认不展示，需要时可做前后对比） */
    private String contentBefore;

    /** 该次修改发生在哪一版报告上（原始版本条目为空） */
    private String reportNo;
}
