package com.suzhou.bank.agent.mapper;

import com.alibaba.fastjson.JSONObject;
import com.suzhou.bank.agent.entity.KnowledgeBaseParamsEntity;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * @Description: test
 * @Author: jeecg-boot
 * @Date:   2024-05-30
 * @Version: V1.0
 */
@Mapper
public interface KnowledgeBaseParamsMapper extends BaseMapper<KnowledgeBaseParamsEntity> {

    List<JSONObject> getApplyPromptList();
}
