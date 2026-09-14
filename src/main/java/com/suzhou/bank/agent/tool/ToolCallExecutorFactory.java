package com.suzhou.bank.agent.tool;

import java.util.HashMap;
import java.util.Map;

public class ToolCallExecutorFactory {

    private static Map<String, ToolCallExecutor> TOOL_CALL_EXECUTOR_MAP = new HashMap<String, ToolCallExecutor>(){{
        put(ToolCallTypeEnum.CUSTOM.getType(), new CustomToolCallExecutor());
        put(ToolCallTypeEnum.KNOWLEDGE.getType(), new KnowledgeToolCallExecutor());
        put(ToolCallTypeEnum.APPLY_PROMPT.getType(), new KnowledgeToolCallExecutor());
        put(ToolCallTypeEnum.TEXTSPLIT.getType(), new TextSplitToolCallExecutor());
    }};

    public static ToolCallExecutor getToolCallExecutor(String type) {
        ToolCallExecutor toolCallExecutor = TOOL_CALL_EXECUTOR_MAP.get(type);
        if (toolCallExecutor == null) {
            throw new RuntimeException("工具类型：{" + type+"}无对应实现");
        }
        return toolCallExecutor;
    }

}
