package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 报告用户行为记录表（app_report_action_log）—— 2026-09-23 测试反馈 #6
 *
 * <p><b>一行 = 一次「采纳 / 无效 / 恢复待处理」的人工决定</b>，AI 风险要点与预警建议<b>共用本表</b>
 * （靠 {@code targetType} 区分），只增不改，纯审计用途。</p>
 *
 * <p><b>为什么单独建表、而不给两张业务表加 operator 列</b>：</p>
 * <ol>
 *   <li>业务表只能留住「<b>最后一次</b>是谁处理的」——改回来就没了；本表是流水，
 *       能回答"谁在什么时候把已采纳改成了无效"；</li>
 *   <li>{@code app_report_ai_risk} 原本<b>连 operator 列都没有</b>，加列就得动存量表结构、
 *       而行内的存量表结构是不能随便改的；新建表不动任何既有表。</li>
 * </ol>
 *
 * <p><b>与 {@code app_report_risk_edit_log} 的分工</b>：那张表记的是「正文被改成了什么」
 * （含内容前后快照），本表记的是「状态被谁改成了什么」。两者都按 {@code checkTaskNo} 归档，
 * 可跨版本追溯。</p>
 *
 * <p>⛔ <b>写入失败不得影响主流程</b>：状态更新成功与否不取决于本表写入，
 * 调用方一律 try-catch 兜住（审计留痕是"尽力而为"，不能因为它让用户点了采纳却报错）。</p>
 *
 * @author 曹陆宇
 * @since 1.4.0
 */
@Data
@TableName("app_report_action_log")
public class AppReportActionLog {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 日检流水号（归档维度①，跨版本追溯用） */
    @TableField("checkTaskNo")
    private String checkTaskNo;

    /** 产生本次操作的报告编号（定位到是哪一版） */
    @TableField("reportNo")
    private String reportNo;

    /** 行为对象类型：AI_RISK-AI风险要点 / WARNING_ADVICE-预警建议 */
    @TableField("targetType")
    private String targetType;

    /** 行为对象主键（app_report_ai_risk.id / app_report_warning_advice.id） */
    @TableField("targetId")
    private Long targetId;

    /** 行为对象业务编号（AI风险=blockCode / 预警建议=seqNo） */
    @TableField("targetCode")
    private String targetCode;

    /** 行为对象名称（AI风险=规则名 / 预警建议=预警信号描述，超长已截断） */
    @TableField("targetName")
    private String targetName;

    /** 变更前状态：ADOPTED / INVALID / PENDING（首次操作前为 PENDING 或空） */
    @TableField("statusBefore")
    private String statusBefore;

    /** 变更后状态：ADOPTED-已采纳 / INVALID-无效 / PENDING-待处理 */
    @TableField("statusAfter")
    private String statusAfter;

    /** 操作人账号 */
    @TableField("operatorNo")
    private String operatorNo;

    /** 操作人姓名（取 sys_user.real_name，取不到回落账号） */
    @TableField("operatorName")
    private String operatorName;

    /** 操作时间（默认当前时间） */
    @TableField("inputtime")
    private Date inputtime;
}
