package com.suzhou.bank.agent.common;

import lombok.Data;

import java.util.Collections;
import java.util.List;

/**
 * agent 模块分页响应体
 *
 * <p>字段命名对齐 MyBatis-Plus 的 {@code Page}（{@code records/total/size/current}），
 * 前端 {@code src/agent/types} 里的 {@code AgentPageResult} 与之对应。</p>
 *
 * <p>注意：这与宿主既有的分页约定（{@code com.suzhou.bank.common} 下的分页结构）是两套，
 * agent 模块内部统一用本类，互不影响。</p>
 *
 * @param <T> 行数据类型
 */
@Data
public class AgentPageResult<T> {

    /** 当前页数据 */
    private List<T> records;

    /** 总记录数 */
    private long total;

    /** 每页条数 */
    private long size;

    /** 当前页码（从 1 开始） */
    private long current;

    public AgentPageResult() {
        this.records = Collections.emptyList();
    }

    public AgentPageResult(List<T> records, long total, long size, long current) {
        this.records = records == null ? Collections.emptyList() : records;
        this.total = total;
        this.size = size;
        this.current = current;
    }

    public static <T> AgentPageResult<T> empty(long size, long current) {
        return new AgentPageResult<>(Collections.emptyList(), 0L, size, current);
    }
}
