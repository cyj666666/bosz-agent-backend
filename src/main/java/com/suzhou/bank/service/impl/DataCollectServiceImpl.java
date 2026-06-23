package com.suzhou.bank.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.mapper.*;
import com.suzhou.bank.service.data.DataCollectService;
import com.suzhou.bank.service.data.collector.DataCollector;
import com.suzhou.bank.service.data.parser.DataParser;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;
import java.util.Map;

/**
 * 数据采集编排服务实现
 * <p>协调 Collector 和 Parser，执行完整的数据采集→解析→入库流程。
 * Collector 和 Parser 通过策略模式按类型自动路由。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DataCollectServiceImpl implements DataCollectService {

    private final List<DataCollector> collectors;
    private final List<DataParser> parsers;

    private final CollectorConfigMapper collectorMapper;
    private final ParserConfigMapper parserMapper;
    private final RawDataLogMapper rawDataLogMapper;
    private final IndicatorDataMapper indicatorDataMapper;
    private final TextDataMapper textDataMapper;

    /** 根据采集器配置执行数据采集 */
    @Override
    public RawDataLog collect(Long collectorId, Long customerId) {
        CollectorConfig config = collectorMapper.selectById(collectorId);
        if (config == null) {
            throw new RuntimeException("采集器配置不存在: " + collectorId);
        }
        if (config.getEnabled() == null || config.getEnabled() != 1) {
            throw new RuntimeException("采集器未启用: " + config.getConfigName());
        }

        RawDataLog rawLog = new RawDataLog();
        rawLog.setCollectorId(collectorId);
        rawLog.setCustomerId(customerId);
        rawLog.setCollectTime(new Date());

        DataCollector collector = findCollector(config.getCollectorType());

        try {
            String rawContent = collector.collect(config);
            rawLog.setRawContent(rawContent);
            rawLog.setContentType("application/json");
            rawLog.setSuccess(1);
            rawDataLogMapper.insert(rawLog);
            log.info("数据采集成功, collectorId={}, customerId={}, type={}, dataSize={}",
                    collectorId, customerId, config.getCollectorType(), rawContent.length());
            // 采集成功后自动触发解析入库
            parseAndStore(rawLog.getId());
        } catch (Exception e) {
            rawLog.setSuccess(0);
            rawLog.setErrorMsg(e.getMessage());
            rawLog.setRawContent("{}");
            rawLog.setContentType("application/json");
            rawDataLogMapper.insert(rawLog);
            log.error("数据采集失败, collectorId={}, customerId={}, type={}",
                    collectorId, customerId, config.getCollectorType(), e);
        }

        return rawLog;
    }

    /** 解析原始数据并入库 */
    @Override
    public void parseAndStore(Long rawDataLogId) {
        RawDataLog rawLog = rawDataLogMapper.selectById(rawDataLogId);
        if (rawLog == null || rawLog.getSuccess() != 1) {
            log.warn("原始数据日志不可解析, rawDataLogId={}", rawDataLogId);
            return;
        }

        Long collectorId = rawLog.getCollectorId();
        Long customerId = rawLog.getCustomerId();
        String rawData = rawLog.getRawContent();

        List<ParserConfig> parserConfigs = parserMapper.selectList(
                new LambdaQueryWrapper<ParserConfig>()
                        .eq(ParserConfig::getCollectorId, collectorId)
                        .orderByAsc(ParserConfig::getSortOrder));

        if (parserConfigs.isEmpty()) {
            log.info("该采集器未配置解析器, collectorId={}", collectorId);
            return;
        }

        int indicatorCount = 0;
        int textCount = 0;

        for (ParserConfig parserCfg : parserConfigs) {
            DataParser parser = findParser(parserCfg.getParserType());
            try {
                List<Map<String, Object>> indicators = parser.parse(rawData, parserCfg.getConfigJson(), customerId);
                for (Map<String, Object> mapping : indicators) {
                    IndicatorData indicator = buildIndicator(mapping, parserCfg.getDomain());
                    indicatorDataMapper.insert(indicator);
                    indicatorCount++;
                }

                TextData text = new TextData();
                text.setCustomerId(customerId);
                text.setDomain(parserCfg.getDomain());
                text.setTextType(parserCfg.getParserType());
                text.setTitle("解析结果摘要");
                text.setContent("解析器: " + parserCfg.getParserType()
                        + ", 提取字段数: " + indicators.size());
                text.setCreatedAt(new Date());
                textDataMapper.insert(text);
                textCount++;

                log.info("解析入库完成, parserType={}, domain={}, indicatorCount={}",
                        parserCfg.getParserType(), parserCfg.getDomain(), indicators.size());
            } catch (Exception e) {
                log.error("解析失败, parserType={}, domain={}", parserCfg.getParserType(), parserCfg.getDomain(), e);
            }
        }

        log.info("数据采集→解析→入库完成, rawDataLogId={}, indicatorCount={}, textCount={}",
                rawDataLogId, indicatorCount, textCount);
    }

    private IndicatorData buildIndicator(Map<String, Object> mapping, String domain) {
        IndicatorData d = new IndicatorData();
        d.setCustomerId(toLong(mapping.get("customerId")));
        d.setIndicatorKey(toString(mapping.get("indicatorKey")));
        d.setIndicatorName(toString(mapping.get("indicatorName")));
        d.setCurrentValue(toString(mapping.get("currentValue")));
        d.setDomain(domain);
        d.setPeriod(toString(mapping.get("period")));
        d.setCreatedAt(new Date());
        return d;
    }

    private DataCollector findCollector(String type) {
        return collectors.stream()
                .filter(c -> c.getType().equalsIgnoreCase(type))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("未找到采集器实现: " + type));
    }

    private DataParser findParser(String type) {
        return parsers.stream()
                .filter(p -> p.getType().equalsIgnoreCase(type))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("未找到解析器实现: " + type));
    }

    private String toString(Object obj) {
        return obj != null ? String.valueOf(obj) : null;
    }

    private Long toLong(Object obj) {
        if (obj == null) return null;
        if (obj instanceof Long) return (Long) obj;
        if (obj instanceof Number) return ((Number) obj).longValue();
        try { return Long.valueOf(String.valueOf(obj)); }
        catch (NumberFormatException e) { return null; }
    }
}
