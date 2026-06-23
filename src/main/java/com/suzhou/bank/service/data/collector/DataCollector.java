package com.suzhou.bank.service.data.collector;

import com.suzhou.bank.entity.CollectorConfig;

public interface DataCollector {
    String getType();
    String collect(CollectorConfig config);
    boolean validateConfig(String configJson);
}
