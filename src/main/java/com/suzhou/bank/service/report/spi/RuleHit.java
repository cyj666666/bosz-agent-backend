package com.suzhou.bank.service.report.spi;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 一条「命中的经验规则」摘要（供风险要点总结用）
 *
 * <p>报告生成跑到「（一）风险要点」的总结块时，把本报告**已生成的全部 RULE 块**
 * 收敛成若干个本对象交给 {@link ReportContentProvider#provideRuleSummary}，
 * 由加工方（智能体侧）拼素材、调大模型出总结。</p>
 *
 * <p>只带「够写总结」的最小信息：是哪条规则、挂在哪个章节、正文内容是什么。</p>
 *
 * @author cyj666666
 * @since 1.4.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RuleHit {

    /** 规则类内容块编号（= 正文里那条风险的定位锚点） */
    private String blockCode;

    /** 规则名称（即内容块名称） */
    private String blockName;

    /** 该规则块的正文内容（大模型生成的风险文案） */
    private String content;

    /** 所属章节名称（写总结时用来分组/说明位置） */
    private String catalogName;
}
