package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("know_kit_task")
public class KnowKitTask {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long customerId;
    private String scenarioTags;
    private String requestJson;
    private String responseJson;
    private String status;
    private String errorMsg;
    private java.util.Date createdAt;
    private java.util.Date completedAt;
}