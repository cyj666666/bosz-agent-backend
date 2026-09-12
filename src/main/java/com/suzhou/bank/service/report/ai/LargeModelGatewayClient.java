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
 * <p>从 {@code large_model_config} 按 {@code lm_code} 取地址与密钥，POST chat completions，
 * 取 {@code choices[0].message.content}。全文分析在后台线程里跑，因此这里用阻塞式调用即可。</p>
 *
 * <p>关于 {@code with_think / default_think_flag}：各网关开启「深度思考」的字段名并不统一
 * （enable_thinking / thinking / enable_search …），因此本类**只取 model_config 里的额外参数原样并入请求体**，
 * 需要开启思考就在该大模型配置行的 {@code model_config} 里写对应 JSON，例如
 * {@code {"enable_thinking": true}}。这样换网关不用改代码。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LargeModelGatewayClient {

    /** 这些键由代码统一装配，不允许被 model_config 覆盖 */
    private static final String[] RESERVED_KEYS = {"model", "messages", "stream"};

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
        String url = config.getUrl();
        if (!StringUtils.hasText(url)) {
            throw new ReportGenerateException("大模型配置未填写地址（lmCode=" + config.getLmCode() + "）");
        }

        JSONObject body = new JSONObject();
        body.put("model", config.getModel());
        JSONArray messages = new JSONArray();
        messages.add(message("system", systemPrompt));
        messages.add(message("user", userPrompt));
        body.put("messages", messages);
        body.put("stream", false);
        if (config.getMaxTokens() != null && config.getMaxTokens() > 0) {
            body.put("max_tokens", config.getMaxTokens());
        }
        mergeExtraParams(body, config.getModelConfig());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(Arrays.asList(MediaType.APPLICATION_JSON, MediaType.ALL));
        if (StringUtils.hasText(config.getApiKey())) {
            headers.set(HttpHeaders.AUTHORIZATION, "Bearer " + config.getApiKey());
        }

        long start = System.currentTimeMillis();
        String responseText;
        try {
            responseText = buildRestTemplate().postForObject(
                    url, new HttpEntity<>(body.toJSONString(), headers), String.class);
        } catch (RestClientResponseException e) {
            // 网关返回 4xx/5xx：带上响应体片段，便于在 failReason 里看清原因
            throw new ReportGenerateException("大模型调用失败：HTTP " + e.getRawStatusCode()
                    + " " + truncate(e.getResponseBodyAsString(), 400));
        } catch (Exception e) {
            throw new ReportGenerateException("大模型调用异常：" + e.getMessage());
        }
        long cost = System.currentTimeMillis() - start;

        String content = extractContent(responseText);
        if (!StringUtils.hasText(content)) {
            throw new ReportGenerateException("大模型返回内容为空：" + truncate(responseText, 300));
        }
        log.info("大模型调用成功：lmCode={} model={} 耗时={}ms 返回长度={}",
                config.getLmCode(), config.getModel(), cost, content.length());

        LlmResult result = new LlmResult();
        result.setContent(content.trim());
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
                    + "），请先在 large_model_config 中维护");
        }
        if (StringUtils.hasText(config.getUseFlag()) && !"Y".equalsIgnoreCase(config.getUseFlag())) {
            throw new ReportGenerateException("大模型配置已停用（lm_code=" + lmCode + "）");
        }
        return config;
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

    /** 把 model_config 里的额外参数并入请求体（已保留键不覆盖） */
    private void mergeExtraParams(JSONObject body, String modelConfig) {
        if (!StringUtils.hasText(modelConfig)) {
            return;
        }
        try {
            JSONObject extra = JSON.parseObject(modelConfig);
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
            log.warn("大模型配置的 model_config 不是合法 JSON，已忽略：{}", truncate(modelConfig, 120));
        }
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
