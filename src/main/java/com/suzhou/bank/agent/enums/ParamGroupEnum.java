package com.suzhou.bank.agent.enums;


public enum ParamGroupEnum {

    Group("GROUP", "分组"),

    CHAR("CHAR", "字符"),

    NUMBER("NUMBER", "数值"),

    LIST("LIST", "列表"),

    OBJECT("OBJECT", "对象");

    public final String id;
    public final String name;

    /***
     * 枚举赋值
     * @param id 枚举id
     * @param name 枚举name
     */
    ParamGroupEnum(String id, String name) {
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
        return Group.id.equals(id) || CHAR.id.equals(id)
                || NUMBER.id.equals(id)
                || LIST.id.equals(id) || OBJECT.id.equals(id);
    }

    public static String getMessageByCode(String code) {
        ParamGroupEnum[] values = ParamGroupEnum.values();
        for (ParamGroupEnum lr : values) {
            if (code.contains(lr.id)) {
                return code.replace(lr.id, lr.name);
            }
        }
        return null;
    }
}
