package com.suzhou.bank.agent.entity;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;


import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * @Description: 指标关联知识库信息表
 * @Author: jeecg-boot
 * @Date: 2025-04-03
 * @Version: V1.0
 */
@Data
@TableName("index_relate_knowledge_info")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="index_relate_knowledge_info对象", description = "指标关联知识库信息表")
public class IndexRelateKnowledgeInfoEntity {

    /**主键id*/
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键id")
    private String id;
    /**指标编号*/
    @Schema(description = "指标编号")
    private String paramNo;
    /**关联知识库编号*/
    @Schema(description = "关联知识库编号")
    private String relateKnowledgeNo;
    /**关联知识库编码*/
    @Schema(description = "关联知识库编码")
    private String relateKnowledgeCode;
    /**关联知识库名称*/
    @Schema(description = "关联知识库名称")
    private String relateKnowledgeName;
    /**关联知识库分组ID*/
    @Schema(description = "关联知识库分组ID")
    private String relateGroupId;
    /**关联知识库项，包含知识配置、溯源配置、图片配置、全部来源配置*/
    @Schema(description = "关联知识库项，包含知识配置、溯源配置、图片配置、全部来源配置")
    private String relateItems;
    /**创建时间*/
    @Schema(description = "创建时间")
    private java.util.Date createTime;
    /**更新时间*/
    @Schema(description = "更新时间")
    private java.util.Date updateTime;
}
