package com.suzhou.bank.agent.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.collections4.CollectionUtils;
import com.suzhou.bank.agent.mapper.TraceQueryResultMapper;
import com.suzhou.bank.agent.entity.TraceQueryResultEntity;
import com.suzhou.bank.agent.service.ITraceQueryResultService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @Description: 溯源查询结果表
 * @Author: jeecg-boot
 * @Date: 2024-11-21
 * @Version: V1.0
 */
@Service
public class TraceQueryResultServiceImpl extends ServiceImpl<TraceQueryResultMapper, TraceQueryResultEntity> implements ITraceQueryResultService {

    @Override
    public TraceQueryResultEntity getTraceQueryResultByTraceId(String traceId) {
        LambdaQueryWrapper<TraceQueryResultEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(TraceQueryResultEntity::getTraceId, traceId);
        List<TraceQueryResultEntity> list = list(queryWrapper);
        if (CollectionUtils.isEmpty(list)) {
            return null;
        }
        return list.get(0);
    }
}
