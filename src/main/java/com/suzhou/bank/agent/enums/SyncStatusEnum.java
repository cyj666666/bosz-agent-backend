package com.suzhou.bank.agent.enums;

/**
 * 知识库同步状态
 * new-新建任务；processing-同步中；success-同步成功；failed-同步失败；
 */
public enum SyncStatusEnum {

    NEW("new", "新建任务"),
    PROCESSING("processing", "同步中"),
    SUCCESS("success", "同步成功"),
    FAILED("failed", "同步失败");

    public final String id;
    public final String name;

    /***
     * 枚举赋值
     * @param id 枚举id
     * @param name 枚举name
     */
    SyncStatusEnum(String id, String name) {
        this.id = id;
        this.name = name;
    }

    /**
     * 通过id找枚举对象
     *
     * @param id 枚举id
     * @return 枚举对象
     */
    public static SyncStatusEnum getById(String id) {
        if (id == null) {
            return null;
        }
        for (SyncStatusEnum tt : SyncStatusEnum.values()) {
            if (tt.id.equals(id)) {
                return tt;
            }
        }
        return null;
    }
}
