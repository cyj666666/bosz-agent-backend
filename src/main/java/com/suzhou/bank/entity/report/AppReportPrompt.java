package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 报告提示词表（app_report_prompt）
 *
 * <p>把「AI 全文分析」「预警建议」等场景的提示词从代码挪到表里，改提示词不用改代码、不用发版。
 * 取用方式：<b>每次调用时按 {@code promptCode} 查表</b>（改完立即生效）；查不到或
 * {@code isEnabled != 'Y'} 时自动回落到代码里的兜底常量，所以空库也能跑。</p>
 *
 * <p>{@code userPromptTemplate} 里用 {@code {material}} 占位，调用时整段替换为组装好的素材。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
@TableName("app_report_prompt")
public class AppReportPrompt {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 提示词编码（唯一）：AI_FULL_ANALYSIS-全文分析 / WARNING_ADVICE-预警建议 */
    @TableField("promptCode")
    private String promptCode;

    /** 提示词名称（界面展示用） */
    @TableField("promptName")
    private String promptName;

    /** 场景分类（AI_ANALYSIS 等，便于分组管理） */
    @TableField("sceneType")
    private String sceneType;

    /** 系统提示词（角色、要求、输出格式） */
    @TableField("systemPrompt")
    private String systemPrompt;

    /** 用户提示词模板，用 {material} 占位，调用时替换为素材 */
    @TableField("userPromptTemplate")
    private String userPromptTemplate;

    /** 是否启用：Y-启用 N-停用（停用则回落到代码兜底常量） */
    @TableField("isEnabled")
    private String isEnabled;

    /** 备注 */
    @TableField("remark")
    private String remark;

    @TableField("inputtime")
    private Date inputtime;

    @TableField("updateTime")
    private Date updateTime;
}
