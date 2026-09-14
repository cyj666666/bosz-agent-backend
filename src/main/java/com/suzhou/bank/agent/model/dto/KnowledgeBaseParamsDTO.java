package com.suzhou.bank.agent.model.dto;

import com.alibaba.fastjson.JSONArray;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Data
public class KnowledgeBaseParamsDTO {

    private List<KnowledgeBaseParamsDTO> children;

    private KnowledgeBaseParamsDTO parent;

    @Schema(description = "知识库编码")
    private String paramNo;

    @Schema(description = "知识库ID")
    private String paramId;

    @Schema(description = "知识库名称")
    private String paramName;

    @Schema(description = "知识库类型 GROUP OBJECT")
    private String paramType;

    @Schema(description = "知识库主体类型")
    private String paramEntityType;

    @Schema(description = "知识库标签")
    private JSONArray paramLabel;

    @Schema(description = "所属模板流水号")
    private String modelNo;

    @Schema(description = "父知识库ID")
    private String parentParamId;

    @Schema(description = "父知识库名称")
    private String parentParamName;

    @Schema(description = "知识库分组ID")
    private String groupId;

    @Schema(description = "排序")
    private String sortNo;

    @Schema(description = "prompt配置")
    private String prompt;

    @Schema(description = "溯源配置")
    private String traceConfig;

    @Schema(description = "关联agent")
    private String agentId;

    @Schema(description = "其他配置")
    private String otherConfig;

    @Schema(description = "知识库状态 0无效 1有效")
    private String paramStatus;

    @Schema(description = "登记人")
    private String inputUserId;

    @Schema(description = "登记日期")
    private String inputTime;

    @Schema(description = "更新用户")
    private String updateUserId;

    @Schema(description = "更新日期")
    private String updateTime;

    private String online;

    private String promptType;

    private String contentDesc;

    private String businessExperience;

    @Schema(description = "输入参数")
    private JSONArray inputParam;

    @Schema(description = "大模型编码")
    private String largeModelCode;

    @Schema(description = "不同大模型对应的输出要求")
    private String largeModelContent;

    @Schema(description = "图片配置")
    private String imageConfig;

    @Schema(description = "全部来源配置")
    private String wholeSourceConfig;

    @Schema(description = "关联指标集合")
    private String relateIndexSet;

    @Schema(description = "黑盒模型编码")
    private String blackModelCode;

    @Schema(description = "黑盒输出要求")
    private String blackContentDesc;

    @Schema(description = "是否markdown格式输出 Y 是 N 否")
    private String isMarkdown;

    @Schema(description = "知识库详细信息描述")
    private String paramDescription;

    @Schema(description = "输入要求条件")
    private String inputCondition;

    @Schema(description = "是否走客户端查询，默认Y（ N否，Y是 ）")
    private String isClientSearch;

    @Schema(description = "输出指标配置")
    private String inputIndex;

    @Schema(description = "大模型属性参数")
    private String largeModelParam;

    @Schema(description = "是否置顶")
    private String isTop;

    @Schema(description = "知识库拆分参数")
    private String splitterParam;

    @Schema(description = "知识库是否有权限")
    private boolean hasAuth;

    @Schema(description = "是否走云端查询大模型渲染后的结果，默认N（ N否，Y是 ）")
    private String isCloudSearch;

    @Schema(description = "用户提示词")
    private String userPrompt;

    @Schema(description = "知识库拆分策略参数")
    private String splitStrategyParam;
}
