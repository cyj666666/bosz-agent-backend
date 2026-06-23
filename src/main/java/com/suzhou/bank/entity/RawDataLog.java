package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 原始数据日志表（raw_data_log）
 * <p>记录每次数据采集的原始数据快照，用于审计追溯和故障排查。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
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