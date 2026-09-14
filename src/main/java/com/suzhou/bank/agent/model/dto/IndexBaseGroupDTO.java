package com.suzhou.bank.agent.model.dto;

import lombok.Data;

import java.util.List;

@Data
public class IndexBaseGroupDTO {

    private List<IndexBaseGroupDTO> children;

    private IndexBaseGroupDTO parent;

    private String groupId;

    private String groupName;

    private String parentGroupId;

    private String parentGroupName;

    private String sortNo;

    private String groupStatus;

    private String inputTime;

    private String updateTime;

    private String groupValue;
}
