package com.suzhou.bank.agent.tool;

import com.suzhou.bank.agent.entity.ToolManagementEntity;
import com.suzhou.bank.agent.model.req.ToolCallReq;

/**
 * 工具调用执行接口
 * @author dwyang
 * @since 2026/02/05
 */
public interface ToolCallExecutor {

    /**
     * 工具调用执行方法
     * @param toolCallReq 工具调用参数
     * @param toolManagementEntity 工具配置信息
     * @return 执行结果(支持流式和非流式)
     * @throws Exception 执行异常
     */
    Object execute(ToolCallReq toolCallReq, ToolManagementEntity toolManagementEntity) throws Exception;

}
