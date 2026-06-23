package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

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