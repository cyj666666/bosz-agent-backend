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
 * @Description: 知识库管理指标信息
 * @Author: jeecg-boot
 * @Date:   2025-09-26
 * @Version: V1.0
 */
@Data
@TableName("knowledge_relate_index")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="knowledge_relate_index对象", description="知识库管理指标信息")
public class KnowledgeRelateIndexEntity {
    
	/**主键ID*/
	@TableId(type = IdType.AUTO)
    @Schema(description = "主键ID")
	private Integer id;
    /**知识库ID*/
    @Schema(description = "知识库ID")
	private String knowledgeId;
	/**指标编号*/
    @Schema(description = "指标编号")
	private String indexNo;
	/**指标名称*/
    @Schema(description = "指标名称")
	private String indexName;
    /**父级指标编号*/
    @Schema(description = "父级指标编号")
    private String parentIndexNo;
	/**指标类型*/
    @Schema(description = "指标类型")
	private String indexType;
	/**关联接口服务ID*/
    @Schema(description = "关联接口服务ID")
	private String supplierId;
	/**关联接口编号*/
    @Schema(description = "关联接口编号")
	private String intfNo;
	/**是否溯源 Y：是，N：否*/
    @Schema(description = "是否溯源 Y：是，N：否")
	private String traceStatus;
	/**是否溯源卡片 Y：是，N：否*/
    @Schema(description = "是否溯源卡片 Y：是，N：否")
	private String traceCardStatus;
	/**溯源配置*/
    @Schema(description = "溯源配置")
	private String traceConfig;
    /**添加类型add-新增，bland-知识库绑定*/
    @Schema(description = "添加类型 add-新增，bland-知识库绑定")
	private String addType;
	/**创建时间*/
	@JsonFormat(timezone = "GMT+8",pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern="yyyy-MM-dd HH:mm:ss")
    @Schema(description = "创建时间")
	private java.util.Date inputTime;
	/**更新时间*/
	@JsonFormat(timezone = "GMT+8",pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern="yyyy-MM-dd HH:mm:ss")
    @Schema(description = "更新时间")
	private java.util.Date updateTime;
}
