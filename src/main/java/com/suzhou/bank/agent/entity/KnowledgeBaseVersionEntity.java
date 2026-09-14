package com.suzhou.bank.agent.entity;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;


import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import com.fasterxml.jackson.annotation.JsonFormat;
import org.springframework.format.annotation.DateTimeFormat;

/**
 * @Description: 知识库版本记录表
 * @Author: jeecg-boot
 * @Date:   2025-11-06
 * @Version: V1.0
 */
@Data
@TableName("knowledge_base_version")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="knowledge_base_version对象", description="知识库版本记录表")
public class KnowledgeBaseVersionEntity {
    
	/**主键ID*/
	@TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键ID")
	private String id;
    /**知识库ID*/
    @Schema(description = "知识库ID")
    private String paramId;
	/**版本编号*/
    @Schema(description = "版本编号")
	private String versionNo;
	/**版本名称*/
    @Schema(description = "版本名称")
	private String versionName;
	/**版本创建时间*/
	@JsonFormat(timezone = "GMT+8",pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern="yyyy-MM-dd HH:mm:ss")
    @Schema(description = "版本创建时间")
	private java.util.Date createTime;
	/**更新时间*/
	@JsonFormat(timezone = "GMT+8",pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern="yyyy-MM-dd HH:mm:ss")
    @Schema(description = "更新时间")
	private java.util.Date updateTime;
	/**创建人ID*/
    @Schema(description = "创建人ID")
	private String createUserId;
	/**创建人名字*/
    @Schema(description = "创建人名字")
	private String createUserName;
	/**排序号*/
    @Schema(description = "排序号")
	private String sortNo;
    /**最新发布标志 1最新 0历史*/
    @Schema(description = "最新发布标志")
	private String latestFlag;
	/**prompt配置*/
    @Schema(description = "prompt配置")
	private String prompt;
    /**输出要求*/
    @Schema(description = "输出要求")
    private String contentDesc;
	/**大模型编码*/
    @Schema(description = "大模型编码")
	private String largeModelCode;
	/**溯源配置*/
    @Schema(description = "溯源配置")
	private String traceConfig;
	/**不同大模型对应的输出要求*/
    @Schema(description = "不同大模型对应的输出要求")
	private String largeModelContent;
	/**图片配置*/
    @Schema(description = "图片配置")
	private String imageConfig;
	/**全部来源配置*/
    @Schema(description = "全部来源配置")
	private String wholeSourceConfig;
	/**知识库关联指标集合*/
    @Schema(description = "知识库关联指标集合")
	private String relateIndexSet;
	/**黑盒输出要求*/
    @Schema(description = "黑盒输出要求")
	private String blackContentDesc;
	/**黑盒大模型编码*/
    @Schema(description = "黑盒大模型编码")
	private String blackModelCode;
	/**其他输出要求*/
    @Schema(description = "其他输出要求")
	private String inputCondition;
	/**输出指标配置*/
    @Schema(description = "输出指标配置")
	private String inputIndex;
	/**大模型属性参数，包括：systemContent: 文本系统提示词 topP: 浮点数top概率 temperature: 浮点数温度*/
    @Schema(description = "大模型属性参数，包括：systemContent: 文本系统提示词 topP: 浮点数top概率 temperature: 浮点数温度")
	private String largeModelParam;
	/**输出要求是否置顶*/
    @Schema(description = "输出要求是否置顶")
	private String isTop;

    @Schema(description = "是否走云端查询大模型渲染后的结果，默认N（ N否，Y是 ）")
    private String isCloudSearch;

    @Schema(description = "是否markdown格式输出，默认N（ N否，Y是 ）")
    private String isMarkdown;

    @Schema(description = "是否走客户端查询，默认N（ N否，Y是 ）")
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
