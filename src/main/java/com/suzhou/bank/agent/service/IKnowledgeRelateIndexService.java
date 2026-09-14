package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.entity.KnowledgeRelateIndexEntity;
import com.suzhou.bank.agent.entity.KnowledgeRelateInputParamEntity;
import com.suzhou.bank.agent.model.req.KnowledgeRelateIndexReq;

import java.util.List;
import java.util.Map;

/**
 * @Description: 知识库管理指标信息
 * @Author: jeecg-boot
 * @Date:   2025-09-26
 * @Version: V1.0
 */
public interface IKnowledgeRelateIndexService extends IService<KnowledgeRelateIndexEntity> {

    Integer saveIndex(KnowledgeRelateIndexEntity knowledgeRelateIndex);

    void updateIndex(List<KnowledgeRelateIndexEntity> knowledgeRelateIndexList);

    List<String> getIndexListByKnowledgeId(String knowledgeId, String addType);

    ListResult<?> getPageList(KnowledgeRelateIndexReq knowledgeRelateIndexReq);

    Map<String, String> getSourceIndexList(String knowledgeId);

    Map<String, String> getSourceCardIndexTraceConfigList(String knowledgeId);

    List<KnowledgeRelateIndexEntity> listByKnowledgeId(List<String> knowledgeIdList);

    List<KnowledgeRelateIndexEntity> listDistanceInputParams(List<String> paramIdList);

    void removeDistanceRelateIndex(List<Integer> collect);

    void saveDistanceRelateIndex(List<KnowledgeRelateIndexEntity> relateIndexEntityList);
}
