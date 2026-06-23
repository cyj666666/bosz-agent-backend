package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("parser_config")
public class ParserConfig {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long collectorId;
    private String parserType;
    private String configJson;
    private String domain;
    private Integer sortOrder;
    private java.util.Date createdAt;
    private java.util.Date updatedAt;
}