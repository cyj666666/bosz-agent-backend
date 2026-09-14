package com.suzhou.bank.agent.tool;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.config.AgentSpringContext;
import com.suzhou.bank.agent.entity.ToolManagementEntity;
import com.suzhou.bank.agent.model.req.ToolCallReq;
import com.suzhou.bank.agent.service.IknowledgeBaseConfigService;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * 基于知识库调用的工具封装
 * @author dwyang
 * @since 2026/02/05
 */
@Slf4j
public class KnowledgeToolCallExecutor implements ToolCallExecutor{
    @Override
    public Object execute(ToolCallReq toolCallReq, ToolManagementEntity toolManagementEntity) throws Exception {
        JSONObject requestBody = buildRequestBody(toolCallReq, toolManagementEntity);
        SseEmitter emitter = new SseEmitter(0L);
        IknowledgeBaseConfigService knowledgeBaseConfigService = AgentSpringContext.getBean(IknowledgeBaseConfigService.class);
        return knowledgeBaseConfigService.getPromptContent(requestBody.toJSONString(), emitter);
    }

    private JSONObject buildRequestBody(ToolCallReq toolCallReq, ToolManagementEntity toolManagementEntity) {
        String toolParameters = toolManagementEntity.getToolParameters();
        if (StringUtils.isBlank(toolParameters)) {
            throw new IllegalArgumentException("工具参数不能为空");
        }
        //工具参数配置，json数组格式,每个元素对象对应一个工具参数定义
        JSONArray toolParametersArray = JSON.parseArray(toolParameters);
        //构建知识库工具调用参数
        JSONObject requestParams = new JSONObject(true){{
            put("moduleCode", toolManagementEntity.getModuleCode());
            put("stream", toolCallReq.isStream());
        }};
        if (toolManagementEntity.getImplType().equals(ToolCallTypeEnum.APPLY_PROMPT.getType())) {
            requestParams.put("withModelSummary", true);
        } else {
            requestParams.put("withModelSummary", toolCallReq.isWithModelSummary());
        }
        toolParametersArray.forEach(item -> {
            JSONObject paramItem = (JSONObject) item;
            String paramName = paramItem.getString("name");
            String requestParamName = paramName;
            if (requestParamName.contains(".")) {
                //调用知识库的参数，有类似params.xxx的格式，去掉params前缀
                requestParamName = requestParamName.substring(requestParamName.indexOf(".") + 1);
            }
            Object paramValue = toolCallReq.getParams().get(requestParamName);
            if (paramValue == null) {
                //接口没有传，检查是否配置了默认值
                paramValue = paramItem.get("default");
                if (paramValue != null && StringUtils.isNotBlank(paramValue.toString())) {
                    requestParams.put(paramName, paramValue);
                }
            } else {
                requestParams.put(paramName, paramValue);
            }
        });

        return requestParams;
    }

}
