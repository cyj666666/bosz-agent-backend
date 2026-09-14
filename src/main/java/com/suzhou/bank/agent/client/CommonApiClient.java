package com.suzhou.bank.agent.client;

import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpUtil;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.parser.Feature;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;

import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * 通用 HTTP 接口调用客户端
 *
 * <p>来源：amar-agent-server 的 {@code com.amarsoft.client.CommonApiClient}。
 * <b>用于「外部接口管理」的接口预览/试调</b>（{@code /extintf/intf/preview} 走它）。</p>
 *
 * <p><b>迁移改造点：HTTP 客户端换成 hutool（业务逻辑一字未改）</b></p>
 * <p>源实现用 Apache HttpClient（{@code CloseableHttpClient} + {@code HttpGet}/{@code HttpPost} +
 * {@code HttpClientUtils.getHttpClient()}）。宿主工程没有 Apache HttpClient 依赖，而 hutool 已在依赖里，
 * 故改用 {@link HttpUtil}/{@link HttpRequest} 表达同样的请求语义。</p>
 * <p>行为等价性说明：两者默认都不设超时（hutool 默认 {@code timeout=-1}，Apache 默认无超时），
 * 请求头/请求体/响应体的处理逐行对应，仅调用方式不同。</p>
 */
@Slf4j
@Repository
public class CommonApiClient {

    /**
     * 需要特殊处理响应的服务地址前缀（逗号分隔）
     *
     * <p>迁移改造点：配置键由源工程的 {@code coze.workflow.dataHandleUrl} 收敛到 agent 命名空间，
     * 默认空表示不做特殊处理。若需要该行为，在 application.yml 里配
     * {@code agent.common-api.data-handle-url}。</p>
     */
    @Value("${agent.common-api.data-handle-url:}")
    private String dataHandleUrl;

    private static final int HTTP_CODE_OK = 200;

    /**
     * 执行一次 HTTP 调用并返回 JSON 结果
     *
     * @param url          目标地址
     * @param transcode    接口编号（仅用于日志）
     * @param method       HTTP 方法，GET 或其它（其它一律按 POST 处理，与源实现一致）
     * @param params       请求体参数（POST 用）
     * @param headerParams 请求头
     * @param urlParams    URL 查询参数（GET 用）
     * @return 响应 JSON；失败时返回空 JSONObject（不抛异常，与源实现一致）
     */
    public JSONObject execute(String url, String transcode, String method, JSONObject params,
                              JSONObject headerParams, JSONObject urlParams) {
        log.info("请求接口[{}]，请求参数为:{}，请求服务器地址:{}", transcode, params.toJSONString(), url);
        long startTime = System.currentTimeMillis();
        JSONObject result = doExecute(url, method, params, headerParams, urlParams);
        long endTime = System.currentTimeMillis();
        log.info("请求接口[{}]调用完成，耗时：{}毫秒", transcode, (endTime - startTime));
        return result;
    }

    private JSONObject doExecute(String serviceUrl, String method, JSONObject requestParams,
                                 JSONObject headerParams, JSONObject urlParams) {
        if ("GET".equalsIgnoreCase(method)) {
            return doGet(serviceUrl, headerParams, urlParams);
        }
        return doPost(serviceUrl, requestParams, headerParams);
    }

    private JSONObject doGet(String serviceUrl, JSONObject headerParams, JSONObject urlParams) {
        // 拼接 URL 查询参数
        if (Objects.nonNull(urlParams) && !urlParams.isEmpty()) {
            StringBuffer queryString = new StringBuffer();
            Set<String> keySet = urlParams.keySet();
            for (String key : keySet) {
                if (queryString.length() > 0) {
                    queryString.append("&");
                }
                queryString.append(key).append("=").append(urlParams.getString(key));
            }
            serviceUrl += (serviceUrl.contains("?") ? "&" : "?") + queryString;
        }
        try {
            HttpRequest request = HttpUtil.createGet(serviceUrl);
            request.header("Content-Type", "application/json;charset=utf-8");
            if (Objects.nonNull(headerParams) && !headerParams.isEmpty()) {
                for (Map.Entry<String, Object> entry : headerParams.entrySet()) {
                    request.header(entry.getKey(), String.valueOf(entry.getValue()));
                }
            }
            cn.hutool.http.HttpResponse response = request.execute();
            String result = response.body();
            if (response.getStatus() != HTTP_CODE_OK) {
                log.error("http-get请求失败，状态码为{}，结果为{}", response.getStatus(), result);
            }
            return JSON.parseObject(result, Feature.OrderedField);
        } catch (Exception e) {
            log.error("请求异常：", e);
            return new JSONObject();
        }
    }

    private JSONObject doPost(String serviceUrl, JSONObject requestParams, JSONObject headerParams) {
        try {
            HttpRequest request = HttpUtil.createPost(serviceUrl);
            request.header("Content-Type", "application/json;charset=utf-8");
            if (Objects.nonNull(headerParams) && !headerParams.isEmpty()) {
                for (Map.Entry<String, Object> entry : headerParams.entrySet()) {
                    request.header(entry.getKey(), String.valueOf(entry.getValue()));
                }
            } else {
                request.header("Accept", "application/json");
            }
            request.body(requestParams.toJSONString());
            cn.hutool.http.HttpResponse response = request.execute();
            String result = response.body();
            if (response.getStatus() != HTTP_CODE_OK) {
                log.error("http-post请求失败，状态码为{}，结果为{}", response.getStatus(), result);
                return new JSONObject();
            }
            JSONObject object = JSON.parseObject(result, Feature.OrderedField);
            handleSpecialResponse(serviceUrl, object);
            return object;
        } catch (Exception e) {
            log.error("请求异常：", e);
            return new JSONObject();
        }
    }

    /**
     * 对特定服务地址的响应做结构适配（原样平移源实现逻辑）
     *
     * <p>当 {@code serviceUrl} 命中 {@code dataHandleUrl} 配置里的任一前缀时，
     * 把响应里的 {@code data} 拆成 {@code out_put} + {@code debug_url}。
     * 解析失败只记日志、不影响返回（与源实现一致）。</p>
     */
    private void handleSpecialResponse(String serviceUrl, JSONObject object) {
        try {
            if (StringUtils.isBlank(dataHandleUrl)) {
                return;
            }
            String[] split = dataHandleUrl.split(",");
            boolean isMatch = false;
            for (String s : split) {
                if (serviceUrl.startsWith(s)) {
                    isMatch = true;
                    break;
                }
            }
            if (!isMatch) {
                return;
            }
            String data = object.getString("data");
            if (Objects.nonNull(data)) {
                JSONObject dataObj = new JSONObject();
                dataObj.put("out_put", JSON.parseObject(data, Feature.OrderedField).get("output"));
                dataObj.put("debug_url", object.get("debug_url"));
                object.put("output", dataObj);
                object.remove("data");
            }
        } catch (Exception e) {
            log.error("解析工作流结果失败：{}", ExceptionUtils.getStackTrace(e));
        }
    }
}
