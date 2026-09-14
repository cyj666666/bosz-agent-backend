package com.suzhou.bank.agent.model.req;

import lombok.Data;

@Data
public class DataSourceTableInfoReq {

    //数据源id
    private String dataSourceId;

    //数据源名称
    private String dataSourceName;

    //表名
    private String tableName;

}
