package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

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
}