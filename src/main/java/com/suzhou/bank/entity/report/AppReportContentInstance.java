package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 报告内容实例表（app_report_content_instance，实例层）
 * <p>一条内容块 → 一条实例，所有填充类型的正文内容一律落在 content 大字段：
 * TITLE-标题文案 / TEXT-分析文本（analysisType=RULE 时为经验规则类内容体）/
 * TABLE-表格成品内容 / SOURCE_LINK-外部跳转链接（块本身就是按钮，点击新开浏览器标签页）。</p>
 * <p>两类"跳转"互相独立：外链看 SOURCE_LINK 块的 content；块间定位看 jumpAnchorCode（与填充类型无关）。</p>
 * <p>结构性字段为生成时对模板的快照，目的是一次查询即可渲染、且模板改版不污染历史报告。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
@TableName("app_report_content_instance")
public class AppReportContentInstance {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("reportNo")
    private String reportNo;

    @TableField("customerId")
    private String customerId;

    @TableField("customerName")
    private String customerName;

    /** 内容块编号（关联模板层 app_report_content_block.blockCode） */
    @TableField("blockCode")
    private String blockCode;

    /** 所属目录编号（报告级内容块为 NULL） */
    @TableField("catalogCode")
    private String catalogCode;

    @TableField("fillType")
    private String fillType;

    @TableField("analysisType")
    private String analysisType;

    @TableField("agentCode")
    private String agentCode;

    @TableField("ruleName")
    private String ruleName;

    @TableField("titleLevel")
    private Integer titleLevel;

    @TableField("sortNo")
    private Integer sortNo;

    /** 锚点编码：本块在报告内的定位锚点（默认取 blockCode），作为其它块跳转的目标标识 */
    @TableField("anchorCode")
    private String anchorCode;

    /**
     * 块间跳转锚点（单向）：点击本块时跳转到的目标块 anchorCode。
     * <p>仅用于内容块之间的点击快速定位，不是外部跳转链接；无跳转则为 NULL。
     * <b>与填充类型无关</b>：任何填充类型的块配置了本值即可跳转。</p>
     */
    @TableField("jumpAnchorCode")
    private String jumpAnchorCode;

    /**
     * 内容成品（大文本）；前置加工无数据时为 NULL，按模板 emptyStrategy 渲染。
     * <p>填充类型为 SOURCE_LINK 时，此处存外部跳转链接（前端渲染为按钮，点击新开浏览器标签页）。</p>
     */
    @TableField("content")
    private String content;

    @TableField("inputtime")
    private Date inputtime;
}
