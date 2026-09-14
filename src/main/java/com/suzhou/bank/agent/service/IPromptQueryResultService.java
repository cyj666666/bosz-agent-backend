package com.suzhou.bank.agent.service;

import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.PromptQueryResultEntity;

/**
 * @Description: prompt请求结果记录表
 * @Author: jeecg-boot
 * @Date:   2024-08-14
 * @Version: V1.0
 */
public interface IPromptQueryResultService extends IService<PromptQueryResultEntity> {

    PromptQueryResultEntity getByTraceId(String traceId);

    void savePromptQueryResult(String moduleCode, JSONObject params, String paramStr, Object object, long costTime, String queryTime, String endTime, String traceId, String failReason);
}
