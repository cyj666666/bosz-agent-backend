package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.entity.KnowledgeSyncTaskExceptionRecordEntity;
import com.suzhou.bank.agent.model.req.KnowledgeSyncTaskReq;

import java.util.List;

public interface IKnowledgeSyncService {

    void syncKnowledge(List<String> knowledgeIdList, String taskId);

    void syncIndex(List<String> syncIdList, String taskId);

    void syncApiSource(List<String> syncIdList, String taskId);

    void syncDataSource(List<String> syncIdList, String taskId);

    String saveSyncTask(String syncType, String syncStatus);

    void updateSyncStatus(String taskId, String syncStatus, long startTime);

    ListResult<?> getSyncTaskList(KnowledgeSyncTaskReq req);

    List<KnowledgeSyncTaskExceptionRecordEntity> getSyncTaskDetail(String taskId);

    void syncLargeModelSource(List<String> syncIdList, String taskId);

    boolean checkSyncException(String taskId);
}
