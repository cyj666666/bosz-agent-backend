package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

@Data
@Tag(name = "IndexParamQueryReq对象", description = "指标参数查询对象")
public class IndexParamQueryReq extends PageBaseParam {

    @Schema(description = "指标名称")
    private String paramName;

    @Schema(description = "指标编号")
    private String paramNo;

    @Schema(description = "父级指标编号")
    private String parentParamNo;

    @Schema(description = "模板编号")
    private String modelNo;

    @Schema(description = "指标编号")
    private String paramId;
}
