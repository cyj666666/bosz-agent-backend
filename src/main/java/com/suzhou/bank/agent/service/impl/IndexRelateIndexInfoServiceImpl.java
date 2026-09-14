package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.mapper.IndexRelateIndexInfoMapper;
import com.suzhou.bank.agent.entity.IndexRelateIndexInfoEntity;
import com.suzhou.bank.agent.model.req.IndexParamsInfoReq;
import com.suzhou.bank.agent.service.IIndexRelateIndexInfoService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @Description: 指标关联指标信息表
 * @Author: jeecg-boot
 * @Date: 2025-04-03
 * @Version: V1.0
 */
@Service
public class IndexRelateIndexInfoServiceImpl extends ServiceImpl<IndexRelateIndexInfoMapper, IndexRelateIndexInfoEntity> implements IIndexRelateIndexInfoService {


    @Override
    public ListResult<?> getListByParamNo(IndexParamsInfoReq reqMsg, List<String> childParamNoList) {
        LambdaQueryWrapper<IndexRelateIndexInfoEntity> wrapper = new LambdaQueryWrapper<>();
        wrapper.like(StringUtils.isNotEmpty(reqMsg.getRelateParamNo()),
                IndexRelateIndexInfoEntity::getRelateParamNo, reqMsg.getRelateParamNo());
        wrapper.like(StringUtils.isNotEmpty(reqMsg.getRelateParamName()),
                IndexRelateIndexInfoEntity::getRelateParamName, reqMsg.getRelateParamName());
        wrapper.and(wq -> wq.eq(IndexRelateIndexInfoEntity::getParamNo, reqMsg.getParamNo())
                .or().in(CollectionUtils.isNotEmpty(childParamNoList),
                        IndexRelateIndexInfoEntity::getParamNo, childParamNoList));

        wrapper.select(IndexRelateIndexInfoEntity::getRelateParamNo,
                IndexRelateIndexInfoEntity::getRelateParamId,
                IndexRelateIndexInfoEntity::getRelateParamName,
                IndexRelateIndexInfoEntity::getRelateGroupId);

        wrapper.groupBy(IndexRelateIndexInfoEntity::getRelateParamNo,
                IndexRelateIndexInfoEntity::getRelateParamId,
                IndexRelateIndexInfoEntity::getRelateParamName,
                IndexRelateIndexInfoEntity::getRelateGroupId);

        Page<IndexRelateIndexInfoEntity> page = new Page<>(reqMsg.getPageIndex(), reqMsg.getPageSize());
        IPage<IndexRelateIndexInfoEntity> pageList = page(page, wrapper);

        if (CollectionUtils.isEmpty(pageList.getRecords())) {
            return new ListResult<>(0, 0);
        }
        return new ListResult<>((int) pageList.getTotal(), reqMsg.getPageSize(),
                reqMsg.getPageIndex(), pageList.getRecords());
    }
}
