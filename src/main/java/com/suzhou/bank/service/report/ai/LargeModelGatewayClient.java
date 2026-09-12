package com.suzhou.bank.service.report.ai;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.suzhou.bank.entity.LargeModelConfig;
import com.suzhou.bank.mapper.LargeModelConfigMapper;
import com.suzhou.bank.service.report.ReportGenerateException;
import com.suzhou.bank.service.report.config.ReportAiAnalysisProperties;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.http.converter.StringHttpMessageConverter;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;

/**
 * 大模型网关客户端（OpenAI 兼容协议，非流式）
 *
 * <p><b>本工程自定义 {@code large_model_config} 的字段语义</b>（不沿用其它工程的口径）。
 * 代码按 {@code report.ai-analysis.lm-code} 指定的 {@code lm_code} 取一行。与调用相关的列：</p>
 * <ul>
 *   <li>{@code url} —— <b>完整的 chat completions 地址</b>（如
 *       {@code http://host:1035/v1/chat/completions}），代码原样请求、不做拼接</li>
 *   <li>{@code api_key} —— <b>明文</b> key，作为 {@code Authorization: Bearer}；留空则不带该头</li>
 *   <li>{@code model} —— 请求体里的 {@code model}</li>
 *   <li>{@code default_think_flag} —— {@code Y} 开启深度思考；默认关闭
 *       （另见 {@link #applyThinkingParams}）</li>
 *   <li>{@code max_tokens} —— {@code > 0} 才传，否则交给网关默认值</li>
 *   <li>{@code model_config} —— 可选，<b>额外请求参数</b>（JSON 对象），原样并入请求体，
 *       用于 temperature / top_p 等微调</li>
 *   <li>{@code use_flag} —— {@code Y} 可用；非 Y 直接报「大模型配置已停用」</li>
 *   <li>{@code lm_name} / {@code lm_desc} / {@code with_think} / {@code create_time} /
 *       {@code update_time} —— <b>不参与调用逻辑</b>（{@code with_think} 保留列但不用）</li>
 * </ul>
 *
 * <p>调用实现按本工程场景定：后台非流式一次性调用，{@link RestTemplate} 同步请求即可，
 * 超时见 {@code report.ai-analysis.timeout-millis}。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LargeModelGatewayClient {

    /** 由代码统一装配，不允许被 model_config 覆盖 */
    private static final String[] RESERVED_KEYS = {"model", "messages", "stream"};

    /** 思考块标记：模型可能把思考过程混在正文里，需要剥掉 */
    private static final String THINK_OPEN = "<think";

    private final LargeModelConfigMapper configMapper;
    private final ReportAiAnalysisProperties properties;

    /**
     * 调用大模型
     *
     * @param systemPrompt 系统提示词
     * @param userPrompt   用户提示词（素材）
     * @return 模型返回内容与元信息
     */
    public LlmResult chat(String systemPrompt, String userPrompt) {
        LargeModelConfig config = loadConfig();
        String url = config.getUrl().trim();

        JSONObject body = new JSONObject();
        if (StringUtils.hasText(config.getModel())) {
            body.put("model", config.getModel());
        }
        JSONArray messages = new JSONArray();
        messages.add(message("system", systemPrompt));
        messages.add(message("user", userPrompt));
        body.put("messages", messages);
        body.put("stream", false);
        if (config.getMaxTokens() != null && config.getMaxTokens() > 0) {
            body.put("max_tokens", config.getMaxTokens());
        }
        applyThinkingParams(body, config);
        mergeExtraParams(body, config.getModelConfig());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(Arrays.asList(MediaType.APPLICATION_JSON, MediaType.ALL));
        if (StringUtils.hasText(config.getApiKey())) {
            headers.set(HttpHeaders.AUTHORIZATION, "Bearer " + config.getApiKey().trim());
        }

        long start = System.currentTimeMillis();
        String responseText;
        try {
            responseText = buildRestTemplate().postForObject(
                    url, new HttpEntity<>(body.toJSONString(), headers), String.class);
        } catch (RestClientResponseException e) {
            throw new ReportGenerateException("大模型调用失败：HTTP " + e.getRawStatusCode()
                    + urlHint(e.getRawStatusCode()) + " " + truncate(e.getResponseBodyAsString(), 400));
        } catch (Exception e) {
            throw new ReportGenerateException("大模型调用异常：" + e.getMessage());
        }
        long cost = System.currentTimeMillis() - start;

        String content = cleanContent(extractContent(responseText));
        if (!StringUtils.hasText(content)) {
            throw new ReportGenerateException("大模型返回内容为空：" + truncate(responseText, 300));
        }
        log.info("大模型调用成功：lmCode={} model={} url={} 耗时={}ms 返回长度={}",
                config.getLmCode(), config.getModel(), url, cost, content.length());

        LlmResult result = new LlmResult();
        result.setContent(content);
        result.setModelName(StringUtils.hasText(config.getModel()) ? config.getModel() : config.getLmCode());
        result.setLmCode(config.getLmCode());
        result.setCostMillis(cost);
        return result;
    }

    /** 取启用中的大模型配置 */
    private LargeModelConfig loadConfig() {
        String lmCode = properties.getLmCode();
        if (!StringUtils.hasText(lmCode)) {
            throw new ReportGenerateException("未配置 report.ai-analysis.lm-code");
        }
        LargeModelConfig config = configMapper.selectOne(
                Wrappers.<LargeModelConfig>lambdaQuery()
                        .eq(LargeModelConfig::getLmCode, lmCode)
                        .last("LIMIT 1"));
        if (config == null) {
            throw new ReportGenerateException("未找到大模型配置（lm_code=" + lmCode
                    + "），请先在 large_model_config 中插入该行");
        }
        if (StringUtils.hasText(config.getUseFlag()) && !"Y".equalsIgnoreCase(config.getUseFlag())) {
            throw new ReportGenerateException("大模型配置已停用（lm_code=" + lmCode + "）");
        }
        if (!StringUtils.hasText(config.getUrl())) {
            throw new ReportGenerateException("大模型配置未填写 url（lm_code=" + lmCode + "）");
        }
        return config;
    }

    /**
     * 思考参数：由 {@code default_think_flag} 决定，字段放请求体顶层。
     * <p>为什么两个字段都要传：Qwen3 这类模型靠 {@code chat_template_kwargs.enable_thinking}
     * 控制思考开关，只传顶层 {@code enable_thinking} 在部分推理后端上不生效 ——
     * 关不掉思考就会把思考过程混进正文（{@link #cleanContent} 是兜底，不是替代）。</p>
     */
    private void applyThinkingParams(JSONObject body, LargeModelConfig config) {
        boolean enableThink = "Y".equalsIgnoreCase(config.getDefaultThinkFlag());
        body.put("enable_thinking", enableThink);

        JSONObject kwargs = new JSONObject();
        kwargs.put("enable_thinking", enableThink);
        kwargs.put("thinking", enableThink);
        body.put("chat_template_kwargs", kwargs);
    }

    /** 把 model_config 里的额外参数并入请求体（代码装配的键不覆盖） */
    private void mergeExtraParams(JSONObject body, String modelConfig) {
        if (!StringUtils.hasText(modelConfig)) {
            return;
        }
        try {
            JSONObject extra = JSON.parseObject(modelConfig.trim());
            if (extra == null) {
                return;
            }
            for (String key : extra.keySet()) {
                if (Arrays.asList(RESERVED_KEYS).contains(key)) {
                    continue;
                }
                body.put(key, extra.get(key));
            }
        } catch (Exception e) {
            log.warn("大模型配置的 model_config 不是合法 JSON 对象，已忽略：{}", truncate(modelConfig, 120));
        }
    }

    private RestTemplate buildRestTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10000);
        factory.setReadTimeout(properties.getTimeoutMillis());
        RestTemplate restTemplate = new RestTemplate(factory);
        // 显式用 UTF-8 解析响应，避免中文在部分网关下乱码
        restTemplate.getMessageConverters().add(0, new StringHttpMessageConverter(StandardCharsets.UTF_8));
        return restTemplate;
    }

    private static JSONObject message(String role, String content) {
        JSONObject message = new JSONObject();
        message.put("role", role);
        message.put("content", content);
        return message;
    }

    /** 404 基本都是 url 没写全，给一句明确提示，省一轮排查 */
    private static String urlHint(int status) {
        return status == 404
                ? "（请确认 large_model_config.url 是完整的 chat completions 地址，"
                + "例如 http://host:1035/v1/chat/completions）"
                : "";
    }

    /** 兼容 OpenAI 标准响应，取 choices[0].message.content */
    private String extractContent(String responseText) {
        if (!StringUtils.hasText(responseText)) {
            return null;
        }
        JSONObject json;
        try {
            json = JSON.parseObject(responseText);
        } catch (Exception e) {
            throw new ReportGenerateException("大模型返回不是合法 JSON：" + truncate(responseText, 300));
        }
        if (json == null) {
            return null;
        }
        JSONArray choices = json.getJSONArray("choices");
        if (choices == null || choices.isEmpty()) {
            return null;
        }
        JSONObject message = choices.getJSONObject(0).getJSONObject("message");
        if (message == null) {
            return null;
        }
        Object content = message.get("content");
        if (content instanceof JSONArray) {
            // 少数网关把 content 返回成 [{type,text}, ...]
            StringBuilder sb = new StringBuilder();
            for (Object part : (JSONArray) content) {
                if (part instanceof JSONObject) {
                    String text = ((JSONObject) part).getString("text");
                    if (StringUtils.hasText(text)) {
                        sb.append(text);
                    }
                } else if (part != null) {
                    sb.append(part);
                }
            }
            return sb.toString();
        }
        return content == null ? null : String.valueOf(content);
    }

    /**
     * 清洗模型输出，保证拿到的是能直接塞进详情页的 HTML 片段：
     * ① 去掉思考块（模型自带 {@code <think>…</think>}，否则会原样渲染到报告里）；
     * ② 去掉可能被包上的 ``` 代码围栏（提示词已要求只输出 HTML，但模型常不听话）。
     */
    private String cleanContent(String content) {
        if (!StringUtils.hasText(content)) {
            return content;
        }
        String text = content.trim();
        if (text.contains(THINK_OPEN)) {
            text = text.replaceAll("(?s)<think[^>]*>.*?</think[^>]*>", "").trim();
        }
        if (text.startsWith("```")) {
            text = text.replaceFirst("^```[a-zA-Z]*\\s*", "");
            int lastFence = text.lastIndexOf("```");
            if (lastFence >= 0) {
                text = text.substring(0, lastFence);
            }
            text = text.trim();
        }
        return text;
    }

    private static String truncate(String value, int max) {
        if (value == null) {
            return "";
        }
        return value.length() <= max ? value : value.substring(0, max) + "…";
    }

    /** 调用结果 */
    @Data
    public static class LlmResult {
        /** 模型返回的正文（按提示词要求是 HTML 片段） */
        private String content;
        private String modelName;
        private String lmCode;
        private Long costMillis;
    }
}
