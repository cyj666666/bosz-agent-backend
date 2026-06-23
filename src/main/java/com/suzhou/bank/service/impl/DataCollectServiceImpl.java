package com.suzhou.bank.service.impl;

import com.suzhou.bank.entity.*;
import com.suzhou.bank.mapper.*;
import com.suzhou.bank.service.data.DataCollectService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import java.util.Date;

/**
 * 数据采集编排服务实现
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DataCollectServiceImpl implements DataCollectService {
    private final CollectorConfigMapper collectorMapper;
    private final ParserConfigMapper parserMapper;
    private final RawDataLogMapper rawDataLogMapper;
    private final IndicatorDataMapper indicatorDataMapper;
    private final TextDataMapper textDataMapper;

    @Override
    public RawDataLog collect(Long collectorId, Long customerId) {
        CollectorConfig config = collectorMapper.selectById(collectorId);
        RawDataLog log = new RawDataLog();
        log.setCollectorId(collectorId);
        log.setCustomerId(customerId);
        log.setCollectTime(new Date());
        try {
            log.setRawContent("{}");
            log.setContentType("application/json");
            log.setSuccess(1);
        } catch (Exception e) {
            log.setSuccess(0);
            log.setErrorMsg(e.getMessage());
        }
        rawDataLogMapper.insert(log);
        return log;
    }

    @Override
    public void parseAndStore(Long rawDataLogId) {
        // TODO: route to specific parser implementation
    }
}
