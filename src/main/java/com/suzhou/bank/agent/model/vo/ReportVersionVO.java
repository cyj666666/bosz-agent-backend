package com.suzhou.bank.agent.model.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

import java.util.List;

@Data
public class ReportVersionVO {

    private String reportVersion;

    private String versionNo;

    private String paramName;

    private String sortNo;

    private String operation;

    private List childrenList;

    private String modelNo;

    private String key;
}
