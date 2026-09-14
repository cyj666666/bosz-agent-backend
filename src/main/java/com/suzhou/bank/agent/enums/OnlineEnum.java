package com.suzhou.bank.agent.enums;

public enum OnlineEnum {
    N("N", "未上线"), Y("Y", "已上线");


    OnlineEnum(String code, String message) {
        this.code = code;
        this.message = message;
    }

    private String code;
    private String message;

    public static String getMessageByCode(String code) {
        OnlineEnum[] values = OnlineEnum.values();
        for (OnlineEnum lr : values) {
            if (code.contains(lr.code)) {
                return code.replace(lr.code, lr.message);
            }
        }
        return null;
    }
}