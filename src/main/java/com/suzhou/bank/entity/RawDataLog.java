package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("raw_data_log")
public class RawDataLog {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long collectorId;
    private String rawContent;
    private String contentType;
    private String filePath;
    private java.util.Date collectTime;
    private Long customerId;
    private Integer success;
    private String errorMsg;
    private java.util.Date createdAt;
}