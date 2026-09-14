package com.suzhou.bank.agent.model.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;


import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;
import lombok.experimental.Accessors;

@Getter
@Setter
@EqualsAndHashCode
public class ModuleCodePromptCacheDto {

	@ExcelProperty("知识库编码")
	private String moduleCode;

	@ExcelProperty("知识库名称")
	private String moduleName;

	@ExcelProperty("请求参数")
	private String params;

	@ExcelProperty("文案内容")
	private String prompt;
}
