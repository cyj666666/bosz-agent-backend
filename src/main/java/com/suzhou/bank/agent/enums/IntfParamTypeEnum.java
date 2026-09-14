package com.suzhou.bank.agent.enums;

public enum IntfParamTypeEnum {

    CHAR("1", "string"),

    NUMBER("2", "number"),

    OBJECT("4", "object"),

    LIST("5", "array"),

    BOOLEAN("3", "boolean");

    public final String id;
    public final String name;

    /***
     * 枚举赋值
     * @param id 枚举id
     * @param name 枚举name
     */
    private IntfParamTypeEnum(String id, String name){
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
    public static IntfParamTypeEnum getById(String id) {
        if(id == null) {
            return null;
        }
        for(IntfParamTypeEnum tt : IntfParamTypeEnum.values()) {
            if(tt.id.equals(id)) {
                return tt;
            }
        }
        return null;
    }
}
