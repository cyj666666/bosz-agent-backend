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
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.http.converter.StringHttpMessageConverter;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestTemplate;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

/**
 * 大模型网关客户端（OpenAI 兼容协议，<b>流式</b>）
 *
 * <h3>🔴 为什么一律走流式（2026-09-18 改）</h3>
 * <p>本平台接的是 reasoning 模型（返回体里带 {@code reasoning_content}），
 * <b>思考 token 与正文 token 共用同一个 {@code max_tokens} 额度</b>。非流式时若思考把额度吃满，
 * 返回的 {@code message.content} 是空串 —— 而且 {@code code=200}、{@code usage} 正常，
 * <b>不报错</b>，调用方只能靠"内容为空"猜出问题。</p>
 *
 * <p>流式则边生成边吐，<b>已产出的正文不会因总量截断而整段丢失</b>，这是"保险"的来源。
 * 报告正文的另外两个入口（知识库块 / 智策引擎块）同样走流式 + 服务端拼接，
 * 见 {@code CollectingSseEmitter}。</p>
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

    /**
     * 未配置 {@code max_tokens} 时的兜底输出上限
     *
     * <p>取 32000 而不是 10000：本平台的模型是 reasoning 模型，
     * 思考 token 与正文 token 共用这个额度，额度太小会出现「思考吃满 → 正文空串」。</p>
     */
    private static final int DEFAULT_MAX_TOKENS = 32000;

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
        // 🔴 一律流式：非流式在 reasoning 模型上会"思考吃满额度 → 正文空串且不报错"（见类注释）
        body.put("stream", true);
        body.put("max_tokens", resolveMaxTokens(config));
        applyThinkingParams(body, config);
        mergeExtraParams(body, config.getModelConfig());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(Arrays.asList(MediaType.TEXT_EVENT_STREAM, MediaType.APPLICATION_JSON, MediaType.ALL));
        if (StringUtils.hasText(config.getApiKey())) {
            headers.set(HttpHeaders.AUTHORIZATION, "Bearer " + config.getApiKey().trim());
        }

        long start = System.currentTimeMillis();
        String streamed;
        try {
            streamed = buildRestTemplate().execute(
                    url,
                    HttpMethod.POST,
                    request -> {
                        request.getHeaders().putAll(headers);
                        StreamUtils.copy(body.toJSONString().getBytes(StandardCharsets.UTF_8), request.getBody());
                    },
                    response -> readSseContent(response.getBody()));
        } catch (RestClientResponseException e) {
            throw new ReportGenerateException("大模型调用失败：HTTP " + e.getRawStatusCode()
                    + urlHint(e.getRawStatusCode()) + " " + truncate(e.getResponseBodyAsString(), 400));
        } catch (Exception e) {
            throw new ReportGenerateException("大模型调用异常：" + e.getMessage());
        }
        long cost = System.currentTimeMillis() - start;

        String content = cleanContent(streamed);
        if (!StringUtils.hasText(content)) {
            throw new ReportGenerateException("大模型流式返回内容为空（lm_code=" + config.getLmCode() + "）");
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
     * 思考开关参数：由 {@code default_think_flag} 决定
     *
     * <p>三个都发，让不同后端各取所需（不认的字段会被忽略）：</p>
     * <ul>
     *   <li>{@code thinking: {"type": "disabled"}} —— <b>深寻系模型真正认的就是这个</b>。
     *       2026-09-18 实测（{@code model=deepseek-flash}）：只发 {@code enable_thinking}
     *       或 {@code chat_template_kwargs} 时思考照旧（completion 181 token、思考占 234 字），
     *       发这个之后 reasoning 归零、completion 降到 38 token；</li>
     *   <li>{@code enable_thinking} —— vLLM 部署的后端认这个；</li>
     *   <li>{@code chat_template_kwargs} —— Qwen3 这类靠模板参数控制的后端认这个。</li>
     * </ul>
     *
     * <p>🔴 关不掉思考的后果不只是慢：思考 token 与正文 token <b>共用 max_tokens</b>，
     * 额度被吃满时正文会变成空串（且不报错）。{@link #cleanContent} 只是兜底，不能替代关开关。</p>
     */
    private void applyThinkingParams(JSONObject body, LargeModelConfig config) {
        boolean enableThink = "Y".equalsIgnoreCase(config.getDefaultThinkFlag());
        body.put("enable_thinking", enableThink);

        JSONObject thinking = new JSONObject();
        thinking.put("type", enableThink ? "enabled" : "disabled");
        body.put("thinking", thinking);

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

    /**
     * 读 SSE 流并拼接正文
     *
     * <p>只认 {@code data:} 行、跳过 {@code [DONE]}；正文取
     * {@code choices[0].delta.content}，部分网关在流式下仍回 {@code message.content}，两种都兼容。
     * 非 JSON 的杂行（心跳等）直接跳过，不中断拼接。</p>
     */
    private String readSseContent(InputStream in) throws IOException {
        StringBuilder sb = new StringBuilder();
        if (in == null) {
            return sb.toString();
        }
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (!line.startsWith("data:")) {
                    continue;
                }
                String payload = line.substring("data:".length()).trim();
                if (!StringUtils.hasText(payload) || "[DONE]".equals(payload)) {
                    continue;
                }
                JSONObject chunk;
                try {
                    chunk = JSON.parseObject(payload);
                } catch (Exception ignore) {
                    continue;
                }
                String piece = extractDeltaContent(chunk);
                if (StringUtils.hasText(piece)) {
                    sb.append(piece);
                }
            }
        }
        return sb.toString();
    }

    /** 从单个流式分片里取文本（{@code delta.content} 优先，回落 {@code message.content}） */
    private String extractDeltaContent(JSONObject chunk) {
        JSONArray choices = chunk.getJSONArray("choices");
        if (choices == null || choices.isEmpty()) {
            return null;
        }
        JSONObject choice = choices.getJSONObject(0);
        if (choice == null) {
            return null;
        }
        JSONObject delta = choice.getJSONObject("delta");
        if (delta != null) {
            String piece = flattenContent(delta.get("content"));
            if (StringUtils.hasText(piece)) {
                return piece;
            }
        }
        JSONObject message = choice.getJSONObject("message");
        return message == null ? null : flattenContent(message.get("content"));
    }

    /** content 兼容 {@code String} 与 {@code [{type,text}, ...]} 两种形态（少数网关是后者） */
    private String flattenContent(Object content) {
        if (content == null) {
            return null;
        }
        if (content instanceof JSONArray) {
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
        return String.valueOf(content);
    }

    /**
     * 输出上限：{@code large_model_config.max_tokens} 填了有效值就用它，否则兜底
     * {@value #DEFAULT_MAX_TOKENS}
     *
     * <p>🔴 不能不吃这个值：reasoning 模型的思考 token 与正文 token 共用该额度，
     * 额度不够时正文会被挤成空串（不报错）。</p>
     */
    private int resolveMaxTokens(LargeModelConfig config) {
        Integer fromConfig = config.getMaxTokens();
        return (fromConfig != null && fromConfig > 0) ? fromConfig : DEFAULT_MAX_TOKENS;
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
