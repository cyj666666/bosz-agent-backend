package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;


@Data
@TableName("trace_query_result")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "trace_query_result对象", description = "溯源查询结果表")
public class TraceQueryResultEntity {

    /**
     * id
     */
    @TableId(type = IdType.AUTO)
    @Schema(description = "id")
    private Integer id;
    /**
     * 追踪ID
     */
    @Schema(description = "追踪ID")
    private String traceId;
    /**
     * 关联知识库编码
     */
    @Schema(description = "关联知识库编码")
    private String knowledgeCode;
    /**
     * 请求状态; Y成功 ; N失败
     */
    @Schema(description = "请求状态; Y成功 ; N失败")
    private String queryStatus;
    /**
     * 溯源请求结果
     */
    @Schema(description = "请求结果")
    private String queryResult;
    /**
     * 图片请求结果
     */
    @Schema(description = "图片请求结果")
    private String imageQueryResult;

    /**
     * 全部来源请求结果
     */
    @Schema(description = "全部来源请求结果")
    private String wholeSourceQueryResult;
    /**
     * APP的page页面请求结果
     */
    @Schema(description = "APP的page页面请求结果")
    private String appSourceQueryResult;
    /**
     * 请求时间
     */
    @Schema(description = "请求时间")
    private String queryTime;
    /**
     * 花费时间;请求总耗时，单位毫秒
     */
    @Schema(description = "花费时间;请求总耗时，单位毫秒")
    private Integer costTime;
    /**
     * 图片花费时间;请求总耗时，单位毫秒
     */
    @Schema(description = "花费时间;请求总耗时，单位毫秒")
    private Integer imageCostTime;
    /**
     * 图片花费时间;请求总耗时，单位毫秒
     */
    @Schema(description = "花费时间;请求总耗时，单位毫秒")
    private Integer wholeSourceCostTime;
    /**
     * 备注
     */
    @Schema(description = "备注")
    private String comment;
}
