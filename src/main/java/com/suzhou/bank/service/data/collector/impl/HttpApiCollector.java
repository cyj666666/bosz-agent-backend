package com.suzhou.bank.service.data.collector.impl;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import com.suzhou.bank.entity.CollectorConfig;
import com.suzhou.bank.service.data.collector.DataCollector;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.URL;
import java.nio.charset.StandardCharsets;

/**
 * HTTP API 采集器
 * <p>对接外部数据平台的 REST API，发送 GET/POST 请求获取 JSON 数据。
 * 适用于天眼查、企查查、税务 API 等外部数据源。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Component
public class HttpApiCollector implements DataCollector {

    @Override
    public String getType() {
        return "HTTP_API";
    }

    @Override
    public String collect(CollectorConfig config, Long customerId) {
        JSONObject cfg = JSON.parseObject(config.getConfigJson());
        String url = cfg.getString("url");
        String method = cfg.getString("method");
        JSONObject headers = cfg.getJSONObject("headers");
        JSONObject params = cfg.getJSONObject("params");

        // SSRF 防护：校验目标 URL 不指向内网地址
        validateUrl(url);

        if ("POST".equalsIgnoreCase(method)) {
            return doPost(url, headers, params);
        }
        return doGet(url, headers, params);
    }

    /**
     * SSRF 防护：校验 URL 目标地址不在内网，并防御 DNS 重绑定攻击。
     */
    private void validateUrl(String urlStr) {
        try {
            URL url = new URL(urlStr);
            String host = url.getHost();
            InetAddress[] allAddrs = InetAddress.getAllByName(host);
            for (InetAddress addr : allAddrs) {
                if (addr.isLoopbackAddress() || addr.isLinkLocalAddress()
                        || addr.isSiteLocalAddress() || addr.isAnyLocalAddress()) {
                    log.error("SSRF 拦截: 目标地址解析到内网地址, ip={}", addr.getHostAddress());
                    throw new SecurityException("不允许访问内网地址");
                }
            }
        } catch (SecurityException e) {
            throw e;
        } catch (Exception e) {
            log.error("URL 校验失败, url={}", maskUrl(urlStr), e);
            throw new RuntimeException("无效的采集 URL，请检查配置", e);
        }
    }

    /**
     * 脱敏 URL 中的敏感参数，避免密钥泄露到日志。
     */
    private String maskUrl(String urlStr) {
        if (urlStr == null) return null;
        // 替换查询参数中的敏感值
        String[] sensitiveKeys = {"apikey", "api_key", "token", "access_token",
                "secret", "password", "passwd", "key", "auth", "sign", "signature"};
        String masked = urlStr;
        for (String key : sensitiveKeys) {
            masked = masked.replaceAll("(?i)[?&]" + key + "=[^&]*", "&" + key + "=***");
        }
        return masked;
    }

    /**
     * 用 IP 替换主机名建立连接，消除 DNS 重绑定窗口。
     * HTTPS 时保留原始 Host 头保证 SNI 和证书校验正确。
     */
    private HttpURLConnection openConnection(String urlStr, boolean isHttps) throws Exception {
        URL originalUrl = new URL(urlStr);
        String host = originalUrl.getHost();
        InetAddress addr = InetAddress.getByName(host);
        String ip = addr.getHostAddress();

        URL safeUrl = new URL(originalUrl.getProtocol(), ip, originalUrl.getPort(),
                originalUrl.getFile() != null && !originalUrl.getFile().isEmpty()
                        ? originalUrl.getFile() : "/");
        HttpURLConnection conn = (HttpURLConnection) safeUrl.openConnection();
        // 非 HTTPS 时设 Host 头确保虚拟主机正确路由
        if (!isHttps) {
            conn.setRequestProperty("Host", originalUrl.getHost());
        }
        conn.setInstanceFollowRedirects(false); // 禁止自动重定向
        return conn;
    }

    private String doGet(String baseUrl, JSONObject headers, JSONObject params) {
        try {
            String fullUrl = buildUrl(baseUrl, params);
            boolean isHttps = fullUrl.startsWith("https");
            HttpURLConnection conn = openConnection(fullUrl, isHttps);
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(30000);
            if (headers != null) {
                headers.forEach((k, v) -> conn.setRequestProperty(k, String.valueOf(v)));
            }

            StringBuilder sb = new StringBuilder();
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = br.readLine()) != null) {
                    sb.append(line);
                }
            }
            log.info("HTTP_API 采集完成, url={}, responseSize={}", maskUrl(baseUrl), sb.length());
            return sb.toString();
        } catch (Exception e) {
            log.error("HTTP_API 采集失败, url={}", maskUrl(baseUrl), e);
            throw new RuntimeException("HTTP_API 采集失败，请检查配置", e);
        }
    }

    private String doPost(String url, JSONObject headers, JSONObject params) {
        try {
            boolean isHttps = url.startsWith("https");
            HttpURLConnection conn = openConnection(url, isHttps);
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(30000);
            conn.setRequestProperty("Content-Type", "application/json");
            if (headers != null) {
                headers.forEach((k, v) -> conn.setRequestProperty(k, String.valueOf(v)));
            }
            if (params != null) {
                byte[] body = params.toJSONString().getBytes(StandardCharsets.UTF_8);
                conn.getOutputStream().write(body);
            }

            StringBuilder sb = new StringBuilder();
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = br.readLine()) != null) {
                    sb.append(line);
                }
            }
            log.info("HTTP_API 采集完成(POST), url={}, responseSize={}", maskUrl(url), sb.length());
            return sb.toString();
        } catch (Exception e) {
            log.error("HTTP_API 采集失败, url={}", maskUrl(url), e);
            throw new RuntimeException("HTTP_API 采集失败，请检查配置", e);
        }
    }

    private String buildUrl(String baseUrl, JSONObject params) {
        if (params == null || params.isEmpty()) return baseUrl;
        StringBuilder sb = new StringBuilder(baseUrl);
        sb.append(baseUrl.contains("?") ? "&" : "?");
        params.forEach((k, v) -> sb.append(k).append("=").append(v).append("&"));
        return sb.substring(0, sb.length() - 1);
    }

    @Override
    public boolean validateConfig(String configJson) {
        try {
            JSONObject cfg = JSON.parseObject(configJson);
            return cfg.containsKey("url") && cfg.containsKey("method");
        } catch (Exception e) {
            return false;
        }
    }
}
