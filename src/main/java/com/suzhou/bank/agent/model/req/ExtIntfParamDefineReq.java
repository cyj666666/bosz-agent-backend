package com.suzhou.bank.agent.model.req;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import java.io.Serializable;

@Data
public class ExtIntfParamDefineReq implements Serializable {

    private static final long serialVersionUID = 1L;

    private String id;

    @NotBlank
    private String supplierId;

    @NotBlank
    private String paramCode;

    @NotBlank
    private String paramType;

    @NotBlank
    private String paramPosition;

    @NotBlank
    private String paramIsRequired;

    private String paramValue;

    private String inputUserId;

    private String inputUserName;

    private String inputTime;

    private String updateUserId;

    private String updateUserName;

    private String updateTime;
}
