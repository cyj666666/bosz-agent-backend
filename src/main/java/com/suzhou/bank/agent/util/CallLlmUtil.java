package com.suzhou.bank.agent.util;

import cn.hutool.core.date.DateUtil;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.google.common.collect.Maps;
import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.apache.commons.lang3.tuple.Pair;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.util.JSONTools;
import com.suzhou.bank.agent.util.AesUtil;
import com.suzhou.bank.agent.entity.CallLlmRecordEntity;
import com.suzhou.bank.agent.entity.ExtIntfParamDefineEntity;
import com.suzhou.bank.agent.entity.ExtIntfSupplierEntity;
import com.suzhou.bank.agent.entity.LargeModelConfigEntity;
import com.suzhou.bank.agent.mapper.KnowledgeBaseParamsMapper;
import com.suzhou.bank.agent.model.dto.ApplyPromptDTO;
import com.suzhou.bank.agent.service.ExtIntfParamDefineService;
import com.suzhou.bank.agent.service.ExtIntfSupplierManageService;
import com.suzhou.bank.agent.service.ICallLlmRecordService;
import com.suzhou.bank.agent.service.ILargeModelConfigService;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.Executor;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;
import java.util.stream.Collectors;

@Slf4j
@Component
public class CallLlmUtil {

    @Value("${llm.answer:暂无数据}")
    private String defaultAnswer;

    @Autowired
    private ICallLlmRecordService callLlmRecordService;

    @Autowired
    private ILargeModelConfigService iLargeModelConfigService;

    @Autowired
    private KnowledgeBaseParamsMapper knowledgeBaseParamsMapper;

    @Autowired
    private ExtIntfParamDefineService extIntfParamDefineService;

    @Autowired
    private ExtIntfSupplierManageService extIntfSupplierManageService;

    // 迁移改造点：源实现是裸 @Resource（源工程容器里只有一个 Executor）。
    // 本工程有多个 Executor（agentTaskExecutor / reportAiAnalysisExecutor），
    // 不加限定符会注入到报告模块的线程池（原因见 AgentTaskExecutorConfig），
    // 导致大模型调用与报告 AI 分析抢线程、且线程名误导排查。故显式指定 agent 自己的线程池。
    @Resource
    @Qualifier("agentTaskExecutor")
    Executor executor;

    private static final AtomicLong sortNoCounter = new AtomicLong(System.currentTimeMillis());

    private static Map<String, LargeModelConfigEntity> largeModelConfigByAccountMap;

    public static Map<String, ApplyPromptDTO> applyPromptDTOBySceneNameMap;

    public static Map<String, Pair<String, List<ExtIntfParamDefineEntity>>> extIntfParamDefineMap;

    @PostConstruct
    public void init() {
        initLargeModelConfigMap();
        initApplyPromptMap();
        initDataSourceMap();
    }

    // 每10秒执行一次刷新任务
    @Scheduled(cron = "*/10 * * * * ?")
    public void scheduledRefreshCallLlmConfig() {
        initLargeModelConfigMap();
        initApplyPromptMap();
    }

    // 每10分钟执行一次刷新任务
    @Scheduled(cron = "0 */10 * * * ?")
    public void scheduledRefreshDataSource() {
        initDataSourceMap();
    }

    // 配置缓存类，从数据源信息表中加载数据源配置
    private void initDataSourceMap() {
        try {
            LambdaQueryWrapper<ExtIntfSupplierEntity> supplierWrapper = Wrappers.lambdaQuery();
            supplierWrapper.select(ExtIntfSupplierEntity::getSupplierId, ExtIntfSupplierEntity::getIntfPath);
            List<ExtIntfSupplierEntity> supplierList = extIntfSupplierManageService.list(supplierWrapper);
            if (supplierList.isEmpty()) {
                return;
            }
            LambdaQueryWrapper<ExtIntfParamDefineEntity> queryWrapper = new LambdaQueryWrapper<>();
            queryWrapper.select(ExtIntfParamDefineEntity::getSupplierId, ExtIntfParamDefineEntity::getParamCode, ExtIntfParamDefineEntity::getParamValue);
            List<ExtIntfParamDefineEntity> entityList = extIntfParamDefineService.list(queryWrapper);
            if (entityList.isEmpty()) {
                return;
            }
            Map<String, List<ExtIntfParamDefineEntity>> listMap = entityList.stream().collect(Collectors.groupingBy(ExtIntfParamDefineEntity::getSupplierId));
            extIntfParamDefineMap = supplierList.stream().collect(Collectors.toMap(
                    ExtIntfSupplierEntity::getSupplierId,
                    supplier -> Pair.of(supplier.getIntfPath(), listMap.getOrDefault(supplier.getSupplierId(), java.util.Collections.emptyList()))
            ));
        } catch (Exception e) {
            log.error("初始化数据源配置失败, 失败原因:{}", ExceptionUtils.getStackTrace(e));
        }
    }

    // 配置缓存类,从配置文件表中加载大模型配置
    private void initLargeModelConfigMap() {
        try {
            List<LargeModelConfigEntity> largeModelConfigEntityList = iLargeModelConfigService.list();
            Map<String, LargeModelConfigEntity> tempMap = new HashMap<>();
            for (LargeModelConfigEntity largeModelConfigEntity : largeModelConfigEntityList) {
                tempMap.put(largeModelConfigEntity.getLmCode(), largeModelConfigEntity);
            }
            largeModelConfigByAccountMap = tempMap;
        } catch (Exception e) {
            log.error("初始化大模型配置失败, 失败原因:{}", ExceptionUtils.getStackTrace(e));
        }
    }

    // 配置缓存类,从配置文件表中加载大模型配置
    private void initApplyPromptMap() {
        try {
            List<JSONObject> applyPromptList = knowledgeBaseParamsMapper.getApplyPromptList();
            Map<String, ApplyPromptDTO> tempMap = new HashMap<>();
            for (JSONObject applyPrompt : applyPromptList) {
                ApplyPromptDTO applyPromptDTO = applyPrompt.toJavaObject(ApplyPromptDTO.class);
                String prompt = applyPromptDTO.getPrompt();
                if (StringUtils.isNotEmpty(prompt)) {
                    try {
                        JSONArray jsonArray = JSONArray.parseArray(prompt);
                        String outPut = jsonArray.getJSONObject(0).getJSONObject("if").getString("output");
                        // 正则匹配{{x1||x2}},将其替换成{x1}
                        outPut = outPut.replaceAll("\\{\\{([^|}]+)\\|\\|([^}]+)}}", "{$1}");
                        applyPromptDTO.setPrompt(outPut);
                    } catch (Exception e) {
                        log.error("解析应用提示词失败,场景名称:{}", applyPromptDTO.getSceneName(), e);
                    }
                }
                tempMap.put(applyPromptDTO.getSceneName(), applyPromptDTO);
            }
            applyPromptDTOBySceneNameMap = tempMap;
        } catch (Exception e) {
            log.error("初始化应用提示词失败, 失败原因:{}", ExceptionUtils.getStackTrace(e));
        }
    }

    public Object callLlm(JSONObject rspBody, SseEmitter emitter, boolean finishFlag, boolean returnFlag, boolean knowledgeQuery) {
        String requestTime = DateUtil.now();
        String traceId = ParamUtil.getSessionNo("llm_");
        String hubAccount = StringUtils.isEmpty(rspBody.getString("hub_account")) ? "init" : rspBody.getString("hub_account");
        String largeModelCode = StringUtils.isNotEmpty(rspBody.getString("large_model_code")) ? rspBody.getString("large_model_code") : "";
        String sessionMsgNo = StringUtils.isEmpty(rspBody.getString("trace_id")) ? rspBody.getString("traceId") : rspBody.getString("trace_id");

        Supplier<CallLlmRecordEntity> logSupplier = () -> {
            CallLlmRecordEntity callLlmRecordEntity = new CallLlmRecordEntity();
            callLlmRecordEntity.setTraceId(traceId);
            callLlmRecordEntity.setRequestTime(requestTime);
            callLlmRecordEntity.setHubAccount(hubAccount);
            callLlmRecordEntity.setLargeModelCode(largeModelCode);
            callLlmRecordEntity.setSessionMsgNo(sessionMsgNo);
            return callLlmRecordEntity;
        };

        // 参数校验
        if (rspBody.isEmpty()) {
            syncSaveCallLlmRecord(logSupplier.get(), requestTime, DateUtil.now(), "", "", 0, 0, 500, -1);
            finishEmitter(emitter, finishFlag);
            return AgentResult.error("参数没有数据!");
        }
        // 大模型校验
        LargeModelConfigEntity largeModelConfigEntity = largeModelConfigByAccountMap.get(largeModelCode);
        if (Objects.isNull(largeModelConfigEntity)) {
            syncSaveCallLlmRecord(logSupplier.get(), requestTime, DateUtil.now(), rspBody.toString(), "", 0, 0, 500, -1);
            finishEmitter(emitter, finishFlag);
            return AgentResult.error("非法的大模型CODE:" + largeModelCode);
        }
        // 获取模型配置
        String model;
        String url;
        String apiKey = "";
        String encryptApiKey;
        JSONObject modelConfig = getRandomModel(largeModelConfigEntity.getModelConfig());
        if (Objects.nonNull(modelConfig) && StringUtils.isNotBlank(String.valueOf(modelConfig))) {
            model = modelConfig.getString("model");
            url = modelConfig.getString("url");
            encryptApiKey = modelConfig.getString("apiKey");
            if (StringUtils.isNotEmpty(encryptApiKey)) {
                apiKey = AesUtil.decrypt(encryptApiKey.split(",")[0]);
            }
        } else {
            model = largeModelConfigEntity.getModel();
            encryptApiKey = largeModelConfigEntity.getApiKey();
            apiKey = AesUtil.decrypt(encryptApiKey.split(",")[0]);
            url = largeModelConfigEntity.getUrl();
        }

        try {
            String systemContent = StringUtils.isEmpty(rspBody.getString("system_content")) ? "You are a helpful assistant" : rspBody.getString("system_content");
            boolean stream = ParamUtil.getBoolValue(rspBody, "stream", true);
            double temperature = StringUtils.isNotEmpty(rspBody.getString("temperature")) ? Double.parseDouble(rspBody.getString("temperature")) : 0.01;
            int maxTokens = StringUtils.isNotEmpty(rspBody.getString("max_tokens")) ? Integer.parseInt(rspBody.getString("max_tokens")) : 10000;
            double topP = StringUtils.isNotEmpty(rspBody.getString("top_p")) ? Double.parseDouble(rspBody.getString("top_p")) : 0.7;
            String prompt = StringUtils.isEmpty(rspBody.getString("prompt")) ? null : rspBody.getString("prompt");
            boolean enableThink = ParamUtil.getBoolValue(
                    rspBody, "enable_think",
                    String.valueOf(largeModelConfigEntity.getDefaultThinkFlag()).equals("Y")
            );
            if (StringUtils.isEmpty(prompt)) {
                syncSaveCallLlmRecord(logSupplier.get().setApiKey(largeModelConfigEntity.getApiKey()), requestTime, DateUtil.now(), rspBody.toString(), "", 0, 0, 500, -1);
                if (stream) {
                    JSONObject response = new JSONObject();
                    response.put("code", 200);
                    response.put("answer", defaultAnswer);
                    emitter.send(SseEmitter.event()
                            .data(response.toJSONString())
                            .id(UUID.randomUUID().toString()));
                }
                finishEmitter(emitter, finishFlag);
                return stream ? emitter : AgentResult.error("非法的prompt:" + prompt);
            }

            // 记录初始化日志
            syncSaveInitCallLlmRecord(logSupplier.get().setApiKey(encryptApiKey), rspBody.toJSONString(), prompt, systemContent, requestTime, DateUtil.now());

            JSONObject requestBody = new JSONObject();
            requestBody.put("large_model_code", largeModelCode);
            requestBody.put("knowledgeQuery", knowledgeQuery);
            requestBody.put("model", model);
            requestBody.put("baseUrl", url);
            requestBody.put("apiKey", apiKey);
            requestBody.put("temperature", temperature);
            requestBody.put("topP", topP);
            requestBody.put("prompt", prompt);
            requestBody.put("maxTokens", maxTokens);
            requestBody.put("systemContent", systemContent);
            requestBody.put("moduleCode", rspBody.getString("moduleCode"));
            if ("IntelligentStrategyEngine".equals(JSONTools.getString(requestBody, "moduleCode"))) {
                requestBody.put("ruleResult", JSONTools.getValue(rspBody, "result"));
                requestBody.put("ruleData", JSONTools.getValue(rspBody, "data"));
            }
            HashMap<String, Object> hashMap = Maps.newHashMap();
            hashMap.put("enable_thinking", enableThink);
            if (largeModelCode.toUpperCase().startsWith("DOUBAO")) {
                hashMap.put("thinking", java.util.Collections.singletonMap("type", enableThink ? "enabled" : "disabled"));
            }
            HashMap<String, Object> kwargsMap = Maps.newHashMap();
            kwargsMap.put("enable_thinking", enableThink);
            kwargsMap.put("thinking", enableThink);
            hashMap.put("chat_template_kwargs", kwargsMap);
            requestBody.put("extraBody", hashMap);

            // 调用Openai客户端
            log.info("开始OpenAi调用，TraceId：{}", traceId);
            return OpenAiChatUtil.handleOpenAiStreamContent(
                    stream, requestBody, emitter, finishFlag,
                    returnFlag, logSupplier.get().setApiKey(encryptApiKey), traceId, enableThink
            );
        } catch (Exception e) {
            log.error("调用大模型失败:{}", ExceptionUtils.getStackTrace(e));
            syncSaveCallLlmRecord(logSupplier.get().setApiKey(encryptApiKey), requestTime, DateUtil.now(), rspBody.toString(), "", 0, 0, 500, 0);
            finishEmitter(emitter, finishFlag);
            return AgentResult.error("调用大模型失败！");
        }
    }

    private JSONObject getRandomModel(String modelConfig) {
        if (StringUtils.isEmpty(modelConfig)) {
            return null;
        }
        try {
            JSONArray jsonArray = JSONArray.parseArray(modelConfig);
            if (jsonArray == null || jsonArray.isEmpty()) {
                return null;
            }
            List<JSONObject> list = jsonArray.stream().map(jsonObject -> (JSONObject) jsonObject).filter(jsonObject -> StringUtils.isNotEmpty(jsonObject.getString("model"))).collect(java.util.stream.Collectors.toList());
            if (CollectionUtils.isEmpty(list)) {
                return null;
            }
            int randomIndex = (int) (Math.random() * list.size());
            return list.get(randomIndex);
        } catch (Exception e) {
            log.error("解析modelConfig失败:{}", ExceptionUtils.getStackTrace(e));
            return null;
        }
    }

    private void syncSaveInitCallLlmRecord(CallLlmRecordEntity callLlmRecordEntity, String requestBody, String prompt, String systemContent, String requestTime, String responseTime) {
        JSONArray messages = new JSONArray();
        JSONObject message = new JSONObject();
        message.put("role", "system");
        message.put("content", systemContent);
        messages.add(message);
        message = new JSONObject();
        message.put("role", "user");
        message.put("content", prompt);
        messages.add(message);
        syncSaveCallLlmRecord(callLlmRecordEntity, requestTime, responseTime, messages.toJSONString(), requestBody, 0, 0, 200, -1);
    }

    public void syncSaveCallLlmRecord(CallLlmRecordEntity callLlmRecordEntity, String requestTime, String responseTime,
                                      String content, String requestBody, Integer promptTokens, Integer completionTokens,
                                      Integer status, Integer sortNo) {
        final Integer finalSortNo = generateSortNo(sortNo);
        executor.execute(() -> saveCallLlmRecord(callLlmRecordEntity, requestTime, responseTime, content, requestBody, promptTokens, completionTokens, status, finalSortNo));
    }

    private Integer generateSortNo(Integer sortNo) {
        if (sortNo != null && (sortNo > 0 || sortNo == -1)) {
            return sortNo;
        }
        return (int) sortNoCounter.getAndIncrement();
    }

    public void saveCallLlmRecord(CallLlmRecordEntity callLlmRecordEntity, String requestTime, String responseTime,
                                  String content, String requestBody, Integer promptTokens, Integer completionTokens,
                                  Integer status, Integer sortNo) {
        try {
            CallLlmRecordEntity record = new CallLlmRecordEntity();
            BeanUtils.copyProperties(callLlmRecordEntity, record);
            record.setRequestTime(requestTime);
            record.setResponseTime(responseTime);
            record.setContent(content);
            record.setRequestBody(requestBody);
            record.setPromptTokens(Objects.nonNull(promptTokens) ? Long.valueOf(promptTokens) : 0);
            record.setCompletionTokens(Objects.nonNull(completionTokens) ? Long.valueOf(completionTokens) : 0);
            record.setStatus(status);
            record.setSortNo(sortNo);
            callLlmRecordService.save(record);
        } catch (Exception e) {
            log.error("保存大模型调用记录失败:{}", ExceptionUtils.getStackTrace(e));
        }
    }

    public static void finishEmitter(SseEmitter emitter, boolean finishFlag) {
        try {
            if (finishFlag) {
                emitter.send("finished!");
            }
            emitter.complete();
        } catch (IOException e) {
            log.error("发送结束消息失败:{}", e.getMessage());
            emitter.completeWithError(e);
        }
    }
}