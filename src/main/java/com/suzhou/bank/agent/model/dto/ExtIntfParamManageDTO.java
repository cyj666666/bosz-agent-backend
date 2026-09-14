package com.suzhou.bank.agent.model.dto;

import lombok.Data;

import java.io.Serializable;

@Data
public class ExtIntfParamManageDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private String id;

    private String supplierId;

    private String intfNo;

    private String paramCode;

    private String paramName;

    private String paramType;

    private String childParamCode;

    private String childParamName;

    private String childParamType;

    private String paramValue;

    private String paramIsRequired;

    private String paramPosition;

    private String paramSource;

    private String sourceTypeDetail;

    private String sourceField;

    private String sourceFieldName;

    private String sourceFieldDictId;

    private String sourceParamCode;

    private String sourceParamType;

    private String inputUserId;

    private String inputUserName;

    private String inputTime;

    private String updateUserId;

    private String updateUserName;

    private String updateTime;
}
