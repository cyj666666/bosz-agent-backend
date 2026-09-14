package com.suzhou.bank.agent.dict;

import java.util.List;
import java.util.Map;

/**
 * agent 模块的字典数据提供者
 *
 * <p><b>为什么抽成接口</b>：源工程里字典缓存（{@code SysDictCache}）通过 JeecgBoot 的
 * {@code CommonAPI.queryAllDictItems()} 取数，实现与 Jeecg 的 Service 体系绑定。
 * agent 模块自带实现，直接读 {@code sys_dict} / {@code sys_dict_item}。</p>
 */
public interface AgentDictProvider {

    /**
     * 一次性取全部字典项
     *
     * @return key 为字典编码（{@code sys_dict.dict_code}），value 为该字典下的全部字典项
     */
    Map<String, List<DictModel>> queryAllDictItems();
}
