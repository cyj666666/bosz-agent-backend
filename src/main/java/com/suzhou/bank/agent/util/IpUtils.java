package com.suzhou.bank.agent.util;

import org.apache.commons.lang3.StringUtils;

import javax.servlet.http.HttpServletRequest;

/**
 * HTTP 请求工具
 *
 * <p>替代源工程的 {@code org.jeecg.common.util.IPUtils}（只用到取 IP 这一项能力）。</p>
 *
 * <p>代理头按优先级依次尝试，与源工程一致：多次代理时 X-Forwarded-For 是逗号分隔列表，取第一段。</p>
 */
public class IpUtils {

    private static final String UNKNOWN = "unknown";

    private static final String[] IP_HEADERS = {
            "X-Forwarded-For",
            "X-Real-IP",
            "Proxy-Client-IP",
            "WL-Proxy-Client-IP",
            "HTTP_CLIENT_IP",
            "HTTP_X_FORWARDED_FOR"
    };

    /**
     * 取客户端 IP
     *
     * @param request 当前请求，可为 null（非 HTTP 线程）
     * @return IP 字符串；取不到时返回 {@code ""}
     */
    public static String getIpAddr(HttpServletRequest request) {
        if (request == null) {
            return "";
        }
        for (String header : IP_HEADERS) {
            String ip = request.getHeader(header);
            if (StringUtils.isNotBlank(ip) && !UNKNOWN.equalsIgnoreCase(ip)) {
                int idx = ip.indexOf(',');
                return idx > 0 ? ip.substring(0, idx).trim() : ip.trim();
            }
        }
        return StringUtils.defaultString(request.getRemoteAddr());
    }
}
