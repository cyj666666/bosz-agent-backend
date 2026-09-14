package com.suzhou.bank.agent.dict;

import com.google.common.cache.CacheBuilder;
import com.google.common.cache.CacheLoader;
import com.google.common.cache.LoadingCache;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;

import javax.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * 数据字典缓存（进程内，永不过期，需显式 {@link #refresh()} 刷新）
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.config.memory.SysDictCache}。</p>
 *
 * <p><b>与源实现的一处重要差异（健壮性）</b>：源实现在 {@code @PostConstruct} 里
 * 直接加载全量字典，取数失败会让整个应用<b>启动失败</b>。本模块把首次加载包在
 * try/catch 中，失败时只记录告警、保持空缓存，应用仍能正常启动——
 * 因为字典缺失只影响个别下拉项/取值分支，不应上升为服务不可用。
 * 需要时可通过缓存刷新接口或重启后重试恢复。</p>
 *
 * <p><b>典型用途</b>：指标取数时读取 {@code SqlLimitType} 字典决定 SQL 结果集条数上限。</p>
 */
@Component
public class AgentDictCache {

    private static final Logger LOGGER = LoggerFactory.getLogger(AgentDictCache.class);

    private LoadingCache<String, List<DictModel>> cache;

    @Autowired
    private AgentDictProvider agentDictProvider;

    @PostConstruct
    public void init() {
        cache = CacheBuilder.newBuilder()
                .expireAfterWrite(Long.MAX_VALUE, TimeUnit.DAYS)
                .build(new CacheLoader<String, List<DictModel>>() {
                    @Override
                    public List<DictModel> load(String key) {
                        return new ArrayList<>();
                    }
                });
        loadAll();
    }

    /**
     * 按字典编码 + 字典值精确取单项
     *
     * @param key  字典编码
     * @param item 字典值（{@code sys_dict_item.item_value}）
     * @return 匹配项，未命中返回 {@code null}
     */
    public DictModel get(String key, String item) {
        if (StringUtils.isBlank(item)) {
            return null;
        }
        try {
            List<DictModel> dictModelList = cache.get(key);
            if (!CollectionUtils.isEmpty(dictModelList)) {
                List<DictModel> collect = dictModelList.stream()
                        .filter(dictModel -> item.equals(dictModel.getValue()))
                        .collect(Collectors.toList());
                if (!CollectionUtils.isEmpty(collect)) {
                    return collect.get(0);
                }
            }
        } catch (Exception e) {
            return null;
        }
        return null;
    }

    /**
     * 取某字典的全部字典项
     *
     * <p>注意：返回的是缓存中的引用，调用方<b>不要就地修改</b>返回的 List。</p>
     */
    public List<DictModel> get(String key) {
        try {
            return cache.get(key);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * 使某个字典缓存失效
     */
    public void invalidateKey(String key) {
        cache.invalidate(key);
    }

    /**
     * 刷新全量字典缓存
     */
    public void refresh() {
        cache.invalidateAll();
        loadAll();
    }

    private void loadAll() {
        try {
            Map<String, List<DictModel>> stringListMap = agentDictProvider.queryAllDictItems();
            if (!CollectionUtils.isEmpty(stringListMap)) {
                cache.putAll(stringListMap);
            }
        } catch (Exception e) {
            // 启动期字典加载失败不应阻断应用启动，详见类注释
            LOGGER.warn("agent 模块字典缓存首次加载失败，将保持空缓存；"
                    + "如需恢复请检查 sys_dict / sys_dict_item 是否就绪后重启。原因：{}", e.getMessage());
        }
    }
}
