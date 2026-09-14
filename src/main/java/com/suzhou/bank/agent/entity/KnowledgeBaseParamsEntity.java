package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import com.suzhou.bank.agent.model.common.BaseTree;

@Data
@TableName("knowledge_base_params")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "knowledge_base_params对象", description = "test")
public class KnowledgeBaseParamsEntity extends BaseTree<KnowledgeBaseParamsEntity> {

    /**
     * 知识库流水号
     */
    @Schema(description = "知识库流水号")
    @TableField("paramNo")
    private String paramNo;
    /**
     * 知识库ID
     */
    @Schema(description = "知识库ID")
    @TableId("paramId")
    private String paramId;
    /**
     * 知识库名称
     */
    @Schema(description = "知识库名称")
    @TableField("paramName")
    private String paramName;
    /**
     * 知识库类型
     */
    @Schema(description = "知识库类型 GROUP OBJECT")
    @TableField("paramType")
    private String paramType;
    /**
     * 知识库主体类型
     */
    @Schema(description = "知识库主体类型")
    @TableField("paramEntityType")
    private String paramEntityType;
    /**
     * 知识库标签
     */
    @Schema(description = "知识库标签")
    @TableField("paramLabel")
    private String paramLabel;
    /**
     * 所属模板流水号
     */
    @Schema(description = "所属模板流水号")
    @TableField("modelNo")
    private String modelNo;
    /**
     * 父知识库ID
     */
    @Schema(description = "父知识库ID")
    @TableField("parentParamId")
    private String parentParamId;
    /**
     * 父知识库名称
     */
    @Schema(description = "父知识库名称")
    @TableField("parentParamName")
    private String parentParamName;
    /**
     * 知识库所属版本
     */
    @Schema(description = "知识库分组ID")
    @TableField("groupId")
    private String groupId;
    /**
     * 排序
     */
    @Schema(description = "排序")
    @TableField("sortNo")
    private String sortNo;
    /**
     * prompt配置
     */
    @Schema(description = "prompt配置")
    @TableField("prompt")
    private String prompt;
    /**
     * 溯源配置
     */
    @Schema(description = "溯源配置")
    private String traceConfig;

    @Schema(description = "图片配置")
    private String imageConfig;

    @Schema(description = "全部来源配置")
    private String wholeSourceConfig;

    @Schema(description = "关联指标集合")
    private String relateIndexSet;

    /**
     * 关联agent
     */
    @Schema(description = "关联agent")
    @TableField("agentId")
    private String agentId;
    /**
     * 其他配置
     */
    @Schema(description = "其他配置")
    @TableField("otherConfig")
    private String otherConfig;
    /**
     * 知识库状态 0无效 1有效
     */
    @Schema(description = "知识库状态 0无效 1有效")
    @TableField("paramStatus")
    private String paramStatus;
    /**
     * 是否markdown格式输出 Y 是 N 否
     */
    @Schema(description = "是否markdown格式输出 Y 是 N 否")
    private String isMarkdown;

    @Schema(description = "是否走客户端查询，默认Y（ N否，Y是 ）")
    private String isClientSearch;

    @Schema(description = "是否走云端查询大模型渲染后的结果，默认N（ N否，Y是 ）")
    private String isCloudSearch;

    /**
     * 登记人
     */
    @Schema(description = "登记人")
    @TableField("inputUserId")
    private String inputUserId;
    /**
     * 登记日期
     */
    @Schema(description = "登记日期")
    @TableField("inputTime")
    private String inputTime;
    /**
     * 更新用户
     */
    @Schema(description = "更新用户")
    @TableField("updateUserId")
    private String updateUserId;
    /**
     * 更新日期
     */
    @Schema(description = "更新日期")
    @TableField("updateTime")
    private String updateTime;


    /**
     * 是否上线 0 否 1 是
     */
    @TableField("\"online\"")
    private String online;

    /**
     * prompt类型：basic 或 content
     */
    @TableField("promptType")
    private String promptType;

    /**
     * 当prompt类型为content，需填此值
     */
    @TableField("contentDesc")
    private String contentDesc;

    @Schema(description = "输入参数")
    private String inputParam;

    @Schema(description = "大模型编码")
    private String largeModelCode;

    @Schema(description = "不同大模型对应的输出要求")
    private String largeModelContent;

    @Schema(description = "黑盒模型编码")
    private String blackModelCode;

    @Schema(description = "黑盒输出要求")
    private String blackContentDesc;

    @Schema(description = "知识库详细信息描述")
    private String paramDescription;

    @Schema(description = "输入要求条件")
    private String inputCondition;

    @Schema(description = "输出指标配置")
    private String inputIndex;

    @Schema(description = "大模型属性参数")
    private String largeModelParam;

    @Schema(description = "是否置顶")
    private String isTop;

    @Schema(description = "知识库拆分参数")
    private String splitterParam;

    @Schema(description = "工具参数配置")
    private String toolParametersConfig;

    @Schema(description = "用户提示词")
    private String userPrompt;

    @Schema(description = "知识库拆分策略参数")
    private String splitStrategyParam;

    @TableField(exist = false)
    private String moduleCode;

    @TableField(exist = false)
    private String groupType;

    @TableField(exist = false)
    private String groupValue;

    @TableField(exist = false)
    private String toolId;

    @TableField(exist = false)
    private String openApiId;

    @TableField(exist = false)
    private String toolParameters;

    @TableField(exist = false)
    private String versionNo;

    @TableField("business_experience")
    private String businessExperience;

}
