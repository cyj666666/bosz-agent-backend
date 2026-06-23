package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 文本数据表（text_data）
 * <p>所有文本数据的统一存储，如 OCR 原始文本、分析总结等。
 * 是 Know-Kit 文本分析输入和报告文字内容的数据来源。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@TableName("text_data")
public class TextData {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long customerId;
    private String textType;
    private String domain;
    private String title;
    private String content;
    private String period;
    private java.util.Date createdAt;
}