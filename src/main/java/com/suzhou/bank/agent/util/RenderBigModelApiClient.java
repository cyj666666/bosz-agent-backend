package com.suzhou.bank.agent.util;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.parser.Feature;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.tuple.Pair;
import com.suzhou.bank.agent.util.JSONTools;
import com.suzhou.bank.agent.entity.ExtIntfParamDefineEntity;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import reactor.core.Disposable;
import reactor.core.publisher.Flux;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

/**
 * 大模型渲染云服务客户端
 */
@Repository
@Slf4j
public class RenderBigModelApiClient {

    @Value("${hubservice.api.url:}")
    private String hubApiUrl;

    @Value("${hubservice.api.account:}")
    private String hubApiAccount;

    private static final int MAX_POLL_COUNT = 1000;
    private static final long POLL_INTERVAL_MS = 100;
    private static final String SUCCESS_CODE = "0000";
    private static final String STREAM_MODE_N = "N";
    private static final String IS_FINISH_N = "N";
    private static final String STREAM_MODE_KEY = "stream";
    private static final String DATA_KEY = "data";
    private static final String CODE_KEY = "code";
    private static final String MSG_KEY = "msg";
    private static final String PROMPT_KEY = "prompt";
    private static final String KEY_KEY = "key";
    private static final String CONTENT_KEY = "content";
    private static final String ANSWER_KEY = "answer";
    private static final String IS_FINISH_KEY = "isFinish";

    public Object handleCallRM1201(JSONObject params, JSONObject promptObject, SseEmitter emitter) {
        if (Objects.isNull(emitter)) {
            log.error("SseEmitter cannot be null");
            return promptObject;
        }

        // 先从缓存中获取hubApiUrl
        Pair<String, String> hubApiInfo = getHubApiInfo();
        params.put("hubApiUrl", StringUtils.isEmpty(hubApiInfo.getLeft()) ? hubApiUrl : hubApiInfo.getLeft());
        params.put("hubApiAccount", StringUtils.isEmpty(hubApiInfo.getRight()) ? hubApiAccount : hubApiInfo.getRight());

        // 非流模式，直接处理
        String streamMode = params.getString(STREAM_MODE_KEY);
        if (STREAM_MODE_N.equals(streamMode)) {
            return handleNonStreamMode(params, promptObject, emitter);
        }

        // 流式模式，使用 Flux 处理
        return handleStreamMode(params, emitter);
    }

    private Object handleNonStreamMode(JSONObject params, JSONObject promptObject, SseEmitter emitter) {
        try {
            JSONObject rm1201AgentResult = callRM1201(params);

            if (isSuccessResponse(rm1201AgentResult)) {
                sendErrorAndComplete(emitter, "接口调用失败", rm1201AgentResult);
                return promptObject;
            }

            String prompt = extractPromptFromResult(rm1201AgentResult);
            if (StringUtils.isEmpty(prompt)) {
                sendErrorAndComplete(emitter, "接口返回数据格式错误", null);
                return promptObject;
            }

            boolean knowledgeQuery = ParamUtil.getBoolValue(params, "knowledgeQuery", true);
            if (knowledgeQuery) {
                promptObject.put(CONTENT_KEY, params.getString("prompt"));
                promptObject.put(ANSWER_KEY, prompt);
            } else {
                promptObject.put(CONTENT_KEY, prompt);
            }

            emitter.complete();
            return promptObject;

        } catch (Exception e) {
            log.error("非流模式处理失败", e);
            sendErrorAndComplete(emitter, "请求处理失败", null);
            return promptObject;
        }
    }

    private SseEmitter handleStreamMode(JSONObject params, SseEmitter emitter) {
        try {
            // 1. 调用 RM1201 获取初始结果和 key
            JSONObject rm1201AgentResult = callRM1201(params);

            if (isSuccessResponse(rm1201AgentResult)) {
                sendErrorAndComplete(emitter, "接口调用失败", rm1201AgentResult);
                return emitter;
            }

            String key = extractKeyFromResult(rm1201AgentResult);
            if (StringUtils.isEmpty(key)) {
                sendErrorAndComplete(emitter, "接口调用失败：缺少必要参数", null);
                return emitter;
            }

            boolean knowledgeQuery = ParamUtil.getBoolValue(params, "knowledgeQuery", true);

            // 2. 创建轮询 Flux
            Flux<String> streamFlux = createPollingStream(params, key);

            // 3. 订阅 Flux 并发送 SSE 事件
            Disposable subscription = streamFlux.subscribe(
                    chunk -> sendChunkToClient(emitter, chunk, knowledgeQuery),
                    error -> handleStreamError(emitter, error),
                    () -> completeStream(emitter)
            );

            // 4. 发送原始文案 prompt 到客户端
            if (knowledgeQuery) {
                sendPromptToClient(emitter, params.getString("prompt"));
            }

            // 5. 设置清理回调
            setupCleanupCallbacks(emitter, subscription);

        } catch (Exception e) {
            log.error("流式模式初始化失败", e);
            sendErrorAndComplete(emitter, "请求处理失败", null);
        }

        return emitter;
    }

    private void handleStreamError(SseEmitter emitter, Throwable error) {
        log.error("流式模式轮询过程中发生错误", error);
        sendErrorAndComplete(emitter, "请求处理失败", null);
    }

    private void completeStream(SseEmitter emitter) {
        emitter.complete();
    }

    private Flux<String> createPollingStream(JSONObject params, String key) {
        return Flux.create(sink -> {
            AtomicReference<String> lastContent = new AtomicReference<>("");
            AtomicInteger pollCount = new AtomicInteger(0);
            AtomicBoolean isCompleted = new AtomicBoolean(false);

            // 使用定时任务进行轮询
            ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
            ScheduledFuture<?> future = scheduler.scheduleAtFixedRate(() -> {
                if (isCompleted.get() || pollCount.get() >= MAX_POLL_COUNT) {
                    scheduler.shutdown();
                    sink.complete();
                    return;
                }

                try {
                    JSONObject apiResult = callRM1202(params, key);
                    if (isSuccessResponse(apiResult)) {
                        log.error("第「{}」次轮询接口transcode=[{}]调用失败", pollCount.get(), "RM1202");
                        sink.error(new RuntimeException("轮询接口调用失败"));
                        isCompleted.set(true);
                        scheduler.shutdown();
                        return;
                    }

                    String prompt = extractContentFromPollResult(apiResult);
                    if (StringUtils.isNotEmpty(prompt)) {
                        String last = lastContent.get();
                        String newContent = prompt.replace(last, "");
                        if (StringUtils.isNotEmpty(newContent)) {
                            sink.next(newContent);
                            lastContent.set(prompt);
                        }
                    }

                    // 检查是否完成
                    if (!IS_FINISH_N.equals(extractFinishStatus(apiResult))) {
                        log.info("轮询完成，总共轮询了{}次", pollCount.get() + 1);
                        isCompleted.set(true);
                        scheduler.shutdown();
                        sink.complete();
                        return;
                    }

                    pollCount.incrementAndGet();

                } catch (Exception e) {
                    log.error("轮询处理异常", e);
                    sink.error(e);
                    isCompleted.set(true);
                    scheduler.shutdown();
                }
            }, 0, POLL_INTERVAL_MS, TimeUnit.MILLISECONDS);

            // 设置取消回调
            sink.onDispose(() -> {
                future.cancel(true);
                scheduler.shutdown();
            });
        });
    }

    private void sendChunkToClient(SseEmitter emitter, String chunk, boolean knowledgeQuery) {
        try {
            JSONObject jsonObject = buildSuccessResponse(chunk, knowledgeQuery);
            emitter.send(SseEmitter.event()
                    .data(jsonObject.toJSONString())
                    .id(UUID.randomUUID().toString()));
            // .name("message"));
        } catch (IOException e) {
            log.error("发送数据到客户端失败", e);
            throw new RuntimeException("SSE发送失败", e);
        }
    }

    private void sendPromptToClient(SseEmitter emitter, String prompt) {
        try {
            JSONObject jsonObject = buildSuccessResponse(prompt, true);
            emitter.send(SseEmitter.event()
                    .data(jsonObject.toJSONString())
                    .id(UUID.randomUUID().toString()));
            // .name("message"));
        } catch (IOException e) {
            log.error("发送知识库原始文案到客户端失败", e);
            throw new RuntimeException("SSE发送失败", e);
        }
    }

    private void setupCleanupCallbacks(SseEmitter emitter, Disposable subscription) {
        emitter.onCompletion(() -> {
            log.info("SSE连接完成");
            if (!subscription.isDisposed()) {
                subscription.dispose();
            }
        });

        emitter.onTimeout(() -> {
            log.warn("SSE连接超时");
            if (!subscription.isDisposed()) {
                subscription.dispose();
            }
        });

        emitter.onError(error -> {
            log.error("SSE连接错误", error);
            if (!subscription.isDisposed()) {
                subscription.dispose();
            }
        });
    }

    private boolean isSuccessResponse(JSONObject result) {
        return result == null || !SUCCESS_CODE.equals(result.getString(CODE_KEY));
    }

    private void sendErrorAndComplete(SseEmitter emitter, String message, JSONObject result) {
        try {
            String errorMsg = result != null ? result.getString(MSG_KEY) : message;
            emitter.send(SseEmitter.event().data(buildErrorResponse(500, errorMsg)));
        } catch (IOException e) {
            log.error("发送错误消息失败", e);
        } finally {
            emitter.complete();
        }
    }

    private String extractPromptFromResult(JSONObject result) {
        JSONArray dataArray = result.getJSONArray(DATA_KEY);
        if (dataArray == null || dataArray.isEmpty()) {
            return null;
        }
        JSONObject firstData = dataArray.getJSONObject(0);
        return firstData != null ? firstData.getString(PROMPT_KEY) : null;
    }

    private String extractKeyFromResult(JSONObject result) {
        JSONArray dataArray = result.getJSONArray(DATA_KEY);
        if (dataArray == null || dataArray.isEmpty()) {
            return null;
        }
        JSONObject firstData = dataArray.getJSONObject(0);
        return firstData != null ? firstData.getString(KEY_KEY) : null;
    }

    private String extractContentFromPollResult(JSONObject result) {
        JSONArray dataArray = result.getJSONArray(DATA_KEY);
        if (dataArray == null || dataArray.isEmpty()) {
            return null;
        }
        JSONObject firstData = dataArray.getJSONObject(0);
        return firstData != null ? firstData.getString(CONTENT_KEY) : null;
    }

    private String extractFinishStatus(JSONObject result) {
        JSONArray dataArray = result.getJSONArray(DATA_KEY);
        if (dataArray == null || dataArray.isEmpty()) {
            return null;
        }
        JSONObject firstData = dataArray.getJSONObject(0);
        return firstData != null ? firstData.getString(IS_FINISH_KEY) : null;
    }

    private JSONObject buildSuccessResponse(String content, boolean knowledgeQuery) {
        JSONObject response = new JSONObject();
        response.put("code", 200);
        if (knowledgeQuery) {
            response.put(ANSWER_KEY, content);
        } else {
            response.put(CONTENT_KEY, content);
        }
        return response;
    }

    private JSONObject buildErrorResponse(int code, String message) {
        JSONObject response = new JSONObject();
        response.put("code", code);
        response.put("message", message);
        return response;
    }

    public JSONObject callRM1201(JSONObject params) {
        String transcode = "RM1201";
        String requestParam = handleRM1201Param(params);
        log.info("请求接口transcode=[{}]，请求参数为:{}", transcode, requestParam);
        long startTime = System.currentTimeMillis();
        JSONObject result = execute(params.getString("hubApiUrl"), requestParam);
        long endTime = System.currentTimeMillis();
        log.info("接口transcode=[{}]调用完成，耗时：{}毫秒", transcode, (endTime - startTime));
        return result;
    }

    private Pair<String, String> getHubApiInfo() {
        Pair<String, List<ExtIntfParamDefineEntity>> ExtIntfPair = CallLlmUtil.extIntfParamDefineMap.get("001");
        if (Objects.isNull(ExtIntfPair)) {
            ExtIntfPair = CallLlmUtil.extIntfParamDefineMap.get("hubservice");
        }
        if (StringUtils.isEmpty(ExtIntfPair.getLeft()) || CollectionUtils.isEmpty(ExtIntfPair.getRight())) {
            return Pair.of("", "");
        }

        String account = ExtIntfPair.getRight().stream()
                .filter(item -> "account".equals(item.getParamCode()))
                .findFirst()
                .map(ExtIntfParamDefineEntity::getParamValue).orElse("");

        return Pair.of(ExtIntfPair.getLeft(), account);
    }

    public JSONObject callRM1202(JSONObject params, String key) {
        String transcode = "RM1202";
        String requestParam = handleRM1202Param(params, key);
        log.info("请求接口transcode=[{}]，请求参数为:{}", transcode, requestParam);
        long startTime = System.currentTimeMillis();
        JSONObject result = execute(params.getString("hubApiUrl"), requestParam);
        long endTime = System.currentTimeMillis();
        log.info("接口transcode=[{}]调用完成，耗时：{}毫秒", transcode, (endTime - startTime));
        return result;
    }

    private JSONObject execute(String serviceUrl, String requestParams) {
        log.info("======>开始请求服务器地址：" + serviceUrl + "<======");
        // 迁移改造点：源实现用 Apache HttpClient（HttpClientUtils.getHttpClient()），
        // 宿主无该依赖、hutool 已在，故改用 hutool 表达同样的请求语义（默认都无超时）。
        try {
            cn.hutool.http.HttpResponse response = cn.hutool.http.HttpUtil.createPost(serviceUrl)
                    .header("Content-Type", "application/json;charset=utf-8")
                    .header("Accept", "application/json")
                    .body(requestParams, "UTF-8")
                    .execute();
            String result = response.body();
            if (response.getStatus() != 200) {
                log.error("http请求失败，状态码为{}，结果为{}", response.getStatus(), result);
                return new JSONObject();
            }
            return JSON.parseObject(result, Feature.OrderedField);
        } catch (Exception e) {
            log.error("请求异常：", e);
            return new JSONObject();
        }
    }

    private String handleRM1202Param(JSONObject params, String key) {
        JSONObject requestParam = new JSONObject();
        requestParam.put("transcode", "RM1202");
        requestParam.put("account", params.getString("hubApiAccount"));
        requestParam.put("source", "EDS");
        String userId = JSONTools.getString(params, "userid");
        if (StringUtils.isBlank(userId)) {
            userId = "EDS";
        }
        requestParam.put("userid", userId);
        String bankId = JSONTools.getString(params, "orgId");
        if (StringUtils.isBlank(bankId)) {
            bankId = "EDS";
        }
        requestParam.put("orgid", bankId);
        JSONObject paramsObj = new JSONObject();
        paramsObj.put("key", key);
        requestParam.put("params", paramsObj);
        return requestParam.toJSONString();
    }

    private String handleRM1201Param(JSONObject params) {
        JSONObject requestParam = new JSONObject();
        requestParam.put("transcode", "RM1201");
        requestParam.put("account", params.getString("hubApiAccount"));
        requestParam.put("params", params);
        return requestParam.toJSONString();
    }
}
