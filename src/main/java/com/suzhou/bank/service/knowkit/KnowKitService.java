package com.suzhou.bank.service.knowkit;

import com.suzhou.bank.entity.KnowKitTask;
import java.util.List;

/**
 * Know-Kit 智能体适配服务接口
 * <p>负责组装客户数据 + 匹配规则，调用 Know-Kit API 进行分析，
 * 并记录每次请求/响应用于审计和追溯。适配层不包含业务逻辑，
 * 仅为数据搬运和格式转换。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
public interface KnowKitService {

    /**
     * 提交分析任务给 Know-Kit
     * <p>查询客户指标和文本数据，按标签匹配风险规则，
     * 组装为 Know-Kit 要求的 JSON 格式并提交。</p>
     *
     * @param customerId   客户ID
     * @param scenarioTags 场景标签列表（用于匹配适用规则）
     * @return 分析任务记录
     */
    KnowKitTask submitAnalysis(Long customerId, List<String> scenarioTags);

    /**
     * 查询任务结果
     *
     * @param taskId 任务ID
     * @return 任务详情（含状态、请求和响应JSON）
     */
    KnowKitTask getTaskResult(Long taskId);

    /**
     * 重试失败任务
     * <p>将任务状态重置为 PENDING 以便重新执行。</p>
     *
     * @param taskId 任务ID
     * @return 更新后的任务记录
     */
    KnowKitTask retryTask(Long taskId);
}
