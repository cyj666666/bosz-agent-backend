package com.suzhou.bank.agent.model.req;

import com.alibaba.fastjson.JSONObject;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ToolCallReq {

    private String jsonrpc = "2.0";

    @NotEmpty
    private String method;

    @NotNull
    private JSONObject params;

    //请求id，可选
    private String id;

    //是否流式返回结果，默认为false
    private boolean stream = false;

    //是否进行模型总结摘要，默认为false
    private boolean withModelSummary = false;

}
