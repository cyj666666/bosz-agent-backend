package com.suzhou.bank.agent.core;

import lombok.Getter;
import lombok.Setter;

/**
 * 指标参数的基础结构
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.agent.core.BaseParam}，原样平移。</p>
 */
@Getter
@Setter
public class BaseParam {

    /** 指标编号 */
    private String paramNo;

    /** 指标主键 */
    private String paramId;

    /** 指标名称 */
    private String paramName;

    /** 指标类型 */
    private String paramType;

    /** 取数脚本类型（Sql / Api ...），决定由哪个 {@link DataSetBuilder} 处理 */
    private String scriptType;

    /** 取数脚本内容 */
    private String script;
}
