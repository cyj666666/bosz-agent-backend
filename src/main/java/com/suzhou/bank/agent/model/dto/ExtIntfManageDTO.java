package com.suzhou.bank.agent.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.io.Serializable;

@Data
public class ExtIntfManageDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private String id;

    @Schema(description = "服务编号")
    private String supplierId;

    @Schema(description = "服务名称")
    private String supplierName;

    @Schema(description = "接口编号")
    private String intfNo;

    @Schema(description = "接口名称")
    private String intfName;

    @Schema(description = "接口请求地址")
    private String intfPath;

    @Schema(description = "接入形式")
    private String intfTypeName;

    @Schema(description = "请求方式")
    private String intfRequestType;

    @Schema(description = "请求超时时间，单位为秒")
    private Integer intfTimeOut;

    @Schema(description = "接口状态 0 无效 1 有效")
    private String intfStatus;

    @Schema(description = "接口描述")
    private String intfDesc;

    @Schema(description = "接口结构")
    private String intfStructure;

    @Schema(description = "依赖接口编号")
    private String referIntfNo;

    @Schema(description = "依赖接口状态 0 无效 1 有效")
    private String referIntfStatus;

    @Schema(description = "是否异步存储 0 否 1是")
    private String asyncSave;

    @Schema(description = "是否为挡板数据 0 否 1是")
    private String battleFlag;

    @Schema(description = "挡板报文")
    private String battleReportContent;

    @Schema(description = "输出报文处理-加密/转码")
    private String beforeHandler;
}
