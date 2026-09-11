package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 贷后报告主表（app_report_info）
 * <p>报告实例层的入口表，一次报告生成一条记录。
 * 报告头（公司名称等展示内容）不落本表，由内容实例表中 titleLevel=1 的标题类内容块承载。</p>
 * <p>说明：本表列名为 camelCase，MyBatis-Plus 全局开启了 underscore-to-camel 映射，
 * 故每个字段显式声明 {@link TableField}，避免字段名被转换为下划线形式。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
@TableName("app_report_info")
public class AppReportInfo {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 报告编号（业务唯一键，关联内容实例表与 AI 风险表） */
    @TableField("reportNo")
    private String reportNo;

    @TableField("customerId")
    private String customerId;

    @TableField("customerName")
    private String customerName;

    /** 报告标题（报告头大标题的文案来源） */
    @TableField("reportTitle")
    private String reportTitle;

    /** 日检任务编号 */
    @TableField("checkTaskNo")
    private String checkTaskNo;

    /** 报告日期（贷后检查日） */
    @TableField("reportDate")
    private String reportDate;

    /** 报告状态：生成中 / 已生成 / 已审批 */
    @TableField("reportStatus")
    private String reportStatus;

    @TableField("generatorName")
    private String generatorName;

    @TableField("generateTime")
    private Date generateTime;

    @TableField("approveStatus")
    private String approveStatus;

    @TableField("approveOpinion")
    private String approveOpinion;

    @TableField("approveTime")
    private Date approveTime;

    @TableField("reportUrl")
    private String reportUrl;

    /** 失败原因：生成过程发生异常（技术类或业务类）时记录详细信息，成功时为空 */
    @TableField("failReason")
    private String failReason;

    /** 入库时间（数据库默认值，插入时留空即可） */
    @TableField("inputtime")
    private Date inputtime;
}
