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
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicBoolean;

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
 *   <li>HTTP 客户端：Spring AI / WebClient / Reactor Netty →
 *       <b>非流式用 hutool</b>、<b>流式改用裸 {@link HttpURLConnection}</b>。
 *       ⚠️ 原因见 {@link #openStreamConnection}：hutool 的 {@code execute()} 会<b>读完整个响应体才返回</b>，
 *       用它做流式会让 SSE 退化成"假流式"（2026-09-15 实测踩到并修复）；</li>
 *   <li>超时：读超时与源实现同为 30 分钟；建连超时收紧到 30 秒（连不上应快速失败）；</li>
 *   <li>错误处理：源实现走 Reactor 的 error 回调，这里改为 try-catch + 落调用流水记录，
 *       并把非 200 的响应体片段一起写进日志（便于定位 401/403 鉴权问题）；</li>
 *   <li><b>调用流水改为「一次调用一行」</b>：源实现（以及本工程改造前）是"上游每来一帧 → 同步 INSERT 一条
 *       {@code call_llm_record}"，一次调用最多 3539 行，且每行都重复存 {@code trace_id/api_key} 等固定字段。
 *       现改为<b>整段输出累加在内存、结束时只落一行</b>（{@code sort_no=0}，与「非流式调用」的落库形态一致），
 *       见 {@link #consumeStream}。依据与代价见该方法注释。</li>
 * </ol>
 */
@Slf4j
public class OpenAiChatUtil {

    /** 大模型调用读超时（毫秒）。长文本生成可能持续数分钟，源实现为 30 分钟，此处保持一致 */
    private static final int READ_TIMEOUT_MILLIS = 30 * 60 * 1000;

    /**
     * 流式读取的「帧间隔」超时（2026-09-19 新增）
     *
     * <p>流式下 readTimeout 的语义是「<b>两次数据到达之间的最大间隔</b>」，正常帧间隔只有
     * 几毫秒~几秒（实测首帧 596ms、平均帧间隔 3ms）。沿用 30 分钟意味着：
     * 模型服务端一旦「<b>不响应也不断开</b>」，这个块就要挂满 30 分钟才超时。</p>
     *
     * <p>🔴 实测（2026-09-19 21:17）：3 个连接被服务端 reset（快速失败、有日志），
     * 另 2 个块卡在 {@code socketRead0} 一动不动 —— 报告 21:17:06 发起，
     * 到 21:22 仍停在 {@code status=000}。jstack 确认就是这两个线程在 socketRead。</p>
     *
     * <p>所以流式单独用 2 分钟：既远大于正常的帧间隔，又能让"挂死"的连接快速失败。
     * 非流式（{@link #READ_TIMEOUT_MILLIS}）保持 30 分钟不变 —— 那是一次性长文本返回，
     * 长间隔是正常的。</p>
     */
    private static final int STREAM_READ_TIMEOUT_MILLIS = 2 * 60 * 1000;

    /** 建连超时（毫秒）。源实现连接超时也是 30 分钟，这里收紧到 30 秒：连不上就该快点失败 */
    private static final int CONNECT_TIMEOUT_MILLIS = 30 * 1000;

    /**
     * 流式调用的「结果行」使用的 {@code sort_no}
     *
     * <p>本工程 {@code call_llm_record} 的主键是 {@code (trace_id, sort_no)}，所以同一次调用里
     * 不同用途的行必须用不同序号：</p>
     * <ul>
     *   <li>{@code sort_no = -1} —— <b>init 行</b>（{@code CallLlmUtil#syncSaveInitCallLlmRecord} 写入），
     *       带完整 {@code request_body}，标记"这次调用已发起"；</li>
     *   <li>{@code sort_no = 0} —— <b>结果行</b>（本常量），{@code content} 存整段模型输出。
     *       与「非流式调用」（{@code doNonStream}）用的是同一个序号 —— 两种调用方式落库形态就此统一。</li>
     * </ul>
     * <p>⚠️ 结果行**不能**也用 -1：会与 init 行主键冲突。</p>
     */
    private static final int STREAM_RESULT_SORT_NO = 0;

    /**
     * 单条流水 {@code content} 的落库长度上限（字符）
     *
     * <p>流式输出现在是"整段拼起来存一行"，所以要有个防御性上限：正常内容远小于此值
     * （公司库实测单行最大 25,787 字符，即非流式路径的整段输出），
     * 只在异常情况下（上游疯狂重复输出）才会触发，触发时会截断并在日志里打 WARN。</p>
     */
    private static final int MAX_RECORD_CONTENT_CHARS = 128 * 1024;

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
                // 🔴 流式分支**必须**用裸 HttpURLConnection（见 openStreamConnection 的说明）：
                //    换成 hutool 的 `buildRequest(...).execute()` 会让整条链路退化成"假流式"。
                HttpURLConnection conn = openStreamConnection(url, apiKey, body);
                try {
                    int status = conn.getResponseCode();
                    if (status != 200) {
                        String errBody = readErrorBody(conn);
                        String errMsg = "大模型流式调用失败，状态码：" + status
                                + (StringUtils.isEmpty(errBody) ? "" : "，响应：" + errBody);
                        log.error("{}, traceId[{}]", errMsg, traceId);
                        callLlmUtil.saveCallLlmRecord(callLlmRecordEntity, callLlmRecordEntity.getRequestTime(),
                                DateUtil.now(), errMsg, "", 0, 0, 500, 0);
                        finishEmitter(emitter, finishFlag);
                        return emitter;
                    }
                    try (InputStream in = conn.getInputStream()) {
                        consumeStream(in, emitter, returnFlag, knowledgeQuery, enableThink,
                                callLlmUtil, callLlmRecordEntity, traceId);
                    }
                } finally {
                    conn.disconnect();
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
     *
     * <h3>落库形态：一次调用一行（2026-09-15 起）</h3>
     * <p>原实现（含源工程）是<b>上游每来一帧就同步 INSERT 一条</b> {@code call_llm_record}，
     * 一次长文本流式调用可达数千行，且每行都要重复存 {@code trace_id / hub_account / api_key /
     * request_time / large_model_code / session_msg_no} 等固定字段（实测 102~113 字节/行）。</p>
     * <p>现在改为：<b>整段输出累加在内存，结束时（{@code finally}）只落一行</b>
     * （{@code sort_no=0}，与非流式路径 {@code doNonStream} 完全一致）。为什么可以这么做：</p>
     * <ul>
     *   <li>这张表<b>两个工程都只写不读</b>（后端全模块只有 {@code save}，源工程 Mapper XML 是空文件，
     *       两个前端 grep 无命中）——逐片时序从来没有人消费过；</li>
     *   <li>公司库实测（20 天生产数据）：8,696 行 / 1,843 次调用 = <b>4.7 行/次</b>，
     *       但本地一次长文本流式就有 <b>3,539 行</b> —— 膨胀率完全取决于输出长度，没有上界；</li>
     *   <li>「一次一行 + {@code content} 存整段输出」在生产上<b>早已存在</b>：
     *       非流式路径就是这么写的（实测单行 {@code content} 最大 25,787 字符），
     *       本改动只是让流式路径与它对齐。</li>
     * </ul>
     * <p><b>代价（明确记录，便于将来评估）</b>：</p>
     * <ol>
     *   <li>丢掉逐片时序 —— "第几帧开始卡"这类证据只能靠 {@code 流式分片统计} 日志
     *       （上游data行 / 推送帧数 / 首帧耗时 / 平均帧间隔）；</li>
     *   <li>若进程在流式过程中被杀，本次输出不会落库（但"发起过"仍由 init 行 {@code sort_no=-1} 可见）；</li>
     *   <li>若将来真要做"调用回放"，需要重新逐片落库（届时建议按需落：正常调用一行、异常调用才留逐片）。</li>
     * </ol>
     */
    private static void consumeStream(InputStream in, SseEmitter emitter, boolean returnFlag, Boolean knowledgeQuery,
                                      boolean enableThink, CallLlmUtil callLlmUtil,
                                      CallLlmRecordEntity callLlmRecordEntity, String traceId) {
        AtomicBoolean withThink = new AtomicBoolean(false);
        AtomicBoolean nativeThink = new AtomicBoolean(false);
        AtomicBoolean contentStart = new AtomicBoolean(false);
        AtomicBoolean eventStart = new AtomicBoolean(true);

        // 分片统计（可观测性）：用来一眼判断"到底是谁在攒数据"——
        //   首帧耗时 ≈ 整段耗时  → 上游/网关在攒，跟我们没关系；
        //   首帧很快、帧间隔均匀 → 我们这条链路是真流式。
        long streamStartAt = System.currentTimeMillis();
        long firstFrameAt = -1L;
        int upstreamRows = 0;
        int pushedFrames = 0;
        // 整段输出累加：一次调用只落一行（见方法注释）。累加的是"推给前端的那份"（enableThink 时含 <think> 包裹），
        // 这样库里的内容与前端页面所见一致，便于对照排查。
        StringBuilder fullOutput = new StringBuilder();
        // 本次调用最终状态：200 正常结束 / 500 读流或推送异常
        int status = 200;
        // token 用量在流式末尾才带，取最后一次出现的值
        Integer latestPromptTokens = null;
        Integer latestCompletionTokens = null;
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
                upstreamRows++;
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
                    latestPromptTokens = usage.getIntValue("prompt_tokens");
                    latestCompletionTokens = usage.getIntValue("completion_tokens");
                }
                if (returnFlag) {
                    emitter.send(eventJson, MediaType.APPLICATION_JSON);
                } else {
                    // returnFlag=false：源实现直接透传原始块，这里保持同样语义
                    emitter.send(chunk, MediaType.APPLICATION_JSON);
                }
                if (firstFrameAt < 0) {
                    firstFrameAt = System.currentTimeMillis() - streamStartAt;
                }
                pushedFrames++;
                eventStart.set(false);
                // 原实现此处是「每帧同步 INSERT 一条 call_llm_record」——一次调用最多几千行、
                // 几千次 DB 往返夹在逐帧推送之间。现在只累加，结束时落一行。
                fullOutput.append(content);
            }
        } catch (Exception e) {
            status = 500;
            log.error("流式读取/推送失败, traceId[{}]，错误信息:{}", traceId, ExceptionUtils.getStackTrace(e));
            // 已经吐出去的内容要保住（这才知道"断在哪"）；一点都没吐出来时，把错误首行存进去，
            // 免得 status=500 的行是一片空白、还得去翻日志。
            if (fullOutput.length() == 0) {
                fullOutput.append(firstLine(ExceptionUtils.getStackTrace(e)));
            }
        } finally {
            // 🔴 一次调用只落一行（sort_no=0，与非流式路径一致）。
            //    放 finally 是为了"正常结束 / 异常中断"两条路都能落库。
            String output = fullOutput.toString();
            if (output.length() > MAX_RECORD_CONTENT_CHARS) {
                log.warn("流式输出过长已截断落库, traceId[{}], 原长={}, 上限={}",
                        traceId, output.length(), MAX_RECORD_CONTENT_CHARS);
                output = output.substring(0, MAX_RECORD_CONTENT_CHARS) + "...[truncated]";
            }
            callLlmUtil.saveCallLlmRecord(callLlmRecordEntity, callLlmRecordEntity.getRequestTime(), DateUtil.now(),
                    output, "", latestPromptTokens, latestCompletionTokens, status, STREAM_RESULT_SORT_NO);
            // 一条 INFO 就能定性"是上游在攒，还是我们在攒"（排查流式问题先看这行）。
            // ⚠️ 改成「一次调用一行」后 DB 里不再有逐片时序 —— 这行日志就是唯一的"分片级"观测，别删。
            long total = System.currentTimeMillis() - streamStartAt;
            String gap = pushedFrames > 1 && firstFrameAt >= 0
                    ? " 平均帧间隔=" + Math.max(0, (total - firstFrameAt) / (pushedFrames - 1)) + "ms"
                    : "";
            log.info("流式分片统计 traceId[{}]：上游data行={} 推送前端帧={} 落库行=1 输出字符数={} 首帧耗时={}ms 总耗时={}ms{}",
                    traceId, upstreamRows, pushedFrames, output.length(),
                    firstFrameAt < 0 ? -1L : firstFrameAt, total, gap);
        }
    }

    /** 取文本首行（异常摘要），用于"一点输出都没有"时给流水行一个可读的原因 */
    private static String firstLine(String text) {
        if (StringUtils.isEmpty(text)) {
            return "";
        }
        int idx = text.indexOf('\n');
        return idx > 0 ? text.substring(0, idx) : text;
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
                .body(body.toJSONString(), "application/json;charset=utf-8")
                .timeout(READ_TIMEOUT_MILLIS);
        if (StringUtils.isNotBlank(apiKey)) {
            request.header("Authorization", apiKey.startsWith("Bearer ") ? apiKey : ("Bearer " + apiKey));
        }
        return request;
    }

    /**
     * 建一个「真流式」的 HTTP 连接（POST /chat/completions）
     *
     * <h3>🔴 为什么流式分支不能用 hutool 的 {@code HttpRequest}</h3>
     * <p>2026-09-15 实测（本地慢速 SSE 服务端：每 400ms 推一帧，共 6 帧）：
     * hutool 5.8.25 的 {@code HttpRequest.execute()}（即 {@code isAsync=false} 的默认路径）
     * 会<b>把整个响应体读完才返回</b> —— 于是在它之后调用 {@code bodyStream()} 拿到的是一个
     * "已经装满数据"的流，逐块推送退化成"最后一次性推送"。<b>代码本身完全看不出问题，
     * 但 SSE 从这一刻起就是假流式</b>（前端只能靠打字机把一次性到达的文本"演"成流式）。</p>
     *
     * <pre>
     * 同一份服务端、同一份 hutool，三种取流方式实测（帧到达时刻）：
     *   A) execute()                → 拿到响应头 +2644ms；6 帧全挤在 +2644ms      ❌ 假流式
     *   B) executeAsync()           → 响应头 +1ms；帧间隔 +1/404/807/1213/1617/2022 ✅
     *   C) 裸 HttpURLConnection      → 响应头 +2ms；帧间隔 +2/415/829/1230/1643/2045 ✅
     * </pre>
     *
     * <h3>为什么选 C（裸 {@link HttpURLConnection}）而不是 B</h3>
     * <p>B 虽然也流式，但 {@code executeAsync()} 是"把请求丢到另一个线程"，主线程马上拿到
     * {@code HttpResponse}，此时 <b>{@code getStatus()} 可能还是 0</b>（响应头尚未到达）。
     * 而下面的代码要靠状态码判断 200 / 记录失败原因，用 B 会误判。
     * {@code getResponseCode()} 的语义恰好是"阻塞到响应头到达" —— 这才是我们要的。</p>
     *
     * <p><b>对照源实现</b>：源工程用 Spring AI + WebClient（Reactor 背压流），本质也是 C 这种
     * "响应头到达即可开始逐块读"的语义，所以在源工程里流式是真的；本工程迁移成 hutool 后
     * 丢掉了这个语义，属于<b>迁移引入的回归</b>。</p>
     *
     * <p>⚠️ {@code Accept-Encoding: identity} 是刻意加的：不让中间层压缩，
     * 避免多一层解压缓冲（gzip 本身也流式，但 identity 更稳、少一个变量）。</p>
     */
    private static HttpURLConnection openStreamConnection(String url, String apiKey, JSONObject body) throws IOException {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setConnectTimeout(CONNECT_TIMEOUT_MILLIS);
        // 流式用「帧间隔」超时（2 分钟），不是 30 分钟 —— 见 STREAM_READ_TIMEOUT_MILLIS 的注释
        conn.setReadTimeout(STREAM_READ_TIMEOUT_MILLIS);
        conn.setRequestProperty("Content-Type", "application/json;charset=utf-8");
        conn.setRequestProperty("Accept", "text/event-stream");
        conn.setRequestProperty("Accept-Encoding", "identity");
        if (StringUtils.isNotBlank(apiKey)) {
            conn.setRequestProperty("Authorization", apiKey.startsWith("Bearer ") ? apiKey : ("Bearer " + apiKey));
        }
        byte[] payload = body.toJSONString().getBytes(StandardCharsets.UTF_8);
        try (OutputStream os = conn.getOutputStream()) {
            os.write(payload);
            os.flush();
        }
        return conn;
    }

    /** 读错误响应体（最多 500 字符），用于把 401/403 等鉴权错误的原因暴露到日志里 */
    private static String readErrorBody(HttpURLConnection conn) {
        InputStream err = conn.getErrorStream();
        if (err == null) {
            return "";
        }
        try (InputStreamReader reader = new InputStreamReader(err, StandardCharsets.UTF_8)) {
            char[] buf = new char[500];
            int n = reader.read(buf);
            return n > 0 ? new String(buf, 0, n) : "";
        } catch (Exception e) {
            return "";
        }
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
        if (!finishFlag || Objects.isNull(emitter)) {
            return;
        }
        try {
            // 迁移修正点：补发「结束帧」。源实现为
            //     if (finishFlag) { emitter.send("finished!"); }
            //     emitter.complete();
            // 本工程重写本类时漏掉了 send 那一句，只保留 complete。
            // 影响：前端（源工程 admin 与本次重写的 React 前端）都以 `data:finished!`
            // 作为「流正常收尾」的判定依据，缺帧时只能退化为「靠连接关闭兜底」——
            // 功能仍可用，但拿不到明确结束信号，且与 CallLlmUtil.finishEmitter 的行为不一致
            // （那个方法一直是带 finished! 的）。此处按源实现恢复该帧。
            emitter.send("finished!");
            emitter.complete();
        } catch (Exception e) {
            // 注：源实现此处调用 completeWithError，本工程改为仅告警——
            // 走到 catch 基本意味着对端已断开，再 completeWithError 只会在已关闭的
            // emitter 上二次抛错，属于噪音而非有效信号。
            log.warn("发送 SSE 结束帧/关闭发射器失败（通常是对端已断开）:{}", e.getMessage());
        }
    }
}
