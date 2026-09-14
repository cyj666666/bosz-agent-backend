package com.suzhou.bank.agent.model.req;

import lombok.Data;

import javax.validation.Valid;
import javax.validation.constraints.NotEmpty;
import java.io.Serializable;
import java.util.List;

@Data
public class AddExtIntfParamDefineReq implements Serializable {

    private static final long serialVersionUID = 1L;

    @NotEmpty
    private List<ExtIntfParamDefineReq> paramDefineList;
}
