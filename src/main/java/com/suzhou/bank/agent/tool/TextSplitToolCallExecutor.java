package com.suzhou.bank.agent.tool;

import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpUtil;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.suzhou.bank.agent.config.AgentSpringContext;
import com.suzhou.bank.agent.entity.ToolManagementEntity;
import com.suzhou.bank.agent.model.req.ToolCallReq;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.exception.ExceptionUtils;

/**
 * 文本拆分工具调用执行器
 *
 * <p>来源：amar-agent-server 的 {@code TextSplitToolCallExecutor}。</p>
 *
 * <p><b>迁移改造点</b>：</p>
 * <ol>
 *   <li><b>okhttp3 → hutool</b>。源实现依赖 okhttp3，并通过 {@code HttpCallingAwareService}
 *       （一个 okhttp 连接池惰性初始化接口）拿 client。宿主无 okhttp 依赖，改为 hutool 直接发请求，
 *       原 okhttp 的四类超时（连接 10s / 读 10min / 写 30s / 调用 2h）收敛为 hutool 的
 *       {@code timeout(读超时)}——文本拆分是短请求，10 分钟读超时足够覆盖；
 *       故 {@code HttpCallingAwareService} 不再需要移植。</li>
 *   <li>取配置由 Jeecg 的 {@code ApplicationContextUtil} 换成 {@link AgentSpringContext}，
 *       配置键收敛为 {@code agent.divide.service-url}。</li>
 * </ol>
 */
@Slf4j
public class TextSplitToolCallExecutor implements ToolCallExecutor {

    /** 文本拆分服务读超时（毫秒） */
    private static final int READ_TIMEOUT_MILLIS = 10 * 60 * 1000;

    @Override
    public Object execute(ToolCallReq toolCallReq, ToolManagementEntity toolManagementEntity) throws Exception {
        JSONObject requestBodyJson = new JSONObject(toolCallReq.getParams());

        String serviceUrl = AgentSpringContext.getApplicationContext().getEnvironment()
                .getProperty("agent.divide.service-url", "http://10.3.10.191:21946");
        String url = serviceUrl + "/" + toolCallReq.getMethod();
        log.info("开始调用文本拆分服务，工具名称：{}，参数：{}，地址：{}", toolCallReq.getMethod(), requestBodyJson, url);

        try {
            HttpRequest request = HttpUtil.createPost(url)
                    .header("Content-Type", "application/json")
                    .body(JSON.toJSONString(requestBodyJson), "application/json;charset=utf-8")
                    .timeout(READ_TIMEOUT_MILLIS);
            cn.hutool.http.HttpResponse response = request.execute();
            if (response.getStatus() == 200) {
                return JSON.parseObject(response.body());
            }
            log.error("调用文本拆分服务失败，状态码：{}，响应：{}", response.getStatus(), response.body());
        } catch (Exception e) {
            // 与源实现一致：失败只记日志、返回 null
            log.error("调用文本拆分服务失败，异常信息：{}", ExceptionUtils.getStackTrace(e));
        }
        return null;
    }
}
