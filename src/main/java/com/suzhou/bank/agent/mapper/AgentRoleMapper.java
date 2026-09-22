package com.suzhou.bank.agent.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 角色关联查询（只读）
 *
 * <p><b>为什么 agent 模块要自己查这张表</b>：源工程把「当前用户的角色主键」放在它自己的
 * {@code LoginUser} 里（由 JeecgBoot 的登录态提供）。宿主 {@code JwtUtil} 签发的 Token
 * 里只带<b>角色编码</b>（{@code roles: ["admin"]}），<b>没有角色主键</b>。</p>
 *
 * <p>而 {@code sys_role_index.role_id} 的取值口径是<b>角色主键</b>（{@code sys_role.id}，
 * 与安硕源工程一致，也符合列名字面含义），所以必须把主键查出来。
 * 两条路可选：</p>
 * <ul>
 *   <li>(a) 改宿主 {@code JwtUtil} 往 Token 里加 roleIds —— 会侵入宿主鉴权链路；</li>
 *   <li>(b) agent 模块自己按 userId 查 —— <b>选此</b>，符合本模块"自成一体、只留最少接缝"的搬迁约定，
 *       宿主一行都不用改。代价是每请求多一次带索引的主键查询。</li>
 * </ul>
 *
 * <p><b>只读</b>：本 Mapper 刻意不提供任何写方法，角色的维护仍由宿主 {@code /api/role} 负责。</p>
 */
@Mapper
public interface AgentRoleMapper {

    /**
     * 按用户主键查该用户关联的角色主键列表
     *
     * @param userId 用户主键（{@code sys_user.id}）
     * @return 角色主键列表；无关联时返回空列表
     */
    @Select("SELECT role_id FROM sys_user_role WHERE user_id = #{userId}")
    List<Long> selectRoleIdsByUserId(@Param("userId") Long userId);

    /**
     * 按角色编码列表查角色主键列表
     *
     * <p><b>为什么放在这里</b>：源工程的 {@code SysRoleAiUserServiceImpl#getAdminRoleId}
     * 注入 Jeecg 的 {@code ISysRoleService} 并构造 {@code SysRole} 查询条件来查 {@code sys_role}。
     * agent 模块不引入 Jeecg 的 Service 体系，改用本 Mapper 的只读查询——
     * 与 {@link #selectRoleIdsByUserId} 同源同表，口径一致。</p>
     *
     * <p>注意宿主 {@code sys_role.id} 是 bigint 自增，故返回 {@code Long}，调用方按需转字符串。</p>
     *
     * @param roleCodes 角色编码列表（{@code sys_role.role_code}）
     * @return 角色主键列表；无匹配时返回空列表
     */
    @Select("<script>SELECT id FROM sys_role WHERE role_code IN "
            + "<foreach collection='roleCodes' item='code' open='(' separator=',' close=')'>#{code}</foreach>"
            + "</script>")
    List<Long> selectRoleIdsByRoleCodes(@Param("roleCodes") List<String> roleCodes);

    /**
     * 全部角色（含菜单权限），供「角色数据授权」配置页选择角色
     *
     * <p>用 {@code Map} 而不是建实体：agent 模块没有 {@code sys_role} 的实体类
     * （宿主的 {@code SysRole} 在 {@code com.suzhou.bank.entity} 下，不宜反向依赖）。</p>
     *
     * <p><b>返回的 key 是库里的列名（小写）</b>：{@code id} / {@code role_code} /
     * {@code role_name} / {@code menu_permissions} —— 前端按这些 key 取值。</p>
     *
     * @return 角色列表（含菜单权限 JSON 串）
     */
    @Select("SELECT id, role_code, role_name, menu_permissions FROM sys_role ORDER BY id")
    List<Map<String, Object>> selectAllRoles();
}
