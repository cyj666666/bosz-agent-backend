package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("credit_record")
public class CreditRecord {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long customerId;
    private String contractNo;
    private String loanType;
    private String currency;
    private String loanAmount;
    private String loanBalance;
    private java.util.Date startDate;
    private java.util.Date endDate;
    private String loanPurpose;
    private String guaranteeType;
    private java.util.Date createdAt;
}