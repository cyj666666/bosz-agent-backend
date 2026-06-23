package com.suzhou.bank.service.data.parser;

import java.util.List;
import java.util.Map;

/**
 * 数据解析器接口（策略模式）
 * <p>定义"怎么解析数据"的抽象，将采集器获取的原始数据
 * 转换为标准化的指标键值对，按数据域（domain）入库。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
public interface DataParser {

    /**
     * 获取解析器类型标识
     *
     * @return 类型字符串（如 JSONPATH、EXCEL_TEMPLATE、OCR_TEXT）
     */
    String getType();

    /**
     * 解析原始数据为标准化指标
     *
     * @param rawData     原始数据字符串
     * @param parseConfig 解析配置（如 JSONPath 表达式、Excel 模板定义等）
     * @param customerId  客户ID（用于关联）
     * @return 标准化的指标列表，每项为 domain + key + value 的 Map
     */
    List<Map<String, Object>> parse(String rawData, String parseConfig, Long customerId);
}
