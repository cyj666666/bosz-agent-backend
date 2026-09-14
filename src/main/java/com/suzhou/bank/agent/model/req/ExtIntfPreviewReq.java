package com.suzhou.bank.agent.model.req;

import com.alibaba.fastjson.JSONObject;


import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

import javax.validation.constraints.NotBlank;
import java.util.Map;

@Data
// @ApiModel(value = "外部接口预览请求对象", description = "ExtIntfPreviewReq")
public class ExtIntfPreviewReq extends PageBaseParam {


    @NotBlank(message = "不可为空")
    private String supplierId;


    @NotBlank(message = "不可为空")
    private String intfNo;


    private String paramJsonStr;


    private JSONObject paramData;
}
