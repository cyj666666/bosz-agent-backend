package com.suzhou.bank.agent.enums;

public enum KnowledgeTypeEnum {

    APPLY_PROMPT("apply_prompt", "应用提示词"),
    GET_KNOWLEDGE("get_knowledge", "知识库"),
    CUSTOM("custom", "用户自定义代码工具");

    public final String id;
    public final String name;

    KnowledgeTypeEnum(String id, String name) {
        this.id = id;
        this.name = name;
    }

    public static KnowledgeTypeEnum getById(String id) {
        if (id == null) {
            return null;
        }
        for (KnowledgeTypeEnum tt : KnowledgeTypeEnum.values()) {
            if (tt.id.equals(id)) {
                return tt;
            }
        }
        return null;
    }
}
