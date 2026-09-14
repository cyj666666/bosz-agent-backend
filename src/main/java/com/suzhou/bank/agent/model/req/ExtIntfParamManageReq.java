package com.suzhou.bank.agent.model.req;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import java.io.Serializable;

@Data
public class ExtIntfParamManageReq implements Serializable {

    private static final long serialVersionUID = 1L;

    private String id;

    @NotBlank
    private String supplierId;

    @NotBlank
    private String intfNo;

    @NotBlank
    private String paramCode;

    @NotBlank
    private String paramName;

    @NotBlank
    private String paramType;

    private String childParamCode;

    private String childParamName;

    private String childParamType;

    private String paramIsRequired = "0";

    @NotBlank
    private String paramPosition;

    @NotBlank
    private String paramSource;

    private String sourceTypeDetail;

    private String sourceField;

    private String sourceFieldName;

    private String sourceFieldDictId;

    private String sourceParamCode;

    private String sourceParamType;

    private String paramValue;

    private String inputUserId;

    private String inputUserName;

    private String inputTime;

    private String updateUserId;

    private String updateUserName;

    private String updateTime;
}
