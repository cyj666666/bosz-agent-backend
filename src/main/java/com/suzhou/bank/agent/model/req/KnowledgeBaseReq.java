package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;


@Data
@Tag(name="KnowledgeBaseReq对象", description="知识库版本查询对象")
public class KnowledgeBaseReq extends PageBaseParam {
    private static final long serialVersionUID = 1L;

    @Schema(description = "报告版本")
    private String reportVersion;

    @Schema(description = "版本号")
    private String versionNo;

    @Schema(description = "版本描述")
    private String label;

    @Schema(description = "所属模板流水号")
    private String modelNo;

    @Schema(description = "操作记录流水号")
    private String operateSerialNo;
}
