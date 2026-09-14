package com.suzhou.bank.agent.service;

import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.KnowledgeBaseGroupEntity;

import java.util.List;


public interface IKnowledgeBaseGroupService extends IService<KnowledgeBaseGroupEntity> {

    String getGroupId(String groupName);

    String getGroupIdByModuleCode(String moduleCode, boolean ignoreStatus);

    String getGroupId(String groupName, String groupValue);

    JSONObject getGroupInfo(String knowledgeId, String groupId);

    void getByGroupId(String groupId, List<String> groupIdList);

    List<KnowledgeBaseGroupEntity> getGroupInfo(List<String> groupValueList);

    void saveDistanceKnowledgeBaseGroup(List<KnowledgeBaseGroupEntity> knowledgeBaseGroupList);
}
