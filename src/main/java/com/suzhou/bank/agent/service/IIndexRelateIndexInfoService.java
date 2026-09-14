package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.entity.IndexRelateIndexInfoEntity;
import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.model.req.IndexParamsInfoReq;

import java.util.List;

/**
 * @Description: 指标关联指标信息表
 * @Author: jeecg-boot
 * @Date:   2025-04-03
 * @Version: V1.0
 */
public interface IIndexRelateIndexInfoService extends IService<IndexRelateIndexInfoEntity> {

    ListResult<?> getListByParamNo(IndexParamsInfoReq reqMsg, List<String> childParamNoList);
}
