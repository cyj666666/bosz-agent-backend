package com.suzhou.bank.agent.entity;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;


import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import com.suzhou.bank.agent.model.common.BaseTree;

/**
 * @Description: 指标分组表
 * @Author: jeecg-boot
 * @Date: 2024-09-13
 * @Version: V1.0
 */
@Data
@TableName("index_base_group")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="index_base_group对象", description = "指标分组表")
public class IndexBaseGroupEntity extends BaseTree<IndexBaseGroupEntity> {

    @Schema(description = "知识库分组Id")
    @TableId(value = "groupId")
    private String groupId;

    @Schema(description = "知识库分组名称")
    @TableField(value = "groupName")
    private String groupName;

    @Schema(description = "父知识库分组Id")
    @TableField(value = "parentGroupId")
    private String parentGroupId;

    @Schema(description = "父知识库分组名称")
    @TableField(value = "parentGroupName")
    private String parentGroupName;

    @Schema(description = "排序")
    @TableField(value = "sortNo")
    private String sortNo;

    @Schema(description = "知识库分组状态 0无效 1有效")
    @TableField(value = "groupStatus")
    private String groupStatus;

    @Schema(description = "登记日期")
    @TableField(value = "inputTime")
    private String inputTime;

    @Schema(description = "更新日期")
    @TableField(value = "updateTime")
    private String updateTime;

    @Schema(description = "知识库分组编码")
    @TableField(value = "groupValue")
    private String groupValue;
}
