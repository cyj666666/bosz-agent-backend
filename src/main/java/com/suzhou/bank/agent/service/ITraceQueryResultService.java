package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.entity.TraceQueryResultEntity;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * @Description: 溯源查询结果表
 * @Author: jeecg-boot
 * @Date:   2024-11-21
 * @Version: V1.0
 */
public interface ITraceQueryResultService extends IService<TraceQueryResultEntity> {

    TraceQueryResultEntity getTraceQueryResultByTraceId(String traceId);
}
