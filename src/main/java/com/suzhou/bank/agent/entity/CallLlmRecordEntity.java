package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * @Description: 知识库code权限配置信息表
 * @Author: jeecg-boot
 * @Date: 2025-10-28
 * @Version: V1.0
 */
@Data
@TableName("call_llm_record")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "call_llm_record对象", description = "调用大模型记录表")
public class CallLlmRecordEntity {

    /**
     * 账号信息
     */
    private String hubAccount;

    /**
     * 追踪ID
     */
    private String traceId;

    /**
     * 排序编号
     */
    private int sortNo;

    /**
     * 请求时间
     */
    private String requestTime;

    /**
     * 状态
     */
    private Integer status;

    /**
     * 内容
     */
    private String content;

    /**
     * 请求体
     */
    private String requestBody;

    /**
     * 响应时间
     */
    private String responseTime;

    /**
     * 大模型编码
     */
    private String largeModelCode;

    /**
     * API密钥
     */
    private String apiKey;

    /**
     * 提示词令牌数
     */
    private Long promptTokens;

    /**
     * 完成令牌数
     */
    private Long completionTokens;

    /**
     * 会话消息编号
     */
    private String sessionMsgNo;
}
