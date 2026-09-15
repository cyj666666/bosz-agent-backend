package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

@Data
@Tag(name = "IndexParamQueryReq对象", description = "指标参数查询对象")
public class IndexParamQueryReq extends PageBaseParam {

    @Schema(description = "指标名称")
    private String paramName;

    @Schema(description = "指标编号")
    private String paramNo;

    @Schema(description = "父级指标编号")
    private String parentParamNo;

    @Schema(description = "模板编号")
    private String modelNo;

    @Schema(description = "指标编号")
    private String paramId;

    /**
     * 数据来源（模糊检索）
     *
     * <p>列表页「数据来源」列展示的是**运行时拼出来的字符串**（SQL 类：数据库编号/名称/涉及的表；
     * 接口类：服务编号/接口编号），不是数据库里的独立列。前端一直有这个检索框，但源工程的
     * {@code IndexParamQueryReq} 里没有该字段 → 参数被静默丢弃、检索框点了没反应
     * （2026-09-16 排查"检索功能失效"时定位）。</p>
     *
     * <p>本工程补上该字段，并在 SQL 上对「产出数据来源的原始列」做模糊匹配：
     * {@code script}（SQL 文本/数据源 JSON 全在里面）、{@code supplierId}、{@code intfNo}。
     * 这样搜表名、数据源代码、接口编号都能命中，与列上展示的内容方向一致。</p>
     */
    @Schema(description = "数据来源（模糊检索 script / supplierId / intfNo）")
    private String indexSource;
}
