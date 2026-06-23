package com.suzhou.bank.service.data.parser.impl;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import com.alibaba.fastjson2.JSONPath;
import com.suzhou.bank.service.data.parser.DataParser;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * JSONPath 解析器
 * <p>通过 JSONPath 表达式从 JSON 数据中提取结构化指标。
 * 适用于 HTTP API 返回的标准 JSON 响应。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Component
public class JsonPathParser implements DataParser {

    @Override
    public String getType() {
        return "JSON_PATH";
    }

    @Override
    public List<Map<String, Object>> parse(String rawData, String parseConfig, Long customerId) {
        JSONObject cfg = JSON.parseObject(parseConfig);
        JSONArray mappings = cfg.getJSONArray("mappings");
        if (mappings == null || mappings.isEmpty()) {
            log.warn("JSON_PATH 解析配置中无 mappings");
            return new ArrayList<>();
        }

        Object root = tryParse(rawData);
        List<Map<String, Object>> result = new ArrayList<>();

        for (int i = 0; i < mappings.size(); i++) {
            JSONObject mapping = mappings.getJSONObject(i);
            String key = mapping.getString("key");
            String name = mapping.getString("name");
            String path = mapping.getString("path");

            try {
                Object value = JSONPath.eval(root, path);
                Map<String, Object> indicator = new LinkedHashMap<>();
                indicator.put("customerId", customerId);
                indicator.put("indicatorKey", key);
                indicator.put("indicatorName", name);
                indicator.put("currentValue", value != null ? String.valueOf(value) : null);
                result.add(indicator);
            } catch (Exception e) {
                log.warn("JSONPath 提取失败, key={}, path={}, error={}", key, path, e.getMessage());
            }
        }

        log.info("JSON_PATH 解析完成, path={}, extractedCount={}", cfg.getString("path"), result.size());
        return result;
    }

    /**
     * 尝试将字符串解析为 JSON 对象或数组
     */
    private Object tryParse(String rawData) {
        try {
            if (rawData.trim().startsWith("[")) {
                return JSON.parseArray(rawData);
            }
            return JSON.parseObject(rawData);
        } catch (Exception e) {
            log.warn("JSON_PATH 数据不是标准JSON，当作纯文本处理");
            return rawData;
        }
    }
}
