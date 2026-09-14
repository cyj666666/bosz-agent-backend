package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;


@Data
@TableName("tool_management")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "tool_management对象", description = "大模型工具管理")
public class ToolManagementEntity {

    /**
     * 主键ID
     */
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键ID")
    private String id;
    /**
     * 工具分类
     */
    @Schema(description = "业务分类")
    private String toolCategory;

    @TableField(exist = false)
    @Schema(description = "业务分类描述")
    private String toolCategoryDesc;
    /**
     * 工具名称
     */
    @Schema(description = "工具名称")
    private String toolName;
    /**
     * 工具描述
     */
    @Schema(description = "工具描述")
    private String toolDescription;
    /**
     * 工具参数
     */
    @Schema(description = "工具参数")
    private String toolParameters;
    /**
     * 工具状态：N-否，Y-是
     */
    @Schema(description = "工具状态：N-停用，Y-正常")
    private String toolStatus;
    /**
     * 创建时间
     */
    @Schema(description = "创建时间")
    private String createTime;
    /**
     * 更新时间
     */
    @Schema(description = "更新时间")
    private String updateTime;

    @Schema(description = "关联工具编码")
    private String moduleCode;

    @Schema(description = "实现分类 get_knowledge-知识库 apply_prompt-应用提示词 custom-用户自定义")
    private String implType;

    @Schema(description = "工具中文展示名")
    private String cnLabel;

    @Schema(description = "工具英文展示名")
    private String enLabel;
}
