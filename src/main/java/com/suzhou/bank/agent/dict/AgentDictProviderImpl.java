package com.suzhou.bank.agent.dict;

import com.suzhou.bank.agent.mapper.AgentDictMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 字典数据提供者实现（读 {@code sys_dict} / {@code sys_dict_item}）
 *
 * <p>替代源工程经 JeecgBoot {@code CommonAPI.queryAllDictItems()} 取字典的路径，
 * 由 agent 模块自己直连这两张表。</p>
 *
 * <p>取数失败时返回空 Map 而不是抛异常——字典缺失只影响个别下拉项与取值分支，
 * 不应让整个应用启动失败（详细理由见 {@code AgentDictCache} 的类注释）。</p>
 */
@Slf4j
@Component
public class AgentDictProviderImpl implements AgentDictProvider {

    @Autowired
    private AgentDictMapper agentDictMapper;

    @Override
    public Map<String, List<DictModel>> queryAllDictItems() {
        Map<String, List<DictModel>> result = new LinkedHashMap<>();
        List<DictItemRow> rows;
        try {
            rows = agentDictMapper.selectAllEnabledDictItems();
        } catch (Exception e) {
            log.warn("agent 模块查询字典失败（sys_dict / sys_dict_item 是否已建好？）：{}", e.getMessage());
            return result;
        }
        if (CollectionUtils.isEmpty(rows)) {
            return result;
        }
        for (DictItemRow row : rows) {
            if (row.getDictCode() == null) {
                continue;
            }
            DictModel model = new DictModel(row.getValue(), row.getText())
                    .setSortOrder(row.getSortOrder())
                    .setSynonymWord(row.getSynonymWord())
                    .setKeyWord(row.getKeyWord())
                    .setRelaTable(row.getRelaTable())
                    .setFieldAttr(row.getFieldAttr());
            result.computeIfAbsent(row.getDictCode(), k -> new ArrayList<>()).add(model);
        }
        log.info("agent 模块字典缓存已加载：{} 个字典编码、{} 条字典项", result.size(), rows.size());
        return result;
    }
}
