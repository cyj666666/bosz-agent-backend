package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 系统用户表（sys_user）
 * <p>存储登录账号信息，密码使用 BCrypt 加密存储。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@TableName("sys_user")
public class SysUser {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String username;
    private String password;
    private String realName;
    private Integer status;       // 1=启用 0=禁用
    private java.util.Date createdAt;
}