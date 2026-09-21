package com.suzhou.bank.service.report.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 信贷页面分享链接（getPageShareUrlN）配置（credit.share.*）
 *
 * <p>报告「溯源」内容块点击后实时获取一次性访问链接（不落库）。
 * 获取到的相对 url 需拼接当前环境的信贷基础地址（base-url）才是最终可访问地址；
 * 每个链接仅限使用一次、默认超时 1h，超时或用后需重新获取。</p>
 *
 * <p>⚠️ 消费方 = 信贷链接服务（行内 `CreditShareUrlService`）。**外网未接入 SSF（无 `AuthApi`）
 * ⇒ 该服务不在外网工程**，本配置在外网暂无消费方；保留是为了让两边**配置契约**
 * （键名 / 缺省语义）保持一致 —— 若外网最终不接 SSF，可随链接服务一起删除。</p>
 *
 * <p>🔴 本文件与行内/外网另一侧 **同包同路径、逐字同源**（2026-09-21 链接溯源行内外同步）。
 * 修改时请两边一起改。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@Component
@ConfigurationProperties(prefix = "credit.share")
public class CreditShareProperties {

    /**
     * 信贷基础地址（**按环境配置**，末尾带 /，如 `http://crcs-web-lb-sit.test:8080/crcs/`）。
     * 最终地址 = base-url + 信贷返回的相对 url。
     *
     * <p>🔴 2026-09-21：**故意不给默认值** —— 各环境信贷地址不同，必须配在
     * `application-{dev,uat,prod}.yml` 的 `credit.share.base-url`。
     * 漏配时换链接会 fail-fast 报错，**不会**静默拼出错误环境的地址。</p>
     */
    private String baseUrl;

    // 🔴 2026-09-21 口径调整：原 appCode / shareCode 两个配置项**已移除** ——
    //   · appCode 固定为 AIMP-PLMA（见 CreditShareUrlService.APP_CODE，代码级固定，不再走配置）
    //   · shareCode 改为**调用方入参**（报告侧取自「链接溯源」内容块的 agentCode，
    //     具体取值由信贷侧的 shareCode 配置表提供）
}
