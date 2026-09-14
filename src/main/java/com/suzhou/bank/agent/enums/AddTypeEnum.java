package com.suzhou.bank.agent.enums;

public enum AddTypeEnum {
    /**
     * 字符串
     */
    ADD("add"),
    /**
     * 数字
     */
    BLAND("bland");

    private final String value;

    AddTypeEnum(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }
}
