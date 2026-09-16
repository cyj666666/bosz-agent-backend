package com.suzhou.bank.service;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import com.suzhou.bank.config.JwtUtil;
import com.suzhou.bank.config.Sm4Service;
import com.suzhou.bank.entity.SysUser;
import com.suzhou.bank.mapper.SysUserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 信贷系统跳转 Token 服务
 * <p>为信贷系统提供两类能力：
 * <ol>
 *   <li>{@link #issueToken(String)}：按操作人账号 userNo（用户账号，String，对应 sys_user.username）
 *       签发一个 4 小时有效的用户 token，
 *       与登录态 token 同构（subject=userId + username + roles），可直接通过现有鉴权拦截器；
 *       客户ID 等业务参数不进 token，由信贷侧用 SM4 加密后随跳转 URL 传递。</li>
 *   <li>{@link #resolve(String)}：用户点击跳转链接后，解密 URL 中的 SM4 密文，
 *       校验其中的 token 有效性，并透传业务参数（customerId 等）给前端。</li>
 * </ol></p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CreditTokenService {

    private final SysUserMapper sysUserMapper;
    private final AuthService authService;
    private final JwtUtil jwtUtil;
    private final Sm4Service sm4Service;

    /** 跳转 token 有效期（毫秒），默认 4 小时 */
    @Value("${credit.token-expiration:14400000}")
    private long tokenExpiration;

    /**
     * 按操作人账号（userNo）签发信贷跳转访问 token（默认 4 小时有效）。
     * <p>userNo 即用户账号（用户登录名），对应 {@code sys_user.username}（= 行内工号 {@code rams_user.tu_no}）。</p>
     *
     * @param userNo 操作人账号（sys_user.username，信贷侧传入）
     * @return { token, userNo, expiresInSeconds }
     * @throws RuntimeException userNo 为空 / 用户不存在 / 账号已禁用
     */
    public Map<String, Object> issueToken(String userNo) {
        if (userNo == null || userNo.trim().isEmpty()) {
            throw new RuntimeException("userNo 不能为空");
        }
        userNo = userNo.trim();
        SysUser user = sysUserMapper.selectOne(
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getUsername, userNo));
        if (user == null) {
            throw new RuntimeException("用户不存在: " + userNo);
        }
        if (user.getStatus() == null || user.getStatus() != 1) {
            throw new RuntimeException("账号已被禁用: " + userNo);
        }

        Long userId = user.getId();
        List<String> roles = authService.getUserRoleCodes(userId);
        String token = jwtUtil.generateToken(userId, user.getUsername(), roles, tokenExpiration);
        log.info("签发信贷跳转token, userNo={}, userId={}, roles={}, expirationMs={}", userNo, userId, roles, tokenExpiration);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("token", token);
        result.put("userNo", userNo);
        result.put("expiresInSeconds", tokenExpiration / 1000);
        return result;
    }

    /**
     * 解密跳转链接中的 SM4 密文，校验其中 token 并透传业务参数。
     *
     * @param base64Cipher SM4 加密后的 Base64 参数串（JSON，必含 token，可含 customerId 等）
     * @return { token, username, realName, roles, expiresInSeconds, ...业务参数(customerId 等) }
     * @throws RuntimeException 密文为空 / 解密失败 / 缺少或无效 token / 用户已禁用
     */
    public Map<String, Object> resolve(String base64Cipher) {
        if (base64Cipher == null || base64Cipher.trim().isEmpty()) {
            throw new RuntimeException("cipher 参数不能为空");
        }

        JSONObject params;
        try {
            // 注意：这里不要 .trim()——cipher 开头若为 '+' 会被 URL 解码成空格，
            // 先 trim 会吃掉该字符导致长度-1（不是16的倍数）。空白归一化在 Sm4Service.normalizeBase64 内统一处理。
            String plain = sm4Service.decrypt(base64Cipher);
            params = JSON.parseObject(plain);
        } catch (IllegalArgumentException e) {
            // Sm4Service 抛出的参数级错误（密文长度非法/被截断等），信息可直接透传给调用方
            log.warn("跳转参数 SM4 解密参数错误: {}", e.getMessage());
            throw new RuntimeException(e.getMessage());
        } catch (Exception e) {
            log.warn("跳转参数 SM4 解密/解析失败: {}", e.getMessage());
            throw new RuntimeException("跳转参数无效（密文与密钥/算法不一致，或链接已损坏），请让信贷系统重新生成");
        }

        String token = params.getString("token");
        if (token == null || token.trim().isEmpty()) {
            throw new RuntimeException("跳转参数缺少 token");
        }
        if (!jwtUtil.validateToken(token)) {
            throw new RuntimeException("链接已失效或已过期，请让信贷系统重新生成");
        }

        Long userId = jwtUtil.getUserId(token);
        SysUser user = sysUserMapper.selectById(userId);
        if (user == null || user.getStatus() == null || user.getStatus() != 1) {
            throw new RuntimeException("账号不可用，无法访问");
        }

        List<String> roles = jwtUtil.getRoles(token);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("token", token);
        result.put("username", user.getUsername());
        result.put("realName", user.getRealName());
        result.put("roles", roles);
        result.put("expiresInSeconds", tokenExpiration / 1000);
        // 透传业务参数（customerId 等），过滤掉 token 本身
        for (Map.Entry<String, Object> e : params.entrySet()) {
            if (!"token".equals(e.getKey())) {
                result.put(e.getKey(), e.getValue());
            }
        }
        log.info("解析信贷跳转链接成功, userId={}, params={}", userId, params.keySet());
        return result;
    }

    /**
     * SM4 加密（供信贷系统联调校验密钥/算法一致性）。
     *
     * @param plain 待加密明文
     * @return Base64 密文
     */
    public String sm4Encrypt(String plain) {
        if (plain == null) {
            throw new RuntimeException("plain 不能为空");
        }
        try {
            return sm4Service.encrypt(plain);
        } catch (Exception e) {
            throw new RuntimeException("SM4 加密失败: " + e.getMessage(), e);
        }
    }

    /**
     * SM4 解密（供信贷系统联调校验密钥/算法一致性）。
     *
     * @param base64Cipher Base64 密文
     * @return 明文
     */
    public String sm4Decrypt(String base64Cipher) {
        if (base64Cipher == null || base64Cipher.trim().isEmpty()) {
            throw new RuntimeException("cipher 不能为空");
        }
        try {
            return sm4Service.decrypt(base64Cipher.trim());
        } catch (Exception e) {
            throw new RuntimeException("SM4 解密失败（请核对密钥/模式/填充是否一致）: " + e.getMessage(), e);
        }
    }
}
