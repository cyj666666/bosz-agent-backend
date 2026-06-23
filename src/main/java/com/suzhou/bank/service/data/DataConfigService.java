package com.suzhou.bank.service.data;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.CollectorConfig;
import com.suzhou.bank.entity.ParserConfig;

import java.util.List;

public interface DataConfigService {
    // 采集器配置
    Page<CollectorConfig> pageCollector(int page, int size, String type);
    CollectorConfig getCollector(Long id);
    void saveCollector(CollectorConfig config);
    void updateCollector(CollectorConfig config);
    void deleteCollector(Long id);
    List<CollectorConfig> listEnabledCollectors();

    // 解析器配置
    List<ParserConfig> listParserByCollector(Long collectorId);
    ParserConfig getParser(Long id);
    void saveParser(ParserConfig config);
    void updateParser(ParserConfig config);
    void deleteParser(Long id);
}
