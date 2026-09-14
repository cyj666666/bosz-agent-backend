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
 * @Description: 指标关联信息表
 * @Author: jeecg-boot
 * @Date: 2024-11-04
 * @Version: V1.0
 */
@Data
@TableName("index_relate_info")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="index_relate_info对象", description = "指标关联信息表")
public class IndexRelateInfoEntity {

    /**
     * id
     */
    @TableId(type = IdType.AUTO)
    @Schema(description = "id")
    private Integer id;
    /**
     * 指标ID
     */
    @Schema(description = "指标ID")
    private String indexId;
    /**
     * 关联指标ID
     */
    @Schema(description = "关联指标ID")
    private String relateIndexId;
    /**
     * 关联时间
     */
    @Schema(description = "关联时间")
    private String relateTime;
    /**
     * 备注
     */
    @Schema(description = "备注")
    private String comment;
}
