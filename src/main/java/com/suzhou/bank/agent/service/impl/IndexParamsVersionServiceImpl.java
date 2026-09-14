package com.suzhou.bank.agent.service.impl;

import com.suzhou.bank.agent.entity.IndexParamsVersionEntity;
import com.suzhou.bank.agent.mapper.IndexParamsVersionMapper;
import com.suzhou.bank.agent.service.IIndexParamsVersionService;
import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;

import java.util.List;

/**
 * @Description: 指标参数版本信息表
 * @Author: jeecg-boot
 * @Date:   2026-02-27
 * @Version: V1.0
 */
@Service
public class IndexParamsVersionServiceImpl extends ServiceImpl<IndexParamsVersionMapper, IndexParamsVersionEntity> implements IIndexParamsVersionService {

    @Override
    public void saveDistanceIndexParamsVersion(List<IndexParamsVersionEntity> indexParamsVersionEntityList) {
        saveBatch(indexParamsVersionEntityList);
    }
}
