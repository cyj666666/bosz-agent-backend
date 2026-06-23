package com.suzhou.bank.controller;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.KnowKitTask;
import com.suzhou.bank.service.knowkit.KnowKitService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

/**
 * Know-Kit 智能体适配接口
 * <p>对接第三方 Know-Kit 智能体产品，负责提交分析任务、查询结果和重试。
 * 本层为适配层，不包含业务逻辑，仅做数据组装和格式转换。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@RestController
@RequestMapping("/api/know-kit")
@RequiredArgsConstructor
public class KnowKitController {
    private final KnowKitService service;

    /**
     * 提交分析任务
     * <p>组装客户指标数据、文本数据和匹配到的风险判定规则，
     * 提交给 Know-Kit 智能体进行分析。</p>
     *
     * @param customerId   客户ID
     * @param scenarioTags 场景标签列表（用于匹配适用的风险规则）
     * @return 分析任务记录
     */
    @PostMapping("/analyze")
    public Result<KnowKitTask> submitAnalysis(@RequestParam Long customerId, @RequestBody List<String> scenarioTags) { return Result.ok(service.submitAnalysis(customerId, scenarioTags)); }

    /**
     * 查询任务结果
     *
     * @param taskId 任务ID
     * @return 任务详情（含状态、请求JSON、响应JSON）
     */
    @GetMapping("/task/{taskId}")
    public Result<KnowKitTask> getTask(@PathVariable Long taskId) { return Result.ok(service.getTaskResult(taskId)); }

    /**
     * 重试失败任务
     * <p>将失败任务重置为 PENDING 状态以便重新执行。</p>
     *
     * @param taskId 任务ID
     * @return 更新后的任务记录
     */
    @PostMapping("/task/{taskId}/retry")
    public Result<KnowKitTask> retryTask(@PathVariable Long taskId) { return Result.ok(service.retryTask(taskId)); }
}
