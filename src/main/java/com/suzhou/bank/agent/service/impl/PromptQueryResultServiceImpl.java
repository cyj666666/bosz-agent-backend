package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.date.DateUtil;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.suzhou.bank.agent.entity.PromptQueryResultEntity;
import com.suzhou.bank.agent.mapper.PromptQueryResultMapper;
import com.suzhou.bank.agent.service.IPromptQueryResultService;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

/**
 * @Description: prompt请求结果记录表
 * @Author: jeecg-boot
 * @Date: 2024-08-14
 * @Version: V1.0
 */
@Service
public class PromptQueryResultServiceImpl extends ServiceImpl<PromptQueryResultMapper, PromptQueryResultEntity> implements IPromptQueryResultService {

    @Override
    public PromptQueryResultEntity getByTraceId(String traceId) {
        return baseMapper.selectOne(new LambdaQueryWrapper<PromptQueryResultEntity>().eq(PromptQueryResultEntity::getTraceId, traceId));
    }

    @Async
    @Override
    public void savePromptQueryResult(String moduleCode, JSONObject params, String paramStr, Object object, long costTime, String queryTime, String endTime, String traceId, String failReason) {
        PromptQueryResultEntity logEntity = new PromptQueryResultEntity();
        logEntity.setModuleCode(moduleCode);
        logEntity.setModuleName(params.getString("moduleName"));
        logEntity.setEntName(params.getString("entName"));
        logEntity.setIsMutiEnt(params.getString("isMutiEnt"));
        logEntity.setQueryParam(paramStr);
        logEntity.setQueryTime(queryTime);
        logEntity.setEndTime(endTime);
        logEntity.setComment("Agent逻辑处理！");
        logEntity.setResultMode("agent");
        logEntity.setQueryStatus("1");
        logEntity.setCostTime((int) costTime);
        logEntity.setQueryResult(JSONObject.toJSONString(object));
        logEntity.setTraceId(traceId);
        logEntity.setFailReason(failReason);
        baseMapper.insert(logEntity);
    }
}
