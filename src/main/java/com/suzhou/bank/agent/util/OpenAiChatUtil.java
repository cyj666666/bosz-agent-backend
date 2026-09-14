package com.suzhou.bank.agent.util;

import cn.hutool.core.date.DateUtil;
import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpUtil;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.parser.Feature;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.config.AgentSpringContext;
import com.suzhou.bank.agent.entity.CallLlmRecordEntity;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.springframework.http.MediaType;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 大模型流式/非流式调用工具（OpenAI 兼容协议）
 *
 * <p><b>来源与改造</b>：源实现（amar-agent-server 的 {@code OpenAiChatUtil}，407 行）基于
 * <b>Spring AI</b>（{@code org.springframework.ai.openai.api.OpenAiApi}）+ Reactor Netty + WebClient。
 * <b>Spring AI 1.1.1 是 Spring Boot 3 专用组件，无法降级到本工程的 Boot 2.7 / JDK 8</b>，
 * 因此这里用 hutool 直连 OpenAI 兼容接口重新实现，<b>保留原有的方法签名与对外契约</b>，
 * 使 {@code CallLlmUtil#callLlm} 零改写。</p>
 *
 * <p><b>保持不变的对外契约（前端依赖，勿改）</b>：</p>
 * <ul>
 *   <li>流式：每块推一条 SSE —— 普通场景 {@code {code:200, content:...}}；
 *       知识库问答场景 {@code {code:200, answer:...}}；带 usage 时附 prompt_tokens/completion_tokens</li>
 *   <li>非流式：返回 {@code {code:200, content, large_model_code, prompt_tokens, completion_tokens}}
 *       （知识库问答附 {@code answer}/{@code prompt}；智策引擎场景附 {@code ruleResult}/{@code ruleData}）</li>
 *   <li>{@code enableThink} 时，思考内容用 {@code <think>...</think>} 包裹后一并输出</li>
 * </ul>
 *
 * <p><b>与源实现的差异（仅实现方式，对外行为一致）</b>：</p>
 * <ol>
 *   <li>HTTP 客户端：Spring AI / WebClient / Reactor Netty → hutool 同步流式读取；</li>
 *   <li>超时：源实现 30 分钟，这里通过 hutool 的 {@code timeout(READ_TIMEOUT_MILLIS)} 保持同等量级；</li>
 *   <li>错误处理：源实现走 Reactor 的 error 回调，这里改为 try-catch + 落调用流水记录。</li>
 * </ol>
 */
@Slf4j
public class OpenAiChatUtil {

    /** 大模型调用读超时（毫秒）。长文本生成可能持续数分钟，源实现为 30 分钟，此处保持一致 */
    private static final int READ_TIMEOUT_MILLIS = 30 * 60 * 1000;

    private static final String THINK_OPEN = "<think>";
    private static final String THINK_CLOSE = "</think>";

    /**
     * 调用大模型（OpenAI 兼容 /chat/completions）
     *
     * @param stream              是否流式
     * @param requestBody         请求参数（含 baseUrl / apiKey / model / prompt / systemContent / temperature 等）
     * @param emitter             SSE 发射器
     * @param finishFlag          结束后是否 complete 掉 emitter
     * @param returnFlag          是否"构造结构化事件逐块推送"（false 表示透传原始 chunk）
     * @param callLlmRecordEntity 调用记录实体（用于落调用流水）
     * @param traceId             链路 id
     * @param enableThink         是否输出思考过程
     * @return 流式返回 emitter；非流式且 returnFlag=true 时返回结果 JSON
     */
    public static Object handleOpenAiStreamContent(
            boolean stream, JSONObject requestBody,
            SseEmitter emitter, boolean finishFlag,
            boolean returnFlag,
            CallLlmRecordEntity callLlmRecordEntity,
            String traceId,
            boolean enableThink
    ) {
        CallLlmUtil callLlmUtil = AgentSpringContext.getBean(CallLlmUtil.class);
        Boolean knowledgeQuery = requestBody.getBoolean("knowledgeQuery");
        String prompt = requestBody.getString("prompt");
        String model = requestBody.getString("model");
        String apiKey = requestBody.getString("apiKey");
        String url = buildCompletionsUrl(requestBody.getString("baseUrl"));

        // 构造 OpenAI 兼容请求体
        JSONObject body = new JSONObject();
        body.put("model", model);
        JSONArray messages = new JSONArray();
        messages.add(buildMessage("system", StringUtils.isEmpty(requestBody.getString("systemContent"))
                ? "You are a helpful assistant" : requestBody.getString("systemContent")));
        messages.add(buildMessage("user", prompt));
        body.put("messages", messages);
        body.put("stream", stream);
        if (requestBody.get("temperature") != null) {
            body.put("temperature", requestBody.getDoubleValue("temperature"));
        }
        if (requestBody.get("topP") != null) {
            body.put("top_p", requestBody.getDoubleValue("topP"));
        }
        if (requestBody.get("maxTokens") != null) {
            body.put("max_tokens", requestBody.getIntValue("maxTokens"));
        }
        if (StringUtils.isNotEmpty(traceId)) {
            body.put("user", traceId);
        }
        // extraBody 展开（enable_thinking / chat_template_kwargs 等厂商私有参数）
        JSONObject extraBody = requestBody.getJSONObject("extraBody");
        if (extraBody != null && !extraBody.isEmpty()) {
            for (String key : extraBody.keySet()) {
                body.put(key, extraBody.get(key));
            }
        }

        long startTime = System.currentTimeMillis();
        try {
            if (stream) {
                log.info("流式调用开始! traceId[{}], model[{}]", traceId, model);
                try (cn.hutool.http.HttpResponse response = buildRequest(url, apiKey, body).execute()) {
                    if (response.getStatus() != 200) {
                        String errMsg = "大模型流式调用失败，状态码：" + response.getStatus();
                        log.error("{}, traceId[{}]", errMsg, traceId);
                        callLlmUtil.saveCallLlmRecord(callLlmRecordEntity, callLlmRecordEntity.getRequestTime(),
                                DateUtil.now(), errMsg, "", 0, 0, 500, 0);
                        finishEmitter(emitter, finishFlag);
                        return emitter;
                    }
                    consumeStream(response.bodyStream(), emitter, returnFlag, knowledgeQuery, enableThink,
                            callLlmUtil, callLlmRecordEntity, traceId);
                }
                log.info("流式调用结束, 耗时[{}]ms, traceId[{}]", System.currentTimeMillis() - startTime, traceId);
                finishEmitter(emitter, finishFlag);
                return emitter;
            } else {
                log.info("非流式调用开始! traceId[{}], model[{}]", traceId, model);
                return doNonStream(url, apiKey, body, emitter, finishFlag, returnFlag, knowledgeQuery,
                        prompt, requestBody, callLlmUtil, callLlmRecordEntity, traceId, enableThink);
            }
        } catch (Exception e) {
            log.error("调用大模型失败, traceId[{}]，错误信息:{}", traceId, ExceptionUtils.getStackTrace(e));
            callLlmUtil.saveCallLlmRecord(callLlmRecordEntity, callLlmRecordEntity.getRequestTime(),
                    DateUtil.now(), ExceptionUtils.getStackTrace(e), "", 0, 0, 500, 0);
            finishEmitter(emitter, finishFlag);
            return AgentResult.error("调用大模型失败！");
        }
    }

    /** 非流式调用（完整保留源实现的返回结构） */
    private static Object doNonStream(String url, String apiKey, JSONObject body, SseEmitter emitter,
                                      boolean finishFlag, boolean returnFlag, Boolean knowledgeQuery,
                                      String prompt, JSONObject requestBody,
                                      CallLlmUtil callLlmUtil, CallLlmRecordEntity callLlmRecordEntity,
                                      String traceId, boolean enableThink) {
        long startTime = System.currentTimeMillis();
        try {
            String responseStr = buildRequest(url, apiKey, body).execute().body();
            JSONObject response = JSON.parseObject(responseStr, Feature.OrderedField);
            JSONObject result = new JSONObject();
            Object content = "";
            int promptTokens = 0;
            int completionTokens = 0;
            if (response != null && response.getJSONArray("choices") != null && !response.getJSONArray("choices").isEmpty()) {
                JSONObject message = response.getJSONArray("choices").getJSONObject(0).getJSONObject("message");
                if (message != null) {
                    String rawContent = message.getString("content");
                    String reasoningContent = message.getString("reasoning_content");
                    if (enableThink) {
                        content = rawContent;
                        if (StringUtils.isNotEmpty(reasoningContent)) {
                            content = THINK_OPEN + "\n" + reasoningContent + "\n" + THINK_CLOSE + "\n" + content;
                        }
                    } else {
                        content = removeThinkTagContent(rawContent);
                    }
                }
            }
            if (response != null && response.getJSONObject("usage") != null) {
                promptTokens = response.getJSONObject("usage").getIntValue("prompt_tokens");
                completionTokens = response.getJSONObject("usage").getIntValue("completion_tokens");
            }
            if (Boolean.TRUE.equals(knowledgeQuery)) {
                result.put("answer", content);
                result.put("content", prompt);
            } else {
                result.put("content", content);
            }
            result.put("code", 200);
            result.put("large_model_code", requestBody.get("large_model_code"));
            result.put("prompt_tokens", promptTokens);
            result.put("completion_tokens", completionTokens);
            if ("IntelligentStrategyEngine".equals(JSONTools.getString(requestBody, "moduleCode"))) {
                result.put("ruleResult", JSONTools.getValue(requestBody, "ruleResult"));
                result.put("ruleData", JSONTools.getValue(requestBody, "ruleData"));
            }
            if (!returnFlag && emitter != null) {
                emitter.send(result, MediaType.APPLICATION_JSON);
            }
            callLlmUtil.saveCallLlmRecord(callLlmRecordEntity, callLlmRecordEntity.getRequestTime(), DateUtil.now(),
                    JSONObject.toJSONString(result), "", promptTokens, completionTokens, 200, 0);
            return returnFlag ? result : emitter;
        } catch (Exception e) {
            log.error("非流式调用出错, traceId[{}]，错误信息:{}", traceId, ExceptionUtils.getStackTrace(e));
            callLlmUtil.saveCallLlmRecord(callLlmRecordEntity, callLlmRecordEntity.getRequestTime(), DateUtil.now(),
                    ExceptionUtils.getStackTrace(e), "", 0, 0, 500, 0);
            return AgentResult.error("非流式调用出错!" + ExceptionUtils.getStackTrace(e));
        } finally {
            log.info("非流式调用结束, 耗时[{}]ms, traceId[{}]", System.currentTimeMillis() - startTime, traceId);
            finishEmitter(emitter, finishFlag);
        }
    }

    /**
     * 消费 SSE 流并逐块推给客户端
     *
     * <p>保留源实现的「思考内容状态机」语义：把 {@code reasoning_content} 与 {@code content}
     * 按 {@code <think>} 标签的开关状态整理后输出，使前端能区分"思考过程"与"正式回答"。</p>
     */
    private static void consumeStream(InputStream in, SseEmitter emitter, boolean returnFlag, Boolean knowledgeQuery,
                                      boolean enableThink, CallLlmUtil callLlmUtil,
                                      CallLlmRecordEntity callLlmRecordEntity, String traceId) {
        AtomicInteger orderCounter = new AtomicInteger(0);
        AtomicBoolean withThink = new AtomicBoolean(false);
        AtomicBoolean nativeThink = new AtomicBoolean(false);
        AtomicBoolean contentStart = new AtomicBoolean(false);
        AtomicBoolean eventStart = new AtomicBoolean(true);
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isEmpty() || !line.startsWith("data:")) {
                    continue;
                }
                String data = line.substring(5).trim();
                if ("[DONE]".equals(data)) {
                    break;
                }
                JSONObject chunk = JSON.parseObject(data, Feature.OrderedField);
                if (chunk == null) {
                    continue;
                }
                JSONArray choices = chunk.getJSONArray("choices");
                if (choices == null || choices.isEmpty()) {
                    continue;
                }
                JSONObject delta = choices.getJSONObject(0).getJSONObject("delta");
                if (delta == null) {
                    continue;
                }
                String content = delta.getString("content") == null ? "" : delta.getString("content");
                String reasoningContent = delta.getString("reasoning_content");

                // ===== 思考内容状态机（照搬源实现逻辑） =====
                if (StringUtils.isNotEmpty(content)) {
                    if (content.contains(THINK_OPEN)) {
                        nativeThink.set(true);
                        reasoningContent = content.replace(THINK_OPEN, "");
                        content = "";
                    } else if (content.contains(THINK_CLOSE)) {
                        List<String> parts = Arrays.asList(
                                content.substring(0, content.indexOf(THINK_CLOSE)),
                                content.substring(content.indexOf(THINK_CLOSE) + THINK_CLOSE.length()));
                        if (!nativeThink.get()) {
                            nativeThink.set(true);
                            reasoningContent = "";
                            content = parts.get(0);
                        } else {
                            nativeThink.set(false);
                            reasoningContent = parts.get(0);
                            content = StringUtils.isEmpty(parts.get(1)) ? "\n" : parts.get(1);
                        }
                    } else if (nativeThink.get()) {
                        reasoningContent = content;
                        content = "";
                    } else {
                        reasoningContent = "";
                    }
                }
                if (StringUtils.isEmpty(content) && StringUtils.isEmpty(reasoningContent)) {
                    continue;
                }
                if (enableThink && StringUtils.isNotEmpty(reasoningContent)) {
                    content = reasoningContent;
                    if (eventStart.get()) {
                        content = THINK_OPEN + "\n" + content;
                        withThink.set(true);
                    }
                } else if (StringUtils.isNotEmpty(content) && !contentStart.get()) {
                    contentStart.set(true);
                    if (withThink.get()) {
                        content = "\n" + THINK_CLOSE + "\n" + content;
                    }
                }
                if (StringUtils.isEmpty(content)) {
                    continue;
                }

                JSONObject eventJson = new JSONObject();
                if (Boolean.TRUE.equals(knowledgeQuery)) {
                    eventJson.put("answer", content);
                } else {
                    eventJson.put("content", content);
                }
                eventJson.put("code", 200);
                JSONObject usage = chunk.getJSONObject("usage");
                if (usage != null) {
                    eventJson.put("prompt_tokens", usage.getIntValue("prompt_tokens"));
                    eventJson.put("completion_tokens", usage.getIntValue("completion_tokens"));
                }
                if (returnFlag) {
                    emitter.send(eventJson, MediaType.APPLICATION_JSON);
                } else {
                    // returnFlag=false：源实现直接透传原始块，这里保持同样语义
                    emitter.send(chunk, MediaType.APPLICATION_JSON);
                }
                eventStart.set(false);
                callLlmUtil.saveCallLlmRecord(callLlmRecordEntity, callLlmRecordEntity.getRequestTime(), DateUtil.now(),
                        eventJson.toJSONString(), "",
                        eventJson.getInteger("prompt_tokens"), eventJson.getInteger("completion_tokens"),
                        200, orderCounter.getAndIncrement());
            }
        } catch (Exception e) {
            log.error("流式读取/推送失败, traceId[{}]，错误信息:{}", traceId, ExceptionUtils.getStackTrace(e));
            callLlmUtil.saveCallLlmRecord(callLlmRecordEntity, callLlmRecordEntity.getRequestTime(), DateUtil.now(),
                    ExceptionUtils.getStackTrace(e), "", 0, 0, 500, orderCounter.getAndIncrement());
        }
    }

    // ==================================================================================
    // 内部辅助
    // ==================================================================================

    private static JSONObject buildMessage(String role, String content) {
        JSONObject message = new JSONObject();
        message.put("role", role);
        message.put("content", content == null ? "" : content);
        return message;
    }

    /** 拼出 /chat/completions 地址（兼容 baseUrl 结尾有无斜杠、以及已带完整路径两种情况） */
    private static String buildCompletionsUrl(String baseUrl) {
        if (StringUtils.isBlank(baseUrl)) {
            return baseUrl;
        }
        String trimmed = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        if (trimmed.endsWith("/chat/completions")) {
            return trimmed;
        }
        return trimmed + "/chat/completions";
    }

    private static HttpRequest buildRequest(String url, String apiKey, JSONObject body) {
        HttpRequest request = HttpUtil.createPost(url)
                .header("Content-Type", "application/json;charset=utf-8")
                .header("Accept", "application/json")
                .body(body.toJSONString(), "UTF-8")
                .timeout(READ_TIMEOUT_MILLIS);
        if (StringUtils.isNotBlank(apiKey)) {
            request.header("Authorization", apiKey.startsWith("Bearer ") ? apiKey : ("Bearer " + apiKey));
        }
        return request;
    }

    /** 去掉 {@code <think>...</think>} 内容（enableThink=false 时用） */
    private static String removeThinkTagContent(String content) {
        if (StringUtils.isEmpty(content)) {
            return content;
        }
        String result = content;
        while (result.contains(THINK_OPEN) && result.contains(THINK_CLOSE)) {
            int start = result.indexOf(THINK_OPEN);
            int end = result.indexOf(THINK_CLOSE, start);
            if (end < 0) {
                break;
            }
            result = result.substring(0, start) + result.substring(end + THINK_CLOSE.length());
        }
        return result.trim();
    }

    private static void finishEmitter(SseEmitter emitter, boolean finishFlag) {
        if (finishFlag && Objects.nonNull(emitter)) {
            try {
                emitter.complete();
            } catch (Exception e) {
                log.warn("关闭 SSE 发射器失败（通常是对端已断开）:{}", e.getMessage());
            }
        }
    }
}
