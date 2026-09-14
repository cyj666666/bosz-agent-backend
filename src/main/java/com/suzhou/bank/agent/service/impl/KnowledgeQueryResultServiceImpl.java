package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.suzhou.bank.agent.entity.KnowledgeQueryResultEntity;
import com.suzhou.bank.agent.mapper.KnowledgeQueryResultMapper;
import com.suzhou.bank.agent.service.IKnowledgeQueryResultService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @Description: 知识库查询记录表
 * @Author: jeecg-boot
 * @Date: 2024-11-06
 * @Version: V1.0
 */
@Service
public class KnowledgeQueryResultServiceImpl extends ServiceImpl<KnowledgeQueryResultMapper, KnowledgeQueryResultEntity> implements IKnowledgeQueryResultService {

    @Override
    public List<KnowledgeQueryResultEntity> getByTraceId(String traceId) {
        QueryWrapper<KnowledgeQueryResultEntity> queryWrapper = new QueryWrapper<>();

        queryWrapper.select(
                "id",
                "query_type as queryType",
                "supplier_id as supplierId",
                "intf_no as intfNo",
                "MAX(cost_time) as costTime"
        );

        queryWrapper.eq("trace_id", traceId);
        queryWrapper.groupBy("query_type", "supplier_id", "intf_no");
        queryWrapper.orderByDesc("costTime");
        queryWrapper.last("limit 10");

        return baseMapper.selectList(queryWrapper);
    }

    @Override
    public void saveBatchLog(List<KnowledgeQueryResultEntity> logEntityList) {
        saveBatch(logEntityList);
    }
}
