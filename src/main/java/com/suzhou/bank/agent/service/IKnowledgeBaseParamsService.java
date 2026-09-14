package com.suzhou.bank.agent.service;

import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.IndexRelateKnowledgeInfoEntity;
import com.suzhou.bank.agent.entity.KnowledgeBaseParamsEntity;

import java.util.List;
import java.util.Map;

/**
 * @Description: test
 * @Author: jeecg-boot
 * @Date:   2024-05-30
 * @Version: V1.0
 */
public interface IKnowledgeBaseParamsService extends IService<KnowledgeBaseParamsEntity> {

    KnowledgeBaseParamsEntity getByCondition(String groupId);

    void updateRelateIndexSet(String id, String relateIndexSet);

    KnowledgeBaseParamsEntity getByParamNo(String paramNo, boolean ignoreStatus);

    void generateIndexRelateKnowledgeInfoV2();

    List<IndexRelateKnowledgeInfoEntity> generateIndexRelateKnowledgeInfo(String paramNo);

    void generateIndexRelateIndexInfo();

    JSONObject getPromptTemplate();

    List<JSONObject> getOtherRelatePromptList(List<String> paramNoList);

    Map<String, String> getMapByParamNo(List<String> paramNoList);

    // 知识库跨数据源同步：保存知识库参数
    void saveSyncKnowledgeBaseParams(List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList);

    // 知识库跨数据源同步：根据知识库参数ID列表查询知识库参数
    List<KnowledgeBaseParamsEntity> listDistanceKnowledgeBaseParams(List<String> paramIdList);

    // 知识库跨数据源同步：保存知识库参数
    void saveDistanceKnowledgeBaseParams(List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList);
}
