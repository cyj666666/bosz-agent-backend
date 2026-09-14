package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.suzhou.bank.agent.entity.KnowledgeRelateInputParamEntity;
import com.suzhou.bank.agent.mapper.KnowledgeRelateInputParamMapper;
import com.suzhou.bank.agent.service.IKnowledgeRelateInputParamService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @Description: 知识库管理数据集
 * @Author: jeecg-boot
 * @Date: 2025-12-02
 * @Version: V1.0
 */
@Service
public class KnowledgeRelateInputParamServiceImpl extends ServiceImpl<KnowledgeRelateInputParamMapper, KnowledgeRelateInputParamEntity> implements IKnowledgeRelateInputParamService {

    @Override
    public List<KnowledgeRelateInputParamEntity> listByKnowledgeId(List<String> knowledgeIdList) {
        return baseMapper.selectList(Wrappers.lambdaQuery(KnowledgeRelateInputParamEntity.class)
                .in(KnowledgeRelateInputParamEntity::getKnowledgeId, knowledgeIdList));
    }

    @Override
    public List<KnowledgeRelateInputParamEntity> listDistanceInputParams(List<String> knowledgeIdList) {
        return baseMapper.selectList(Wrappers.lambdaQuery(KnowledgeRelateInputParamEntity.class)
                .in(KnowledgeRelateInputParamEntity::getKnowledgeId, knowledgeIdList));
    }

    @Override
    public void removeDistanceInputParams(List<String> idList) {
        removeByIds(idList);
    }

    @Override
    public void saveDistanceInputParams(List<KnowledgeRelateInputParamEntity> inputParamList) {
        saveOrUpdateBatch(inputParamList);
    }
}
