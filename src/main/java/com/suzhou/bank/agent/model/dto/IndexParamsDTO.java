package com.suzhou.bank.agent.model.dto;


import lombok.Data;

import java.util.List;

@Data
public class IndexParamsDTO {

    private List<IndexParamsDTO> children;

    private IndexParamsDTO parent;

    private String paramNo;

    private String paramID;

    private String paramName;

    private String paramType;

    private String codeMethod;

    private String codeNo;

    private String required;

    private String readOnly;

    private String defaultFormat;

    private String inputMethod;

    private String fromParamNo;

    private String defaultValue;

    private String parentParamNo;

    private String publicParamStatus;

    private String modelNo;

    private String inputUserID;

    private String inputTime;

    private String updateTime;

    private String updateUserID;

    private String inputOrgID;

    private String updateOrgID;

    private String initMethod;

    private String dataMethod;

    private String parentParamName;

    private String reportVersion;

    private String versionNo;

    private String paramSource;

    private String chartType;

    private String sortNo;

    private String placeHolder;

    private String actureColumn;

    private String columnLength;

    private String columnType;

    private String columnRemark;

    private String columnIsNull;

    private String columnComment;

    private String columnFromTable;

    private String columnFromDataSource;

    private String ScriptType;

    private String Script;

    private String scriptTypeDesc;

    private String indexSource;
    
    private String supplierId;

    
    private String intfNo;

    
    private String intfParams;

    
    private String intfField;

    
    private String structure;

    
    private String extendField;

    
    private List<Object> fieldList;
}
