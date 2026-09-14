package com.suzhou.bank.agent.model.dto;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;


@Data
@Tag(name = "KnowledgeBaseVersionDTO对象", description = "知识库版本记录表请求对象")
public class KnowledgeBaseVersionDTO {

    @Schema(description = "主键ID")
	private String id;

    @Schema(description = "知识库ID")
    private String paramId;

    @Schema(description = "版本编号")
	private String versionNo;

    @Schema(description = "版本名称")
	private String versionName;

    @Schema(description = "prompt配置")
	private String prompt;

    @Schema(description = "输出要求")
    private String contentDesc;

    @Schema(description = "大模型编码")
	private String largeModelCode;

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

    @Schema(description = "是否走云端查询大模型渲染后的结果，默认N（ N否，Y是 ）")
    private String isCloudSearch;

    @Schema(description = "是否markdown格式输出 Y 是 N 否")
    private String isMarkdown;

    @Schema(description = "是否走客户端查询，默认Y（ N否，Y是 ）")
    private String isClientSearch;

    @Schema(description = "是否走云端查询，默认N（ N否，Y是 ）")
    private String isOnlineSearch;

    @Schema(description = "知识库拆分参数")
    private String splitterParam;

    @Schema(description = "用户提示词")
    private String userPrompt;

    @Schema(description = "知识库拆分策略参数")
    private String splitStrategyParam;

    @Schema(description = "业务经验知识")
    private String businessExperience;
}
