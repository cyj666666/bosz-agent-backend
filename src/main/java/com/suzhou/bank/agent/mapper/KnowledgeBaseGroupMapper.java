package com.suzhou.bank.agent.mapper;

import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import com.suzhou.bank.agent.entity.KnowledgeBaseGroupEntity;
import com.suzhou.bank.agent.model.vo.KnowledgeInfoVO;

import java.util.List;

@Mapper
public interface KnowledgeBaseGroupMapper extends BaseMapper<KnowledgeBaseGroupEntity> {

    List<KnowledgeInfoVO> getKnowledgeGroupTree();

    String getKnowledgeBaseLevelInfo(String groupId);

    String getKnowledgeBaseNameInfo(String groupId);

    JSONObject getKnowledgeBaseInfo(String groupId);

    String getGroupId(String groupId);

    List<KnowledgeBaseGroupEntity> getFirstKnowledgeBaseGroup();

    List<KnowledgeBaseGroupEntity> getKnowledgeBaseGroupList(@Param("groupIdListStr") String groupIdListStr, @Param("groupIdList") List<String> groupIdList);
}
