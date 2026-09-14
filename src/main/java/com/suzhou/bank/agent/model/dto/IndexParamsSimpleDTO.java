package com.suzhou.bank.agent.model.dto;


import lombok.Data;

import java.util.List;

/**
 * getParamNo, IndexParamsEntity::getParamName, IndexParamsEntity::getInputMethod,
 * IndexParamsEntity::getScriptType,
 * IndexParamsEntity::getParamType, IndexParamsEntity::getParentParamNo,
 * IndexParamsEntity::getParamName);
 */
@Data
public class IndexParamsSimpleDTO {

    private List<IndexParamsSimpleDTO> children;

    private IndexParamsSimpleDTO parent;

    private String paramNo;

    private String paramName;

    private String paramType;

    private String inputMethod;

    private String parentParamNo;

    private String parentParamName;

    private String ScriptType;


}
