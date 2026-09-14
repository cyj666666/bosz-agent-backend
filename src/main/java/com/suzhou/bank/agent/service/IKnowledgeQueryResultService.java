package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.KnowledgeQueryResultEntity;

import java.util.List;

/**
 * @Description: 知识库查询记录表
 * @Author: jeecg-boot
 * @Date: 2024-11-06
 * @Version: V1.0
 */
public interface IKnowledgeQueryResultService extends IService<KnowledgeQueryResultEntity> {

    List<KnowledgeQueryResultEntity> getByTraceId(String traceId);

    void saveBatchLog(List<KnowledgeQueryResultEntity> logEntityList);
}
