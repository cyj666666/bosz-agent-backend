package com.suzhou.bank.agent.service.impl;

import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.google.common.collect.Maps;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import java.util.ArrayList;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.mapper.KnowledgeBaseGroupMapper;
import com.suzhou.bank.agent.mapper.KnowledgeBaseParamsMapper;
import com.suzhou.bank.agent.entity.KnowledgeBaseGroupEntity;
import com.suzhou.bank.agent.entity.KnowledgeBaseParamsEntity;
import com.suzhou.bank.agent.service.IKnowledgeBaseGroupService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

import java.util.*;


@Slf4j
@Service
public class KnowledgeBaseGroupServiceImpl extends ServiceImpl<KnowledgeBaseGroupMapper, KnowledgeBaseGroupEntity> implements IKnowledgeBaseGroupService {

    @Resource
    private KnowledgeBaseGroupMapper knowledgeBaseGroupMapper;

    @Resource
    private KnowledgeBaseParamsMapper knowledgeBaseParamsMapper;

    @Override
    public String getGroupId(String groupName) {
        LambdaQueryWrapper<KnowledgeBaseGroupEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(KnowledgeBaseGroupEntity::getGroupId);
        queryWrapper.eq(KnowledgeBaseGroupEntity::getGroupName, groupName);
        List<KnowledgeBaseGroupEntity> list = list(queryWrapper);
        if (CollectionUtils.isEmpty(list)) {
            return "";
        }
        return list.get(0).getGroupId();
    }

    @Override
    public String getGroupIdByModuleCode(String moduleCode, boolean ignoreStatus) {
        List<String> moduleCodeList = Arrays.asList(moduleCode.split("-"));
        String groupValue = moduleCodeList.get(moduleCodeList.size() - 1);
        LambdaQueryWrapper<KnowledgeBaseParamsEntity> lambdaQuery = Wrappers.lambdaQuery();
        // lambdaQuery.eq(!ignoreStatus, KnowledgeBaseParamsEntity::getParamStatus, 'Y');
        lambdaQuery.eq(!ignoreStatus, KnowledgeBaseParamsEntity::getOnline, 'Y');
        lambdaQuery.eq(KnowledgeBaseParamsEntity::getParamNo, groupValue);
        List<KnowledgeBaseParamsEntity> list = knowledgeBaseParamsMapper.selectList(lambdaQuery);
        if (CollectionUtils.isEmpty(list)) {
            return null;
        }

        // 循环取到对应该modelCode的知识库主键ID
        String paramId = "";
        for (KnowledgeBaseParamsEntity baseGroupEntity : list) {
            String groupId = baseGroupEntity.getGroupId();
            List<String> groupValueList = new ArrayList<>();
            groupValueList.add(baseGroupEntity.getParamNo());
            getGroupInfo(groupId, groupValueList);
            StringBuffer value = new StringBuffer();
            for (int i = groupValueList.size() - 1; i >= 0; i--) {
                if (StringUtils.isEmpty(value)) {
                    value.append(groupValueList.get(i));
                } else {
                    value.append("-").append(groupValueList.get(i));
                }
            }
            boolean vsFlag = value.toString().equalsIgnoreCase(moduleCode);
            if (vsFlag) {
                paramId = baseGroupEntity.getParamId();
                break;
            }
        }

        return paramId;
    }

    @Override
    public String getGroupId(String groupName, String groupValue) {
        LambdaQueryWrapper<KnowledgeBaseGroupEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(KnowledgeBaseGroupEntity::getGroupId);
        queryWrapper.eq(KnowledgeBaseGroupEntity::getGroupName, groupName);
        queryWrapper.eq(KnowledgeBaseGroupEntity::getGroupValue, groupValue);
        List<KnowledgeBaseGroupEntity> baseGroupEntityList = list(queryWrapper);
        if (CollectionUtils.isEmpty(baseGroupEntityList)) {
            return "";
        }
        return baseGroupEntityList.get(0).getGroupId();
    }

    @Override
    public JSONObject getGroupInfo(String knowledgeId, String groupId) {
        Map<String, JSONObject> result = Maps.newHashMap();
        JSONObject knowledgeBaseInfo = knowledgeBaseGroupMapper.getKnowledgeBaseInfo(groupId);
        if (Objects.isNull(knowledgeBaseInfo)) {
            return null;
        }
        return knowledgeBaseInfo;
    }

    @Override
    public void getByGroupId(String groupId, List<String> groupIdList) {
        LambdaQueryWrapper<KnowledgeBaseGroupEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(KnowledgeBaseGroupEntity::getGroupId);
        queryWrapper.eq(KnowledgeBaseGroupEntity::getParentGroupId, groupId);
        queryWrapper.ne(KnowledgeBaseGroupEntity::getGroupName, "全部");
        List<KnowledgeBaseGroupEntity> baseGroupEntityList = list(queryWrapper);
        if (CollectionUtils.isNotEmpty(baseGroupEntityList)) {
            baseGroupEntityList.forEach(group -> {
                groupIdList.add(group.getGroupId());
                getByGroupId(group.getGroupId(), groupIdList);
            });
        }
    }

    @Override
    public List<KnowledgeBaseGroupEntity> getGroupInfo(List<String> groupValueList) {
        if (CollectionUtils.isEmpty(groupValueList)) {
            return Collections.emptyList();
        }
        LambdaQueryWrapper<KnowledgeBaseGroupEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(KnowledgeBaseGroupEntity::getGroupId, KnowledgeBaseGroupEntity::getGroupName, KnowledgeBaseGroupEntity::getGroupValue, KnowledgeBaseGroupEntity::getParentGroupId, KnowledgeBaseGroupEntity::getParentGroupName, KnowledgeBaseGroupEntity::getSortNo, KnowledgeBaseGroupEntity::getGroupStatus, KnowledgeBaseGroupEntity::getInputTime, KnowledgeBaseGroupEntity::getUpdateTime);
        queryWrapper.in(KnowledgeBaseGroupEntity::getGroupValue, groupValueList);
        List<KnowledgeBaseGroupEntity> baseGroupEntityList = list(queryWrapper);
        if (CollectionUtils.isEmpty(baseGroupEntityList)) {
            return Collections.emptyList();
        }
        return baseGroupEntityList;
    }

    @Override
    public void saveDistanceKnowledgeBaseGroup(List<KnowledgeBaseGroupEntity> knowledgeBaseGroupList) {
        saveOrUpdateBatch(knowledgeBaseGroupList);
    }

    private void getGroupInfo(String groupId, List<String> groupValueList) {
        KnowledgeBaseGroupEntity baseGroupEntity = getById(groupId);
        if (Objects.nonNull(baseGroupEntity)) {
            if (!Objects.equals(baseGroupEntity.getParentGroupId(), "0")) {
                groupValueList.add(baseGroupEntity.getGroupValue());
            }
            if (StringUtils.isNotEmpty(baseGroupEntity.getParentGroupId())) {
                getGroupInfo(baseGroupEntity.getParentGroupId(), groupValueList);
            }
        }
    }
}
