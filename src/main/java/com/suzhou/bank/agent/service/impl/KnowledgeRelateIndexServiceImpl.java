package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.entity.IndexParamsEntity;
import com.suzhou.bank.agent.entity.KnowledgeRelateIndexEntity;
import com.suzhou.bank.agent.entity.KnowledgeRelateInputParamEntity;
import com.suzhou.bank.agent.enums.AddTypeEnum;
import com.suzhou.bank.agent.enums.OnlineEnum;
import com.suzhou.bank.agent.mapper.KnowledgeRelateIndexMapper;
import com.suzhou.bank.agent.model.req.KnowledgeRelateIndexReq;
import com.suzhou.bank.agent.service.IIndexParamsService;
import com.suzhou.bank.agent.service.IKnowledgeRelateIndexService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * @Description: 知识库管理指标信息
 * @Author: jeecg-boot
 * @Date: 2025-09-26
 * @Version: V1.0
 */
@Service
public class KnowledgeRelateIndexServiceImpl extends ServiceImpl<KnowledgeRelateIndexMapper, KnowledgeRelateIndexEntity> implements IKnowledgeRelateIndexService {

    @Autowired
    protected IIndexParamsService indexParamsService;

    @Override
    public Integer saveIndex(KnowledgeRelateIndexEntity knowledgeRelateIndex) {
        IndexParamsEntity indexParamsEntity = indexParamsService.getById(knowledgeRelateIndex.getIndexNo());
        if (indexParamsEntity == null) {
            throw new AgentBizException("选择的指标不存在，保存失败！");
        }
        // 查询指标类型、关联接口
        IndexParamsEntity parentIndexEntity = indexParamsService.getById(indexParamsEntity.getParentParamNo());
        if (Objects.nonNull(parentIndexEntity)) {
            knowledgeRelateIndex.setSupplierId(parentIndexEntity.getSupplierId());
            knowledgeRelateIndex.setIntfNo(parentIndexEntity.getIntfNo());
        }
        String parentParamNo = StringUtils.isEmpty(indexParamsEntity.getOtherNo()) ? indexParamsEntity.getParentParamNo() : indexParamsEntity.getOtherNo();
        knowledgeRelateIndex.setParentIndexNo(parentParamNo);
        knowledgeRelateIndex.setAddType(AddTypeEnum.ADD.getValue());
        knowledgeRelateIndex.setIndexType(indexParamsEntity.getParamType());
        save(knowledgeRelateIndex);
        return knowledgeRelateIndex.getId();
    }

    @Override
    public void updateIndex(List<KnowledgeRelateIndexEntity> knowledgeRelateIndexList) {
        if (knowledgeRelateIndexList.isEmpty()) {
            return;
        }
        updateBatchById(knowledgeRelateIndexList);
    }

    @Override
    public List<String> getIndexListByKnowledgeId(String knowledgeId, String addType) {
        if (knowledgeId == null || knowledgeId.isEmpty()) {
            return Collections.emptyList();
        }
        LambdaQueryWrapper<KnowledgeRelateIndexEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.select(KnowledgeRelateIndexEntity::getIndexNo);
        queryWrapper.eq(KnowledgeRelateIndexEntity::getAddType, addType);
        queryWrapper.eq(KnowledgeRelateIndexEntity::getKnowledgeId, knowledgeId);
        return baseMapper.selectList(queryWrapper)
                .stream()
                .map(KnowledgeRelateIndexEntity::getIndexNo)
                .collect(Collectors.toList());
    }

    @Override
    public ListResult<?> getPageList(KnowledgeRelateIndexReq knowledgeRelateIndexReq) {
        LambdaQueryWrapper<KnowledgeRelateIndexEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.like(StringUtils.isNotEmpty(knowledgeRelateIndexReq.getIndexNo()), KnowledgeRelateIndexEntity::getIndexNo, knowledgeRelateIndexReq.getIndexNo());
        queryWrapper.like(StringUtils.isNotEmpty(knowledgeRelateIndexReq.getIndexName()), KnowledgeRelateIndexEntity::getIndexName, knowledgeRelateIndexReq.getIndexName());
        queryWrapper.eq(StringUtils.isNotEmpty(knowledgeRelateIndexReq.getTraceStatus()), KnowledgeRelateIndexEntity::getTraceStatus, knowledgeRelateIndexReq.getTraceStatus());
        queryWrapper.eq(StringUtils.isNotEmpty(knowledgeRelateIndexReq.getTraceCardStatus()), KnowledgeRelateIndexEntity::getTraceCardStatus, knowledgeRelateIndexReq.getTraceCardStatus());
        queryWrapper.eq(StringUtils.isNotEmpty(knowledgeRelateIndexReq.getIndexType()), KnowledgeRelateIndexEntity::getIndexType, knowledgeRelateIndexReq.getIndexType());
        queryWrapper.eq(KnowledgeRelateIndexEntity::getKnowledgeId, knowledgeRelateIndexReq.getKnowledgeId());
        queryWrapper.orderByDesc(KnowledgeRelateIndexEntity::getInputTime);
        Page<KnowledgeRelateIndexEntity> page = new Page<>(knowledgeRelateIndexReq.getPageIndex(), knowledgeRelateIndexReq.getPageSize());
        IPage<KnowledgeRelateIndexEntity> pageList = page(page, queryWrapper);
        if (CollectionUtils.isEmpty(pageList.getRecords())) {
            return new ListResult<>(0, 0);
        }
        return new ListResult<>((int) pageList.getTotal(), knowledgeRelateIndexReq.getPageSize(), knowledgeRelateIndexReq.getPageIndex(), pageList.getRecords());
    }

    @Override
    public Map<String, String> getSourceIndexList(String knowledgeId) {
        if (knowledgeId == null || knowledgeId.isEmpty()) {
            return Collections.emptyMap();
        }
        LambdaQueryWrapper<KnowledgeRelateIndexEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.select(KnowledgeRelateIndexEntity::getIndexNo, KnowledgeRelateIndexEntity::getIndexName);
        queryWrapper.eq(KnowledgeRelateIndexEntity::getTraceStatus, OnlineEnum.Y.name());
        queryWrapper.eq(KnowledgeRelateIndexEntity::getKnowledgeId, knowledgeId);
        // 防止key重复
        return baseMapper.selectList(queryWrapper)
                .stream()
                .collect(Collectors.toMap(KnowledgeRelateIndexEntity::getIndexNo, KnowledgeRelateIndexEntity::getIndexName, (oldValue, newValue) -> oldValue));
    }

    @Override
    public Map<String, String> getSourceCardIndexTraceConfigList(String knowledgeId) {
        if (knowledgeId == null || knowledgeId.isEmpty()) {
            return Collections.emptyMap();
        }
        LambdaQueryWrapper<KnowledgeRelateIndexEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.select(KnowledgeRelateIndexEntity::getIndexNo, KnowledgeRelateIndexEntity::getTraceConfig);
        queryWrapper.eq(KnowledgeRelateIndexEntity::getTraceCardStatus, OnlineEnum.Y.name());
        queryWrapper.eq(KnowledgeRelateIndexEntity::getKnowledgeId, knowledgeId);
        return baseMapper.selectList(queryWrapper)
                .stream()
                .collect(Collectors.toMap(KnowledgeRelateIndexEntity::getIndexNo, KnowledgeRelateIndexEntity::getTraceConfig, (oldValue, newValue) -> oldValue));
    }

    @Override
    public List<KnowledgeRelateIndexEntity> listByKnowledgeId(List<String> knowledgeIdList) {
        return baseMapper.selectList(Wrappers.lambdaQuery(KnowledgeRelateIndexEntity.class)
                .in(KnowledgeRelateIndexEntity::getKnowledgeId, knowledgeIdList));
    }

    @Override
    public List<KnowledgeRelateIndexEntity> listDistanceInputParams(List<String> paramIdList) {
        return baseMapper.selectList(Wrappers.lambdaQuery(KnowledgeRelateIndexEntity.class)
                .in(KnowledgeRelateIndexEntity::getKnowledgeId, paramIdList));
    }

    @Override
    public void removeDistanceRelateIndex(List<Integer> collect) {
        removeBatchByIds(collect);
    }

    @Override
    public void saveDistanceRelateIndex(List<KnowledgeRelateIndexEntity> relateIndexEntityList) {
        saveBatch(relateIndexEntityList);
    }

}
