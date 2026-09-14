package com.suzhou.bank.agent.service;


import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.entity.ExtIntfSupplierEntity;
import com.suzhou.bank.agent.model.req.AddExtIntfSupplierReq;
import com.suzhou.bank.agent.model.req.CheckExtIntfSupplierRepeatReq;
import com.suzhou.bank.agent.model.req.ExtIntfSupplierListReq;
import com.suzhou.bank.agent.model.req.RemoveExtIntfSupplierReq;

import java.util.List;

public interface ExtIntfSupplierManageService extends IService<ExtIntfSupplierEntity> {

    ListResult<?> queryExtIntfSupplierList(ExtIntfSupplierListReq reqMsg);

    boolean checkExtIntfSupplierRepeat(CheckExtIntfSupplierRepeatReq reqMsg);

    ListResult<?> queryExtIntfSupplierSelectList();

    boolean addExtIntfSupplier(AddExtIntfSupplierReq req);

    boolean updateExtIntfSupplier(AddExtIntfSupplierReq req);

    boolean removeExtIntfSupplier(RemoveExtIntfSupplierReq req);

    List<ExtIntfSupplierEntity> listDistanceSupplier(List<String> supplierIdList);

    void saveDistanceSupplier(List<ExtIntfSupplierEntity> supplierEntityList);

}
