package com.suzhou.bank.agent.enums;

public enum DataTypeEnum {
    /**
     * 字符串
     */
    STRING("string"),
    /**
     * 数字
     */
    NUMBER("number"),
    /**
     * 日期
     */
    DATE("date"),
    /**
     * 数组
     */
    OBJECT("object"),
    /**
     * 数组
     */
    ARRAY("array"),
    /**
     * 布尔
     */
    BOOLEAN("boolean");

    private final String value;

    DataTypeEnum(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }
}
