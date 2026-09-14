package com.suzhou.bank.agent.model.req;

import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

import javax.validation.constraints.NotBlank;

@Data
public class ExtIntfParamDefineListReq extends PageBaseParam {

    @NotBlank
    private String supplierId;

    private String paramCode;

}
