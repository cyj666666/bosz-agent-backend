package com.suzhou.bank.agent.model.req;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import com.suzhou.bank.agent.model.common.PageBaseParam;

@Tag(name = "知识库同步任务请求参数")
@Data
public class KnowledgeSyncTaskReq extends PageBaseParam {

    @Schema(description = "任务ID")
    private String taskId;

    @Schema(description = "同步类型")
    private String syncType;

    @Schema(description = "同步状态")
    private String syncStatus;

    @Schema(description = "开始时间开始")
    private String startTimeBegin;

    @Schema(description = "开始时间结束")
    private String startTimeEnd;

}
