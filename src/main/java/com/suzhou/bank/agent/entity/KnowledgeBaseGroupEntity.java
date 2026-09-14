package com.suzhou.bank.agent.entity;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import lombok.Data;
import com.suzhou.bank.agent.model.common.BaseTree;

@Data
@TableName(value = "knowledge_base_group")
public class KnowledgeBaseGroupEntity extends BaseTree<KnowledgeBaseGroupEntity> {

    @TableId(value = "groupId")
    private String groupId;

    @TableField("groupName")
    private String groupName;

    @TableField("parentGroupId")
    private String parentGroupId;

    @TableField("parentGroupName")
    private String parentGroupName;

    @TableField("sortNo")
    private String sortNo;

    @TableField("groupStatus")
    private String groupStatus;

    @TableField("inputTime")
    private String inputTime;

    @TableField("updateTime")
    private String updateTime;

    @TableField("groupValue")
    private String groupValue;

    @TableField("groupType")
    private String groupType;

    @TableField(exist = false)
    @Schema(description = "是否是当前Space的关联的知识库")
    private String isKnowledgeRelated = "N";

    @TableField(exist = false)
    @Schema(description = "输入参数")
    private String inputParam;
}
