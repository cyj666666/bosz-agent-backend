package com.suzhou.bank.agent.enums;

/**
 * 知识库同步异常阶段
 */
public enum ExcepitonStageEnum {

    INIT("init", "数据查询阶段"),
    KNOWLEDGE("knowledge", "同步知识库配置阶段"),
    LARGE_MODEL_SOURCE("large_model_source", "同步大模型阶段"),
    KNOWLEDGE_RELATE_INDEX("knowledge_relate_index", "同步知识库溯源阶段"),
    KNOWLEDGE_BLACK_PARAMS("knowledge_black_params", "同步知识库黑盒参数阶段"),
    KNOWLEDGE_INPUT_PARAM("knowledge_input_param", "同步知识库参数集阶段"),
    KNOWLEDGE_GROUP("knowledge_group", "同步知识库分组阶段"),
    INDEX("index", "同步指标配置阶段"),
    INDEX_GROUP("index_group", "同步指标分组阶段"),
    SOURCE("source", "同步数据源阶段");

    public final String id;
    public final String name;

    /***
     * 枚举赋值
     * @param id 枚举id
     * @param name 枚举name
     */
    ExcepitonStageEnum(String id, String name) {
        this.id = id;
        this.name = name;
    }

    /**
     * 通过id找枚举对象
     *
     * @param id 枚举id
     * @return 枚举对象
     */
    public static ExcepitonStageEnum getById(String id) {
        if (id == null) {
            return null;
        }
        for (ExcepitonStageEnum tt : ExcepitonStageEnum.values()) {
            if (tt.id.equals(id)) {
                return tt;
            }
        }
        return null;
    }
}
