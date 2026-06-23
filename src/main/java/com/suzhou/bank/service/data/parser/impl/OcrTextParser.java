package com.suzhou.bank.service.data.parser.impl;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import com.suzhou.bank.service.data.parser.DataParser;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * OCR 文本解析器
 * <p>对 OCR 识别后的纯文本，按关键词匹配提取结构化数据。
 * 适用于营业执照、审计报告等扫描件的文字提取。</p>
 *
 * <p>OCR 识别本身依赖外部服务（阿里云/腾讯云 OCR API），
 * 本解析器假设输入已经是识别后的纯文本。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Component
public class OcrTextParser implements DataParser {

    @Override
    public String getType() {
        return "OCR_TEXT";
    }

    @Override
    public List<Map<String, Object>> parse(String rawData, String parseConfig, Long customerId) {
        JSONObject cfg = JSON.parseObject(parseConfig);
        JSONArray keywords = cfg.getJSONArray("keywords");
        String extractPattern = cfg.getString("extractPattern");

        if (keywords == null || keywords.isEmpty()) {
            log.warn("OCR_TEXT 解析配置中无 keywords");
            return new ArrayList<>();
        }

        List<Map<String, Object>> result = new ArrayList<>();

        for (int i = 0; i < keywords.size(); i++) {
            String keyword = keywords.getString(i);
            String value = extractByPattern(rawData, keyword, extractPattern);

            Map<String, Object> indicator = new LinkedHashMap<>();
            indicator.put("customerId", customerId);
            indicator.put("indicatorKey", toKey(keyword));
            indicator.put("indicatorName", keyword);
            indicator.put("currentValue", value);
            result.add(indicator);
        }

        log.info("OCR_TEXT 解析完成, keywordCount={}, extractedCount={}", keywords.size(), result.size());
        return result;
    }

    /**
     * 按模式从文本中提取关键词对应的值
     */
    private String extractByPattern(String text, String keyword, String pattern) {
        if (text == null || keyword == null) return null;

        // 模式1: keyValue — 关键词在左，值在右（如"注册资本：500万元"）
        if ("keyValue".equals(pattern) || pattern == null) {
            // 匹配：关键词 + 可选的中文冒号/空格 + 值
            String regex = Pattern.quote(keyword) + "\\s*[：:]?\\s*([0-9,.，。]+[万万千百亿亿]?[元美元人个]?|\\S{1,50})";
            Matcher m = Pattern.compile(regex).matcher(text);
            if (m.find()) {
                return m.group(1).trim();
            }
        }

        // 模式2: valueKey — 值在左，关键词在右（如"500万元 注册资本"）
        if ("valueKey".equals(pattern)) {
            String regex = "([0-9,.，。]+[万万千百亿亿]?[元美元人个]?|\\S{1,50})\\s*" + Pattern.quote(keyword);
            Matcher m = Pattern.compile(regex).matcher(text);
            if (m.find()) {
                return m.group(1).trim();
            }
        }

        // 模式3: 就近匹配 — 找关键词前后最近的数字
        if ("nearby".equals(pattern)) {
            return findNearestNumber(text, keyword);
        }

        return null;
    }

    /**
     * 在所有关键词附近找最近的数值
     */
    private String findNearestNumber(String text, String keyword) {
        int pos = text.indexOf(keyword);
        if (pos < 0) return null;
        // 取关键词前后各50个字符
        int start = Math.max(0, pos - 50);
        int end = Math.min(text.length(), pos + keyword.length() + 50);
        String nearby = text.substring(start, end);
        Matcher m = Pattern.compile("[0-9,.，。]+[万万千百亿亿]?[元美元人个]?").matcher(nearby);
        return m.find() ? m.group() : null;
    }

    /**
     * 中文关键词转为驼峰 key（如 "注册资本" → "registerCapital"）
     */
    private String toKey(String keyword) {
        // 简单处理：去掉空格和标点，保留下划线分隔
        return keyword.replaceAll("[\\s\\p{P}]", "_").toLowerCase();
    }
}
