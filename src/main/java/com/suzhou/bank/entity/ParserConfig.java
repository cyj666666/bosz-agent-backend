package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 解析器配置表（parser_config）
 * <p>定义"怎么解析数据"，将采集器获取的原始数据转换为标准化指标。
 * 一个采集器可配置多个解析器，按 sortOrder 顺序执行。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
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