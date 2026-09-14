package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.alibaba.fastjson.JSONArray;


import lombok.Data;

import javax.validation.constraints.NotBlank;

@Data
@Tag(name = "KnowledgeResultCheckReq对象", description = "知识库结果校验请求")
public class KnowledgeResultCheckReq {

    @Schema(description = "知识库ID")
    private String paramId;

    @Schema(description = "企业名称")
    private String entName;

    @Schema(description = "主体类型 ")
    private String mainType;

    @Schema(description = "大模型选择")
    private String largeModelCode;

    @Schema(description = "大模型参数")
    private String largeModelParam;

    @NotBlank
    @Schema(description = "prompt文案")
    private String prompt;

    
    private String outPutContent;

    @Schema(description = "输入参数")
    private JSONArray inputParam;
}
