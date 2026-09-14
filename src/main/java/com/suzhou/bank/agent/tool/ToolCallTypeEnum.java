package com.suzhou.bank.agent.tool;

import lombok.Getter;


@Getter
public enum ToolCallTypeEnum {

    //基于python脚本的自定义工具调用
    CUSTOM("custom"),
    //基于知识库配置的工具调用
    KNOWLEDGE("get_knowledge"),
    //文案提示词工具调用
    APPLY_PROMPT("apply_prompt"),
    // 基于文本拆分配置的工具调用
    TEXTSPLIT("text_split");

    ToolCallTypeEnum(String type) {
        this.type = type;
    }

    public static boolean checkType(String type) {
        for (ToolCallTypeEnum toolCallType : ToolCallTypeEnum.values()) {
            if (toolCallType.getType().equals(type)) {
                return true;
            }
        }
        return false;
    }

    private final String type;

}
