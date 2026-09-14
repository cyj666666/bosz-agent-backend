package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.mapper.IndexRelateKnowledgeInfoMapper;
import com.suzhou.bank.agent.entity.IndexRelateKnowledgeInfoEntity;
import com.suzhou.bank.agent.model.req.IndexParamsInfoReq;
import com.suzhou.bank.agent.service.IIndexRelateKnowledgeInfoService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @Description: 指标关联知识库信息表
 * @Author: jeecg-boot
 * @Date: 2025-04-03
 * @Version: V1.0
 */
@Service
public class IndexRelateKnowledgeInfoServiceImpl extends ServiceImpl<IndexRelateKnowledgeInfoMapper, IndexRelateKnowledgeInfoEntity> implements IIndexRelateKnowledgeInfoService {

    @Override
    public ListResult<?> getListByParamNo(IndexParamsInfoReq reqMsg, List<String> childParamNoList) {
        LambdaQueryWrapper<IndexRelateKnowledgeInfoEntity> wrapper = new LambdaQueryWrapper<>();
        wrapper.like(StringUtils.isNotEmpty(reqMsg.getRelateKnowledgeName()),
                IndexRelateKnowledgeInfoEntity::getRelateKnowledgeName,
                reqMsg.getRelateKnowledgeName());
        wrapper.like(StringUtils.isNotEmpty(reqMsg.getRelateKnowledgeCode()),
                IndexRelateKnowledgeInfoEntity::getRelateKnowledgeCode,
                reqMsg.getRelateKnowledgeCode());
        wrapper.and(wq -> wq.eq(IndexRelateKnowledgeInfoEntity::getParamNo, reqMsg.getParamNo())
                .or().in(CollectionUtils.isNotEmpty(childParamNoList),
                        IndexRelateKnowledgeInfoEntity::getParamNo, childParamNoList));

        wrapper.select(IndexRelateKnowledgeInfoEntity::getRelateKnowledgeNo,
                IndexRelateKnowledgeInfoEntity::getRelateKnowledgeCode,
                IndexRelateKnowledgeInfoEntity::getRelateKnowledgeName,
                IndexRelateKnowledgeInfoEntity::getRelateGroupId,
                IndexRelateKnowledgeInfoEntity::getRelateItems);
        wrapper.groupBy(IndexRelateKnowledgeInfoEntity::getRelateKnowledgeNo,
                IndexRelateKnowledgeInfoEntity::getRelateKnowledgeCode,
                IndexRelateKnowledgeInfoEntity::getRelateKnowledgeName,
                IndexRelateKnowledgeInfoEntity::getRelateGroupId,
                IndexRelateKnowledgeInfoEntity::getRelateItems);

        Page<IndexRelateKnowledgeInfoEntity> page = new Page<>(reqMsg.getPageIndex(), reqMsg.getPageSize());
        IPage<IndexRelateKnowledgeInfoEntity> pageList = page(page, wrapper);

        if (CollectionUtils.isEmpty(pageList.getRecords())) {
            return new ListResult<>(0, 0);
        }
        return new ListResult<>((int) pageList.getTotal(), reqMsg.getPageSize(),
                reqMsg.getPageIndex(), pageList.getRecords());
    }
}
