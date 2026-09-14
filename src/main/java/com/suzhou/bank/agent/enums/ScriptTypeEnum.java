package com.suzhou.bank.agent.enums;

public enum ScriptTypeEnum {

    SQL("Sql", "数据库"),

    JAVA("Java", "Java方法"),

    PARAM_SET("ParamSet", "参数集"),

    API("Api", "接口调用"),

    KNOWLEDGE_CODE("KnowledgeCode", "大模型知识库code");

    public final String id;
    public final String name;

    /***
     * 枚举赋值
     * @param id 枚举id
     * @param name 枚举name
     */
    ScriptTypeEnum(String id, String name) {
        this.id = id;
        this.name = name;
    }

    /**
     * 判断当前输入的参数值是否是枚举的一个值
     *
     * @param id 枚举id
     * @return 是否存在状态
     */
    public static boolean isExist(String id) {
        return SQL.id.equals(id) || JAVA.id.equals(id) || API.id.equals(id);
    }

    /**
     * 通过id找枚举对象
     *
     * @param id 枚举id
     * @return 枚举对象
     */
    public static ScriptTypeEnum getById(String id) {
        if (id == null) {
            return null;
        }
        for (ScriptTypeEnum tt : ScriptTypeEnum.values()) {
            if (tt.id.equals(id)) {
                return tt;
            }
        }
        return null;
    }
}
