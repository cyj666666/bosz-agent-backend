package com.suzhou.bank.agent.model.req;

import cn.hutool.json.JSONArray;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

import java.util.List;


@Data
@Tag(name = "参数信息列表对象", description = "KnowledgeBaseParamsInfoSaveReq")
public class KnowledgeBaseParamsInfoSaveReq {

    @Schema(description = "知识库ID")
    private String paramId;

    @Schema(description = "知识库流水号")
    private String paramNo;

    @Schema(description = "知识库名称")
    private String paramName;

    @Schema(description = "知识库类型 GROUP OBJECT")
    private String paramType;

    @Schema(description = "知识库分组ID")
    private String groupId;

    @Schema(description = "知识库主体类型")
    private String paramEntityType;

    @Schema(description = "知识库标签")
    private List<String> paramLabel;

    @Schema(description = "父知识库ID")
    private String parentParamId;

    @Schema(description = "父知识库名称")
    private String parentParamName;

    @Schema(description = "prompt配置")
    private String prompt;

    @Schema(description = "溯源配置")
    private String traceConfig;

    @Schema(description = "图片配置")
    private String imageConfig;

    @Schema(description = "全部来源配置")
    private String wholeSourceConfig;

    @Schema(description = "关联标志，用于判断是否更新")
    private String relateFlag;

    @Schema(description = "关联指标集合")
    private String relateIndexSet;

    @Schema(description = "关联agent")
    private String agentId;

    @Schema(description = "知识库状态 0无效 1有效")
    private String paramStatus;

    @Schema(description = "是否上线")
    private String online;

    @Schema(description = "prompt类型")
    private String promptType;

    @Schema(description = "知识库详细信息描述")
    private String contentDesc;

    @Schema(description = "业务经验知识")
    private String businessExperience;

    @Schema(description = "输入参数")
    private JSONArray inputParam;

    @Schema(description = "大模型编码")
    private String largeModelCode;

    @Schema(description = "复制知识库ID")
    private String selectKnowledgeId;

    @Schema(description = "是否markdown格式输出 Y 是 N 否")
    private String isMarkdown;

    @Schema(description = "知识库详细信息描述")
    private String paramDescription;

    @Schema(description = "输入要求条件")
    private String inputCondition;

    @Schema(description = "是否走客户端查询，默认Y（ N否，Y是 ）")
    private String isClientSearch;

    @Schema(description = "是否走云端查询大模型渲染后的结果，默认N（ N否，Y是 ）")
    private String isCloudSearch;

    @Schema(description = "输出指标配置")
    private String inputIndex;

    @Schema(description = "大模型属性参数")
    private String largeModelParam;

    @Schema(description = "是否置顶")
    private String isTop;

    @Schema(description = "知识库拆分参数")
    private String splitterParam;

    @Schema(description = "用户提示词")
    private String userPrompt;

    @Schema(description = "知识库拆分策略参数")
    private String splitStrategyParam;
}
