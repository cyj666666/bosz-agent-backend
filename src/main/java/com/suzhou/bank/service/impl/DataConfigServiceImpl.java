package com.suzhou.bank.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.CollectorConfig;
import com.suzhou.bank.entity.ParserConfig;
import com.suzhou.bank.mapper.CollectorConfigMapper;
import com.suzhou.bank.mapper.ParserConfigMapper;
import com.suzhou.bank.service.data.DataConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DataConfigServiceImpl implements DataConfigService {
    private final CollectorConfigMapper cm;
    private final ParserConfigMapper pm;

    @Override
    public Page<CollectorConfig> pageCollector(int page, int size, String type) {
        LambdaQueryWrapper<CollectorConfig> w = new LambdaQueryWrapper<CollectorConfig>();
        if (type != null && !type.isEmpty()) w.eq(CollectorConfig::getCollectorType, type);
        w.orderByDesc(CollectorConfig::getCreatedAt);
        return cm.selectPage(new Page<>(page, size), w);
    }

    @Override public CollectorConfig getCollector(Long id) { return cm.selectById(id); }
    @Override public void saveCollector(CollectorConfig c) { cm.insert(c); }
    @Override public void updateCollector(CollectorConfig c) { cm.updateById(c); }
    @Override public void deleteCollector(Long id) { cm.deleteById(id); }

    @Override
    public List<CollectorConfig> listEnabledCollectors() {
        return cm.selectList(new LambdaQueryWrapper<CollectorConfig>().eq(CollectorConfig::getEnabled, 1));
    }

    @Override
    public List<ParserConfig> listParserByCollector(Long cid) {
        return pm.selectList(new LambdaQueryWrapper<ParserConfig>()
            .eq(ParserConfig::getCollectorId, cid).orderByAsc(ParserConfig::getSortOrder));
    }

    @Override public ParserConfig getParser(Long id) { return pm.selectById(id); }
    @Override public void saveParser(ParserConfig p) { pm.insert(p); }
    @Override public void updateParser(ParserConfig p) { pm.updateById(p); }
    @Override public void deleteParser(Long id) { pm.deleteById(id); }
}
