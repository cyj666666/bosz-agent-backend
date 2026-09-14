package com.suzhou.bank.agent.model.req;

import lombok.Data;

import javax.validation.constraints.NotBlank;

@Data
public class CheckExtIntfParamDefineRepeatReq {

    @NotBlank
    private String supplierId;

    @NotBlank
    private String paramCode;

}
