package com.suzhou.bank.agent.model.req;


import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class PreviewJsExceptionReq {

    @Schema(description = "js表达式")
    private String jsExpression;
}
