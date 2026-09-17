package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 担保人信息表（app_guarantor_info）
 *
 * <p>只映射报告加工真正用到的几列 —— 本表还有 {@code isStateOwned / education /
 * zxReportNoZX} 等列，未用到故不映射（MyBatis-Plus 只查询已声明字段即可）。</p>
 *
 * <p><b>用途</b>：报告模板里标注了 {@code agentParams = reportNo,entName,guarantorName}
 * 的内容块（如「十二、（二）担保人征信信息」下那一批），要按**企业担保人**口径轮循调用智能体，
 * 这里就是取 {@code guarantorName} 的来源：
 * {@code reportNo + subjectType='担保人' + guarantorType='法人'}。</p>
 *
 * @author cyj666666
 * @since 1.4.0
 */
@Data
@TableName("app_guarantor_info")
public class AppGuarantorInfo {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 报告编号 */
    @TableField("reportNo")
    private String reportNo;

    /** 担保人名称 */
    @TableField("guarantorName")
    private String guarantorName;

    /** 担保人类型：法人 / 自然人 */
    @TableField("guarantorType")
    private String guarantorType;

    /** 主体类型：借款人 / 担保人 */
    @TableField("subjectType")
    private String subjectType;
}
