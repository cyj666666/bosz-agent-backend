package com.suzhou.bank.agent.model.req;

import lombok.Data;

import javax.validation.constraints.NotBlank;

@Data
public class CheckExtIntfSupplierRepeatReq {

    @NotBlank
    private String supplierId;

}
