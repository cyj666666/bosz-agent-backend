package com.suzhou.bank.agent.enums;

/**
 * 知识库同步状态
 * knowledge-知识库同步, index-指标同步, apiSource-API数据源同步, dataSource-SQL数据源, largeModelSource-大模型
 */
public enum SyncTypeEnum {

    KNOWLEDGE("knowledge", "知识库同步"),
    INDEX("index", "指标同步"),
    API_SOURCE("apiSource", "API数据源同步"),
    DATA_SOURCE("dataSource", "SQL数据源同步"),
    LARGE_MODEL_SOURCE("largeModelSource", "大模型同步");

    public final String id;
    public final String name;

    /***
     * 枚举赋值
     * @param id 枚举id
     * @param name 枚举name
     */
    SyncTypeEnum(String id, String name) {
        this.id = id;
        this.name = name;
    }

    /**
     * 通过id找枚举对象
     *
     * @param id 枚举id
     * @return 枚举对象
     */
    public static SyncTypeEnum getById(String id) {
        if (id == null) {
            return null;
        }
        for (SyncTypeEnum tt : SyncTypeEnum.values()) {
            if (tt.id.equals(id)) {
                return tt;
            }
        }
        return null;
    }
}
