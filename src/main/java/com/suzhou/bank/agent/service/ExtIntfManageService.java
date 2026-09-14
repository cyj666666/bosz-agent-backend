package com.suzhou.bank.agent.service;


import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.entity.ExtIntfManageEntity;
import com.suzhou.bank.agent.model.req.CheckExtIntfManageRepeatReq;
import com.suzhou.bank.agent.model.req.ExtIntfManageListReq;
import com.suzhou.bank.agent.model.req.ExtIntfManageReq;
import com.suzhou.bank.agent.model.req.RemoveExtIntfReq;

import java.util.List;
import java.util.Map;

public interface ExtIntfManageService extends IService<ExtIntfManageEntity> {

    ListResult<?> queryExtIntfManageList(ExtIntfManageListReq reqMsg);

    boolean checkExtIntfManageRepeat(CheckExtIntfManageRepeatReq reqMsg);

    boolean handleExtIntfManage(ExtIntfManageReq req);

    boolean removeExtIntfManage(RemoveExtIntfReq req);

    Map<String, String> getExtIntfInfoList(List<String> intfNoList, List<String> supplierIdList);

    ExtIntfManageEntity getExtIntfManage(String intfNo, String supplierId);

    List<ExtIntfManageEntity> listExtIntfManage(List<String> supplierIdList, List<String> intfNoList);

    void saveDistanceExtIntfManage(List<ExtIntfManageEntity> extIntfManageList);
}
