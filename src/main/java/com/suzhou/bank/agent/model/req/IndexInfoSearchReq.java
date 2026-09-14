package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.alibaba.fastjson.JSONObject;


import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

import java.util.List;

@Data
@Tag(name = "IndexInfoSearchReq", description = "指标信息查询")
public class IndexInfoSearchReq extends PageBaseParam {

    @Schema(description = "指标ID列表")
    private List<String> indexIdList;

    @Schema(description = "指标ID")
    private String indexId;

    @Schema(description = "请求参数")
    private JSONObject params;
}
