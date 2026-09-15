package com.suzhou.bank.agent.util;

import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpUtil;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.parser.Feature;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;

import javax.annotation.PostConstruct;
import javax.crypto.Cipher;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * 外部接口调用客户端（带加签与 AES 加解密）
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.util.APIClient}。
 * 用于「外部接口管理」执行被配置的 HTTP 接口，以及指标取数时的接口型数据源调用。</p>
 *
 * <p><b>迁移改造点 1：HTTP 客户端换成 hutool</b>（业务逻辑与加解密算法一字未改）</p>
 * <p>源实现用 Apache HttpClient，宿主工程没有该依赖而 hutool 已在依赖里，故改用
 * {@link HttpUtil}/{@link HttpRequest}。</p>
 *
 * <p><b>迁移改造点 2：硬编码的 serverCode / secret 已移除</b></p>
 * <p>源实现把它们写死在类里：</p>
 * <pre>
 *   private static final String serverCode = "BANK_AS";
 *   private static final String secret     = "&lt;一串 Base64 编码的密钥&gt;";
 * </pre>
 * <p>这是<b>厂商侧的外部服务凭据</b>（用于给外部接口的报文加密 + 加签），硬编码在源码里有两个问题：
 * 换环境要改代码、且凭据随源码扩散。本工程改为配置项：</p>
 * <pre>
 *   agent.ext-intf.server-code: &lt;向行内/公司索取&gt;
 *   agent.ext-intf.secret:      &lt;向行内/公司索取&gt;
 * </pre>
 * <p><b>未配置时不会导致应用起不来</b>，但调用外部接口会失败并打 WARN——
 * 这样密钥不再进代码库，同时把"没配"这件事显式暴露出来。</p>
 */
@Slf4j
@Repository
public class APIClient {

    /** 外部服务标识（原实现硬编码为 BANK_AS，此处改为配置项） */
    @Value("${agent.ext-intf.server-code:}")
    private String serverCode;

    /** 外部服务密钥，Base64 编码（原实现硬编码，此处改为配置项） */
    @Value("${agent.ext-intf.secret:}")
    private String secret;

    @PostConstruct
    public void checkConfig() {
        if (StringUtils.isBlank(serverCode) || StringUtils.isBlank(secret)) {
            log.warn("agent 外部接口调用的 server-code / secret 未配置"
                    + "（agent.ext-intf.server-code / agent.ext-intf.secret），"
                    + "「外部接口预览」等调用外部服务的功能将不可用。"
                    + "如需启用，请向公司索取外部服务凭据后配置。"
                    + "注：源工程把这两个值硬编码在代码里，本工程刻意不再固化为常量。");
        }
    }

    /**
     * 发送外部接口请求（加签 + 请求体加密 + 响应解密）
     *
     * @param intfNo 接口编号（仅用于日志）
     * @param url    目标地址
     * @param params 业务参数
     * @return 响应 JSON；失败返回空 JSONObject
     */
    public JSONObject sendRequest(String intfNo, String url, JSONObject params) {
        log.info("请求接口[{}]，请求参数为:{}，请求服务器地址:{}", intfNo, params.toJSONString(), url);
        if (StringUtils.isBlank(serverCode) || StringUtils.isBlank(secret)) {
            log.warn("外部服务凭据未配置，跳过接口调用：{}", intfNo);
            return new JSONObject();
        }
        Map<String, Object> paramMaps = new HashMap<>();
        params.keySet().forEach(key -> paramMaps.put(key, params.get(key)));
        // 对参数进行加密
        Map<String, Object> encryptMaps = encryptMapValues(paramMaps, secret);
        long timestamp = System.currentTimeMillis();
        String body = JSONObject.toJSONString(encryptMaps);
        long startTime = System.currentTimeMillis();
        try {
            HttpRequest request = HttpUtil.createPost(url);
            request.header("Content-Type", "application/json");
            request.header("Accept", "application/json");
            request.header("server_code", serverCode);
            request.header("signature", generateSignature(serverCode, secret, mapToString(encryptMaps), timestamp));
            request.header("timestamp", String.valueOf(timestamp));
            request.body(body, "application/json;charset=utf-8");

            cn.hutool.http.HttpResponse response = request.execute();
            int status = response.getStatus();
            String result = response.body();
            if (status != 200) {
                log.error("http请求失败，状态码为{}，结果为{}", status, result);
                return new JSONObject();
            }
            // 进行解密
            JSONObject jsonObject = JSON.parseObject(result, Feature.OrderedField);
            String responseCipherText = jsonObject.getString("data");
            if (Objects.isNull(responseCipherText)) {
                return jsonObject;
            }
            JSONObject parsedObject = JSON.parseObject(decryptECB(responseCipherText, secret));
            if (Objects.isNull(parsedObject) || parsedObject.isEmpty()) {
                return jsonObject;
            }
            String extraInfo = parsedObject.getString("extraInfo");
            if (StringUtils.isNotEmpty(extraInfo)) {
                parsedObject.put("extraInfo", JSONObject.parseObject(extraInfo));
            }
            jsonObject.put("data", parsedObject);
            long endTime = System.currentTimeMillis();
            log.info("请求接口[{}]调用完成，耗时：{}毫秒", intfNo, (endTime - startTime));
            return jsonObject;
        } catch (Exception e) {
            log.error("请求异常：", e);
            return new JSONObject();
        }
    }

    /**
     * 加签操作
     *
     * @param serverCode  服务标识
     * @param secret      密钥（Base64）
     * @param requestBody 请求体字符串
     * @param timestamp   时间戳
     * @return 签名（Base64）
     */
    public static String generateSignature(String serverCode, String secret, String requestBody, long timestamp) {
        try {
            String data = serverCode + requestBody + timestamp;
            byte[] secretBytes = Base64.getDecoder().decode(secret);
            SecretKeySpec secretKey = new SecretKeySpec(secretBytes, "HmacSHA256");
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(secretKey);
            byte[] signatureBytes = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(signatureBytes);
        } catch (Exception e) {
            return null;
        }
    }

    /** 将参数值逐个加密 */
    public static Map<String, Object> encryptMapValues(Map<String, Object> params, String secret) {
        Map<String, Object> encryptedParams = new HashMap<>();
        for (Map.Entry<String, Object> entry : params.entrySet()) {
            String value = entry.getValue().toString();
            String encryptedValue = encryptECB(value, secret);
            encryptedParams.put(entry.getKey(), encryptedValue);
        }
        return encryptedParams;
    }

    /** 将参数值逐个解密 */
    public static Map<String, Object> decryptMapValues(Map<String, Object> params, String secret) {
        Map<String, Object> encryptedParams = new HashMap<>();
        for (Map.Entry<String, Object> entry : params.entrySet()) {
            String value = entry.getValue().toString();
            String encryptedValue = decryptECB(value, secret);
            encryptedParams.put(entry.getKey(), encryptedValue);
        }
        return encryptedParams;
    }

    /**
     * AES 的 ECB 模式加密
     *
     * <p>WARNING: ECB mode is insecure. {@code Cipher.getInstance("AES")} 默认是
     * AES/ECB/PKCS5Padding。新开发请用 CBC 或 GCM。本方法为兼容既有外部服务协议而保留。</p>
     *
     * @deprecated 沿用源实现，仅为协议兼容；新接口请用 CBC/GCM
     */
    @Deprecated
    public static String encryptECB(String data, String secret) {
        if (StringUtils.isEmpty(secret)) {
            throw new IllegalArgumentException("加密失败,加密密钥为空");
        }
        byte[] secretBytes = Base64.getDecoder().decode(secret.getBytes(StandardCharsets.UTF_8));
        SecretKeySpec aesKey = new SecretKeySpec(secretBytes, "AES");
        try {
            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.ENCRYPT_MODE, aesKey);
            byte[] encrypted = cipher.doFinal(data.getBytes(Charset.forName("UTF-8")));
            return Base64.getEncoder().encodeToString(encrypted);
        } catch (Exception e) {
            throw new IllegalArgumentException("加密失败: " + e.getMessage());
        }
    }

    /**
     * AES 的 ECB 模式解密
     *
     * @deprecated 沿用源实现，仅为协议兼容；新接口请用 CBC/GCM
     */
    @Deprecated
    public static String decryptECB(String data, String secret) {
        if (StringUtils.isEmpty(secret)) {
            throw new IllegalArgumentException("解密失败，解密 secret 为空");
        }
        byte[] decode = Base64.getDecoder().decode(data.getBytes(StandardCharsets.UTF_8));
        byte[] secretBytes = Base64.getDecoder().decode(secret.getBytes(StandardCharsets.UTF_8));
        SecretKeySpec aesKey = new SecretKeySpec(secretBytes, "AES");
        try {
            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.DECRYPT_MODE, aesKey);
            return new String(cipher.doFinal(decode), StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalArgumentException("解密失败: " + e.getMessage());
        }
    }

    /** 将参数 map 按 key 排序后拼成 {@code k=v&k2=v2} 形式（签名用） */
    private static String mapToString(Map<String, Object> params) {
        Set<String> keysSet = params.keySet();
        Object[] keys = keysSet.toArray();
        Arrays.sort(keys);
        StringBuffer temp = new StringBuffer();
        boolean first = true;
        for (Object key : keys) {
            if (first) {
                first = false;
            } else {
                temp.append("&");
            }
            temp.append(key).append("=");
            Object value = params.get(key);
            String valueString = "";
            if (null != value) {
                valueString = String.valueOf(value);
            }
            temp.append(valueString);
        }
        return temp.toString();
    }
}
