package com.suzhou.bank.agent.service.impl;
import java.util.ArrayList;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.google.common.collect.Lists;
import org.apache.commons.collections.CollectionUtils;
import com.suzhou.bank.agent.mapper.IndexBaseGroupMapper;
import com.suzhou.bank.agent.entity.IndexBaseGroupEntity;
import com.suzhou.bank.agent.service.IIndexBaseGroupService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @Description: 指标分组表
 * @Author: jeecg-boot
 * @Date: 2024-09-13
 * @Version: V1.0
 */
@Service
public class IndexBaseGroupServiceImpl extends ServiceImpl<IndexBaseGroupMapper, IndexBaseGroupEntity> implements IIndexBaseGroupService {

    @Override
    public List<String> getAllChildGroupIdList(String groupId) {
        List<String> allChildGroupIdList = new ArrayList<>();
        getAllChildGroupIdList(groupId, allChildGroupIdList);
        return allChildGroupIdList;
    }

    @Override
    public void saveDistanceIndexBaseGroup(List<IndexBaseGroupEntity> indexBaseGroupList) {
        saveOrUpdateBatch(indexBaseGroupList);
    }

    private void getAllChildGroupIdList(String groupId, List<String> groupIdList) {
        LambdaQueryWrapper<IndexBaseGroupEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.select(IndexBaseGroupEntity::getGroupId, IndexBaseGroupEntity::getParentGroupId);
        queryWrapper.eq(IndexBaseGroupEntity::getParentGroupId, groupId);
        List<IndexBaseGroupEntity> indexBaseGroupEntityList = baseMapper.selectList(queryWrapper);
        if (CollectionUtils.isNotEmpty(indexBaseGroupEntityList)) {
            for (IndexBaseGroupEntity childGroup : indexBaseGroupEntityList) {
                groupIdList.add(childGroup.getGroupId());
                getAllChildGroupIdList(childGroup.getGroupId(), groupIdList);
            }
        }
    }
}
