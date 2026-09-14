package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.date.DateUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.collections4.CollectionUtils;
import com.suzhou.bank.agent.mapper.IndexRelateInfoMapper;
import com.suzhou.bank.agent.entity.IndexRelateInfoEntity;
import com.suzhou.bank.agent.service.IIndexRelateInfoService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * @Description: 指标关联信息表
 * @Author: jeecg-boot
 * @Date: 2024-11-04
 * @Version: V1.0
 */
@Service
public class IndexRelateInfoServiceImpl extends ServiceImpl<IndexRelateInfoMapper, IndexRelateInfoEntity> implements IIndexRelateInfoService {


    @Override
    public List<String> getRelateIndexList(List<String> indexList) {
        LambdaQueryWrapper<IndexRelateInfoEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.select(IndexRelateInfoEntity::getRelateIndexId);
        queryWrapper.in(IndexRelateInfoEntity::getIndexId, indexList);
        List<IndexRelateInfoEntity> list = list(queryWrapper);
        if (CollectionUtils.isEmpty(list)) {
            return null;
        }
        return list.stream().map(IndexRelateInfoEntity::getRelateIndexId).collect(Collectors.toList());
    }

    @Override
    public boolean removeRelateInfo(List<String> indexIdList, List<String> relateIndexList) {
        LambdaQueryWrapper<IndexRelateInfoEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.in(IndexRelateInfoEntity::getIndexId, indexIdList);
        queryWrapper.in(IndexRelateInfoEntity::getRelateIndexId, relateIndexList);
        remove(queryWrapper);
        return false;
    }

    @Override
    public boolean saveRelateInfo(List<String> indexIdList, List<String> relateIndexList) {
        indexIdList.forEach(indexId -> relateIndexList.forEach(relateIndexId -> {
            IndexRelateInfoEntity indexRelateInfoEntity = new IndexRelateInfoEntity();
            indexRelateInfoEntity.setIndexId(indexId);
            indexRelateInfoEntity.setRelateIndexId(relateIndexId);
            indexRelateInfoEntity.setRelateTime(DateUtil.now());
            save(indexRelateInfoEntity);
        }));
        return true;
    }

    @Override
    public void saveDistanceRelateInfo(String indexId, List<String> relateIndexList) {
        relateIndexList.forEach(relateIndexId -> {
            IndexRelateInfoEntity indexRelateInfoEntity = new IndexRelateInfoEntity();
            indexRelateInfoEntity.setIndexId(indexId);
            indexRelateInfoEntity.setRelateIndexId(relateIndexId);
            indexRelateInfoEntity.setRelateTime(DateUtil.now());
            save(indexRelateInfoEntity);
        });
    }

    @Override
    public void removeDistanceRelateInfo(String indexId) {
        LambdaQueryWrapper<IndexRelateInfoEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(IndexRelateInfoEntity::getIndexId, indexId);
        remove(queryWrapper);
    }

    @Override
    public boolean removeRelateInfoByIndexId(List<String> indexIdList) {
        LambdaQueryWrapper<IndexRelateInfoEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.in(IndexRelateInfoEntity::getRelateIndexId, indexIdList);
        remove(queryWrapper);
        return true;
    }
}
