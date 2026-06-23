package com.suzhou.bank.controller;

import com.suzhou.bank.common.Result;
import com.suzhou.bank.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 认证接口
 * <p>提供登录功能，登录成功返回 JWT Token。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /**
     * 用户登录
     *
     * @param body { username, password }
     * @return { token, username, realName }
     */
    @PostMapping("/login")
    public Result<Map<String, Object>> login(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");
        if (username == null || password == null) {
            return Result.fail("用户名和密码不能为空");
        }
        try {
            return Result.ok(authService.login(username, password));
        } catch (RuntimeException e) {
            return Result.fail(401, e.getMessage());
        }
    }
}