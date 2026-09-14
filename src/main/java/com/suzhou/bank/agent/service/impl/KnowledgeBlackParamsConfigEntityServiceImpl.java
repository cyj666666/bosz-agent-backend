package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.suzhou.bank.agent.entity.KnowledgeBlackParamsConfigEntity;
import com.suzhou.bank.agent.entity.KnowledgeRelateInputParamEntity;
import com.suzhou.bank.agent.mapper.KnowledgeBlackParamsConfigEntityMapper;
import com.suzhou.bank.agent.service.IKnowledgeBlackParamsConfigEntityService;
import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;

import java.util.List;

/**
 * @Description: 知识库黑盒参数配置表
 * @Author: jeecg-boot
 * @Date:   2025-02-20
 * @Version: V1.0
 */
@Service
public class KnowledgeBlackParamsConfigEntityServiceImpl extends ServiceImpl<KnowledgeBlackParamsConfigEntityMapper, KnowledgeBlackParamsConfigEntity> implements IKnowledgeBlackParamsConfigEntityService {

    @Override
    public List<KnowledgeBlackParamsConfigEntity> getListByKnowledgeId(String knowledgeId) {
        LambdaQueryWrapper<KnowledgeBlackParamsConfigEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(KnowledgeBlackParamsConfigEntity::getRelateKnowledgeId, knowledgeId);
        return list(queryWrapper);
    }

    @Override
    public List<KnowledgeBlackParamsConfigEntity> listByKnowledgeId(List<String> paramIdList) {
        return baseMapper.selectList(new LambdaQueryWrapper<KnowledgeBlackParamsConfigEntity>()
                .in(KnowledgeBlackParamsConfigEntity::getRelateKnowledgeId, paramIdList));
    }

    @Override
    public List<KnowledgeBlackParamsConfigEntity> listDistanceInputParams(List<String> paramIdList) {
        LambdaQueryWrapper<KnowledgeBlackParamsConfigEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.in(KnowledgeBlackParamsConfigEntity::getRelateKnowledgeId, paramIdList);
        return list(queryWrapper);
    }

    @Override
    public void removeDistanceBlackParamsConfig(List<Integer> idList) {
        removeBatchByIds(idList);
    }

    @Override
    public void saveDistanceBlackParamsConfig(List<KnowledgeBlackParamsConfigEntity> blackParamsConfigEntityList) {
        saveBatch(blackParamsConfigEntityList);
    }
}
