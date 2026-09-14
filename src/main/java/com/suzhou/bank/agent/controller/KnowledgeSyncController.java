package com.suzhou.bank.agent.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.enums.SyncStatusEnum;
import com.suzhou.bank.agent.enums.SyncTypeEnum;
import com.suzhou.bank.agent.model.req.KnowledgeSyncReq;
import com.suzhou.bank.agent.model.req.KnowledgeSyncTaskReq;
import com.suzhou.bank.agent.service.IKnowledgeSyncService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@Slf4j
@Tag(name = "知识库同步接口")
// 迁移改造点：路径加 /api/agent 前缀（源工程为 "/knowledge/sync"）。
// 两个原因：① 宿主 AuthInterceptor 只拦 /api/**，不加前缀则完全无鉴权；
//           ② 前端 agent 模块的 axios baseURL 统一为 /api/agent（源工程为 /jeecg-boot）。
    @RequestMapping("/api/agent/knowledge/sync")
@RequiredArgsConstructor
public class KnowledgeSyncController {

    private final IKnowledgeSyncService knowledgeSyncService;

    @Operation(summary = "查询知识库同步任务列表", description = "根据同步类型查询不同的同步任务列表")
    @PostMapping("/get/list")
    public AgentResult<?> getSyncTaskList(@RequestBody KnowledgeSyncTaskReq syncTaskReq) {
        return AgentResult.OK(knowledgeSyncService.getSyncTaskList(syncTaskReq));
    }

    @Operation(summary = "查询知识库同步任务详情", description = "根据任务ID查询同步任务详情")
    @PostMapping("/get/detail")
    public AgentResult<?> getSyncTaskDetail(@RequestBody KnowledgeSyncTaskReq syncTaskReq) {
        return AgentResult.OK(knowledgeSyncService.getSyncTaskDetail(syncTaskReq.getTaskId()));
    }

    @Operation(summary = "执行知识库相关同步", description = "根据同步类型执行不同的同步操作")
    @PostMapping("/execute")
    public AgentResult<?> executeSync(@RequestBody @Valid KnowledgeSyncReq request) {
        String syncType = request.getSyncType();
        List<String> syncIdList = request.getSyncIdList();
        String syncTypeDesc = SyncTypeEnum.getById(syncType).name;

        log.info("开始执行{}类型的同步操作", syncTypeDesc);

        // 创建任务记录
        String taskId = knowledgeSyncService.saveSyncTask(syncType, SyncStatusEnum.NEW.id);

        // 迁移改造点：源实现用的是 Java 17 的 switch 表达式（case "x" -> { ... yield ...; }），
        // 本工程是 Java 8，降级为等价的 switch 语句；非法类型返回 error 而不抛异常的语义保持不变。
        switch (syncType) {
            case "knowledge":
                knowledgeSyncService.syncKnowledge(syncIdList, taskId);
                return AgentResult.OK("知识库同步成功！");
            case "index":
                knowledgeSyncService.syncIndex(syncIdList, taskId);
                return AgentResult.OK("指标同步成功！");
            case "apiSource":
                knowledgeSyncService.syncApiSource(syncIdList, taskId);
                return AgentResult.OK("API数据源同步成功！");
            case "dataSource":
                knowledgeSyncService.syncDataSource(syncIdList, taskId);
                return AgentResult.OK("SQL数据源同步成功！");
            case "largeModelSource":
                knowledgeSyncService.syncLargeModelSource(syncIdList, taskId);
                return AgentResult.OK("大模型同步成功！");
            default:
                return AgentResult.error("同步类型错误！");
        }
    }
}
