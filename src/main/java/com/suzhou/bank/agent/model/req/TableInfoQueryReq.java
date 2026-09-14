package com.suzhou.bank.agent.model.req;

import lombok.Data;

@Data
public class TableInfoQueryReq {

    private Integer tableNo;

    private String tableName;

    private String dataSourceId;

    private Integer status;
}
