package com.suzhou.bank.controller;

import com.suzhou.bank.common.Result;
import com.suzhou.bank.service.CreditTokenService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 信贷系统跳转 Token 接口
 * <p>独立于现有登录认证（JWT 拦截器）之外，供信贷系统调用：
 * <ul>
 *   <li>{@code POST /api/credit/token} 传入操作人 userNo（用户账号，sys_user.username，String），签发 4 小时有效 token；</li>
 *   <li>{@code GET /api/credit/resolve?cipher=} 用户点击跳转链接后，前端把 URL 中的
 *       SM4 密文传给本接口，后端解密并校验 token、透传业务参数（customerId 等）。</li>
 *   <li>{@code POST /api/credit/sm4} SM4 加解密测试接口，供信贷系统联调校验密钥/算法一致性。</li>
 * </ul>
 * 客户ID 等业务参数由信贷侧用 SM4 加密后拼入 URL，不进 token。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@RestController
@RequestMapping("/api/credit")
@RequiredArgsConstructor
public class CreditTokenController {

    private final CreditTokenService creditTokenService;

    /**
     * 签发信贷跳转访问 token（按操作人 userNo，用户账号，String）
     *
     * @param body { userNo }
     * @return { token, userNo, expiresInSeconds }
     */
    @PostMapping("/token")
    public Result<Map<String, Object>> token(@RequestBody Map<String, String> body) {
        try {
            return Result.ok(creditTokenService.issueToken(body.get("userNo")));
        } catch (RuntimeException e) {
            return Result.fail(400, e.getMessage());
        }
    }

    /**
     * 解析跳转链接：SM4 解密 + 校验 token + 透传业务参数
     *
     * @param cipher URL 中的 SM4 密文（token+业务参数，Base64）
     * @return { token, username, realName, roles, expiresInSeconds, customerId, ... }
     */
    @GetMapping("/resolve")
    public Result<Map<String, Object>> resolve(@RequestParam String cipher) {
        try {
            return Result.ok(creditTokenService.resolve(cipher));
        } catch (RuntimeException e) {
            return Result.fail(400, e.getMessage());
        }
    }

    /**
     * SM4 加解密测试接口（供信贷系统联调，校验密钥/算法一致性）
     * <p>传 {@code plain} 则返回加密后的 Base64 密文；传 {@code cipher} 则返回解密后的明文。
     * 两者都传则同时返回。算法：SM4/ECB/PKCS7，密钥为 UTF-8 文本，输出 Base64。</p>
     *
     * 信贷需要传入的sm4加密参数
     * userNo：用户账号
     * checkTaskNo：日检任务编号
     * isReSubmit：是否支持重跑
     * isRiskApply：是否支持发起预警（预留字段）
     * token：贷后智能体token
     *
     * @param body { plain?, cipher? }
     * @return { plain?, cipher? }（对应传入的项）
     */
    @PostMapping("/sm4")
    public Result<Map<String, Object>> sm4(@RequestBody Map<String, String> body) {
        String plain = body.get("plain");
        String cipher = body.get("cipher");
        if ((plain == null || plain.trim().isEmpty()) && (cipher == null || cipher.trim().isEmpty())) {
            return Result.fail(400, "plain 与 cipher 至少传一个");
        }
        try {
            Map<String, Object> result = new LinkedHashMap<>();
            if (plain != null && !plain.trim().isEmpty()) {
                result.put("cipher", creditTokenService.sm4Encrypt(plain));
                result.put("plain", plain);
            }
            if (cipher != null && !cipher.trim().isEmpty()) {
                result.put("plain", creditTokenService.sm4Decrypt(cipher));
                result.put("cipher", cipher);
            }
            return Result.ok(result);
        } catch (RuntimeException e) {
            return Result.fail(400, e.getMessage());
        }
    }
}
