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
 * @Description: 指标关联指标信息表
 * @Author: jeecg-boot
 * @Date:   2025-04-03
 * @Version: V1.0
 */
@Data
@TableName("index_relate_index_info")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="index_relate_index_info对象", description="指标关联指标信息表")
public class IndexRelateIndexInfoEntity {
    
	/**主键id*/
	@TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键id")
	private String id;
	/**指标编号*/
    @Schema(description = "指标编号")
	private String paramNo;
	@Schema(description = "关联指标编号")
	private String relateParamNo;
	/**关联指标编码*/
    @Schema(description = "关联指标编码")
	private String relateParamId;
	/**关联指标名称*/
    @Schema(description = "关联指标名称")
	private String relateParamName;
	/**关联指标分组ID*/
	@Schema(description = "关联指标分组ID")
	private String relateGroupId;
	/**创建时间*/
    @Schema(description = "创建时间")
	private java.util.Date createTime;
	/**更新时间*/
    @Schema(description = "更新时间")
	private java.util.Date updateTime;
}
