package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.date.DateUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.config.ApiContextModel;
import com.suzhou.bank.agent.entity.KnowledgeBaseParamsEntity;
import com.suzhou.bank.agent.entity.KnowledgeBaseVersionEntity;
import com.suzhou.bank.agent.mapper.KnowledgeBaseVersionMapper;
import com.suzhou.bank.agent.model.dto.KnowledgeBaseVersionDTO;
import com.suzhou.bank.agent.service.IKnowledgeBaseVersionService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * @Description: 知识库版本记录表
 * @Author: jeecg-boot
 * @Date: 2025-11-06
 * @Version: V1.0
 */
@Service
public class KnowledgeBaseVersionServiceImpl extends ServiceImpl<KnowledgeBaseVersionMapper, KnowledgeBaseVersionEntity> implements IKnowledgeBaseVersionService {

    @Override
    public KnowledgeBaseVersionEntity getLatestVersion(String paramId) {
        LambdaQueryWrapper<KnowledgeBaseVersionEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(KnowledgeBaseVersionEntity::getParamId, paramId);
        queryWrapper.eq(KnowledgeBaseVersionEntity::getLatestFlag, "1");
        queryWrapper.orderByDesc(KnowledgeBaseVersionEntity::getCreateTime);
        queryWrapper.last("limit 1");
        return baseMapper.selectOne(queryWrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String publicVersion(KnowledgeBaseVersionDTO knowledgeBaseVersionDTO) {
        // 先将所有版本设置为历史版本
        LambdaQueryWrapper<KnowledgeBaseVersionEntity> updateWrapper = new LambdaQueryWrapper<>();
        updateWrapper.eq(KnowledgeBaseVersionEntity::getParamId, knowledgeBaseVersionDTO.getParamId());
        KnowledgeBaseVersionEntity updateEntity = new KnowledgeBaseVersionEntity();
        updateEntity.setLatestFlag("0");
        update(updateEntity, updateWrapper);
        // 保存最新版本
        KnowledgeBaseVersionEntity knowledgeBaseVersionEntity = new KnowledgeBaseVersionEntity();
        BeanUtil.copyProperties(knowledgeBaseVersionDTO, knowledgeBaseVersionEntity);
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        knowledgeBaseVersionEntity.setCreateUserId(apiContextModel.getUserId());
        knowledgeBaseVersionEntity.setCreateUserName(apiContextModel.getUserName());
        save(knowledgeBaseVersionEntity);
        return knowledgeBaseVersionEntity.getId();
    }

    @Override
    public void saveDistanceKnowledgeBaseVersion(List<KnowledgeBaseVersionEntity> backupKnowledgeBaseParamsList) {
        saveOrUpdateBatch(backupKnowledgeBaseParamsList);
    }

    @Override
    public void publicDistanceKnowledgeBaseVersion(List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList) {
        List<String> paramIdList = knowledgeBaseParamsList.stream().map(KnowledgeBaseParamsEntity::getParamId).collect(java.util.stream.Collectors.toList());

        // 先将所有版本设置为历史版本
        LambdaQueryWrapper<KnowledgeBaseVersionEntity> updateWrapper = new LambdaQueryWrapper<>();
        updateWrapper.in(KnowledgeBaseVersionEntity::getParamId, paramIdList);
        KnowledgeBaseVersionEntity updateEntity = new KnowledgeBaseVersionEntity();
        updateEntity.setLatestFlag("0");
        update(updateEntity, updateWrapper);

        // 保存最新版本
        String versionNo = DateUtil.now() + "_" + System.currentTimeMillis();
        List<KnowledgeBaseVersionEntity> knowledgeBaseVersionEntityList = knowledgeBaseParamsList.stream().map(knowledgeBaseParamsEntity -> {
            KnowledgeBaseVersionEntity knowledgeBaseVersionEntity = new KnowledgeBaseVersionEntity();
            BeanUtil.copyProperties(knowledgeBaseParamsEntity, knowledgeBaseVersionEntity);
            ApiContextModel apiContextModel = ApiContext.getApiContextModel();
            knowledgeBaseVersionEntity.setCreateUserId(apiContextModel.getUserId());
            knowledgeBaseVersionEntity.setCreateUserName(apiContextModel.getUserName());
            knowledgeBaseVersionEntity.setVersionNo(versionNo);
            knowledgeBaseVersionEntity.setLatestFlag("1");
            knowledgeBaseVersionEntity.setVersionName("系统自动发布版本");
            return knowledgeBaseVersionEntity;
        }).collect(Collectors.toList());
        saveOrUpdateBatch(knowledgeBaseVersionEntityList);
    }
}
