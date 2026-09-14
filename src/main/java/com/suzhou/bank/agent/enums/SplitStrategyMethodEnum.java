package com.suzhou.bank.agent.enums;

/**
 * 拆分策略方法枚举
 */
public enum SplitStrategyMethodEnum {

    BY_NUMBER_AND_SEARCH("api_divide_by_number_and_search", "按文档层级分段分割文档和自动分段默认"),
    BY_SYMBOL_AND_SEARCH("api_divide_by_symbol_and_search", "按照给定的符号分割文本"),
    BY_FIXED_SIZE_AND_SEARCH("api_divide_by_fixed_size_and_search", "按照固定大小分块分割文档");


    SplitStrategyMethodEnum(String code, String message) {
        this.code = code;
        this.message = message;
    }

    public final String code;
    public final String message;

    public static String getMessageByCode(String code) {
        SplitStrategyMethodEnum[] values = SplitStrategyMethodEnum.values();
        for (SplitStrategyMethodEnum lr : values) {
            if (code.contains(lr.code)) {
                return code.replace(lr.code, lr.message);
            }
        }
        return null;
    }
}
