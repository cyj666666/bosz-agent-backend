package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * @Description: 大模型信息配置表
 * @Author: jeecg-boot
 * @Date: 2024-11-05
 * @Version: V1.0
 */
@Data
@TableName("large_model_config")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "large_model_config对象", description = "大模型信息配置表")
public class LargeModelConfigEntity {

    /**
     * 大模型唯一ID
     */
    @TableId(type = IdType.AUTO)
    @Schema(description = "大模型唯一ID")
    private Integer id;
    /**
     * 大模型唯一CODE
     */
    @Schema(description = "大模型唯一CODE")
    private String lmCode;
    /**
     * 模型
     */
    @Schema(description = "模型")
    private String model;
    /**
     * 大模型名称
     */
    @Schema(description = "大模型名称")
    private String lmName;
    /**
     * 大模型地址URL
     */
    @Schema(description = "大模型地址URL")
    private String url;
    /**
     * api key
     */
    @Schema(description = "api key")
    private String apiKey;
    /**
     * 大模型描述
     */
    @Schema(description = "大模型描述")
    private Object lmDesc;
    /**
     * 有效标志位
     */
    @Schema(description = "有效标志位")
    private String useFlag;
    /**
     * 是否有思考
     */
    @Schema(description = "是否有思考")
    private String withThink;
    /**
     * 默认是否开启思考, Y:开启,N:不开启
     */
    @Schema(description = "默认是否开启思考, Y:开启,N:不开启")
    private String defaultThinkFlag;
    @Schema(description = "最大tokens")
    private Integer maxTokens;
    /**
     * 创建时间
     */
    @Schema(description = "创建时间")
    private String createTime;
    /**
     * 更新时间
     */
    @Schema(description = "更新时间")
    private String updateTime;

    @Schema(description = "模型配置")
    private String modelConfig;
}
