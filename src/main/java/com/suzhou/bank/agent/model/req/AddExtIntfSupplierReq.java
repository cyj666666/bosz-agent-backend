package com.suzhou.bank.agent.model.req;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import java.io.Serializable;

@Data
public class AddExtIntfSupplierReq implements Serializable {

    private static final long serialVersionUID = 1L;

    @NotBlank
    private String supplierId;

    @NotBlank
    private String supplierName;

    @NotBlank
    private String intfType;

    @NotBlank
    private String intfPath;

    private String status = "1";

    private String inputUserId;

    private String inputUserName;

    private String inputTime;

    private String updateUserId;

    private String updateUserName;

    private String updateTime;
}
