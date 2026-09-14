package com.suzhou.bank.agent.service.impl;

import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import com.suzhou.bank.agent.entity.KnowledgeQueryResultEntity;
import com.suzhou.bank.agent.service.IKnowledgeQueryResultService;
import com.suzhou.bank.agent.service.SyncExecuteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@Slf4j
public class SyncExecuteServiceImpl implements SyncExecuteService {

    @Autowired
    private IKnowledgeQueryResultService knowledgeQueryResultService;

    @Async
    @Override
    public void syncSaveKnowledgeLog(Boolean batchFlag, String traceId, String moduleCode, List<KnowledgeQueryResultEntity> logEntityList) {
        try {
            // 过滤掉列表中的空元素，如果过滤后列表为空则直接返回
            if (CollectionUtils.isEmpty(logEntityList = logEntityList.stream().filter(Objects::nonNull).collect(Collectors.toList()))) {
                return;
            }
            // 跑批日志记录+通用日志记录
            if (Objects.isNull(batchFlag) || !batchFlag) {
                knowledgeQueryResultService.saveBatchLog(logEntityList);
            }
        } catch (Exception e) {
            log.error("保存知识库{}查询日志信息异常，TraceId为[{}]异常信息：{}", moduleCode, traceId, ExceptionUtils.getStackTrace(e));
        }
    }
}
