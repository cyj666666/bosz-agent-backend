package com.suzhou.bank.agent.core;

import com.alibaba.fastjson.JSONArray;
import lombok.Data;

/**
 * SQL 取数脚本结构（{@code index_params.script} 里 scriptType=Sql 时的 JSON 结构）
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.agent.core.SqlScript}，原样平移。</p>
 */
@Data
public class SqlScript {

    /** 数据源编码（{@code sys_data_source.code}） */
    private String dataSource;

    /** SQL 语句，支持 {@code :paramName} 形式的命名参数与 {@code {{paramNo}} 模板占位 */
    private String sql;

    /** 参数定义（name / defaultValue / relateIndex 等） */
    private JSONArray paramData;
}
