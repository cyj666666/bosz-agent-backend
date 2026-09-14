package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.entity.KnowledgeBlackParamsConfigEntity;
import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.KnowledgeRelateInputParamEntity;

import java.util.List;

/**
 * @Description: 知识库黑盒参数配置表
 * @Author: jeecg-boot
 * @Date:   2025-02-20
 * @Version: V1.0
 */
public interface IKnowledgeBlackParamsConfigEntityService extends IService<KnowledgeBlackParamsConfigEntity> {

    List<KnowledgeBlackParamsConfigEntity> getListByKnowledgeId(String knowledgeId);

    List<KnowledgeBlackParamsConfigEntity> listByKnowledgeId(List<String> paramIdList);

    List<KnowledgeBlackParamsConfigEntity> listDistanceInputParams(List<String> paramIdList);

    void removeDistanceBlackParamsConfig(List<Integer> idList);

    void saveDistanceBlackParamsConfig(List<KnowledgeBlackParamsConfigEntity> blackParamsConfigEntityList);
}
