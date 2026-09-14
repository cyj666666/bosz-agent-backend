package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.KnowledgeRelateInputParamEntity;

import java.util.List;

/**
 * @Description: 知识库管理数据集
 * @Author: jeecg-boot
 * @Date:   2025-12-02
 * @Version: V1.0
 */
public interface IKnowledgeRelateInputParamService extends IService<KnowledgeRelateInputParamEntity> {

    List<KnowledgeRelateInputParamEntity> listByKnowledgeId(List<String> knowledgeIdList);

    List<KnowledgeRelateInputParamEntity> listDistanceInputParams(List<String> knowledgeIdList);

    void removeDistanceInputParams(List<String> idList);

    void saveDistanceInputParams(List<KnowledgeRelateInputParamEntity> inputParamList);
}
