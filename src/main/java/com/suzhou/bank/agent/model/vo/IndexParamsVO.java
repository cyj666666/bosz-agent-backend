package com.suzhou.bank.agent.model.vo;

import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

import java.io.Serializable;
import java.util.List;


@Data
@Tag(name = "指标参数传输对象", description = "IndexParamsVO")
public class IndexParamsVO implements Serializable {
    private static final long serialVersionUID = 1L;

    private String paramNo;


    private String paramID;


    private String paramName;


    private String paramType;


    private String dataMethod;


    private String codeMethod;


    private String codeNo;


    private String required;


    private String readOnly;


    private String defaultFormat;


    private String fromParamNo;


    private String inputMethod;


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


    private String sortNo;


    private String actureColumn;

    private String columnLength;

    private String columnType;

    private String columnRemark;

    private String columnIsNull;

    private String columnComment;

    private String columnFromTable;

    private String columnFromDataSource;

    private List<IndexParamsVO> childList;

    private String isIntroduced;

    private String datasourceId;

    private String ScriptType;

    private String Script;
}
