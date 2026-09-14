package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Getter;
import lombok.Setter;
import com.suzhou.bank.agent.model.common.PageBaseParam;

@Getter
@Setter
@Tag(name="KnowledgeBaseVersionReq对象", description="知识库版本记录表请求参数")
public class KnowledgeBaseVersionReq extends PageBaseParam {

    @Schema(description = "版本号")
    String versionNo;

    @Schema(description = "版本名称")
    String versionName;

    @Schema(description = "知识库ID")
    String paramId;
}
