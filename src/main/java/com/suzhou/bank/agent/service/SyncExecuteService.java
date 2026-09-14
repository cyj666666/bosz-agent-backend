package com.suzhou.bank.agent.service;


import com.suzhou.bank.agent.entity.KnowledgeQueryResultEntity;

import java.util.List;

public interface SyncExecuteService {

    void syncSaveKnowledgeLog(Boolean batchFlag, String traceId, String knowledgeCode, List<KnowledgeQueryResultEntity> logEntityList);
}
