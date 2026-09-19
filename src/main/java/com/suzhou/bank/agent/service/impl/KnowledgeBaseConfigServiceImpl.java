package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.date.DateUtil;
import cn.hutool.core.lang.UUID;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.parser.Feature;
import com.alibaba.fastjson.serializer.SerializerFeature;
import com.suzhou.bank.agent.client.HubApiClient;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import java.util.ArrayList;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.apache.commons.lang3.tuple.Pair;
import com.suzhou.bank.agent.config.ApiContext;
import org.htmlcleaner.HtmlCleaner;
import org.htmlcleaner.TagNode;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.dict.DictModel;
import com.suzhou.bank.agent.util.JSONTools;
import com.suzhou.bank.agent.config.AgentSpringContext;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.config.ApiContextModel;
import com.suzhou.bank.agent.dict.AgentDictCache;
import com.suzhou.bank.agent.core.DataSetBuilder;
import com.suzhou.bank.agent.core.SqlDataSetBuilder;
import com.suzhou.bank.agent.entity.*;
import com.suzhou.bank.agent.enums.*;
import com.suzhou.bank.agent.mapper.KnowledgeBaseGroupMapper;
import com.suzhou.bank.agent.mapper.OpenApiConfMapper;
import com.suzhou.bank.agent.mapper.ToolManagementMapper;
import com.suzhou.bank.agent.model.dto.ApplyPromptDTO;
import com.suzhou.bank.agent.model.dto.KnowledgeBaseGroupDTO;
import com.suzhou.bank.agent.model.dto.KnowledgeBaseParamsDTO;
import com.suzhou.bank.agent.model.req.*;
import com.suzhou.bank.agent.model.vo.*;
import com.suzhou.bank.agent.service.*;
import com.suzhou.bank.agent.tool.ToolCallExecutorFactory;
import com.suzhou.bank.agent.tool.ToolCallTypeEnum;
import com.suzhou.bank.agent.cache.DoubleCache;
import com.suzhou.bank.agent.constant.ErrorMessageConstant;
import com.suzhou.bank.agent.util.KnowledgeCacheHandler;
import com.suzhou.bank.agent.util.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.*;
import java.util.function.Supplier;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class KnowledgeBaseConfigServiceImpl implements IknowledgeBaseConfigService {

    private static final String LINE_BREAK = "{\"换行\":\"\\r\\n\"}";

    @Value("${image.source.url:}")
    private String imagePrefix;

    @Value("${module-code.cache.enable:false}")
    private boolean moduleCodeCacheEnable;

    @Autowired
    @Qualifier(value = "FetchDataThreadPool")
    private Executor fetchDataThreadPool;

    @Autowired
    @Qualifier(value = "FetchTraceThreadPool")
    private Executor fetchTraceThreadPool;

    @Autowired
    @Qualifier(value = "FetchGroupThreadPool")
    private Executor fetchGroupThreadPool;

    @Autowired
    @Qualifier(value = "SplitterThreadPool")
    private Executor splitterThreadPool;

    @Autowired
    @Lazy
    private DoubleCache doubleCache;

    private final IPromptQueryResultService promptQueryResultEntityService;

    private final ITraceQueryResultService traceQueryResultService;

    private final Executor executor;

    private final IKnowledgeBaseParamsService knowledgeBaseParamsService;

    private final KnowledgeBaseGroupMapper knowledgeBaseGroupMapper;

    private final IKnowledgeBaseGroupService knowledgeBaseGroupService;

    private final IIndexParamsService indexParamsService;

    private final ExtIntfParamManageService extIntfParamManageService;

    private final ExtIntfManageService extIntfManageService;

    private final IIndexRelateInfoService indexRelateInfoService;

    private final HubApiClient hubApiClient;

    private final RenderBigModelApiClient renderBigModelApiClient;

    private final HtmlConvertor htmlConvertor;

    private final AgentDictCache sysDictCache;

    private final ISysRoleKnowledgeService sysRoleKnowledgeService;

    private final CallLlmUtil callLlmUtil;

    private final ISysRoleKnowledgeOutputService sysRoleKnowledgeOutputService;

    private final IKnowledgeBlackParamsConfigEntityService blackParamsConfigEntityService;

    private final KnowledgeCacheHandler knowledgeCacheHandler;

    private final IKnowledgeRelateIndexService knowledgeRelateIndexService;

    private final IKnowledgeBaseVersionService knowledgeBaseVersionService;

    private final ILargeModelConfigService largeModelConfigService;

    private final ToolManagementMapper toolManagementMapper;

    private final OpenApiConfMapper openApiConfMapper;

    private final IModuleCodePromptCacheService moduleCodePromptCacheService;

    private final SyncExecuteService syncExecuteService;

    @Autowired
    @Lazy
    private IAgentRuleService agentRuleService;

    /**
     * 本地内存锁容器（替代 Redis 分布式锁），key -> 过期时间戳(毫秒)
     */
    private final ConcurrentHashMap<String, Long> localLocks = new ConcurrentHashMap<>();

    @Override
    public ListResult<?> queryKnowledgeBaseGroupTree(boolean authFlag, Integer spaceId, String relaGroupFlag, Integer modelFlag, String groupName, String groupValue) {
        // 权限过滤
        List<String> knowledgeIdList = null;
        if (authFlag) {
            knowledgeIdList = getKnowledgeIdListByRoleId();
            if (CollectionUtils.isEmpty(knowledgeIdList)) {
                return new ListResult<>(0, 0);
            }
        }

        LambdaQueryWrapper<KnowledgeBaseGroupEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(KnowledgeBaseGroupEntity::getGroupStatus, "1");
        queryWrapper.like(StringUtils.isNotEmpty(groupName), KnowledgeBaseGroupEntity::getGroupName, groupName);
        queryWrapper.like(StringUtils.isNotEmpty(groupValue), KnowledgeBaseGroupEntity::getGroupValue, groupValue);
        queryWrapper.in(CollectionUtils.isNotEmpty(knowledgeIdList), KnowledgeBaseGroupEntity::getGroupId, knowledgeIdList);
        queryWrapper.ne(null == modelFlag, KnowledgeBaseGroupEntity::getGroupName, "全部");
        List<KnowledgeBaseGroupEntity> knowledgeBaseGroupEntityList = knowledgeBaseGroupService.list(queryWrapper);
        if (CollectionUtils.isEmpty(knowledgeBaseGroupEntityList)) {
            return new ListResult<>(0, 0);
        }

        List<KnowledgeBaseGroupEntity> knowledgeBaseGroupTree = TreeUtil.buildTree(knowledgeBaseGroupEntityList, KnowledgeBaseGroupEntity::getGroupId, KnowledgeBaseGroupEntity::getParentGroupId);
        List<KnowledgeBaseGroupDTO> knowledgeBaseGroupDTOList = new ArrayList<>();
        List<KnowledgeBaseGroupDTO> groupDTOArrayList = new ArrayList<>();
        knowledgeBaseGroupTree.forEach(know -> {
            KnowledgeBaseGroupDTO knowledgeBaseGroupDTO = new KnowledgeBaseGroupDTO();
            BeanUtil.copyProperties(know, knowledgeBaseGroupDTO, true);
            knowledgeBaseGroupDTOList.add(knowledgeBaseGroupDTO);
        });
        if (null != modelFlag) {
            knowledgeBaseGroupDTOList.forEach(each -> {
                if (Objects.nonNull(each.getChildren())) {
                    groupDTOArrayList.addAll(each.getChildren());
                }
            });
            return new ListResult<>(groupDTOArrayList);
        }
        return new ListResult<>(knowledgeBaseGroupDTOList);
    }

    @Override
    public AgentResult<?> updateKnowledgeBaseGroupInfo(KnowledgeBaseGroupReq reqMsg) {
        LambdaUpdateWrapper<KnowledgeBaseGroupEntity> updateWrapper = Wrappers.lambdaUpdate();
        updateWrapper.set(KnowledgeBaseGroupEntity::getGroupName, reqMsg.getGroupName());
        updateWrapper.set(KnowledgeBaseGroupEntity::getGroupValue, reqMsg.getGroupValue());
        updateWrapper.set(KnowledgeBaseGroupEntity::getGroupType, reqMsg.getGroupType());
        updateWrapper.eq(KnowledgeBaseGroupEntity::getGroupId, reqMsg.getGroupId());
        knowledgeBaseGroupService.update(updateWrapper);
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> deleteKnowledgeBaseGroupInfo(String groupId) {
        LambdaQueryWrapper<KnowledgeBaseGroupEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(KnowledgeBaseGroupEntity::getGroupId, groupId);
        knowledgeBaseGroupService.remove(queryWrapper);
        return AgentResult.OK();
    }

    @Async("AiSummaryThreadPool")
    @Override
    public void sendAnswer(KnowledgeBasePromptViewReq req, SseEmitter emitter) {
        try {
            // 如果请求参数中有prompt文案，则直接使用该文案
            KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = knowledgeBaseParamsService.getById(req.getParamId());
            if (Objects.isNull(knowledgeBaseParamsEntity)) {
                throw new AgentBizException("请求异常，未查询到相关知识库信息！");
            }

            // 组装参数
            String moduleCode = knowledgeBaseParamsEntity.getParamNo();
            JSONObject params = JSONObject.parseObject(JSONObject.toJSONString(req));
            params.put("moduleCode", moduleCode);

            // 处理输入参数
            List<JSONObject> inputParam = req.getInputParam();
            if (CollectionUtils.isNotEmpty(inputParam)) {
                inputParam.forEach(obj -> {
                    String name = obj.getString("name");
                    String value = obj.getString("defaultValue");
                    if (StringUtils.isNotEmpty(name) && StringUtils.isNotEmpty(value)) {
                        params.put(name, value);
                    }
                });
            }

            String traceId;
            String previewPrompt = req.getPreviewPrompt();
            if (StringUtils.isNotEmpty(previewPrompt)) {
                // 如果当前是预览模式，需要使用页面的请求的数据
                knowledgeBaseParamsEntity.setPrompt(params.getString("prompt"));
                knowledgeBaseParamsEntity.setInputParam(params.getString("inputParam"));
                knowledgeBaseParamsEntity.setContentDesc(params.getString("contentDesc"));
                knowledgeBaseParamsEntity.setLargeModelCode(params.getString("largeModelCode"));
                knowledgeBaseParamsEntity.setLargeModelParam(params.getString("largeModelParam"));
                knowledgeBaseParamsEntity.setIsTop(params.getString("isTop"));
                knowledgeBaseParamsEntity.setInputCondition(params.getString("inputCondition"));
                traceId = ParamUtil.getTraceId(previewPrompt);
                previewPrompt = previewPrompt.replaceAll("数据详情追踪ID:\\[\\s*(\\w+)\\s*]", "")
                        .replaceAll("(?s)【系统提示词开始】.*?【系统提示词结束】", "")
                        .replaceAll("(?s)【输出要求开始】.*?【输出要求结束】", "");
            } else {
                JSONObject jsonObject = handlePromptContent(params);
                Object content = jsonObject.get("content");
                if (content instanceof JSONArray) {
                    previewPrompt = getDividedPromptResult((JSONArray) content);
                } else {
                    previewPrompt = String.valueOf(content);
                }
                traceId = jsonObject.getString("traceId");
            }
            if (StringUtils.isBlank(previewPrompt)) {
                finishEmitter(emitter);
                return;
            }

            // 解析输出要求
            Map<String, String> promptDescWithCond = getPromptDescWithCond(knowledgeBaseParamsEntity.getRelateIndexSet(), knowledgeBaseParamsEntity.getContentDesc(), knowledgeBaseParamsEntity.getInputCondition(), params, Maps.newHashMap());
            String corePrompt = promptDescWithCond.get("corePrompt");
            String outputRequirements = promptDescWithCond.get("userPrompt");
            if (StringUtils.isNotBlank(corePrompt)) {
                outputRequirements = (StringUtils.isNotBlank(outputRequirements) ? outputRequirements + "\n" + corePrompt : corePrompt);
            }

            long startTime = System.currentTimeMillis();
            JSONObject requestForQuestion = new JSONObject(true);
            String largeModelCode = req.getLargeModelCode();
            // 处理大模型属性参数
            String largeModelParam = knowledgeBaseParamsEntity.getLargeModelParam();
            if (StringUtils.isNotEmpty(largeModelCode) && StringUtils.isNotEmpty(largeModelParam)) {
                JSONObject jsonObject = JSON.parseObject(largeModelParam);
                if (Objects.nonNull(jsonObject) && !jsonObject.isEmpty()) {
                    JSONObject objectValue = jsonObject.getJSONObject(largeModelCode);
                    if (Objects.nonNull(objectValue) && !objectValue.isEmpty()) {
                        requestForQuestion.put("temperature", objectValue.get("temperature"));
                        requestForQuestion.put("top_p", objectValue.get("topP"));
                        requestForQuestion.put("enable_think", objectValue.get("enableThink"));
                        String systemContent = objectValue.getString("systemContent");
                        if (StringUtils.isNotBlank(systemContent)) {
                            Map<String, Object> paramGroupResultMap = Maps.newHashMap();
                            handleOutputGroupParam(knowledgeBaseParamsEntity.getRelateIndexSet(), paramGroupResultMap, params, systemContent);
                            if (!paramGroupResultMap.isEmpty()) {
                                systemContent = parsePrompt(systemContent, params, paramGroupResultMap);
                            }
                            requestForQuestion.put("system_content", systemContent);
                        }
                    }
                }
            }
            Object splitContent = handleOverallContent(knowledgeBaseParamsEntity.getSplitterParam(), largeModelCode, requestForQuestion, previewPrompt, outputRequirements, knowledgeBaseParamsEntity.getIsTop());
            requestForQuestion.put("prompt", splitContent);
            requestForQuestion.put("large_model_code", largeModelCode);
            requestForQuestion.put("stream", true);
            callLlmUtil.callLlm(requestForQuestion, emitter, true, true, false);
            requestForQuestion.put("trace_id", traceId);
            log.info("OpenAi调用完成，耗时：{}毫秒", (System.currentTimeMillis() - startTime));
        } catch (Exception e) {
            log.error("开始预览请求异常，异常信息:{}", ExceptionUtils.getStackTrace(e));
            finishEmitter(emitter);
        }
    }

    private static final int MAX_PROMPT_CONTENT_LENGTH = 100000;

    private Object handleOverallContent(String splitterParam, String largeModelCode, JSONObject largeModelParamObj, Object promptContent, String outputRequirements, String isTop) {
        List<String> splitResult;
        String splitContent;
        StringBuffer stringBuilder = new StringBuffer();

        StringBuffer resultContent = new StringBuffer();
        if (Objects.nonNull(promptContent) && promptContent instanceof JSONArray) {
            JSONArray jsonArray = (JSONArray) promptContent;
            for (Object json : jsonArray) {
                JSONObject object = (JSONObject) json;
                resultContent.append(object.getString("content")).append("\n");
            }
        } else if (StringUtils.isNotBlank(String.valueOf(promptContent))) {
            resultContent.append(promptContent);
        }

        String finalPromptContent = isTop.equals("Y") ? outputRequirements + "\n" + resultContent : resultContent + "\n" + outputRequirements;

        if (StringUtils.isNotEmpty(splitterParam) && !JSONObject.parseObject(splitterParam).isEmpty() && JSONObject.parseObject(splitterParam).getBoolean("isActive")) {
            // 查询大模型配置,取最大token数
            LargeModelConfigEntity largeModelConfigEntity = largeModelConfigService.getByLargeModelCode(largeModelCode);
            if (Objects.isNull(largeModelConfigEntity) || largeModelConfigEntity.getMaxTokens() <= 0) {
                stringBuilder.append(finalPromptContent);
            } else {
                int maxTokens = largeModelConfigEntity.getMaxTokens();
                JSONObject splitterJson = JSONObject.parseObject(splitterParam);
                double ratio = Double.parseDouble(splitterJson.getString("ratio"));
                splitContent = splitterJson.getString("content");
                // 拆分文案
                SmartTextSplitter splitter = new SmartTextSplitter.Builder().maxLength((int) (ratio / 100 * maxTokens)).targetFillRatio(1).trimSpaces(true).build();
                splitResult = splitter.split(String.valueOf(resultContent));
                if (CollectionUtils.isNotEmpty(splitResult) && splitResult.size() > 1) {
                    List<Future<String>> splitterFutures = new ArrayList<>();
                    ExecutorCompletionService<String> splitterCompletionService = new ExecutorCompletionService<>(splitterThreadPool);
                    for (int i = 0; i < splitResult.size(); i++) {
                        int finalI = i;
                        splitterFutures.add(splitterCompletionService.submit(() -> {
                            stringBuilder.append(getSplitterPromptResult(isTop.equals("Y") ? outputRequirements + "\n" + splitResult.get(finalI) : splitResult.get(finalI) + "\n" + outputRequirements, largeModelCode, largeModelParamObj));
                            return "";
                        }));
                    }
                    processResults(splitterFutures);
                    if (StringUtils.isNotBlank(splitContent)) {
                        stringBuilder.append("\n").append(splitContent);
                    }
                } else {
                    stringBuilder.append(finalPromptContent);
                }
            }
        } else {
            stringBuilder.append(finalPromptContent);
        }
        return stringBuilder.toString();
    }

    private Object handleSplitContent(List<String> splitResult, String largeModelCode, JSONObject largeModelParamObj, String outputRequirements, String businessExperience, String isTop) {
        StringBuffer stringBuilder = new StringBuffer();
        List<Future<String>> splitterFutures = new ArrayList<>();
        ExecutorCompletionService<String> splitterCompletionService = new ExecutorCompletionService<>(splitterThreadPool);
        for (int i = 0; i < splitResult.size(); i++) {
            int finalI = i;
            splitterFutures.add(splitterCompletionService.submit(() -> {
                stringBuilder.append(getSplitterPromptResult(isTop.equals("Y") ? outputRequirements + "\n" + splitResult.get(finalI) + "\n" + businessExperience : splitResult.get(finalI) + "\n" + outputRequirements + "\n" + businessExperience, largeModelCode, largeModelParamObj));
                return "";
            }));
        }
        processResults(splitterFutures);
        return stringBuilder.toString();
    }

    private Object handleSplitStrategyContent(String traceId, String knowledgeDesc, String splitStrategyParam, Object promptContent, String outputRequirements, String businessExperience, String isTop, String largeModelCode, JSONObject largeModelParamObj) {
        log.info("开始执行知识库分段策略....");
        String concatPromptContent = isTop.equals("Y") ? outputRequirements + "\n" + promptContent + "\n" + businessExperience : promptContent + "\n" + outputRequirements + "\n" + businessExperience;
        try {
            ToolCallReq toolCallReq = new ToolCallReq();
            toolCallReq.setId(traceId);
            ToolManagementEntity toolManagementEntity = new ToolManagementEntity();
            toolManagementEntity.setImplType(ToolCallTypeEnum.TEXTSPLIT.getType());

            JSONObject params = new JSONObject();
            params.put("text", promptContent);

            // 解析分段策略参数
            JSONObject splitStrategyJson = JSONObject.parseObject(splitStrategyParam);
            handleSplitStrategyParam(params, splitStrategyJson, knowledgeDesc);

            // 调用工具服务
            toolCallReq.setMethod(params.getString("method"));
            toolCallReq.setParams(params);
            Object toolResult = ToolCallExecutorFactory
                    .getToolCallExecutor(toolManagementEntity.getImplType())
                    .execute(toolCallReq, toolManagementEntity);
            if (Objects.isNull(toolResult)
                || Objects.isNull(JSONObject.parseObject(String.valueOf(toolResult)).getJSONArray("result"))) {
                return concatPromptContent;
            }

            JSONObject toolResultObj = (JSONObject) toolResult;
            JSONArray resultArray = JSONObject.parseObject(String.valueOf(toolResult)).getJSONArray("result");
            if (!toolResultObj.getString("status").equalsIgnoreCase("ok")) {
                return concatPromptContent;
            }
            if (toolResultObj.getString("status").equalsIgnoreCase("ok") && resultArray.isEmpty()) {
                return "";
            }
            // 取分段结果
            List<String> splitResultArray = new ArrayList<>();
            // final_text是否为空，如果为空，从content中取,如果content也为空，直接取item
            for (Object item : resultArray) {
                if (item instanceof String) {
                    splitResultArray.add(item + "\n\n");
                    continue;
                }
                JSONObject itemJson = (JSONObject) item;
                if (Objects.nonNull(itemJson.get("number"))
                    && itemJson.getInteger("number") == 0
                    && "整篇文章".equals(itemJson.getString("original"))) {
                    continue;
                }
                if (StringUtils.isNotBlank(itemJson.getString("final_text"))) {
                    splitResultArray.add(itemJson.getString("final_text") + "\n\n");
                } else {
                    splitResultArray.add(itemJson.getString("content") + "\n\n");
                }
            }

            // 提示词执行策略
            String promptStrategy = splitStrategyJson.getString("promptStrategy");
            // 将知识检索的结果直接拼接知识库提示词后执行
            if ("strict".equalsIgnoreCase(promptStrategy) || StringUtils.isEmpty(largeModelCode) || largeModelCode.equalsIgnoreCase("NONE")) {
                StringBuffer splitResult = new StringBuffer();
                splitResultArray.forEach(item -> splitResult.append(item).append("\n"));
                return splitResult + "\n" + outputRequirements + "\n" + businessExperience;
            } else {
                // 将知识检索到的分割分段内容拼接知识库提示词后进行模型润色，最终再将所有模型分析结果合并，拼接合并提示词后进行模型润色
                return handleSplitContent(splitResultArray, largeModelCode, largeModelParamObj, outputRequirements, businessExperience, isTop);
            }
        } catch (Exception e) {
            log.error("工具调用异常，异常信息:{}", ExceptionUtils.getStackTrace(e));
            return concatPromptContent;
        }
    }

    private void handleSplitStrategyParam(JSONObject params, JSONObject splitStrategyJson, String knowledgeDesc) {
        // 分段策略
        String splitStrategy = splitStrategyJson.getString("splitStrategy");
        Integer splitMaxLength = splitStrategyJson.getInteger("splitMaxLength");
        String splitLabel = splitStrategyJson.getString("splitLabel");
        String floorLevel = splitStrategyJson.getString("floorLevel");

        // 知识检索策略
        String retrievalStrategy = splitStrategyJson.getString("retrievalStrategy");
        JSONArray retrievalMode = splitStrategyJson.getJSONArray("retrievalMode");
        String retrievalKeywords = splitStrategyJson.getString("retrievalKeywords");
        String checkKeyword = splitStrategyJson.getString("checkKeyword");
        String checkLlm = splitStrategyJson.getString("checkLlm");
        int returnCount = Objects.isNull(splitStrategyJson.getInteger("returnCount")) ? 10 : splitStrategyJson.getInteger("returnCount");

        // 定义工具名称
        String method = "";
        params.put("check_keyword", checkKeyword);
        params.put("check_llm", checkLlm);
        params.put("merge_only_content", "all");
        // 1.分段策略为：自动分段默认、按文档层级分段、自定义分段-只有maxsize、自定义分段-有maxsize和切分符号
        if ("auto".equalsIgnoreCase(splitStrategy)) {
            params.put("process_md", "strict");
            params.put("merge_level", 0);
            method = SplitStrategyMethodEnum.BY_NUMBER_AND_SEARCH.code;
        } else if ("floor".equalsIgnoreCase(splitStrategy)) {
            params.put("process_md", "merge");
            params.put("merge_level", floorLevel);
            method = SplitStrategyMethodEnum.BY_NUMBER_AND_SEARCH.code;
        } else if ("custom".equalsIgnoreCase(splitStrategy) && Objects.nonNull(splitMaxLength) && StringUtils.isBlank(splitLabel)) {
            params.put("step_size", splitMaxLength);
            method = SplitStrategyMethodEnum.BY_FIXED_SIZE_AND_SEARCH.code;
        } else if ("custom".equalsIgnoreCase(splitStrategy) && StringUtils.isNotBlank(splitLabel)) {
            params.put("max_size", splitMaxLength);
            params.put("split_symbol", JSONArray.parseArray(JSONObject.toJSONString(java.util.Arrays.asList(splitLabel))));
            method = SplitStrategyMethodEnum.BY_SYMBOL_AND_SEARCH.code;
        }

        // 2.知识检索策略: 不检索、自动检索、自定义检索
        if ("none".equalsIgnoreCase(retrievalStrategy)) {
            retrievalMode = new JSONArray();
            retrievalKeywords = "";
            returnCount = 10;
        } else if ("auto".equalsIgnoreCase(retrievalStrategy)) {
            retrievalMode = JSONArray.parseArray(JSONObject.toJSONString(Arrays.asList("keyword", "embedding")));
            retrievalKeywords = knowledgeDesc;
        } else {
            params.put("call_func", retrievalMode);
            params.put("question", retrievalKeywords);
            params.put("top_k", returnCount);
        }

        params.put("call_func", retrievalMode);
        params.put("question", retrievalKeywords);
        params.put("top_k", returnCount);
        params.put("method", method);
        params.put("add_betag", true);
    }

    @Override
    public void sendResultCheck(KnowledgeResultCheckReq reqMsg, SseEmitter emitter) {
        try {
            String outPutContent = reqMsg.getOutPutContent();
            if (StringUtils.isBlank(outPutContent)) {
                throw new AgentBizException("参数异常！");
            }
            // 获取模版信息
            JSONObject promptTemplateObj = knowledgeBaseParamsService.getPromptTemplate();
            if (Objects.isNull(promptTemplateObj) || StringUtils.isEmpty(promptTemplateObj.getString("prompt_template"))) {
                log.info("结果校验时，未查询到相关模版信息！");
                throw new AgentBizException("结果校验异常！");
            }

            JSONObject requestForQuestion = new JSONObject(true);

            // 处理大模型属性参数
            String largeModelCode = reqMsg.getLargeModelCode();
            if (StringUtils.isEmpty(largeModelCode)) {
                largeModelCode = promptTemplateObj.getString("large_model_code");
            }
            requestForQuestion.put("large_model_code", largeModelCode);
            requestForQuestion.put("temperature", 0);
            requestForQuestion.put("top_p", 0.8);
            requestForQuestion.put("enable_think", true);

            String promptTemplate = promptTemplateObj.getString("prompt_template");
            promptTemplate = promptTemplate.replace("{rewrite_question}", reqMsg.getPrompt()).replace("{answer}", outPutContent).replace("{cur_time}", DateUtil.format(new Date(), "yyyy-MM-dd"));
            requestForQuestion.put("prompt", promptTemplate);
            requestForQuestion.put("stream", true);
            callLlmUtil.callLlm(requestForQuestion, emitter, true, true, false);
        } catch (Exception e) {
            log.error("结果校验,开始预览请求异常，异常信息:{}", ExceptionUtils.getStackTrace(e));
            finishEmitter(emitter);
        }
    }

    @Override
    public AgentResult<?> resultCheck(KnowledgeResultCheckReq reqMsg) {
        try {
            String prompt = reqMsg.getPrompt();
            if (StringUtils.isBlank(prompt)) {
                return AgentResult.error("参数异常！");
            }

            // 获取模版信息
            JSONObject promptTemplateObj = knowledgeBaseParamsService.getPromptTemplate();
            if (Objects.isNull(promptTemplateObj) || StringUtils.isEmpty(promptTemplateObj.getString("prompt_template"))) {
                log.info("结果校验时，未查询到相关模版信息！");
                return AgentResult.error("结果校验异常！");
            }

            JSONObject requestForQuestion = new JSONObject(true);

            // 处理大模型属性参数
            String largeModelCode = reqMsg.getLargeModelCode();
            if (StringUtils.isEmpty(largeModelCode)) {
                largeModelCode = promptTemplateObj.getString("large_model_code");
            }
            requestForQuestion.put("large_model_code", largeModelCode);
            requestForQuestion.put("temperature", 0);
            requestForQuestion.put("top_p", 0.8);
            requestForQuestion.put("enable_think", true);

            String promptTemplate = promptTemplateObj.getString("prompt_template");
            promptTemplate = promptTemplate.replace("{rewrite_question}", reqMsg.getPrompt()).replace("{answer}", prompt).replace("{cur_time}", DateUtil.format(new Date(), "yyyy-MM-dd"));
            requestForQuestion.put("prompt", promptTemplate);
            requestForQuestion.put("stream", false);
            Object execute = callLlmUtil.callLlm(requestForQuestion, new SseEmitter(0L), true, true, false);
            return AgentResult.OK(execute);
        } catch (Exception e) {
            return AgentResult.error("结果校验异常！");
        }
    }

    @Override
    public AgentResult<?> knowledgeBasePromptPreview(KnowledgeBasePromptViewReq reqMsg) {
        String traceId = ParamUtil.getSessionNo("");
        reqMsg.setTraceId(traceId);
        reqMsg.setIgnoreStatus(true);
        reqMsg.setPreviewFlag(true);

        Pair<String, Object> result = getPromptContentAndModuleCode(reqMsg);
        String knowledgeCode = result.getKey();
        Object promptContent = result.getValue();

        StringBuffer resultContent = new StringBuffer();
        if (Objects.nonNull(promptContent) && promptContent instanceof JSONArray) {
            JSONArray jsonArray = (JSONArray) promptContent;
            for (Object json : jsonArray) {
                JSONObject object = (JSONObject) json;
                resultContent.append(object.getString("content")).append("\n");
            }
        } else if (StringUtils.isNotBlank(String.valueOf(promptContent))) {
            String promptContentStr = String.valueOf(promptContent);
            if (promptContentStr.length() > MAX_PROMPT_CONTENT_LENGTH) {
                log.warn("promptContent exceeds max length limit, truncating to {} characters", MAX_PROMPT_CONTENT_LENGTH);
                promptContentStr = promptContentStr.substring(0, MAX_PROMPT_CONTENT_LENGTH);
            }
            resultContent.append(promptContentStr);
        }

        resultContent.append("\n\n数据详情追踪ID:[ ").append(traceId).append(" ]");
        log.info("完成知识库[{}]生成文案，TraceId为[{}]！", knowledgeCode, traceId);
        return AgentResult.OK(resultContent);
    }

    @Override
    public AgentResult<?> KnowledgeBaseTracePreview(KnowledgeBasePromptViewReq reqMsg) {
        String traceId = ParamUtil.getSessionNo("");

        Pair<String, String> result = getTraceConfig(reqMsg, traceId);
        String knowledgeCode = result.getKey();
        String traceConfig = result.getValue();

        return AgentResult.OK(traceConfig);
    }

    @Override
    public AgentResult<?> KnowledgeBaseImagePreview(KnowledgeBasePromptViewReq reqMsg) {
        String traceId = ParamUtil.getSessionNo("");

        Pair<String, String> pai = getImageConfig(reqMsg, traceId);
        String knowledgeCode = pai.getKey();
        String imageContent = pai.getValue();

        List<String> result = new ArrayList<>();
        if (StringUtils.isNotEmpty(imageContent)) {
            JSONArray jsonArray = JSONArray.parseArray(imageContent);
            jsonArray.forEach(item -> {
                JSONObject object = (JSONObject) item;
                result.add(object.getString("image"));
            });
        }

        return AgentResult.OK(result);
    }

    @Override
    public AgentResult<?> KnowledgeBaseWholeSourcePreview(KnowledgeBasePromptViewReq reqMsg) {
        String traceId = ParamUtil.getSessionNo("");

        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = knowledgeBaseParamsService.getById(reqMsg.getParamId());
        if (Objects.isNull(knowledgeBaseParamsEntity)) {
            throw new AgentBizException("请求异常，未查询到相关知识库信息！");
        }

        // 参数处理
        String wholeSourceConfig = knowledgeBaseParamsEntity.getWholeSourceConfig();
        String relateIndexSet = knowledgeBaseParamsEntity.getRelateIndexSet();
        String moduleCode = knowledgeBaseParamsEntity.getParamNo();
        JSONObject params = handleKnowledgeParam(reqMsg, traceId);

        String wholeSourceContent = getWholeSourceConfig(relateIndexSet, wholeSourceConfig, params, moduleCode);
        JSONArray jsonArray = null;
        if (StringUtils.isNotEmpty(wholeSourceContent)) {
            jsonArray = JSONArray.parseArray(wholeSourceContent);
        }

        return AgentResult.OK(jsonArray);
    }

    @Override
    public ListResult<?> getKnowledgeParamsList(KnowledgeBlackParamsConfigReq reqMsg) {
        int pageIndex = reqMsg.getPageIndex();
        int pageSize = reqMsg.getPageSize();
        LambdaQueryWrapper<KnowledgeBlackParamsConfigEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(KnowledgeBlackParamsConfigEntity::getRelateKnowledgeId, reqMsg.getRelateKnowledgeId());
        queryWrapper.orderByDesc(KnowledgeBlackParamsConfigEntity::getInputTime);
        Page<KnowledgeBlackParamsConfigEntity> page = new Page<>(pageIndex, pageSize);
        IPage<KnowledgeBlackParamsConfigEntity> pageList = blackParamsConfigEntityService.page(page, queryWrapper);
        if (pageList.getTotal() <= 0) {
            return new ListResult<>(0, 0);
        }
        List<KnowledgeBlackParamsConfigVO> resultList = new ArrayList<>();
        for (KnowledgeBlackParamsConfigEntity rec : pageList.getRecords()) {
            KnowledgeBlackParamsConfigVO paramsConfigVO = new KnowledgeBlackParamsConfigVO();
            BeanUtil.copyProperties(rec, paramsConfigVO, true);
            resultList.add(paramsConfigVO);
        }
        return new ListResult<>((int) pageList.getTotal(), pageSize, pageIndex, resultList);
    }

    @Override
    public AgentResult<?> addKnowledgeParams(KnowledgeBlackParamsConfigVO reqMsg) {
        if (Objects.isNull(reqMsg)) {
            throw new AgentBizException("参数异常！");
        }
        KnowledgeBlackParamsConfigEntity entity = new KnowledgeBlackParamsConfigEntity();
        BeanUtil.copyProperties(reqMsg, entity);
        entity.setInputTime(DateUtil.now());
        entity.setUpdateTime(DateUtil.now());
        blackParamsConfigEntityService.save(entity);
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> batchAddKnowledgeParams(List<KnowledgeBlackParamsConfigVO> reqMsg) {
        if (CollectionUtils.isEmpty(reqMsg)) {
            throw new AgentBizException("参数异常！");
        }
        List<KnowledgeBlackParamsConfigEntity> batchSaveList = new ArrayList<>();
        reqMsg.forEach(item -> {
            KnowledgeBlackParamsConfigEntity entity = new KnowledgeBlackParamsConfigEntity();
            BeanUtil.copyProperties(item, entity);
            entity.setInputTime(DateUtil.now());
            entity.setUpdateTime(DateUtil.now());
            batchSaveList.add(entity);
        });
        blackParamsConfigEntityService.saveBatch(batchSaveList);
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> getParamSelectList(KnowledgeBlackParamsConfigReq reqMsg) {
        if (Objects.isNull(reqMsg)) {
            throw new AgentBizException("参数异常！");
        }
        String relateKnowledgeId = reqMsg.getRelateKnowledgeId();
        KnowledgeBaseParamsEntity baseParamsEntity = knowledgeBaseParamsService.getById(relateKnowledgeId);
        if (Objects.isNull(baseParamsEntity)) {
            throw new AgentBizException("未查询到相关知识库信息！");
        }
        String relateIndexSet = baseParamsEntity.getRelateIndexSet();
        if (StringUtils.isEmpty(relateIndexSet)) {
            return AgentResult.OK();
        }
        JSONArray jsonArray = JSONArray.parseArray(relateIndexSet);
        if (Objects.isNull(jsonArray) || jsonArray.isEmpty()) {
            return AgentResult.OK();
        }
        // 解析，判断哪些已经关联了
        List<KnowledgeBlackParamsConfigEntity> listByKnowledgeId = blackParamsConfigEntityService.getListByKnowledgeId(relateKnowledgeId);
        if (CollectionUtils.isNotEmpty(listByKnowledgeId)) {
            jsonArray.forEach(obj -> {
                JSONObject object = (JSONObject) obj;
                String paramNo = object.getString("paramNo");
                JSONArray params = object.getJSONArray("params");
                if (CollectionUtils.isNotEmpty(params)) {
                    params.forEach(item -> {
                        JSONObject itemObj = (JSONObject) item;
                        String itemField = itemObj.getString("field");
                        Optional<KnowledgeBlackParamsConfigEntity> any = listByKnowledgeId.stream().filter(it -> paramNo.equals(it.getParamNo()) && itemField.equals(it.getParamCode())).findAny();
                        if (any.isPresent()) {
                            itemObj.put("isSelect", true);
                        }
                    });
                }
            });
        }
        return AgentResult.OK(jsonArray);
    }

    @Override
    public AgentResult<?> deleteKnowledgeParams(KnowledgeBlackParamsConfigReq reqMsg) {
        if (Objects.isNull(reqMsg) || Objects.isNull(reqMsg.getId())) {
            throw new AgentBizException("参数异常！");
        }
        blackParamsConfigEntityService.removeById(reqMsg.getId());
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> batchDeleteKnowledgeParams(List<Integer> idList) {
        if (CollectionUtils.isEmpty(idList)) {
            throw new AgentBizException("参数异常！");
        }
        blackParamsConfigEntityService.removeByIds(idList);
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> updateKnowledgeParams(KnowledgeBlackParamsConfigVO reqMsg) {
        if (Objects.isNull(reqMsg)) {
            throw new AgentBizException("参数异常！");
        }
        KnowledgeBlackParamsConfigEntity entity = new KnowledgeBlackParamsConfigEntity();
        BeanUtil.copyProperties(reqMsg, entity);
        entity.setUpdateTime(DateUtil.now());
        blackParamsConfigEntityService.updateById(entity);
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> batchUpdateKnowledgeParams(List<KnowledgeBlackParamsConfigVO> reqMsg) {
        if (CollectionUtils.isEmpty(reqMsg)) {
            throw new AgentBizException("参数异常！");
        }
        List<KnowledgeBlackParamsConfigEntity> batchSaveList = new ArrayList<>();
        reqMsg.forEach(item -> {
            KnowledgeBlackParamsConfigEntity entity = new KnowledgeBlackParamsConfigEntity();
            BeanUtil.copyProperties(item, entity);
            entity.setUpdateTime(DateUtil.now());
            batchSaveList.add(entity);
        });
        blackParamsConfigEntityService.updateBatchById(batchSaveList);
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> saveBlackParam(KnowledgeBlackConfigSaveVO reqMsg) {
        if (Objects.isNull(reqMsg)) {
            throw new AgentBizException("参数异常！");
        }
        // 更新知识库信息
        LambdaUpdateWrapper<KnowledgeBaseParamsEntity> updateWrapper = Wrappers.lambdaUpdate();
        updateWrapper.set(KnowledgeBaseParamsEntity::getBlackModelCode, reqMsg.getBlackModelCode());
        updateWrapper.set(KnowledgeBaseParamsEntity::getBlackContentDesc, reqMsg.getBlackContentDesc());
        updateWrapper.eq(KnowledgeBaseParamsEntity::getParamId, reqMsg.getRelateKnowledgeId());
        knowledgeBaseParamsService.update(updateWrapper);
        // 更新黑盒参数信息
        List<KnowledgeBlackParamsConfigVO> blackParamsConfigVOList = reqMsg.getBlackParamsConfigVOList();
        if (CollectionUtils.isNotEmpty(blackParamsConfigVOList)) {
            List<KnowledgeBlackParamsConfigEntity> batchSaveList = new ArrayList<>();
            blackParamsConfigVOList.forEach(item -> {
                KnowledgeBlackParamsConfigEntity entity = new KnowledgeBlackParamsConfigEntity();
                BeanUtil.copyProperties(item, entity);
                entity.setUpdateTime(DateUtil.now());
                batchSaveList.add(entity);
            });
            blackParamsConfigEntityService.updateBatchById(batchSaveList);
        }
        return AgentResult.OK();
    }

    @Override
    public String parsePrompt(String prompt, JSONObject params, Map<String, Object> groupMap) {
        if (StringUtils.isEmpty(prompt)) {
            return prompt;
        }
        String entName = params.getString("entName");
        if (StringUtils.isNotEmpty(entName)) {
            prompt = prompt.replace("{{objectName}}", entName);
        }
        prompt = ParamUtil.replacePromptParam(prompt, params);
        prompt = ParamUtil.decodeBase64Prompt(prompt, groupMap);
        return ParamUtil.insteadPrompt(prompt, groupMap);
    }

    @Override
    public Map<String, Object> parsePromptWithCondAndKnowledge(String isMarkdown, String relateIndexSet, String prompt, JSONObject params, Map<String, Object> paramGroupResultMap) {
        if (StringUtils.isEmpty(prompt)) {
            return null;
        }

        // 获取所有条件组中相关的指标值
        JSONArray promptCondGroups = JSONArray.parseArray(prompt);
        handleConditionGroupParam(relateIndexSet, params, promptCondGroups, paramGroupResultMap);

        // 取出满足条件的分组的文案配置中的指标集合
        // 使用线程隔离方式，每个线程返回独立结果，主线程汇总，避免并发修改问题
        Set<String> outPutRuleSet = ConcurrentHashMap.newKeySet();
        List<Future<Set<String>>> groupFutures = new ArrayList<>();
        ExecutorCompletionService<Set<String>> groupCompletionService = new ExecutorCompletionService<>(fetchGroupThreadPool);
        promptCondGroups.forEach(condGroup -> groupFutures.add(groupCompletionService.submit(() -> {
            Set<String> resultSet = new HashSet<>();
            JSONObject promptCondGroup = (JSONObject) condGroup;
            if (promptCondGroup.containsKey("if")) {
                JSONObject ifCond = promptCondGroup.getJSONObject("if");
                String joinCond = ifCond.getString("condition");
                String outPut = ifCond.getString("output");
                JSONArray variables = ifCond.getJSONArray("variables");
                if (shouldProcessCondition(joinCond, variables, paramGroupResultMap)) {
                    outPutRuleSet.addAll(ParamUtil.getRuleList(outPut));
                    resultSet.addAll(ParamUtil.getParamNoList(outPut));
                }
            }
            return resultSet;
        })));

        // 汇总所有线程的结果
        Set<String> outPutParamNoSet = new HashSet<>();
        for (Future<Set<String>> future : groupFutures) {
            try {
                outPutParamNoSet.addAll(future.get());
            } catch (InterruptedException | ExecutionException e) {
                log.error("获取分组条件指标结果失败", e);
            }
        }

        // 取出满足条件的规则集合的值
        getPromptRuleValueMap(outPutRuleSet, params, paramGroupResultMap);

        // 取值满足条件指标集合的值
        ArrayList<String> outPutParamNoList = new ArrayList<>(outPutParamNoSet);
        getIndexValueMap(relateIndexSet, params, outPutParamNoList, paramGroupResultMap);

        // 开始处理prompt文案
        JSONArray promptArray = new JSONArray();
        JSONArray resourceArray = new JSONArray();
        int[] indexes = new int[]{0, 0};
        Map<String, Object> resultMap = Maps.newHashMap();
        // 初始化已访问知识库ID集合，用于防止多层嵌套引用时的循环引用
        Set<String> visitedKnowledgeIds = new HashSet<>();
        visitedKnowledgeIds.add(params.getString("paramId"));
        for (Object condGroup : promptCondGroups) {
            JSONObject promptCondGroup = (JSONObject) condGroup;
            if (!promptCondGroup.containsKey("if")) {
                continue;
            }

            String currentPrompt = "";
            JSONObject ifCond = promptCondGroup.getJSONObject("if");
            String joinCond = ifCond.getString("condition");
            String outPut = ifCond.getString("output");
            JSONArray variables = ifCond.getJSONArray("variables");
            if (shouldProcessCondition(joinCond, variables, paramGroupResultMap)) {
                JSONArray resourceArr = ifCond.getJSONArray("resource");
                Boolean resourceFlag = ifCond.getBoolean("resourceFlag");
                if (Objects.nonNull(resourceFlag) && resourceFlag && CollectionUtils.isNotEmpty(resourceArr)) {
                    // 获取溯源文案
                    Pair<Integer, Map<String, Object>> resourcePrompt = getResourcePrompt(indexes[0], resourceArr, paramGroupResultMap);
                    if (Objects.nonNull(resourcePrompt)) {
                        indexes[0] = resourcePrompt.getKey();
                        Map<String, Object> value = resourcePrompt.getValue();
                        paramGroupResultMap.forEach(value::putIfAbsent);
                        String processedOutPut4 = replaceRuleReferences(outPut, paramGroupResultMap);
                        currentPrompt = parsePrompt(processedOutPut4, params, value);
                    }
                    // 获取溯源内容
                    Pair<Integer, JSONArray> resourceContent = getResourceContent(indexes[1], resourceArr, paramGroupResultMap);
                    indexes[1] = resourceContent.getKey();
                    resourceArray.addAll(resourceContent.getValue());
                } else {
                    String processedOutPut5 = replaceRuleReferences(outPut, paramGroupResultMap);
                    currentPrompt = parsePrompt(processedOutPut5, params, paramGroupResultMap);
                }
                if (StringUtils.isNotEmpty(currentPrompt)) {
                    JSONObject currentObj = new JSONObject();
                    if (StringUtils.isNotEmpty(isMarkdown) && OnlineEnum.Y.name().equals(isMarkdown)) {
                        currentPrompt = JsonToMarkdown.transferJsonToMarkDown(currentPrompt);
                    }
                    currentObj.put("content", currentPrompt);
                    currentObj.put("largeModelCode", "");
                    promptArray.add(currentObj);
                }
                // 处理引用知识库
                processKnowledgeReferences(indexes, params, ifCond, promptArray, resourceArray, paramGroupResultMap, visitedKnowledgeIds);
            }
        }

        resultMap.put("promptContent", promptArray);
        resultMap.put("sourceCard", resourceArray);
        return resultMap;
    }

    @Override
    public Map<String, Object> parsePromptWithCond(String isMarkdown, int[] indexes, String relateIndexSet, String prompt, JSONObject params, Map<String, Object> paramGroupResultMap) {
        if (StringUtils.isEmpty(prompt)) {
            return null;
        }
        // 获取所有条件组中相关的指标值
        JSONArray promptCondGroups = JSONArray.parseArray(prompt);
        handleConditionGroupParam(relateIndexSet, params, promptCondGroups, paramGroupResultMap);

        Map<String, Object> resultMap = Maps.newHashMap();
        StringBuffer promptBuilder = new StringBuffer();
        JSONArray resourceArray = new JSONArray();
        if (indexes == null) {
            indexes = new int[]{0, 0};
        }
        // 取出满足条件的分组的文案配置中的指标集合
        Set<String> outPutParamNoSet = ConcurrentHashMap.newKeySet();
        Set<String> outPutRuleSet = ConcurrentHashMap.newKeySet();
        List<Future<String>> groupFutures = new ArrayList<>();
        ExecutorCompletionService<String> groupCompletionService = new ExecutorCompletionService<>(fetchGroupThreadPool);
        promptCondGroups.forEach(condGroup -> groupFutures.add(groupCompletionService.submit(() -> {
            JSONObject promptCondGroup = (JSONObject) condGroup;
            if (promptCondGroup.containsKey("if")) {
                JSONObject ifCond = promptCondGroup.getJSONObject("if");
                String joinCond = ifCond.getString("condition");
                String outPut = ifCond.getString("output");
                JSONArray variables = ifCond.getJSONArray("variables");
                if (shouldProcessCondition(joinCond, variables, paramGroupResultMap)) {
                    outPutRuleSet.addAll(ParamUtil.getRuleList(outPut));
                    outPutParamNoSet.addAll(ParamUtil.getParamNoList(outPut));
                }
            }
            return "";
        })));
        processResults(groupFutures);

        // 取出满足条件的规则集合的值
        getPromptRuleValueMap(outPutRuleSet, params, paramGroupResultMap);

        // 取值满足条件指标集合的值
        getIndexValueMap(relateIndexSet, params, new ArrayList<>(outPutParamNoSet), paramGroupResultMap);

        // 查询需要溯源的指标
        Map<String, String> indexInfoMap = knowledgeRelateIndexService.getSourceCardIndexTraceConfigList(params.getString("knowledgeId"));
        Set<String> sourceParamNoSet = indexInfoMap.keySet();

        // 开始处理prompt文案
        for (Object condGroup : promptCondGroups) {
            JSONObject promptCondGroup = (JSONObject) condGroup;
            if (!promptCondGroup.containsKey("if")) {
                continue;
            }
            JSONObject ifCond = promptCondGroup.getJSONObject("if");
            String joinCond = ifCond.getString("condition");
            String outPut = ifCond.getString("output");
            JSONArray variables = ifCond.getJSONArray("variables");
            if (shouldProcessCondition(joinCond, variables, paramGroupResultMap)) {
                JSONArray resourceArr = ifCond.getJSONArray("resource");
                Boolean resourceFlag = ifCond.getBoolean("resourceFlag");
                List<String> paramNoList = ParamUtil.getParamNoList(outPut);
                // 判断indexInfoMap是否包含paramNoList中的某个指标
                if (Objects.nonNull(resourceFlag) && resourceFlag && CollectionUtils.isNotEmpty(resourceArr)) {
                    // 获取溯源文案
                    Pair<Integer, Map<String, Object>> resourcePrompt = getResourcePrompt(indexes[0], resourceArr, paramGroupResultMap);
                    if (Objects.nonNull(resourcePrompt)) {
                        indexes[0] = resourcePrompt.getKey();
                        Map<String, Object> value = resourcePrompt.getValue();
                        paramGroupResultMap.forEach(value::putIfAbsent);
                        String processedOutPut = replaceRuleReferences(outPut, paramGroupResultMap);
                        promptBuilder.append(parsePrompt(processedOutPut, params, value));
                    }
                    // 获取溯源内容
                    Pair<Integer, JSONArray> resourceContent = getResourceContent(indexes[1], resourceArr, paramGroupResultMap);
                    indexes[1] = resourceContent.getKey();
                    resourceArray.addAll(resourceContent.getValue());
                } else if (!indexInfoMap.isEmpty() && paramNoList.stream().anyMatch(sourceParamNoSet::contains)) {
                    // 新溯源取值逻辑
                    Pair<Integer, Map<String, Object>> resourcePrompt = getNewResourcePrompt(indexes[0], indexInfoMap, paramGroupResultMap);
                    indexes[0] = resourcePrompt.getKey();
                    Map<String, Object> value = resourcePrompt.getValue();
                    paramGroupResultMap.forEach(value::putIfAbsent);
                    String processedOutPut2 = replaceRuleReferences(outPut, paramGroupResultMap);
                    promptBuilder.append(parsePrompt(processedOutPut2, params, value));
                    // 过滤掉indexInfoMap中不包含在paramNoList中的指标
                    Map<String, String> filteredIndexInfoMap = indexInfoMap.entrySet().stream()
                            .filter(entry -> paramNoList.contains(entry.getKey()))
                            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
                    Pair<Integer, JSONArray> resourceContent = getNewResourceContent(indexes[1], filteredIndexInfoMap, paramGroupResultMap);
                    indexes[1] = resourceContent.getKey();
                    JSONArray contentValue = resourceContent.getValue();
                    if (Objects.nonNull(contentValue) && !contentValue.isEmpty()) {
                        resourceArray.addAll(contentValue);
                    }
                } else {
                    // 获取普通文案
                    String processedOutPut3 = replaceRuleReferences(outPut, paramGroupResultMap);
                    promptBuilder.append(parsePrompt(processedOutPut3, params, paramGroupResultMap));
                }
            }
        }
        String promptContent = promptBuilder.toString();
        if (StringUtils.isNotEmpty(isMarkdown) && OnlineEnum.Y.name().equals(isMarkdown)) {
            promptContent = JsonToMarkdown.transferJsonToMarkDown(promptContent);
        }
        resultMap.put("promptContent", promptContent);
        resultMap.put("sourceCard", resourceArray);
        return resultMap;
    }

    @Override
    public Map<String, String> getPromptDescWithCond(String relateIndexSet, String contentDesc, String inputCondition, JSONObject params, Map<String, Object> paramGroupResultMap) {
        String largeModelCode = "";
        StringBuffer corePromptBuilder = new StringBuffer();
        StringBuffer userPromptBuilder = new StringBuffer();
        try {
            if (StringUtils.isEmpty(contentDesc)) {
                return Maps.newHashMap();
            }
            JSONArray promptCondGroups = JSONArray.parseArray(contentDesc);
            handleConditionGroupParam(relateIndexSet, params, promptCondGroups, paramGroupResultMap);
            for (Object condGroup : promptCondGroups) {
                JSONObject promptCondGroup = (JSONObject) condGroup;
                if (!promptCondGroup.containsKey("if")) {
                    continue;
                }
                JSONObject ifCond = promptCondGroup.getJSONObject("if");
                String joinCond = ifCond.getString("condition");
                JSONArray variables = ifCond.getJSONArray("variables");
                boolean condition = shouldProcessCondition(joinCond, variables, paramGroupResultMap);
                // 核心提示词
                String output = ifCond.getString("output");
                if (condition && StringUtils.isNotEmpty(output)) {
                    if (StringUtils.isEmpty(largeModelCode)) {
                        JSONObject modelInfo = ifCond.getJSONObject("modelInfo");
                        largeModelCode = Objects.nonNull(modelInfo) && !"NONE".equalsIgnoreCase(modelInfo.getString("largeModelCode")) ? modelInfo.getString("largeModelCode") : "";
                    }
                    handleOutputGroupParam(relateIndexSet, paramGroupResultMap, params, output);
                    String processedOutput = replaceRuleReferences(output, paramGroupResultMap);
                    corePromptBuilder.append(parsePrompt(processedOutput, params, paramGroupResultMap));
                }
                // 用户提示词
                String usePrompt = ifCond.getString("usePrompt");
                if (condition && StringUtils.isNotEmpty(usePrompt)) {
                    if (StringUtils.isEmpty(largeModelCode)) {
                        JSONObject modelInfo = ifCond.getJSONObject("modelInfo");
                        largeModelCode = Objects.nonNull(modelInfo) && !"NONE".equalsIgnoreCase(modelInfo.getString("largeModelCode")) ? modelInfo.getString("largeModelCode") : "";
                    }
                    handleOutputGroupParam(relateIndexSet, paramGroupResultMap, params, usePrompt);
                    String processedOutput = replaceRuleReferences(usePrompt, paramGroupResultMap);
                    userPromptBuilder.append(parsePrompt(processedOutput, params, paramGroupResultMap));
                }
            }
            if (StringUtils.isEmpty(corePromptBuilder.toString()) && StringUtils.isEmpty(userPromptBuilder.toString()) && StringUtils.isNotEmpty(inputCondition)) {
                try {
                    // 处理 inputCondition 中指标
                    JSONObject object = JSONObject.parseObject(inputCondition);
                    String inputOutput = object.getString("output");
                    handleOutputGroupParam(relateIndexSet, paramGroupResultMap, params, inputOutput);
                    String corePrompt = parsePrompt(inputOutput, params, paramGroupResultMap);
                    // 用户提示词
                    String usePrompt = object.getString("usePrompt");
                    handleOutputGroupParam(relateIndexSet, paramGroupResultMap, params, usePrompt);
                    String processedOutput = replaceRuleReferences(usePrompt, paramGroupResultMap);
                    String userPrompt = parsePrompt(processedOutput, params, paramGroupResultMap);
                    JSONObject modelInfo = object.getJSONObject("modelInfo");
                    largeModelCode = Objects.nonNull(modelInfo) && !"NONE".equalsIgnoreCase(modelInfo.getString("largeModelCode")) ? modelInfo.getString("largeModelCode") : "";
                    Map<String, String> resultMap = Maps.newHashMap();
                    resultMap.put("corePrompt", corePrompt);
                    resultMap.put("userPrompt", userPrompt);
                    resultMap.put("largeModelCode", largeModelCode);
                    return resultMap;
                } catch (Exception e) {
                    Map<String, String> resultMap = Maps.newHashMap();
                    resultMap.put("corePrompt", inputCondition);
                    resultMap.put("userPrompt", "");
                    resultMap.put("largeModelCode", largeModelCode);
                    return resultMap;
                }
            }
            Map<String, String> resultMap = Maps.newHashMap();
            resultMap.put("corePrompt", corePromptBuilder.toString());
            resultMap.put("userPrompt", userPromptBuilder.toString());
            resultMap.put("largeModelCode", largeModelCode);
            return resultMap;
        } catch (Exception e) {
            log.error("输出要求条件检查异常，请重新初始化该配置！");
            Map<String, String> resultMap = Maps.newHashMap();
            resultMap.put("corePrompt", contentDesc);
            resultMap.put("userPrompt", "");
            resultMap.put("largeModelCode", largeModelCode);
            return resultMap;
        }
    }

    @Override
    public String parseTraceConfig(String relateIndexSet, String moduleCode, String traceConfig, JSONObject params, Map<String, Object> paramGroupResultMap) {
        JSONArray traceConfigArr = JSONArray.parseArray(traceConfig);
        HtmlCleaner htmlCleaner = new HtmlCleaner();

        List<String> allParamNoList = new ArrayList<>();
        Map<String, Object> dataMap = new HashMap<>();
        List<IndexParamsEntity> paramList = new ArrayList<>();
        for (Object trace : traceConfigArr) {
            JSONObject traceObj = (JSONObject) trace;
            String sourceAnchor = traceObj.getString("source_anchor");
            List<String> sourceParamNoList = ParamUtil.getParamNoList(sourceAnchor);
            if (CollectionUtils.isNotEmpty(sourceParamNoList)) {
                allParamNoList.addAll(sourceParamNoList);
            }

            // 提取html中涉及的指标
            String html = traceObj.getString("html").replace("<br />", "").replace("&nbsp;", "");
            if (StringUtils.isNotEmpty(html)) {
                TagNode tagNode = htmlCleaner.clean(html);
                List<? extends TagNode> allNodes = tagNode.getElementListHavingAttribute("data-param-no", true);
                if (CollectionUtils.isNotEmpty(allNodes)) {
                    Set<String> htmlParamNoList = allNodes.stream().map(node -> node.getAttributeByName("data-param-no")).collect(Collectors.toSet());
                    allParamNoList.addAll(htmlParamNoList);
                }
            }
        }

        if (CollectionUtils.isNotEmpty(allParamNoList)) {
            // 查询相关指标信息
            List<IndexParamsEntity> indexParamsEntityList = indexParamsService.listByIds(allParamNoList);
            List<IndexParamsEntity> apiCollect = indexParamsEntityList.stream().filter(index -> "Api".equalsIgnoreCase(index.getScriptType())).collect(Collectors.toList());
            List<IndexParamsEntity> sqlCollect = indexParamsEntityList.stream().filter(index -> !"Api".equalsIgnoreCase(index.getScriptType())).collect(Collectors.toList());
            if (CollectionUtils.isNotEmpty(apiCollect)) {
                Set<String> set = apiCollect.stream().map(IndexParamsEntity::getOtherNo).collect(Collectors.toSet());
                List<IndexParamsEntity> apiParamList = indexParamsService.selectByOtherNoList(new ArrayList<>(set));
                paramList.addAll(apiParamList);
                allParamNoList.addAll(set);
            }
            if (CollectionUtils.isNotEmpty(sqlCollect)) {
                Set<String> set = sqlCollect.stream().map(IndexParamsEntity::getParentParamNo).collect(Collectors.toSet());
                List<IndexParamsEntity> sqlParamList = indexParamsService.selectByParentParamNoList(new ArrayList<>(set));
                paramList.addAll(sqlParamList);
                allParamNoList.addAll(set);
            }
            // 获取指标数据集合
            dataMap = handleParam(relateIndexSet, params, allParamNoList, new HashMap<>(0), paramGroupResultMap);
        }

        // 多线程处理卡片数据
        ExecutorCompletionService<String> completionService = new ExecutorCompletionService<>(fetchTraceThreadPool);
        List<Future<String>> futures = new ArrayList<>();

        Map<String, Object> finalDataMap = dataMap;
        List<JSONObject> finalTraceConfigArr = new CopyOnWriteArrayList<>();
        for (Object trace : traceConfigArr) {
            futures.add(completionService.submit(() -> {
                JSONObject traceObj = (JSONObject) trace;

                // 单独存储溯源指标配置
                String sourceAnchor = traceObj.getString("source_anchor");
                traceObj.put("source_index", sourceAnchor);

                // 溯源展示类型
                String sourceType = traceObj.getString("sourceType");

                // 溯源指标解析
                if (StringUtils.isNotEmpty(sourceAnchor)) {
                    String sourceValue = ParamUtil.insteadPrompt(sourceAnchor, finalDataMap);
                    traceObj.put("source_anchor", sourceValue);
                    if (StringUtils.isNotEmpty(sourceType) && "cardType".equals(sourceType)) {
                        JSONArray sourceArray = new JSONArray();
                        JSONArray inputParams = traceObj.getJSONArray("inputParam");
                        JSONArray defaultParams = traceObj.getJSONArray("defaultParams");
                        if (CollectionUtils.isNotEmpty(defaultParams)) {
                            List<JSONObject> collect = defaultParams.stream().map(def -> (JSONObject) def).filter(def -> OnlineEnum.Y.name().equalsIgnoreCase(def.getString("isSourceMatch"))).collect(Collectors.toList());
                            sourceArray.addAll(collect);
                        }
                        if (CollectionUtils.isNotEmpty(inputParams)) {
                            List<JSONObject> collect = inputParams.stream().map(def -> (JSONObject) def).filter(def -> OnlineEnum.Y.name().equalsIgnoreCase(def.getString("isSourceMatch"))).collect(Collectors.toList());
                            sourceArray.addAll(collect);
                        }

                        Object parseObj = JSON.parse(sourceValue);
                        JSONArray jsonArray;
                        if (parseObj instanceof JSONObject) {
                            jsonArray = new JSONArray();
                            jsonArray.add(parseObj);
                        } else {
                            jsonArray = (JSONArray) parseObj;
                        }

                        // card内容解析
                        jsonArray.forEach(parse -> {
                            JSONObject object = (JSONObject) parse;
                            JSONObject newJson = new JSONObject();

                            if (CollectionUtils.isNotEmpty(defaultParams)) {
                                defaultParams.forEach(def -> {
                                    JSONObject defObj = (JSONObject) def;
                                    Object paramMapping = object.get(defObj.getString("paramMapping"));
                                    newJson.put(defObj.getString("urlParam"), Objects.isNull(paramMapping) ? "" : paramMapping);
                                });

                                // 判断是否为空
                                if (TreeUtil.checkAllValuesEmpty(newJson)) {
                                    newJson.put("id", UUID.fastUUID().toString());
                                    newJson.put("card_title", newJson.get("title"));
                                    JSONArray externalField = new JSONArray();
                                    if (CollectionUtils.isNotEmpty(inputParams)) {
                                        inputParams.forEach(input -> {
                                            JSONObject inputObj = (JSONObject) input;
                                            Object paramMapping = object.get(inputObj.getString("paramMapping"));
                                            JSONObject newInputObj = new JSONObject();
                                            newInputObj.put("name", inputObj.getString("paramName"));
                                            newInputObj.put("value", Objects.isNull(paramMapping) ? "" : paramMapping);
                                            externalField.add(newInputObj);
                                        });
                                    }
                                    newJson.put("externalField", externalField);

                                    // 是否溯源逻辑过滤
                                    if (!sourceArray.isEmpty()) {
                                        JSONArray finalSourceArr = new JSONArray();
                                        JSONObject finalSource = new JSONObject();
                                        List<String> paramMapping = sourceArray.stream().map(obj -> ((JSONObject) obj).getString("paramMapping")).collect(Collectors.toList());
                                        paramMapping.forEach(map -> finalSource.put(map, object.getString(map)));
                                        finalSourceArr.add(finalSource);
                                        newJson.put("source_anchor", JSON.toJSONString(finalSourceArr));
                                    }
                                    finalTraceConfigArr.add(newJson);
                                }
                            }
                        });
                    }
                    // html内容解析
                    else if (StringUtils.isEmpty(sourceType) || "listType".equals(sourceType)) {
                        String html = traceObj.getString("html").replace("<br />", "").replace("&nbsp;", "");
                        if (StringUtils.isNotEmpty(html)) {
                            TagNode tagNode = htmlCleaner.clean(html);
                            TagNode convert = htmlConvertor.convert(tagNode, finalDataMap, paramList);
                            List<? extends TagNode> table = convert.getElementListByName("table", true);
                            if (CollectionUtils.isNotEmpty(table) && table.get(0).hasChildren()) {
                                JSONObject newInputObj = new JSONObject();
                                newInputObj.put("id", StringUtils.isEmpty(traceObj.getString("id")) ? UUID.fastUUID().toString() : traceObj.getString("id"));
                                newInputObj.put("source_index", traceObj.getString("source_index"));
                                newInputObj.put("card_title", traceObj.getString("card_title"));
                                newInputObj.put("source_anchor", traceObj.getString("source_anchor"));
                                newInputObj.put("html", DOMUtils.toString(convert));
                                finalTraceConfigArr.add(newInputObj);
                            }
                        }
                    }
                    // 原始文本输出
                    else {
                        JSONObject newInputObj = new JSONObject();
                        newInputObj.put("id", StringUtils.isEmpty(traceObj.getString("id")) ? UUID.fastUUID().toString() : traceObj.getString("id"));
                        newInputObj.put("source_index", traceObj.getString("source_index"));
                        newInputObj.put("card_title", traceObj.getString("card_title"));
                        newInputObj.put("source_anchor", traceObj.getString("source_anchor"));
                        newInputObj.put("html", sourceValue);
                        finalTraceConfigArr.add(newInputObj);
                    }
                }
                return "";
            }));
        }

        processResults(futures);
        return JSONObject.toJSONString(finalTraceConfigArr);
    }

    @Override
    public String parseImageConfig(String relateIndexSet, String moduleCode, String imageConfig, JSONObject params, Map<String, Object> paramGroupResultMap) {
        JSONObject traceConfig = JSONArray.parseArray(imageConfig).getJSONObject(0);

        List<String> paramNoList = new ArrayList<>();

        // 提取html中涉及的指标
        String html = traceConfig.getString("html").replace("<br />", "").replace("&nbsp;", "");
        if (StringUtils.isNotEmpty(html)) {
            Pair<String, List<String>> paramInfoList = ParamUtil.getParamInfoList(html);
            paramNoList = paramInfoList.getValue();
        }

        // 查询溯源指标配置
        Map<String, Object> dataMap = handleParam(relateIndexSet, params, paramNoList, new HashMap<>(0), paramGroupResultMap);
        if (Objects.isNull(dataMap) || dataMap.isEmpty()) {
            return null;
        }

        // 处理图片数据(只取一条数据)
        JSONArray jsonArray = new JSONArray();
        for (Map.Entry<String, Object> entry : dataMap.entrySet()) {
            String imageContent = String.valueOf(entry.getValue());
            if (StringUtils.isNotEmpty(imageContent)) {
                jsonArray = JSONArray.parseArray(imageContent);
                jsonArray.forEach(item -> {
                    JSONObject object = (JSONObject) item;
                    object.put("img", object.getString("image"));
                    object.put("image", imagePrefix + object.getString("image"));
                });
            }
            break;
        }
        return JSONArray.toJSONString(jsonArray);
    }

    @Override
    public String parseWholeSourceConfig(String relateIndexSet, String moduleCode, String wholeSourceConfig, JSONObject params, Map<String, Object> paramGroupResultMap) {
        JSONArray wholeSourceArr = JSONArray.parseArray(wholeSourceConfig);
        if (CollectionUtils.isEmpty(wholeSourceArr)) {
            return null;
        }

        List<String> paramNoList = new ArrayList<>();

        // 提取sourceAnchor中涉及的指标
        for (Object source : wholeSourceArr) {
            JSONObject sourceObject = (JSONObject) source;
            String sourceAnchor = sourceObject.getString("sourceAnchor");
            List<String> sourceParamNoList = ParamUtil.getParamNoList(sourceAnchor);
            paramNoList.addAll(sourceParamNoList);
        }

        // 处理指标数据
        Map<String, Object> dataMap = handleParam(relateIndexSet, params, paramNoList, new HashMap<>(0), paramGroupResultMap);
        if (Objects.isNull(dataMap) || dataMap.isEmpty()) {
            return null;
        }

        JSONArray wholeSourceResult = new JSONArray();
        for (Object source : wholeSourceArr) {
            JSONObject sourceObject = (JSONObject) source;
            String sourceAnchor = sourceObject.getString("sourceAnchor");
            String paramNo = ParamUtil.getParamNoList(sourceAnchor).get(0);
            Object paramValue = dataMap.get(paramNo);
            if (Objects.isNull(paramValue)) {
                continue;
            }

            // appID公共参数
            JSONObject appParams = new JSONObject();
            BeanUtil.copyProperties(params, appParams, true);
            List<String> removeKeyList = Arrays.asList("largeModelCode", "knowledgeCode", "traceId", "isMutiEnt", "moduleCode");
            removeKeyList.forEach(appParams::remove);

            // 处理wholeSource
            String pageId = sourceObject.getString("pageId");
            String appId = sourceObject.getString("appId");
            JSONArray newParamValueArr;
            if (paramValue instanceof JSONObject) {
                newParamValueArr = new JSONArray();
                newParamValueArr.add(paramValue);
            } else {
                newParamValueArr = (JSONArray) paramValue;
            }
            for (Object obj : newParamValueArr) {
                JSONObject newParamValue = (JSONObject) obj;
                JSONObject newObject = new JSONObject();
                JSONObject newAppParams = new JSONObject();
                String refererParam1 = sourceObject.getString("refererParam1");
                String fixedParam1 = sourceObject.getString("fixedParam1");
                String refererParam2 = sourceObject.getString("refererParam2");
                String fixedParam2 = sourceObject.getString("fixedParam2");
                String refererParam3 = sourceObject.getString("refererParam3");
                String fixedParam3 = sourceObject.getString("fixedParam3");
                String refererParam4 = sourceObject.getString("refererParam4");
                String fixedParam4 = sourceObject.getString("fixedParam4");
                if (StringUtils.isNotEmpty(refererParam1)) {
                    newObject.put(fixedParam1, Objects.isNull(newParamValue.get(refererParam1)) ? "" : newParamValue.get(refererParam1));
                }
                if (StringUtils.isNotEmpty(refererParam2)) {
                    newObject.put(fixedParam2, Objects.isNull(newParamValue.get(refererParam2)) ? "" : newParamValue.get(refererParam2));
                }
                if (StringUtils.isNotEmpty(refererParam3)) {
                    newObject.put(fixedParam3, Objects.isNull(newParamValue.get(refererParam3)) ? "" : newParamValue.get(refererParam3));
                }
                if (StringUtils.isNotEmpty(refererParam4)) {
                    newObject.put(fixedParam4, Objects.isNull(newParamValue.get(refererParam4)) ? "" : newParamValue.get(refererParam4));
                }

                // 判断是否为空
                if (TreeUtil.checkAllValuesEmpty(newObject)) {
                    JSONArray inputParam = sourceObject.getJSONArray("inputParam");
                    if (null != inputParam && !inputParam.isEmpty()) {
                        JSONArray newInputParam = new JSONArray();
                        inputParam.forEach(param -> {
                            JSONObject paramObj = (JSONObject) param;
                            JSONObject jsonObject = new JSONObject();
                            jsonObject.put("name", paramObj.getString("urlParam"));
                            String paramMapping = newParamValue.getString(paramObj.getString("paramMapping"));
                            if (newParamValue.containsKey(paramObj.getString("paramMapping"))) {
                                jsonObject.put("value", StringUtils.isEmpty(paramMapping) ? "" : paramMapping);
                            } else {
                                jsonObject.put("value", StringUtils.isEmpty(paramObj.getString("defaultValue")) ? "" : paramObj.getString("defaultValue"));
                            }
                            newAppParams.put(jsonObject.getString("name"), jsonObject.get("value"));
                            newInputParam.add(jsonObject);
                        });
                        newObject.put("params", newInputParam);
                        // 添加pageId
                        if (StringUtils.isNotEmpty(pageId)) {
                            newObject.put("pageId", pageId);
                        }
                    }
                    // 添加appId
                    if (StringUtils.isNotEmpty(appId)) {
                        newObject.put("appId", appId);
                        newAppParams.putAll(appParams);
                        newObject.put("appParams", newAppParams);
                    }
                    wholeSourceResult.add(newObject);
                }
            }
        }
        return JSONObject.toJSONString(wholeSourceResult);
    }

    @Override
    public String getAiAnswerMsgNo(KnowledgeBasePromptViewReq reqMsg) {
        String traceId = ParamUtil.getSessionNo("");
        Pair<String, Object> content = getPromptContentAndModuleCode(reqMsg);
        String knowledgeCode = content.getKey();
        Object promptContent = content.getValue();

        JSONObject param = new JSONObject();
        param.put("aisType", "");
        param.put("aiTransCode", "/chat/question");
        param.put("userId", "123456");
        param.put("msg", "提问");
        param.put("invokeMethod", "sse");
        param.put("promptAttachType", "15");
        param.put("clientId", "IRiskAPP");
        if (StringUtils.isNotEmpty(reqMsg.getLargeModelCode())) {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put(reqMsg.getLargeModelCode(), reqMsg.getContentDesc());
            param.put("largeModelCode", jsonObject);
        } else {
            param.put("largeModelCode", new JSONObject());
        }
        param.put("promptMsg", promptContent);

        String result = "";
        HubApiClient.ApiResult apiResult = hubApiClient.callS1101("RAI001", param);
        if (apiResult.isSuccess() && !apiResult.getDatas().isEmpty()) {
            JSONObject object = apiResult.getDatas().getJSONObject(0);
            result = object.getString("answerSessionMsgNo");
        }
        log.info("完成知识库[{}]文案预览，TraceId为[{}]！", knowledgeCode, traceId);
        return result;
    }

    @Override
    public AgentResult<?> insertKnowledgeBaseGroupInfo(KnowledgeBaseGroupReq reqMsg) {
        KnowledgeBaseGroupEntity knowledgeBaseGroupEntity = new KnowledgeBaseGroupEntity();
        BeanUtil.copyProperties(reqMsg, knowledgeBaseGroupEntity, true);
        knowledgeBaseGroupEntity.setInputTime(DateUtil.now());
        knowledgeBaseGroupEntity.setUpdateTime(DateUtil.now());
        if (Objects.isNull(reqMsg.getParentGroupId()) || StringUtils.isEmpty(reqMsg.getParentGroupId())) {
            knowledgeBaseGroupEntity.setParentGroupId("0");
        }
        knowledgeBaseGroupService.save(knowledgeBaseGroupEntity);
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> insertKnowledgeBaseParamsInfo(KnowledgeBaseParamsInfoSaveReq reqMsg) {
        if (doubleCheckKnowledge(reqMsg.getParamNo(), "")) {
            return AgentResult.error(ErrorMessageConstant.KNOWLEDGE_CODE_EXIST);
        }
        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = new KnowledgeBaseParamsEntity();
        BeanUtil.copyProperties(reqMsg, knowledgeBaseParamsEntity, true);
        if (CollectionUtils.isNotEmpty(reqMsg.getParamLabel())) {
            knowledgeBaseParamsEntity.setParamLabel(JSONObject.toJSONString(reqMsg.getParamLabel()));
        }
        knowledgeBaseParamsEntity.setModelNo("Public");
        knowledgeBaseParamsEntity.setParamType("OBJECT");
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        knowledgeBaseParamsEntity.setInputUserId(apiContextModel.getUserName());
        knowledgeBaseParamsEntity.setInputTime(DateUtil.now());
        knowledgeBaseParamsEntity.setUpdateUserId(apiContextModel.getUserName());
        knowledgeBaseParamsEntity.setUpdateTime(DateUtil.now());
        if (null != reqMsg.getInputParam() && !reqMsg.getInputParam().isEmpty()) {
            knowledgeBaseParamsEntity.setInputParam(JSONObject.toJSONString(reqMsg.getInputParam()));
        }
        knowledgeBaseParamsService.save(knowledgeBaseParamsEntity);
        executor.execute(() -> handleIndexParamConfig(knowledgeBaseParamsEntity, knowledgeBaseParamsEntity.getRelateIndexSet()));
        return AgentResult.OK();
    }

    @Override
    public JSONObject addDocumentKnowledge(DocumentKnowledgeReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isBlank(reqMsg.getDocumentId()) || StringUtils.isBlank(reqMsg.getRuleId())) {
            throw new AgentBizException("参数异常，documentId与ruleId不能为空！");
        }
        String documentId = reqMsg.getDocumentId();
        String documentName = reqMsg.getDocumentName();
        String ruleId = reqMsg.getRuleId();
        if (StringUtils.isNotBlank(documentName)) {
            int dotIndex = documentName.lastIndexOf(".");
            if (dotIndex > 0) {
                documentName = documentName.substring(0, dotIndex);
            }
        }
        String paramNo = "ComplianceCheck-" + documentId + "-" + ruleId;

        String lockKey = "add_document_knowledge_lock:" + documentId + ":" + ruleId;
        boolean locked = tryLock(lockKey, "1", 30);
        if (!locked) {
            throw new AgentBizException("系统繁忙，请稍后重试！");
        }
        try {
            String topGroupId = getOrCreateTopGroup();
            String childGroupId = getOrCreateChildGroup(topGroupId, documentId, documentName);
            String paramId = getOrCreateKnowledgeParam(childGroupId, paramNo);
            JSONObject result = new JSONObject();
            result.put("paramId", paramId);
            result.put("paramNo", paramNo);
            return result;
        } finally {
            releaseLock(lockKey);
        }
    }

    private String getOrCreateTopGroup() {
        LambdaQueryWrapper<KnowledgeBaseGroupEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(KnowledgeBaseGroupEntity::getParentGroupId, "0");
        queryWrapper.eq(KnowledgeBaseGroupEntity::getGroupValue, "documentGroup");
        queryWrapper.eq(KnowledgeBaseGroupEntity::getGroupType, "get_knowledge");
        KnowledgeBaseGroupEntity topGroup = knowledgeBaseGroupService.getOne(queryWrapper, false);
        if (Objects.nonNull(topGroup)) {
            return topGroup.getGroupId();
        }
        KnowledgeBaseGroupEntity newGroup = new KnowledgeBaseGroupEntity();
        newGroup.setGroupName("合规智能体中枢");
        newGroup.setGroupValue("documentGroup");
        newGroup.setGroupType("get_knowledge");
        newGroup.setParentGroupId("0");
        newGroup.setParentGroupName("");
        newGroup.setGroupStatus("1");
        newGroup.setInputTime(DateUtil.now());
        newGroup.setUpdateTime(DateUtil.now());
        knowledgeBaseGroupService.save(newGroup);
        return newGroup.getGroupId();
    }

    private String getOrCreateChildGroup(String topGroupId, String documentId, String documentName) {
        LambdaQueryWrapper<KnowledgeBaseGroupEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(KnowledgeBaseGroupEntity::getParentGroupId, topGroupId);
        queryWrapper.eq(KnowledgeBaseGroupEntity::getGroupValue, documentId);
        KnowledgeBaseGroupEntity childGroup = knowledgeBaseGroupService.getOne(queryWrapper, false);
        if (Objects.nonNull(childGroup)) {
            return childGroup.getGroupId();
        }
        KnowledgeBaseGroupEntity newGroup = new KnowledgeBaseGroupEntity();
        newGroup.setGroupName(documentName);
        newGroup.setGroupValue(documentId);
        newGroup.setGroupType("get_knowledge");
        newGroup.setParentGroupId(topGroupId);
        newGroup.setParentGroupName("合规智能体中枢");
        newGroup.setGroupStatus("1");
        newGroup.setInputTime(DateUtil.now());
        newGroup.setUpdateTime(DateUtil.now());
        knowledgeBaseGroupService.save(newGroup);
        return newGroup.getGroupId();
    }

    private String getOrCreateKnowledgeParam(String groupId, String paramNo) {
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(KnowledgeBaseParamsEntity::getGroupId, groupId);
        queryWrapper.eq(KnowledgeBaseParamsEntity::getParamNo, paramNo);
        KnowledgeBaseParamsEntity existParam = knowledgeBaseParamsService.getOne(queryWrapper, false);
        if (Objects.nonNull(existParam)) {
            existParam.setParamStatus(OnlineEnum.Y.name());
            existParam.setOnline(OnlineEnum.Y.name());
            knowledgeBaseParamsService.updateById(existParam);
            return existParam.getParamId();
        }

        KnowledgeBaseParamsEntity entity = new KnowledgeBaseParamsEntity();
        entity.setParamNo(paramNo);
        entity.setGroupId(groupId);
        entity.setParamName(paramNo);
        entity.setModelNo("Public");
        entity.setParamType("OBJECT");
        entity.setParamStatus(OnlineEnum.Y.name());
        entity.setOnline(OnlineEnum.Y.name());
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        entity.setInputUserId(apiContextModel.getUserName());
        entity.setInputTime(DateUtil.now());
        entity.setUpdateUserId(apiContextModel.getUserName());
        entity.setUpdateTime(DateUtil.now());
        knowledgeBaseParamsService.save(entity);
        return entity.getParamId();
    }

    private boolean tryLock(String key, String value, int expireSeconds) {
        try {
            long now = System.currentTimeMillis();
            long expireAt = now + expireSeconds * 1000L;
            // 原子抢锁：仅当 key 不存在或已过期时才放入，否则抢锁失败
            Long previous = localLocks.putIfAbsent(key, expireAt);
            if (previous == null) {
                return true;
            }
            // 已存在但已过期，则尝试通过原子替换抢占
            if (previous <= now) {
                if (localLocks.replace(key, previous, expireAt)) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            log.error("获取本地锁异常，key:{}", key, e);
            return false;
        }
    }

    private void releaseLock(String key) {
        try {
            localLocks.remove(key);
        } catch (Exception e) {
            log.error("释放本地锁异常，key:{}", key, e);
        }
    }

    @Override
    public Object unbindKnowledge(JSONObject reqMsg) {
        if (Objects.isNull(reqMsg)) {
            return AgentResult.error("参数异常，reqMsg不能为空！");
        }
        String paramId = reqMsg.getString("paramId");
        if (StringUtils.isBlank(paramId)) {
            return AgentResult.error("参数异常，paramId不能为空！");
        }
        String onLine = reqMsg.getString("onLine");
        if (StringUtils.isBlank(onLine)) {
            onLine = OnlineEnum.N.name();
        }
        if (!OnlineEnum.N.name().equalsIgnoreCase(onLine) && !OnlineEnum.Y.name().equalsIgnoreCase(onLine)) {
            return AgentResult.error("参数异常，onLine仅支持Y或N！");
        }
        LambdaUpdateWrapper<KnowledgeBaseParamsEntity> updateWrapper = Wrappers.lambdaUpdate();
        updateWrapper.eq(KnowledgeBaseParamsEntity::getParamId, paramId);
        updateWrapper.set(KnowledgeBaseParamsEntity::getOnline, onLine.toUpperCase());
        updateWrapper.set(KnowledgeBaseParamsEntity::getUpdateTime, DateUtil.now());
        return knowledgeBaseParamsService.update(updateWrapper) ? AgentResult.OK() : AgentResult.error("解绑失败！");
    }

    @Override
    public void handleIndexParamConfig(KnowledgeBaseParamsEntity knowledgeBaseParamsEntity, String relateIndexSet) {
        String knowledgeId = knowledgeBaseParamsEntity.getParamId();
        if (StringUtils.isEmpty(knowledgeBaseParamsEntity.getPrompt())) {
            return;
        }

        // 解析prompt信息，获取所有涉及的指标编号集合
        JSONArray promptCondGroups = JSONArray.parseArray(knowledgeBaseParamsEntity.getPrompt());
        Set<String> paramNoSet = getParamNoSet(promptCondGroups);
        if (CollectionUtils.isEmpty(paramNoSet)) {
            // 清空知识库关联指标
            knowledgeRelateIndexService.remove(new LambdaQueryWrapper<KnowledgeRelateIndexEntity>().eq(KnowledgeRelateIndexEntity::getKnowledgeId, knowledgeId).eq(KnowledgeRelateIndexEntity::getAddType, AddTypeEnum.BLAND.getValue()));
        }

        // 查询所有新增指标参数配置
        List<String> indexNoList = knowledgeRelateIndexService.getIndexListByKnowledgeId(knowledgeId, AddTypeEnum.ADD.getValue());
        indexNoList.addAll(paramNoSet);

        // 清空知识库关联指标参数配置
        if (CollectionUtils.isEmpty(indexNoList)) {
            if (StringUtils.isEmpty(knowledgeBaseParamsEntity.getToolId())) {
                removeToolParametersConfig(knowledgeBaseParamsEntity.getToolId());
            }
            if (StringUtils.isNotEmpty(knowledgeBaseParamsEntity.getOpenApiId())) {
                removeOpenApiParametersConfig(knowledgeBaseParamsEntity.getOpenApiId());
            }
            knowledgeBaseParamsService.updateRelateIndexSet(knowledgeId, "");
            return;
        }

        // 处理关联指标参数配置
        JSONArray allParentIndexList = new JSONArray();
        handleRelateIndexSet(knowledgeId, relateIndexSet, indexNoList, allParentIndexList);
        // 处理知识库关联指标
        handleKnowledgeRelateIndex(knowledgeId, paramNoSet, allParentIndexList);

        // 处理工具参数配置
        if (StringUtils.isEmpty(knowledgeBaseParamsEntity.getToolId())) {
            handleToolParametersConfig(knowledgeBaseParamsEntity, allParentIndexList);
        }

        // 处理openapi参数配置
        if (StringUtils.isNotEmpty(knowledgeBaseParamsEntity.getOpenApiId())) {
            handleOpenApiParametersConfig(knowledgeBaseParamsEntity, allParentIndexList);
        }
    }

    @Override
    public void handleInterfaceConfig(OpenApiConfEntity openApiConfEntity) {
        ExtIntfManageEntity extIntfManageEntity = extIntfManageService.getExtIntfManage(openApiConfEntity.getApiCode(), openApiConfEntity.getProviderId());
        if (Objects.isNull(extIntfManageEntity)) {
            return;
        }
        openApiConfEntity.setApiDesc(extIntfManageEntity.getIntfName());
        openApiConfEntity.setHttpMethod(extIntfManageEntity.getIntfRequestType());
        openApiConfEntity.setUpstreamPath(extIntfManageEntity.getIntfPath());
        List<ExtIntfParamManageEntity> extIntfParamManageEntityList =
                extIntfParamManageService.listExtIntfParamManage(openApiConfEntity.getProviderId(), extIntfManageEntity.getIntfNo());
        if (CollectionUtils.isEmpty(extIntfParamManageEntityList)) {
            return;
        }
        // 原始参数配置
        List<OpenApiConfEntity.RequestParam> requestParams = openApiConfEntity.getRequestParams();
        List<OpenApiConfEntity.RequestParam> paramsInfoArr = new ArrayList<>();
        for (ExtIntfParamManageEntity index : extIntfParamManageEntityList) {
            String field = index.getParamCode();
            if (paramsInfoArr.stream().anyMatch(item -> item.getName().equals(field))) {
                continue;
            }
            if (StringUtils.isNotEmpty(field) && (Objects.nonNull(requestParams) && requestParams.stream().anyMatch(item -> item.getName().equals(field)))) {
                OpenApiConfEntity.RequestParam object = requestParams.stream().filter(item -> item.getName().equals(field)).findFirst().orElseThrow(() -> new IllegalStateException("请求参数配置不存在: " + field));
                object.setType(IntfParamTypeEnum.getById(index.getParamType()).name);
                paramsInfoArr.add(object);
                continue;
            }
            OpenApiConfEntity.RequestParam paramsInfo = new OpenApiConfEntity.RequestParam();
            paramsInfo.setRequired(!Objects.equals(index.getParamIsRequired(), "0"));
            paramsInfo.setName(field);
            paramsInfo.setDescription(index.getParamName());
            paramsInfo.setType(IntfParamTypeEnum.getById(index.getParamType()).name);
            paramsInfo.setEnums(new ArrayList<>());
            String defaultValue = index.getParamValue();
            if (StringUtils.isNotEmpty(defaultValue) && defaultValue.startsWith("'") && defaultValue.endsWith("'")) {
                defaultValue = defaultValue.substring(1, defaultValue.length() - 1);
            }
            paramsInfo.setToolParamFlag(false);
            paramsInfo.setDefaultValue(defaultValue);
            paramsInfo.setLocation("body");
            paramsInfoArr.add(paramsInfo);
        }
        openApiConfEntity.setRequestParams(paramsInfoArr);
    }

    private void removeOpenApiParametersConfig(String openApiId) {
        OpenApiConfEntity openApiConfEntity = new OpenApiConfEntity();
        openApiConfEntity.setId(openApiId);
        openApiConfEntity.setRequestParams(Collections.emptyList());
        openApiConfMapper.updateById(openApiConfEntity);
    }

    private void removeToolParametersConfig(String toolId) {
        ToolManagementEntity toolManagementEntity = new ToolManagementEntity();
        toolManagementEntity.setId(toolId);
        toolManagementEntity.setToolParameters("");
        toolManagementMapper.updateById(toolManagementEntity);
    }

    private void handleOpenApiParametersConfig(KnowledgeBaseParamsEntity knowledgeBaseParamsEntity, JSONArray allParentIndexList) {
        LambdaQueryWrapper<OpenApiConfEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(OpenApiConfEntity::getId, knowledgeBaseParamsEntity.getOpenApiId());
        List<OpenApiConfEntity> openApiConfEntityList = openApiConfMapper.selectList(queryWrapper);
        if (CollectionUtils.isEmpty(openApiConfEntityList)) {
            return;
        }

        openApiConfEntityList.forEach(tool -> {
            List<OpenApiConfEntity.RequestParam> paramsInfoArr = new ArrayList<>();
            // 参数相关信息
            if (CollectionUtils.isNotEmpty(allParentIndexList)) {
                // 原始参数配置
                List<OpenApiConfEntity.RequestParam> finalToolParameters = tool.getRequestParams();
                allParentIndexList.forEach(index -> {
                    JSONObject json = (JSONObject) index;
                    JSONArray params = json.getJSONArray("params");
                    if (Objects.nonNull(params) && !params.isEmpty()) {
                        for (Object obj : params) {
                            JSONObject param = (JSONObject) obj;
                            String sField = "";
                            // 优先从细类字段取
                            String sourceField = param.getString("sourceField");
                            if (StringUtils.isNotEmpty(sourceField)) {
                                String[] split = sourceField.split("-");
                                int idx = split.length == 3 ? 2 : (split.length == 2 ? 1 : -1);
                                if (idx != -1) {
                                    sField = split[idx];
                                }
                                if (split.length > 3) {
                                    int ind = sourceField.indexOf("-", split[0].length() + 1);
                                    sField = sourceField.substring(ind + 1);
                                }
                            }
                            String field = StringUtils.isEmpty(sField) ? param.getString("field") : sField;
                            if (paramsInfoArr.stream().anyMatch(item -> item.getName().equals(field))) {
                                continue;
                            }
                            if (StringUtils.isNotEmpty(field) && (Objects.nonNull(finalToolParameters) && finalToolParameters.stream().anyMatch(item -> item.getName().equals(field)))) {
                                OpenApiConfEntity.RequestParam object = finalToolParameters.stream().filter(item -> item.getName().equals(field)).findFirst().orElseThrow(() -> new IllegalStateException("工具参数配置不存在: " + field));
                                object.setType(param.getString("fieldType"));
                                paramsInfoArr.add(object);
                                continue;
                            }
                            OpenApiConfEntity.RequestParam paramsInfo = new OpenApiConfEntity.RequestParam();
                            paramsInfo.setRequired(param.getBoolean("required"));
                            paramsInfo.setName(field);
                            paramsInfo.setDescription(StringUtils.isEmpty(param.getString("fieldName")) ? "" : param.getString("fieldName"));
                            paramsInfo.setType(StringUtils.isEmpty(param.getString("fieldType")) ? "" : param.getString("fieldType"));
                            paramsInfo.setEnums(new ArrayList<>());
                            // 判断defaultValue是否已'开头，且已'结尾,则去除头尾的'
                            String defaultValue = param.getString("defaultValue");
                            if (StringUtils.isNotEmpty(defaultValue) && defaultValue.startsWith("'") && defaultValue.endsWith("'")) {
                                defaultValue = defaultValue.substring(1, defaultValue.length() - 1);
                            }
                            paramsInfo.setToolParamFlag(false);
                            paramsInfo.setDefaultValue(defaultValue);
                            paramsInfo.setLocation("body");
                            paramsInfoArr.add(paramsInfo);
                        }
                    }
                });
            }

            if (!paramsInfoArr.isEmpty()) {
                OpenApiConfEntity openApiConfEntity = new OpenApiConfEntity();
                openApiConfEntity.setId(tool.getId());
                openApiConfEntity.setRequestParams(paramsInfoArr);
                openApiConfMapper.updateById(openApiConfEntity);
            }
        });
    }


    private void handleToolParametersConfig(KnowledgeBaseParamsEntity knowledgeBaseParamsEntity, JSONArray allParentIndexList) {
        LambdaQueryWrapper<ToolManagementEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(ToolManagementEntity::getId, knowledgeBaseParamsEntity.getToolId());
        List<ToolManagementEntity> toolManagementEntityList = toolManagementMapper.selectList(queryWrapper);
        if (CollectionUtils.isEmpty(toolManagementEntityList)) {
            return;
        }

        toolManagementEntityList.forEach(tool -> {
            JSONArray paramsInfoArr = new JSONArray();
            // 参数相关信息
            if (CollectionUtils.isNotEmpty(allParentIndexList)) {
                // 原始参数配置
                JSONArray toolParameters = null;
                if (StringUtils.isNotEmpty(tool.getToolParameters())) {
                    toolParameters = JSONArray.parseArray(tool.getToolParameters());
                }
                JSONArray finalToolParameters = toolParameters;
                allParentIndexList.forEach(index -> {
                    JSONObject json = (JSONObject) index;
                    JSONArray params = json.getJSONArray("params");
                    if (Objects.nonNull(params) && !params.isEmpty()) {
                        for (Object obj : params) {
                            JSONObject param = (JSONObject) obj;
                            // 优先从细类字段取
                            String sField = "";
                            String sourceField = param.getString("sourceField");
                            if (StringUtils.isNotEmpty(sourceField)) {
                                String[] split = sourceField.split("-");
                                int idx = split.length == 3 ? 2 : (split.length == 2 ? 1 : -1);
                                if (idx != -1) {
                                    sField = split[idx];
                                }
                                if (split.length > 3) {
                                    int ind = sourceField.indexOf("-", split[0].length() + 1);
                                    sField = sourceField.substring(ind + 1);
                                }
                            }
                            String field = StringUtils.isEmpty(sField) ? param.getString("field") : sField;
                            if (paramsInfoArr.stream().anyMatch(item -> ((JSONObject) item).getString("name").equals(field))) {
                                continue;
                            }
                            if (StringUtils.isNotEmpty(field) && (Objects.nonNull(finalToolParameters) && finalToolParameters.stream().anyMatch(item -> ((JSONObject) item).getString("name").equals(field)))) {
                                Object object = finalToolParameters.stream().filter(item -> ((JSONObject) item).getString("name").equals(field)).findFirst().orElseThrow(() -> new IllegalStateException("工具参数配置不存在: " + field));
                                ((JSONObject) object).put("type", param.getString("fieldType"));
                                paramsInfoArr.add(object);
                                continue;
                            }
                            JSONObject paramsInfo = new JSONObject();
                            paramsInfo.put("is_required", StringUtils.isEmpty(param.getString("isRequired")) ? true : param.getString("isRequired"));
                            paramsInfo.put("name", field);
                            paramsInfo.put("description", StringUtils.isEmpty(param.getString("fieldName")) ? "" : param.getString("fieldName"));
                            paramsInfo.put("type", StringUtils.isEmpty(param.getString("fieldType")) ? "" : param.getString("fieldType"));
                            paramsInfo.put("enum", new JSONArray());
                            // 判断defaultValue是否已'开头，且已'结尾,则去除头尾的'
                            String defaultValue = param.getString("defaultValue");
                            if (StringUtils.isNotEmpty(defaultValue) && defaultValue.startsWith("'") && defaultValue.endsWith("'")) {
                                defaultValue = defaultValue.substring(1, defaultValue.length() - 1);
                            }
                            paramsInfo.put("default", defaultValue);
                            paramsInfo.put("example", param.getString("example"));
                            paramsInfoArr.add(paramsInfo);
                        }
                    }
                });
            }

            if (!paramsInfoArr.isEmpty()) {
                ToolManagementEntity toolManagementEntity = new ToolManagementEntity();
                toolManagementEntity.setId(tool.getId());
                toolManagementEntity.setToolParameters(paramsInfoArr.toJSONString());
                toolManagementMapper.updateById(toolManagementEntity);
            }
        });
    }

    @Override
    public void handleKnowledgeRelateIndex(String knowledgeId, Set<String> indexNoSet, JSONArray allParentIndexList) {
        // 文案中没有关联指标
        if (CollectionUtils.isEmpty(allParentIndexList)) {
            return;
        }
        List<IndexParamsEntity> indexParamsEntityList = indexParamsService.listByIds(indexNoSet);
        if (CollectionUtils.isEmpty(indexParamsEntityList)) {
            return;
        }
        // 先查询知识库关联指标
        List<KnowledgeRelateIndexEntity> existKnowledgeRelateIndexList = knowledgeRelateIndexService.list(new LambdaQueryWrapper<KnowledgeRelateIndexEntity>().eq(KnowledgeRelateIndexEntity::getKnowledgeId, knowledgeId).eq(KnowledgeRelateIndexEntity::getAddType, AddTypeEnum.BLAND.getValue()));
        // 对比是否有新增关联指标
        Set<String> deleteIndexNoSet = new HashSet<>();
        List<IndexParamsEntity> newIndexList = indexParamsEntityList;
        if (CollectionUtils.isNotEmpty(existKnowledgeRelateIndexList)) {
            Set<String> existIndexNoSet = existKnowledgeRelateIndexList.stream().map(KnowledgeRelateIndexEntity::getIndexNo).collect(Collectors.toSet());
            newIndexList = indexParamsEntityList.stream().filter(item -> !existIndexNoSet.contains(item.getParamNo())).collect(Collectors.toList());
            deleteIndexNoSet = existIndexNoSet.stream().filter(item -> !indexNoSet.contains(item)).collect(Collectors.toSet());
        }
        // 新增关联指标
        if (CollectionUtils.isNotEmpty(newIndexList)) {
            List<KnowledgeRelateIndexEntity> knowledgeRelateIndexList = newIndexList.stream().map(item -> {
                KnowledgeRelateIndexEntity knowledgeRelateIndexEntity = new KnowledgeRelateIndexEntity();
                knowledgeRelateIndexEntity.setKnowledgeId(knowledgeId);
                knowledgeRelateIndexEntity.setIndexNo(item.getParamNo());
                knowledgeRelateIndexEntity.setIndexName(item.getParamName());
                knowledgeRelateIndexEntity.setIndexType(item.getParamType());
                knowledgeRelateIndexEntity.setAddType(AddTypeEnum.BLAND.getValue());
                knowledgeRelateIndexEntity.setParentIndexNo(StringUtils.isEmpty(item.getOtherNo()) ? item.getParentParamNo() : item.getOtherNo());
                List<JSONObject> parentIndexList = allParentIndexList.stream().map(index -> (JSONObject) index).filter(index -> index.getString("paramNo").equals(item.getParentParamNo())).collect(Collectors.toList());
                if (CollectionUtils.isNotEmpty(parentIndexList)) {
                    JSONObject parentIndex = parentIndexList.get(0);
                    knowledgeRelateIndexEntity.setSupplierId(parentIndex.getString("supplierId"));
                    knowledgeRelateIndexEntity.setIntfNo(parentIndex.getString("intfNo"));
                }
                return knowledgeRelateIndexEntity;
            }).collect(Collectors.toList());
            knowledgeRelateIndexService.saveBatch(knowledgeRelateIndexList);
        }
        // 删除关联指标
        if (CollectionUtils.isNotEmpty(deleteIndexNoSet)) {
            knowledgeRelateIndexService.remove(new LambdaQueryWrapper<KnowledgeRelateIndexEntity>().eq(KnowledgeRelateIndexEntity::getKnowledgeId, knowledgeId).in(KnowledgeRelateIndexEntity::getIndexNo, deleteIndexNoSet));
        }
    }

    @Override
    public void copyKnowledgeBaseParamsInfo(KnowledgeBaseParamsInfoSaveReq reqMsg) {
        String selectKnowledgeId = reqMsg.getSelectKnowledgeId();
        if (StringUtils.isEmpty(selectKnowledgeId)) {
            throw new AgentBizException("复制失败，未选择待复制的知识库！");
        }

        KnowledgeBaseParamsEntity selectKnowledge = knowledgeBaseParamsService.getById(selectKnowledgeId);
        if (Objects.isNull(selectKnowledge)) {
            throw new AgentBizException("复制失败，选择的知识库不存在！");
        }

        String paramName = selectKnowledge.getParamName() + "_copy";
        String paramNo = selectKnowledge.getParamNo() + "_copy";
        if (doubleCheckKnowledge(paramNo, "")) {
            paramName = selectKnowledge.getParamName() + "_copy_" + System.currentTimeMillis();
            paramNo = selectKnowledge.getParamNo() + "_copy_" + System.currentTimeMillis();
        }

        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = new KnowledgeBaseParamsEntity();
        BeanUtil.copyProperties(selectKnowledge, knowledgeBaseParamsEntity, true);
        knowledgeBaseParamsEntity.setParamId(null);
        knowledgeBaseParamsEntity.setOnline(null);
        knowledgeBaseParamsEntity.setPromptType(null);
        knowledgeBaseParamsEntity.setGroupId(reqMsg.getGroupId());
        knowledgeBaseParamsEntity.setParamName(paramName);
        knowledgeBaseParamsEntity.setParamNo(paramNo);
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        knowledgeBaseParamsEntity.setInputUserId(apiContextModel.getUserName());
        knowledgeBaseParamsEntity.setInputTime(DateUtil.now());
        knowledgeBaseParamsEntity.setUpdateUserId(apiContextModel.getUserName());
        knowledgeBaseParamsEntity.setUpdateTime(DateUtil.now());
        knowledgeBaseParamsService.save(knowledgeBaseParamsEntity);
    }

    @Override
    public void moveKnowledgeBaseParamsInfo(KnowledgeBaseParamsInfoSaveReq reqMsg) {
        String selectKnowledgeId = reqMsg.getSelectKnowledgeId();
        String groupId = reqMsg.getGroupId();
        if (StringUtils.isEmpty(selectKnowledgeId) || StringUtils.isEmpty(groupId)) {
            throw new AgentBizException("请求参数异常，移动失败！");
        }

        KnowledgeBaseParamsEntity selectKnowledge = knowledgeBaseParamsService.getById(selectKnowledgeId);
        if (Objects.isNull(selectKnowledge)) {
            throw new AgentBizException("移动失败，选择的知识库不存在！");
        }

        KnowledgeBaseGroupEntity knowledgeBaseGroupEntity = knowledgeBaseGroupService.getById(groupId);
        if (Objects.isNull(knowledgeBaseGroupEntity)) {
            throw new AgentBizException("移动失败，选择的知识库分组不存在！");
        }

        // 判断分组是否是全部
        String groupName = knowledgeBaseGroupEntity.getGroupName();
        if ("全部".equals(groupName)) {
            groupId = knowledgeBaseGroupEntity.getParentGroupId();
        }

        selectKnowledge.setGroupId(groupId);
        knowledgeBaseParamsService.updateById(selectKnowledge);
    }

    @Override
    public ListResult<?> queryKnowledgeBaseParamsList(KnowledgeBaseParamReq reqMsg) {
        if (StringUtils.isNotEmpty(reqMsg.getParentGroupId())) {
            KnowledgeBaseGroupEntity groupEntity = knowledgeBaseGroupService.getById(reqMsg.getGroupId());
            if (groupEntity != null && groupEntity.getGroupName().equals("全部")) {
                reqMsg.setGroupId(reqMsg.getParentGroupId());
            }
        }
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getOnline()), KnowledgeBaseParamsEntity::getOnline, reqMsg.getOnline());
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParamStatus()), KnowledgeBaseParamsEntity::getParamStatus, reqMsg.getParamStatus());
        queryWrapper.like(StringUtils.isNotEmpty(reqMsg.getParamNo()), KnowledgeBaseParamsEntity::getParamNo, reqMsg.getParamNo());
        queryWrapper.like(StringUtils.isNotEmpty(reqMsg.getParamName()), KnowledgeBaseParamsEntity::getParamName, reqMsg.getParamName());
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParentParamId()), KnowledgeBaseParamsEntity::getParentParamId, reqMsg.getParentParamId());
        queryWrapper.orderByDesc(KnowledgeBaseParamsEntity::getInputTime);
        if (StringUtils.isNotEmpty(reqMsg.getGroupId())) {
            queryWrapper.eq(KnowledgeBaseParamsEntity::getGroupId, reqMsg.getGroupId());
        }

        List<KnowledgeBaseParamsEntity> indexParamsEntityList = knowledgeBaseParamsService.list(queryWrapper);
        if (CollectionUtils.isEmpty(indexParamsEntityList)) {
            return new ListResult<>(0, 0);
        }

        List<KnowledgeBaseParamsDTO> indexParamsDTOList = new ArrayList<>();
        // 判断角色是否有知识库权限
        List<String> roleKnowledgeIds = new ArrayList<>();
        if (StringUtils.isNotEmpty(reqMsg.getRoleId())) {
            LambdaQueryWrapper<SysRoleKnowledgeOutputEntity> roleKnowledgeWrapper = new LambdaQueryWrapper<>();
            roleKnowledgeWrapper.eq(SysRoleKnowledgeOutputEntity::getRoleId, reqMsg.getRoleId());
            roleKnowledgeWrapper.eq(SysRoleKnowledgeOutputEntity::getGroupId, reqMsg.getGroupId());
            List<SysRoleKnowledgeOutputEntity> roleKnowledgeList = sysRoleKnowledgeOutputService.list(roleKnowledgeWrapper);
            roleKnowledgeIds = roleKnowledgeList.stream().map(SysRoleKnowledgeOutputEntity::getKnowledgeId).collect(java.util.stream.Collectors.toList());
        }

        List<String> finalRoleKnowledgeIds = roleKnowledgeIds;
        indexParamsEntityList.forEach(param -> {
            KnowledgeBaseParamsDTO indexParamsDTO = new KnowledgeBaseParamsDTO();
            BeanUtil.copyProperties(param, indexParamsDTO, true);
            if (finalRoleKnowledgeIds.contains(indexParamsDTO.getParamId())) {
                indexParamsDTO.setHasAuth(true);
            }
            if (StringUtils.isNotEmpty(param.getInputParam())) {
                try {
                    indexParamsDTO.setInputParam(JSONObject.parseArray(param.getInputParam()));
                } catch (Exception e) {
                    log.error("解析输入参数{}失败，失败原因：{}", param.getInputParam(), ExceptionUtils.getStackTrace(e));
                }
            }
            indexParamsDTOList.add(indexParamsDTO);
        });
        return new ListResult<>(indexParamsDTOList);
    }

    @Override
    public ListResult<?> pageKnowledgeBaseParamsList(KnowledgeBaseParamReq reqMsg) {
        List<String> knowledgeIdList = getKnowledgeIdListByRoleId();
        if (CollectionUtils.isEmpty(knowledgeIdList)) {
            return new ListResult<>(0, 0);
        }

        if (StringUtils.isNotEmpty(reqMsg.getParentGroupId())) {
            KnowledgeBaseGroupEntity groupEntity = knowledgeBaseGroupService.getById(reqMsg.getGroupId());
            if (groupEntity != null && groupEntity.getGroupName().equals("全部")) {
                reqMsg.setGroupId(reqMsg.getParentGroupId());
            }
        }
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getOnline()), KnowledgeBaseParamsEntity::getOnline, reqMsg.getOnline());
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParamStatus()), KnowledgeBaseParamsEntity::getParamStatus, reqMsg.getParamStatus());
        queryWrapper.like(StringUtils.isNotEmpty(reqMsg.getParamNo()), KnowledgeBaseParamsEntity::getParamNo, reqMsg.getParamNo());
        queryWrapper.like(StringUtils.isNotEmpty(reqMsg.getParamName()), KnowledgeBaseParamsEntity::getParamName, reqMsg.getParamName());
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParentParamId()), KnowledgeBaseParamsEntity::getParentParamId, reqMsg.getParentParamId());
        queryWrapper.orderByDesc(KnowledgeBaseParamsEntity::getInputTime);
        if (StringUtils.isNotEmpty(reqMsg.getGroupId())) {
            queryWrapper.eq(KnowledgeBaseParamsEntity::getGroupId, reqMsg.getGroupId());
        }
        if (CollectionUtils.isNotEmpty(knowledgeIdList)) {
            queryWrapper.in(CollectionUtils.isNotEmpty(knowledgeIdList), KnowledgeBaseParamsEntity::getGroupId, knowledgeIdList);
        }

        Page<KnowledgeBaseParamsEntity> page = new Page<>(reqMsg.getPageIndex(), reqMsg.getPageSize());
        IPage<KnowledgeBaseParamsEntity> pageList = knowledgeBaseParamsService.page(page, queryWrapper);
        if (CollectionUtils.isEmpty(pageList.getRecords())) {
            return new ListResult<>(0, 0);
        }
        return new ListResult<>((int) pageList.getTotal(), reqMsg.getPageSize(), reqMsg.getPageIndex(), pageList.getRecords());
    }

    @Override
    public AgentResult<?> deleteKnowledgeBaseParamsInfo(String paramId) {
        boolean delete = knowledgeBaseParamsService.removeById(paramId);
        if (delete) {
            QueryWrapper<KnowledgeBaseParamsEntity> queryWrapper = new QueryWrapper<>();
            queryWrapper.eq("parentParamId", paramId);
            List<KnowledgeBaseParamsEntity> list = knowledgeBaseParamsService.list(queryWrapper);
            if (list != null) {
                for (KnowledgeBaseParamsEntity indexParams : list) {
                    deleteKnowledgeBaseParamsInfo(indexParams.getParamNo());
                }
            }
        }
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> queryKnowledgeBaseParamsInfo(KnowledgeBaseParamsInfoReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isBlank(reqMsg.getParamId())) {
            return AgentResult.error("参数异常，paramId不能为空！");
        }
        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = knowledgeBaseParamsService.getById(reqMsg.getParamId());
        if (Objects.isNull(knowledgeBaseParamsEntity)) {
            return AgentResult.error("未查询到相关数据！");
        }
        KnowledgeBaseParamsDTO knowledgeBaseParamsDTO = new KnowledgeBaseParamsDTO();
        BeanUtil.copyProperties(knowledgeBaseParamsEntity, knowledgeBaseParamsDTO);
        if (StringUtils.isNotEmpty(knowledgeBaseParamsEntity.getParamLabel())) {
            knowledgeBaseParamsDTO.setParamLabel(JSONObject.parseArray(knowledgeBaseParamsEntity.getParamLabel()));
        }
        if (StringUtils.isNotEmpty(knowledgeBaseParamsEntity.getInputParam())) {
            knowledgeBaseParamsDTO.setInputParam(JSONObject.parseArray(knowledgeBaseParamsEntity.getInputParam()));
        } else {
            knowledgeBaseParamsDTO.setInputParam(new JSONArray());
        }
        // 判断输出要求权限
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        String role = apiContextModel.getRole();
        if (StringUtils.isNotEmpty(role)) {
            List<String> roleIdList = JSON.parseArray(role, String.class);
            boolean hasAuth = sysRoleKnowledgeOutputService.checkKnowledgeOutputAuth(roleIdList, reqMsg.getParamId());
            knowledgeBaseParamsDTO.setHasAuth(hasAuth);
        }
        return AgentResult.OK(knowledgeBaseParamsDTO);
    }

    @Override
    public AgentResult<?> updateKnowledgeBaseParamsInfo(KnowledgeBaseParamsInfoSaveReq reqMsg) {
        String knowledgeId = reqMsg.getParamId();
        KnowledgeBaseParamsEntity originEntity = knowledgeBaseParamsService.getById(knowledgeId);
        if (Objects.isNull(originEntity)) {
            return AgentResult.error("未查询到相关数据！");
        }

        if (doubleCheckKnowledge(reqMsg.getParamNo(), knowledgeId)) {
            return AgentResult.error(ErrorMessageConstant.KNOWLEDGE_CODE_EXIST);
        }

        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = new KnowledgeBaseParamsEntity();
        BeanUtil.copyProperties(reqMsg, knowledgeBaseParamsEntity, true);
        knowledgeBaseParamsEntity.setUpdateTime(DateUtil.now());
        knowledgeBaseParamsEntity.setUpdateUserId(ApiContext.getApiContextModel().getUserName());
        if (CollectionUtils.isNotEmpty(reqMsg.getInputParam())) {
            knowledgeBaseParamsEntity.setInputParam(JSONObject.toJSONString(reqMsg.getInputParam()));
        }
        try {
            String largeModelCode = reqMsg.getLargeModelCode();
            if (StringUtils.isNotEmpty(largeModelCode)) {
                String largeModelContent = originEntity.getLargeModelContent();
                JSONObject jsonObject;
                if (StringUtils.isNotEmpty(largeModelContent)) {
                    jsonObject = JSONObject.parseObject(largeModelContent);
                    jsonObject.put(largeModelCode, reqMsg.getContentDesc());
                } else {
                    jsonObject = new JSONObject();
                    jsonObject.put(largeModelCode, reqMsg.getContentDesc());
                }
                knowledgeBaseParamsEntity.setLargeModelContent(jsonObject.toJSONString());
            }
        } catch (Exception e) {
            log.error("解析不同大模型对应的输出要求异常，异常信息{}！", ExceptionUtils.getStackTrace(e));
        }
        knowledgeBaseParamsService.updateById(knowledgeBaseParamsEntity);
        // 当更新内容为prompt，则异步处理关联指标配置信息
        if (YesOrNoEnum.Y.code.equalsIgnoreCase(reqMsg.getRelateFlag())) {
            KnowledgeBaseParamsEntity updatedEntity = knowledgeBaseParamsService.getById(knowledgeId);
            executor.execute(() -> handleIndexParamConfig(updatedEntity, originEntity.getRelateIndexSet()));
        }
        return AgentResult.OK();
    }

    @Override
    public Map<String, Object> handleParam(String relateIndexSet, JSONObject params, List<String> paramNoList, Map<String, Object> cascadeMap, Map<String, Object> paramGroupResultMap) {
        if (CollectionUtils.isEmpty(paramNoList)) {
            return null;
        }

        // 从结果集中，获取各类指标的结果
        Map<String, Object> returnResult = Maps.newHashMap();

        List<IndexParamsEntity> indexParamsEntityList = indexParamsService.listByIds(paramNoList);
        if (CollectionUtils.isEmpty(indexParamsEntityList)) {
            return null;
        }

        // 开始从知识库code取数据
        List<IndexParamsEntity> codeIndexParamsList = indexParamsEntityList.stream().filter(index -> StringUtils.isNotEmpty(index.getScriptType()) && index.getScriptType().equalsIgnoreCase(ScriptTypeEnum.KNOWLEDGE_CODE.id)).collect(Collectors.toList());
        if (CollectionUtils.isNotEmpty(codeIndexParamsList)){
            log.info("======getKnowledgeCode===开始");
            codeIndexParamsList.forEach(e->{
                log.info("======getKnowledgeCode===id:"+e.getParamNo());
                JSONObject scriptJo = JSONObject.parseObject(e.getScript());
                if(params != null){
                    for(String key : params.keySet()){
                           if(!"moduleCode".equals(key) && !"withModelSummary".equals(key) && !"traceId".equals(key)){
                            scriptJo.put(key, params.get(key));
                        }
                    }
                }
                scriptJo.put("stream",false);
                String value = getKnowledgeCode(scriptJo.toJSONString());
                returnResult.put(e.getParamNo(),value);
            });
        }

        // 全局日志存储组装桶，用于线索查询
        String moduleCode = params.getString("moduleCode");
        String traceId = params.getString("traceId");
        List<KnowledgeQueryResultEntity> logEntityList = new CopyOnWriteArrayList<>();

        // 开始从参数集取数
        List<IndexParamsEntity> paramSetIndexParamsList = indexParamsEntityList.stream().filter(index -> StringUtils.isNotEmpty(index.getScriptType()) && index.getScriptType().equalsIgnoreCase(ScriptTypeEnum.PARAM_SET.id)).collect(Collectors.toList());
        handleParamSetIndex(paramSetIndexParamsList, params, paramGroupResultMap);

        // 开始从API接口取数据
        List<IndexParamsEntity> apiIndexParamsList = indexParamsEntityList.stream().filter(index -> StringUtils.isNotEmpty(index.getScriptType()) && index.getScriptType().equalsIgnoreCase(ScriptTypeEnum.API.id)).collect(Collectors.toList());

        ExecutorCompletionService<String> completionService = new ExecutorCompletionService<>(fetchDataThreadPool);
        List<Future<String>> futures = new ArrayList<>();

        // 提取创建 logSupplier 的逻辑到单独的方法
        Supplier<KnowledgeQueryResultEntity> logSupplier = () -> {
            KnowledgeQueryResultEntity logEntity = new KnowledgeQueryResultEntity();
            logEntity.setKnowledgeCode(moduleCode);
            logEntity.setTraceId(traceId);
            return logEntity;
        };
        if (CollectionUtils.isNotEmpty(apiIndexParamsList)) {
            List<IndexParamsEntity> oneAllParams = new ArrayList<>();
            getAllParamsByParentParamNo(apiIndexParamsList, oneAllParams);
            // 过滤oneAllParams中已查询过的指标
            List<IndexParamsEntity> notExistsOneAllParams = oneAllParams.stream().filter(index -> !paramGroupResultMap.containsKey(index.getParamNo())).collect(Collectors.toList());
            apiIndexParamsList.forEach(param -> param.setParent(oneAllParams.stream().filter(one -> one.getParamNo().equals(param.getParentParamNo())).findFirst().orElse(null)));
            // 启用多线程从api接口获取数据
            notExistsOneAllParams.forEach(index -> futures.add(completionService.submit(() -> {
                String paramNo = index.getParamNo();
                IndexParamsEntity parent = index.getParent();
                String supplierId = index.getSupplierId();
                String intfNo = index.getIntfNo();
                String intfParams = index.getIntfParams();
                if (Objects.nonNull(parent)) {
                    paramNo = parent.getParamNo();
                    supplierId = parent.getSupplierId();
                    intfNo = parent.getIntfNo();
                    intfParams = parent.getIntfParams();
                }
                try {
                    // 接口传参综合解析（包含：指标配置层、页面手动添加、大模型传参）
                    JSONArray jsonArray = StringUtils.isNotEmpty(intfParams) ? JSON.parseArray(intfParams) : new JSONArray();
                    JSONObject paramJson = new JSONObject();
                    if (null != jsonArray && !jsonArray.isEmpty()) {
                        jsonArray.forEach(json -> {
                            JSONObject object = (JSONObject) json;
                            object.keySet().forEach(obj -> {
                                JSONObject value = object.getJSONObject(obj);
                                if (Objects.nonNull(value)) {
                                    JSONObject relateIndex = value.getJSONObject("relateIndex");
                                    if (Objects.nonNull(relateIndex) && StringUtils.isNotEmpty(relateIndex.getString("no"))) {
                                        // 特殊处理： 接口的关联参数取值
                                        paramJson.put(obj, cascadeMap.get(relateIndex.getString("no")));
                                    } else {
                                        paramJson.put(obj, value.get("value"));
                                    }
                                }
                            });
                        });
                    }
                    if (!params.isEmpty()) {
                        paramJson.putAll(params);
                    }
                    String result = "";
                    String publicParam = "";
                    long start = System.currentTimeMillis();
                    Map<String, String> dataMap = extIntfParamManageService.getIntfData(paramNo, supplierId, intfNo, paramJson, jsonArray, relateIndexSet);
                    int costTime = (int) (System.currentTimeMillis() - start);
                    if (null != dataMap && !dataMap.isEmpty()) {
                        for (Map.Entry<String, String> entry : dataMap.entrySet()) {
                            result = entry.getValue();
                            publicParam = entry.getKey();
                            break;
                        }
                        paramGroupResultMap.put(paramNo, JSONObject.parseObject(result));
                    }
                    // 存储日志信息
                    KnowledgeQueryResultEntity logEntity = logSupplier.get();
                    logEntity.setCostTime(costTime);
                    logEntity.setIntfNo(intfNo);
                    logEntity.setQueryType(1);
                    logEntity.setSupplierId(supplierId);
                    logEntity.setQueryTime(DateUtil.now());
                    logEntity.setIntfParam(publicParam);
                    logEntity.setQueryResult(result);
                    logEntityList.add(logEntity);
                } catch (Exception e) {
                    log.error("查询接口[{}][{}]数据异常，异常信息为{}！", supplierId + "-" + intfNo, intfParams, ExceptionUtils.getStackTrace(e));
                }
                return "";
            })));
        }

        // 开始从数据源取数据
        List<IndexParamsEntity> sqlIndexParamsList = indexParamsEntityList.stream().filter(index -> StringUtils.isEmpty(index.getScriptType()) || index.getScriptType().equalsIgnoreCase(ScriptTypeEnum.SQL.id)).collect(Collectors.toList());

        Map<String, Object> sqlResult = Maps.newHashMap();
        Map<String, String> parentParmaType = Maps.newHashMap();
        if (CollectionUtils.isNotEmpty(sqlIndexParamsList)) {
            List<IndexParamsEntity> parentIndexList = new ArrayList<>();
            getParamsByParentParamNo(sqlIndexParamsList, parentIndexList);
            Map<String, Object> paramData = Maps.newHashMap();
            // 入参名归一（兼容旧写法）：取数前兜最后一层 —— 无论上游传 reportno 还是 reportNo，
            // 都能命中配置里已改成驼峰的 :reportNo / :entName / :guarantorName。
            AgentParamNames.normalizeInPlace(params);
            params.keySet().forEach(key -> paramData.put(key, params.get(key)));
            // 特殊处理： sql查询的关联参数取值
            if (cascadeMap != null && !cascadeMap.isEmpty()) {
                cascadeMap.keySet().forEach(key -> paramData.put(key, cascadeMap.get(key)));
            }
            // 启用多线程从数据库获取数据
            parentIndexList.forEach(p -> futures.add(completionService.submit(() -> {
                try {
                    String paramNo = p.getParamNo();
                    String scriptType = p.getScriptType();
                    String script = p.getScript();
                    long start = System.currentTimeMillis();
                    DataSetBuilder bean = AgentSpringContext.getBean(scriptType, DataSetBuilder.class);
                    List<?> build = bean.build(paramNo, script, paramData, relateIndexSet);
                    long costTime = System.currentTimeMillis() - start;
                    log.info("执行sql取数方法[{} {}]，取数方法执行完成！耗时：{}ms", p.getParamID(), p.getParamName(), costTime);
                    if (build != null && !build.isEmpty()) {
                        try {
                            JSONArray finalResult = new JSONArray();
                            List<IndexParamsEntity> paramsList = p.getParamsList();
                            // 🔴 必须给合并函数：index_params 里同一 paramID 可对应多行（实测 91 组重复，
                            //    如 dfjelxsqjs = "代发金额连续三期逐步减少" / "连续三期代发金额同比下降"）。
                            //    无合并函数时 Collectors.toMap 直接抛 IllegalStateException(Duplicate key)
                            //    —— 注意异常消息里打印的是 **value(paramName)** 不是 key，所以日志里看着像中文名。
                            //    被外层 catch 吞掉后走 sqlResult.put(paramNo, build)，该指标的**列名映射整体失效**
                            //    （下游按中文名取值取不到 ⇒ 静默降级成"未取到值"）。取首值即可。
                            Map<String, String> map = CollectionUtils.isNotEmpty(paramsList)
                                    ? paramsList.stream().collect(Collectors.toMap(
                                            IndexParamsEntity::getParamID, IndexParamsEntity::getParamName, (a, b) -> a))
                                    : null;
                            build.forEach(data -> {
                                // 保证解析时有序（FastJSON）
                                JSONObject jsonObject = JSON.parseObject(JSON.toJSONString(data), Feature.OrderedField);
                                if (Objects.nonNull(jsonObject) && !jsonObject.isEmpty()) {
                                    // 使用 LinkedHashMap 保证顺序
                                    JSONObject newJsonObject = new JSONObject(true);
                                    // 保证 key 的遍历顺序
                                    List<String> keysToProcess = new ArrayList<>(jsonObject.keySet());
                                    for (String key : keysToProcess) {
                                        Object value = jsonObject.get(key);
                                        boolean isNumeric = ParamUtil.isNumericDouble(value);
                                        if (isNumeric) {
                                            value = ParamUtil.formatDecimal(value);
                                        }
                                        // 键名映射
                                        String newKey = (map != null && map.containsKey(key)) ? map.get(key) : key;
                                        newJsonObject.put(newKey, value);
                                    }
                                    finalResult.add(newJsonObject);
                                }
                            });
                            if (!finalResult.isEmpty()) {
                                sqlResult.put(paramNo, finalResult);
                            }
                        } catch (Exception e) {
                            log.error("处理sql字段数值格式异常，异常信息为：{}", ExceptionUtils.getStackTrace(e));
                            sqlResult.put(paramNo, build);
                        }
                        parentParmaType.put(paramNo, p.getParamType());
                    }
                    // 存储日志信息
                    KnowledgeQueryResultEntity logEntity = logSupplier.get();
                    logEntity.setQueryType(2);
                    logEntity.setScriptSql(script);
                    logEntity.setQueryTime(DateUtil.now());
                    logEntity.setSqlParam(paramData.toString());
                    logEntity.setCostTime((int) (System.currentTimeMillis() - start));
                    logEntity.setQueryResult(Objects.isNull(build) ? "" : build.toString());
                    logEntityList.add(logEntity);
                } catch (Exception e) {
                    log.error("执行sql取数方法[{} {}]报错!，异常信息：{}", p.getParamID(), p.getParamName(), ExceptionUtils.getStackTrace(e));
                }
                return "";
            })));
        }
        processResults(futures);

        // 从Api接口数据集apiResult中解析出指标值
        handleApiIndexValue(apiIndexParamsList, paramGroupResultMap, returnResult);
        // 从数据源结果集sqlResult中解析出指标值
        handleSqlIndexValue(sqlIndexParamsList, sqlResult, returnResult, parentParmaType);

        // 异步保存请求日志
        Boolean batchFlag = params.getBoolean("batchFlag");
        syncExecuteService.syncSaveKnowledgeLog(batchFlag, traceId, moduleCode, logEntityList);

        return returnResult;
    }

    private void handleParamSetIndex(List<IndexParamsEntity> paramSetIndexParamsList, JSONObject params, Map<String, Object> paramGroupResultMap) {
        if (CollectionUtils.isEmpty(paramSetIndexParamsList)) {
            return;
        }
        paramSetIndexParamsList.forEach(indexParam -> {
            String paramID = indexParam.getParamID();
            if (params.containsKey(paramID)) {
                paramGroupResultMap.put(indexParam.getParamNo(), params.get(paramID));
            } else {
                JSONObject extensions = params.getJSONObject("extensions");
                if (Objects.nonNull(extensions) && !extensions.isEmpty() && extensions.containsKey(paramID)) {
                    paramGroupResultMap.put(indexParam.getParamNo(), extensions.get(paramID));
                }
            }
        });
    }

    @Override
    public AgentResult<?> getSourceParamList(String paramId) {
        KnowledgeBaseParamsEntity baseParamsEntity = knowledgeBaseParamsService.getById(paramId);
        if (Objects.isNull(baseParamsEntity) || StringUtils.isEmpty(baseParamsEntity.getRelateIndexSet())) {
            return AgentResult.OK();
        }
        String relateIndexSet = baseParamsEntity.getRelateIndexSet();
        JSONArray jsonArray = JSONArray.parseArray(relateIndexSet);
        if (null == jsonArray || jsonArray.isEmpty()) {
            return AgentResult.OK();
        }

        JSONArray sourceParamList = new JSONArray();
        jsonArray.forEach(json -> {
            JSONObject jsonObj = (JSONObject) json;
            JSONArray params = jsonObj.getJSONArray("params");
            if (Objects.nonNull(params) && !params.isEmpty()) {
                for (Object param : params) {
                    JSONObject paramObj = (JSONObject) param;
                    JSONObject sourceParam = new JSONObject();
                    String sourceField = paramObj.getString("sourceField");
                    String fieldName = paramObj.getString("fieldName");
                    if (StringUtils.isNotEmpty(sourceField)) {
                        String[] split = sourceField.split("-");
                        if (split.length > 2) {
                            Optional<JSONObject> exist = sourceParamList.stream().map(obj -> (JSONObject) obj).filter(obj -> obj.getString("key").equals(split[0])).findAny();
                            if (!exist.isPresent()) {
                                sourceParam.put("key", split[0]);
                                int index = sourceField.indexOf("-", split[0].length() + 1);
                                sourceParam.put("value", fieldName + "-" + sourceField.substring(index + 1));
                                sourceParamList.add(sourceParam);
                            }
                        }
                    }
                }
            }
        });
        return AgentResult.OK(sourceParamList);
    }

    @Override
    public Map<String, Object> getIndexValueMap(String relateIndexSet, JSONObject params, List<String> arrayList, Map<String, Object> paramGroupResultMap) {
        if (CollectionUtils.isEmpty(arrayList)) {
            return Collections.emptyMap();
        }
        // 查询级联相关指标
        Map<String, Object> cascadeMap = Maps.newHashMap();
        List<String> cascadeList = indexRelateInfoService.getRelateIndexList(arrayList);
        paramGroupResultMap = Objects.isNull(paramGroupResultMap) ? new HashMap<>(0) : paramGroupResultMap;
        if (CollectionUtils.isNotEmpty(cascadeList)) {
            // 过滤掉已查询过的指标
            List<String> notExistsCascadeList = new ArrayList<>();
            for (String string : cascadeList) {
                if (!paramGroupResultMap.containsKey(string)) {
                    notExistsCascadeList.add(string);
                }
            }
            if (CollectionUtils.isNotEmpty(notExistsCascadeList)) {
                cascadeMap = handleParam(relateIndexSet, params, notExistsCascadeList, Maps.newHashMap(), paramGroupResultMap);
            }
            if (Objects.isNull(cascadeMap)) {
                cascadeMap = Maps.newHashMap();
            }
            // 补充已查询过的指标值
            List<String> existsCascadeList = cascadeList.stream().filter(paramGroupResultMap::containsKey).collect(Collectors.toList());
            if (CollectionUtils.isNotEmpty(existsCascadeList)) {
                for (String item : existsCascadeList) {
                    cascadeMap.put(item, paramGroupResultMap.get(item));
                }
            }
        }
        // 过滤arrayList中已查询过的指标
        List<String> notExistsArrayList = new ArrayList<>();
        for (String item : arrayList) {
            if (!paramGroupResultMap.containsKey(item)) {
                notExistsArrayList.add(item);
            }
        }
        Map<String, Object> objectMap = null;
        if (CollectionUtils.isNotEmpty(notExistsArrayList)) {
            objectMap = handleParam(relateIndexSet, params, notExistsArrayList, cascadeMap, paramGroupResultMap);
            if (Objects.isNull(objectMap)) {
                objectMap = Maps.newHashMap();
            }
            paramGroupResultMap.putAll(objectMap);
            // 补充已查询过的指标值
            List<String> existsArrayList = arrayList.stream().filter(paramGroupResultMap::containsKey).collect(Collectors.toList());
            if (CollectionUtils.isNotEmpty(existsArrayList)) {
                for (String item : existsArrayList) {
                    objectMap.put(item, paramGroupResultMap.get(item));
                }
            }
        }
        return objectMap;
    }

    @Override
    public AgentResult<?> KnowledgeResourcePreview(KnowledgeResourceViewReq reqMsg) {
        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = knowledgeBaseParamsService.getById(reqMsg.getParamId());
        if (Objects.isNull(knowledgeBaseParamsEntity)) {
            throw new AgentBizException("请求异常，未查询到相关知识库信息！");
        }
        if (CollectionUtils.isEmpty(reqMsg.getResourceContent())) {
            return AgentResult.OK();
        }
        String previewContent = getResourcePreview(reqMsg.getResourceContent(), knowledgeBaseParamsEntity.getRelateIndexSet(), reqMsg.getParams());
        return AgentResult.OK(previewContent);
    }

    @Override
    public Object previewJsExpression(PreviewJsExceptionReq reqMsg) {
        return null;
    }

    @Async
    @Override
    public void knowledgeCacheParse(InputStream inputStream, String fileName) {
        knowledgeCacheHandler.excelDataExecutor(inputStream, fileName);
    }

    /** 「无数据」标记的 key（由 {@link #isIndexNoData} 判定、写在 promptObject 上） */
    private static final String RESULT_NO_INDEX_DATA = "noIndexData";

    /**
     * 本次取数是否「完全没有拿到数据」（2026-09-19 用户口径）
     *
     * <p>判据：<b>配了关联指标集（{@code relateIndexSet}）却一条值都没取到</b>。
     * 之所以要求"配了指标集"，是为了不误伤纯提示词类知识库（本来就不依赖业务数据）。</p>
     *
     * <p>为什么需要它：取数全空时大模型仍会被调用，模型在零数据输入下会
     * <b>照抄提示词里的示例数值、甚至凭空编造具体企业名/金额</b>（2026-09-19 实测：
     * 正文里的 17.60/13.60/10.50 正是提示词"数值处理规则"的示例值；
     * 抵押物正文里的企业名在模型输入里 0 次命中）。产出的是"看起来很专业但没有依据"的正文，
     * 比直接报错危险得多。</p>
     *
     * <p>没有数据支持就不该调用大模型，正文按 {@code emptyStrategy} 展示"暂无数据"即可。</p>
     */
    private static boolean isIndexNoData(String relateIndexSet, Map<String, Object> paramGroupResultMap) {
        // 没配关联指标集 ⇒ 不拦（纯提示词类知识库，取数与它无关）
        if (StringUtils.isEmpty(relateIndexSet)) {
            return false;
        }
        if (paramGroupResultMap == null || paramGroupResultMap.isEmpty()) {
            return true;
        }
        for (Object value : paramGroupResultMap.values()) {
            if (hasIndexValue(value)) {
                return false;
            }
        }
        return true;
    }

    /** 取数结果是否"有值"（null / 空串 / 空数组 / 空对象 / 字面量 "null" 都算无值） */
    private static boolean hasIndexValue(Object value) {
        if (value == null) {
            return false;
        }
        if (value instanceof Collection) {
            return !((Collection<?>) value).isEmpty();
        }
        if (value instanceof Map) {
            return !((Map<?, ?>) value).isEmpty();
        }
        String text = String.valueOf(value).trim();
        return !text.isEmpty() && !"[]".equals(text) && !"{}".equals(text) && !"null".equals(text);
    }

    /**
     * 严格模式（报告链路）下，知识库取数全空 ⇒ 短路，不调用大模型。
     *
     * <p>只在 {@code __strictFetch=true} 时生效 —— 配置页预览、智策引擎试跑保持原行为，
     * 仍允许用空数据调试提示词。</p>
     */
    private boolean shouldSkipLlmForNoIndexData(JSONObject params, JSONObject promptObject) {
        if (promptObject == null || !promptObject.getBooleanValue("isExist")) {
            return false;
        }
        if (!promptObject.getBooleanValue(RESULT_NO_INDEX_DATA)) {
            return false;
        }
        // 非严格模式 ⇒ 不拦
        return Boolean.parseBoolean(String.valueOf(params.get(SqlDataSetBuilder.STRICT_FETCH_KEY)));
    }

    @Override
    public Object getPromptContent(String paramStr, SseEmitter emitter) {
        JSONObject params = JSONObject.parseObject(paramStr);
        // 入参名归一（兼容旧写法）：reportno/guarantorname 等历史写法补上规范名键（双写，原键保留）。
        // 挂在这里是因为：{{objectName}} 替换、ent_name 日志、以及后续取数都读这个 params。
        AgentParamNames.normalizeInPlace(params);
        String moduleCode = params.getString("moduleCode");
        if (StringUtils.isEmpty(moduleCode)) {
            log.info("接收到获取文案接口请求，请求参数异常！参数：{}", paramStr);
            return new JSONObject(0);
        }

        // 溯源查询，直接返回结果
        String sourceTraceId = params.getString("traceId");
        if (StringUtils.isNotEmpty(sourceTraceId)) {
            return AgentResult.OK(getSourceResult(moduleCode, sourceTraceId));
        }

        // 生成追踪ID
        String traceId = resolveTraceId(params);
        params.put("traceId", traceId);

        String queryTime = DateUtil.now();
        long startTime = System.currentTimeMillis();
        try {
            String promptCache = "";
            JSONObject promptObject;
            if (moduleCodeCacheEnable) {
                log.info("缓存开关：开启状态，开始从缓存中获取知识库[{}]的prompt文案！", moduleCode);
                promptCache = moduleCodePromptCacheService.getPromptCache(moduleCode, paramStr);
            }
            if (StringUtils.isNotEmpty(promptCache)) {
                log.info("命中缓存，开始从缓存中获取知识库[{}]的prompt文案！", moduleCode);
                promptObject = JSONObject.parseObject(promptCache);
            } else {
                log.info("未命中缓存，开始获取知识库[{}]的prompt文案！", moduleCode);
                promptObject = handlePromptContent(params);
            }

            // 🆕 2026-09-19 用户口径：业务数据不支持 ⇒ 不必调大模型，报告展示"暂无数据"即可。
            boolean noIndexData = shouldSkipLlmForNoIndexData(params, promptObject);
            Object llmResult;
            if (noIndexData) {
                log.warn("【无数据短路】知识库[{}] 关联指标全部未取到值，跳过调用大模型（traceId={}）"
                                + "—— 该块按 emptyStrategy 展示暂无数据", moduleCode, traceId);
                llmResult = null;
            } else {
                llmResult = invokeLlmIfNeeded(params, promptObject, moduleCode, emitter);
            }
            promptQueryResultEntityService.savePromptQueryResult(
                    moduleCode, params, paramStr, promptObject,
                    System.currentTimeMillis() - startTime, queryTime, DateUtil.now(), traceId, "");
            // ⚠️ 短路时必须**直接返回空对象**：不能回落到 promptObject —— 它含提示词原文，
            //    会被上层 pickLlmText 当成"模型输出"写进报告正文（重演 tddkjcqk 那个坑）。
            if (noIndexData) {
                return new JSONObject();
            }
            return shouldReturnLlmResult(promptObject, llmResult) ? llmResult : promptObject;
        } catch (Exception e) {
            String failReason = ExceptionUtils.getStackTrace(e);
            promptQueryResultEntityService.savePromptQueryResult(
                    moduleCode, params, paramStr, new JSONObject(0),
                    System.currentTimeMillis() - startTime, queryTime, DateUtil.now(), traceId, failReason);
            log.error("获取prompt文案失败！traceId为{},原因：{}", traceId, failReason);
            return new JSONObject();
        }
    }

    private String resolveTraceId(JSONObject params) {
        String plumeLogId = params.getString("plumeLogId");
        return StringUtils.isNotEmpty(plumeLogId) ? plumeLogId : ParamUtil.getSessionNo("");
    }

    private Object invokeLlmIfNeeded(JSONObject params, JSONObject promptObject, String moduleCode, SseEmitter emitter) {
        boolean withModelSummary = ParamUtil.getBoolValue(params, "withModelSummary", false);
        boolean isCloudSearch = ParamUtil.getBoolValue(promptObject, "isCloudSearch", false);

        if (withModelSummary) {
            return invokeLocalLlm(params, promptObject, moduleCode, emitter);
        }
        if (isCloudSearch) {
            return invokeCloudLlm(params, promptObject, moduleCode, emitter);
        }
        return null;
    }

    private Object invokeLocalLlm(JSONObject params, JSONObject promptObject, String moduleCode, SseEmitter emitter) {
        params.put("prompt", promptObject.get("content"));
        params.put("large_model_code", promptObject.get("largeModelCode"));
        mergeLlmParams(params, promptObject.getJSONObject("largeModelParam"));
        log.info("知识库[{}]：确认走本地大模型渲染最后结果！", moduleCode);
        String finishFlag = JSONTools.getString(params, "finishFlag");
        return callLlmUtil.callLlm(params, emitter, "true".equals(finishFlag), true, true);
    }

    private Object invokeCloudLlm(JSONObject params, JSONObject promptObject, String moduleCode, SseEmitter emitter) {
        log.info("知识库[{}]：确认走云端查询大模型渲染最后结果！", moduleCode);
        boolean stream = ParamUtil.getBoolValue(params, "stream", false);
        params.put("stream", stream ? "Y" : "N");
        params.put("knowledgeQuery", true);
        return renderBigModelApiClient.handleCallRM1201(params, promptObject, emitter);
    }

    private void mergeLlmParams(JSONObject params, JSONObject largeModelParam) {
        if (largeModelParam == null || largeModelParam.isEmpty()) {
            return;
        }
        putIfAbsentOrEmpty(params, "top_p", largeModelParam.get("topP"));
        putIfAbsentOrEmpty(params, "temperature", largeModelParam.get("temperature"));
        putIfAbsentOrEmpty(params, "system_content", largeModelParam.get("systemContent"));
        putIfAbsentOrEmpty(params, "enable_think", largeModelParam.get("enableThink"));
    }

    private void putIfAbsentOrEmpty(JSONObject params, String key, Object value) {
        if (!params.containsKey(key) || StringUtils.isEmpty(params.getString(key))) {
            params.put(key, value);
        }
    }

    private boolean shouldReturnLlmResult(JSONObject promptObject, Object llmResult) {
        return promptObject.getBoolean("isExist") && llmResult != null;
    }

    @Override
    public Object getPromptStream(String paramStr, SseEmitter emitter) {
        JSONObject params = JSONObject.parseObject(paramStr);
        String moduleCode = params.getString("moduleCode");
        if (StringUtils.isEmpty(moduleCode)) {
            emitter.complete();
            return AgentResult.error("参数异常");
        }

        // 判断是否溯源查询,直接返回结果
        String sourceTraceId = params.getString("traceId");
        if (StringUtils.isNotEmpty(sourceTraceId)) {
            emitter.complete();
            return AgentResult.OK();
        }

        // 生成一个追踪ID，用于在日志中追踪请求
        String plumeLogId = params.getString("plumeLogId");
        String traceId = StringUtils.isNotEmpty(plumeLogId) ? plumeLogId : ParamUtil.getSessionNo("");
        params.put("traceId", traceId);

        String queryTime = DateUtil.now();
        long startTime = System.currentTimeMillis();
        params.put("knowledge_query_startTime", startTime);
        try {
            JSONObject promptObject = handlePromptContent(params);
            promptQueryResultEntityService.savePromptQueryResult(moduleCode, params, paramStr, promptObject, System.currentTimeMillis() - startTime, queryTime, DateUtil.now(), traceId, "");
            Boolean stream = Objects.nonNull(params.get("stream")) && params.getBoolean("stream");
            return getCallContent(promptObject, emitter, stream);
        } catch (Exception e) {
            String failReason = ExceptionUtils.getStackTrace(e);
            promptQueryResultEntityService.savePromptQueryResult(moduleCode, params, paramStr, new JSONObject(0), System.currentTimeMillis() - startTime, queryTime, DateUtil.now(), traceId, failReason);
            emitter.complete();
            return new JSONObject();
        }
    }

    private Object getCallContent(JSONObject promptObject, SseEmitter emitter, Boolean stream) {
        JSONObject requestBody = new JSONObject();
        requestBody.put("stream", stream);
        JSONObject largeModelParam = promptObject.getJSONObject("largeModelParam");
        if (Objects.nonNull(largeModelParam)) {
            requestBody.put("large_model_code", largeModelParam.getString("largeModelCode"));
            requestBody.put("system_content", largeModelParam.getString("systemContent"));
            requestBody.put("temperature", largeModelParam.getDouble("temperature"));
            requestBody.put("top_p", largeModelParam.getDouble("topP"));
        }
        requestBody.put("prompt", promptObject.getString("content").replace("{\"换行\":\"\\r\\n\"}", "\n"));
        return callLlmUtil.callLlm(requestBody, emitter, false, false, false);
    }

    @Override
    public Pair<String, Object> getPromptContentAndModuleCode(KnowledgeBasePromptViewReq req) {
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> lambdaQueryWrapper = Wrappers.lambdaQuery();
        lambdaQueryWrapper.select(KnowledgeBaseParamsEntity::getGroupId, KnowledgeBaseParamsEntity::getParamNo, KnowledgeBaseParamsEntity::getParamId);
        lambdaQueryWrapper.eq(KnowledgeBaseParamsEntity::getParamId, req.getParamId());
        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = knowledgeBaseParamsService.getOne(lambdaQueryWrapper);
        if (Objects.isNull(knowledgeBaseParamsEntity)) {
            throw new AgentBizException("请求异常，未查询到相关知识库信息！");
        }

        // 组装参数
        String moduleCode = knowledgeBaseParamsEntity.getParamNo();
        JSONObject params = JSONObject.parseObject(JSONObject.toJSONString(req));
        params.put("moduleCode", moduleCode);
        // 入参名归一（兼容旧写法）：补上规范名键（双写，原键保留）
        AgentParamNames.normalizeInPlace(params);

        // 处理输入参数
        List<JSONObject> inputParam = req.getInputParam();
        if (CollectionUtils.isNotEmpty(inputParam)) {
            inputParam.forEach(obj -> {
                String name = obj.getString("name");
                String value = obj.getString("defaultValue");
                if (StringUtils.isNotEmpty(name) && StringUtils.isNotEmpty(value)) {
                    params.put(name, value);
                }
            });
        }

        // 获取文案内容
        JSONObject promptObject = handlePromptContent(params);
        return Pair.of(moduleCode, Objects.isNull(promptObject.get("content")) ? "" : promptObject.get("content"));
    }

    @Override
    public Object knowledgePreview(KnowledgePreviewReq req) {
        SseEmitter emitter = new SseEmitter(0L);
        try {
            // 处理输入参数
            JSONObject params = req.getParams();
            // 入参名归一（兼容旧写法）：补上规范名键（双写，原键保留）
            AgentParamNames.normalizeInPlace(params);
            JSONArray inputParam = params.getJSONArray("inputParam");
            if (CollectionUtils.isNotEmpty(inputParam)) {
                inputParam.forEach(obj -> {
                    JSONObject object = (JSONObject) obj;
                    String name = object.getString("name");
                    String value = object.getString("defaultValue");
                    if (StringUtils.isNotEmpty(name) && StringUtils.isNotEmpty(value)) {
                        params.put(name, value);
                    }
                });
            }

            // 获取文案信息
            JSONObject promptObject = handlePromptContent(params);
            Object content = promptObject.get("content");
            if (Objects.isNull(content) || StringUtils.isEmpty(content.toString())) {
                finishEmitter(emitter);
            } else if (content instanceof String) {
                long startTime = System.currentTimeMillis();
                if (!req.isStream()) {
                    JSONObject requestForQuestion = new JSONObject(true);
                    requestForQuestion.put("prompt", content);
                    requestForQuestion.put("large_model_code", req.getLargeModelCode());
                    requestForQuestion.put("stream", false);
                    callLlmUtil.callLlm(requestForQuestion, emitter, true, true, false);
                    log.info("OpenAi调用完成，耗时：{}毫秒", (System.currentTimeMillis() - startTime));
                    return AgentResult.OK();
                }
                JSONObject requestForQuestion = new JSONObject(true);
                requestForQuestion.put("prompt", content);
                requestForQuestion.put("large_model_code", req.getLargeModelCode());
                requestForQuestion.put("stream", true);
                callLlmUtil.callLlm(requestForQuestion, emitter, true, true, false);
                log.info("OpenAi调用完成，耗时：{}毫秒", (System.currentTimeMillis() - startTime));
            } else if (content instanceof JSONArray) {
                int chunkSize = 1000;
                String dividedPromptResult = getDividedPromptResult((JSONArray) content);
                if (!req.isStream()) {
                    return AgentResult.OK(dividedPromptResult);
                }
                // 迁移改造点：源实现用 reactor 的 Flux.range(...).map(...).subscribe(...) 做「分块 + 逐块推 SSE」。
                // 本工程不引入 reactor，改为等价的同步 for 循环：按 chunkSize 切片逐块发送，
                // 单块发送失败时记日志并结束 emitter（与原实现的块级 catch 行为一致），全部完成后 finishEmitter。
                int chunkCount = (dividedPromptResult.length() + chunkSize - 1) / chunkSize;
                for (int i = 0; i < chunkCount; i++) {
                    String charStr = dividedPromptResult.substring(i * chunkSize, Math.min((i + 1) * chunkSize, dividedPromptResult.length()));
                    try {
                        JSONObject result = new JSONObject();
                        result.put("code", 200);
                        result.put("content", charStr);
                        SseEmitter.SseEventBuilder event = SseEmitter.event().name("message").data(result.toJSONString());
                        emitter.send(event);
                    } catch (IOException e) {
                        log.error("发送失败:{}", ExceptionUtils.getStackTrace(e));
                        finishEmitter(emitter);
                    }
                }
                finishEmitter(emitter);
            }
            return emitter;
        } catch (Exception e) {
            log.error("开始预览请求异常，异常信息:{}", ExceptionUtils.getStackTrace(e));
            finishEmitter(emitter);
            return AgentResult.error("系统异常!");
        }
    }

    @Override
    public Integer saveRelateIndex(KnowledgeRelateIndexEntity knowledgeRelateIndex) {
        Integer id = knowledgeRelateIndexService.saveIndex(knowledgeRelateIndex);
        // 异步处理关联指标配置信息
        syncHandleRelateIndex(knowledgeRelateIndex.getKnowledgeId());
        return id;
    }

    @Override
    public void updateRelateIndex(List<KnowledgeRelateIndexEntity> knowledgeRelateIndexList) {
        knowledgeRelateIndexService.updateIndex(knowledgeRelateIndexList);
        // 异步处理关联指标配置信息
        KnowledgeRelateIndexEntity knowledgeRelateIndex = knowledgeRelateIndexService.getById(knowledgeRelateIndexList.get(0).getKnowledgeId());
        if (Objects.nonNull(knowledgeRelateIndex)) {
            syncHandleRelateIndex(knowledgeRelateIndex.getKnowledgeId());
        }
    }

    @Override
    public void removeRelateIndexList(List<Integer> idList) {
        knowledgeRelateIndexService.removeByIds(idList);
        // 异步处理关联指标配置信息
        KnowledgeRelateIndexEntity knowledgeRelateIndex = knowledgeRelateIndexService.getById(idList.get(0));
        if (Objects.nonNull(knowledgeRelateIndex)) {
            syncHandleRelateIndex(knowledgeRelateIndex.getKnowledgeId());
        }
    }

    @Override
    public ListResult<?> selectRelateIndexList(KnowledgeRelateIndexReq reqMsg) {
        return knowledgeRelateIndexService.getPageList(reqMsg);
    }

    @Override
    public ListResult<?> queryFirstKnowledgeGroup() {
        return new ListResult<>(knowledgeBaseGroupMapper.getFirstKnowledgeBaseGroup());
    }

    @Override
    public void knowledgeCallLlm(JSONObject req, SseEmitter emitter) {
        callLlmUtil.callLlm(req, emitter, false, false, false);
    }

    @Override
    public Object getApplyPrompt(JSONObject req, SseEmitter emitter) {
        try {
            // 参数验证
            if (req == null || req.isEmpty()) {
                return AgentResult.error("参数没有数据");
            }

            // 生成一个追踪ID，用于在日志中追踪请求
            String traceId = StringUtils.isNotEmpty(req.getString("trace_id")) ? req.getString("trace_id") : ParamUtil.getSessionNo("");

            // 获取params参数
            JSONObject params = req.getJSONObject("params");
            if (params == null) {
                return AgentResult.error("参数为空");
            }

            // 获取system_content
            String systemContent = (String) req.get("system_content");
            if (systemContent == null || systemContent.isEmpty()) {
                systemContent = "You are a helpful assistant";
            }

            // 获取temperature
            double temperature = 0.01;
            Object tempObj = req.get("temperature");
            if (tempObj != null) {
                if (tempObj instanceof Double) {
                    temperature = (Double) tempObj;
                } else if (tempObj instanceof Integer) {
                    temperature = ((Integer) tempObj).doubleValue();
                } else {
                    try {
                        temperature = Double.parseDouble(tempObj.toString());
                    } catch (NumberFormatException e) {
                        log.error("temperature参数格式错误:{}", ExceptionUtils.getStackTrace(e));
                    }
                }
            }

            // 获取top_p
            double topP = 0.7;
            Object topPObj = req.get("top_p");
            if (topPObj != null) {
                if (topPObj instanceof Double) {
                    topP = (Double) topPObj;
                } else if (topPObj instanceof Integer) {
                    topP = ((Integer) topPObj).doubleValue();
                } else {
                    try {
                        topP = Double.parseDouble(topPObj.toString());
                    } catch (NumberFormatException e) {
                        log.error("top_p参数格式错误:{}", ExceptionUtils.getStackTrace(e));
                    }
                }
            }

            // 处理params参数，转换为markdown格式
            for (Map.Entry<String, Object> entry : params.entrySet()) {
                if (entry.getValue() != null) {
                    params.put(entry.getKey(), ParamUtil.toMarkdown(entry.getValue()));
                } else {
                    params.put(entry.getKey(), "");
                }
            }

            // 获取enable_think
            boolean enableThink = ParamUtil.getBoolValue(req, "enable_think", false);

            // 获取max_tokens
            Integer maxTokens = req.getInteger("max_tokens");

            // 获取stream
            boolean stream = ParamUtil.getBoolValue(req, "stream", true);

            // 获取translate_config
            JSONObject translateConfig = req.getJSONObject("translate_config");
            if (!ParamUtil.validateTranslateConfig(translateConfig)) {
                return AgentResult.error("translate_config参数错误");
            }

            // 获取scenario
            String scenario = (String) req.get("scenario");
            if (StringUtils.isEmpty(scenario) || "None".equalsIgnoreCase(scenario)) {
                return AgentResult.error("非法的场景名称:" + scenario);
            }

            try {
                // 获取prompt配置
                ApplyPromptDTO promptResult = CallLlmUtil.applyPromptDTOBySceneNameMap.get(scenario);
                if (promptResult != null && promptResult.getPrompt() != null && promptResult.getLargeModelCode() != null) {

                    String promptTemplate = promptResult.getPrompt();
                    // 替换模板中的参数
                    for (Map.Entry<String, Object> entry : params.entrySet()) {
                        String placeholder = "{" + entry.getKey() + "}";
                        promptTemplate = promptTemplate.replace(
                                placeholder,
                                entry.getValue() != null ? entry.getValue().toString() : ""
                        );
                    }

                    // 构建调用参数
                    JSONObject callParams = new JSONObject();
                    callParams.put("prompt", promptTemplate);
                    callParams.put("large_model_code", promptResult.getLargeModelCode());
                    callParams.put("top_p", topP);
                    callParams.put("system_content", systemContent);
                    callParams.put("stream", stream);
                    callParams.put("temperature", temperature);
                    callParams.put("trace_id", traceId);
                    callParams.put("enable_think", enableThink);
                    callParams.put("translate_config", translateConfig);
                    callParams.put("max_tokens", maxTokens);

                    // 调用大模型
                    return callLlmUtil.callLlm(callParams, emitter, false, true, false);
                } else {
                    log.error("非法的场景名称:{}", scenario);
                    return AgentResult.error("非法的场景名称:" + scenario);
                }
            } catch (Exception e) {
                log.error("调用大模型错误:{}", ExceptionUtils.getStackTrace(e));
                return AgentResult.error("调用大模型错误!");
            }
        } catch (Exception e) {
            log.error("系统错误:{}", ExceptionUtils.getStackTrace(e));
            return AgentResult.error("调用大模型错误!");
        }
    }

    private void syncHandleRelateIndex(String knowledgeId) {
        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = knowledgeBaseParamsService.getById(knowledgeId);
        if (Objects.nonNull(knowledgeBaseParamsEntity)) {
            executor.execute(() -> handleIndexParamConfig(knowledgeBaseParamsEntity, knowledgeBaseParamsEntity.getRelateIndexSet()));
        }
    }

    private void asyncHandleTraceConfig(JSONObject params, KnowledgeBaseParamsEntity knowledgeBaseParamsEntity, String relateIndexSet, String moduleCode, String traceId) {
        try {
            String traceConfig = knowledgeBaseParamsEntity.getTraceConfig();
            String imageConfig = knowledgeBaseParamsEntity.getImageConfig();
            boolean traceFlag = StringUtils.isNotEmpty(traceConfig) && !JSONArray.parseArray(traceConfig, JSONObject.class).isEmpty();
            boolean imageFlag = StringUtils.isNotEmpty(imageConfig) && !JSONArray.parseArray(imageConfig, JSONObject.class).isEmpty();
            if (traceFlag || imageFlag) {
                String nowTime = DateUtil.now();
                long startTime = System.currentTimeMillis();
                executor.execute(() -> {
                    long traceConfigEndTime = 0L;
                    long imageConfigEndTime = 0L;

                    String traceConfigContent = "";
                    String imageContent = "";
                    // 开始解析溯源配置
                    if (traceFlag) {
                        try {
                            long start = System.currentTimeMillis();
                            traceConfigContent = parseTraceConfig(relateIndexSet, moduleCode, traceConfig, params, Maps.newHashMap());
                            traceConfigEndTime = System.currentTimeMillis() - start;
                        } catch (Exception e) {
                            log.error("处理[{}]的溯源配置失败，TraceId为[{}]，失败原因[{}]", moduleCode, traceId, ExceptionUtils.getStackTrace(e));
                        }
                    }
                    // 开始解析图片配置
                    if (imageFlag) {
                        try {
                            long start = System.currentTimeMillis();
                            imageContent = parseImageConfig(relateIndexSet, moduleCode, imageConfig, params, Maps.newHashMap());
                            imageConfigEndTime = System.currentTimeMillis() - start;
                        } catch (Exception e) {
                            log.error("处理[{}]的溯源图片配置失败，TraceId为[{}]，失败原因[{}]", moduleCode, traceId, ExceptionUtils.getStackTrace(e));
                        }
                    }
                    // 存储溯源指标配置(redis+mysql)
                    String key = "debug_info:" + traceId + "-" + "source_card";
                    try {
                        JSONObject redisResult = new JSONObject();
                        redisResult.put("traceId", traceId);
                        JSONArray sourceCard = new JSONArray();
                        JSONArray sourceImage = new JSONArray();
                        if (StringUtils.isNotEmpty(traceConfigContent)) {
                            try {
                                sourceCard = JSONArray.parseArray(traceConfigContent);
                            } catch (Exception e) {
                                log.error("溯源查询溯源配置[{}]转换异常，异常信息：{}", traceConfigContent, ExceptionUtils.getStackTrace(e));
                            }
                        }
                        if (StringUtils.isNotEmpty(imageContent)) {
                            try {
                                sourceImage = JSONArray.parseArray(imageContent);
                            } catch (Exception e) {
                                log.error("溯源查询图片配置[{}]转换异常，异常信息：{}", imageContent, ExceptionUtils.getStackTrace(e));
                            }
                        }
                        redisResult.put("source_card", sourceCard);
                        redisResult.put("image_source", sourceImage);
                        doubleCache.set(key, JSONObject.toJSONString(redisResult), 10 * 60);
                    } catch (Exception e) {
                        log.error("key：{}-存储数据到redis异常，失败原因：{}", key, ExceptionUtils.getStackTrace(e));
                    }

                    TraceQueryResultEntity traceQueryResultEntity = new TraceQueryResultEntity();
                    traceQueryResultEntity.setQueryTime(nowTime);
                    traceQueryResultEntity.setTraceId(traceId);
                    traceQueryResultEntity.setKnowledgeCode(moduleCode);
                    traceQueryResultEntity.setCostTime((int) (traceConfigEndTime));
                    traceQueryResultEntity.setImageCostTime((int) imageConfigEndTime);
                    traceQueryResultEntity.setQueryResult(traceConfigContent);
                    traceQueryResultEntity.setImageQueryResult(imageContent);
                    traceQueryResultService.save(traceQueryResultEntity);
                    log.info("完成[{}]的溯源配置解析，TraceId为[{}], 耗时[{}ms]", moduleCode, traceId, System.currentTimeMillis() - startTime);
                });
            }
        } catch (Exception e) {
            log.error("处理[{}]的溯源相关配置失败，TraceId为[{}]，失败原因[{}]", moduleCode, traceId, ExceptionUtils.getStackTrace(e));
        }
    }

    private String getDividedPromptResult(JSONArray promptContent) {
        try {
            StringBuffer stringBuilder = new StringBuffer();
            promptContent.forEach(json -> {
                JSONObject object = (JSONObject) json;
                String largeModelCode = object.getString("largeModelCode");
                if (StringUtils.isNotEmpty(largeModelCode) && !largeModelCode.equalsIgnoreCase("NONE")) {
                    JSONObject requestForQuestion = new JSONObject(true);
                    requestForQuestion.put("prompt", object.getString("content"));
                    requestForQuestion.put("large_model_code", largeModelCode);
                    requestForQuestion.put("stream", false);
                    Object execute = callLlmUtil.callLlm(requestForQuestion, new SseEmitter(0L), true, true, false);
                    stringBuilder.append(Objects.isNull(execute) ? "" : execute);
                } else {
                    stringBuilder.append(Objects.isNull(object.getString("content")) ? "" : object.getString("content"));
                }
                stringBuilder.append("\n\n");
            });
            return stringBuilder.toString();
        } catch (Exception e) {
            log.error("处理拆分文案失败，失败原因[{}]", ExceptionUtils.getStackTrace(e));
            return "";
        }
    }

    private String getDividedPromptResult(String largeModelCode, String promptContent) {
        StringBuffer stringBuilder = new StringBuffer();
        if (StringUtils.isNotEmpty(largeModelCode) && !largeModelCode.equalsIgnoreCase("NONE")) {
            JSONObject requestForQuestion = new JSONObject(true);
            requestForQuestion.put("prompt", promptContent);
            requestForQuestion.put("large_model_code", largeModelCode);
            requestForQuestion.put("stream", false);
            Object execute = callLlmUtil.callLlm(requestForQuestion, new SseEmitter(0L), true, true, false);
            stringBuilder.append(extractLlmContent(execute));
        } else {
            stringBuilder.append(StringUtils.isEmpty(promptContent) ? "" : promptContent);
        }
        stringBuilder.append("\n");
        return stringBuilder.toString();
    }

    private String extractLlmContent(Object execute) {
        if (Objects.isNull(execute)) {
            return "";
        }
        if (execute instanceof JSONObject) {
            return StringUtils.isEmpty(((JSONObject) execute).getString("content")) ? "" : ((JSONObject) execute).getString("content");
        }
        if (execute instanceof AgentResult) {
            AgentResult<?> result = (AgentResult<?>) execute;
            log.error("调用大模型失败，无法提取拆分文案内容，错误信息[{}]", result.getMessage());
            return "";
        }
        if (execute instanceof SseEmitter) {
            log.error("调用大模型返回了流式 SseEmitter，无法同步提取拆分文案内容，请使用非流式(stream=false)且 returnFlag=true 的方式调用");
            return "";
        }
        log.error("调用大模型返回了未知类型[{}]，无法提取拆分文案内容", execute.getClass().getName());
        return "";
    }

    private String getSplitterPromptResult(String promptContent, String largeModelCode, JSONObject largeModelParamObj) {
        StringBuffer stringBuilder = new StringBuffer();
        JSONObject requestForQuestion = new JSONObject(true);
        requestForQuestion.put("prompt", promptContent);
        requestForQuestion.put("large_model_code", largeModelCode);
        requestForQuestion.put("stream", false);
        requestForQuestion.put("trace_id", largeModelParamObj.get("trace_id"));
        requestForQuestion.put("temperature", largeModelParamObj.get("temperature"));
        requestForQuestion.put("top_p", largeModelParamObj.get("topP"));
        requestForQuestion.put("enable_think", largeModelParamObj.get("enableThink"));
        requestForQuestion.put("systemContent", largeModelParamObj.get("systemContent"));
        Object execute = callLlmUtil.callLlm(requestForQuestion, new SseEmitter(0L), true, true, false);
        stringBuilder.append(Objects.isNull(execute) ? "" : ((JSONObject) execute).getString("content"));
        stringBuilder.append("\n");
        return stringBuilder.toString();
    }

    private String getWholeSourceConfig(String relateIndexSet, String wholeSourceConfig, JSONObject params, String knowledgeCode) {
        return parseWholeSourceConfig(relateIndexSet, knowledgeCode, wholeSourceConfig, params, Maps.newHashMap());
    }

    private Pair<String, String> getImageConfig(KnowledgeBasePromptViewReq reqMsg, String traceId) {
        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = knowledgeBaseParamsService.getById(reqMsg.getParamId());
        if (Objects.isNull(knowledgeBaseParamsEntity)) {
            throw new AgentBizException("请求异常，未查询到相关知识库信息！");
        }

        // 参数处理
        JSONObject params = handleKnowledgeParam(reqMsg, traceId);
        String moduleCode = knowledgeBaseParamsEntity.getParamNo();
        log.info("开始知识库[{}]图片溯源预览，TraceId为[{}]，请求参数{}", moduleCode, traceId, params);

        // 图片溯源解析
        String imageContent = "";
        String imageConfig = knowledgeBaseParamsEntity.getImageConfig();
        String relateIndexSet = knowledgeBaseParamsEntity.getRelateIndexSet();
        if (StringUtils.isNotEmpty(imageConfig)) {
            imageContent = parseImageConfig(relateIndexSet, moduleCode, imageConfig, params, Maps.newHashMap());
        }
        return Pair.of(moduleCode, imageContent);
    }

    private Pair<String, String> getTraceConfig(KnowledgeBasePromptViewReq reqMsg, String traceId) {
        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = knowledgeBaseParamsService.getById(reqMsg.getParamId());
        if (Objects.isNull(knowledgeBaseParamsEntity)) {
            throw new AgentBizException("请求异常，未查询到相关知识库信息！");
        }

        // 参数处理
        JSONObject params = handleKnowledgeParam(reqMsg, traceId);
        String moduleCode = knowledgeBaseParamsEntity.getParamNo();
        log.info("开始知识库[{}]溯源预览，TraceId为[{}]，请求参数{}", moduleCode, traceId, params);

        // 溯源解析
        String traceConfigContent = "";
        String traceConfig = knowledgeBaseParamsEntity.getTraceConfig();
        String relateIndexSet = knowledgeBaseParamsEntity.getRelateIndexSet();
        if (StringUtils.isNotEmpty(traceConfig)) {
            traceConfigContent = parseTraceConfig(relateIndexSet, moduleCode, traceConfig, params, Maps.newHashMap());
        }
        return Pair.of(moduleCode, traceConfigContent);
    }

    private JSONObject handleKnowledgeParam(KnowledgeBasePromptViewReq reqMsg, String traceId) {
        JSONObject params = new JSONObject();
        params.put("entName", reqMsg.getEntName());
        params.put("mainType", reqMsg.getMainType());
        params.put("traceId", traceId);

        // 处理输入参数
        List<JSONObject> inputParam = reqMsg.getInputParam();
        if (CollectionUtils.isNotEmpty(inputParam)) {
            inputParam.forEach(obj -> {
                String name = obj.getString("name");
                String value = obj.getString("defaultValue");
                if (StringUtils.isNotEmpty(name) && StringUtils.isNotEmpty(value)) {
                    params.put(name, value);
                }
            });
        }
        return params;
    }

    @Override
    public Set<String> getParamNoSet(JSONArray promptCondGroups) {
        Set<String> paramNoSet = Sets.newHashSet();
        for (Object group : promptCondGroups) {
            JSONObject groupObj = (JSONObject) group;
            JSONObject condObj = groupObj.getJSONObject("if");
            if (Objects.isNull(condObj)) {
                continue;
            }
            String condition = condObj.getString("condition");
            if (StringUtils.isNotEmpty(condition)) {
                JSONArray variables = condObj.getJSONArray("variables");
                if (CollectionUtils.isNotEmpty(variables)) {
                    variables.forEach(var -> {
                        JSONObject varObj = (JSONObject) var;
                        String valueType = varObj.getString("valueType");
                        paramNoSet.add(varObj.getString("field"));
                        if ("indicator".equals(valueType)) {
                            paramNoSet.add(varObj.getString("value"));
                        }
                    });
                }
            }
            String output = condObj.getString("output");
            if (StringUtils.isNotEmpty(output)) {
                List<String> paramNoList = ParamUtil.getParamNoList(output);
                paramNoSet.addAll(paramNoList);
            }
        }
        return paramNoSet;
    }

    private boolean doubleCheckKnowledge(String paramNo, String paramId) {
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.ne(StringUtils.isNotEmpty(paramId), KnowledgeBaseParamsEntity::getParamId, paramId);
        queryWrapper.eq(KnowledgeBaseParamsEntity::getParamNo, paramNo);
        // queryWrapper.eq(KnowledgeBaseParamsEntity::getParamStatus, OnlineEnum.Y.name());
        List<KnowledgeBaseParamsEntity> list = knowledgeBaseParamsService.list(queryWrapper);
        if (CollectionUtils.isNotEmpty(list)) {
            return true;
        }
        return false;
    }

    private void handleRelateIndexSet(String id, String relateIndexSet, List<String> paramNoList, JSONArray allParentIndexList) {
        // 根据指标编号，查询相关指标信息
        List<IndexParamsEntity> indexParamsEntityList = indexParamsService.listByIds(paramNoList);
        if (CollectionUtils.isEmpty(indexParamsEntityList)) {
            return;
        }
        // 指标分类：查询参数集类型指标，查询知识库关联的指标参数集, 并解析出相关参数信息
        List<IndexParamsEntity> paramSetIndexParamsList = indexParamsEntityList.stream().filter(index -> StringUtils.isNotEmpty(index.getScriptType()) && index.getScriptType().equalsIgnoreCase(ScriptTypeEnum.PARAM_SET.id)).collect(java.util.stream.Collectors.toList());
        if (CollectionUtils.isNotEmpty(paramSetIndexParamsList)) {
            List<IndexParamsEntity> allParentIndexParams = new ArrayList<>();
            getParamsByParentParamNo(paramSetIndexParamsList, allParentIndexParams);
            concatParamSetIndexParam(allParentIndexParams, allParentIndexList, paramSetIndexParamsList);
        }

        // 指标分类：查询接口类型指标，查询所有父类指标, 并解析出相关参数信息
        List<IndexParamsEntity> apiIndexParamsList = indexParamsEntityList.stream().filter(index -> StringUtils.isNotEmpty(index.getScriptType()) && index.getScriptType().equalsIgnoreCase(ScriptTypeEnum.API.id)).collect(Collectors.toList());
        if (CollectionUtils.isNotEmpty(apiIndexParamsList)) {
            List<IndexParamsEntity> allParentIndexParams = new ArrayList<>();
            getAllParamsByParentParamNo(apiIndexParamsList, allParentIndexParams);
            // 查询接口名称
            List<String> intfNoList = allParentIndexParams.stream().map(IndexParamsEntity::getIntfNo).collect(Collectors.toList());
            List<String> supplierIdList = allParentIndexParams.stream().map(IndexParamsEntity::getSupplierId).collect(Collectors.toList());
            if (CollectionUtils.isNotEmpty(intfNoList) && CollectionUtils.isNotEmpty(supplierIdList)) {
                Map<String, String> intfMap = extIntfManageService.getExtIntfInfoList(intfNoList, supplierIdList);
                List<String> relateIndexNoList = concatIndexParam(allParentIndexParams, allParentIndexList, intfMap);
                if (CollectionUtils.isNotEmpty(relateIndexNoList)) {
                    handleRelateIndexSet(id, relateIndexSet, relateIndexNoList, allParentIndexList);
                }
            }
        }
        // 指标分类：查询非接口类型指标，查询所有父类指标, 并解析出相关参数信息
        List<IndexParamsEntity> sqlIndexParamsList = indexParamsEntityList.stream().filter(index -> StringUtils.isNotEmpty(index.getScriptType()) && index.getScriptType().equalsIgnoreCase(ScriptTypeEnum.SQL.id)).collect(Collectors.toList());
        if (CollectionUtils.isNotEmpty(sqlIndexParamsList)) {
            List<IndexParamsEntity> allParentIndexParams = new ArrayList<>();
            getParamsByParentParamNo(sqlIndexParamsList, allParentIndexParams);
            List<String> relateIndexNoList = concatIndexParam(allParentIndexParams, allParentIndexList, null);
            if (CollectionUtils.isNotEmpty(relateIndexNoList)) {
                handleRelateIndexSet(id, relateIndexSet, relateIndexNoList, allParentIndexList);
            }
        }
        // 对比当前指标参数信息，更新指标参数信息
        if (CollectionUtils.isNotEmpty(allParentIndexList)) {
            if (StringUtils.isNotEmpty(relateIndexSet)) {
                JSONArray jsonArray = JSONArray.parseArray(relateIndexSet);
                allParentIndexList.stream().map(index -> (JSONObject) index).forEach(index -> {
                    List<Object> collect = jsonArray.stream().filter(item -> ((JSONObject) item).getString("paramNo").equalsIgnoreCase(index.getString("paramNo"))).collect(Collectors.toList());
                    if (CollectionUtils.isNotEmpty(collect)) {
                        JSONObject object = (JSONObject) collect.get(0);
                        JSONArray originParams = object.getJSONArray("params");
                        JSONArray newParams = index.getJSONArray("params");
                        if (null != originParams && !originParams.isEmpty() && null != newParams && !newParams.isEmpty()) {
                            newParams.forEach(param -> {
                                JSONObject newParam = (JSONObject) param;
                                List<Object> objectList = originParams.stream().filter(item -> ((JSONObject) item).getString("field").equalsIgnoreCase(newParam.getString("field"))).collect(Collectors.toList());
                                if (CollectionUtils.isNotEmpty(objectList)) {
                                    JSONObject originParam = (JSONObject) objectList.get(0);
                                    newParam.put("sourceFlag", originParam.get("sourceFlag"));
                                    newParam.put("sourceField", originParam.get("sourceField"));
                                }
                            });
                        }
                    }
                });
            }
            knowledgeBaseParamsService.updateRelateIndexSet(id, JSON.toJSONString(allParentIndexList));
        }
    }

    private List<String> concatIndexParam(List<IndexParamsEntity> allParentIndexParams, JSONArray allParentIndexList, Map<String, String> intfMap) {
        List<String> relateParamNo = new ArrayList<>();
        allParentIndexParams.forEach(parent -> {
            JSONObject indexInfo = new JSONObject();
            String scriptType = parent.getScriptType();
            indexInfo.put("type", scriptType);
            indexInfo.put("paramNo", parent.getParamNo());
            indexInfo.put("paramName", parent.getParamName());
            JSONArray paramArr = new JSONArray();
            if (ScriptTypeEnum.API.id.equalsIgnoreCase(scriptType)) {
                indexInfo.put("intfNo", parent.getIntfNo());
                indexInfo.put("intfName", intfMap.get(parent.getSupplierId() + parent.getIntfNo()));
                indexInfo.put("supplierId", parent.getSupplierId());
                JSONArray interfaceParams = JSON.parseArray(parent.getIntfParams());
                if (null != interfaceParams && !interfaceParams.isEmpty()) {
                    for (Object param : interfaceParams) {
                        JSONObject paramObj = (JSONObject) param;
                        for (String key : paramObj.keySet()) {
                            JSONObject jsonObject = paramObj.getJSONObject(key);
                            String isSync = jsonObject.getString("isSync");
                            if ("N".equalsIgnoreCase(isSync)) {
                                continue;
                            }
                            JSONObject paramInfo = new JSONObject();
                            paramInfo.put("field", key);
                            String type = jsonObject.getString("type");
                            if (StringUtils.isNotEmpty(type)) {
                                paramInfo.put("fieldType", IntfParamTypeEnum.getById(type).name);
                            }
                            paramInfo.put("fieldName", jsonObject.getString("name"));
                            paramInfo.put("defaultValue", jsonObject.getString("value"));
                            JSONObject relateIndex = jsonObject.getJSONObject("relateIndex");
                            if (Objects.nonNull(relateIndex)) {
                                paramInfo.put("relateIndex", relateIndex.getString("name"));
                                relateParamNo.add(relateIndex.getString("no"));
                            }
                            paramInfo.put("sourceFlag", YesOrNoEnum.N.code);
                            paramInfo.put("sourceField", "");
                            paramArr.add(paramInfo);
                        }
                    }
                }
            }
            if (ScriptTypeEnum.SQL.id.equalsIgnoreCase(scriptType)) {
                String script = parent.getScript();
                /*
                 * 🔴 取数配置缺失 ⇒ 该指标**不进入取数入参集**（2026-09-19 加）。
                 *
                 * 原实现：script 为空时照常 put 一个 `params = []` 的指标 —— 取数层拿到空参数、
                 * 却仍会对该表做查询（`intfNo = columnFromTable`）⇒ **不带 reportNo 的全表查**，
                 * 同一批数据服务所有报告版本（实测 748 个指标处于此状态）。
                 *
                 * 现在直接跳过：指标不出现在 relateIndexSet 里 ⇒ 取数时不会被请求 ⇒ 值缺失，
                 * 由上层按"未取到值"处理（规则侧会走 missingValueCount / executeFailed 那条路），
                 * 而不是拿全表第一行算出个看起来正常的结论。
                 */
                if (StringUtils.isEmpty(script)) {
                    log.warn("【取数配置缺失】指标[{}] scriptType=Sql 但未配置取数SQL，"
                                    + "不加入取数入参集（避免生成不带 reportNo 的全表查询）。指标名={} 表={}",
                            parent.getParamNo(), parent.getParamName(), parent.getColumnFromTable());
                    return;
                }
                indexInfo.put("intfNo", parent.getColumnFromTable());
                indexInfo.put("intfName", parent.getParentParamName());
                indexInfo.put("supplierId", parent.getColumnFromDataSource());
                JSONObject object = JSON.parseObject(script);
                JSONArray paramData = object.getJSONArray("paramData");
                if (null != paramData && !paramData.isEmpty()) {
                    for (Object param : paramData) {
                        JSONObject paramObj = (JSONObject) param;
                        JSONObject paramInfo = new JSONObject();
                        String isSync = paramObj.getString("isSync");
                        if ("N".equalsIgnoreCase(isSync)) {
                            continue;
                        }
                        paramInfo.put("field", paramObj.getString("name"));
                        String type = paramObj.getString("type");
                        if (StringUtils.isNotEmpty(type)) {
                            paramInfo.put("fieldType", IntfParamTypeEnum.getById(type).name);
                        }
                        paramInfo.put("fieldName", paramObj.getString("desc"));
                        paramInfo.put("defaultValue", paramObj.getString("defaultValue"));
                        JSONObject relateIndex = paramObj.getJSONObject("relateIndex");
                        if (Objects.nonNull(relateIndex)) {
                            paramInfo.put("relateIndex", relateIndex.getString("name"));
                            relateParamNo.add(relateIndex.getString("no"));
                        }
                        paramInfo.put("sourceFlag", YesOrNoEnum.N.code);
                        paramInfo.put("sourceField", "");
                        paramArr.add(paramInfo);
                    }
                }
            }
            indexInfo.put("params", paramArr);
            // 去重
            Optional<Object> any = allParentIndexList.stream().filter(item -> ((JSONObject) item).getString("paramNo").equalsIgnoreCase(indexInfo.getString("paramNo"))).findAny();
            if (!any.isPresent()) {
                allParentIndexList.add(indexInfo);
            }
        });
        return relateParamNo;
    }

    private void concatParamSetIndexParam(List<IndexParamsEntity> allParentIndexParams, JSONArray allParentIndexList, List<IndexParamsEntity> indexParamsEntityList) {
        allParentIndexParams.forEach(parent -> {
            JSONObject indexInfo = new JSONObject();
            String scriptType = parent.getScriptType();
            indexInfo.put("type", scriptType);
            indexInfo.put("paramNo", parent.getParamNo());
            indexInfo.put("paramName", parent.getParamName());
            JSONArray paramArr = new JSONArray();

            indexParamsEntityList.forEach(indexParam -> {
                JSONObject paramInfo = new JSONObject();
                paramInfo.put("field", indexParam.getParamID());
                paramInfo.put("fieldType", IndexParamTypeEnum.getById(indexParam.getParamType()).name);
                paramInfo.put("fieldName", indexParam.getParamName());
                paramInfo.put("defaultValue", indexParam.getDefaultValue());
                paramInfo.put("sourceFlag", YesOrNoEnum.N.code);
                paramInfo.put("sourceField", "");
                paramArr.add(paramInfo);
            });

            indexInfo.put("params", paramArr);
            // 去重
            Optional<Object> any = allParentIndexList.stream().filter(item -> ((JSONObject) item).getString("paramNo").equalsIgnoreCase(indexInfo.getString("paramNo"))).findAny();
            if (!any.isPresent()) {
                allParentIndexList.add(indexInfo);
            }
        });
    }

    private boolean shouldProcessCondition(String joinCond, JSONArray variables, Map<String, Object> paramGroupResultMap) {
        if (StringUtils.isEmpty(joinCond) || CollectionUtils.isEmpty(variables)) {
            return true;
        }
        if (joinCond.toUpperCase(Locale.ROOT).equalsIgnoreCase("AND")) {
            return !variables.stream().map(r -> assertCond(r, paramGroupResultMap)).collect(Collectors.toList()).contains(false);
        } else {
            return variables.stream().anyMatch(r -> assertCond(r, paramGroupResultMap));
        }
    }

    private void processKnowledgeReferences(int[] indexes, JSONObject params, JSONObject ifCond, JSONArray promptArray, JSONArray resourceArray, Map<String, Object> paramGroupResultMap, Set<String> visitedKnowledgeIds) {
        JSONArray relateKnowledgeArr = ifCond.getJSONArray("reference");
        if (CollectionUtils.isEmpty(relateKnowledgeArr)) {
            return;
        }

        for (Object know : relateKnowledgeArr) {
            JSONObject knowObj = (JSONObject) know;
            String knowledgeId = knowObj.getString("knowledgeId");
            // 避免循环引用（直接自引用和多层循环引用）
            if (knowledgeId.equals(params.getString("paramId")) || visitedKnowledgeIds.contains(knowledgeId)) {
                continue;
            }
            visitedKnowledgeIds.add(knowledgeId);
            processSingleKnowledgeReference(indexes, params, knowObj, knowledgeId, promptArray, resourceArray, paramGroupResultMap, visitedKnowledgeIds);
        }
    }

    /**
     * 遍历prompt条件组，对满足条件的嵌套引用，通过processKnowledgeReferences递归处理。
     * 嵌套知识库走完整的processSingleKnowledgeReference流程（含拆分策略、大模型渲染等），
     * 结果放入指定的promptArray中。
     */
    private void collectNestedKnowledgeResults(int[] indexes, JSONObject params, String prompt, JSONArray promptArray, JSONArray resourceArray, Map<String, Object> paramGroupResultMap, Set<String> visitedKnowledgeIds) {
        try {
            if (StringUtils.isEmpty(prompt)) {
                return;
            }
            JSONArray promptCondGroups = JSONArray.parseArray(prompt);
            if (!checkContainReference(promptCondGroups)) {
                return;
            }
            for (Object condGroup : promptCondGroups) {
                JSONObject promptCondGroup = (JSONObject) condGroup;
                if (!promptCondGroup.containsKey("if")) {
                    continue;
                }
                JSONObject nestedIfCond = promptCondGroup.getJSONObject("if");
                String nestedJoinCond = nestedIfCond.getString("condition");
                JSONArray nestedVariables = nestedIfCond.getJSONArray("variables");
                if (shouldProcessCondition(nestedJoinCond, nestedVariables, paramGroupResultMap)) {
                    processKnowledgeReferences(indexes, params, nestedIfCond, promptArray, resourceArray, paramGroupResultMap, visitedKnowledgeIds);
                }
            }
        } catch (Exception e) {
            log.error("收集嵌套知识库结果失败，异常信息：{}", ExceptionUtils.getStackTrace(e));
        }
    }

    private void processSingleKnowledgeReference(int[] indexes, JSONObject params, JSONObject knowObj, String knowledgeId, JSONArray promptArray, JSONArray resourceArray, Map<String, Object> paramGroupResultMap, Set<String> visitedKnowledgeIds) {
        // 获取最新版本的知识库
        KnowledgeBaseParamsEntity knowledgeEntity;
        KnowledgeBaseVersionEntity knowledgeBaseVersionEntity = knowledgeBaseVersionService.getLatestVersion(knowledgeId);
        if (Objects.isNull(knowledgeBaseVersionEntity)) {
            knowledgeEntity = knowledgeBaseParamsService.getById(knowledgeId);
        } else {
            knowledgeEntity = new KnowledgeBaseParamsEntity();
            BeanUtil.copyProperties(knowledgeBaseVersionEntity, knowledgeEntity, true);
        }
        if (Objects.isNull(knowledgeEntity)) {
            return;
        }

        String largeModelCode = Optional.ofNullable(knowObj.getString("largeModelCode")).orElse("");
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("largeModelCode", largeModelCode);

        // 如果当前知识库还是嵌套知识库，继续递归处理
        Map<String, Object> promptResult = parsePromptWithCond(knowledgeEntity.getIsMarkdown(), indexes, knowledgeEntity.getRelateIndexSet(), knowledgeEntity.getPrompt(), params, paramGroupResultMap);
        if (Objects.nonNull(promptResult) && !promptResult.isEmpty()) {
            Object promptContent = promptResult.get("promptContent");

            // 1. 先收集嵌套知识库的最终结果（走完整的processSingleKnowledgeReference递归链路，嵌套KB自身也会判断拆分）
            JSONArray tempPromptArray = new JSONArray();
            collectNestedKnowledgeResults(indexes, params, knowledgeEntity.getPrompt(), tempPromptArray, resourceArray, paramGroupResultMap, visitedKnowledgeIds);

            // 2. 拼接：当前知识库文案 + 所有嵌套知识库结果
            StringBuffer combinedContent = new StringBuffer();
            if (StringUtils.isNotBlank(String.valueOf(promptContent))) {
                combinedContent.append(promptContent);
            }
            for (Object tempObj : tempPromptArray) {
                JSONObject tempJson = (JSONObject) tempObj;
                String nestedFinalContent = tempJson.getString("content");
                if (StringUtils.isNotBlank(nestedFinalContent)) {
                    combinedContent.append("\n").append(nestedFinalContent);
                }
            }

            // 3. 每一层都判断是否走拆分
            String splitStrategyParam = knowledgeEntity.getSplitStrategyParam();
            boolean strategyIsActive = StringUtils.isNotEmpty(splitStrategyParam) && !JSONObject.parseObject(splitStrategyParam).isEmpty() && JSONObject.parseObject(splitStrategyParam).getBoolean("isActive");
            if (strategyIsActive && combinedContent.length() > 0) {
                String knowledgeDesc = StringUtils.isEmpty(knowledgeEntity.getParamDescription()) ? knowledgeEntity.getParamName() : knowledgeEntity.getParamName() + "," + knowledgeEntity.getParamDescription();
                promptContent = handleSplitStrategyContent("", knowledgeDesc, splitStrategyParam, combinedContent.toString(), "", "", "N", largeModelCode, new JSONObject());
            } else if (combinedContent.length() > 0) {
                promptContent = combinedContent.toString();
            }

            if (Objects.nonNull(promptContent) && StringUtils.isNotEmpty(String.valueOf(promptContent))) {
                // 判断是否走大模型渲染
                if (StringUtils.isNotEmpty(largeModelCode) && !largeModelCode.equalsIgnoreCase("NONE")) {
                    Map<String, String> promptDescWithCond = getPromptDescWithCond(knowledgeEntity.getRelateIndexSet(), knowledgeEntity.getContentDesc(), knowledgeEntity.getInputCondition(), params, paramGroupResultMap);
                    String corePrompt = promptDescWithCond.get("corePrompt");
                    String promptDesc = promptDescWithCond.get("userPrompt");
                    if (StringUtils.isNotBlank(corePrompt)) {
                        promptDesc = (StringUtils.isNotBlank(promptDesc) ? promptDesc + "\n" + corePrompt : corePrompt);
                    }
                    if (StringUtils.isNotEmpty(promptDesc)) {
                        promptContent = promptContent + "\n" + promptDesc;
                    }
                    promptContent = getDividedPromptResult(largeModelCode, String.valueOf(promptContent));
                }
                jsonObject.put("content", promptContent + (StringUtils.isNotBlank(knowledgeEntity.getBusinessExperience()) ?  "\n" + knowledgeEntity.getBusinessExperience() + "\n" : ""));
                promptArray.add(jsonObject);
            }
            Object sourceCard = promptResult.get("sourceCard");
            if (Objects.nonNull(sourceCard) && !((JSONArray) sourceCard).isEmpty()) {
                JSONArray sourceCardArr = (JSONArray) sourceCard;
                resourceArray.addAll(sourceCardArr);
            }
        }
    }

    private Pair<Integer, Map<String, Object>> getResourcePrompt(Integer index, JSONArray resourceArr, Map<String, Object> paramGroupResultMap) {
        Map<String, Object> paramValueMap = Maps.newHashMap();
        for (Object resource : resourceArr) {
            StringBuffer prompt = new StringBuffer();
            JSONObject output = JSON.parseObject(JSON.toJSONString(resource)).getJSONObject("output");
            if (Objects.isNull(output)) {
                return null;
            }
            // 获取参数值
            JSONObject traceObj = JSON.parseObject(JSON.toJSONString(resource)).getJSONObject("config");
            if (Objects.isNull(traceObj)) {
                return Pair.of(index, paramValueMap);
            }
            String sourceType = traceObj.getString("sourceType");
            JSONArray defaultParams = traceObj.getJSONArray("defaultParams");
            // 如果是卡片类型，取出desc映射的字段，用于过滤字段内容为空的数据
            String paramMapping = "";
            if ("cardType".equals(sourceType) && defaultParams != null && !defaultParams.isEmpty()) {
                for (Object def : defaultParams) {
                    JSONObject defObj = JSON.parseObject(JSON.toJSONString(def));
                    String urlParam = defObj.getString("urlParam");
                    if (urlParam.equalsIgnoreCase("desc")) {
                        paramMapping = defObj.getString("paramMapping");
                        break;
                    }
                }
            }
            String paramNo = output.keySet().iterator().next();
            Object paramValue = getPromptValue(paramGroupResultMap, output, paramNo);
            if (Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue))) {
                continue;
            }
            // 根据溯源类型，生成文案
            if ("cardType".equals(sourceType) && paramValue instanceof JSONArray) {
                for (Object item : ((JSONArray) paramValue)) {
                    JSONObject itemObj = (JSONObject) item;
                    if (Objects.nonNull(itemObj.get(paramMapping)) && StringUtils.isNotEmpty(String.valueOf(itemObj.get(paramMapping)))) {
                        index++;
                        prompt.append("[查询结果 ").append(ParamUtil.getFullNumberStr(index)).append(" begin]\n");
                        prompt.append(JSONObject.toJSONString(itemObj));
                        prompt.append("[查询结果 ").append(ParamUtil.getFullNumberStr(index)).append(" end]\n");
                    } else {
                        prompt.append(JSONObject.toJSONString(itemObj));
                    }
                }
            } else {
                index++;
                prompt.append("[查询结果 ").append(ParamUtil.getFullNumberStr(index)).append(" begin]\n");
                prompt.append(paramValue);
                prompt.append("[查询结果 ").append(ParamUtil.getFullNumberStr(index)).append(" end]\n");
            }
            paramValueMap.put(paramNo, prompt.toString());
        }
        return Pair.of(index, paramValueMap);
    }

    private Pair<Integer, Map<String, Object>> getNewResourcePrompt(Integer index, Map<String, String> indexInfoMap, Map<String, Object> paramGroupResultMap) {
        Map<String, Object> paramValueMap = Maps.newHashMap();
        for (String paramNo : indexInfoMap.keySet()) {
            StringBuffer prompt = new StringBuffer();
            Object resource = indexInfoMap.get(paramNo);
            // 获取参数值
            JSONObject traceObj = JSONObject.parseObject(String.valueOf(resource));
            if (Objects.isNull(traceObj)) {
                continue;
            }
            String sourceType = traceObj.getString("sourceType");
            JSONArray defaultParams = traceObj.getJSONArray("defaultParams");
            // 如果是卡片类型，取出desc映射的字段，用于过滤字段内容为空的数据
            String paramMapping = "";
            if ("cardType".equals(sourceType) && defaultParams != null && !defaultParams.isEmpty()) {
                for (Object def : defaultParams) {
                    JSONObject defObj = JSON.parseObject(JSON.toJSONString(def));
                    String urlParam = defObj.getString("urlParam");
                    if (urlParam.equalsIgnoreCase("desc")) {
                        paramMapping = defObj.getString("paramMapping");
                        break;
                    }
                }
            }
            Object paramValue = paramGroupResultMap.get(paramNo);
            if (Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue))) {
                continue;
            }
            // 根据溯源类型，生成文案
            if ("cardType".equals(sourceType) && paramValue instanceof JSONArray) {
                for (Object item : ((JSONArray) paramValue)) {
                    JSONObject itemObj = (JSONObject) item;
                    if (Objects.nonNull(itemObj.get(paramMapping)) && StringUtils.isNotEmpty(String.valueOf(itemObj.get(paramMapping)))) {
                        index++;
                        prompt.append("[查询结果 ").append(ParamUtil.getFullNumberStr(index)).append(" begin]\n");
                        prompt.append(JSONObject.toJSONString(itemObj));
                        prompt.append("[查询结果 ").append(ParamUtil.getFullNumberStr(index)).append(" end]\n");
                    } else {
                        prompt.append(JSONObject.toJSONString(itemObj));
                    }
                }
            } else {
                index++;
                prompt.append("[查询结果 ").append(ParamUtil.getFullNumberStr(index)).append(" begin]\n");
                prompt.append(paramValue);
                prompt.append("[查询结果 ").append(ParamUtil.getFullNumberStr(index)).append(" end]\n");
            }
            paramValueMap.put(paramNo, prompt.toString());
        }
        return Pair.of(index, paramValueMap);
    }

    private Object getParamValueByCopy(Map<String, Object> paramGroupResultMap, JSONObject output, String paramNo, JSONArray defaultParams, String sourceType) {
        Object paramValue = paramGroupResultMap.get(paramNo);
        if (Objects.isNull(paramValue)) {
            return null;
        }
        JSONObject nameMapping = output.getJSONObject("nameMapping");
        JSONArray jsonArray = output.getJSONArray(paramNo);
        if (Objects.isNull(jsonArray) || jsonArray.isEmpty()) {
            return paramValue;
        }
        // 如果是卡片类型，取出desc映射的字段，用于过滤字段内容为空的数据
        String paramMapping = "";
        if ("cardType".equals(sourceType) && defaultParams != null && !defaultParams.isEmpty()) {
            for (Object def : defaultParams) {
                JSONObject defObj = JSON.parseObject(JSON.toJSONString(def));
                String urlParam = defObj.getString("urlParam");
                if (urlParam.equalsIgnoreCase("desc")) {
                    paramMapping = defObj.getString("paramMapping");
                    break;
                }
            }
        }
        if (paramValue instanceof JSONArray) {
            JSONArray resultArray = new JSONArray();
            JSONArray copyArray = new JSONArray();
            for (Object item : (JSONArray) paramValue) {
                JSONObject itemObj = (JSONObject) item;
                JSONObject copy = new JSONObject(true);
                jsonArray.forEach(key -> {
                    if (Objects.isNull(nameMapping) || nameMapping.isEmpty()) {
                        copy.put((String) key, itemObj.get(key));
                    } else {
                        copy.put(nameMapping.getString((String) key), itemObj.get(key));
                    }
                });
                copyArray.add(copy);
                if (copy.containsKey(paramMapping) && Objects.nonNull(copy.get(paramMapping)) && StringUtils.isNotEmpty(String.valueOf(copy.get(paramMapping)))) {
                    resultArray.add(copy);
                }
            }
            if ("cardType".equals(sourceType)) {
                return resultArray;
            } else {
                return copyArray;
            }
        }
        if (paramValue instanceof JSONObject) {
            Set<String> allowedFields = new HashSet<>(jsonArray.toJavaList(String.class));
            JSONObject itemObj = (JSONObject) paramValue;
            JSONObject copy = new JSONObject();
            itemObj.keySet().forEach(key -> {
                if (allowedFields.contains(key)) {
                    copy.put(key, itemObj.get(key));
                }
            });
            if (Objects.nonNull(itemObj.get(paramMapping)) && StringUtils.isNotEmpty(String.valueOf(copy.get(paramMapping)))) {
                return null;
            }
            return copy;
        }
        return paramValue;
    }

    private Object getPromptValue(Map<String, Object> paramGroupResultMap, JSONObject output, String paramNo) {
        Object paramValue = paramGroupResultMap.get(paramNo);
        if (Objects.isNull(paramValue)) {
            return null;
        }
        JSONArray jsonArray = output.getJSONArray(paramNo);
        if (Objects.isNull(jsonArray) || jsonArray.isEmpty()) {
            return paramValue;
        }
        if (paramValue instanceof JSONArray) {
            Set<String> allowedFields = new HashSet<>(jsonArray.toJavaList(String.class));
            JSONArray resultArray = new JSONArray();
            for (Object item : (JSONArray) paramValue) {
                JSONObject itemObj = (JSONObject) item;
                JSONObject copy = new JSONObject();
                itemObj.keySet().forEach(key -> {
                    if (allowedFields.contains(key)) {
                        copy.put(key, itemObj.get(key));
                    }
                });
                resultArray.add(copy);
            }
            return resultArray;
        }
        if (paramValue instanceof JSONObject) {
            Set<String> allowedFields = new HashSet<>(jsonArray.toJavaList(String.class));
            JSONObject itemObj = (JSONObject) paramValue;
            JSONObject copy = new JSONObject();
            itemObj.keySet().forEach(key -> {
                if (allowedFields.contains(key)) {
                    copy.put(key, itemObj.get(key));
                }
            });
            return copy;
        }
        return paramValue;
    }

    private Pair<Integer, JSONArray> getResourceContent(Integer index, JSONArray resourceArr, Map<String, Object> dataMap) {
        JSONArray resourceArray = new JSONArray();
        for (Object resource : resourceArr) {
            JSONObject output = JSON.parseObject(JSON.toJSONString(resource)).getJSONObject("output");
            if (Objects.isNull(output)) {
                continue;
            }
            String paramNo = output.keySet().iterator().next();
            // 获取参数值
            JSONObject traceObj = JSON.parseObject(JSON.toJSONString(resource)).getJSONObject("config");
            if (Objects.isNull(traceObj)) {
                return Pair.of(index, resourceArray);
            }
            String sourceType = traceObj.getString("sourceType");
            JSONArray defaultParams = traceObj.getJSONArray("defaultParams");
            Object paramValue = dataMap.get(paramNo);
            if (Objects.isNull(paramValue)) {
                continue;
            }
            // 全部来源
            JSONArray wholeSourceConfig = traceObj.getJSONArray("wholeSourceConfig");
            JSONObject wholeSource = null;
            if (CollectionUtils.isNotEmpty(wholeSourceConfig)) {
                wholeSource = wholeSourceConfig.getJSONObject(0);
            }
            if (StringUtils.isNotEmpty(sourceType) && "cardType".equals(sourceType)) {
                JSONArray inputParams = traceObj.getJSONArray("inputParam");
                JSONArray jsonArray;
                if (paramValue instanceof JSONObject) {
                    jsonArray = new JSONArray();
                    jsonArray.add(paramValue);
                } else {
                    jsonArray = (JSONArray) paramValue;
                }
                // card内容解析
                for (Object obj : jsonArray) {
                    JSONObject object = (JSONObject) obj;
                    JSONObject newJson = new JSONObject();
                    if (CollectionUtils.isNotEmpty(defaultParams)) {
                        for (Object def : defaultParams) {
                            JSONObject defObj = JSON.parseObject(JSON.toJSONString(def));
                            Object paramMapping = object.get(defObj.getString("paramMapping"));
                            newJson.put(defObj.getString("urlParam"), paramMapping);
                        }
                        JSONArray externalField = new JSONArray();
                        if (CollectionUtils.isNotEmpty(inputParams)) {
                            inputParams.forEach(input -> {
                                JSONObject inputObj = JSON.parseObject(JSON.toJSONString(input));
                                Object paramMapping = object.get(inputObj.getString("paramMapping"));
                                JSONObject newInputObj = new JSONObject();
                                newInputObj.put("name", inputObj.getString("paramName"));
                                newInputObj.put("value", Objects.isNull(paramMapping) ? "" : paramMapping);
                                externalField.add(newInputObj);
                            });
                        }
                        if (Objects.nonNull(wholeSource)) {
                            JSONObject newAppParams = new JSONObject();
                            String appId = wholeSource.getString("appId");
                            String pageId = wholeSource.getString("pageId");
                            JSONArray inputParam = wholeSource.getJSONArray("inputParam");
                            if (null != inputParam && !inputParam.isEmpty()) {
                                JSONArray newInputParam = new JSONArray();
                                inputParam.forEach(param -> {
                                    JSONObject paramObj = (JSONObject) param;
                                    JSONObject jsonObject = new JSONObject();
                                    jsonObject.put("name", paramObj.getString("urlParam"));
                                    String paramMapping = object.getString(paramObj.getString("paramMapping"));
                                    if (object.containsKey(paramObj.getString("paramMapping"))) {
                                        jsonObject.put("value", StringUtils.isEmpty(paramMapping) ? "" : paramMapping);
                                    } else {
                                        jsonObject.put("value", StringUtils.isEmpty(paramObj.getString("defaultValue")) ? "" : paramObj.getString("defaultValue"));
                                    }
                                    newAppParams.put(jsonObject.getString("name"), jsonObject.get("value"));
                                    newInputParam.add(jsonObject);
                                });
                                newJson.put("params", newInputParam);
                                // 添加pageId
                                if (StringUtils.isNotEmpty(pageId)) {
                                    newJson.put("pageId", pageId);
                                }
                            }
                            // 添加appId
                            if (StringUtils.isNotEmpty(appId)) {
                                newJson.put("appId", appId);
                                newJson.put("appParams", newAppParams);
                            }
                        }
                        Object desc = newJson.get("desc");
                        if (Objects.nonNull(desc) && StringUtils.isNotEmpty(String.valueOf(desc))) {
                            index++;
                            newJson.put("id", ParamUtil.getFullNumberStr(index));
                            newJson.put("externalField", externalField);
                            resourceArray.add(newJson);
                        }
                    }
                }
            } else {
                // html内容解析+原始文本输出
                Object value = getParamValueByCopy(dataMap, output, paramNo, defaultParams, sourceType);
                if (Objects.nonNull(value) && StringUtils.isNotEmpty(String.valueOf(value))) {
                    index++;
                    String content = JsonToMarkdown.transferJsonToMarkDown(JSONObject.toJSONString(paramValue));
                    JSONObject newInputObj = new JSONObject();
                    newInputObj.put("id", ParamUtil.getFullNumberStr(index));
                    newInputObj.put("title", traceObj.getString("title"));
                    newInputObj.put("desc", traceObj.getString("title"));
                    newInputObj.put("siteName", traceObj.getString("site"));
                    newInputObj.put("content", content);
                    resourceArray.add(newInputObj);
                }
            }
            log.info("完成解析卡片[{}][{}]数据", traceObj.get("id"), traceObj.get("card_title"));
        }
        return Pair.of(index, resourceArray);
    }

    private Pair<Integer, JSONArray> getNewResourceContent(Integer index, Map<String, String> indexInfoMap, Map<String, Object> dataMap) {
        JSONArray resourceArray = new JSONArray();
        for (String paramNo : indexInfoMap.keySet()) {// 获取参数值
            Object resource = indexInfoMap.get(paramNo);
            // 获取参数值
            JSONObject traceObj = JSONObject.parseObject(String.valueOf(resource));
            if (Objects.isNull(traceObj)) {
                continue;
            }
            String sourceType = traceObj.getString("sourceType");
            JSONArray defaultParams = traceObj.getJSONArray("defaultParams");
            Object paramValue = dataMap.get(paramNo);
            if (Objects.isNull(paramValue)) {
                continue;
            }
            // 全部来源
            JSONArray wholeSourceConfig = traceObj.getJSONArray("wholeSourceConfig");
            JSONObject wholeSource = null;
            if (CollectionUtils.isNotEmpty(wholeSourceConfig)) {
                wholeSource = wholeSourceConfig.getJSONObject(0);
            }
            if (StringUtils.isNotEmpty(sourceType) && "cardType".equals(sourceType)) {
                JSONArray inputParams = traceObj.getJSONArray("inputParam");
                JSONArray jsonArray;
                if (paramValue instanceof JSONObject) {
                    jsonArray = new JSONArray();
                    jsonArray.add(paramValue);
                } else {
                    jsonArray = (JSONArray) paramValue;
                }
                // card内容解析
                for (Object obj : jsonArray) {
                    JSONObject object = (JSONObject) obj;
                    JSONObject newJson = new JSONObject();
                    if (CollectionUtils.isNotEmpty(defaultParams)) {
                        for (Object def : defaultParams) {
                            JSONObject defObj = JSON.parseObject(JSON.toJSONString(def));
                            Object paramMapping = object.get(defObj.getString("paramMapping"));
                            newJson.put(defObj.getString("urlParam"), paramMapping);
                        }
                        JSONArray externalField = new JSONArray();
                        if (CollectionUtils.isNotEmpty(inputParams)) {
                            inputParams.forEach(input -> {
                                JSONObject inputObj = JSON.parseObject(JSON.toJSONString(input));
                                Object paramMapping = object.get(inputObj.getString("paramMapping"));
                                JSONObject newInputObj = new JSONObject();
                                newInputObj.put("name", inputObj.getString("paramName"));
                                newInputObj.put("value", Objects.isNull(paramMapping) ? "" : paramMapping);
                                externalField.add(newInputObj);
                            });
                        }
                        if (Objects.nonNull(wholeSource)) {
                            JSONObject newAppParams = new JSONObject();
                            String appId = wholeSource.getString("appId");
                            String pageId = wholeSource.getString("pageId");
                            JSONArray inputParam = wholeSource.getJSONArray("inputParam");
                            if (null != inputParam && !inputParam.isEmpty()) {
                                JSONArray newInputParam = new JSONArray();
                                inputParam.forEach(param -> {
                                    JSONObject paramObj = (JSONObject) param;
                                    JSONObject jsonObject = new JSONObject();
                                    jsonObject.put("name", paramObj.getString("urlParam"));
                                    String paramMapping = object.getString(paramObj.getString("paramMapping"));
                                    if (object.containsKey(paramObj.getString("paramMapping"))) {
                                        jsonObject.put("value", StringUtils.isEmpty(paramMapping) ? "" : paramMapping);
                                    } else {
                                        jsonObject.put("value", StringUtils.isEmpty(paramObj.getString("defaultValue")) ? "" : paramObj.getString("defaultValue"));
                                    }
                                    newAppParams.put(jsonObject.getString("name"), jsonObject.get("value"));
                                    newInputParam.add(jsonObject);
                                });
                                newJson.put("params", newInputParam);
                                // 添加pageId
                                if (StringUtils.isNotEmpty(pageId)) {
                                    newJson.put("pageId", pageId);
                                }
                            }
                            // 添加appId
                            if (StringUtils.isNotEmpty(appId)) {
                                newJson.put("appId", appId);
                                newJson.put("appParams", newAppParams);
                            }
                        }
                        Object desc = newJson.get("desc");
                        if (Objects.nonNull(desc) && StringUtils.isNotEmpty(String.valueOf(desc))) {
                            index++;
                            newJson.put("id", ParamUtil.getFullNumberStr(index));
                            newJson.put("externalField", externalField);
                            resourceArray.add(newJson);
                        }
                    }
                }
            } else {
                // html内容解析+原始文本输出
                JSONObject output = new JSONObject();
                String innerHtml = traceObj.getString("html");
                if (StringUtils.isNotEmpty(innerHtml)) {
                    String html = innerHtml.replace("<br />", "").replace("&nbsp;", "");
                    if (StringUtils.isNotEmpty(html)) {
                        Pair<List<String>, Map<String, String>> inputField = htmlConvertor.getInputField(html);
                        output.put(paramNo, inputField.getLeft());
                        output.put("nameMapping", inputField.getRight());
                    }
                }

                Object value = getParamValueByCopy(dataMap, output, paramNo, defaultParams, sourceType);
                if (Objects.nonNull(value) && StringUtils.isNotEmpty(String.valueOf(value))) {
                    index++;
                    String content = JsonToMarkdown.transferJsonToMarkDown(JSONObject.toJSONString(value));
                    JSONObject newInputObj = new JSONObject();
                    newInputObj.put("id", ParamUtil.getFullNumberStr(index));
                    newInputObj.put("title", traceObj.getString("title"));
                    newInputObj.put("desc", traceObj.getString("title"));
                    newInputObj.put("siteName", traceObj.getString("site"));
                    newInputObj.put("content", content);
                    resourceArray.add(newInputObj);
                }
            }
            log.info("完成解析卡片[{}][{}]数据", traceObj.get("id"), traceObj.get("card_title"));
        }
        return Pair.of(index, resourceArray);
    }

    private String getResourcePreview(List<JSONObject> traceConfigArr, String relateIndexSet, JSONObject params) {
        List<String> allParamNoList = new ArrayList<>();
        Map<String, Object> dataMap = new HashMap<>();
        List<IndexParamsEntity> paramList = new ArrayList<>();
        HtmlCleaner htmlCleaner = new HtmlCleaner();
        for (JSONObject trace : traceConfigArr) {
            JSONObject traceObj = trace.getJSONObject("config");
            String sourceAnchor = traceObj.getString("source_anchor");
            List<String> sourceParamNoList = ParamUtil.getParamNoList(sourceAnchor);
            if (CollectionUtils.isNotEmpty(sourceParamNoList)) {
                allParamNoList.addAll(sourceParamNoList);
            }
            // 提取html中涉及的指标
            String html = traceObj.getString("html").replace("<br />", "").replace("&nbsp;", "");
            if (StringUtils.isNotEmpty(html)) {
                TagNode tagNode = htmlCleaner.clean(html);
                List<? extends TagNode> allNodes;
                if ("v2".equalsIgnoreCase(params.getString("version"))) {
                    allNodes = tagNode.getElementListHavingAttribute("data-mce-annotation", true);
                    if (CollectionUtils.isNotEmpty(allNodes)) {
                        Set<String> htmlParamNoList = allNodes.stream().map(node -> node.getAllChildren().get(0).toString().split("\\|\\|")[1].replace("}}", "")).collect(Collectors.toSet());
                        allParamNoList.addAll(htmlParamNoList);
                    }
                } else {
                    allNodes = tagNode.getElementListHavingAttribute("data-param-no", true);
                    if (CollectionUtils.isNotEmpty(allNodes)) {
                        Set<String> htmlParamNoList = allNodes.stream().map(node -> node.getAttributeByName("data-param-no")).collect(Collectors.toSet());
                        allParamNoList.addAll(htmlParamNoList);
                    }
                }
            }
        }

        if (CollectionUtils.isNotEmpty(allParamNoList)) {
            // 查询相关指标信息
            List<IndexParamsEntity> indexParamsEntityList = indexParamsService.listByIds(allParamNoList);
            List<IndexParamsEntity> apiCollect = indexParamsEntityList.stream().filter(index -> "Api".equalsIgnoreCase(index.getScriptType())).collect(Collectors.toList());
            List<IndexParamsEntity> sqlCollect = indexParamsEntityList.stream().filter(index -> !"Api".equalsIgnoreCase(index.getScriptType())).collect(Collectors.toList());
            if (CollectionUtils.isNotEmpty(apiCollect)) {
                Set<String> set = apiCollect.stream().map(IndexParamsEntity::getOtherNo).collect(Collectors.toSet());
                List<IndexParamsEntity> apiParamList = indexParamsService.selectByOtherNoList(new ArrayList<>(set));
                paramList.addAll(apiParamList);
                allParamNoList.addAll(set);
            }
            if (CollectionUtils.isNotEmpty(sqlCollect)) {
                Set<String> set = sqlCollect.stream().map(IndexParamsEntity::getParentParamNo).collect(Collectors.toSet());
                List<IndexParamsEntity> sqlParamList = indexParamsService.selectByParentParamNoList(new ArrayList<>(set));
                paramList.addAll(sqlParamList);
                allParamNoList.addAll(set);
            }
            // 获取指标数据集合
            dataMap = handleParam(relateIndexSet, params, allParamNoList, new HashMap<>(0), Maps.newHashMap());
        }

        List<JSONObject> finalTraceConfigArr = new CopyOnWriteArrayList<>();
        for (JSONObject trace : traceConfigArr) {
            JSONObject output = trace.getJSONObject("output");
            if (Objects.isNull(output) || output.isEmpty()) {
                return null;
            }
            String paramNo = output.keySet().iterator().next();
            Object paramValue = dataMap.get(paramNo);
            if (Objects.isNull(paramValue)) {
                continue;
            }
            // 溯源指标解析
            JSONObject traceObj = trace.getJSONObject("config");
            String sourceType = traceObj.getString("sourceType");
            if (StringUtils.isNotEmpty(sourceType) && "cardType".equals(sourceType)) {
                JSONArray sourceArray = new JSONArray();
                JSONArray inputParams = traceObj.getJSONArray("inputParam");
                JSONArray defaultParams = traceObj.getJSONArray("defaultParams");
                if (CollectionUtils.isNotEmpty(defaultParams)) {
                    List<JSONObject> collect = defaultParams.stream().map(obj -> JSON.parseObject(JSON.toJSONString(obj))).filter(def -> OnlineEnum.Y.name().equalsIgnoreCase(def.getString("isSourceMatch"))).collect(Collectors.toList());
                    sourceArray.addAll(collect);
                }
                if (CollectionUtils.isNotEmpty(inputParams)) {
                    List<JSONObject> collect = inputParams.stream().map(def -> JSON.parseObject(JSON.toJSONString(def))).filter(def -> OnlineEnum.Y.name().equalsIgnoreCase(def.getString("isSourceMatch"))).collect(Collectors.toList());
                    sourceArray.addAll(collect);
                }
                JSONArray jsonArray;
                if (paramValue instanceof JSONObject) {
                    jsonArray = new JSONArray();
                    jsonArray.add(paramValue);
                } else {
                    jsonArray = (JSONArray) paramValue;
                }
                // card内容解析
                jsonArray.forEach(parse -> {
                    JSONObject object = (JSONObject) parse;
                    JSONObject newJson = new JSONObject();

                    if (CollectionUtils.isNotEmpty(defaultParams)) {
                        defaultParams.forEach(def -> {
                            JSONObject defObj = JSON.parseObject(JSON.toJSONString(def));
                            Object paramMapping = object.get(defObj.getString("paramMapping"));
                            newJson.put(defObj.getString("urlParam"), Objects.isNull(paramMapping) ? "" : paramMapping);
                        });

                        // 判断是否为空
                        if (TreeUtil.checkAllValuesEmpty(newJson)) {
                            newJson.put("id", UUID.fastUUID().toString());
                            newJson.put("card_title", newJson.get("title"));
                            JSONArray externalField = new JSONArray();
                            if (CollectionUtils.isNotEmpty(inputParams)) {
                                inputParams.forEach(input -> {
                                    JSONObject inputObj = JSON.parseObject(JSON.toJSONString(input));
                                    Object paramMapping = object.get(inputObj.getString("paramMapping"));
                                    JSONObject newInputObj = new JSONObject();
                                    newInputObj.put("name", inputObj.getString("paramName"));
                                    newInputObj.put("value", Objects.isNull(paramMapping) ? "" : paramMapping);
                                    externalField.add(newInputObj);
                                });
                            }
                            newJson.put("externalField", externalField);

                            // 是否溯源逻辑过滤
                            if (!sourceArray.isEmpty()) {
                                JSONArray finalSourceArr = new JSONArray();
                                JSONObject finalSource = new JSONObject();
                                List<String> paramMapping = sourceArray.stream().map(obj -> ((JSONObject) obj).getString("paramMapping")).collect(Collectors.toList());
                                paramMapping.forEach(map -> finalSource.put(map, object.getString(map)));
                                finalSourceArr.add(finalSource);
                                newJson.put("source_anchor", JSON.toJSONString(finalSourceArr));
                            }
                            finalTraceConfigArr.add(newJson);
                        }
                    }
                });
            } else if (StringUtils.isEmpty(sourceType) || "listType".equals(sourceType)) {
                // html内容解析
                String html = traceObj.getString("html").replace("<br />", "").replace("&nbsp;", "");
                JSONObject newInputObj = new JSONObject();
                if (StringUtils.isNotEmpty(html)) {
                    TagNode tagNode = htmlCleaner.clean(html);
                    TagNode convert;
                    if ("v2".equalsIgnoreCase(params.getString("version"))) {
                        convert = htmlConvertor.convertV2(tagNode, dataMap, paramList);
                    } else {
                        convert = htmlConvertor.convert(tagNode, dataMap, paramList);
                    }
                    List<? extends TagNode> table = convert.getElementListByName("table", true);
                    String htmlContent = "";
                    if (CollectionUtils.isNotEmpty(table) && table.get(0).hasChildren()) {
                        htmlContent = DOMUtils.toString(convert);
                    }
                    newInputObj.put("html", htmlContent);
                    newInputObj.put("id", StringUtils.isEmpty(traceObj.getString("id")) ? UUID.fastUUID().toString() : traceObj.getString("id"));
                    newInputObj.put("source_index", traceObj.getString("source_index"));
                    newInputObj.put("card_title", "");
                    newInputObj.put("source_anchor", traceObj.getString("source_anchor"));
                    finalTraceConfigArr.add(newInputObj);
                }
            } else {
                // 原始文本输出
                String html = traceObj.getString("html").replace("<br />", "").replace("&nbsp;", "");
                if (StringUtils.isNotEmpty(html) && "v2".equalsIgnoreCase(params.getString("version"))) {
                    Pair<List<String>, Map<String, String>> inputField = htmlConvertor.getInputField(html);
                    output.put(paramNo, inputField.getLeft());
                    output.put("nameMapping", inputField.getRight());
                }
                Object paramValueByCopy = getParamValueByCopy(dataMap, output, paramNo, traceObj.getJSONArray("defaultParams"), sourceType);
                if (Objects.nonNull(paramValueByCopy) && StringUtils.isNotEmpty(String.valueOf(paramValueByCopy))) {
                    JSONObject newInputObj = new JSONObject();
                    newInputObj.put("id", StringUtils.isEmpty(traceObj.getString("id")) ? UUID.fastUUID().toString() : traceObj.getString("id"));
                    newInputObj.put("source_index", traceObj.getString("source_index"));
                    newInputObj.put("card_title", "");
                    newInputObj.put("source_anchor", traceObj.getString("source_anchor"));
                    newInputObj.put("html", JsonToMarkdown.transferJsonToMarkDown(JSONObject.toJSONString(paramValueByCopy)));
                    finalTraceConfigArr.add(newInputObj);
                }
            }
        }
        return JSONObject.toJSONString(finalTraceConfigArr);
    }

    private boolean assertCond(Object r, Map<String, Object> valueMap) {
        try {
            if (!(r instanceof JSONObject)) {
                log.warn("r is null or is not json object");
                return false;
            }
            JSONObject cond = (JSONObject) r;
            String fieldName;
            String tabType = cond.getString("tabType");
            if ("rule".equalsIgnoreCase(tabType)) {
                fieldName = cond.getString("field") + "_" + cond.getString("label");
            } else {
                fieldName = cond.getString("field");
            }
            if (StringUtils.isEmpty(fieldName)) {
                log.warn("fieldName is empty");
                return false;
            }

            Object fieldVal;
            String dataType = cond.getString("data_type");
            if (!valueMap.containsKey(fieldName)) {
                if (dataType.equals(DataTypeEnum.NUMBER.getValue())) {
                    fieldVal = 0;
                } else if (dataType.equals(DataTypeEnum.BOOLEAN.getValue())) {
                    fieldVal = false;
                } else {
                    fieldVal = null;
                }
            } else {
                fieldVal = valueMap.get(fieldName);
            }

            String op = cond.getString("operator");
            if (StringUtils.isEmpty(op)) {
                log.warn("operator is empty");
                return false;
            }
            op = op.replaceAll("\\s+", "");
            List<String> ops = Arrays.stream(OpTypeEnum.values()).map(x -> x.getValue()).collect(Collectors.toList());
            if (!ops.contains(op)) {
                log.warn("operator is invalid:{}", op);
                return false;
            }

            if (StringUtils.isEmpty(dataType)) {
                log.warn("data_type is empty");
                return false;
            }
            List<String> dataTypes = Arrays.stream(DataTypeEnum.values()).map(x -> x.getValue()).collect(Collectors.toList());
            if (!dataTypes.contains(dataType)) {
                log.warn("dataType is invalid:{}", dataType);
                return false;
            }

            String rightValue;
            String value = cond.getString("value");
            String valueType = cond.getString("valueType");
            if (StringUtils.isNotEmpty(valueType) && valueType.equals("indicator")) {
                rightValue = Objects.isNull(valueMap.get(value)) ? "" : String.valueOf(valueMap.get(value));
            } else {
                rightValue = value;
            }
            if (dataType.equals(DataTypeEnum.ARRAY.getValue())) {
                return assertListCond(fieldVal, op, rightValue);
            } else if (dataType.equals(DataTypeEnum.NUMBER.getValue())) {
                return assertNumCond(fieldVal, op, rightValue);
            } else if (dataType.equals(DataTypeEnum.STRING.getValue())) {
                return assertStrCond(fieldVal, op, rightValue);
            } else if (dataType.equals(DataTypeEnum.DATE.getValue())) {
                return assertDateCond(fieldVal, op, rightValue);
            } else if (dataType.equals(DataTypeEnum.BOOLEAN.getValue())) {
                return assertBoolCond(fieldVal, op);
            } else {
                return false;
            }
        } catch (Exception e) {
            log.error("分组条件判断异常，异常信息为：{}", ExceptionUtils.getStackTrace(e));
            return false;
        }
    }

    private boolean assertDateCond(Object fieldVal, String op, String rightValue) {
        if (op.equals(OpTypeEnum.EQ.getValue())) {
            if (fieldVal == null) {
                return false;
            } else {
                return fieldVal.toString().equals(rightValue);
            }
        } else if (op.equals(OpTypeEnum.NE.getValue())) {
            if (fieldVal == null) {
                return false;
            } else {
                return !fieldVal.toString().equals(rightValue);
            }
        } else if (op.equals(OpTypeEnum.IS_NULL.getValue())) {
            if (fieldVal == null) {
                return true;
            } else {
                return fieldVal.toString().equals("");
            }
        } else if (op.equals(OpTypeEnum.IS_NOT_NULL.getValue())) {
            if (fieldVal == null) {
                return false;
            } else {
                return !fieldVal.toString().equals("");
            }
        } else if (op.equals(OpTypeEnum.GT.getValue())) {
            if (fieldVal == null) {
                return false;
            } else {
                return fieldVal.toString().compareToIgnoreCase(rightValue) > 0;
            }
        } else if (op.equals(OpTypeEnum.GTE.getValue())) {
            if (fieldVal == null) {
                return false;
            } else {
                return fieldVal.toString().compareToIgnoreCase(rightValue) >= 0;
            }
        } else if (op.equals(OpTypeEnum.LT.getValue())) {
            if (fieldVal == null) {
                return false;
            } else {
                return fieldVal.toString().compareToIgnoreCase(rightValue) < 0;
            }
        } else if (op.equals(OpTypeEnum.LTE.getValue())) {
            if (fieldVal == null) {
                return false;
            } else {
                return fieldVal.toString().compareToIgnoreCase(rightValue) <= 0;
            }
        } else if (op.equals(OpTypeEnum.CONTAINS.getValue())) {
            if (fieldVal == null) {
                return false;
            } else {
                return fieldVal.toString().contains(rightValue);
            }
        } else if (op.equals(OpTypeEnum.NOT_CONTAINS.getValue())) {
            if (fieldVal == null) {
                return false;
            } else {
                return !fieldVal.toString().contains(rightValue);
            }
        } else {
            return false;
        }
    }

    private boolean assertBoolCond(Object fieldVal, String op) {
        if (!(fieldVal instanceof Boolean)) {
            return false;
        }
        if (op.equals(OpTypeEnum.IS_TRUE.getValue())) {
            return fieldVal == Boolean.TRUE;
        } else if (op.equals(OpTypeEnum.IS_FALSE.getValue())) {
            return fieldVal == Boolean.FALSE;
        }
        return false;
    }

    private boolean assertListCond(Object fieldVal, String op, String rightValue) {
        // log.info("assertListCond fieldVal:{} op:{} rightValue:{}", fieldVal, op, rightValue);
        if (fieldVal == null) {
            if (op.equals(OpTypeEnum.IS_NULL.getValue())) {
                return true;
            } else {
                return false;
            }
        }

        List<String> fieldValList = new ArrayList<>();
        if (fieldVal instanceof List) {
            fieldValList = (List<String>) ((List) fieldVal).stream().map(r -> r.toString()).collect(Collectors.toList());
        } else if (fieldVal instanceof Object[]) {
            for (Object r : (Object[]) fieldVal) {
                fieldValList.add(r.toString());
            }
        } else {
            if (StringUtils.isNotEmpty(fieldVal.toString())) {
                fieldValList.add(String.valueOf(fieldVal));
            }
        }

        // log.info("fieldVal type:{} op:{} fieldValList size:{}", fieldVal.getClass().getName(), op, fieldValList.size());

        if (op.equals(OpTypeEnum.LEN_EQ.getValue())) {
            return fieldValList.size() == Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_NE.getValue())) {
            return fieldValList.size() != Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_GT.getValue())) {
            return fieldValList.size() > Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_GTE.getValue())) {
            return fieldValList.size() >= Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_LT.getValue())) {
            return fieldValList.size() < Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_LTE.getValue())) {
            return fieldValList.size() <= Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.CONTAINS.getValue())) {
            return fieldValList.contains(rightValue);
        } else if (op.equals(OpTypeEnum.NOT_CONTAINS.getValue())) {
            return !fieldValList.contains(rightValue);
        } else if (op.equals(OpTypeEnum.IS_NOT_NULL.getValue())) {
            return fieldValList.size() > 0;
        } else if (op.equals(OpTypeEnum.IS_NULL.getValue())) {
            return fieldValList.size() == 0;
        } else {
            return false;
        }
    }

    private boolean assertStrCond(Object fieldVal, String op, String rightValue) {
        // log.info("assertStrCond fieldVal:{} op:{} rightValue:{}", fieldVal, op, rightValue);
        if (fieldVal == null) {
            if (op.equals(OpTypeEnum.IS_NULL.getValue())) {
                return true;
            } else {
                return false;
            }
        }

        String leftValue = fieldVal.toString();
        // log.info("leftValue:{}", leftValue);
        if (op.equals(OpTypeEnum.EQ.getValue())) {
            return leftValue.equals(rightValue);
        } else if (op.equals(OpTypeEnum.NE.getValue())) {
            return !leftValue.equals(rightValue);
        } else if (op.equals(OpTypeEnum.IS_NULL.getValue())) {
            return leftValue.equals("");
        } else if (op.equals(OpTypeEnum.IS_NOT_NULL.getValue())) {
            return !leftValue.equals("");
        } else if (op.equals(OpTypeEnum.GT.getValue())) {
            return leftValue.compareToIgnoreCase(rightValue) > 0;
        } else if (op.equals(OpTypeEnum.GTE.getValue())) {
            return leftValue.compareToIgnoreCase(rightValue) >= 0;
        } else if (op.equals(OpTypeEnum.LT.getValue())) {
            return leftValue.compareToIgnoreCase(rightValue) < 0;
        } else if (op.equals(OpTypeEnum.LTE.getValue())) {
            return leftValue.compareToIgnoreCase(rightValue) <= 0;
        } else if (op.equals(OpTypeEnum.CONTAINS.getValue())) {
            return leftValue.contains(rightValue);
        } else if (op.equals(OpTypeEnum.NOT_CONTAINS.getValue())) {
            return !leftValue.contains(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_GT.getValue())) {
            return leftValue.length() > Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_GTE.getValue())) {
            return leftValue.length() >= Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_LT.getValue())) {
            return leftValue.length() < Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_LTE.getValue())) {
            return leftValue.length() <= Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_EQ.getValue())) {
            return leftValue.length() == Integer.valueOf(rightValue);
        } else if (op.equals(OpTypeEnum.LEN_NE.getValue())) {
            return leftValue.length() != Integer.valueOf(rightValue);
        } else {
            return false;
        }
    }

    private boolean assertNumCond(Object fieldVal, String op, String rightValue) {
        if (fieldVal == null) {
            if (op.equals(OpTypeEnum.IS_NULL.getValue())) {
                return true;
            } else {
                return false;
            }
        }

        BigDecimal leftValue;
        try {
            leftValue = BigDecimal.valueOf(Double.valueOf(String.valueOf(fieldVal)));
        } catch (Exception e) {
            log.warn("Parse field value to decimal failed:{}", fieldVal);
            return false;
        }

        BigDecimal rightValueDecimal;
        try {
            rightValueDecimal = StringUtils.isEmpty(rightValue) ? null : new BigDecimal(Double.valueOf(rightValue));
        } catch (Exception e) {
            log.warn("Parse right value to decimal failed:{}", rightValue);
            return false;
        }
        // log.info("leftValue:{} op:{} rightValueDecimal:{}", leftValue, op, rightValueDecimal);

        if (op.equals(OpTypeEnum.IS_NULL.getValue())) {
            return false;
        } else if (op.equals(OpTypeEnum.IS_NOT_NULL.getValue())) {
            return true;
        }

        if (rightValueDecimal == null) {
            return false;
        }

        if (op.equals(OpTypeEnum.EQ.getValue())) {
            return leftValue.compareTo(rightValueDecimal) == 0;
        } else if (op.equals(OpTypeEnum.NE.getValue())) {
            return leftValue.compareTo(rightValueDecimal) != 0;
        } else if (op.equals(OpTypeEnum.GT.getValue())) {
            return leftValue.compareTo(rightValueDecimal) > 0;
        } else if (op.equals(OpTypeEnum.GTE.getValue())) {
            return leftValue.compareTo(rightValueDecimal) >= 0;
        } else if (op.equals(OpTypeEnum.LT.getValue())) {
            return leftValue.compareTo(rightValueDecimal) < 0;
        } else if (op.equals(OpTypeEnum.LTE.getValue())) {
            return leftValue.compareTo(rightValueDecimal) <= 0;
        } else {
            return false;
        }
    }

    private void handleApiIndexValue(List<IndexParamsEntity> apiIndexParamsList, Map<String, Object> apiResult, Map<String, Object> allResult) {
        for (IndexParamsEntity index : apiIndexParamsList) {
            try {
                String paramNo = index.getParamNo();
                String parentParamNo = "";
                IndexParamsEntity parent = index.getParent();
                String extendField = index.getExtendField();
                String structure = index.getStructure();
                String parentStructure = "";
                String parentExtendField = "";
                if (Objects.nonNull(parent)) {
                    parentParamNo = parent.getParamNo();
                    extendField = parent.getExtendField();
                    parentStructure = parent.getStructure();
                    parentExtendField = parent.getExtendField();
                }
                JSONObject result = (JSONObject) apiResult.get(parentParamNo);
                if (Objects.nonNull(result)) {
                    String intfField = index.getIntfField();
                    if (StringUtils.isNotEmpty(intfField)) {
                        // 判断是否为求和指标
                        String fieldNo = "";
                        String originStructure = structure;
                        boolean sumFlag = StringUtils.isNotBlank(structure) && structure.contains("##sum");
                        if (sumFlag) {
                            String[] structures = structure.split("@@");
                            fieldNo = Arrays.stream(structures).filter(s -> s.contains("##sum")).findFirst().orElse("");
                            structure = structure.replace("@@" + fieldNo, "");
                            String[] intfFields = intfField.split("@@");
                            String field = Arrays.stream(intfFields).filter(s -> s.contains("##sum")).findFirst().orElse("");
                            intfField = intfField.replace("@@" + field, "");
                        }
                        boolean countFlag = intfField.contains("@@count");
                        if (countFlag) {
                            String replace = intfField.replace("@@count", "");
                            String[] split = replace.split("@@");
                            for (String obj : split) {
                                JSONObject jsonObject = JSONObject.parseObject(obj);
                                if (StringUtils.isEmpty(structure)) {
                                    structure = jsonObject.keySet().stream().findFirst().orElse("");
                                } else {
                                    structure = structure + "@@" + jsonObject.keySet().stream().findFirst().orElse("");
                                }
                            }
                        }
                        Object data = handleFieldValue(result, intfField, extendField, structure);
                        Object currentData = handleCurrentStructure(sumFlag, result, data, structure, extendField, parentStructure, parentExtendField, countFlag);
                        if (Objects.nonNull(currentData)) {
                            if (sumFlag && currentData instanceof List && !((List<?>) currentData).isEmpty()) {
                                try {
                                    Map<String, String> fieldNameMap = Maps.newHashMap();
                                    if (StringUtils.isNotEmpty(parentExtendField) && !"[]".equals(parentExtendField)) {
                                        JSONArray extendFieldArr = JSONObject.parseArray(parentExtendField);
                                        if (null != extendFieldArr && !extendFieldArr.isEmpty()) {
                                            extendFieldArr.forEach(extend -> {
                                                JSONObject jsonObject = (JSONObject) extend;
                                                jsonObject.keySet().forEach(key -> {
                                                    JSONObject keyObj = jsonObject.getJSONObject(key);
                                                    fieldNameMap.put(key, keyObj.getString("relaPname"));
                                                });
                                            });
                                        }
                                    }
                                    // 判断原始值不是纯数字，需要去除非数字部分再相加，最后再拼上
                                    String finalFieldNo = fieldNameMap.get(structure + "@@" + fieldNo.replace("##sum", ""));
                                    List<String> addDataList = new ArrayList<>();
                                    ((JSONArray) currentData).forEach(obj -> {
                                        Object value = ((JSONObject) obj).get(finalFieldNo);
                                        if (value != null) {
                                            addDataList.add(String.valueOf(value));
                                        }
                                    });
                                    currentData = ParamUtil.sumNumericWithSuffix(addDataList);
                                    // sum配置再次参与过滤
                                    currentData = handleCurrentStructure(sumFlag, result, currentData, originStructure, extendField, parentStructure, parentExtendField, countFlag);
                                } catch (Exception e) {
                                    log.error("求和异常，异常信息为：{}", ExceptionUtils.getStackTrace(e));
                                    currentData = "";
                                }
                            }
                            if ((currentData instanceof List && ((List<?>) currentData).isEmpty()) || (currentData instanceof JSONObject && ((JSONObject) currentData).isEmpty())) {
                                continue;
                            }
                            allResult.put(paramNo, currentData);
                        }
                    }
                }
            } catch (Exception e) {
                log.error("获取指标{}异常，异常信息为{}！", JSONObject.toJSONString(index), ExceptionUtils.getStackTrace(e));
            }
        }
    }

    private void handleSqlIndexValue(List<IndexParamsEntity> sqlIndexParamsList, Map<String, Object> sqlResult, Map<String, Object> result, Map<String, String> paramTypeMap) {
        for (IndexParamsEntity index : sqlIndexParamsList) {
            try {
                String parentParamNo = index.getParentParamNo();
                String paramNo = index.getParamNo();
                String parentParamType = paramTypeMap.get(parentParamNo);
                if (null == sqlResult || sqlResult.isEmpty()) {
                    result.put(paramNo, "");
                    continue;
                }

                if (sqlResult.containsKey(paramNo)) {
                    result.put(paramNo, sqlResult.get(paramNo));
                    continue;
                }

                Object obj = sqlResult.get(parentParamNo);
                if (Objects.isNull(obj)) {
                    result.put(paramNo, "");
                    continue;
                }

                if ("OBJECT".equals(parentParamType)) {
                    if (ParamTypeEnum.CHAR.id.equalsIgnoreCase(index.getParamType()) || ParamTypeEnum.NUMBER.id.equalsIgnoreCase(index.getParamType())) {
                        JSONObject json = (JSONObject) JSON.parse(JSON.toJSONString(obj, SerializerFeature.WriteMapNullValue));
                        Object value = JSONTools.getValue(json, index.getParamID());
                        if (ParamUtil.isNumericInt(String.valueOf(value))) {
                            value = new BigDecimal(String.valueOf(value)).setScale(2, RoundingMode.HALF_UP);
                        }
                        result.put(paramNo, value);
                    } else {
                        result.put(paramNo, obj);
                    }
                } else {
                    if (ParamTypeEnum.CHAR.id.equalsIgnoreCase(index.getParamType()) || ParamTypeEnum.NUMBER.id.equalsIgnoreCase(index.getParamType())) {
                        JSONObject json = JSON.parseArray(JSON.toJSONString(obj, SerializerFeature.WriteMapNullValue)).getJSONObject(0);
                        Object value = Objects.isNull(JSONTools.getValue(json, index.getParamName())) ? JSONTools.getValue(json, index.getParamID()) : JSONTools.getValue(json, index.getParamName());
                        result.put(paramNo, value);
                    } else {
                        result.put(paramNo, obj);
                    }
                }
            } catch (Exception e) {
                log.error("从父指标中解析子指标异常，异常信息{}", ExceptionUtils.getStackTrace(e));
            }
        }
    }

    private Object handleCurrentStructure(boolean sumFlag, JSONObject apiResult, Object data, String structure, String extendField, String parentStructure, String parentExtendField, boolean countFlag) {
        try {
            if (Objects.isNull(data) || StringUtils.isEmpty(String.valueOf(data))) {
                return null;
            }
            JSONArray jsonArray = JSONObject.parseArray(parentStructure);
            if (null == jsonArray || jsonArray.isEmpty()) {
                return data;
            }

            JSONArray extendFieldJsonArray = JSONObject.parseArray(extendField);
            List<String> javaList = jsonArray.toJavaList(String.class);
            List<String> collect = javaList.stream().filter(str -> str.contains(structure + "@@")).collect(Collectors.toList());
            if (CollectionUtils.isEmpty(collect) && !countFlag) {
                List<JSONObject> structureCollect = extendFieldJsonArray.stream().map(ext -> (JSONObject) ext).filter(ext -> ext.containsKey(structure)).collect(Collectors.toList());
                if (CollectionUtils.isNotEmpty(structureCollect)) {
                    // 数据字典解析
                    try {
                        JSONObject jsonObject = structureCollect.get(0).getJSONObject(structure);
                        String relaDict = jsonObject.getString("relaDict");
                        if (StringUtils.isNotEmpty(relaDict)) {
                            DictModel dictModel = sysDictCache.get(relaDict, String.valueOf(data));
                            if (Objects.nonNull(dictModel)) {
                                data = dictModel.getText();
                            }
                        }
                        // 限制条件
                        JSONArray limitCondition = jsonObject.getJSONArray("limitCondition");
                        if (CollectionUtils.isNotEmpty(limitCondition)) {
                            String limitConditionLogic = jsonObject.getString("limitConditionLogic");
                            boolean conditionResult = evaluateLimitConditions(limitConditionLogic, limitCondition, data);
                            String limitArea = jsonObject.getString("limitArea");
                            if (!conditionResult) {
                                if ("2".equals(limitArea)) {
                                    data = null;
                                }
                            }
                            if (conditionResult) {
                                if ("4".equals(limitArea)) {
                                    data = null;
                                }
                            }
                        }
                    } catch (Exception e) {
                        log.error("处理当前指标配置报错：{}", ExceptionUtils.getStackTrace(e));
                    }
                }
                return data;
            }

            // 解析字段中文名称
            Map<String, String> fieldNameMap = Maps.newHashMap();
            if (StringUtils.isNotEmpty(parentExtendField) && !"[]".equals(parentExtendField)) {
                JSONArray extendFieldArr = JSONObject.parseArray(parentExtendField);
                if (null != extendFieldArr && !extendFieldArr.isEmpty()) {
                    extendFieldArr.forEach(extend -> {
                        JSONObject jsonObject = (JSONObject) extend;
                        jsonObject.keySet().forEach(key -> {
                            JSONObject keyObj = jsonObject.getJSONObject(key);
                            fieldNameMap.put(key, keyObj.getString("relaPname"));
                        });
                    });
                }
            }

            // 只返回当前配置的字段
            if (data instanceof JSONObject) {
                JSONObject originValue = (JSONObject) data;
                JSONObject newValue = new JSONObject();
                getDataValue(sumFlag, extendFieldJsonArray, originValue, newValue, structure, fieldNameMap, apiResult);
                return newValue;
            }

            if (data instanceof List) {
                JSONArray result = new JSONArray();
                JSONArray array = JSONObject.parseArray(String.valueOf(data));
                if (array == null || array.isEmpty()) {
                    return null;
                }
                array.forEach(obj -> {
                    JSONObject originValue = (JSONObject) obj;
                    JSONObject newValue = new JSONObject();
                    getDataValue(sumFlag, extendFieldJsonArray, originValue, newValue, structure, fieldNameMap, apiResult);
                    if (!newValue.isEmpty()) {
                        result.add(newValue);
                    }
                });
                return countFlag ? result.size() : result;
            }
        } catch (Exception e) {
            log.error("处理当前指标结构报错：{}", ExceptionUtils.getStackTrace(e));
        }
        return data;
    }

    private void getDataValue(boolean sumFlag, JSONArray extendFieldJsonArray, JSONObject originValue, JSONObject json, String lastStructure, Map<String, String> fieldNameMap, JSONObject result) {
        for (String key : originValue.keySet()) {
            String concat = lastStructure.concat("@@").concat(key);
            if (fieldNameMap.containsKey(concat)) {
                String newKey = fieldNameMap.get(concat);
                Object newValue = originValue.get(key);
                if (newValue instanceof JSONArray) {
                    JSONArray array = (JSONArray) newValue;
                    JSONArray newArray = new JSONArray();
                    for (Object obj : array) {
                        if (obj instanceof String) {
                            newArray.add(obj);
                            continue;
                        }
                        if (obj instanceof JSONArray) {
                            newArray.add(obj);
                            continue;
                        }
                        if (obj instanceof JSONObject) {
                            JSONObject objValue = (JSONObject) obj;
                            JSONObject newObj = new JSONObject();
                            getDataValue(sumFlag, extendFieldJsonArray, objValue, newObj, concat, fieldNameMap, result);
                            if (!newObj.isEmpty()) {
                                newArray.add(newObj);
                            }
                        }
                    }
                    List<JSONObject> structureCollect = extendFieldJsonArray.stream().map(ext -> (JSONObject) ext).filter(ext -> ext.containsKey(concat)).collect(Collectors.toList());
                    int count = 10;
                    if (CollectionUtils.isNotEmpty(structureCollect)) {
                        JSONObject jsonObject = structureCollect.get(0).getJSONObject(concat);
                        count = Objects.nonNull(jsonObject.getInteger("count")) ? jsonObject.getInteger("count") : count;
                    }
                    newValue = newArray.stream().limit(count).collect(Collectors.toList());
                } else if (newValue instanceof JSONObject) {
                    JSONObject objValue = (JSONObject) newValue;
                    JSONObject newObj = new JSONObject();
                    getDataValue(sumFlag, extendFieldJsonArray, objValue, newObj, concat, fieldNameMap, result);
                    newValue = newObj;
                } else {
                    List<JSONObject> structureCollect = extendFieldJsonArray.stream().map(ext -> (JSONObject) ext).filter(ext -> ext.containsKey(concat)).collect(Collectors.toList());
                    if (CollectionUtils.isNotEmpty(structureCollect)) {
                        // 数据字典解析
                        JSONObject jsonObject = structureCollect.get(0).getJSONObject(concat);
                        String relaDict = jsonObject.getString("relaDict");
                        if (StringUtils.isNotEmpty(relaDict)) {
                            DictModel dictModel = sysDictCache.get(relaDict, String.valueOf(newValue));
                            if (Objects.nonNull(dictModel)) {
                                newValue = dictModel.getText();
                            }
                        }
                        // 限制条件
                        JSONArray limitCondition = jsonObject.getJSONArray("limitCondition");
                        if (CollectionUtils.isNotEmpty(limitCondition)) {
                            List<Boolean> list = new ArrayList<>();
                            for (Object r : limitCondition) {
                                Boolean indexAssertCond = indexAssertCond(newValue, r);
                                list.add(indexAssertCond);
                            }
                            String limitArea = jsonObject.getString("limitArea");
                            if (list.contains(false)) {
                                // 1: 输出当前字段，2：输出当前记录
                                if ("1".equals(limitArea)) {
                                    json.put(newKey, "");
                                    continue;
                                }
                                if ("2".equals(limitArea)) {
                                    json.clear();
                                    break;
                                }
                            }
                            if (!list.contains(false)) {
                                // 3：不输出当前字段 4：不输出当前记录
                                if ("3".equals(limitArea)) {
                                    json.put(newKey, "");
                                    continue;
                                }
                                if ("4".equals(limitArea)) {
                                    json.clear();
                                    break;
                                }
                            }
                        }
                    }
                }
                json.put(newKey, newValue);
            }
        }
    }

    private boolean evaluateLimitConditions(String limitConditionLogic, JSONArray limitCondition, Object fieldVal) {
        if (CollectionUtils.isEmpty(limitCondition)) {
            return true;
        }
        Boolean combined = null;
        for (Object r : limitCondition) {
            boolean currentResult = indexAssertCond(fieldVal, r);
            if (combined == null) {
                combined = currentResult;
            } else {
                if ("OR".equalsIgnoreCase(limitConditionLogic)) {
                    combined = combined || currentResult;
                } else {
                    // 默认为且逻辑（兼容旧配置中没有 limitConditionLogic 的情况）
                    combined = combined && currentResult;
                }
            }
        }
        return combined != null && combined;
    }

    private boolean indexAssertCond(Object fieldVal, Object r) {
        try {
            if (!(r instanceof JSONObject)) {
                log.warn("r is null or is not json object");
                return false;
            }
            JSONObject cond = (JSONObject) r;

            String op = cond.getString("operator");
            if (StringUtils.isEmpty(op)) {
                log.warn("operator is empty");
                return false;
            }
            op = op.replaceAll("\\s+", "");
            List<String> ops = Arrays.stream(OpTypeEnum.values()).map(x -> x.getValue()).collect(Collectors.toList());
            if (CollectionUtils.isEmpty(ops) || !ops.contains(op)) {
                log.warn("operator is invalid:{}", op);
                return false;
            }

            String dataType = DataTypeEnum.STRING.getValue();
            if (fieldVal instanceof Integer || fieldVal instanceof Long || fieldVal instanceof BigDecimal || fieldVal instanceof Double || fieldVal instanceof Float) {
                dataType = DataTypeEnum.NUMBER.getValue();
            } else if (fieldVal instanceof Boolean) {
                dataType = DataTypeEnum.BOOLEAN.getValue();
            }

            if (StringUtils.isEmpty(dataType)) {
                log.warn("data_type is empty");
                return false;
            }
            List<String> dataTypes = Arrays.stream(DataTypeEnum.values()).map(x -> x.getValue()).collect(Collectors.toList());
            if (!dataTypes.contains(dataType)) {
                log.warn("dataType is invalid:{}", dataType);
                return false;
            }

            String rightValue = cond.getString("value");
            if (dataType.equals(DataTypeEnum.ARRAY.getValue())) {
                return assertListCond(fieldVal, op, rightValue);
            } else if (dataType.equals(DataTypeEnum.NUMBER.getValue())) {
                return assertNumCond(fieldVal, op, rightValue);
            } else if (dataType.equals(DataTypeEnum.STRING.getValue())) {
                return assertStrCond(fieldVal, op, rightValue);
            } else if (dataType.equals(DataTypeEnum.DATE.getValue())) {
                return assertDateCond(fieldVal, op, rightValue);
            } else if (dataType.equals(DataTypeEnum.BOOLEAN.getValue())) {
                return assertBoolCond(fieldVal, op);
            } else {
                return false;
            }
        } catch (Exception e) {
            log.error("条件判断异常，异常信息为：{}", ExceptionUtils.getStackTrace(e));
            return false;
        }
    }

    private void processResults(List<Future<String>> futures) {
        for (Future<String> future : futures) {
            try {
                future.get();
            } catch (Exception e) {
                log.error("异常信息：{}", ExceptionUtils.getStackTrace(e));
            }
        }
    }

    private Object handleFieldValue(JSONObject jsonResult, String intfField, String extendField, String structure) {
        try {
            if (StringUtils.isNotEmpty(structure) && !structure.contains("@@") && !"data".equals(structure)) {
                return jsonResult.get(structure);
            }

            String tempIntfField = intfField;
            if (intfField.contains("@@count")) {
                tempIntfField = intfField.replace("@@count", "");
            }

            List<String> rawList = Arrays.asList(tempIntfField.split("@@"));
            if (CollectionUtils.isEmpty(rawList)) {
                return null;
            }

            // 取配置的条数（默认只返回10条）
            int count = 10;
            if (StringUtils.isNotEmpty(extendField)) {
                JSONArray extendFieldJson = JSONObject.parseArray(extendField);
                List<JSONObject> collect = extendFieldJson.stream().map(json -> (JSONObject) json).filter(json -> json.containsKey(structure)).collect(Collectors.toList());
                if (CollectionUtils.isNotEmpty(collect)) {
                    JSONObject jsonObject = collect.get(0).getJSONObject(structure);
                    count = Objects.nonNull(jsonObject.getInteger("count")) ? jsonObject.getInteger("count") : count;
                }
            }

            // 按层级处理取值
            String lastType = DataTypeEnum.OBJECT.getValue();
            Object lastValue = null;
            Object transferValue = jsonResult;
            for (String raw : rawList) {
                if (Objects.isNull(transferValue) || (transferValue instanceof JSONObject && ((JSONObject) transferValue).isEmpty()) || (transferValue instanceof JSONArray && ((JSONArray) transferValue).isEmpty())) {
                    return null;
                }
                JSONObject rawValue = JSONObject.parseObject(raw);
                String fieldNo = "";
                JSONObject paramInfo = new JSONObject();
                for (String key : rawValue.keySet()) {
                    fieldNo = key;
                    paramInfo = rawValue.getJSONObject(key);
                    break;
                }
                String fieldType = paramInfo.getString("type");
                if (lastType.equals(DataTypeEnum.OBJECT.getValue())) {
                    if (transferValue instanceof JSONObject) {
                        transferValue = ((JSONObject) transferValue).get(fieldNo);
                    }
                } else if (lastType.equals(DataTypeEnum.ARRAY.getValue())) {
                    if (transferValue instanceof JSONArray) {
                        transferValue = ((JSONArray) transferValue).getJSONObject(0).get(fieldNo);
                    }
                }
                lastType = fieldType;
                lastValue = transferValue;
            }
            if (Objects.isNull(lastValue)) {
                return lastValue;
            }
            if (lastType.equals(DataTypeEnum.ARRAY.getValue())) {
                return JSONArray.parseArray(String.valueOf(lastValue)).stream().limit(count).collect(Collectors.toList());
            }
            return lastValue;
        } catch (Exception e) {
            log.error("{}字段取值异常！异常信息为：{}", intfField, ExceptionUtils.getStackTrace(e));
            return null;
        }
    }

    private void getParamsByParentParamNo(List<IndexParamsEntity> list, List<IndexParamsEntity> allList) {
        Set<String> parent = list.stream().filter(index -> index.getParamType().equals(ParamTypeEnum.LIST.id) || index.getParamType().equals(ParamTypeEnum.OBJECT.id)).map(IndexParamsEntity::getParamNo).collect(Collectors.toSet());
        Set<String> child = list.stream().filter(index -> !index.getParamType().equals(ParamTypeEnum.LIST.id)).map(IndexParamsEntity::getParentParamNo).collect(Collectors.toSet());
        List<String> all = new ArrayList<>();
        if (CollectionUtils.isNotEmpty(parent)) {
            all.addAll(parent);
        }
        if (CollectionUtils.isNotEmpty(child)) {
            all.addAll(child);
        }
        if (CollectionUtils.isNotEmpty(all)) {
            QueryWrapper<IndexParamsEntity> queryWrapper = new QueryWrapper<>();
            queryWrapper.in("paramNo", all);
            queryWrapper.ne("paramType", "GROUP");
            List<IndexParamsEntity> indexParamsEntityList = indexParamsService.list(queryWrapper);
            if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
                // 查询父级的所有子集
                LambdaQueryWrapper<IndexParamsEntity> wrapper = Wrappers.lambdaQuery();
                wrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParentParamNo, IndexParamsEntity::getParamID, IndexParamsEntity::getParamName);
                wrapper.in(IndexParamsEntity::getParentParamNo, all);
                List<IndexParamsEntity> allChildParamsEntity = indexParamsService.list(wrapper);
                if (CollectionUtils.isNotEmpty(allChildParamsEntity)) {
                    Map<String, List<IndexParamsEntity>> parentGroup = allChildParamsEntity.stream().collect(Collectors.groupingBy(IndexParamsEntity::getParentParamNo));
                    indexParamsEntityList.forEach(group -> group.setParamsList(parentGroup.get(group.getParamNo())));
                }
            }
            allList.addAll(indexParamsEntityList);
        }
    }

    private void getAllParamsByParentParamNo(List<IndexParamsEntity> list, List<IndexParamsEntity> allList) {
        Set<String> collect = list.stream().map(IndexParamsEntity::getParentParamNo).collect(Collectors.toSet());
        if (CollectionUtils.isNotEmpty(collect)) {
            QueryWrapper<IndexParamsEntity> queryWrapper = new QueryWrapper<>();
            queryWrapper.in("paramNo", collect);
            queryWrapper.ne("paramType", "GROUP");
            List<IndexParamsEntity> indexParamsEntityList = indexParamsService.list(queryWrapper);
            allList.addAll(indexParamsEntityList);
        }
    }

    private static final Pattern RULE_REF_PATTERN = Pattern.compile("\\[\\[(.*?)\\|\\|(.*?)]]");


    private AgentRuleExecuteVO executeRuleAndGetField(String ruleCode, JSONObject params) {
        try {
            AgentRuleEntity entity = agentRuleService.getRule(ruleCode);
            if (entity == null) {
                log.warn("规则不存在，ruleCode: {}", ruleCode);
                return null;
            }
            AgentRuleExecuteReq req = new AgentRuleExecuteReq();
            req.setRuleCode(ruleCode);
            req.setRequestParams(params);
            req.setName(JSONTools.getString(params, "name"));
            req.setId(entity.getId());
            req.setRuleStatus(entity.getRuleStatus());
            req.setParsedExpression(entity.getParsedExpression());
            req.setPromptKey(entity.getPromptKey());
            return agentRuleService.executeRule(req);
        } catch (Exception e) {
            log.error("执行规则异常，ruleCode: {}, 异常信息: {}", ruleCode, ExceptionUtils.getStackTrace(e));
            return null;
        }
    }


    private void getRuleValueMap(JSONArray promptCondGroups, JSONObject params, Map<String, Object> paramGroupResultMap) {
        for (Object group : promptCondGroups) {
            JSONObject groupObj = (JSONObject) group;
            JSONObject condObj = groupObj.getJSONObject("if");
            if (Objects.isNull(condObj)) {
                continue;
            }

            JSONArray variables = condObj.getJSONArray("variables");
            if (CollectionUtils.isEmpty(variables)) {
                continue;
            }
            for (Object var : variables) {
                JSONObject varObj = (JSONObject) var;
                if (!"rule".equalsIgnoreCase(varObj.getString("tabType"))) {
                    continue;
                }
                String ruleCode = varObj.getString("field");
                if (StringUtils.isEmpty(ruleCode)) {
                    continue;
                }
                resolveRuleField(ruleCode, varObj.getString("label"), params, paramGroupResultMap);
            }
        }
    }

    private void getPromptRuleValueMap(Set<String> outPutRuleSet, JSONObject params, Map<String, Object> paramGroupResultMap) {
        for (String var : outPutRuleSet) {
            String[] split = var.split("@@");
            resolveRuleField(split[0], split[1], params, paramGroupResultMap);
        }
    }

    /**
     * 获取规则执行结果并按字段名缓存
     * 优先从缓存取已执行的规则VO，缓存未命中时才执行规则
     */
    private void resolveRuleField(String ruleCode, String resultField, JSONObject params, Map<String, Object> paramGroupResultMap) {
        String stringKey = ruleCode + "_" + resultField;
        AgentRuleExecuteVO vo = (AgentRuleExecuteVO) paramGroupResultMap.get(ruleCode);
        if (vo == null) {
            vo = executeRuleAndGetField(ruleCode, params);
            paramGroupResultMap.put(ruleCode, vo);
        }
        if (vo != null) {
            if ("ruleResult".equals(resultField)) {
                paramGroupResultMap.put(stringKey, vo.getResultStatus());
            } else if ("ruleData".equals(resultField)) {
                List<AgentRuleMetricVO> matchedMetrics = vo.getMatchedMetrics();
                List<Map<String, Object>> resultList = matchedMetrics.stream().map(x -> {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("指标名称", x.getIndexName());
                    map.put("命中值", x.getActualValue());
                    map.put("单位", x.getDataUnit());
                    return map;
                }).collect(Collectors.toList());
                paramGroupResultMap.put(stringKey, resultList);
            } else if ("factExpression".equals(resultField)) {
                paramGroupResultMap.put(stringKey, vo.getFactExpression());
            }
        }
    }

    private String replaceRuleReferences(String text, Map<String, Object> paramGroupResultMap) {
        if (StringUtils.isEmpty(text) || !text.contains("[[")) {
            return text;
        }
        Matcher m = RULE_REF_PATTERN.matcher(text);
        StringBuffer sb = new StringBuffer();
        while (m.find()) {
            String fieldName = m.group(2);
            String ruleCode = m.group(1);
            Object value = paramGroupResultMap.get(fieldName + "_" + ruleCode);
            String replacement;
            if (value == null) {
                replacement = "";
            } else if (value instanceof JSONObject || value instanceof JSONArray) {
                replacement = JSONObject.toJSONString(value, SerializerFeature.WriteMapNullValue);
            } else {
                replacement = String.valueOf(value);
            }
            m.appendReplacement(sb, Matcher.quoteReplacement(replacement));
        }
        m.appendTail(sb);
        return sb.toString();
    }

    private void handleConditionGroupParam(String relateIndexSet, JSONObject params, JSONArray promptCondGroups, Map<String, Object> paramGroupResultMap) {
        try {
            Set<String> paramNoSet = Sets.newHashSet();
            for (Object group : promptCondGroups) {
                JSONObject groupObj = (JSONObject) group;
                JSONObject condObj = groupObj.getJSONObject("if");
                if (Objects.isNull(condObj)) {
                    continue;
                }
                String condition = condObj.getString("condition");
                if (StringUtils.isNotEmpty(condition)) {
                    JSONArray variables = condObj.getJSONArray("variables");
                    if (CollectionUtils.isNotEmpty(variables)) {
                        variables.forEach(var -> {
                            JSONObject varObj = (JSONObject) var;
                            String valueType = varObj.getString("valueType");
                            paramNoSet.add(varObj.getString("field"));
                            if ("indicator".equals(valueType)) {
                                paramNoSet.add(varObj.getString("value"));
                            }
                        });
                    }
                }
            }
            if (CollectionUtils.isEmpty(paramNoSet)) {
                return;
            }
            ArrayList<String> arrayList = new ArrayList<>(paramNoSet);
            getIndexValueMap(relateIndexSet, params, arrayList, paramGroupResultMap);
        } catch (Exception e) {
            log.error("查询分组条件相关指标异常！异常信息为：{}", ExceptionUtils.getStackTrace(e));
        }
    }

    public void handleOutputGroupParam(String relateIndexSet, Map<String, Object> paramGroupResultMap, JSONObject params, String output) {
        try {
            Set<String> paramNoSet = Sets.newHashSet();
            if (StringUtils.isNotEmpty(output)) {
                List<String> paramNoList = ParamUtil.getParamNoList(output);
                paramNoSet.addAll(paramNoList);
            }
            Set<String> existParamNoSet = paramGroupResultMap.keySet();
            paramNoSet.removeAll(existParamNoSet);
            if (CollectionUtils.isEmpty(paramNoSet)) {
                return;
            }

            ArrayList<String> arrayList = new ArrayList<>(paramNoSet);
            Map<String, Object> indexValueMap = getIndexValueMap(relateIndexSet, params, arrayList, paramGroupResultMap);
            if (Objects.nonNull(indexValueMap) && !indexValueMap.isEmpty()) {
                paramGroupResultMap.putAll(indexValueMap);
            }
        } catch (Exception e) {
            log.error("查询分组文案相关指标异常！异常信息为：{}", ExceptionUtils.getStackTrace(e));
        }
    }

    private JSONObject handlePromptContent(JSONObject params) {
        JSONObject result = new JSONObject();
        result.put("isExist", false);
        String moduleCode = params.getString("moduleCode");
        if (StringUtils.isEmpty(moduleCode)) {
            return result;
        }

        long startTime = System.currentTimeMillis();
        String traceId = params.getString("traceId");
        log.info("开始处理[{}]的prompt请求，TraceId为[{}]，请求参数{}", moduleCode, traceId, params.toJSONString());

        // 行业特殊取值
        JSONObject extensions = params.getJSONObject("extensions");
        if (Objects.isNull(extensions)) {
            try {
                String extensionsStr = String.valueOf(params.get("extensions_str"));
                if (StringUtils.isNotBlank(extensionsStr)) {
                    extensions = JSON.parseObject(extensionsStr);
                }
            } catch (Exception e) {
                log.error("extensions_str取值异常！异常原因：{}", ExceptionUtils.getStackTrace(e));
            }
        }
        if (Objects.nonNull(extensions)) {
            JSONObject paramMapping = extensions.getJSONObject("paramMapping");
            if (Objects.nonNull(paramMapping)) {
                JSONArray indGradecodeArr = paramMapping.getJSONArray("indGradecname");
                if (null != indGradecodeArr && !indGradecodeArr.isEmpty() && indGradecodeArr.get(0).equals(".")) {
                    JSONObject icObj = extensions.getJSONObject("IC");
                    if (Objects.nonNull(icObj) && !icObj.getJSONArray("indGradecname").isEmpty()) {
                        params.put("industry", icObj.getJSONArray("indGradecname").get(0));
                    }
                }
            }
        }

        // 获取知识库信息
        boolean ignoreStatus = Objects.nonNull(params.getBoolean("ignoreStatus")) && params.getBoolean("ignoreStatus");
        KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = queryKnowledgeBaseParams(moduleCode, ignoreStatus);
        if (Objects.isNull(knowledgeBaseParamsEntity)) {
            log.info("完成[{}]的prompt请求，未配置[{}]知识库文案，TraceId为[{}]，耗时[{}ms]", moduleCode, moduleCode, traceId, System.currentTimeMillis() - startTime);
            return result;
        }

        // 如果是知识库查询，需要取最新发布版本
        if (!ignoreStatus) {
            KnowledgeBaseVersionEntity knowledgeBaseVersionEntity = knowledgeBaseVersionService.getLatestVersion(knowledgeBaseParamsEntity.getParamId());
            if (Objects.nonNull(knowledgeBaseVersionEntity)) {
                BeanUtil.copyProperties(knowledgeBaseVersionEntity, knowledgeBaseParamsEntity, true);
            }
        }

        // 判断是否走云端查询大模型渲染后的结果
        boolean answer = ParamUtil.getBoolValue(params, "withModelSummary", false);
        String isCloudSearch = knowledgeBaseParamsEntity.getIsCloudSearch();
        if (!answer && StringUtils.isNotEmpty(isCloudSearch) && OnlineEnum.Y.name().equals(isCloudSearch)) {
            result.put("isCloudSearch", true);
            result.put("isExist", true);
            result.put("content", "");
            result.put("promptDesc", "");
            result.put("traceId", traceId);
            result.put("largeModelParam", new JSONObject());
            result.put("inputIndexContent", new JSONObject());
            result.put("source_card", new JSONArray());
            result.put("whole_source", new JSONArray());
            return result;
        }

        // 如果当前是预览模式，需要使用页面的请求的数据
        boolean previewFlag = Objects.nonNull(params.getBoolean("previewFlag")) && params.getBoolean("previewFlag");
        if (previewFlag) {
            knowledgeBaseParamsEntity.setPrompt(params.getString("prompt"));
            knowledgeBaseParamsEntity.setInputParam(params.getString("inputParam"));
            knowledgeBaseParamsEntity.setContentDesc(params.getString("contentDesc"));
            knowledgeBaseParamsEntity.setLargeModelCode(params.getString("largeModelCode"));
            knowledgeBaseParamsEntity.setLargeModelParam(params.getString("largeModelParam"));
            knowledgeBaseParamsEntity.setIsTop(params.getString("isTop"));
            knowledgeBaseParamsEntity.setInputCondition(params.getString("inputCondition"));
            knowledgeBaseParamsEntity.setUserPrompt(params.getString("userPrompt"));
            knowledgeBaseParamsEntity.setSplitStrategyParam(params.getString("splitStrategyParam"));
        }

        // 处理知识库prompt
        params.put("knowledgeId", knowledgeBaseParamsEntity.getParamId());
        result.put("groupId", knowledgeBaseParamsEntity.getGroupId());
        handleMorePromptContent(traceId, moduleCode, result, knowledgeBaseParamsEntity, params);
        return result;
    }

    private void handleMorePromptContent(String traceId, String moduleCode, JSONObject result, KnowledgeBaseParamsEntity knowledgeBaseParamsEntity, JSONObject params) {
        // 知识库文案解析相关参数
        long startTime = System.currentTimeMillis();
        Object promptContent = "";
        Object originPromptContent = "";
        boolean authFlag = Objects.nonNull(params.getBoolean("authFlag")) && params.getBoolean("authFlag");
        JSONObject largeModelParamObj = new JSONObject();
        Map<String, Object> paramGroupResultMap = Maps.newHashMap();
        String paramId = knowledgeBaseParamsEntity.getParamId();
        String isTop = knowledgeBaseParamsEntity.getIsTop();
        String prompt = knowledgeBaseParamsEntity.getPrompt();
        String businessExperience = knowledgeBaseParamsEntity.getBusinessExperience();
        String relateIndexSet = knowledgeBaseParamsEntity.getRelateIndexSet();

        // 查询黑盒参数配置
        List<KnowledgeBlackParamsConfigEntity> listByKnowledgeId = blackParamsConfigEntityService.getListByKnowledgeId(paramId);
        if (CollectionUtils.isNotEmpty(listByKnowledgeId)) {
            Map<String, Object> blackParamsMap = Maps.newHashMap();
            listByKnowledgeId.stream().filter(json -> StringUtils.isNotEmpty(json.getParamValue())).forEach(json -> {
                blackParamsMap.put(json.getParamNo() + "--" + json.getParamCode(), ParamUtil.getValueByType(json.getParamType(), json.getParamValue()));
            });
            params.put("blackParams", blackParamsMap);
        }

        // 解析输出要求
        Map<String, String> promptDescWithCond = getPromptDescWithCond(relateIndexSet, knowledgeBaseParamsEntity.getContentDesc(), knowledgeBaseParamsEntity.getInputCondition(), params, paramGroupResultMap);
        String corePrompt = promptDescWithCond.get("corePrompt");
        String userPromptFromCond = promptDescWithCond.get("userPrompt");
        // outputRequirements = 用户提示词 + 核心提示词（条件中的usePrompt） + entity上的用户提示词
        String outputRequirements = userPromptFromCond;
        if (StringUtils.isNotBlank(corePrompt)) {
            outputRequirements = (StringUtils.isNotBlank(outputRequirements) ? outputRequirements + "\n" + corePrompt : corePrompt);
        }
        String entityUserPrompt = knowledgeBaseParamsEntity.getUserPrompt();
        if (StringUtils.isNotBlank(entityUserPrompt)) {
            outputRequirements = (StringUtils.isNotBlank(outputRequirements) ? outputRequirements + "\n" + entityUserPrompt : entityUserPrompt);
        }
        // 无权限时可见内容：用户提示词（条件中的usePrompt） + entity上的用户提示词
        String userSideRequirements = "";
        if (StringUtils.isNotBlank(userPromptFromCond)) {
            userSideRequirements = userPromptFromCond;
        }
        if (StringUtils.isNotBlank(entityUserPrompt)) {
            userSideRequirements = (StringUtils.isNotBlank(userSideRequirements) ? userSideRequirements + "\n" + entityUserPrompt : entityUserPrompt);
        }

        // 判断是否走客户端查询
        String isClientSearch = knowledgeBaseParamsEntity.getIsClientSearch();
        if (StringUtils.isNotEmpty(isClientSearch) && OnlineEnum.Y.name().equals(isClientSearch)) {
            String reqMsgBase64 = Base64.getEncoder().encodeToString(params.toJSONString().getBytes(StandardCharsets.UTF_8));
            promptContent = "@@向行端@@" + moduleCode + "@@向行端@@" + reqMsgBase64;
            result.put("isExist", true);
            result.put("content", promptContent);
            // 合并核心提示词和用户提示词用于promptDesc
            String promptDesc = userPromptFromCond;
            if (StringUtils.isNotBlank(corePrompt)) {
                promptDesc = (StringUtils.isNotBlank(promptDesc) ? promptDesc + "\n" + corePrompt : corePrompt);
            }
            result.put("promptDesc", promptDesc);
            result.put("traceId", traceId);
            result.put("source_card", new JSONArray());
            result.put("whole_source", new JSONArray());
            log.info("完成[{}]的prompt请求，走行端查询，TraceId为[{}]，耗时[{}ms]", moduleCode, traceId, System.currentTimeMillis() - startTime);
            return;
        }

        // 异步解析溯源配置，存储到redis缓存中
        asyncHandleTraceConfig(params, knowledgeBaseParamsEntity, relateIndexSet, moduleCode, traceId);

        // 大模型code
        String inputLargeModelCode = promptDescWithCond.get("largeModelCode");
        String largeModelCode = knowledgeBaseParamsEntity.getLargeModelCode();
        if (StringUtils.isNotEmpty(inputLargeModelCode) && !"NONE".equalsIgnoreCase(inputLargeModelCode)) {
            largeModelCode = inputLargeModelCode;
        }
        boolean useLargeModel = StringUtils.isEmpty(largeModelCode) || (StringUtils.isNotEmpty(largeModelCode) && !"NONE".equalsIgnoreCase(largeModelCode));

        // 解析全部来源配置
        JSONArray wholeSource = new JSONArray();
        String wholeSourceConfig = knowledgeBaseParamsEntity.getWholeSourceConfig();
        boolean wholeSourceFlag = StringUtils.isNotEmpty(wholeSourceConfig) && !JSONArray.parseArray(wholeSourceConfig, JSONObject.class).isEmpty();
        if (wholeSourceFlag) {
            try {
                log.info("开始[{}]的全部来源查询请求，TraceId为[{}]", moduleCode, traceId);
                long start = System.currentTimeMillis();
                String wholeSourceContent = parseWholeSourceConfig(relateIndexSet, moduleCode, wholeSourceConfig, params, paramGroupResultMap);
                if (StringUtils.isNotEmpty(wholeSourceContent)) {
                    wholeSource = JSONArray.parseArray(wholeSourceContent);
                }
                log.info("完成[{}]的全部来源配置请求，TraceId为[{}], 耗时[{}ms]", moduleCode, traceId, System.currentTimeMillis() - start);
            } catch (Exception e) {
                log.error("处理[{}]的溯源全部来源配置失败，TraceId为[{}]，失败原因[{}]", moduleCode, traceId, ExceptionUtils.getStackTrace(e));
            }
        }

        // 解析prompt文案配置
        boolean containFlag = false;
        if (StringUtils.isNotEmpty(prompt)) {
            // 判断是否包含引用知识库
            containFlag = checkContainReference(JSONArray.parseArray(prompt));
            Boolean inputFlag = params.getBoolean("inputFlag");
            Boolean previewFlag = params.getBoolean("previewFlag");
            // 引用知识库处理
            if (containFlag) {
                params.put("paramId", paramId);
                Map<String, Object> resultMap = parsePromptWithCondAndKnowledge(knowledgeBaseParamsEntity.getIsMarkdown(), relateIndexSet, prompt, params, paramGroupResultMap);
                if (Objects.nonNull(resultMap) && !resultMap.isEmpty()) {
                    // 溯源配置
                    result.put("source_card", resultMap.get("sourceCard"));
                    // 文案内容
                    JSONArray promptContentArr = (JSONArray) resultMap.get("promptContent");
                    originPromptContent = resultMap.get("promptContent");
                    // 拼接业务经验知识
                    if (StringUtils.isNotBlank(businessExperience)) {
                        JSONObject jsonObject = new JSONObject();
                        jsonObject.put("type", "prompt");
                        jsonObject.put("largeModelCode", "");
                        jsonObject.put("content", businessExperience);
                        promptContentArr.add(jsonObject);
                    }
                    if (null != promptContentArr && !promptContentArr.isEmpty()) {
                        if (StringUtils.isNotBlank(outputRequirements)) {
                            JSONObject jsonObject = new JSONObject();
                            jsonObject.put("type", "prompt");
                            jsonObject.put("largeModelCode", "");
                            // 鉴权：有权限（Knowledge角色）输出全部，无权限只输出用户提示词
                            if (Objects.nonNull(previewFlag) && previewFlag) {
                                List<String> roleCode = ApiContext.getApiContextModel().getRoleCode();
                                if (CollectionUtils.isNotEmpty(roleCode) && roleCode.contains("Knowledge")) {
                                    jsonObject.put("content", "\n" + outputRequirements);
                                } else if (StringUtils.isNotBlank(userSideRequirements)) {
                                    jsonObject.put("content", "\n" + userSideRequirements);
                                }
                            } else if (Objects.isNull(inputFlag) || !inputFlag) {
                                jsonObject.put("content", LINE_BREAK + outputRequirements);
                            }
                            // 判断是否置顶
                            if (OnlineEnum.Y.name().equals(isTop)) {
                                promptContentArr.add(0, jsonObject);
                            } else {
                                promptContentArr.add(jsonObject);
                            }
                        }
                        promptContent = promptContentArr;
                    }
                }
            } else {
                Map<String, Object> resultMap = parsePromptWithCond(knowledgeBaseParamsEntity.getIsMarkdown(), null, relateIndexSet, prompt, params, paramGroupResultMap);
                if (Objects.nonNull(resultMap) && !resultMap.isEmpty()) {
                    // 溯源配置
                    result.put("source_card", resultMap.get("sourceCard"));
                    // 文案内容
                    originPromptContent = resultMap.get("promptContent");
                    promptContent = resultMap.get("promptContent");
                    // 拼接业务经验知识
                    if (StringUtils.isNotBlank(businessExperience)) {
                        promptContent = promptContent + "\n" + businessExperience + "\n";
                    }
                    if (Objects.nonNull(promptContent) && StringUtils.isNotBlank(String.valueOf(promptContent))) {
                        if (StringUtils.isNotBlank(outputRequirements)) {
                            // 鉴权：有权限（Knowledge角色）输出全部，无权限只输出用户提示词
                            if (Objects.nonNull(previewFlag) && previewFlag) {
                                List<String> roleCode = ApiContext.getApiContextModel().getRoleCode();
                                if (CollectionUtils.isNotEmpty(roleCode) && roleCode.contains("Knowledge")) {
                                    String tempStr = "\n【输出要求开始】" + outputRequirements + "【输出要求结束】\n";
                                    promptContent = OnlineEnum.N.name().equals(isTop) ? promptContent + "\n" + tempStr : tempStr + "\n" + promptContent;
                                } else if (StringUtils.isNotBlank(userSideRequirements)) {
                                    String tempStr = "\n【输出要求开始】" + userSideRequirements + "【输出要求结束】\n";
                                    promptContent = OnlineEnum.N.name().equals(isTop) ? promptContent + "\n" + tempStr : tempStr + "\n" + promptContent;
                                }
                            } else if (Objects.isNull(inputFlag) || !inputFlag) {
                                promptContent = OnlineEnum.N.name().equals(isTop) ? promptContent + LINE_BREAK + outputRequirements : outputRequirements + LINE_BREAK + promptContent;
                            }
                        }
                    }
                }
            }

            // 处理大模型属性参数
            if (StringUtils.isNotEmpty(params.getString("largeModelCode"))) {
                largeModelCode = params.getString("largeModelCode");
            }
            String largeModelParam = knowledgeBaseParamsEntity.getLargeModelParam();
            if (StringUtils.isNotEmpty(largeModelCode) && StringUtils.isNotEmpty(largeModelParam)) {
                JSONObject jsonObject = JSON.parseObject(largeModelParam);
                if (Objects.nonNull(jsonObject) && !jsonObject.isEmpty()) {
                    JSONObject largeModeInfo = jsonObject.getJSONObject(largeModelCode);
                    if (Objects.nonNull(largeModeInfo) && !largeModeInfo.isEmpty()) {
                        largeModelParamObj = largeModeInfo;
                        String systemContent = largeModelParamObj.getString("systemContent");
                        if (StringUtils.isNotBlank(systemContent)) {
                            handleOutputGroupParam(relateIndexSet, paramGroupResultMap, params, systemContent);
                            if (StringUtils.isNotBlank(systemContent)) {
                                String parseSystemContent = parsePrompt(systemContent, params, paramGroupResultMap);
                                largeModelParamObj.put("systemContent", parseSystemContent);
                                // 处理大模型属性参数systemContent，追加到文案中
                                if (Objects.nonNull(promptContent) && StringUtils.isNotBlank(String.valueOf(promptContent)) && authFlag) {
                                    List<String> roleCode = ApiContext.getApiContextModel().getRoleCode();
                                    if (CollectionUtils.isNotEmpty(roleCode) && roleCode.contains("Knowledge")) {
                                        promptContent = promptContent + "\n【系统提示词开始】" + parseSystemContent + "【系统提示词结束】\n";
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 获取inputIndex指标值
        JSONObject inputIndexContent = handleInputIndex(knowledgeBaseParamsEntity.getInputIndex(), params, relateIndexSet, paramGroupResultMap);
        if (inputIndexContent.isEmpty()) {
            inputIndexContent = handleNewInputIndex(paramId, params, relateIndexSet, paramGroupResultMap);
        }
        // 知识库调用时，进行分段应用策略处理
        Object splitContent = StringUtils.isBlank(String.valueOf(promptContent)) ? "" : promptContent;
        String splitStrategyParam = knowledgeBaseParamsEntity.getSplitStrategyParam();
        boolean strategyIsActive = StringUtils.isNotEmpty(splitStrategyParam) && !JSONObject.parseObject(splitStrategyParam).isEmpty() && JSONObject.parseObject(splitStrategyParam).getBoolean("isActive");
        if (strategyIsActive && StringUtils.isNotBlank(String.valueOf(originPromptContent))) {
            // 判断是否是知识库引用
            if (containFlag && originPromptContent instanceof JSONArray) {
                StringBuffer resultContent = new StringBuffer();
                if (Objects.nonNull(promptContent) && promptContent instanceof JSONArray) {
                    JSONArray jsonArray = (JSONArray) promptContent;
                    for (Object json : jsonArray) {
                        JSONObject object = (JSONObject) json;
                        if (StringUtils.isNotBlank(object.getString("content"))) {
                            resultContent.append(object.getString("content")).append("\n");
                        }
                    }
                    originPromptContent = resultContent.toString().replaceAll("\\[查询结果 \\d+ (?:begin|end)]", "\n");
                }
            }
            String knowledgeDesc = StringUtils.isEmpty(knowledgeBaseParamsEntity.getParamDescription()) ? knowledgeBaseParamsEntity.getParamName() : knowledgeBaseParamsEntity.getParamName() + "," + knowledgeBaseParamsEntity.getParamDescription();
            splitContent = handleSplitStrategyContent(traceId, knowledgeDesc, splitStrategyParam, originPromptContent, outputRequirements, businessExperience, isTop, largeModelCode, largeModelParamObj);
        }

        // 组装返回结果
        result.put("traceId", traceId);
        result.put("isExist", true);
        result.put("inputIndexContent", inputIndexContent);
        // 🆕 2026-09-19 用户口径：「业务数据不支持 ⇒ 就不要调大模型，报告展示暂无数据即可」。
        //    判据 = **配了关联指标集、但一条值都没取到**（没配指标集的纯提示词类知识库不受影响）。
        //    真正拦不拦由 getPromptContent 决定 —— 只在严格模式（报告链路，__strictFetch=true）下拦，
        //    配置页预览 / 智策引擎试跑保持原行为（允许空数据试提示词）。
        result.put(RESULT_NO_INDEX_DATA, isIndexNoData(relateIndexSet, paramGroupResultMap));
        result.put("promptDesc", "");
        result.put("whole_source", wholeSource);
        result.put("useLargeModel", useLargeModel);
        result.put("largeModelCode", largeModelCode);
        result.put("largeModelParam", largeModelParamObj);
        result.put("outputRequirements", outputRequirements);
        result.put("content", splitContent);
    }

    @Override
    public KnowledgeBaseParamsEntity queryKnowledgeBaseParams(String moduleCode, boolean ignoreStatus) {
        KnowledgeBaseParamsEntity entity = knowledgeBaseParamsService.getByParamNo(moduleCode, ignoreStatus);
        if (Objects.isNull(entity)) {
            List<String> moduleCodeList = Arrays.asList(moduleCode.split("-"));
            String groupValue = moduleCodeList.get(moduleCodeList.size() - 1);
            entity = knowledgeBaseParamsService.getByParamNo(moduleCode + "-" + groupValue, true);
        }
        return entity;
    }

    @Override
    public KnowledgeBaseParamsEntity getKnowledgeGroupType(String moduleCode) {
        KnowledgeBaseParamsEntity baseParamsEntity = queryKnowledgeBaseParams(moduleCode, true);
        if (Objects.nonNull(baseParamsEntity)) {
            String groupId = baseParamsEntity.getGroupId();
            if (StringUtils.isNotEmpty(groupId)) {
                String concatGroupId = knowledgeBaseGroupMapper.getGroupId(groupId);
                if (StringUtils.isNotEmpty(concatGroupId)) {
                    KnowledgeBaseGroupEntity groupEntity = knowledgeBaseGroupService.getById(concatGroupId.split("-")[0]);
                    if (Objects.nonNull(groupEntity)) {
                        baseParamsEntity.setGroupType(groupEntity.getGroupType());
                        baseParamsEntity.setGroupValue(groupEntity.getGroupValue());
                    }
                }
            }
        }
        return baseParamsEntity;
    }

    @Override
    public String getGroupType(String groupId) {
        if (StringUtils.isEmpty(groupId)) {
            return "";
        }
        KnowledgeBaseGroupEntity groupEntity = knowledgeBaseGroupMapper.selectById(groupId);
        return Objects.nonNull(groupEntity) ? groupEntity.getGroupType() : "";
    }

    @Override
    public Map<String, String> getGroupNameList(List<String> groupValue) {
        if (CollectionUtils.isEmpty(groupValue)) {
            return Collections.emptyMap();
        }
        List<KnowledgeBaseGroupEntity> groupEntityList = knowledgeBaseGroupService.getGroupInfo(groupValue);
        if (CollectionUtils.isNotEmpty(groupEntityList)) {
            return groupEntityList.stream().collect(Collectors.toMap(KnowledgeBaseGroupEntity::getGroupValue, KnowledgeBaseGroupEntity::getGroupName, (oldValue, newValue) -> oldValue));
        }
        return Collections.emptyMap();
    }

    @Override
    public Object simplePageKnowledgeBaseParamsList(KnowledgeBaseParamReq reqMsg) {
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.select(KnowledgeBaseParamsEntity::getParamNo, KnowledgeBaseParamsEntity::getParamName);
        queryWrapper.eq(KnowledgeBaseParamsEntity::getOnline, OnlineEnum.Y.name());
        if (StringUtils.isNotEmpty(reqMsg.getKeyword())) {
            queryWrapper.and(wrapper -> wrapper.like(KnowledgeBaseParamsEntity::getParamNo, reqMsg.getKeyword())
                    .or()
                    .like(KnowledgeBaseParamsEntity::getParamName, reqMsg.getKeyword()));
        }
        queryWrapper.orderByDesc(KnowledgeBaseParamsEntity::getInputTime);
        if (StringUtils.isNotEmpty(reqMsg.getGroupId())) {
            queryWrapper.eq(KnowledgeBaseParamsEntity::getGroupId, reqMsg.getGroupId());
        }

        Page<KnowledgeBaseParamsEntity> page = new Page<>(reqMsg.getPageIndex(), reqMsg.getPageSize());
        IPage<KnowledgeBaseParamsEntity> pageList = knowledgeBaseParamsService.page(page, queryWrapper);
        if (CollectionUtils.isEmpty(pageList.getRecords())) {
            // 迁移修正点：源实现此处 `return Collections.emptyMap();`，导致本方法【空结果返回 {}、
            // 有结果返回 []】两种形态（Object 返回类型掩盖了它）。而调用方（源工程 RuleFormModal.vue:561）
            // 直接 `res.result.find(...)`，即【假定永远是数组】——空结果时会抛 find is not a function。
            // 这里改为返回空 List，与方法结尾的返回类型保持一致；对外契约因此收敛为「永远是数组」。
            return new ArrayList<>();
        }
        List<JSONObject> paramNoList = new ArrayList<>();
        pageList.getRecords().forEach(entity -> {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("paramNo", entity.getParamNo());
            jsonObject.put("paramName", entity.getParamName());
            paramNoList.add(jsonObject);
        });
        return paramNoList;
    }

    private JSONObject handleNewInputIndex(String knowledgeId, JSONObject params, String relateIndexSet, Map<String, Object> paramGroupResultMap) {
        JSONObject inputIndexContent = new JSONObject();
        Boolean indexFlag = params.getBoolean("indexFlag");
        if (Objects.nonNull(indexFlag) && indexFlag) {
            long start = System.currentTimeMillis();
            // 查询需要溯源的指标
            Map<String, String> indexInfoMap = knowledgeRelateIndexService.getSourceIndexList(knowledgeId);
            if (Objects.nonNull(indexInfoMap) && !indexInfoMap.isEmpty()) {
                log.info("开始inputIndex查询请求，TraceId为[{}]", params.getString("traceId"));
                List<String> indexList = new ArrayList<>(indexInfoMap.keySet());
                getIndexValueMap(relateIndexSet, params, indexList, paramGroupResultMap);
                indexInfoMap.keySet().forEach(indexNo -> inputIndexContent.put(indexInfoMap.get(indexNo), paramGroupResultMap.get(indexNo)));
            }
            log.info("完成inputIndex查询请求，TraceId为[{}], 耗时[{}ms]", params.getString("traceId"), System.currentTimeMillis() - start);
        }
        return inputIndexContent;
    }

    private JSONObject handleInputIndex(String inputIndex, JSONObject params, String relateIndexSet, Map<String, Object> paramGroupResultMap) {
        JSONObject inputIndexContent = new JSONObject();
        Boolean indexFlag = params.getBoolean("indexFlag");
        if (Objects.nonNull(indexFlag) && indexFlag && StringUtils.isNotEmpty(inputIndex)) {
            log.info("开始inputIndex查询请求，TraceId为[{}]", params.getString("traceId"));
            long start = System.currentTimeMillis();
            JSONArray inputIndexArray = JSONArray.parseArray(inputIndex);
            List<String> indexNoList = inputIndexArray.stream().map(r -> ((JSONObject) r).getString("indexNo")).collect(Collectors.toList());
            if (CollectionUtils.isNotEmpty(indexNoList)) {
                getIndexValueMap(relateIndexSet, params, indexNoList, paramGroupResultMap);
                for (Object inputIndexObj : inputIndexArray) {
                    JSONObject inputIndexJson = (JSONObject) inputIndexObj;
                    String indexName = inputIndexJson.getString("indexName");
                    String indexNo = inputIndexJson.getString("indexNo");
                    inputIndexContent.put(indexName, paramGroupResultMap.get(indexNo));
                }
            }
            log.info("完成inputIndex查询请求，TraceId为[{}], 耗时[{}ms]", params.getString("traceId"), System.currentTimeMillis() - start);
        }
        return inputIndexContent;
    }

    private JSONObject getSourceResult(String moduleCode, String sourceTraceId) {
        log.info("开始[{}]的溯源查询请求，TraceId为[{}]", moduleCode, sourceTraceId);
        long startTime = System.currentTimeMillis();
        TraceQueryResultEntity traceInfo = traceQueryResultService.getTraceQueryResultByTraceId(sourceTraceId);
        JSONArray sourceCard = new JSONArray();
        JSONArray sourceImage = new JSONArray();
        JSONArray wholeSource = new JSONArray();
        if (Objects.nonNull(traceInfo)) {
            String queryResult = traceInfo.getQueryResult();
            if (StringUtils.isNotEmpty(queryResult)) {
                try {
                    sourceCard = JSONArray.parseArray(queryResult);
                } catch (Exception e) {
                    log.error("溯源查询结果溯源配置[{}]转换异常，异常信息：{}", queryResult, ExceptionUtils.getStackTrace(e));
                }
            }
            String imageQueryResult = traceInfo.getImageQueryResult();
            if (StringUtils.isNotEmpty(imageQueryResult)) {
                try {
                    sourceImage = JSONArray.parseArray(imageQueryResult);
                } catch (Exception e) {
                    log.error("溯源查询结果图片配置[{}]转换异常，异常信息：{}", imageQueryResult, ExceptionUtils.getStackTrace(e));
                }
            }
            String wholeSourceQueryResult = traceInfo.getWholeSourceQueryResult();
            if (StringUtils.isNotEmpty(wholeSourceQueryResult)) {
                try {
                    wholeSource = JSONArray.parseArray(wholeSourceQueryResult);
                } catch (Exception e) {
                    log.error("溯源查询结果来源配置[{}]转换异常，异常信息：{}", wholeSourceQueryResult, ExceptionUtils.getStackTrace(e));
                }
            }
        }
        JSONObject result = new JSONObject();
        result.put("isExist", true);
        result.put("promptContent", "");
        result.put("traceId", sourceTraceId);
        result.put("source_card", sourceCard);
        result.put("image_source", sourceImage);
        result.put("whole_source", wholeSource);
        log.info("完成[{}]的溯源查询请求，TraceId为[{}]，耗时：{}ms", moduleCode, sourceTraceId, System.currentTimeMillis() - startTime);
        return result;
    }

    public boolean checkContainReference(JSONArray jsonArray) {
        return jsonArray.stream().filter(obj -> obj instanceof JSONObject).map(obj -> (JSONObject) obj).map(jsonObj -> jsonObj.getJSONObject("if")).filter(Objects::nonNull).map(ifObj -> ifObj.getJSONArray("reference")).anyMatch(reference -> reference != null && !reference.isEmpty());
    }

    private List<String> getKnowledgeIdListByRoleId() {
        List<String> knowledgeIdList = null;
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        String role = apiContextModel.getRole();
        if (StringUtils.isNotEmpty(role)) {
            List<String> roleIdList = JSON.parseArray(role, String.class);
            knowledgeIdList = sysRoleKnowledgeService.getKnowledgeIdListByRoleId(roleIdList);
        }
        return knowledgeIdList;
    }

    private void finishEmitter(SseEmitter emitter) {
        if (Objects.isNull(emitter)) {
            return;
        }
        try {
            emitter.send("finished!");
        } catch (IOException e) {
            log.error("发送结束消息失败:{}", e.getMessage());
            emitter.completeWithError(e);
        }
        emitter.complete();
    }

    private String getKnowledgeCode(String paramStr){
        String result = "";
        // Spring Security: SecurityContext is set by JwtAuthenticationFilter automatically
        SseEmitter emitter = new SseEmitter(0L);
        log.info("======getKnowledgeCode======入参："+paramStr);
        Object obj = getPromptContent(paramStr, emitter);
        log.info("======getKnowledgeCode======入参："+paramStr+"====结果："+obj);
        if(obj instanceof JSONObject){
            JSONObject objJO = (JSONObject) obj;
            if(objJO.containsKey("answer")){
                result = JSONTools.getString(objJO,"answer");
            }
            if(StringUtils.isBlank(result)){
                result = JSONTools.getString(objJO,"content");
            }
        }
        return result;
    }
}
