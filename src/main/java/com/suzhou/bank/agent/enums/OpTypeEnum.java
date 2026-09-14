package com.suzhou.bank.agent.enums;

public enum OpTypeEnum {
    /**
     * 等于
     */
    EQ("="),
    /**
     * 不等于
     */
    NE("!="),
    /**
     * 小于等于
     */
    LTE("<="),
    /**
     * 小于
     */
    LT("<"),
    /**
     * 大于
     */
    GT(">"),
    /**
     * 大于等于
     */
    GTE(">="),
    /**
     * 为空
     */
    IS_NULL("is_null"),
    /**
     * 不为空
     */
    IS_NOT_NULL("is_not_null"),
    /**
     * 包含
     */
    CONTAINS("contains"),
    /**
     * 不包含
     */
    NOT_CONTAINS("not_contains"),
    /**
     * 长度等于
     */
    LEN_EQ("len_="),
    /**
     * 长度不等于
     */
    LEN_NE("len_!="),
    /**
     * 长度小于等于
     */
    LEN_LTE("len_<="),
    /**
     * 长度小于
     */
    LEN_LT("len_<"),
    /**
     * 长度大于
     */
    LEN_GT("len_>"),
    /**
     * 长度大于等于
     */
    LEN_GTE("len_>="),
    /**
     * 布尔为true
     */
    IS_TRUE("is_true"),
    /**
     * B布尔为false
     */
    IS_FALSE("is_false")
    ;


    private final String value;

    OpTypeEnum(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }
}
