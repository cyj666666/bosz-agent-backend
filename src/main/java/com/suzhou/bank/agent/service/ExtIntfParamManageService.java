package com.suzhou.bank.agent.service;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.entity.ExtIntfParamManageEntity;
import com.suzhou.bank.agent.model.req.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public interface ExtIntfParamManageService extends IService<ExtIntfParamManageEntity> {

    ListResult<?> queryExtIntfParamManageList(ExtIntfParamManageListReq reqMsg);

    boolean checkExtIntfParamManageRepeat(CheckExtIntfParamManageRepeatReq req);

    boolean handleExtIntfParamManage(ExtIntfParamManageReq req);

    boolean removeExtIntfParamManage(RemoveExtIntfReq req);

    Map<String, String> getIntfData(String paramNo, String supplierId, String intfNo, JSONObject paramJson, JSONArray intfParamArr, String relateIndexSet);

    JSONObject getIntfStructure(CheckExtIntfManageRepeatReq reqMsg);

    List<ExtIntfParamManageEntity> listExtIntfParamManage(List<String> supplierIdList, ArrayList<String> intfNoList);

    void saveDistanceExtIntfParamManage(List<ExtIntfParamManageEntity> paramManageList);

    List<ExtIntfParamManageEntity> listExtIntfParamManage(String supplierId, String intfNo);
}
