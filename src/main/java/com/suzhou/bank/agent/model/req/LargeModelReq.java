package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

@Data
@Tag(name = "大模型配置列表查询对象", description = "LargeModelReq")
public class LargeModelReq extends PageBaseParam {

    @Schema(description = "大模型名称")
    private String lmName;

    @Schema(description = "大模型编码")
    private String lmCode;

    @Schema(description = "模型")
    private String model;
}
