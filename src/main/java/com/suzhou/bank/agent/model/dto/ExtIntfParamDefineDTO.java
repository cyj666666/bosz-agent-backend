package com.suzhou.bank.agent.model.dto;

import lombok.Data;

import java.io.Serializable;

@Data
public class ExtIntfParamDefineDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private String id;

    private String supplierId;

    private String paramCode;

    private String paramType;

    private String paramValue;

    private String inputUserId;

    private String inputUserName;

    private String inputTime;

    private String updateUserId;

    private String updateUserName;

    private String updateTime;

    private String paramPosition;

    private String paramIsRequired;
}
