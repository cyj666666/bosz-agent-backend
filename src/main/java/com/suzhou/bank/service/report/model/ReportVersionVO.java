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

    /** 版本号（如 V1/V2/V3，可能为空） */
    private String version;

    /** 报告状态：111-待开始 000-进行中 888-已完成 999-失败 */
    private String status;

    /** 更新时间（生成完成/失败时刷新） */
    private Date updatedAt;
}
