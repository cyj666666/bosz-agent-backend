package com.suzhou.bank.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.CollectorConfig;
import com.suzhou.bank.entity.ParserConfig;
import com.suzhou.bank.mapper.CollectorConfigMapper;
import com.suzhou.bank.mapper.ParserConfigMapper;
import com.suzhou.bank.service.data.DataConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import java.util.List;

@Slf4j
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

    @Override
    public void saveCollector(CollectorConfig c) {
        cm.insert(c);
        log.info("采集器已新增, id={}, name={}, type={}", c.getId(), c.getConfigName(), c.getCollectorType());
    }

    @Override public void updateCollector(CollectorConfig c) {
        cm.updateById(c);
        log.info("采集器已更新, id={}, name={}", c.getId(), c.getConfigName());
    }

    @Override
    public void deleteCollector(Long id) {
        cm.deleteById(id);
        log.info("采集器已删除, id={}", id);
    }

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

    @Override
    public void saveParser(ParserConfig p) {
        pm.insert(p);
        log.info("解析器已新增, id={}, collectorId={}, type={}, domain={}", p.getId(), p.getCollectorId(), p.getParserType(), p.getDomain());
    }

    @Override public void updateParser(ParserConfig p) {
        pm.updateById(p);
        log.info("解析器已更新, id={}, type={}, domain={}", p.getId(), p.getParserType(), p.getDomain());
    }

    @Override
    public void deleteParser(Long id) {
        pm.deleteById(id);
        log.info("解析器已删除, id={}", id);
    }
}
