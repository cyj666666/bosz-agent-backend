package com.suzhou.bank.agent.mapper;

import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import com.suzhou.bank.agent.entity.KnowledgeRelateIndexEntity;

import java.util.List;

/**
 * @Description: 知识库管理指标信息
 * @Author: jeecg-boot
 * @Date:   2025-09-26
 * @Version: V1.0
 */
@Mapper
public interface KnowledgeRelateIndexMapper extends BaseMapper<KnowledgeRelateIndexEntity> {

    List<JSONObject> getAllIndexRelateInfo();
}
