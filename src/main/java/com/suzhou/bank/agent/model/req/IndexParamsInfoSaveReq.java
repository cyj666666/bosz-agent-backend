package com.suzhou.bank.agent.model.req;


import lombok.Data;


@Data
public class IndexParamsInfoSaveReq {
    private static final long serialVersionUID = 1L;

    private String paramNo;

    private String paramID;

    private String paramName;

    private String paramType;

    private String dataMethod;

    private String codeMethod;

    private String codeNo;

    private String required;

    private String defaultFormat;

    private String fromParamNo;

    private String inputMethod;

    private String placeHolder;

    private String defaultValue;

    private String parentParamNo;

    private String parentParamName;

    private String publicParamStatus;

    private String modelNo;

    private String inputUserID;

    private String inputTime;

    private String updateTime;

    private String inputOrgID;

    private String updateOrgID;

    private String initMethod;

    private String updateUserID;

    private String reportVersion;

    private String versionNo;

    private String paramSource;

    private String columnLength;

    private String columnType;

    private String columnRemark;

    private String columnIsNull;

    private String columnComment;

    private String columnFromTable;

    private String columnFromDataSource;

    private String actureColumn;

    private String chartType;

    private String script;

    private String scriptType;

    private String otherConfig;

    private String validators;

    private String chartInitMethod;

    private String readOnly;

    private String supplierId;

    private String intfNo;

    private String intfParams;

    private String intfField;

    private String structure;

    private String extendField;

    private String countField;

    private Integer isOnline;

    /**
     * 指标介绍
     */
    private String metricIntro;

    /**
     * 数值单位
     */
    private String dataUnit;

    /**
     * 数据样例
     */
    private String dataExample;

    /**
     * 数据类型
     */
    private String dataType;

    /**
     * 数据内容解析
     */
    private String dataContentParse;

    /**
     * 指标唯一标志
     */
    private String paramKey;
}
