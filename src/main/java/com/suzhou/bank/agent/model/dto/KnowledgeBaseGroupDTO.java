package com.suzhou.bank.agent.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Data
public class KnowledgeBaseGroupDTO {

    private List<KnowledgeBaseGroupDTO> children;

    private KnowledgeBaseGroupDTO parent;

    private String groupId;

    private String groupName;

    private String parentGroupId;

    private String parentGroupName;

    private String sortNo;

    private String groupStatus;

    private String inputTime;

    private String updateTime;

    private String groupValue;

    private String groupType;

    private String isKnowledgeRelated = "N";
}
