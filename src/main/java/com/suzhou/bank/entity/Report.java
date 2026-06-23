package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 报告主表（report）
 * <p>存储贷后管理报告，包含 H5 HTML 内容和生成时的数据快照（dataSnapshot）。
 * 报告一旦生成即不可变，dataSnapshot 保证历史回溯和审计完整性。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@TableName("report")
public class Report {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long customerId;
    private String reportTitle;
    private String reportType;
    private String status;
    private Long knowKitTaskId;
    private String contentHtml;
    private String dataSnapshot;
    private java.util.Date createdAt;
    private java.util.Date updatedAt;

    /** 关联查询用，非数据库字段 */
    @com.baomidou.mybatisplus.annotation.TableField(exist = false)
    private String companyName;
}