package com.suzhou.bank.agent.model.dto;

import lombok.Data;

import java.io.Serializable;

@Data
public class ExtIntfSupplierDTO implements Serializable {
    private static final long serialVersionUID = 1L;

    private String supplierId;

    private String supplierName;

    private String intfType;

    private String intfPath;

    private String status;

    private String inputUserId;

    private String inputUserName;

    private String inputTime;

    private String updateUserId;

    private String updateUserName;

    private String updateTime;

}
