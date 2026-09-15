package com.suzhou.bank.agent.client;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.parser.Feature;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.util.JSONTools;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;

/**
 * hubservice云服务客户端
 */
@Repository
@Slf4j
public class HubApiClient {

    @Value("${hubservice.api.url:}")
    private String hubApiUrl;

    @Value("${hubservice.api.account:}")
    private String hubApiAccount;

    public ApiResult callS1101(String transcode, JSONObject params) {
        String requestParam = handleS1101Param(transcode, params);
        log.info("请求接口transcode=[{}]，请求参数为:{}", transcode, requestParam);
        long startTime = System.currentTimeMillis();
        JSONObject result = execute(hubApiUrl, requestParam);
        long endTime = System.currentTimeMillis();
        log.info("接口transcode=[{}]调用完成，耗时：{}毫秒", transcode, (endTime - startTime));
        if ("B118".equals(transcode)) {
            JSONArray jsonResult = new JSONArray();
            jsonResult.add(result);
            ApiResult apiResult = new ApiResult(true, jsonResult);
            return apiResult;
        }
        return handleResult(transcode, result);
    }

    /**
     * 入口
     *
     * @param transcode 接口编号
     * @param params    请求参数
     * @return
     */
    public ApiResult execute(String transcode, JSONObject params) {
        String requestParam = handleParam(transcode, params);
        log.info("请求接口transcode=[{}]，请求参数为:{}", transcode, requestParam);
        long startTime = System.currentTimeMillis();
        JSONObject result = execute(hubApiUrl, requestParam);
        long endTime = System.currentTimeMillis();
        log.info("接口transcode=[{}]调用完成，耗时：{}毫秒", transcode, (endTime - startTime));
        if ("B118".equals(transcode)) {
            JSONArray jsonResult = new JSONArray();
            jsonResult.add(result);
            ApiResult apiResult = new ApiResult(true, jsonResult);
            return apiResult;
        }
        ApiResult apiResult = handleResult(transcode, result);
        return apiResult;
    }


    /**
     * 组装请求参数
     *
     * @param transcode 接口编号
     * @param params    请求参数
     * @return
     */
    private String handleParam(String transcode, JSONObject params) {
        JSONObject requestParam = new JSONObject();
        requestParam.put("transcode", transcode);
        requestParam.put("source", "EDS");
        String userId = JSONTools.getString(params, "userid");
        if (StringUtils.isBlank(userId)) {
            userId = "EDS";
        }
        requestParam.put("userid", userId);
        String bankId = JSONTools.getString(params, "orgId");
        ;
        if (StringUtils.isBlank(bankId)) {
            bankId = "EDS";
        }
        requestParam.put("orgid", bankId);
        String account = transcode.startsWith("B309") ? "SPDbank" : hubApiAccount;
        requestParam.put("account", account);
        requestParam.put("params", params);

        return requestParam.toJSONString();
    }

    /**
     * 请求服务器
     *
     * @param requestParams 请求参数
     * @return
     */
    private JSONObject execute(String serviceUrl, String requestParams) {
        log.info("======>开始请求服务器地址：" + serviceUrl + "<======");
        // 迁移改造点：源实现用 Apache HttpClient（HttpClientUtils.getHttpClient()），
        // 宿主无该依赖、hutool 已在依赖里，故改用 hutool 表达同样的请求语义（默认都无超时）。
        try {
            cn.hutool.http.HttpResponse response = cn.hutool.http.HttpUtil.createPost(serviceUrl)
                    .header("Content-Type", "application/json;charset=utf-8")
                    .header("Accept", "application/json")
                    .body(requestParams, "application/json;charset=utf-8")
                    .execute();
            String result = response.body();
            if (response.getStatus() != 200) {
                log.error("http请求失败，状态码为{}，结果为{}", response.getStatus(), result);
                return new JSONObject();
            }
            return JSON.parseObject(result, Feature.OrderedField);
        } catch (Exception e) {
            log.error("请求异常：", e);
            return new JSONObject();
        }
    }

    private boolean isSuccess(JSONObject result) {
        if (result == null || result.isEmpty()) {
            return false;
        }

        String code = result.getString("code");
        return !StringUtils.isBlank(code) && "0000".equals(code);
    }

    private String handleS1101Param(String transcode, JSONObject params) {
        JSONObject requestParam = new JSONObject();
        requestParam.put("transcode", "S1101");
        requestParam.put("serviceCode", transcode);
        requestParam.put("source", "EDS");
        String userId = JSONTools.getString(params, "userid");
        if (StringUtils.isBlank(userId)) {
            userId = "EDS";
        }
        requestParam.put("userid", userId);
        String bankId = JSONTools.getString(params, "orgId");
        ;
        if (StringUtils.isBlank(bankId)) {
            bankId = "EDS";
        }
        requestParam.put("orgid", bankId);
        requestParam.put("account", hubApiAccount);
        JSONTools.setSimilarValue(params, "clientId", hubApiAccount);
        requestParam.put("params", params);

        return requestParam.toJSONString();
    }

    private ApiResult handleResult(String transcode, JSONObject result) {
        if (result == null) {
            return new ApiResult(false, "调用远程服务接口[" + transcode + "]失败");
        }
        if (!isSuccess(result)) {
            log.error("======>接口编号[{}]调用失败<======", transcode);
            return new ApiResult(false, JSONTools.getString(result, "msg"));
        }
        Integer totalCount = result.getInteger("totalCount") == null ? 0 : result.getInteger("totalCount");
        Integer totalPage = result.getInteger("totalPage");
        ApiResult apiResult = new ApiResult(true, result.getJSONArray("data"), totalCount, totalPage);
        apiResult.setPageIndex(result.getInteger("pageIndex"));
        return apiResult;
    }

    @Data
    public static class ApiResult {

        private boolean isSuccess;

        private JSONArray datas;

        private String message = "接口调用成功";

        private Integer totalCount;

        private Integer totalPage;

        private Integer pageIndex;

        public ApiResult(boolean isSuccess, JSONArray datas) {
            this.isSuccess = isSuccess;
            this.datas = datas;
        }

        public ApiResult(boolean success, String message) {
            this.isSuccess = success;
            this.message = message;
            this.datas = new JSONArray(0);
        }

        public ApiResult(boolean isSuccess, JSONArray datas, Integer totalCount) {
            this.isSuccess = isSuccess;
            this.datas = datas;
            this.totalCount = totalCount;
        }

        public ApiResult(boolean isSuccess, JSONArray datas, Integer totalCount, Integer totalPage) {
            this.isSuccess = isSuccess;
            this.datas = datas;
            this.totalCount = totalCount;
            this.totalPage = totalPage;
        }

        public ApiResult(boolean isSuccess, JSONArray datas, Integer totalCount, Integer totalPage, Integer pageIndex) {
            this.isSuccess = isSuccess;
            this.datas = datas;
            this.totalCount = totalCount;
            this.totalPage = totalPage;
            this.pageIndex = pageIndex;
        }

        public ApiResult(boolean isSuccess, JSONArray datas, Integer totalCount, int totalPage, String repCode, String repDesc, String packageIndex, int total, String repContent) {
            super();
            this.isSuccess = isSuccess;
            this.datas = datas;
            this.totalCount = totalCount;
            this.totalPage = totalPage;
        }
    }
}