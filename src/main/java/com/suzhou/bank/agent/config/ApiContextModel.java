package com.suzhou.bank.agent.config;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 当前调用者的上下文信息
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.config.ApiContextModel}，字段原样平移。</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApiContextModel {

    /** 用户id */
    private String userId;

    /** 用户名称（登录账号） */
    private String userName;

    /** 用户角色 */
    private String role;

    /** 角色编码 */
    private List<String> roleCode;

    /**
     * 角色主键列表（{@code sys_role.id}）
     *
     * <p><b>与 {@link #role} / {@link #roleCode} 的区别（三者口径不同，别混用）</b>：</p>
     * <ul>
     *   <li>{@code roleIdList} —— 角色<b>主键</b>（如 {@code ["1"]}），用于查
     *       {@code sys_role_index}（授权数据关联，口径与安硕源工程一致）；</li>
     *   <li>{@code roleCode} —— 角色<b>编码</b>（如 {@code ["admin"]}），来自宿主 JWT，
     *       用于"超管放行"这类可读的运维判断；</li>
     *   <li>{@code role} —— 为兼容源工程遗留代码保留，内容是 {@code roleIdList} 的
     *       <b>JSON 数组字符串</b>（源工程用 {@code JSON.parseArray} 消费它）。</li>
     * </ul>
     *
     * <p>宿主 JWT 里没有角色主键，本字段由 {@code ApiContext} 按 userId 查 {@code sys_user_role} 得到。</p>
     */
    private List<String> roleIdList;

    /** 机构名称/真实姓名 */
    private String realName;

    /** 电话号码 */
    private String phone;
}
