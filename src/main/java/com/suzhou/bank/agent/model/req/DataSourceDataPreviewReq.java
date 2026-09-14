package com.suzhou.bank.agent.model.req;

import com.alibaba.fastjson.JSONArray;
import lombok.Data;

/**
 * 数据预览请求参数
 *
 * @author 16221
 */
@Data
public class DataSourceDataPreviewReq {

    private Integer tableNo;

    /**
     * 表名
     */
    private String tableName;

    /**
     * 数据源id
     */
    private String dataSourceId;

    /**
     * 页码
     */
    private Integer pageIndex;

    /**
     * 页大小
     */
    private Integer pageSize = 10;

    /**
     * sql内容
     */
    private String sqlContent;

    /**
     * sql参数
     */
    private JSONArray sqlParam;

}
