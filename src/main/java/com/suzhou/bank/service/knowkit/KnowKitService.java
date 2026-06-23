package com.suzhou.bank.service.knowkit;

import com.suzhou.bank.entity.KnowKitTask;
import java.util.List;

public interface KnowKitService {
    /** 提交分析任务给 Know-Kit */
    KnowKitTask submitAnalysis(Long customerId, List<String> scenarioTags);

    /** 查询任务结果 */
    KnowKitTask getTaskResult(Long taskId);

    /** 重试失败任务 */
    KnowKitTask retryTask(Long taskId);
}
