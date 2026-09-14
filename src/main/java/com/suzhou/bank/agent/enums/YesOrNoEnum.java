package com.suzhou.bank.agent.enums;

/**
 * 是否枚举
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.agent.enums.YesOrNoEnum}，原样平移。</p>
 *
 * <p><b>注意</b>：分类字典（{@code sys_category.param_status}）的取值判断用的是
 * {@code YesOrNoEnum.Y.name()}，即<b>枚举常量名 "Y"</b>，而不是 {@code code}（"1"）。
 * 改这里会让分类树的查询条件与库里数据对不上。</p>
 */
public enum YesOrNoEnum {
    N("0", "NO"), Y("1", "YES");

    YesOrNoEnum(String code, String message) {
        this.code = code;
        this.message = message;
    }

    public final String code;
    public final String message;

    public static String getMessageByCode(String code) {
        YesOrNoEnum[] values = YesOrNoEnum.values();
        for (YesOrNoEnum lr : values) {
            if (code.contains(lr.code)) {
                return code.replace(lr.code, lr.message);
            }
        }
        return null;
    }
}
