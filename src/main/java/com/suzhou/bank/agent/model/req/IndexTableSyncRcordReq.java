package com.suzhou.bank.agent.model.req;


import lombok.Data;

import java.io.Serializable;


@Data
// @ApiModel(value = "表名预处理指标请求对象", description = "IndexTableSyncRcordReq")
public class IndexTableSyncRcordReq implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 表名
     */
    private String tableName;

    /**
     * 指标分组流水号
     */
    private String paramNo;

    /**
     * 指标分组名称
     */
    private String paramName;

    /**
     * 指标所属模板编号
     */
    private String modelNo;

    /**
     * 指标版本
     */
    private String reportVersion;

    /**
     * 指标版本号
     */
    private String versionNo;

    /**
     * 数据源ID
     */
    private String dataSourceId;

    /**
     * 指标编号
     */
    private String paramId;

}
