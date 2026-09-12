package com.suzhou.bank.service.report.model;

import lombok.Data;

import java.util.Date;

/**
 * 报告版本项（版本下拉框数据源）
 * <p>同一日检流水号（checkTaskNo）下的一条报告记录即一个版本，
 * 供详情页顶部下拉框切换历史版本用。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
public class ReportVersionVO {

    /** 报告编号（详情接口入参） */
    private String reportNo;

    /** 版本号（1/2/3…，可能为空；"V"前缀由前端拼接） */
    private Integer version;

    /** 报告状态：111-待开始 000-进行中 888-已完成 999-失败 */
    private String status;

    /** 失败原因（status=999 时有值，供前端提示"新报告生成失败"） */
    private String failReason;

    /** 更新时间（生成完成/失败时刷新） */
    private Date updatedAt;
}
