package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.entity.ExtIntfParamDefineEntity;
import com.suzhou.bank.agent.model.req.*;

import java.util.List;


public interface ExtIntfParamDefineService extends IService<ExtIntfParamDefineEntity> {

    ListResult<?> queryExtIntfParamDefine(ExtIntfParamDefineListReq reqMsg);

    boolean checkParamDefineRepeat(CheckExtIntfParamDefineRepeatReq reqMsg);

    boolean handleExtIntfParamDefine(ExtIntfParamDefineReq req);

    boolean removeExtIntfParamDefine(RemoveExtIntfReq req);

    List<ExtIntfParamDefineEntity> queryExtIntfParamDefine(List<String> supplierIdList);

    void saveDistanceExtIntfParamDefine(List<ExtIntfParamDefineEntity> defineEntityList);
}
