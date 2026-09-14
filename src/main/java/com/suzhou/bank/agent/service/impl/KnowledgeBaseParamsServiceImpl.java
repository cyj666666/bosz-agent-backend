package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.date.DateUtil;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.google.common.collect.Lists;
import com.google.common.collect.Sets;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.apache.commons.lang3.tuple.Pair;
import org.htmlcleaner.HtmlCleaner;
import org.htmlcleaner.TagNode;
import com.suzhou.bank.agent.entity.*;
import com.suzhou.bank.agent.mapper.IndexParamsMapper;
import com.suzhou.bank.agent.mapper.KnowledgeBaseParamsMapper;
import com.suzhou.bank.agent.mapper.KnowledgeRelateIndexMapper;
import com.suzhou.bank.agent.service.IIndexRelateIndexInfoService;
import com.suzhou.bank.agent.service.IIndexRelateKnowledgeInfoService;
import com.suzhou.bank.agent.service.IKnowledgeBaseParamsService;
import com.suzhou.bank.agent.service.IKnowledgeBaseVersionService;
import com.suzhou.bank.agent.util.ParamUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class KnowledgeBaseParamsServiceImpl extends ServiceImpl<KnowledgeBaseParamsMapper, KnowledgeBaseParamsEntity> implements IKnowledgeBaseParamsService {

    @Autowired
    private IIndexRelateKnowledgeInfoService indexRelateKnowledgeInfoService;

    @Autowired
    private IIndexRelateIndexInfoService indexRelateIndexInfoService;

    @Resource
    private IndexParamsMapper indexParamsMapper;

    @Resource
    private KnowledgeRelateIndexMapper knowledgeRelateIndexMapper;

    @Autowired
    private IKnowledgeBaseVersionService knowledgeBaseVersionService;

    @Autowired
    @Qualifier(value = "RelateIndexThreadPool")
    Executor relateIndexThreadPool;

    @Override
    public KnowledgeBaseParamsEntity getByCondition(String groupId) {
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(KnowledgeBaseParamsEntity::getGroupId, groupId);
        // queryWrapper.eq(KnowledgeBaseParamsEntity::getParamStatus, 'Y');
        queryWrapper.eq(KnowledgeBaseParamsEntity::getOnline, 'Y');
        List<KnowledgeBaseParamsEntity> indexParamsEntityList = list(queryWrapper);
        if (CollectionUtils.isEmpty(indexParamsEntityList)) {
            return null;
        }
        return indexParamsEntityList.get(0);
    }

    @Override
    public void updateRelateIndexSet(String id, String relateIndexSet) {
        LambdaUpdateWrapper<KnowledgeBaseParamsEntity> queryWrapper = Wrappers.lambdaUpdate();
        queryWrapper.set(KnowledgeBaseParamsEntity::getRelateIndexSet, relateIndexSet);
        queryWrapper.eq(KnowledgeBaseParamsEntity::getParamId, id);
        update(queryWrapper);
    }

    @Override
    public KnowledgeBaseParamsEntity getByParamNo(String paramNo, boolean ignoreStatus) {
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(KnowledgeBaseParamsEntity::getParamNo, paramNo);
        queryWrapper.eq(!ignoreStatus, KnowledgeBaseParamsEntity::getOnline, 'Y');
        // queryWrapper.eq(!ignoreStatus, KnowledgeBaseParamsEntity::getParamStatus, 'Y');
        queryWrapper.orderByDesc(KnowledgeBaseParamsEntity::getInputTime);
        queryWrapper.last(" limit 1");
        return getOne(queryWrapper);
    }

    @Override
    public void generateIndexRelateKnowledgeInfoV2() {
        log.info("开始批量生成指标关联知识库信息！");
        List<JSONObject> allIndexRelateInfo = knowledgeRelateIndexMapper.getAllIndexRelateInfo();
        if (CollectionUtils.isEmpty(allIndexRelateInfo)) {
            return;
        }

        // 先清除历史跑批数据
        indexRelateKnowledgeInfoService.remove(Wrappers.lambdaQuery());

        Lists.partition(allIndexRelateInfo, 1000).forEach(partition -> {
            List<IndexRelateKnowledgeInfoEntity> relateKnowledgeInfoEntityList = new ArrayList<>();
            partition.forEach(object -> {
                if (Objects.nonNull(object)) {
                    IndexRelateKnowledgeInfoEntity indexRelateKnowledgeInfoEntity = new IndexRelateKnowledgeInfoEntity();
                    indexRelateKnowledgeInfoEntity.setParamNo(object.getString("indexNo"));
                    indexRelateKnowledgeInfoEntity.setRelateGroupId(object.getString("groupId"));
                    indexRelateKnowledgeInfoEntity.setRelateKnowledgeNo(object.getString("paramId"));
                    indexRelateKnowledgeInfoEntity.setRelateKnowledgeCode(object.getString("paramNo"));
                    indexRelateKnowledgeInfoEntity.setRelateKnowledgeName(object.getString("paramName"));
                    indexRelateKnowledgeInfoEntity.setRelateItems("知识配置");
                    relateKnowledgeInfoEntityList.add(indexRelateKnowledgeInfoEntity);
                }
            });
            if (CollectionUtils.isNotEmpty(relateKnowledgeInfoEntityList)) {
                indexRelateKnowledgeInfoService.saveBatch(relateKnowledgeInfoEntityList);
            }
        });
    }

    @Override
    public List<IndexRelateKnowledgeInfoEntity> generateIndexRelateKnowledgeInfo(String paramNo) {
        long count = count(Wrappers.lambdaQuery());
        if (count == 0) {
            return null;
        }
        int pageSize = 10;
        List<IndexRelateKnowledgeInfoEntity> relateKnowledgeInfoEntityList = new ArrayList<>();
        for (int i = 0; i < count; i += pageSize) {
            LambdaQueryWrapper<KnowledgeBaseParamsEntity> lambdaQueryWrapper = Wrappers.lambdaQuery();
            lambdaQueryWrapper.select(KnowledgeBaseParamsEntity::getGroupId, KnowledgeBaseParamsEntity::getParamId, KnowledgeBaseParamsEntity::getParamNo, KnowledgeBaseParamsEntity::getParamName, KnowledgeBaseParamsEntity::getPrompt, KnowledgeBaseParamsEntity::getTraceConfig, KnowledgeBaseParamsEntity::getRelateIndexSet, KnowledgeBaseParamsEntity::getImageConfig, KnowledgeBaseParamsEntity::getWholeSourceConfig);
            Page<KnowledgeBaseParamsEntity> page = new Page<>(i / pageSize + 1, pageSize);
            Page<KnowledgeBaseParamsEntity> pageResult = page(page, lambdaQueryWrapper);
            if (CollectionUtils.isNotEmpty(pageResult.getRecords())) {
                for (KnowledgeBaseParamsEntity knowledgeBaseParamsEntity : pageResult.getRecords()) {
                    boolean isExistsInPrompt = checkIsExistsInPrompt(knowledgeBaseParamsEntity.getPrompt(), paramNo);
                    boolean isExistsInWholeSourceConfig = checkIsExistsInWholeSourceConfig(knowledgeBaseParamsEntity.getWholeSourceConfig(), paramNo);
                    boolean isExistsInImageConfig = checkIsExistsInImageConfig(knowledgeBaseParamsEntity.getImageConfig(), paramNo);
                    boolean isExistsInTraceConfig = checkIsExistsInTraceConfig(knowledgeBaseParamsEntity.getTraceConfig(), paramNo);
                    boolean isParamNoExists = isExistsInPrompt || isExistsInWholeSourceConfig || isExistsInImageConfig || isExistsInTraceConfig;
                    if (isParamNoExists) {
                        IndexRelateKnowledgeInfoEntity indexRelateKnowledgeInfoEntity = new IndexRelateKnowledgeInfoEntity();
                        indexRelateKnowledgeInfoEntity.setParamNo(paramNo);
                        indexRelateKnowledgeInfoEntity.setRelateGroupId(knowledgeBaseParamsEntity.getGroupId());
                        indexRelateKnowledgeInfoEntity.setRelateKnowledgeNo(knowledgeBaseParamsEntity.getParamId());
                        indexRelateKnowledgeInfoEntity.setRelateKnowledgeCode(knowledgeBaseParamsEntity.getParamNo());
                        indexRelateKnowledgeInfoEntity.setRelateKnowledgeName(knowledgeBaseParamsEntity.getParamName());
                        StringBuffer items = new StringBuffer();
                        if (isExistsInPrompt) {
                            items.append("知识配置,");
                        }
                        if (isExistsInTraceConfig) {
                            items.append("溯源配置,");
                        }
                        if (isExistsInImageConfig) {
                            items.append("图片配置,");
                        }
                        if (isExistsInWholeSourceConfig) {
                            items.append("全部来源配置");
                        }
                        if (items.length() > 0 && items.charAt(items.length() - 1) == ',') {
                            items.deleteCharAt(items.length() - 1);
                        }
                        indexRelateKnowledgeInfoEntity.setRelateItems(items.toString());
                        relateKnowledgeInfoEntityList.add(indexRelateKnowledgeInfoEntity);
                    }
                }
            }
        }
        return relateKnowledgeInfoEntityList;
    }

    @Async
    @Override
    public void generateIndexRelateIndexInfo() {
        List<String> allParamNoList = indexParamsMapper.getAllParamNoList();
        if (CollectionUtils.isEmpty(allParamNoList)) {
            return;
        }

        List<IndexParamsEntity> havingRelationIndexList = indexParamsMapper.getHavingRelationIndexList();
        if (CollectionUtils.isEmpty(havingRelationIndexList)) {
            return;
        }
        int count = havingRelationIndexList.size();
        if (count == 0) {
            return;
        }

        // 先清除历史跑批数据
        indexRelateIndexInfoService.remove(Wrappers.lambdaQuery());

        ExecutorCompletionService<String> completionService = new ExecutorCompletionService<>(relateIndexThreadPool);
        List<Future<String>> futures = new ArrayList<>();

        for (String paramNo : allParamNoList) {
            List<IndexRelateIndexInfoEntity> relateIndexInfoEntityList = new CopyOnWriteArrayList<>();
            for (IndexParamsEntity indexParamsEntity : havingRelationIndexList) {
                String scriptType = indexParamsEntity.getScriptType();
                String script = indexParamsEntity.getScript();
                String intfParams = indexParamsEntity.getIntfParams();
                if ((scriptType.equals("Api") && !intfParams.contains(paramNo)) || (scriptType.equals("Sql") && !script.contains(paramNo))) {
                    continue;
                }
                futures.add(completionService.submit(() -> {
                    boolean isExistsInPrompt;
                    if (scriptType.equals("Api")) {
                        isExistsInPrompt = isExistsInApiParams(indexParamsEntity, paramNo);
                    } else {
                        isExistsInPrompt = isExistsInSqlParams(indexParamsEntity, paramNo);
                    }
                    if (isExistsInPrompt) {
                        IndexRelateIndexInfoEntity indexRelateIndexInfoEntity = new IndexRelateIndexInfoEntity();
                        indexRelateIndexInfoEntity.setParamNo(paramNo);
                        indexRelateIndexInfoEntity.setRelateGroupId(indexParamsEntity.getParentParamNo());
                        indexRelateIndexInfoEntity.setRelateParamId(indexParamsEntity.getParamID());
                        indexRelateIndexInfoEntity.setRelateParamNo(indexParamsEntity.getParamNo());
                        indexRelateIndexInfoEntity.setRelateParamName(indexParamsEntity.getParamName());
                        relateIndexInfoEntityList.add(indexRelateIndexInfoEntity);
                    }
                    return "";
                }));
            }
            for (Future<String> future : futures) {
                try {
                    future.get();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    log.error("线程被中断，异常信息：{}", ExceptionUtils.getStackTrace(e));
                    break;
                } catch (ExecutionException e) {
                    log.error("任务执行异常，异常信息：{}", ExceptionUtils.getStackTrace(e.getCause()));
                }
            }
            if (CollectionUtils.isNotEmpty(relateIndexInfoEntityList)) {
                indexRelateIndexInfoService.saveBatch(relateIndexInfoEntityList);
            }
        }
        log.info("完成批量生成指标关联指标信息！");
    }

    @Override
    public JSONObject getPromptTemplate() {
        return indexParamsMapper.getPromptTemplate();
    }

    @Override
    public List<JSONObject> getOtherRelatePromptList(List<String> paramNoList) {
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> queryWrapper = Wrappers.lambdaQuery(KnowledgeBaseParamsEntity.class)
                .select(KnowledgeBaseParamsEntity::getParamNo, KnowledgeBaseParamsEntity::getPrompt, KnowledgeBaseParamsEntity::getParamName)
                .in(KnowledgeBaseParamsEntity::getParamNo, paramNoList)
                .eq(KnowledgeBaseParamsEntity::getOnline, 'Y');
        List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList = list(queryWrapper);
        if (CollectionUtils.isEmpty(knowledgeBaseParamsList)) {
            return Collections.emptyList();
        }
        List<JSONObject> promptList = new ArrayList<>();
        try {
            knowledgeBaseParamsList.forEach(item -> {
                JSONObject jsonObject = new JSONObject();
                jsonObject.put("code", item.getParamNo());
                jsonObject.put("name", item.getParamName());
                String prompt = JSONArray.parseArray(item.getPrompt()).getJSONObject(0).getJSONObject("if").getString("output");
                if (StringUtils.isNotEmpty(prompt)) {
                    String today = DateUtil.format(new Date(), "yyyy-MM-dd");
                    String tomorrow = DateUtil.format(DateUtil.offsetDay(new Date(), 1), "yyyy-MM-dd");
                    String yesterday = DateUtil.format(DateUtil.offsetDay(new Date(), -1), "yyyy-MM-dd");
                    prompt = prompt.replace("{today}", today).replace("{tomorrow}", tomorrow).replace("{yesterday}", yesterday);
                }
                jsonObject.put("prompt", prompt);
                promptList.add(jsonObject);
            });
        } catch (Exception e) {
            log.error("获取其他关联指标提示词异常，异常信息：{}", ExceptionUtils.getStackTrace(e));
            return Collections.emptyList();
        }
        return promptList;
    }

    @Override
    public Map<String, String> getMapByParamNo(List<String> paramNoList) {
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> queryWrapper = Wrappers.lambdaQuery(KnowledgeBaseParamsEntity.class)
                .select(KnowledgeBaseParamsEntity::getParamNo, KnowledgeBaseParamsEntity::getLargeModelCode, KnowledgeBaseParamsEntity::getParamId)
                .in(KnowledgeBaseParamsEntity::getParamNo, paramNoList)
                .ne(KnowledgeBaseParamsEntity::getLargeModelCode, "")
                .isNotNull(KnowledgeBaseParamsEntity::getLargeModelCode)
                .eq(KnowledgeBaseParamsEntity::getOnline, 'Y');
        List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList = list(queryWrapper);
        if (CollectionUtils.isEmpty(knowledgeBaseParamsList)) {
            return Collections.emptyMap();
        }

        // 查知识库版本数据
        List<String> paramIdList = knowledgeBaseParamsList.stream().map(KnowledgeBaseParamsEntity::getParamId).collect(java.util.stream.Collectors.toList());
        LambdaQueryWrapper<KnowledgeBaseVersionEntity> versionQueryWrapper = Wrappers.lambdaQuery(KnowledgeBaseVersionEntity.class)
                .select(KnowledgeBaseVersionEntity::getParamId, KnowledgeBaseVersionEntity::getLargeModelCode)
                .in(KnowledgeBaseVersionEntity::getLatestFlag, 1)
                .in(KnowledgeBaseVersionEntity::getParamId, paramIdList);
        List<KnowledgeBaseVersionEntity> knowledgeBaseVersionList = knowledgeBaseVersionService.list(versionQueryWrapper);
        if (CollectionUtils.isNotEmpty(knowledgeBaseVersionList)) {
            knowledgeBaseParamsList.forEach(item -> {
                KnowledgeBaseVersionEntity knowledgeBaseVersionEntity = knowledgeBaseVersionList.stream().filter(version -> version.getParamId().equals(item.getParamId())).findFirst().orElse(null);
                if (Objects.nonNull(knowledgeBaseVersionEntity) && StringUtils.isNotEmpty(knowledgeBaseVersionEntity.getLargeModelCode())) {
                    item.setLargeModelCode(knowledgeBaseVersionEntity.getLargeModelCode());
                }
            });
        }

        return knowledgeBaseParamsList.stream().collect(Collectors.toMap(KnowledgeBaseParamsEntity::getParamNo, KnowledgeBaseParamsEntity::getLargeModelCode, (oldValue, newValue) -> newValue));
    }

    @Override
    public void saveSyncKnowledgeBaseParams(List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList) {
        saveOrUpdateBatch(knowledgeBaseParamsList);
    }

    @Override
    public List<KnowledgeBaseParamsEntity> listDistanceKnowledgeBaseParams(List<String> paramIdList) {
        return listByIds(paramIdList);
    }

    @Override
    public void saveDistanceKnowledgeBaseParams(List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList) {
        saveOrUpdateBatch(knowledgeBaseParamsList);
    }

    private boolean isExistsInSqlParams(IndexParamsEntity indexParamsEntity, String paramNo) {
        try {
            String script = indexParamsEntity.getScript();
            if (StringUtils.isEmpty(script) || !script.startsWith("{")) {
                return false;
            }
            JSONObject jsonObject = JSONObject.parseObject(script);
            if (Objects.isNull(jsonObject)) {
                return false;
            }
            List<String> paramNoList = new ArrayList<>();
            for (Object obj : jsonObject.getJSONArray("paramData")) {
                JSONObject object = (JSONObject) obj;
                JSONObject relateIndex = object.getJSONObject("relateIndex");
                if (Objects.nonNull(relateIndex)) {
                    String no = relateIndex.getString("no");
                    paramNoList.add(no);
                }
            }
            return paramNoList.contains(paramNo);
        } catch (Exception e) {
            log.error("关联Sql接口关联参数判断异常，异常原因{}", ExceptionUtils.getStackTrace(e));
            return false;
        }
    }

    private boolean isExistsInApiParams(IndexParamsEntity indexParamsEntity, String paramNo) {
        try {
            String intfParams = indexParamsEntity.getIntfParams();
            if (StringUtils.isEmpty(intfParams) || !intfParams.startsWith("[")) {
                return false;
            }
            JSONArray jsonArray = JSON.parseArray(intfParams);
            List<String> paramNoList = new ArrayList<>();
            if (null != jsonArray && !jsonArray.isEmpty()) {
                jsonArray.forEach(json -> {
                    JSONObject object = (JSONObject) json;
                    object.keySet().forEach(obj -> {
                        JSONObject value = object.getJSONObject(obj);
                        if (Objects.nonNull(value)) {
                            JSONObject relateIndex = value.getJSONObject("relateIndex");
                            if (Objects.nonNull(relateIndex) && StringUtils.isNotEmpty(relateIndex.getString("no"))) {
                                paramNoList.add(relateIndex.getString("no"));
                            }
                        }
                    });
                });
            }
            return paramNoList.contains(paramNo);
        } catch (Exception e) {
            log.error("关联Api接口关联参数判断异常，异常原因{}", ExceptionUtils.getStackTrace(e));
            return false;
        }
    }

    private boolean checkIsExistsInWholeSourceConfig(String wholeSourceConfig, String paramNo) {
        try {
            if (StringUtils.isEmpty(wholeSourceConfig) || !wholeSourceConfig.startsWith("[")) {
                return false;
            }
            JSONArray wholeSourceArr = JSONArray.parseArray(wholeSourceConfig);
            if (CollectionUtils.isEmpty(wholeSourceArr)) {
                return false;
            }
            List<String> paramNoList = new ArrayList<>();
            for (Object source : wholeSourceArr) {
                JSONObject sourceObject = (JSONObject) source;
                String sourceAnchor = sourceObject.getString("sourceAnchor");
                List<String> sourceParamNoList = ParamUtil.getParamNoList(sourceAnchor);
                paramNoList.addAll(sourceParamNoList);
            }
            return paramNoList.contains(paramNo);
        } catch (Exception e) {
            log.error("全部来源配置解析失败:{}，失败原因{}", wholeSourceConfig, ExceptionUtils.getStackTrace(e));
            return false;
        }
    }

    private boolean checkIsExistsInImageConfig(String imageConfig, String paramNo) {
        try {
            if (StringUtils.isEmpty(imageConfig) || !imageConfig.startsWith("[")) {
                return false;
            }
            JSONArray jsonArray = JSONArray.parseArray(imageConfig);
            if (CollectionUtils.isEmpty(jsonArray)) {
                return false;
            }
            JSONObject traceConfig = jsonArray.getJSONObject(0);
            List<String> paramNoList = new ArrayList<>();
            String html = traceConfig.getString("html").replace("<br />", "").replace("&nbsp;", "");
            if (StringUtils.isNotEmpty(html)) {
                Pair<String, List<String>> paramInfoList = ParamUtil.getParamInfoList(html);
                paramNoList = paramInfoList.getValue();
            }
            return paramNoList.contains(paramNo);
        } catch (Exception e) {
            log.error("图片配置解析失败:{}，失败原因{}", imageConfig, ExceptionUtils.getStackTrace(e));
            return false;
        }
    }

    private boolean checkIsExistsInTraceConfig(String traceConfig, String paramNo) {
        try {
            if (StringUtils.isEmpty(traceConfig) || !traceConfig.startsWith("[")) {
                return false;
            }
            JSONArray traceConfigArr = JSONArray.parseArray(traceConfig);
            if (CollectionUtils.isEmpty(traceConfigArr)) {
                return false;
            }
            HtmlCleaner htmlCleaner = new HtmlCleaner();
            List<String> allParamNoList = new ArrayList<>();
            for (Object trace : traceConfigArr) {
                JSONObject traceObj = (JSONObject) trace;
                String sourceAnchor = traceObj.getString("source_anchor");
                List<String> sourceParamNoList = ParamUtil.getParamNoList(sourceAnchor);
                if (CollectionUtils.isNotEmpty(sourceParamNoList)) {
                    allParamNoList.addAll(sourceParamNoList);
                }
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
            return allParamNoList.contains(paramNo);
        } catch (Exception e) {
            log.error("溯源配置解析失败:{}，失败原因{}", traceConfig, ExceptionUtils.getStackTrace(e));
            return false;
        }
    }

    private boolean checkIsExistsInPrompt(String prompt, String paramNo) {
        try {
            if (StringUtils.isEmpty(prompt) || !prompt.startsWith("[")) {
                return false;
            }
            JSONArray jsonArray = JSONArray.parseArray(prompt);
            if (CollectionUtils.isEmpty(jsonArray)) {
                return false;
            }
            Set<String> paramNoSet = Sets.newHashSet();
            for (Object group : jsonArray) {
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
            return paramNoSet.contains(paramNo);
        } catch (Exception e) {
            log.error("知识库配置解析失败:{}，失败原因{}", prompt, ExceptionUtils.getStackTrace(e));
            return false;
        }
    }
}
