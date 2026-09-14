package com.suzhou.bank.agent.model.req;



import lombok.Data;

import javax.validation.constraints.NotBlank;

@Data
// @ApiModel(value = "外部接口结构查询对象", description = "CheckExtIntfManageRepeatReq")
public class CheckExtIntfManageRepeatReq {

    @NotBlank(message = "不可为空")

    private String supplierId;


    @NotBlank(message = "不可为空")
    private String intfNo;
}
