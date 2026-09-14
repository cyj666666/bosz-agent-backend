package com.suzhou.bank.agent.service;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import org.apache.commons.lang3.tuple.Pair;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.entity.KnowledgeBaseParamsEntity;
import com.suzhou.bank.agent.entity.KnowledgeRelateIndexEntity;
import com.suzhou.bank.agent.entity.OpenApiConfEntity;
import com.suzhou.bank.agent.model.req.*;
import com.suzhou.bank.agent.model.vo.KnowledgeBlackConfigSaveVO;
import com.suzhou.bank.agent.model.vo.KnowledgeBlackParamsConfigVO;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.InputStream;
import java.util.List;
import java.util.Map;
import java.util.Set;

public interface IknowledgeBaseConfigService {

    ListResult<?> queryKnowledgeBaseGroupTree(boolean authFlag, Integer spaceId, String relaGroupFlag, Integer modelFlag, String groupName, String groupValue);

    AgentResult<?> updateKnowledgeBaseGroupInfo(KnowledgeBaseGroupReq reqMsg);

    AgentResult<?> insertKnowledgeBaseGroupInfo(KnowledgeBaseGroupReq reqMsg);

    AgentResult<?> insertKnowledgeBaseParamsInfo(KnowledgeBaseParamsInfoSaveReq reqMsg);

    void handleIndexParamConfig(KnowledgeBaseParamsEntity knowledgeBaseParamsEntity, String relateIndexSet);

    void handleInterfaceConfig(OpenApiConfEntity openApiConfEntity);

    Set<String> getParamNoSet(JSONArray promptCondGroups);

    void handleKnowledgeRelateIndex(String knowledgeId, Set<String> indexNoSet, JSONArray allParentIndexList);

    void copyKnowledgeBaseParamsInfo(KnowledgeBaseParamsInfoSaveReq reqMsg);

    void moveKnowledgeBaseParamsInfo(KnowledgeBaseParamsInfoSaveReq reqMsg);

    ListResult<?> queryKnowledgeBaseParamsList(KnowledgeBaseParamReq reqMsg);

    ListResult<?> pageKnowledgeBaseParamsList(KnowledgeBaseParamReq reqMsg);

    AgentResult<?> deleteKnowledgeBaseParamsInfo(String paramId);

    AgentResult<?> queryKnowledgeBaseParamsInfo(KnowledgeBaseParamsInfoReq reqMsg);

    AgentResult<?> updateKnowledgeBaseParamsInfo(KnowledgeBaseParamsInfoSaveReq reqMsg);

    AgentResult<?> deleteKnowledgeBaseGroupInfo(String groupId);

    void sendAnswer(KnowledgeBasePromptViewReq req, SseEmitter emitter);

    void sendResultCheck(KnowledgeResultCheckReq req, SseEmitter emitter);

    AgentResult<?> resultCheck(KnowledgeResultCheckReq reqMsg);

    AgentResult<?> knowledgeBasePromptPreview(KnowledgeBasePromptViewReq reqMsg);

    AgentResult<?> KnowledgeBaseTracePreview(KnowledgeBasePromptViewReq reqMsg);

    AgentResult<?> KnowledgeBaseImagePreview(KnowledgeBasePromptViewReq reqMsg);

    AgentResult<?> KnowledgeBaseWholeSourcePreview(KnowledgeBasePromptViewReq reqMsg);

    String parsePrompt(String prompt, JSONObject params, Map<String, Object> groupMap);

    Map<String, Object> parsePromptWithCond(String isMarkdown, int[] indexes, String relateIndexSet, String prompt, JSONObject params, Map<String, Object> paramGroupResultMap);

    Map<String, String> getPromptDescWithCond(String relateIndexSet, String contentDesc, String inputCondition, JSONObject params, Map<String, Object> paramGroupResultMap);

    Map<String, Object> parsePromptWithCondAndKnowledge(String isMarkdown, String relateIndexSet, String prompt, JSONObject params, Map<String, Object> paramGroupResultMap);

    String parseTraceConfig(String relateIndexSet, String moduleCode, String traceConfig, JSONObject params, Map<String, Object> paramGroupResultMap);

    String parseImageConfig(String relateIndexSet, String moduleCode, String traceConfig, JSONObject params, Map<String, Object> paramGroupResultMap);

    String parseWholeSourceConfig(String relateIndexSet, String moduleCode, String wholeSourceConfig, JSONObject params, Map<String, Object> paramGroupResultMap);

    String getAiAnswerMsgNo(KnowledgeBasePromptViewReq reqMsg);

    Map<String, Object> handleParam(String relateIndexSet, JSONObject params, List<String> paramNoList, Map<String, Object> cascadeMap, Map<String, Object> paramGroupResultMap);

    AgentResult<?> getSourceParamList(String paramId);

    ListResult<?> getKnowledgeParamsList(KnowledgeBlackParamsConfigReq reqMsg);

    AgentResult<?> addKnowledgeParams(KnowledgeBlackParamsConfigVO reqMsg);

    AgentResult<?> updateKnowledgeParams(KnowledgeBlackParamsConfigVO reqMsg);

    AgentResult<?> batchAddKnowledgeParams(List<KnowledgeBlackParamsConfigVO> reqMsg);

    AgentResult<?> getParamSelectList(KnowledgeBlackParamsConfigReq reqMsg);

    AgentResult<?> deleteKnowledgeParams(KnowledgeBlackParamsConfigReq reqMsg);

    AgentResult<?> batchDeleteKnowledgeParams(List<Integer> idList);

    AgentResult<?> batchUpdateKnowledgeParams(List<KnowledgeBlackParamsConfigVO> reqMsg);

    AgentResult<?> saveBlackParam(KnowledgeBlackConfigSaveVO reqMsg);

    Map<String, Object> getIndexValueMap(String relateIndexSet, JSONObject params, List<String> arrayList, Map<String, Object> paramGroupResultMap);

    AgentResult<?> KnowledgeResourcePreview(KnowledgeResourceViewReq reqMsg);

    Object previewJsExpression(PreviewJsExceptionReq reqMsg);

    void handleOutputGroupParam(String relateIndexSet, Map<String, Object> paramGroupResultMap, JSONObject params, String output);

    void knowledgeCacheParse(InputStream inputStream, String fileName);

    Object getPromptContent(String paramStr, SseEmitter emitter);

    Object getPromptStream(String paramStr, SseEmitter emitter);

    Pair<String, Object> getPromptContentAndModuleCode(KnowledgeBasePromptViewReq reqMsg);

    Object knowledgePreview(KnowledgePreviewReq knowledgePreviewReq);

    Integer saveRelateIndex(KnowledgeRelateIndexEntity knowledgeRelateIndex);

    void updateRelateIndex(List<KnowledgeRelateIndexEntity> knowledgeRelateIndexList);

    void removeRelateIndexList(List<Integer> idList);

    ListResult<?> selectRelateIndexList(KnowledgeRelateIndexReq reqMsg);

    void knowledgeCallLlm(JSONObject req, SseEmitter emitter);

    Object getApplyPrompt(JSONObject req, SseEmitter emitter);

    ListResult<?> queryFirstKnowledgeGroup();

    KnowledgeBaseParamsEntity queryKnowledgeBaseParams(String moduleCode, boolean ignoreStatus);

    KnowledgeBaseParamsEntity getKnowledgeGroupType(String moduleCode);

    String getGroupType(String groupId);

    Map<String, String> getGroupNameList(List<String> groupValue);

    Object simplePageKnowledgeBaseParamsList(KnowledgeBaseParamReq reqMsg);

    JSONObject addDocumentKnowledge(DocumentKnowledgeReq reqMsg);

    Object unbindKnowledge(JSONObject reqMsg);
}
