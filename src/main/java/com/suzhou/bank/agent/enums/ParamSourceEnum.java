package com.suzhou.bank.agent.enums;

/**
 * 指标参数来源枚举
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.agent.enums.ParamSourceEnum}，原样平移。</p>
 *
 * <p>用于标记一个指标（{@code index_params.param_source}）是从哪条链路创建出来的：
 * 数据源快速引入（{@link #TABLE}）、前台手工配置（{@link #BACK}）、XML 配置转化（{@link #XML}）、
 * 大模型指标转化（{@link #BIGDATA}）。</p>
 */
public enum ParamSourceEnum {

    XML("1", "XML配置转化"),
    BACK("2", "前台配置"),
    TABLE("3", "前端业务引入"),
    BIGDATA("4", "大模型指标转化");

    public final String id;
    public final String name;

    ParamSourceEnum(String id, String name) {
        this.id = id;
        this.name = name;
    }

    /** 判断传入的 id 是否是本枚举的合法值 */
    public static boolean isExist(String id) {
        return XML.id.equals(id)
                || BACK.id.equals(id)
                || TABLE.id.equals(id)
                || BIGDATA.id.equals(id);
    }

    /** 通过 id 找枚举对象 */
    public static ParamSourceEnum getById(String id) {
        if (id == null) {
            return null;
        }
        for (ParamSourceEnum tt : ParamSourceEnum.values()) {
            if (tt.id.equals(id)) {
                return tt;
            }
        }
        return null;
    }
}
