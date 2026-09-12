package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 报告主表（report）
 * <p>报告实例层的入口表，一次报告生成一条记录。
 * 报告头（公司名称等展示内容）不落本表，由内容实例表中 titleLevel=1 的标题类内容块承载。</p>
 * <p>说明：本表列名为下划线命名（snake_case），MyBatis-Plus 全局开启了
 * map-underscore-to-camel-case 映射，字段名（camelCase）与列名自动对应，
 * 故无需逐字段声明 {@code @TableField}。</p>
 * <p>报告记录由上游预生成（初始状态 {@code status=111} 待开始），
 * 生成服务只负责状态流转（000/888/999）与失败原因落库。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@TableName("report")
public class Report {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 报告编号（业务唯一键，关联内容实例表与 AI 风险表；VARCHAR(64)） */
    private String reportNo;

    /** 客户编号 */
    private String customerId;

    /** 客户名称 */
    private String customerName;

    /** 报告标题（报告头大标题的文案来源） */
    private String reportTitle;

    /** 报告类型 */
    private String reportType;

    /** 日检任务编号（日检流水号，同一流水号下可有多个版本） */
    private String checkTaskNo;

    /** 报告版本号（1/2/3…，同一 checkTaskNo 下区分历史版本；数字存储便于排序，"V"前缀由前端拼接） */
    private Integer version;

    /** 报告状态：111-待开始 000-进行中 888-已完成 999-失败 */
    private String status;

    /** 失败原因：生成过程发生异常（技术类或业务类）时记录详细信息，成功时为空 */
    private String failReason;

    /** 入库时间（数据库默认值） */
    private Date createdAt;

    /** 更新时间（状态流转/失败原因写入时刷新） */
    private Date updatedAt;
}
