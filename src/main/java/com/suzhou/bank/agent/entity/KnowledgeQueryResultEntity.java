package com.suzhou.bank.agent.entity;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;


import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * @Description: 知识库查询记录表
 * @Author: jeecg-boot
 * @Date: 2024-11-06
 * @Version: V1.0
 */
@Data
@TableName("knowledge_query_result")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="knowledge_query_result对象", description = "知识库查询记录表")
public class KnowledgeQueryResultEntity {

    /**
     * id
     */
    @TableId(type = IdType.ASSIGN_ID)
    private String id;
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
     * 服务编号
     */
    @Schema(description = "服务编号")
    private String supplierId;
    /**
     * 接口编号
     */
    @Schema(description = "接口编号")
    private String intfNo;
    /**
     * 接口请求参数
     */
    @Schema(description = "接口请求参数")
    private String intfParam;
    /**
     * sql脚本
     */
    @Schema(description = "sql脚本")
    private String scriptSql;
    /**
     * sql脚本关联参数
     */
    @Schema(description = "sql脚本关联参数")
    private String sqlParam;
    /**
     * 请求状态;1 成功 ; 0 失败
     */
    @Schema(description = "请求状态;1 成功 ; 0 失败")
    private String queryStatus;
    /**
     * 查询类型 1接口 2数据源
     */
    @Schema(description = "查询类型 1接口 2数据源")
    private Integer queryType;
    /**
     * 请求结果
     */
    @Schema(description = "请求结果")
    private String queryResult;
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
     * 备注
     */
    @Schema(description = "备注")
    private String comment;
}
