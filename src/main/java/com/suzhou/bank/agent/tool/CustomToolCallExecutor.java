package com.suzhou.bank.agent.tool;

import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpUtil;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.suzhou.bank.agent.config.AgentSpringContext;
import com.suzhou.bank.agent.entity.ToolManagementEntity;
import com.suzhou.bank.agent.model.req.ToolCallReq;
import lombok.extern.slf4j.Slf4j;

/**
 * 自定义工具调用执行器
 *
 * <p>来源：amar-agent-server 的 {@code CustomToolCallExecutor}。</p>
 *
 * <p><b>迁移改造点</b>：</p>
 * <ol>
 *   <li>HTTP 客户端 Apache HttpClient → hutool（宿主无前者，hutool 已在依赖里）；</li>
 *   <li>取配置由 Jeecg 的 {@code ApplicationContextUtil.getContext()} 换成 agent 自己的
 *       {@link AgentSpringContext}，去掉对 JeecgBoot 的依赖；配置键也收敛到 {@code agent.*} 命名空间；</li>
 *   <li>去掉源实现 {@code new JSONObject() {{ put(...) }}} 的双花括号匿名子类写法
 *       （会产生隐式外部类引用，Java 8 下易出推断问题）。</li>
 * </ol>
 */
@Slf4j
public class CustomToolCallExecutor implements ToolCallExecutor {

    @Override
    public Object execute(ToolCallReq toolCallReq, ToolManagementEntity toolManagementEntity) throws Exception {
        // 构建工具调用服务请求体
        JSONObject requestBody = new JSONObject(toolCallReq.getParams());
        requestBody.fluentPut("trace_id", toolCallReq.getId())
                .fluentPut("group", toolManagementEntity.getToolCategory())
                .fluentPut("name", toolCallReq.getMethod());
        // 调用工具服务
        String serviceUrl = AgentSpringContext.getApplicationContext().getEnvironment()
                .getProperty("agent.tool.service-url", "http://172.20.2.102:38002/public/callTool");
        log.info("开始调用工具服务，工具名称：{}，参数：{}，地址：{}", toolCallReq.getMethod(), requestBody, serviceUrl);
        JSONObject result = new JSONObject();
        result.put("content", "");
        try {
            HttpRequest request = HttpUtil.createPost(serviceUrl)
                    .header("Content-Type", "application/json")
                    .body(requestBody.toJSONString(), "application/json;charset=utf-8");
            cn.hutool.http.HttpResponse response = request.execute();
            if (response.getStatus() == 200) {
                JSONObject resultJson = JSON.parseObject(response.body());
                if (resultJson != null && resultJson.get("code") != null && resultJson.get("code").equals(200)) {
                    result.put("content", resultJson.get("data"));
                }
            }
            log.info("调用工具服务完成，http状态码为：{}", response.getStatus());
        } catch (Exception e) {
            // 与源实现一致：调用失败只记日志、返回空 content，不向上抛（工具调用失败不该中断整条链路）
            log.error("调用工具服务异常", e);
        }
        return result;
    }
}
