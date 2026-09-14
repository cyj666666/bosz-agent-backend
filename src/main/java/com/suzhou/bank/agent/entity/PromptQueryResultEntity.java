package com.suzhou.bank.agent.entity;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;


import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;


@Data
@TableName("prompt_query_result")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="prompt_query_result对象", description = "prompt请求结果记录表")
public class PromptQueryResultEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    @Schema(description = "请求参数")
    private String queryParam;

    @Schema(description = "结果类型;agent：命中agent平台取值方式；prompt：命中prompt平台取值方式")
    private String resultMode;

    @Schema(description = "请求状态;1 成功 ; 0 失败")
    private String queryStatus;

    @Schema(description = "花费时间;请求总耗时，单位秒")
    private Integer costTime;

    @Schema(description = "请求结果")
    private String queryResult;

    @Schema(description = "请求时间")
    private String queryTime;

    @Schema(description = "请求结束时间")
    private String endTime;

    @Schema(description = "备注")
    private String comment;

    @Schema(description = "跟踪ID")
    private String traceId;

    @Schema(description = "模块编码")
    private String moduleCode;

    @Schema(description = "模块名称")
    private String moduleName;

    @Schema(description = "主体名称")
    private String entName;

    @Schema(description = "是否多主体 1是 0否")
    private String isMutiEnt;

    @Schema(description = "失败原因")
    private String failReason;
}
