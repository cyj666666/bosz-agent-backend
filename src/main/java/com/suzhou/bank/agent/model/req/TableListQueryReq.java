package com.suzhou.bank.agent.model.req;

import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

@Data
public class TableListQueryReq extends PageBaseParam {

    /**
     * 表名
     */
    private String tableName;

    /**
     * 表注释
     */
    private String tableNote;

    /**
     * 数据库源
     */
    private String dataSourceId;

    //数据源名称
    private String dataSourceName;

}
