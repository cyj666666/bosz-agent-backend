package com.suzhou.bank.agent.model.req;

import lombok.Data;

import java.util.Map;

/**
 * 数据预览请求参数
 *
 * @author 16221
 */
@Data
public class ParamsDataSourceDataPreviewReq {

    private String datasource;

    private String sql;

    private Map<String, Object> parameters;
}
