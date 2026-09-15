package com.suzhou.bank.agent.mapper;

import com.suzhou.bank.agent.model.vo.AgentOptionVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 智能体配置查询 Mapper（只读）
 *
 * <p><b>为什么现在才补</b>：{@code agent_config} 表随源工程库一起存在于本工程库里
 * （见 {@code sql/agent/agent_gauss_ddl.sql}），但本工程此前没有任何实体/Mapper/Controller 映射它。
 * 前端「关联 agent」下拉需要它，故补一个最小只读 Mapper。</p>
 *
 * <p><b>为什么不用 BaseMapper + Entity</b>：整表含两个 TEXT 大字段，而下拉只需要 5 列，
 * 用投影查询避免把大字段读进内存。</p>
 *
 * <p><b>口径说明</b>：源工程 {@code /agent/agentConfig/list} 未做任何状态过滤（下拉列出全部智能体），
 * 这里保持一致——若将来要只列启用项，应同时在源工程与本工程改，避免两边下拉项不一致。</p>
 *
 * <p>列名显式起驼峰别名，与本工程 {@code AgentDictMapper} 的写法保持一致。</p>
 */
@Mapper
public interface AgentConfigMapper {

    /**
     * 智能体下拉列表
     *
     * <p>不分页：源工程前端一次取 {@code pageSize: 2000}，等价于全量；本工程数据量同源库，
     * 直接全量返回并让前端过滤，少一次分页参数的往返。</p>
     */
    @Select("select id              as id, "
            + "       agent_name     as agentName, "
            + "       agent_code     as agentCode, "
            + "       agent_status   as agentStatus, "
            + "       large_model_code as largeModelCode "
            + "  from agent_config "
            + " order by id")
    List<AgentOptionVO> selectAgentOptions();
}
