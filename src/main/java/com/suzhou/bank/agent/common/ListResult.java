package com.suzhou.bank.agent.common;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

/**
 * 列表/分页结果体
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.common.api.vo.ListResult}，
 * 字段与全部构造方法原样平移。</p>
 *
 * <p><b>本类与 {@link AgentPageResult} 的关系</b>：两者都是分页结构，但来源不同——</p>
 * <ul>
 *   <li>{@code ListResult}：源工程（JeecgBoot）的分页结构，字段为
 *       {@code totalCount / pageSize / pageIndex / columnList / list}。
 *       从源工程平移过来的 Service 方法签名大量使用它，<b>必须保留原样</b>，否则要改上百处调用。</li>
 *   <li>{@link AgentPageResult}：agent 模块新写代码用的分页结构，字段对齐 MyBatis-Plus 的
 *       {@code Page}（{@code records / total / size / current}）。</li>
 * </ul>
 *
 * <p>两者并存是刻意的折中：强行统一会让平移过来的代码大面积改写，反而放大出错风险。
 * 前端需要按返回的具体结构分别解析——这是迁移的已知成本，已在前端接口层集中处理。</p>
 */
@Data
public class ListResult<T> {

    /** 总记录数 */
    private int totalCount;

    /** 每页最大记录数 */
    private int pageSize;

    /** 页码 */
    private int pageIndex;

    /** 列名 */
    private List<String> columnList;

    /** 返回的当前页的实际记录数 */
    private List<T> list;

    public ListResult(List<T> rows) {
        this(rows != null ? rows.size() : 0, rows);
    }

    public ListResult(Integer totalCount, List<T> rows) {
        this.totalCount = totalCount;
        this.list = rows;
    }

    public ListResult(int totalCount, int pageSize) {
        this.totalCount = totalCount;
        this.pageSize = pageSize;
        this.list = new ArrayList<>(0);
    }

    public ListResult(int totalCount, int pageSize, List list) {
        this.totalCount = totalCount;
        this.pageSize = pageSize;
        this.list = list;
    }

    public ListResult(int totalCount, int pageSize, List list, List<String> columnList) {
        this.totalCount = totalCount;
        this.pageSize = pageSize;
        this.list = list;
        this.columnList = columnList;
    }

    public ListResult(int totalCount, int pageSize, int pageIndex, List list) {
        this.totalCount = totalCount;
        this.pageSize = pageSize;
        this.pageIndex = pageIndex;
        this.list = list;
    }

    public ListResult(int totalCount, int pageSize, int pageIndex, List list, List<String> columnList) {
        this.totalCount = totalCount;
        this.pageSize = pageSize;
        this.pageIndex = pageIndex;
        this.list = list;
        this.columnList = columnList;
    }
}
