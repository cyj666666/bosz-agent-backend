package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 大模型配置表（large_model_config）
 *
 * <p>各业务模块按 {@code lm_code} 取用大模型网关的地址与密钥。AI 全文分析用的那一行由
 * {@code report.ai-analysis.lm-code} 指定。</p>
 *
 * <p><b>字段语义（本工程口径，见 {@code LargeModelGatewayClient} 的取用实现）</b>：</p>
 * <ul>
 *   <li>{@code url} —— <b>完整的 chat completions 地址</b>（含 {@code /v1/chat/completions}），
 *       代码原样请求、不做拼接</li>
 *   <li>{@code api_key} —— <b>明文</b> key，作为 {@code Authorization: Bearer}；留空则不带该头</li>
 *   <li>{@code model} —— 请求体里的 {@code model}</li>
 *   <li>{@code default_think_flag} —— {@code Y} 开启深度思考（请求体带 {@code enable_thinking}
 *       与 {@code chat_template_kwargs}），默认 {@code N} 关闭</li>
 *   <li>{@code max_tokens} —— {@code > 0} 才传，否则交给网关默认值</li>
 *   <li>{@code model_config} —— 可选，<b>额外请求参数</b>（JSON 对象），原样并入请求体</li>
 *   <li>{@code use_flag} —— {@code Y} 可用；非 Y 报「大模型配置已停用」</li>
 *   <li>{@code lm_name} / {@code lm_desc} / {@code with_think} / {@code create_time} /
 *       {@code update_time} —— 不参与调用逻辑（{@code with_think} 保留列但不用）</li>
 * </ul>
 *
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

    /** 大模型唯一CODE（代码按它取行） */
    private String lmCode;

    /** 模型（请求体里的 model，如 default / qwen3-32b） */
    private String model;

    /** 大模型名称（仅管理界面展示） */
    private String lmName;

    /** 大模型地址URL：完整的 chat completions 地址，代码不做拼接 */
    private String url;

    /** api key：明文，直接作为 Bearer 令牌 */
    private String apiKey;

    /** 大模型描述（备注，不参与逻辑） */
    private String lmDesc;

    /** 有效标志位：Y-有效 N-停用 */
    private String useFlag;

    /** 是否带思考（保留列，代码不使用；是否开思考看 defaultThinkFlag） */
    private String withThink;

    /** 默认是否开启思考：Y-开启 N-不开启（代码据此传 enable_thinking / chat_template_kwargs） */
    private String defaultThinkFlag;

    /** 最大 token 数（<=0 表示不传，交给网关默认值） */
    private Integer maxTokens;

    private Date createTime;

    private Date updateTime;

    /** 模型配置：可选的额外请求参数（JSON 对象），原样并入请求体 */
    private String modelConfig;
}
