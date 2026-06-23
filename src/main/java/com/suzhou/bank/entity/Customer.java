package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("customer")
public class Customer {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String companyName;
    private String creditCode;
    private String legalPerson;
    private String actualController;
    private String registeredCapital;
    private String paidCapital;
    private java.util.Date establishDate;
    private String industry;
    private String bizScope;
    private String registerAddress;
    private String holdingType;
    private String shareholder;
    private String groupName;
    private String customerType;
    private java.util.Date firstLoanDate;
    private java.util.Date lastApprovalDate;
    private String mainBank;
    private String settlementBank;
    private String status;
    private java.util.Date createdAt;
    private java.util.Date updatedAt;
}