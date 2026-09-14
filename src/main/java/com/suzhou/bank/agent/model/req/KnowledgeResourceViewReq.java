package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.alibaba.fastjson.JSONObject;


import lombok.Data;

import java.util.List;

@Data
@Tag(name = "KnowledgeResourceViewReq", description = "分组下知识库溯源配置预览")
public class KnowledgeResourceViewReq {

    @Schema(description = "知识库ID")
    private String paramId;

    @Schema(description = "溯源内容")
    private List<JSONObject> resourceContent;

    @Schema(description = "参数")
    private JSONObject params;
}
