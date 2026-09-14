package com.suzhou.bank.agent.model.req;

import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

@Data
public class ExtIntfSupplierListReq extends PageBaseParam {

    private String supplierId;

    private String supplierName;

    private String supplierType;

}
