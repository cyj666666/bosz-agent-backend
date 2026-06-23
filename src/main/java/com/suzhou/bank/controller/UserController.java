package com.suzhou.bank.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.SysUser;
import com.suzhou.bank.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.*;

/**
 * 用户管理接口
 * <p>管理员操作，需要 admin 角色。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /** 用户分页列表 */
    @GetMapping("/page")
    public Result<Map<String, Object>> page(@RequestParam(defaultValue = "1") int page,
                                            @RequestParam(defaultValue = "10") int size,
                                            @RequestParam(required = false) String keyword) {
        Page<SysUser> result = userService.page(page, size, keyword);
        // 组装返回，每个用户带角色信息
        List<Map<String, Object>> records = new ArrayList<>();
        for (SysUser u : result.getRecords()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", u.getId());
            item.put("username", u.getUsername());
            item.put("realName", u.getRealName());
            item.put("status", u.getStatus());
            item.put("createdAt", u.getCreatedAt());
            item.put("roles", userService.getUserRoleCodes(u.getId()));
            item.put("roleIds", userService.getUserRoleIds(u.getId()));
            records.add(item);
        }
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("records", records);
        data.put("total", result.getTotal());
        return Result.ok(data);
    }

    /** 用户详情 */
    @GetMapping("/{id}")
    public Result<Map<String, Object>> getById(@PathVariable Long id) {
        SysUser user = userService.getById(id);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", user.getId());
        data.put("username", user.getUsername());
        data.put("realName", user.getRealName());
        data.put("status", user.getStatus());
        data.put("createdAt", user.getCreatedAt());
        data.put("roleIds", userService.getUserRoleIds(id));
        return Result.ok(data);
    }

    /** 新增用户 */
    @PostMapping
    public Result<Void> save(@RequestBody Map<String, Object> body) {
        SysUser user = new SysUser();
        user.setUsername((String) body.get("username"));
        user.setPassword((String) body.get("password"));
        user.setRealName((String) body.get("realName"));
        @SuppressWarnings("unchecked")
        List<Integer> rawIds = (List<Integer>) body.get("roleIds");
        List<Long> roleIds = rawIds != null ? rawIds.stream().map(Long::valueOf).collect(java.util.stream.Collectors.toList()) : null;
        userService.save(user, roleIds);
        return Result.ok();
    }

    /** 更新用户 */
    @PutMapping
    public Result<Void> update(@RequestBody Map<String, Object> body) {
        SysUser user = new SysUser();
        user.setId(Long.valueOf(body.get("id").toString()));
        user.setRealName((String) body.get("realName"));
        user.setStatus((Integer) body.get("status"));
        @SuppressWarnings("unchecked")
        List<Integer> rawIds = (List<Integer>) body.get("roleIds");
        List<Long> roleIds = rawIds != null ? rawIds.stream().map(Long::valueOf).collect(java.util.stream.Collectors.toList()) : null;
        userService.update(user, roleIds);
        return Result.ok();
    }

    /** 删除用户 */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id, HttpServletRequest request) {
        Long currentUserId = (Long) request.getAttribute("userId");
        userService.delete(id, currentUserId);
        return Result.ok();
    }

    /** 管理员重置用户密码为默认值 Abc12345 */
    @PostMapping("/{id}/reset-password")
    public Result<Map<String, String>> resetPassword(@PathVariable Long id) {
        String newPwd = userService.resetPassword(id);
        Map<String, String> data = new HashMap<>();
        data.put("newPassword", newPwd);
        return Result.ok(data);
    }

    /** 管理员手动设置用户密码 */
    @PutMapping("/{id}/set-password")
    public Result<Void> setPassword(@PathVariable Long id, @RequestBody Map<String, String> body) {
        String newPwd = body.get("password");
        if (newPwd == null || newPwd.length() < 6) {
            return Result.fail("密码至少6位");
        }
        userService.setPassword(id, newPwd);
        return Result.ok();
    }

    /** 当前用户修改自己的密码 */
    @PostMapping("/change-password")
    public Result<Void> changePassword(@RequestBody Map<String, String> body,
                                       HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        userService.changePassword(userId, body.get("oldPassword"), body.get("newPassword"));
        return Result.ok();
    }
}