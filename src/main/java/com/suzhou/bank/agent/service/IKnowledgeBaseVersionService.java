package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.entity.KnowledgeBaseParamsEntity;
import com.suzhou.bank.agent.entity.KnowledgeBaseVersionEntity;
import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.model.dto.KnowledgeBaseVersionDTO;

import java.util.List;

/**
 * @Description: 知识库版本记录表
 * @Author: jeecg-boot
 * @Date:   2025-11-06
 * @Version: V1.0
 */
public interface IKnowledgeBaseVersionService extends IService<KnowledgeBaseVersionEntity> {

    KnowledgeBaseVersionEntity getLatestVersion(String paramId);

    String publicVersion(KnowledgeBaseVersionDTO knowledgeBaseVersionDTO);

    void saveDistanceKnowledgeBaseVersion(List<KnowledgeBaseVersionEntity> backupKnowledgeBaseParamsList);

    void publicDistanceKnowledgeBaseVersion(List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList);
}
