package com.suzhou.bank.agent.service.impl;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.collections4.CollectionUtils;
import com.suzhou.bank.agent.entity.LargeModelConfigEntity;
import com.suzhou.bank.agent.mapper.LargeModelConfigMapper;
import com.suzhou.bank.agent.service.ILargeModelConfigService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @Description: 大模型信息配置表
 * @Author: jeecg-boot
 * @Date: 2024-11-05
 * @Version: V1.0
 */
@Service
public class LargeModelConfigServiceImpl extends ServiceImpl<LargeModelConfigMapper, LargeModelConfigEntity> implements ILargeModelConfigService {

    @Override
    public LargeModelConfigEntity getByLargeModelCode(String largeModelCode) {
        LambdaQueryWrapper<LargeModelConfigEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.select(LargeModelConfigEntity::getMaxTokens, LargeModelConfigEntity::getLmCode);
        queryWrapper.eq(LargeModelConfigEntity::getLmCode, largeModelCode);
        return baseMapper.selectOne(queryWrapper);
    }

    @Override
    public List<LargeModelConfigEntity> listByLargeModelCode(List<String> largeModelCodeList) {
        LambdaQueryWrapper<LargeModelConfigEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.in(LargeModelConfigEntity::getLmCode, largeModelCodeList);
        return baseMapper.selectList(queryWrapper);
    }

    @Override
    public List<LargeModelConfigEntity> listDistanceLargeModelCode(List<String> largeModelCodeList) {
        LambdaQueryWrapper<LargeModelConfigEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.in(LargeModelConfigEntity::getLmCode, largeModelCodeList);
        return list(queryWrapper);
    }

    @Override
    public void saveDistanceLargeModelConfig(List<LargeModelConfigEntity> modelConfigEntityList) {
        saveBatch(modelConfigEntityList);
    }

    @Override
    public void initModelConfig() {
        LambdaQueryWrapper<LargeModelConfigEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.isNull(LargeModelConfigEntity::getModelConfig);
        List<LargeModelConfigEntity> modelConfigEntityList = list(queryWrapper);
        if (CollectionUtils.isEmpty(modelConfigEntityList)) {
            return;
        }
        modelConfigEntityList.forEach(modelConfigEntity -> {
            JSONArray modelConfigArray = new JSONArray();
            JSONObject modelConfig = new JSONObject();
            modelConfig.put("model", modelConfigEntity.getModel());
            modelConfig.put("apiKey", modelConfigEntity.getApiKey());
            modelConfig.put("url", modelConfigEntity.getUrl());
            modelConfigArray.add(modelConfig);
            modelConfigEntity.setModelConfig(modelConfigArray.toJSONString());
        });
        updateBatchById(modelConfigEntityList);
    }
}
