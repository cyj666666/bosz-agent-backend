package com.suzhou.bank.service.data.parser;

import java.util.List;
import java.util.Map;

public interface DataParser {
    String getType();
    List<Map<String, Object>> parse(String rawData, String parseConfig, Long customerId);
}
