package com.suzhou.bank.agent.model.req;

import com.alibaba.fastjson.JSONObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;

import java.util.List;

@Data
@Tag(name = "KnowledgeBasePromptViewReq对象", description = "分组下知识库prompt配置预览请求")
public class KnowledgeBasePromptViewReq {

    @Schema(description = "企业名称")
    private String entName;

    @Schema(description = "知识库ID")
    private String paramId;

    @Schema(description = "主体类型 ")
    private String mainType;

    @Schema(description = "大模型选择")
    private String largeModelCode;

    @Schema(description = "输出要求")
    private String contentDesc;

    @Schema(description = "输入参数")
    private List<JSONObject> inputParam;

    @Schema(description = "关联ID")
    private String traceId;

    @Schema(description = "文案")
    private String prompt;

    @Schema(description = "预览文案")
    private String previewPrompt;

    @Schema(description = "是否忽略知识库状态")
    private boolean ignoreStatus;

    @Schema(description = "是否鉴权")
    private boolean authFlag;

    @Schema(description = "是否预览")
    private boolean previewFlag;

    @Schema(description = "溯源配置")
    private String traceConfig;

    @Schema(description = "不同大模型对应的输出要求")
    private String largeModelContent;

    @Schema(description = "图片配置")
    private String imageConfig;

    @Schema(description = "全部来源配置")
    private String wholeSourceConfig;

    @Schema(description = "知识库关联指标集合")
    private String relateIndexSet;

    @Schema(description = "黑盒输出要求")
    private String blackContentDesc;

    @Schema(description = "黑盒大模型编码")
    private String blackModelCode;

    @Schema(description = "其他输出要求")
    private String inputCondition;

    @Schema(description = "输出指标配置")
    private String inputIndex;

    @Schema(description = "大模型属性参数，包括：systemContent: 文本系统提示词 topP: 浮点数top概率 temperature: 浮点数温度")
    private String largeModelParam;

    @Schema(description = "输出要求是否置顶")
    private String isTop;

    @Schema(description = "用户提示词")
    private String userPrompt;

    @Schema(description = "分段策略参数")
    private String splitStrategyParam;

    @Schema(description = "业务经验")
    private String businessExperience;
}
