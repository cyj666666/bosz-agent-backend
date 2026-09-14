package com.suzhou.bank.agent.enums;

public enum ParamTypeEnum {

    CHAR("CHAR", "字符"),

    NUMBER("NUMBER", "数值"),

    DATE("DATE", "数值"),

    LIST("LIST", "列表"),

    OBJECT("OBJECT", "对象");

    public final String id;
    public final String name;

    /***
     * 枚举赋值
     * @param id 枚举id
     * @param name 枚举name
     */
    private ParamTypeEnum(String id, String name){
        this.id = id;
        this.name = name;
    }

    /**
     * 判断当前输入的参数值是否是枚举的一个值
     * @param id 枚举id
     * @return 是否存在状态
     */
    public static boolean isExist(String id) {
        return CHAR.id.equals(id)
                || NUMBER.id.equals(id)
                  || LIST.id.equals(id)|| OBJECT.id.equals(id);
    }

    /**
     * 通过id找枚举对象
     * @param id 枚举id
     * @return 枚举对象
     */
    public static ParamTypeEnum getById(String id) {
        if(id == null) {
            return null;
        }
        for(ParamTypeEnum tt : ParamTypeEnum.values()) {
            if(tt.id.equals(id)) {
                return tt;
            }
        }
        return null;
    }
}
