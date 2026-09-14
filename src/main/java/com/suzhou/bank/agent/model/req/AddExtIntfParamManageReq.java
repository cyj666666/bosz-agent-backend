package com.suzhou.bank.agent.model.req;

import lombok.Data;

import javax.validation.Valid;
import javax.validation.constraints.NotEmpty;
import java.util.List;

@Data
public class AddExtIntfParamManageReq {

    @NotEmpty
    private List<ExtIntfParamManageReq> paramManageList;
}
