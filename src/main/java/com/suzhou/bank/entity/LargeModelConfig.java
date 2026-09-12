package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 大模型配置表（large_model_config）
 * <p>平台级配置：各业务模块按 {@code lm_code} 取用大模型网关的地址与密钥。</p>
 * <p><b>注意：本表是 snake_case 列名</b>（lm_code / api_key / use_flag …），
 * MP 全局开了 {@code map-underscore-to-camel-case} 会自动映射，实体字段
 * <b>不需要</b>也不能加 {@code @TableField} —— 这一点与 app_report_* 的 camelCase 约定相反，别混。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Data
@TableName("large_model_config")
public class LargeModelConfig {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 大模型唯一CODE */
    private String lmCode;

    /** 模型（如 qwen-max / deepseek-chat） */
    private String model;

    /** 大模型名称 */
    private String lmName;

    /** 大模型地址URL（chat completions 完整地址） */
    private String url;

    /** api key */
    private String apiKey;

    /** 大模型描述 */
    private String lmDesc;

    /** 有效标志位：Y-有效 N-停用 */
    private String useFlag;

    /** 是否带思考 */
    private String withThink;

    /** 默认是否开启思考：Y-开启 N-不开启 */
    private String defaultThinkFlag;

    /** 最大 token 数（<=0 表示不传，交给网关默认值） */
    private Integer maxTokens;

    private Date createTime;

    private Date updateTime;

    /** 模型配置（额外参数 JSON，原样并入请求体） */
    private String modelConfig;
}
