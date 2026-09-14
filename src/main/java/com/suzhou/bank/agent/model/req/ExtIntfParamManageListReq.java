package com.suzhou.bank.agent.model.req;

import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

import javax.validation.constraints.NotBlank;

@Data
public class ExtIntfParamManageListReq extends PageBaseParam {

    @NotBlank
    private String supplierId;

    @NotBlank
    private String intfNo;

}
