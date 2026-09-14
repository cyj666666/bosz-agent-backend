package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.entity.KnowledgeRelateIndexVersionEntity;
import com.baomidou.mybatisplus.extension.service.IService;

import java.util.List;

/**
 * @Description: 知识库关联指标版本记录表
 * @Author: jeecg-boot
 * @Date:   2026-03-04
 * @Version: V1.0
 */
public interface IKnowledgeRelateIndexVersionService extends IService<KnowledgeRelateIndexVersionEntity> {

    void saveDistanceRelateIndexVersion(List<KnowledgeRelateIndexVersionEntity> backupList);
}
