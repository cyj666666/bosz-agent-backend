package com.suzhou.bank.service.data;

import com.suzhou.bank.entity.RawDataLog;

public interface DataCollectService {
    /** 根据采集器配置执行数据采集 */
    RawDataLog collect(Long collectorId, Long customerId);

    /** 解析原始数据并入库 */
    void parseAndStore(Long rawDataLogId);
}
