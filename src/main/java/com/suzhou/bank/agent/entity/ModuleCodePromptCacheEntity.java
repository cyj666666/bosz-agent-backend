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
 * @Description: 知识库文案缓存表
 * @Author: jeecg-boot
 * @Date:   2025-08-01
 * @Version: V1.0
 */
@Data
@TableName("module_code_prompt_cache")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="module_code_prompt_cache对象", description="知识库文案缓存表")
public class ModuleCodePromptCacheEntity {

	/**知识库编码*/
    @Schema(description = "知识库编码")
	private String moduleCode;
	/**知识库名称*/
    @Schema(description = "知识库名称")
	private String moduleName;
	/**请求参数md5*/
    @Schema(description = "请求参数")
	private String params;
	/**请求参数md5*/
    @Schema(description = "请求参数md5")
	private String paramsMd5;
	/**文案内容*/
    @Schema(description = "文案内容")
	private String prompt;
	/**缓存状态 Y有效 N无效*/
    @Schema(description = "缓存状态 Y有效 N无效")
	private String status;
	/**创建时间*/
    @Schema(description = "创建时间")
	private java.util.Date createTime;
	/**更新时间*/
    @Schema(description = "更新时间")
	private java.util.Date updateTime;
}
